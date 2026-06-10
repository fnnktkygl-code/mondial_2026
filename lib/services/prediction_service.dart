import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../app_constants.dart';
import '../l10n/translations.dart';
import 'firebase_service.dart';

class MatchPrediction {
  final String matchId;
  final int t1Score;
  final int t2Score;
  final String? extraTimeWinner;
  final bool? penaltyWinner;

  MatchPrediction({
    required this.matchId,
    required this.t1Score,
    required this.t2Score,
    this.extraTimeWinner,
    this.penaltyWinner,
  });

  factory MatchPrediction.fromJson(Map<String, dynamic> json) {
    return MatchPrediction(
      matchId: json['matchId'] as String,
      t1Score: json['t1Score'] as int,
      t2Score: json['t2Score'] as int,
      extraTimeWinner: json['extraTimeWinner'] as String?,
      penaltyWinner: json['penaltyWinner'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      't1Score': t1Score,
      't2Score': t2Score,
      if (extraTimeWinner != null) 'extraTimeWinner': extraTimeWinner,
      if (penaltyWinner != null) 'penaltyWinner': penaltyWinner,
    };
  }
}

class PredictionData {
  String username;
  String avatar;
  String? championCode;
  String? goldenBootPlayer;
  String? goldenBootWinner;
  String? topAssisterPlayer;
  String? topAssisterWinner;
  String? supportedTeam;
  String? boosterMatchId;
  DateTime? championPredictedAt;
  DateTime? goldenBootPredictedAt;
  DateTime? topAssisterPredictedAt;
  Map<String, MatchPrediction> matchPredictions;

  PredictionData({
    this.username = kDefaultUsername,
    this.avatar = '',
    this.championCode,
    this.goldenBootPlayer,
    this.goldenBootWinner,
    this.topAssisterPlayer,
    this.topAssisterWinner,
    this.supportedTeam,
    this.boosterMatchId,
    this.championPredictedAt,
    this.goldenBootPredictedAt,
    this.topAssisterPredictedAt,
    Map<String, MatchPrediction>? matchPredictions,
  }) : matchPredictions = matchPredictions ?? {};

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    final Map<String, MatchPrediction> preds = {};
    if (json['preds'] != null) {
      final Map<String, dynamic> rawPreds =
          json['preds'] as Map<String, dynamic>;
      rawPreds.forEach((key, val) {
        preds[key] = MatchPrediction.fromJson(val as Map<String, dynamic>);
      });
    }

    return PredictionData(
      username: json['username'] as String? ?? kDefaultUsername,
      avatar: json['avatar'] as String? ?? '',
      championCode: json['championCode'] as String?,
      goldenBootPlayer: json['goldenBootPlayer'] as String?,
      goldenBootWinner: json['goldenBootWinner'] as String?,
      topAssisterPlayer: json['topAssisterPlayer'] as String?,
      topAssisterWinner: json['topAssisterWinner'] as String?,
      supportedTeam: json['supportedTeam'] as String?,
      boosterMatchId: json['boosterMatchId'] as String?,
      championPredictedAt: json['championPredictedAt'] != null
          ? DateTime.tryParse(json['championPredictedAt'] as String)
          : null,
      goldenBootPredictedAt: json['goldenBootPredictedAt'] != null
          ? DateTime.tryParse(json['goldenBootPredictedAt'] as String)
          : null,
      topAssisterPredictedAt: json['topAssisterPredictedAt'] != null
          ? DateTime.tryParse(json['topAssisterPredictedAt'] as String)
          : null,
      matchPredictions: preds,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, Map<String, dynamic>> predsJson = {};
    matchPredictions.forEach((key, val) {
      predsJson[key] = val.toJson();
    });

    return {
      'username': username,
      'avatar': avatar,
      'championCode': championCode,
      'goldenBootPlayer': goldenBootPlayer,
      'goldenBootWinner': goldenBootWinner,
      'topAssisterPlayer': topAssisterPlayer,
      'topAssisterWinner': topAssisterWinner,
      'supportedTeam': supportedTeam,
      'boosterMatchId': boosterMatchId,
      if (championPredictedAt != null)
        'championPredictedAt': championPredictedAt!.toIso8601String(),
      if (goldenBootPredictedAt != null)
        'goldenBootPredictedAt': goldenBootPredictedAt!.toIso8601String(),
      if (topAssisterPredictedAt != null)
        'topAssisterPredictedAt': topAssisterPredictedAt!.toIso8601String(),
      'preds': predsJson,
    };
  }
}

class FriendScore {
  final String name;
  final int points;
  final String emblem;
  final bool isUser;
  final String? userId;

  FriendScore({
    required this.name,
    required this.points,
    required this.emblem,
    this.isUser = false,
    this.userId,
  });
}

class FriendGroup {
  final String name;
  final String code;
  final List<FriendScore> members;
  final String? creatorId;

  FriendGroup({
    required this.name,
    required this.code,
    required this.members,
    this.creatorId,
  });
}

class PredictionService {
  static const String _prefsKey = kPredictionsKey;

  // ─── Storage ────────────────────────────────────────────────────────────────

  static Future<void> savePredictionData(PredictionData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString(_prefsKey, jsonStr);
  }

  static Future<PredictionData> loadPredictionData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final data = PredictionData.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );
        return data;
      } catch (_) {
        return PredictionData();
      }
    }
    return PredictionData();
  }

  static Future<PredictionData> resetPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    return PredictionData();
  }

  // ─── Scoring ─────────────────────────────────────────────────────────────────

  static int evaluatePoints(WorldCupMatch match, MatchPrediction pred) {
    if (!match.isPlayed) return 0;

    final actual1 = match.t1Score!;
    final actual2 = match.t2Score!;
    final pred1 = pred.t1Score;
    final pred2 = pred.t2Score;

    if (!match.isKnockout) {
      if (actual1 == pred1 && actual2 == pred2) return kExactScorePoints;
      final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
      final predOutcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
      if (actualOutcome == predOutcome) return kCorrectOutcomePoints;
      return 0;
    }

    if (actual1 == pred1 && actual2 == pred2) {
      return kExactScoreKnockoutPoints + _evalKnockoutBeyond90(match, pred);
    }

    final actual90Outcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
    final pred90Outcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
    if (actual90Outcome == pred90Outcome) {
      return kCorrectOutcomeKnockoutPts + _evalKnockoutBeyond90(match, pred);
    }

    return 0;
  }

  static int _evalKnockoutBeyond90(WorldCupMatch match, MatchPrediction pred) {
    int bonus = 0;
    if (match.wentToET == true && match.etWinner != null) {
      if (pred.extraTimeWinner != null &&
          pred.extraTimeWinner!.toLowerCase() ==
              match.etWinner!.toLowerCase()) {
        bonus += kExtraTimeBonusPoints;
      }
    }
    if (match.wentToPK == true && match.pkWinner != null) {
      if (pred.penaltyWinner == true &&
          match.pkWinner!.toLowerCase() == match.t1.toLowerCase()) {
        bonus += kPenaltyShootoutBonusPoints;
      } else if (pred.penaltyWinner == false &&
          match.pkWinner!.toLowerCase() == match.t2.toLowerCase()) {
        bonus += kPenaltyShootoutBonusPoints;
      }
    }
    return bonus;
  }

  static String? getPredictionResult(
    WorldCupMatch match,
    PredictionData? userPreds,
  ) {
    if (!match.isPlayed || userPreds == null) return null;
    final pred = userPreds.matchPredictions[match.id];
    if (pred == null) return null;

    final actualT1 = match.t1Score!;
    final actualT2 = match.t2Score!;
    if (pred.t1Score == actualT1 && pred.t2Score == actualT2) return 'exact';

    final predictedWinner = pred.t1Score > pred.t2Score ? 't1' : pred.t1Score < pred.t2Score ? 't2' : 'draw';
    final actualWinner = actualT1 > actualT2 ? 't1' : actualT1 < actualT2 ? 't2' : 'draw';
    if (predictedWinner == actualWinner) return 'winner';
    return 'wrong';
  }

  // ─── Stats ───────────────────────────────────────────────────────────────────

  static Map<String, DateTime> getStageStartTimes(List<WorldCupMatch> matches) {
    DateTime? kickoff;
    DateTime? r32;
    DateTime? r16;
    DateTime? qf;
    DateTime? sf;

    for (final m in matches) {
      final d = m.date;
      if (kickoff == null || d.isBefore(kickoff)) kickoff = d;
      final stg = m.stage ?? '';
      if (stg == 'Round of 32') {
        if (r32 == null || d.isBefore(r32)) r32 = d;
      } else if (stg == 'Round of 16') {
        if (r16 == null || d.isBefore(r16)) r16 = d;
      } else if (stg == 'Quarter-Final') {
        if (qf == null || d.isBefore(qf)) qf = d;
      } else if (stg == 'Semi-Final') {
        if (sf == null || d.isBefore(sf)) sf = d;
      }
    }

    return {
      'kickoff': kickoff ?? DateTime(2026, 6, 11, 20, 0),
      'r32': r32 ?? DateTime(2026, 6, 25, 18, 0),
      'r16': r16 ?? DateTime(2026, 6, 29, 18, 0),
      'qf': qf ?? DateTime(2026, 7, 4, 18, 0),
      'sf': sf ?? DateTime(2026, 7, 8, 20, 0),
    };
  }

  static double getPenaltyMultiplier(DateTime? predictedAt, Map<String, DateTime> starts) {
    if (predictedAt == null) return 1.0;
    if (predictedAt.isBefore(starts['kickoff']!)) return 1.0;
    if (predictedAt.isBefore(starts['r32']!)) return 0.8;
    if (predictedAt.isBefore(starts['r16']!)) return 0.6;
    if (predictedAt.isBefore(starts['qf']!)) return 0.4;
    if (predictedAt.isBefore(starts['sf']!)) return 0.2;
    return 0.0;
  }

  static int getPotentialChampionPoints(DateTime? predictedAt, List<WorldCupMatch> matches) {
    final starts = getStageStartTimes(matches);
    return (kChampionBonusPoints * getPenaltyMultiplier(predictedAt, starts)).round();
  }

  static int getPotentialGoldenBootPoints(DateTime? predictedAt, List<WorldCupMatch> matches) {
    final starts = getStageStartTimes(matches);
    return (kGoldenBootBonusPoints * getPenaltyMultiplier(predictedAt, starts)).round();
  }

  static int getPotentialTopAssisterPoints(DateTime? predictedAt, List<WorldCupMatch> matches) {
    final starts = getStageStartTimes(matches);
    return (kTopAssisterBonusPoints * getPenaltyMultiplier(predictedAt, starts)).round();
  }

  static int calculateTotalPoints(PredictionData userPreds, List<WorldCupMatch> matches) {
    int score = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = userPreds.matchPredictions[match.id];
        if (pred != null) {
          int matchPoints = evaluatePoints(match, pred);
          if (userPreds.boosterMatchId == match.id) matchPoints *= 2;
          score += matchPoints;
        }
      }
    }
    final starts = getStageStartTimes(matches);
    final finalMatch = matches.firstWhere((m) => m.id == kFinalMatchId, orElse: () => matches[0]);
    if (finalMatch.isPlayed && userPreds.championCode != null) {
      final actualChampion = finalMatch.t1Score! > finalMatch.t2Score! ? finalMatch.t1 : finalMatch.t2;
      if (actualChampion.toLowerCase() == userPreds.championCode!.toLowerCase()) {
        score += (kChampionBonusPoints * getPenaltyMultiplier(userPreds.championPredictedAt, starts)).round();
      }
    }
    if (userPreds.goldenBootWinner != null && userPreds.goldenBootPlayer != null) {
      if (userPreds.goldenBootPlayer!.trim().toLowerCase() == userPreds.goldenBootWinner!.trim().toLowerCase()) {
        score += (kGoldenBootBonusPoints * getPenaltyMultiplier(userPreds.goldenBootPredictedAt, starts)).round();
      }
    }
    if (userPreds.topAssisterWinner != null && userPreds.topAssisterPlayer != null) {
      if (userPreds.topAssisterPlayer!.trim().toLowerCase() == userPreds.topAssisterWinner!.trim().toLowerCase()) {
        score += (kTopAssisterBonusPoints * getPenaltyMultiplier(userPreds.topAssisterPredictedAt, starts)).round();
      }
    }
    return score;
  }

  static int calculateActiveStreak(PredictionData data, List<WorldCupMatch> matches) {
    final playedMatches = matches.where((m) => m.isPlayed).toList()..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final match in playedMatches) {
      final pred = data.matchPredictions[match.id];
      if (pred == null) break;
      final actualOutcome = match.t1Score! > match.t2Score! ? 1 : (match.t1Score! < match.t2Score! ? -1 : 0);
      final predOutcome = pred.t1Score > pred.t2Score ? 1 : (pred.t1Score < pred.t2Score ? -1 : 0);
      if (actualOutcome == predOutcome) streak++; else break;
    }
    return streak;
  }

  static int calculateExactScoreCount(PredictionData data, List<WorldCupMatch> matches) {
    int count = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = data.matchPredictions[match.id];
        if (pred != null && match.t1Score == pred.t1Score && match.t2Score == pred.t2Score) count++;
      }
    }
    return count;
  }

  static int calculateExactGuessesCount(PredictionData data, List<WorldCupMatch> matches) => calculateExactScoreCount(data, matches);

  static Map<String, dynamic> getXpDetails(int totalPoints, String lang) {
    final xp = totalPoints;
    for (int i = kXpLevels.length - 1; i >= 0; i--) {
      final entry = kXpLevels[i];
      final minXp = entry['minXp'] as int;
      final maxXp = entry['maxXp'] as int?;
      if (xp >= minXp && (maxXp == null || xp < maxXp)) {
        return {
          'xp': xp,
          'level': entry['level'],
          'rankName': AppTranslations.get(lang, entry['rankKey']),
          'progress': maxXp == null ? 1.0 : ((xp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0),
          'nextLevelXp': entry['nextLevelXp'],
        };
      }
    }
    return {'xp': xp, 'level': 1, 'rankName': AppTranslations.get(lang, 'rankRookie'), 'progress': (xp / 100).clamp(0.0, 1.0), 'nextLevelXp': 100};
  }

  // ─── Group Management ──────────────────────────────────────────────────────

  static Future<void> createCustomGroup(String groupName) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    final groupId = firestore.collection('groups').doc().id;
    await firestore.collection('groups').doc(groupId).set({
      'name': groupName,
      'creatorId': uid,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _generateSmartInvite(groupId, uid);
  }

  static Future<String> _generateSmartInvite(String groupId, String creatorId) async {
    final firestore = FirebaseFirestore.instance;
    final token = const Uuid().v4().substring(0, 8);
    final inviteId = const Uuid().v4();
    await firestore.collection('invites').doc(inviteId).set({
      'groupId': groupId,
      'token': token,
      'creatorId': creatorId,
      'usesCount': 0,
      'maxUses': 100,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return '${inviteId}_$token';
  }

  static Future<String> getShareLink(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore.collection('invites').where('groupId', isEqualTo: groupId).limit(20).get();
      if (snapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        final docs = snapshot.docs.toList()..sort((a, b) {
          final tA = a.data()['createdAt'] as Timestamp? ?? Timestamp.now();
          final tB = b.data()['createdAt'] as Timestamp? ?? Timestamp.now();
          return tB.compareTo(tA);
        });
        for (final doc in docs) {
          final data = doc.data();
          if ((data['expiresAt'] as Timestamp).toDate().isAfter(now) && (data['usesCount'] as int) < (data['maxUses'] as int)) {
            return '${doc.id}_${data['token']}';
          }
        }
      }
    } catch (e) { debugPrint('Error fetching invite: $e'); }
    return await _generateSmartInvite(groupId, uid);
  }

  static Future<void> editCustomGroup(String groupId, String newName) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({'name': newName});
  }

  static Future<void> deleteCustomGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;
    final invites = await firestore.collection('invites').where('groupId', isEqualTo: groupId).get();
    final batch = firestore.batch();
    for (var doc in invites.docs) batch.delete(doc.reference);
    batch.delete(firestore.collection('groups').doc(groupId));
    await batch.commit();
  }

  static Future<void> leaveCustomGroup(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  static Future<bool> joinCustomGroup(String inviteCode) async {
    final parts = inviteCode.trim().split('_');
    if (parts.length != 2) return false;
    final inviteId = parts[0];
    final token = parts[1];
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    try {
      final inviteRef = firestore.collection('invites').doc(inviteId);
      final inviteSnap = await inviteRef.get();
      if (!inviteSnap.exists) return false;
      final inviteData = inviteSnap.data()!;
      if (inviteData['token'] != token || inviteData['usesCount'] >= inviteData['maxUses'] || (inviteData['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) return false;
      final groupId = inviteData['groupId'] as String;
      final groupRef = firestore.collection('groups').doc(groupId);
      final groupSnap = await groupRef.get();
      if (!groupSnap.exists) return false;
      final List<dynamic> members = groupSnap.data()!['members'] ?? [];
      if (members.contains(uid)) return true;
      final batch = firestore.batch();
      batch.update(inviteRef, {'usesCount': FieldValue.increment(1)});
      batch.update(groupRef, {'members': FieldValue.arrayUnion([uid])});
      await batch.commit();
      _sendJoinNotifications(groupId, members, uid);
      return true;
    } catch (e) { debugPrint('Join group error: $e'); return false; }
  }

  static Future<void> _sendJoinNotifications(String groupId, List<dynamic> memberIds, String newMemberUid) async {
    final firestore = FirebaseFirestore.instance;
    try {
      final groupSnap = await firestore.collection('groups').doc(groupId).get();
      final groupName = groupSnap.data()?['name'] ?? 'Group';
      final userDoc = await firestore.collection('users').doc(newMemberUid).get();
      final username = userDoc.data()?['username'] ?? 'Someone';
      for (final memberId in memberIds) {
        if (memberId != newMemberUid) {
          firestore.collection('users').doc(memberId as String).collection('notifications').add({
            'title': 'New Group Member', 'body': '$username joined $groupName!', 'createdAt': FieldValue.serverTimestamp(), 'read': false,
          });
        }
      }
    } catch (_) {}
  }

  static Future<List<FriendGroup>> loadChallengeGroups(PredictionData userData, List<WorldCupMatch> matches) async {
    final List<FriendGroup> groups = [];
    final userPoints = calculateTotalPoints(userData, matches);
    final userEmblem = userData.avatar.isNotEmpty ? userData.avatar : kUserEmblem;
    final uid = await WCFirebaseService.getOrCreateUserId();
    groups.add(FriendGroup(name: kGlobalGroupName, code: kGlobalGroupCode, members: [FriendScore(name: userData.username, points: userPoints, emblem: userEmblem, isUser: true, userId: uid)]));
    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore.collection('groups').where('members', arrayContains: uid).get();
    for (final doc in groupsSnapshot.docs) {
      final data = doc.data();
      final List<dynamic> memberIds = data['members'] ?? [];
      final List<FriendScore> members = [];
      for (final memberId in memberIds) {
        final isUser = memberId == uid;
        int points = 0; String mName = 'Unknown'; String mEmblem = '👤';
        if (isUser) { points = userPoints; mName = userData.username; mEmblem = userEmblem; }
        else {
          final userDoc = await firestore.collection('users').doc(memberId as String).get();
          if (userDoc.exists) { final uData = userDoc.data()!; points = uData['points'] ?? 0; mName = uData['username'] ?? 'Unknown'; mEmblem = uData['avatar'] ?? '👤'; }
        }
        members.add(FriendScore(name: mName, points: points, emblem: mEmblem, isUser: isUser, userId: memberId as String));
      }
      members.sort((a, b) => b.points.compareTo(a.points));
      groups.add(FriendGroup(name: data['name'] as String, code: doc.id, members: members, creatorId: data['creatorId'] as String? ?? ''));
    }
    return groups;
  }

  static String generateSharePayload(String inviteId, String token) => '${inviteId}_$token';
}
