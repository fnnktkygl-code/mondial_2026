import 'dart:convert';
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
  final String? inviteToken;
  final String? creatorId;

  FriendGroup({
    required this.name,
    required this.code,
    required this.members,
    this.inviteToken,
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
        bool migrated = false;
        final keys = List<String>.from(data.matchPredictions.keys);
        for (final key in keys) {
          if (key.startsWith('m')) {
            final idNum = int.tryParse(key.substring(1));
            if (idNum != null && idNum <= kGroupMatchMaxIndex) {
              final pred = data.matchPredictions.remove(key);
              if (pred != null) {
                final newKey = '$kGroupMatchIdPrefix$key';
                data.matchPredictions[newKey] = MatchPrediction(
                  matchId: newKey,
                  t1Score: pred.t1Score,
                  t2Score: pred.t2Score,
                );
                migrated = true;
              }
            }
          }
        }
        if (migrated) {
          await savePredictionData(data);
        }
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
          pred.extraTimeWinner!.toLowerCase() == match.etWinner!.toLowerCase()) {
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

  // ─── Résultat du pronostic (centralisé ici, utilisé par tous les widgets) ───

  /// Retourne 'exact' | 'winner' | 'wrong' | null pour un match joué.
  static String? getPredictionResult(
    WorldCupMatch match,
    PredictionData? userPreds,
  ) {
    if (!match.isPlayed) return null;
    if (userPreds == null) return null;

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
        final mult = getPenaltyMultiplier(userPreds.championPredictedAt, starts);
        score += (kChampionBonusPoints * mult).round();
      }
    }

    final goldenBootWinner = userPreds.goldenBootWinner;
    if (goldenBootWinner != null &&
        goldenBootWinner.isNotEmpty &&
        userPreds.goldenBootPlayer != null &&
        userPreds.goldenBootPlayer!.isNotEmpty) {
      if (userPreds.goldenBootPlayer!.trim().toLowerCase() == goldenBootWinner.trim().toLowerCase()) {
        final mult = getPenaltyMultiplier(userPreds.goldenBootPredictedAt, starts);
        score += (kGoldenBootBonusPoints * mult).round();
      }
    }

    final topAssisterWinner = userPreds.topAssisterWinner;
    if (topAssisterWinner != null &&
        topAssisterWinner.isNotEmpty &&
        userPreds.topAssisterPlayer != null &&
        userPreds.topAssisterPlayer!.isNotEmpty) {
      if (userPreds.topAssisterPlayer!.trim().toLowerCase() == topAssisterWinner.trim().toLowerCase()) {
        final mult = getPenaltyMultiplier(userPreds.topAssisterPredictedAt, starts);
        score += (kTopAssisterBonusPoints * mult).round();
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
      final actual1 = match.t1Score!;
      final actual2 = match.t2Score!;
      final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
      final predOutcome = pred.t1Score > pred.t2Score ? 1 : (pred.t1Score < pred.t2Score ? -1 : 0);
      if (actualOutcome == predOutcome) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int calculateExactScoreCount(PredictionData data, List<WorldCupMatch> matches) {
    int count = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = data.matchPredictions[match.id];
        if (pred != null && match.t1Score == pred.t1Score && match.t2Score == pred.t2Score) {
          count++;
        }
      }
    }
    return count;
  }

  static int calculateExactGuessesCount(PredictionData data, List<WorldCupMatch> matches) => calculateExactScoreCount(data, matches);

  // ─── XP / Level ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> getXpDetails(int totalPoints, String lang) {
    final xp = totalPoints;
    for (int i = kXpLevels.length - 1; i >= 0; i--) {
      final entry = kXpLevels[i];
      final minXp = entry['minXp'] as int;
      final maxXp = entry['maxXp'] as int?;
      final level = entry['level'] as int;
      final rankKey = entry['rankKey'] as String;
      final nextXp = entry['nextLevelXp'] as int;

      if (xp >= minXp && (maxXp == null || xp < maxXp)) {
        final double progress = maxXp == null ? 1.0 : ((xp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0);
        return {
          'xp': xp,
          'level': level,
          'rankName': AppTranslations.get(lang, rankKey),
          'progress': progress,
          'nextLevelXp': nextXp,
        };
      }
    }
    return {
      'xp': xp,
      'level': 1,
      'rankName': AppTranslations.get(lang, 'rankRookie'),
      'progress': (xp / 100).clamp(0.0, 1.0),
      'nextLevelXp': 100,
    };
  }

  // ─── Groups (Firestore) ───────────────────────────────────────────────────────

  static Future<List<FriendGroup>> loadChallengeGroups(PredictionData userData, List<WorldCupMatch> matches) async {
    final List<FriendGroup> groups = [];
    final userPoints = calculateTotalPoints(userData, matches);
    final userEmblem = userData.avatar.isNotEmpty ? userData.avatar : kUserEmblem;
    final uid = await WCFirebaseService.getOrCreateUserId();

    groups.add(FriendGroup(
      name: kGlobalGroupName,
      code: kGlobalGroupCode,
      members: [FriendScore(name: userData.username, points: userPoints, emblem: userEmblem, isUser: true, userId: uid)],
    ));

    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore.collection('groups').where('members', arrayContains: uid).get();

    for (final doc in groupsSnapshot.docs) {
      final data = doc.data();
      final List<dynamic> memberIds = data['members'] ?? [];
      final List<FriendScore> members = [];
      for (final memberId in memberIds) {
        final isUser = memberId == uid;
        int points = 0; String mName = 'Unknown'; String mEmblem = '👤';
        if (isUser) {
          points = userPoints; mName = userData.username; mEmblem = userEmblem;
        } else {
          final userDoc = await firestore.collection('users').doc(memberId as String).get();
          if (userDoc.exists) {
            final uData = userDoc.data()!;
            points = uData['points'] ?? 0;
            mName = uData['username'] ?? 'Unknown';
            mEmblem = uData['avatar'] ?? '👤';
          }
        }
        members.add(FriendScore(name: mName, points: points, emblem: mEmblem, isUser: isUser, userId: memberId as String));
      }
      members.sort((a, b) => b.points.compareTo(a.points));
      groups.add(FriendGroup(
        name: data['name'] as String,
        code: doc.id,
        members: members,
        inviteToken: data['inviteToken'] as String?,
        creatorId: data['creatorId'] as String?,
      ));
    }
    return groups;
  }

  static Future<void> createCustomGroup(String groupName) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    final token = const Uuid().v4().substring(0, 8);
    await firestore.collection('groups').add({
      'name': groupName,
      'creatorId': uid,
      'members': [uid],
      'inviteToken': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> editCustomGroup(String groupId, String newName) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({'name': newName});
  }

  static Future<void> deleteCustomGroup(String groupId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
  }

  static Future<void> leaveCustomGroup(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({'members': FieldValue.arrayRemove([uid])});
  }

  static Future<bool> joinCustomGroup(String inviteCode) async {
    final parts = inviteCode.trim().split('_');
    if (parts.length != 2) return false;
    final groupId = parts[0]; final token = parts[1];
    final uid = await WCFirebaseService.getOrCreateUserId();
    final docRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data['inviteToken'] == token) {
        final List<dynamic> members = data['members'] ?? [];
        if (!members.contains(uid)) {
          await docRef.update({'members': FieldValue.arrayUnion([uid])});
          return true;
        }
      }
    }
    return false;
  }

  static String generateSharePayload(String inviteId, String token) => '${inviteId}_$token';

  static String getShareLink(String groupId, String inviteToken) {
    final payload = base64Url.encode(utf8.encode('${groupId}_$inviteToken'));
    return 'https://fnnktkygl-code.github.io/mondial_2026/app.html?group=$payload';
  }
}
