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
  /// For knockout matches where the user predicts a draw at 90 min:
  /// which team code they predict wins in extra time.
  final String? extraTimeWinner;
  /// For knockout matches: true if the user predicts it goes to penalties.
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
  String avatar; // emoji avatar chosen by user
  String? championCode;
  String? goldenBootPlayer; // user's locked prediction of top scorer name
  String? goldenBootWinner; // set when official top scorer is confirmed
  String? supportedTeam;
  String? boosterMatchId;
  DateTime? championPredictedAt;
  DateTime? goldenBootPredictedAt;
  Map<String, MatchPrediction> matchPredictions;

  PredictionData({
    this.username = kDefaultUsername,
    this.avatar = '',
    this.championCode,
    this.goldenBootPlayer,
    this.goldenBootWinner,
    this.supportedTeam,
    this.boosterMatchId,
    this.championPredictedAt,
    this.goldenBootPredictedAt,
    Map<String, MatchPrediction>? matchPredictions,
  }) : matchPredictions = matchPredictions ?? {};

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    final Map<String, MatchPrediction> preds = {};
    if (json['preds'] != null) {
      final Map<String, dynamic> rawPreds = json['preds'] as Map<String, dynamic>;
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
      supportedTeam: json['supportedTeam'] as String?,
      boosterMatchId: json['boosterMatchId'] as String?,
      championPredictedAt: json['championPredictedAt'] != null ? DateTime.tryParse(json['championPredictedAt'] as String) : null,
      goldenBootPredictedAt: json['goldenBootPredictedAt'] != null ? DateTime.tryParse(json['goldenBootPredictedAt'] as String) : null,
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
      'supportedTeam': supportedTeam,
      'boosterMatchId': boosterMatchId,
      if (championPredictedAt != null) 'championPredictedAt': championPredictedAt!.toIso8601String(),
      if (goldenBootPredictedAt != null) 'goldenBootPredictedAt': goldenBootPredictedAt!.toIso8601String(),
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
  static const String _prefsKey       = kPredictionsKey;

  /// Save predictions to local storage
  static Future<void> savePredictionData(PredictionData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString(_prefsKey, jsonStr);
  }

  /// Load predictions from local storage
  static Future<PredictionData> loadPredictionData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final data = PredictionData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
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

  /// Reset predictions
  static Future<PredictionData> resetPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    return PredictionData();
  }

  /// Evaluate user prediction score for a single match.
  ///
  /// Scoring tiers:
  ///  Group stage  → exact=30, correct outcome=10
  ///  Knockout 90' → exact=40, correct outcome=15
  ///  Correct ET winner (cumulative)  → +20
  ///  Correct PK winner (cumulative)  → +25
  static int evaluatePoints(WorldCupMatch match, MatchPrediction pred) {
    if (!match.isPlayed) return 0;

    final actual1 = match.t1Score!;
    final actual2 = match.t2Score!;
    final pred1   = pred.t1Score;
    final pred2   = pred.t2Score;

    if (!match.isKnockout) {
      // ── Group stage ──────────────────────────────────────────────────────
      if (actual1 == pred1 && actual2 == pred2) return kExactScorePoints;
      final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
      final predOutcome   = pred1   > pred2   ? 1 : (pred1   < pred2   ? -1 : 0);
      if (actualOutcome == predOutcome) return kCorrectOutcomePoints;
      return 0;
    }

    // ── Knockout stage ───────────────────────────────────────────────────────
    // Exact 90-min scoreline
    if (actual1 == pred1 && actual2 == pred2) {
      int pts = kExactScoreKnockoutPoints;
      // Also credit ET/PK bonus if applicable
      pts += _evalKnockoutBeyond90(match, pred);
      return pts;
    }

    // Correct 90-min outcome (including "drew at 90 min" which then went to ET)
    final actual90Outcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
    final pred90Outcome   = pred1   > pred2   ? 1 : (pred1   < pred2   ? -1 : 0);
    if (actual90Outcome == pred90Outcome) {
      int pts = kCorrectOutcomeKnockoutPts;
      pts += _evalKnockoutBeyond90(match, pred);
      return pts;
    }

    return 0;
  }

  /// Calculates bonus points for correct ET / PK winner prediction.
  /// Called only when the 90-min outcome was correctly predicted.
  static int _evalKnockoutBeyond90(WorldCupMatch match, MatchPrediction pred) {
    int bonus = 0;

    // Extra time
    if (match.wentToET == true && match.etWinner != null) {
      if (pred.extraTimeWinner != null &&
          pred.extraTimeWinner!.toLowerCase() == match.etWinner!.toLowerCase()) {
        bonus += kExtraTimeBonusPoints;
      }
    }

    // Penalty shootout (independent bonus on top of ET bonus)
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
    
    if (predictedAt.isBefore(starts['kickoff']!)) {
      return 1.0;
    } else if (predictedAt.isBefore(starts['r32']!)) {
      return 0.8;
    } else if (predictedAt.isBefore(starts['r16']!)) {
      return 0.6;
    } else if (predictedAt.isBefore(starts['qf']!)) {
      return 0.4;
    } else if (predictedAt.isBefore(starts['sf']!)) {
      return 0.2;
    } else {
      return 0.0;
    }
  }

  static int getPotentialChampionPoints(DateTime? predictedAt, List<WorldCupMatch> matches) {
    final starts = getStageStartTimes(matches);
    final mult = getPenaltyMultiplier(predictedAt, starts);
    return (kChampionBonusPoints * mult).round();
  }

  static int getPotentialGoldenBootPoints(DateTime? predictedAt, List<WorldCupMatch> matches) {
    final starts = getStageStartTimes(matches);
    final mult = getPenaltyMultiplier(predictedAt, starts);
    return (kGoldenBootBonusPoints * mult).round();
  }

  /// Calculate user's total points across all matches (including bonus predictions).
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

    // Bonus: correct champion prediction
    final finalMatch = matches.firstWhere(
      (m) => m.id == kFinalMatchId,
      orElse: () => matches[0],
    );
    if (finalMatch.isPlayed && userPreds.championCode != null) {
      final actualChampion = finalMatch.t1Score! > finalMatch.t2Score!
          ? finalMatch.t1
          : finalMatch.t2;
      if (actualChampion.toLowerCase() == userPreds.championCode!.toLowerCase()) {
        final mult = getPenaltyMultiplier(userPreds.championPredictedAt, starts);
        score += (kChampionBonusPoints * mult).round();
      }
    }

    // Bonus: correct golden boot prediction (awarded when goldenBootWinner is set)
    final goldenBootWinner = userPreds.goldenBootWinner;
    if (goldenBootWinner != null &&
        goldenBootWinner.isNotEmpty &&
        userPreds.goldenBootPlayer != null &&
        userPreds.goldenBootPlayer!.isNotEmpty) {
      if (userPreds.goldenBootPlayer!.trim().toLowerCase() ==
          goldenBootWinner.trim().toLowerCase()) {
        final mult = getPenaltyMultiplier(userPreds.goldenBootPredictedAt, starts);
        score += (kGoldenBootBonusPoints * mult).round();
      }
    }

    return score;
  }

  /// Calculate current consecutive correct prediction outcome streak.
  static int calculateActiveStreak(PredictionData data, List<WorldCupMatch> matches) {
    final playedMatches = matches.where((m) => m.isPlayed).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    int streak = 0;
    for (final match in playedMatches) {
      final pred = data.matchPredictions[match.id];
      if (pred == null) break;

      final actual1 = match.t1Score!;
      final actual2 = match.t2Score!;
      final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
      final predOutcome   = pred.t1Score > pred.t2Score ? 1 : (pred.t1Score < pred.t2Score ? -1 : 0);

      if (actualOutcome == predOutcome) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculate count of exact score guesses
  static int calculateExactGuessesCount(PredictionData data, List<WorldCupMatch> matches) {
    int count = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = data.matchPredictions[match.id];
        if (pred != null &&
            match.t1Score == pred.t1Score &&
            match.t2Score == pred.t2Score) {
          count++;
        }
      }
    }
    return count;
  }



  /// Calculate total points for a friend (real or simulated)
  static int _calculateFriendPoints(
    String name,
    List<WorldCupMatch> matches,
    PredictionData creatorData,
  ) {
    int points = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = creatorData.matchPredictions[match.id];
        if (pred != null) points += evaluatePoints(match, pred);
      }
    }
    // Champion bonus
    final finalMatch = matches.firstWhere(
      (m) => m.id == kFinalMatchId,
      orElse: () => matches[0],
    );
    if (finalMatch.isPlayed && creatorData.championCode != null) {
      final actualChampion = finalMatch.t1Score! > finalMatch.t2Score!
          ? finalMatch.t1
          : finalMatch.t2;
      if (actualChampion.toLowerCase() == creatorData.championCode!.toLowerCase()) {
        points += kChampionBonusPoints;
      }
    }
    return points;
  }

  /// Get XP/level details for the user. Uses kXpLevels from app_constants.dart.
  static Map<String, dynamic> getXpDetails(int totalPoints, String lang) {
    final xp = totalPoints;

    // Walk the level table
    for (int i = kXpLevels.length - 1; i >= 0; i--) {
      final entry   = kXpLevels[i];
      final minXp   = entry['minXp'] as int;
      final maxXp   = entry['maxXp'] as int?;
      final level   = entry['level'] as int;
      final rankKey = entry['rankKey'] as String;
      final nextXp  = entry['nextLevelXp'] as int;

      if (xp >= minXp && (maxXp == null || xp < maxXp)) {
        final double progress = maxXp == null
            ? 1.0
            : ((xp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0);

        return {
          'xp': xp,
          'level': level,
          'rankName': AppTranslations.get(lang, rankKey),
          'progress': progress,
          'nextLevelXp': nextXp,
        };
      }
    }

    // Fallback (should never reach here)
    return {
      'xp': xp,
      'level': 1,
      'rankName': AppTranslations.get(lang, 'rankRookie'),
      'progress': (xp / 100).clamp(0.0, 1.0),
      'nextLevelXp': 100,
    };
  }

  /// Fetch user-created/joined challenge groups from Firestore.
  static Future<List<FriendGroup>> loadChallengeGroups(
    PredictionData userData,
    List<WorldCupMatch> matches,
  ) async {
    final List<FriendGroup> groups = [];
    final userPoints = calculateTotalPoints(userData, matches);
    final userEmblem = userData.avatar.isNotEmpty ? userData.avatar : kUserEmblem;

    // 1. Default global group (placeholder, UI fetches actual from Firestore stream if needed,
    //    or we can keep it local for just the user and let the leaderboard handle global)
    final globalMembers = <FriendScore>[
      FriendScore(name: userData.username, points: userPoints, emblem: userEmblem, isUser: true, userId: await WCFirebaseService.getOrCreateUserId()),
    ]..sort((a, b) => b.points.compareTo(a.points));

    groups.add(FriendGroup(
      name: kGlobalGroupName,
      code: kGlobalGroupCode,
      members: globalMembers,
    ));

    // 2. Fetch custom groups from Firestore
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore.collection('groups')
        .where('members', arrayContains: uid)
        .get();

    for (final doc in groupsSnapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String;
      final id = doc.id;
      final inviteToken = data['inviteToken'] as String? ?? '';
      final creatorId = data['creatorId'] as String? ?? '';

      final List<dynamic> memberIds = data['members'] ?? [];
      final List<FriendScore> members = [];

      // Fetch each member's points from the users collection
      for (final memberId in memberIds) {
        final isUser = memberId == uid;
        int points = 0;
        String mName = 'Unknown';
        String mEmblem = '👤';

        if (isUser) {
          points = userPoints;
          mName = userData.username;
          mEmblem = userEmblem;
        } else {
          final userDoc = await firestore.collection('users').doc(memberId as String).get();
          if (userDoc.exists) {
            final uData = userDoc.data()!;
            points = uData['points'] as int? ?? 0;
            mName = uData['username'] as String? ?? 'Unknown';
            mEmblem = uData['avatar'] as String? ?? '👤';
          }
        }
        members.add(FriendScore(name: mName, points: points, emblem: mEmblem, isUser: isUser, userId: memberId as String));
      }

      members.sort((a, b) => b.points.compareTo(a.points));
      groups.add(FriendGroup(
        name: name,
        code: id, // use Firestore ID as the base code
        members: members,
        inviteToken: inviteToken,
        creatorId: creatorId,
      ));
    }

    return groups;
  }

  /// Create a new custom prediction group
  static Future<void> createCustomGroup(String groupName) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;

    final token = const Uuid().v4().substring(0, 8); // secure invite token

    await firestore.collection('groups').add({
      'name': groupName,
      'creatorId': uid,
      'members': [uid],
      'inviteToken': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Edit a custom prediction group
  static Future<void> editCustomGroup(String groupId, String newName) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({'name': newName});
  }

  /// Delete a custom prediction group
  static Future<void> deleteCustomGroup(String groupId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).delete();
  }

  /// Leave a custom prediction group
  static Future<void> leaveCustomGroup(String groupId) async {
    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid])
    });
  }

  /// Join a group using an invite string (format: groupId_token)
  static Future<bool> joinCustomGroup(String inviteCode) async {
    final parts = inviteCode.trim().split('_');
    if (parts.length != 2) return false;

    final groupId = parts[0];
    final token = parts[1];

    final uid = await WCFirebaseService.getOrCreateUserId();
    final firestore = FirebaseFirestore.instance;

    final docRef = firestore.collection('groups').doc(groupId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data['inviteToken'] == token) {
        final List<dynamic> members = data['members'] ?? [];
        if (!members.contains(uid)) {
          await docRef.update({
            'members': FieldValue.arrayUnion([uid])
          });

          // Notify creator and other members
          final creatorId = data['creatorId'] as String;
          final groupName = data['name'] as String;
          final userDoc = await firestore.collection('users').doc(uid).get();
          final username = userDoc.data()?['username'] ?? 'Someone';

          for (final memberId in members) {
             if (memberId != uid) {
                 await firestore.collection('users').doc(memberId as String).collection('notifications').add({
                     'title': 'New Group Member',
                     'body': '$username joined $groupName!',
                     'createdAt': FieldValue.serverTimestamp(),
                     'read': false,
                 });
             }
          }
          return true;
        }
      }
    }
    return false;
  }

  /// Serialize a shareable invite link
  static String generateSharePayload(String groupId, String inviteToken) {
    return '${groupId}_$inviteToken';
  }
}