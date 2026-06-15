import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../app_constants.dart';
import '../l10n/translations.dart';
import 'firebase_service.dart';
import 'odds_service.dart';
import 'player_database_service.dart';

class MatchPrediction {
  final String matchId;
  final int t1Score;
  final int t2Score;
  final String? extraTimeWinner;
  final bool? penaltyWinner;
  final Map<String, int> predictedScorers;
  final bool outcomeOnly;

  MatchPrediction({
    required this.matchId,
    required this.t1Score,
    required this.t2Score,
    this.extraTimeWinner,
    this.penaltyWinner,
    Map<String, int>? predictedScorers,
    this.outcomeOnly = false,
  }) : predictedScorers = predictedScorers ?? {};

  factory MatchPrediction.fromJson(Map<String, dynamic> json) {
    Map<String, int> scorers = {};
    
    // Migration: Handle the old single string 'predictedScorer'
    if (json.containsKey('predictedScorer') && json['predictedScorer'] != null) {
      scorers[json['predictedScorer'] as String] = 1;
    }
    
    // Handle the new map structure
    if (json.containsKey('predictedScorers') && json['predictedScorers'] != null) {
      final map = json['predictedScorers'] as Map<String, dynamic>;
      map.forEach((k, v) => scorers[k] = v as int);
    }

    return MatchPrediction(
      matchId: json['matchId'] as String,
      t1Score: json['t1Score'] as int,
      t2Score: json['t2Score'] as int,
      extraTimeWinner: json['extraTimeWinner'] as String?,
      penaltyWinner: json['penaltyWinner'] as bool?,
      predictedScorers: scorers,
      outcomeOnly: json['outcomeOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      't1Score': t1Score,
      't2Score': t2Score,
      if (extraTimeWinner != null) 'extraTimeWinner': extraTimeWinner,
      if (penaltyWinner != null) 'penaltyWinner': penaltyWinner,
      if (predictedScorers.isNotEmpty) 'predictedScorers': predictedScorers,
      'outcomeOnly': outcomeOnly,
    };
  }
}

class PronounsHistoryItem {
  final String pronouns;
  final DateTime updatedAt;

  PronounsHistoryItem({required this.pronouns, required this.updatedAt});

  Map<String, dynamic> toJson() => {
    'pronouns': pronouns,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PronounsHistoryItem.fromJson(Map<String, dynamic> json) => PronounsHistoryItem(
    pronouns: json['pronouns'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class PredictionData {
  String username;
  String avatar;
  String? championCode;
  String? goldenBootPlayer;
  String? goldenBootWinner;
  String? supportedTeam;
  String? boosterMatchId; // Legacy
  List<String> boosterMatchIds;
  DateTime? championPredictedAt;
  DateTime? goldenBootPredictedAt;
  Map<String, MatchPrediction> matchPredictions;
  String? pronouns;
  List<PronounsHistoryItem> pronounsHistory;
  int? points;

  PredictionData({
    this.username = kDefaultUsername,
    this.avatar = '',
    this.championCode,
    this.goldenBootPlayer,
    this.goldenBootWinner,
    this.supportedTeam,
    this.boosterMatchId,
    List<String>? boosterMatchIds,
    this.championPredictedAt,
    this.goldenBootPredictedAt,
    Map<String, MatchPrediction>? preds,
    this.pronouns,
    List<PronounsHistoryItem>? pronounsHistory,
    this.points,
  })  : matchPredictions = preds ?? {},
        boosterMatchIds = boosterMatchIds ?? [],
        pronounsHistory = pronounsHistory ?? [];

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    final Map<String, MatchPrediction> preds = {};
    if (json['preds'] != null) {
      final Map<String, dynamic> rawPreds =
      json['preds'] as Map<String, dynamic>;
      rawPreds.forEach((key, val) {
        preds[key] = MatchPrediction.fromJson(val as Map<String, dynamic>);
      });
    }

    final List<String> parsedBoosters = [];
    if (json['boosterMatchIds'] != null) {
      final list = json['boosterMatchIds'] as List<dynamic>;
      parsedBoosters.addAll(list.map((e) => e.toString()));
    } else if (json['boosterMatchId'] != null) {
      // Migrate legacy booster
      parsedBoosters.add(json['boosterMatchId'].toString());
    }

    return PredictionData(
      username: json['username'] as String? ?? kDefaultUsername,
      avatar: json['avatar'] as String? ?? '',
      championCode: json['championCode'] as String?,
      goldenBootPlayer: json['goldenBootPlayer'] as String?,
      goldenBootWinner: json['goldenBootWinner'] as String?,
      supportedTeam: json['supportedTeam'] as String?,
      boosterMatchId: json['boosterMatchId'] as String?,
      boosterMatchIds: parsedBoosters,
      championPredictedAt: json['championPredictedAt'] != null
          ? DateTime.tryParse(json['championPredictedAt'] as String)
          : null,
      goldenBootPredictedAt: json['goldenBootPredictedAt'] != null
          ? DateTime.tryParse(json['goldenBootPredictedAt'] as String)
          : null,
      preds: preds,
      pronouns: json['pronouns'] as String?,
      pronounsHistory: json['pronounsHistory'] != null
          ? (json['pronounsHistory'] as List<dynamic>)
              .map((e) => PronounsHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      points: json['points'] as int?,
    );
  }

  factory PredictionData.fromFirestore(Map<String, dynamic> json) {
    final Map<String, MatchPrediction> preds = {};
    // Firestore uses 'predictions' key
    final Map<String, dynamic> rawPreds = json['predictions'] as Map<String, dynamic>? ?? {};
    rawPreds.forEach((key, val) {
      preds[key] = MatchPrediction.fromJson(Map<String, dynamic>.from(val));
    });

    final List<String> parsedBoosters = [];
    if (json['boosterMatchIds'] != null) {
      final list = json['boosterMatchIds'] as List<dynamic>;
      parsedBoosters.addAll(list.map((e) => e.toString()));
    }

    return PredictionData(
      username: json['username'] as String? ?? 'User',
      avatar: json['avatar'] as String? ?? '',
      championCode: json['championCode'] as String?,
      goldenBootPlayer: json['goldenBootPlayer'] as String?,
      goldenBootWinner: json['goldenBootWinner'] as String?,
      supportedTeam: json['supportedTeam'] as String?,
      boosterMatchIds: parsedBoosters,
      preds: preds,
      pronouns: json['pronouns'] as String?,
      pronounsHistory: json['pronounsHistory'] != null
          ? (json['pronounsHistory'] as List<dynamic>)
              .map((e) => PronounsHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      points: json['points'] as int?,
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
      'boosterMatchIds': boosterMatchIds,
      if (championPredictedAt != null)
        'championPredictedAt': championPredictedAt!.toIso8601String(),
      if (goldenBootPredictedAt != null)
        'goldenBootPredictedAt': goldenBootPredictedAt!.toIso8601String(),
      'preds': predsJson,
      'pronouns': pronouns,
      'pronounsHistory': pronounsHistory.map((e) => e.toJson()).toList(),
      if (points != null) 'points': points,
    };
  }
}

class FriendScore {
  final String name;
  final int points;
  final String emblem;
  final bool isUser;
  final String? userId;
  final int rank;

  FriendScore({
    required this.name,
    required this.points,
    required this.emblem,
    this.isUser = false,
    this.userId,
    this.rank = 0,
  });
}

class FriendGroup {
  final String name;
  final String code;
  final List<FriendScore> members;
  final String? inviteToken;
  final String? creatorId;
  final int? globalRank; // Added

  FriendGroup({
    required this.name,
    required this.code,
    required this.members,
    this.inviteToken,
    this.creatorId,
    this.globalRank, // Added
  });
}

class PredictionService {
  static const String _prefsKey = kPredictionsKey;

  // ─── Storage & Locking ──────────────────────────────────────────────────────

  static bool isPredictionLocked(WorldCupMatch match) {
    if (match.status == 'IN_PLAY' || match.status == 'FINISHED' || match.status == 'PAUSED') {
      return true;
    }

    final now = DateTime.now().toUtc();
    if (now.isAfter(match.date.subtract(const Duration(minutes: 5)))) {
      return true;
    }
    return false;
  }

  static bool isTournamentPredictionLocked(List<WorldCupMatch> matches) {
    try {
      final firstKnockoutMatch = matches.firstWhere((m) => m.isKnockout);
      return isPredictionLocked(firstKnockoutMatch);
    } catch (e) {
      return true; // Fallback sécurisé
    }
  }

  static Future<bool> saveMatchPrediction(WorldCupMatch match, PredictionData currentData, MatchPrediction newPrediction) async {
    if (isPredictionLocked(match)) {
      return false;
    }
    currentData.matchPredictions[match.id] = newPrediction;
    await savePredictionData(currentData);
    return true;
  }

  static Future<void> savePredictionData(PredictionData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString(_prefsKey, jsonStr);

    // Sync to Firestore for persistence
    try {
      final uid = await WCFirebaseService.getOrCreateUserId();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'predictions': data.matchPredictions.map((key, value) => MapEntry(key, value.toJson())),
        'championCode': data.championCode,
        'goldenBootPlayer': data.goldenBootPlayer,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error syncing predictions to Firestore: $e");
    }
  }

  static Future<PredictionData> loadPredictionData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    PredictionData? localData;

    if (jsonStr != null) {
      try {
        localData = PredictionData.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );
        
        bool migrated = false;
        final keys = List<String>.from(localData.matchPredictions.keys);
        for (final key in keys) {
          if (key.startsWith('m')) {
            final idNum = int.tryParse(key.substring(1));
            if (idNum != null && idNum <= kGroupMatchMaxIndex) {
              final pred = localData.matchPredictions.remove(key);
              if (pred != null) {
                final newKey = '$kGroupMatchIdPrefix$key';
                localData.matchPredictions[newKey] = MatchPrediction(
                  matchId: newKey,
                  t1Score: pred.t1Score,
                  t2Score: pred.t2Score,
                  predictedScorers: pred.predictedScorers,
                );
                migrated = true;
              }
            }
          }
        }
        if (migrated) {
          await savePredictionData(localData);
        }
      } catch (_) {}
    }

    // Attempt to merge with Firestore
    try {
      final uid = await WCFirebaseService.getOrCreateUserId();
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final remoteJson = doc.data()!;
        final remotePreds = remoteJson['predictions'] as Map<String, dynamic>? ?? {};
        
        final finalData = localData ?? PredictionData(
          username: remoteJson['username'] ?? 'User',
          avatar: remoteJson['avatar'] ?? 'assets/avatars/1.png',
          supportedTeam: remoteJson['supportedTeam'],
        );

        // Merge logic: prefer local but fill missing from remote
        remotePreds.forEach((key, value) {
          if (!finalData.matchPredictions.containsKey(key)) {
            finalData.matchPredictions[key] = MatchPrediction.fromJson(Map<String, dynamic>.from(value));
          }
        });

        finalData.championCode ??= remoteJson['championCode'];
        finalData.goldenBootPlayer ??= remoteJson['goldenBootPlayer'];
        
        localData = finalData;
      }
    } catch (e) {
      debugPrint("Error loading predictions from Firestore: $e");
    }

    return localData ?? PredictionData();
  }

  static Future<PredictionData> resetPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    return PredictionData();
  }

  // ─── Scoring ─────────────────────────────────────────────────────────────────

  static String getMatchPhase(WorldCupMatch match, List<WorldCupMatch> allMatches) {
    if (!match.isKnockout) {
      // Filter group stage matches
      final groupMatches = allMatches.where((m) => !m.isKnockout).toList();
      // Sort chronologically by date
      groupMatches.sort((a, b) => a.date.compareTo(b.date));
      // Find the index of the current match
      final index = groupMatches.indexWhere((m) => m.id == match.id);
      if (index == -1) {
        return 'group_1'; // fallback
      }
      if (index < 24) return 'group_1';
      if (index < 48) return 'group_2';
      return 'group_3';
    }
    // Knockout phases
    final stg = match.stage;
    if (stg == 'Round of 32') return 'round_32';
    if (stg == 'Round of 16') return 'round_16';
    if (stg == 'Quarter-Final') return 'quarter';
    if (stg == 'Semi-Final') return 'semi';
    return 'final'; // For 'Final' and 'Play-off for third place'
  }

  static int getAvailableBoostersForPhase(String phase) {
    return 1; // 1 joker for each phase/session
  }

  static int evaluatePoints(WorldCupMatch match, MatchPrediction pred) {
    if (!match.isPlayed || match.t1Score == null || match.t2Score == null) return 0;

    final actual1 = match.t1Score90 ?? match.t1Score!;
    final actual2 = match.t2Score90 ?? match.t2Score!;
    final pred1 = pred.t1Score;
    final pred2 = pred.t2Score;

    final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
    final predOutcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
    final bool isOutcomeCorrect = (actualOutcome == predOutcome);
    final bool isScoreExact = (actual1 == pred1 && actual2 == pred2);
    
    // Retrieve decimal odds from odds service (1X2)
    final odds = WCOddsService.calculateMatchOdds(match.t1, match.t2);
    double rawOddsMultiplier = 1.0;
    if (predOutcome == 1) {
      rawOddsMultiplier = odds['1'] ?? 1.0;
    } else if (predOutcome == -1) {
      rawOddsMultiplier = odds['2'] ?? 1.0;
    } else {
      rawOddsMultiplier = odds['X'] ?? 1.0;
    }
    
    // Cap the odds multiplier to prevent over-scaling on extreme underdogs
    final double oddsMultiplier = rawOddsMultiplier.clamp(1.0, kMaxOddsMultiplier);

    double totalMatchPoints = 0.0;

    if (isOutcomeCorrect) {
      // 1. Base Outcome (Multiplied by outcome odds to reward risk)
      totalMatchPoints += kCorrectOutcomePoints * oddsMultiplier;

      // In outcomeOnly mode, we stop here for the match score part
      if (!pred.outcomeOnly) {
        // 2. Goal Difference (GD) Bonus (Multiplied by outcome odds)
        final actualGD = (actual1 - actual2).abs();
        final predGD = (pred1 - pred2).abs();
        if (actualGD == predGD) {
          double gdPoints = 0;
          if (actualGD == 0) { gdPoints = kGdDiff0Points.toDouble(); }
          else if (actualGD == 1) { gdPoints = kGdDiff1Points.toDouble(); }
          else if (actualGD == 2) { gdPoints = kGdDiff2Points.toDouble(); }
          else if (actualGD == 3) { gdPoints = kGdDiff3Points.toDouble(); }
          else if (actualGD >= 4) { gdPoints = kGdDiff4Points.toDouble(); }
          
          totalMatchPoints += gdPoints * oddsMultiplier;
        }

        // 3. Exact Score "Summum" Bonus (Multiplied by odds and score risk/rarity factor)
        if (isScoreExact) {
          // High goals and high difference increase correct score rarity/risk
          final double scoreRiskFactor = 1.0 + ((pred1 - pred2).abs() * 0.40) + ((pred1 + pred2) * 0.20);
          totalMatchPoints += kExactScoreBonus * oddsMultiplier * scoreRiskFactor;
        }
        
        // 4. Total Goals Bonus (if not exact score but same total; scaled by odds)
        if (!isScoreExact && (actual1 + actual2 == pred1 + pred2)) {
          totalMatchPoints += kTotalGoalsBonus * oddsMultiplier;
        }
      }
    }

    // ── Scorer bonus (Exponential & scaled by team odds) ──
    double scorerBonus = 0.0;
    // In outcomeOnly mode, we don't have scorers
    if (!pred.outcomeOnly && pred.predictedScorers.isNotEmpty) {
      final actualGoalCounts = <String, int>{};
      for (final goal in match.goals) {
        if (goal.isOwnGoal) continue;
        final key = goal.scorer.trim().toLowerCase();
        actualGoalCounts[key] = (actualGoalCounts[key] ?? 0) + 1;
      }

      pred.predictedScorers.forEach((predictedName, predictedCount) {
        int actualCount = 0;
        String? actualScorerName;
        for (final entry in actualGoalCounts.entries) {
          if (isSamePlayer(entry.key, predictedName)) {
            actualCount = entry.value;
            actualScorerName = entry.key;
            break;
          }
        }
        
        if (actualCount > 0 && actualScorerName != null) {
          final goalEvent = match.goals.firstWhere(
            (g) => isSamePlayer(g.scorer, actualScorerName), 
            orElse: () => GoalEvent(team: 't1', scorer: '', minute: 0)
          );
          final teamStr = goalEvent.team == 't1' ? match.t1 : match.t2;
          final position = PlayerDatabaseService.getPlayerPosition(AppTranslations.getTeam('en', teamStr), actualScorerName);
          
          double ptsPerGoal = kScorerBonusMidfielder.toDouble();
          if (position == 'Forwards') { ptsPerGoal = kScorerBonusForward.toDouble(); }
          else if (position == 'Defenders' || position == 'Goalkeepers') { ptsPerGoal = kScorerBonusDefenderOrGK.toDouble(); }
          
          // Get the decimal odds of the team scoring (home team -> '1', away team -> '2') and cap it
          final double rawTeamOdds = goalEvent.team == 't1' ? (odds['1'] ?? 1.0) : (odds['2'] ?? 1.0);
          final double teamOdds = rawTeamOdds.clamp(1.0, kMaxOddsMultiplier);
          double currentScorerPoints = ptsPerGoal * teamOdds;
          
          // Exponential: Exact goal count bonus (scaled by team odds)
          if (actualCount == predictedCount) {
            // New logic: bonus depends on the number of goals
            final int bonusIndex = actualCount.clamp(0, kScorerExactCountBonusByGoals.length - 1);
            currentScorerPoints += kScorerExactCountBonusByGoals[bonusIndex] * teamOdds;
          }
          
          scorerBonus += currentScorerPoints;
        }
      });
    }

    // ── Outsider bonus (flat) ──
    double outsiderBonus = 0.0;
    if (isOutcomeCorrect) {
      double prob = 1.0 / rawOddsMultiplier;
      if (prob < kOutsiderProbabilityThreshold) {
        outsiderBonus = kOutsiderBonusPoints.toDouble();
      }
    }

    double finalScore = totalMatchPoints + scorerBonus + outsiderBonus;

    // Knockout Stage Multiplier
    if (match.isKnockout) {
      finalScore *= kKnockoutMultiplier;
      
      // Extra Time / Penalties Bonuses (scaled by outcome odds)
      if (match.wentToET == true && pred.extraTimeWinner != null && match.etWinner == pred.extraTimeWinner) {
        finalScore += kExtraTimeBonusPoints * oddsMultiplier;
      }
      if (match.wentToPK == true && match.pkWinner != null) {
        final bool predT1WinsPK = pred.penaltyWinner == true;
        final bool actualT1WinsPK = match.pkWinner!.toLowerCase() == match.t1.toLowerCase();
        if (pred.penaltyWinner != null && predT1WinsPK == actualT1WinsPK) {
          finalScore += kPenaltyShootoutBonusPoints * oddsMultiplier;
        }
      }
    }

    return finalScore.round();
  }

  static int evaluatePointsWithBooster(WorldCupMatch match, MatchPrediction pred, bool isBoosterActive) {
    int pointsEarned = evaluatePoints(match, pred);
    if (isBoosterActive && match.isPlayed && match.t1Score != null && match.t2Score != null) {
      final actual1 = match.t1Score90 ?? match.t1Score!;
      final actual2 = match.t2Score90 ?? match.t2Score!;
      final pred1 = pred.t1Score;
      final pred2 = pred.t2Score;

      final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
      final predOutcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
      final bool isScoreExact = (actual1 == pred1 && actual2 == pred2);
      final bool isOutcomeCorrect = (actualOutcome == predOutcome);

      if (isScoreExact) {
        pointsEarned = (pointsEarned * 2.0).round();
      } else if (isOutcomeCorrect) {
        pointsEarned = (pointsEarned * 1.5).round();
      }
    }
    return pointsEarned;
  }

  static Map<String, dynamic> evaluatePointsBreakdown(WorldCupMatch match, MatchPrediction pred, bool isBoosterActive) {
    if (!match.isPlayed || match.t1Score == null || match.t2Score == null) {
      return {
        'outcomePoints': 0.0,
        'gdPoints': 0.0,
        'exactScorePoints': 0.0,
        'totalGoalsPoints': 0.0,
        'outsiderPoints': 0.0,
        'scorerPoints': 0.0,
        'scorerBreakdown': <String, double>{},
        'extraTimePoints': 0.0,
        'penaltyPoints': 0.0,
        'knockoutMultiplier': 1.0,
        'boosterMultiplier': 1.0,
        'totalPoints': 0,
        'oddsMultiplier': 1.0,
        'isOutcomeCorrect': false,
        'isScoreExact': false,
        'isBoosterActive': isBoosterActive,
        'outcomeText': '',
      };
    }

    final actual1 = match.t1Score90 ?? match.t1Score!;
    final actual2 = match.t2Score90 ?? match.t2Score!;
    final pred1 = pred.t1Score;
    final pred2 = pred.t2Score;

    final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
    final predOutcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
    final bool isOutcomeCorrect = (actualOutcome == predOutcome);
    final bool isScoreExact = (actual1 == pred1 && actual2 == pred2);
    
    // Retrieve decimal odds from odds service (1X2)
    final odds = WCOddsService.calculateMatchOdds(match.t1, match.t2);
    double rawOddsMultiplier = 1.0;
    String outcomeText = '';
    if (predOutcome == 1) {
      rawOddsMultiplier = odds['1'] ?? 1.0;
      outcomeText = '1';
    } else if (predOutcome == -1) {
      rawOddsMultiplier = odds['2'] ?? 1.0;
      outcomeText = '2';
    } else {
      rawOddsMultiplier = odds['X'] ?? 1.0;
      outcomeText = 'N';
    }

    final double oddsMultiplier = rawOddsMultiplier.clamp(1.0, kMaxOddsMultiplier);

    double outcomePoints = 0.0;
    double gdPoints = 0.0;
    double exactScorePoints = 0.0;
    double totalGoalsPoints = 0.0;

    if (isOutcomeCorrect) {
      // 1. Base Outcome
      outcomePoints = kCorrectOutcomePoints * oddsMultiplier;

      if (!pred.outcomeOnly) {
        // 2. Goal Difference (GD) Bonus
        final actualGD = (actual1 - actual2).abs();
        final predGD = (pred1 - pred2).abs();
        if (actualGD == predGD) {
          double gdBase = 0;
          if (actualGD == 0) { gdBase = kGdDiff0Points.toDouble(); }
          else if (actualGD == 1) { gdBase = kGdDiff1Points.toDouble(); }
          else if (actualGD == 2) { gdBase = kGdDiff2Points.toDouble(); }
          else if (actualGD == 3) { gdBase = kGdDiff3Points.toDouble(); }
          else if (actualGD >= 4) { gdBase = kGdDiff4Points.toDouble(); }
          
          gdPoints = gdBase * oddsMultiplier;
        }

        // 3. Exact Score Bonus
        if (isScoreExact) {
          final double scoreRiskFactor = 1.0 + ((pred1 - pred2).abs() * 0.40) + ((pred1 + pred2) * 0.20);
          exactScorePoints = kExactScoreBonus * oddsMultiplier * scoreRiskFactor;
        }
        
        // 4. Total Goals Bonus
        if (!isScoreExact && (actual1 + actual2 == pred1 + pred2)) {
          totalGoalsPoints = kTotalGoalsBonus * oddsMultiplier;
        }
      }
    }

    // Scorer Bonus
    double scorerPoints = 0.0;
    final Map<String, double> scorerBreakdown = <String, double>{};
    if (!pred.outcomeOnly && pred.predictedScorers.isNotEmpty) {
      final actualGoalCounts = <String, int>{};
      for (final goal in match.goals) {
        if (goal.isOwnGoal) continue;
        final key = goal.scorer.trim().toLowerCase();
        actualGoalCounts[key] = (actualGoalCounts[key] ?? 0) + 1;
      }

      pred.predictedScorers.forEach((predictedName, predictedCount) {
        int actualCount = 0;
        String? actualScorerName;
        for (final entry in actualGoalCounts.entries) {
          if (isSamePlayer(entry.key, predictedName)) {
            actualCount = entry.value;
            actualScorerName = entry.key;
            break;
          }
        }
        
        if (actualCount > 0 && actualScorerName != null) {
          final goalEvent = match.goals.firstWhere(
            (g) => isSamePlayer(g.scorer, actualScorerName), 
            orElse: () => GoalEvent(team: 't1', scorer: '', minute: 0)
          );
          final teamStr = goalEvent.team == 't1' ? match.t1 : match.t2;
          final position = PlayerDatabaseService.getPlayerPosition(AppTranslations.getTeam('en', teamStr), actualScorerName);
          
          double ptsPerGoal = kScorerBonusMidfielder.toDouble();
          if (position == 'Forwards') { ptsPerGoal = kScorerBonusForward.toDouble(); }
          else if (position == 'Defenders' || position == 'Goalkeepers') { ptsPerGoal = kScorerBonusDefenderOrGK.toDouble(); }
          
          final double rawTeamOdds = goalEvent.team == 't1' ? (odds['1'] ?? 1.0) : (odds['2'] ?? 1.0);
          final double teamOdds = rawTeamOdds.clamp(1.0, kMaxOddsMultiplier);
          double currentScorerPoints = ptsPerGoal * teamOdds;
          
          if (actualCount == predictedCount) {
            final int bonusIndex = actualCount.clamp(0, kScorerExactCountBonusByGoals.length - 1);
            currentScorerPoints += kScorerExactCountBonusByGoals[bonusIndex] * teamOdds;
          }
          
          scorerBreakdown[predictedName] = currentScorerPoints;
          scorerPoints += currentScorerPoints;
        }
      });
    }

    // Outsider Bonus (flat)
    double outsiderPoints = 0.0;
    if (isOutcomeCorrect) {
      double prob = 1.0 / rawOddsMultiplier;
      if (prob < kOutsiderProbabilityThreshold) {
        outsiderPoints = kOutsiderBonusPoints.toDouble();
      }
    }

    double extraTimePoints = 0.0;
    double penaltyPoints = 0.0;
    double knockoutMultiplier = 1.0;

    double matchSubtotal = outcomePoints + gdPoints + exactScorePoints + totalGoalsPoints + outsiderPoints + scorerPoints;

    if (match.isKnockout) {
      knockoutMultiplier = kKnockoutMultiplier;
      matchSubtotal *= knockoutMultiplier;
      
      if (match.wentToET == true && pred.extraTimeWinner != null && match.etWinner == pred.extraTimeWinner) {
        extraTimePoints = kExtraTimeBonusPoints * oddsMultiplier;
      }
      if (match.wentToPK == true && match.pkWinner != null) {
        final bool predT1WinsPK = pred.penaltyWinner == true;
        final String predPKWinner = predT1WinsPK ? match.t1 : match.t2;
        if (predPKWinner.toLowerCase() == match.pkWinner!.toLowerCase()) {
          penaltyPoints = kPenaltyShootoutBonusPoints * oddsMultiplier;
        }
      }
    }

    double finalScore = matchSubtotal + extraTimePoints + penaltyPoints;

    double boosterMultiplier = 1.0;
    if (isBoosterActive) {
      if (isScoreExact) {
        boosterMultiplier = 2.0;
        finalScore *= 2.0;
      } else if (isOutcomeCorrect) {
        boosterMultiplier = 1.5;
        finalScore *= 1.5;
      }
    }

    return {
      'outcomePoints': outcomePoints,
      'gdPoints': gdPoints,
      'exactScorePoints': exactScorePoints,
      'totalGoalsPoints': totalGoalsPoints,
      'outsiderPoints': outsiderPoints,
      'scorerPoints': scorerPoints,
      'scorerBreakdown': scorerBreakdown,
      'extraTimePoints': extraTimePoints,
      'penaltyPoints': penaltyPoints,
      'knockoutMultiplier': knockoutMultiplier,
      'boosterMultiplier': boosterMultiplier,
      'totalPoints': finalScore.round(),
      'oddsMultiplier': oddsMultiplier,
      'isOutcomeCorrect': isOutcomeCorrect,
      'isScoreExact': isScoreExact,
      'isBoosterActive': isBoosterActive,
      'outcomeText': outcomeText,
    };
  }


  // ─── Résultat du pronostic ───

  static String? getPredictionResult(
      WorldCupMatch match,
      PredictionData? userPreds,
      ) {
    if (!match.isPlayed || match.t1Score == null || match.t2Score == null) return null;
    if (userPreds == null) return null;

    final pred = userPreds.matchPredictions[match.id];
    if (pred == null) return null;

    final actual1 = match.t1Score90 ?? match.t1Score!;
    final actual2 = match.t2Score90 ?? match.t2Score!;

    final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
    final predOutcome = pred.t1Score > pred.t2Score ? 1 : (pred.t1Score < pred.t2Score ? -1 : 0);

    if (pred.outcomeOnly) {
      return actualOutcome == predOutcome ? 'winner' : 'wrong';
    }

    // 1. Check for exact score
    if (pred.t1Score == actual1 && pred.t2Score == actual2) {
      if (!match.isKnockout) return 'exact';
      if (actual1 != actual2) return 'exact';

      String predictedWinner = '';
      if (pred.extraTimeWinner != null) {
        predictedWinner = pred.extraTimeWinner!;
      } else if (pred.t1Score > pred.t2Score) {
        predictedWinner = match.t1;
      } else if (pred.t2Score > pred.t1Score) {
        predictedWinner = match.t2;
      }

      if (predictedWinner.toLowerCase() == match.getWinner().toLowerCase()) return 'exact';
      return 'winner';
    }

    // 2. Check for correct winner
    final actualWinner = match.getWinner().toLowerCase();
    String predictedWinner = '';
    if (pred.extraTimeWinner != null) {
      predictedWinner = pred.extraTimeWinner!;
    } else if (pred.t1Score > pred.t2Score) {
      predictedWinner = match.t1;
    } else if (pred.t2Score > pred.t1Score) {
      predictedWinner = match.t2;
    }

    if (predictedWinner.toLowerCase() == actualWinner && actualWinner.isNotEmpty) {
      return 'winner';
    }

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

  static String normalizePlayerName(String name) {
    String normalized = name.trim().toLowerCase();
    const accents = 'àáâãäåòóôõöøèéêëìíîïùúûüñç';
    const without = 'aaaaaaooooooeeeeiiiiuuuunc';
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], without[i]);
    }
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static bool isSamePlayer(String? nameA, String? nameB) {
    if (nameA == null || nameB == null) return false;
    if (nameA.isEmpty || nameB.isEmpty) return false;

    final nA = normalizePlayerName(nameA);
    final nB = normalizePlayerName(nameB);

    if (nA == nB) return true;

    final partsA = nA.split(' ');
    final partsB = nB.split(' ');

    final bool aIsShort = partsA.any((p) => p.length == 1);
    final bool bIsShort = partsB.any((p) => p.length == 1);

    if (aIsShort || bIsShort) {
      final shortParts = aIsShort ? partsA : partsB;
      final longParts = aIsShort ? partsB : partsA;

      final lastNameShort = shortParts.last;
      final lastNameLong = longParts.last;

      if (lastNameShort == lastNameLong) {
        final initial = shortParts.first;
        final longFirstName = longParts.first;
        if (longFirstName.startsWith(initial)) {
          return true;
        }
      }
    }

    if (nA.length > 4 && nB.length > 4) {
      if (nA.contains(nB) || nB.contains(nA)) return true;
    }

    return false;
  }

  static bool isScorerPredictionCorrect(String? player, List<WorldCupMatch> matches) {
    if (player == null || player.isEmpty) return false;
    final stats = TournamentStats.compute(matches);
    if (stats.scorers.isEmpty) return false;
    final maxGoals = stats.scorers.first.value;
    final winners = stats.scorers.where((s) => s.value == maxGoals).map((s) => s.name).toList();
    return winners.any((w) => isSamePlayer(w, player));
  }

  static int calculateTotalPoints(PredictionData userPreds, List<WorldCupMatch> matches) {
    int score = 0;
    for (final match in matches) {
      if (match.isPlayed) {
        final pred = userPreds.matchPredictions[match.id];
        if (pred != null) {
          int matchPoints = evaluatePoints(match, pred);
          
          // Apply Booster Logic (Joker)
          bool isBoosterActive = userPreds.boosterMatchId == match.id || userPreds.boosterMatchIds.contains(match.id);
          if (isBoosterActive) {
            final actual1 = match.t1Score90 ?? match.t1Score!;
            final actual2 = match.t2Score90 ?? match.t2Score!;
            final pred1 = pred.t1Score;
            final pred2 = pred.t2Score;

            final actualOutcome = actual1 > actual2 ? 1 : (actual1 < actual2 ? -1 : 0);
            final predOutcome = pred1 > pred2 ? 1 : (pred1 < pred2 ? -1 : 0);
            final bool isScoreExact = (actual1 == pred1 && actual2 == pred2);
            final bool isOutcomeCorrect = (actualOutcome == predOutcome);

            if (isScoreExact) {
              matchPoints = (matchPoints * 2.0).round();
            } else if (isOutcomeCorrect) {
              matchPoints = (matchPoints * 1.5).round();
            }
            // No penalty for a wrong prediction
          }
          
          score += matchPoints;
        }
      }
    }

    final starts = getStageStartTimes(matches);
    final finalMatch = matches.firstWhere((m) => m.id == kFinalMatchId, orElse: () => matches[0]);
    if (finalMatch.isPlayed && userPreds.championCode != null && finalMatch.t1Score != null && finalMatch.t2Score != null) {
      final actualChampion = finalMatch.t1Score! > finalMatch.t2Score! ? finalMatch.t1 : finalMatch.t2;
      if (actualChampion.toLowerCase() == userPreds.championCode!.toLowerCase()) {
        final mult = getPenaltyMultiplier(userPreds.championPredictedAt, starts);
        score += (kChampionBonusPoints * mult).round();
      }
    }

    final stats = TournamentStats.compute(matches);
    if (userPreds.goldenBootPlayer != null && userPreds.goldenBootPlayer!.isNotEmpty && stats.scorers.isNotEmpty) {
      final maxGoals = stats.scorers.first.value;
      final topScorers = stats.scorers.where((s) => s.value == maxGoals).map((s) => s.name.toLowerCase().trim()).toList();

      if (topScorers.contains(userPreds.goldenBootPlayer!.toLowerCase().trim())) {
        final mult = getPenaltyMultiplier(userPreds.goldenBootPredictedAt, starts);
        score += (kGoldenBootBonusPoints * mult).round();
      }
    }

    return score;
  }

  static int calculateActiveStreak(PredictionData data, List<WorldCupMatch> matches) {
    final playedMatches = matches.where((m) => m.isPlayed).toList()..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final match in playedMatches) {
      final pred = data.matchPredictions[match.id];
      if (pred == null || match.t1Score == null || match.t2Score == null) break;

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
      if (match.isPlayed && match.t1Score != null && match.t2Score != null) {
        final pred = data.matchPredictions[match.id];
        if (pred != null && !pred.outcomeOnly && match.t1Score == pred.t1Score && match.t2Score == pred.t2Score) {
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

  static Future<List<FriendGroup>> loadChallengeGroups(
      PredictionData userData,
      List<WorldCupMatch> matches,
      ) async {
    final List<FriendGroup> groups = [];
    final userPoints = calculateTotalPoints(userData, matches);
    final userEmblem =
    userData.avatar.isNotEmpty ? userData.avatar : kUserEmblem;
    final uid = await WCFirebaseService.getOrCreateUserId().timeout(
      const Duration(seconds: 5),
      onTimeout: () => 'anonymous_timeout',
    );

    final firestore = FirebaseFirestore.instance;
    
    // 1. Setup Global Group with REAL data
    int globalRank = 1;
    final List<FriendScore> globalMembers = [];
    final List<FriendScore> tempGlobalMembers = [];
    
    if (uid != 'anonymous_timeout') {
      try {
        // Get true global rank
        final rankSnap = await firestore
            .collection('users')
            .where('points', isGreaterThan: userPoints)
            .count()
            .get()
            .timeout(const Duration(seconds: 3));
        globalRank = (rankSnap.count ?? 0) + 1;

        // Get top 3 global players
        final topSnap = await firestore
            .collection('users')
            .orderBy('points', descending: true)
            .limit(3)
            .get()
            .timeout(const Duration(seconds: 3));

        for (final d in topSnap.docs) {
          final data = d.data();
          final remoteData = PredictionData.fromFirestore(data);
          
          final int memberPoints;
          if (remoteData.matchPredictions.isEmpty && 
              remoteData.championCode == null && 
              remoteData.goldenBootPlayer == null) {
            memberPoints = data['points'] as int? ?? 0;
          } else {
            memberPoints = calculateTotalPoints(remoteData, matches);
          }

          tempGlobalMembers.add(FriendScore(
            name: data['username'] ?? 'Unknown',
            points: memberPoints,
            emblem: data['avatar'] ?? '👤',
            isUser: d.id == uid,
            userId: d.id,
          ));
        }

        // Add user if not in top 3
        if (!tempGlobalMembers.any((m) => m.userId == uid)) {
          tempGlobalMembers.add(FriendScore(
            name: userData.username,
            points: userPoints,
            emblem: userEmblem,
            isUser: true,
            userId: uid,
            rank: globalRank,
          ));
        }
      } catch (e) {
        debugPrint('Error loading global rank: $e');
        // Fallback to just the user
        tempGlobalMembers.add(FriendScore(
          name: userData.username,
          points: userPoints,
          emblem: userEmblem,
          isUser: true,
          userId: uid,
          rank: 1,
        ));
      }
    } else {
      tempGlobalMembers.add(FriendScore(
        name: userData.username,
        points: userPoints,
        emblem: userEmblem,
        isUser: true,
        userId: uid,
        rank: 1,
      ));
    }
    
    tempGlobalMembers.sort((a, b) => b.points.compareTo(a.points));
    
    int currentGlobalRank = 1;
    for (int i = 0; i < tempGlobalMembers.length; i++) {
      int r = currentGlobalRank;
      if (tempGlobalMembers[i].isUser && tempGlobalMembers[i].points == userPoints) {
        // preserve the true global rank for the user if they were appended at the end
         if (tempGlobalMembers[i].rank > 0 && tempGlobalMembers[i].rank > i + 1) {
            r = tempGlobalMembers[i].rank;
         } else {
            if (i > 0 && tempGlobalMembers[i].points < tempGlobalMembers[i - 1].points) {
               currentGlobalRank = i + 1;
            }
            r = currentGlobalRank;
         }
      } else {
         if (i > 0 && tempGlobalMembers[i].points < tempGlobalMembers[i - 1].points) {
            currentGlobalRank = i + 1;
         }
         r = currentGlobalRank;
      }
      
      globalMembers.add(FriendScore(
        name: tempGlobalMembers[i].name,
        points: tempGlobalMembers[i].points,
        emblem: tempGlobalMembers[i].emblem,
        isUser: tempGlobalMembers[i].isUser,
        userId: tempGlobalMembers[i].userId,
        rank: r,
      ));
    }

    groups.add(
      FriendGroup(
        name: kGlobalGroupName,
        code: kGlobalGroupCode,
        members: globalMembers,
        globalRank: globalRank,
      ),
    );

    if (uid == 'anonymous_timeout') return groups;

    try {
      final groupsSnapshot = await firestore
          .collection('groups')
          .where('members', arrayContains: uid)
          .get()
          .timeout(const Duration(seconds: 8));

      for (final doc in groupsSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> memberIds = data['members'] ?? [];
        final List<FriendScore> members = [];

        final memberDocsFutures = memberIds.map((id) async {
          final memberId = id as String;
          if (memberId == uid) {
            return FriendScore(
              name: userData.username,
              points: userPoints,
              emblem: userEmblem,
              isUser: true,
              userId: uid,
            );
          } else {
            try {
              final userDoc = await firestore
                  .collection('users')
                  .doc(memberId)
                  .get()
                  .timeout(const Duration(seconds: 3));
              if (userDoc.exists) {
                final uData = userDoc.data()!;
                final remoteData = PredictionData.fromFirestore(uData);

                final int memberPoints;
                if (remoteData.matchPredictions.isEmpty && 
                    remoteData.championCode == null && 
                    remoteData.goldenBootPlayer == null) {
                  memberPoints = uData['points'] as int? ?? 0;
                } else {
                  memberPoints = calculateTotalPoints(remoteData, matches);
                }

                return FriendScore(
                  name: uData['username'] ?? 'Unknown',
                  points: memberPoints,
                  emblem: uData['avatar'] ?? '👤',
                  isUser: false,
                  userId: memberId,
                );
              }
            } catch (e) {
              debugPrint('Error loading member $memberId: $e');
            }
            return FriendScore(
              name: 'Unknown',
              points: 0,
              emblem: '👤',
              isUser: false,
              userId: memberId,
            );
          }
        });

        final resolvedMembers = await Future.wait(memberDocsFutures);
        resolvedMembers.sort((a, b) => b.points.compareTo(a.points));
        
        // Calculate ranks handling ties
        int currentRank = 1;
        for (int i = 0; i < resolvedMembers.length; i++) {
          if (i > 0 && resolvedMembers[i].points < resolvedMembers[i - 1].points) {
            currentRank = i + 1;
          }
          members.add(FriendScore(
            name: resolvedMembers[i].name,
            points: resolvedMembers[i].points,
            emblem: resolvedMembers[i].emblem,
            isUser: resolvedMembers[i].isUser,
            userId: resolvedMembers[i].userId,
            rank: currentRank,
          ));
        }

        groups.add(
          FriendGroup(
            name: data['name'] as String,
            code: doc.id,
            members: members,
            inviteToken: data['inviteToken'] as String?,
            creatorId: data['creatorId'] as String?,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading challenge groups: $e');
    }
    return groups;
  }

  static Future<bool> createCustomGroup(String groupName) async {
    try {
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
      return true;
    } catch (e) {
      debugPrint("Error in createCustomGroup: $e");
      return false;
    }
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
    try {
      String cleanInput = inviteCode.trim();
      if (cleanInput.isEmpty) return false;

      // 1. Extract payload from URL/text using RegExp if present, otherwise fallback to URL parser
      final groupRegExp = RegExp(r'[?&]group=([a-zA-Z0-9_-]+)');
      final match = groupRegExp.firstMatch(cleanInput);
      if (match != null) {
        cleanInput = match.group(1)!;
      } else if (cleanInput.startsWith('http://') || cleanInput.startsWith('https://')) {
        try {
          final uri = Uri.parse(cleanInput);
          final groupParam = uri.queryParameters['group'];
          if (groupParam != null && groupParam.isNotEmpty) {
            cleanInput = groupParam;
          }
        } catch (e) {
          debugPrint("Error parsing group URL: $e");
        }
      }

      // 2. Try to decode it as base64. If it's valid base64, decode it first.
      String decoded = cleanInput;
      try {
        String normalized = cleanInput;
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }
        final decodedBytes = base64Url.decode(normalized);
        decoded = utf8.decode(decodedBytes);
      } catch (_) {
        try {
          String normalized = cleanInput;
          while (normalized.length % 4 != 0) {
            normalized += '=';
          }
          final decodedBytes = base64.decode(normalized);
          decoded = utf8.decode(decodedBytes);
        } catch (_) {
          decoded = cleanInput;
        }
      }

      // 3. Split parts
      final parts = decoded.trim().split('_');
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
          } else {
            return true; // Already joined
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error in joinCustomGroup: $e");
      return false;
    }
  }

  static String generateSharePayload(String inviteId, String token) => '${inviteId}_$token';

  static String getShareLink(String groupId, String inviteToken) {
    final payload = base64Url.encode(utf8.encode('${groupId}_$inviteToken'));
    return 'https://fnnktkygl-code.github.io/mondial_2026/index.html?group=$payload';
  }
}