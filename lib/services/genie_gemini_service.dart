import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import 'team_profile_service.dart';
import 'player_database_service.dart';
import 'prediction_service.dart';
import 'odds_service.dart';
import 'insights_service.dart';

class GenieAnalysis {
  final String summaryLine;
  final String rankingAnalysis;
  final String oddsAnalysis;
  final String historyAnalysis;
  final String sentimentAnalysis;
  final String formAnalysis;
  final String scorerReasoning;
  final double confidenceScore;

  GenieAnalysis({
    required this.summaryLine,
    required this.rankingAnalysis,
    required this.oddsAnalysis,
    required this.historyAnalysis,
    required this.sentimentAnalysis,
    required this.formAnalysis,
    required this.scorerReasoning,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
        'summaryLine': summaryLine,
        'rankingAnalysis': rankingAnalysis,
        'oddsAnalysis': oddsAnalysis,
        'historyAnalysis': historyAnalysis,
        'sentimentAnalysis': sentimentAnalysis,
        'formAnalysis': formAnalysis,
        'scorerReasoning': scorerReasoning,
        'confidenceScore': confidenceScore,
      };

  factory GenieAnalysis.fromJson(Map<String, dynamic> json) => GenieAnalysis(
        summaryLine: json['summaryLine'] as String? ?? '',
        rankingAnalysis: json['rankingAnalysis'] as String? ?? '',
        oddsAnalysis: json['oddsAnalysis'] as String? ?? '',
        historyAnalysis: json['historyAnalysis'] as String? ?? '',
        sentimentAnalysis: json['sentimentAnalysis'] as String? ?? '',
        formAnalysis: json['formAnalysis'] as String? ?? '',
        scorerReasoning: json['scorerReasoning'] as String? ?? '',
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.5,
      );
}

class GenieGeminiService {
  static const String _apiKeyPrefsKey = 'gemini_api_key';
  static const String _modelPrefsKey = 'gemini_model';
  static const String _botPredictionsPrefsKey = 'genie_gemini_predictions';
  static const String _botAnalysisPrefix = 'genie_gemini_analysis_';
  static const String _defaultModel = 'gemini-2.5-flash';

  // ─── API Settings ──────────────────────────────────────────────────────────

  /// Get the active API Key. Priority: SharedPreferences > environment variable
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_apiKeyPrefsKey);
    if (storedKey != null && storedKey.trim().isNotEmpty) {
      return storedKey.trim();
    }
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, apiKey.trim());
  }

  static Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefsKey) ?? _defaultModel;
  }

  static Future<void> saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefsKey, model.trim());
  }

  static const String _ignoredMatchesPrefsKey = 'genie_gemini_ignored_match_ids';

  static Future<List<String>> getIgnoredMatchIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_ignoredMatchesPrefsKey) ?? [];
  }

  static Future<void> saveIgnoredMatchIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ignoredMatchesPrefsKey, ids);
  }

  // ─── Core Prediction loading ───────────────────────────────────────────────

  /// Loads the full prediction profile for Genie Gemini.
  /// If predictions are missing or need updates, they are computed/fetched.
  static Future<PredictionData> loadBotData(List<WorldCupMatch> allMatches, {String lang = 'fr'}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJsonStr = prefs.getString(_botPredictionsPrefsKey);
    PredictionData botData;

    if (cachedJsonStr != null) {
      try {
        final decoded = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
        botData = PredictionData.fromJson(decoded);
      } catch (e) {
        debugPrint("GenieGeminiService: Error parsing cached predictions: $e");
        botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
      }
    } else {
      botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
    }

    botData.username = 'Genie Gemini';
    botData.avatar = '🧠';

    // 1. Check Champion and Golden Boot predictions
    final bool isTourneyLocked = PredictionService.isTournamentPredictionLocked(allMatches);
    if (!isTourneyLocked || botData.championCode == null || botData.goldenBootPlayer == null) {
      // Check if we need to initialize or refresh tournament predictions
      final needsRefresh = botData.championCode == null || botData.goldenBootPlayer == null;
      if (needsRefresh) {
        await _fetchOrGenerateTournamentPredictions(botData, allMatches, lang);
      }
    }

    // 2. Ensure every match has a prediction
    bool hasChanges = false;
    for (final match in allMatches) {
      final String mId = match.id;
      final existingPred = botData.matchPredictions[mId];
      final bool isLocked = PredictionService.isPredictionLocked(match);

      // We generate a prediction if:
      // - No prediction exists
      // - OR: prediction exists but the match is not locked (upcoming) and the cache is older than 6 hours (fresh live data)
      bool needsPrediction = false;
      if (existingPred == null) {
        needsPrediction = true;
      } else if (!isLocked) {
        // Check if the cached analysis exists and is older than 6 hours
        final analysisKey = '$_botAnalysisPrefix$mId';
        final cachedAnalysis = prefs.getString(analysisKey);
        if (cachedAnalysis == null) {
          needsPrediction = true;
        } else {
          // Check timestamp of the match prediction
          // Since MatchPrediction doesn't have a timestamp, we store match prediction update time separately or just let it update on explicit request.
          // Let's implement an age check using SharedPreferences timestamp
          final timestampKey = '${analysisKey}_time';
          final savedTimeStr = prefs.getString(timestampKey);
          if (savedTimeStr != null) {
            final savedTime = DateTime.tryParse(savedTimeStr);
            if (savedTime != null && DateTime.now().difference(savedTime).inHours >= 24) {
              needsPrediction = true;
            }
          } else {
            needsPrediction = true;
          }
        }
      }

      if (needsPrediction) {
        debugPrint("GenieGeminiService: Generating prediction for match ${match.id} (${match.t1} vs ${match.t2})");
        final result = await _fetchOrGeneratePrediction(match, allMatches, lang);
        botData.matchPredictions[mId] = result.prediction;
        
        // Save analysis to its own key
        final analysisKey = '$_botAnalysisPrefix$mId';
        await prefs.setString(analysisKey, jsonEncode(result.analysis.toJson()));
        await prefs.setString('${analysisKey}_time', DateTime.now().toIso8601String());
        hasChanges = true;
      }
    }

    if (hasChanges) {
      // Save updated predictions to cache
      await prefs.setString(_botPredictionsPrefsKey, jsonEncode(botData.toJson()));
    }

    // Calculate dynamic score excluding ignored matches
    final ignoredIds = await getIgnoredMatchIds();
    final cleanData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
    cleanData.championCode = botData.championCode;
    cleanData.goldenBootPlayer = botData.goldenBootPlayer;
    botData.matchPredictions.forEach((key, val) {
      if (!ignoredIds.contains(key)) {
        cleanData.matchPredictions[key] = val;
      }
    });
    botData.points = PredictionService.calculateTotalPoints(cleanData, allMatches);
    return botData;
  }

  /// Force a refresh of the prediction for a specific match.
  static Future<void> refreshMatchPrediction(WorldCupMatch match, List<WorldCupMatch> allMatches, {String lang = 'fr'}) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await _fetchOrGeneratePrediction(match, allMatches, lang, forceRefresh: true);

    // Load current prediction data
    final cachedJsonStr = prefs.getString(_botPredictionsPrefsKey);
    PredictionData botData;
    if (cachedJsonStr != null) {
      try {
        botData = PredictionData.fromJson(jsonDecode(cachedJsonStr) as Map<String, dynamic>);
      } catch (_) {
        botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
      }
    } else {
      botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
    }

    botData.matchPredictions[match.id] = result.prediction;
    
    // Save analysis and predictions
    final analysisKey = '$_botAnalysisPrefix${match.id}';
    await prefs.setString(analysisKey, jsonEncode(result.analysis.toJson()));
    await prefs.setString('${analysisKey}_time', DateTime.now().toIso8601String());
    await prefs.setString(_botPredictionsPrefsKey, jsonEncode(botData.toJson()));
  }

  /// Get the cached analysis for a match.
  static Future<GenieAnalysis?> getMatchAnalysis(String matchId, WorldCupMatch match, List<WorldCupMatch> allMatches, {String lang = 'fr'}) async {
    final prefs = await SharedPreferences.getInstance();
    final analysisKey = '$_botAnalysisPrefix$matchId';
    final cachedJsonStr = prefs.getString(analysisKey);
    if (cachedJsonStr != null) {
      try {
        return GenieAnalysis.fromJson(jsonDecode(cachedJsonStr) as Map<String, dynamic>);
      } catch (e) {
        debugPrint("GenieGeminiService: Error loading analysis for $matchId: $e");
      }
    }

    // If missing from cache, generate it (either from API or fallback)
    debugPrint("GenieGeminiService: Analysis missing for $matchId, generating...");
    final result = await _fetchOrGeneratePrediction(match, allMatches, lang);
    
    // Save to cache
    await prefs.setString(analysisKey, jsonEncode(result.analysis.toJson()));
    await prefs.setString('${analysisKey}_time', DateTime.now().toIso8601String());
    
    // Also save prediction
    final cachedPredsStr = prefs.getString(_botPredictionsPrefsKey);
    PredictionData botData;
    if (cachedPredsStr != null) {
      try {
        botData = PredictionData.fromJson(jsonDecode(cachedPredsStr) as Map<String, dynamic>);
      } catch (_) {
        botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
      }
    } else {
      botData = PredictionData(username: 'Genie Gemini', avatar: '🧠');
    }
    botData.matchPredictions[matchId] = result.prediction;
    await prefs.setString(_botPredictionsPrefsKey, jsonEncode(botData.toJson()));

    return result.analysis;
  }

  // ─── API Communication & Fallback logic ───────────────────────────────────

  static Future<({MatchPrediction prediction, GenieAnalysis analysis})> _fetchOrGeneratePrediction(
      WorldCupMatch match, List<WorldCupMatch> allMatches, String lang,
      {bool forceRefresh = false}) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      debugPrint("GenieGeminiService: No API Key found. Using deterministic fallback.");
      return _generateSeededFallbackPrediction(match, allMatches, lang);
    }

    final model = await getModel();
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey");

    // Gather context details for the prompt
    final team1Name = AppTranslations.getTeam(lang, match.t1);
    final team2Name = AppTranslations.getTeam(lang, match.t2);
    final rank1 = WCTeamProfileService.getFifaRanking(match.t1);
    final rank2 = WCTeamProfileService.getFifaRanking(match.t2);
    final stageName = match.stage ?? (match.isKnockout ? 'Knockout Stage' : 'Group Stage');
    final odds = WCOddsService.calculateMatchOdds(match.t1, match.t2, allMatches);
    final matchupFact = WCInsightsService.getMatchupFact(match.t1, match.t2) ?? "No head-to-head match history data available.";

    // Retrieve squad lists to ensure prediction of valid players
    final team1Players = PlayerDatabaseService.getPlayersForTeam(team1Name);
    final team2Players = PlayerDatabaseService.getPlayersForTeam(team2Name);

    final promptText = """
You are "Genie Gemini", an expert football analyst and AI sports oracle. Analyze the upcoming FIFA World Cup 2026 match:
Team 1: $team1Name (FIFA Rank: $rank1, Country Code: ${match.t1})
Team 2: $team2Name (FIFA Rank: $rank2, Country Code: ${match.t2})
Stage: $stageName
Odds (implied probabilities):
- $team1Name win (1): ${odds['1']} decimal odds
- Draw (X): ${odds['X']} decimal odds
- $team2Name win (2): ${odds['2']} decimal odds

Match History Fact: $matchupFact

Here are the squads. If you predict any goalscorers, you MUST select them EXACTLY from these lists (otherwise return empty scorers):
$team1Name Squad: ${team1Players.join(', ')}
$team2Name Squad: ${team2Players.join(', ')}

Predict the final score after 90 minutes of play (t1Score and t2Score).
If this is a knockout match (${match.isKnockout}) AND you predict a draw (t1Score == t2Score), you MUST specify:
- extraTimeWinner (either 't1', 't2', or null if it goes to penalties)
- penaltyWinner (true if Team 1 wins penalties, false if Team 2 wins penalties; only specify if extraTimeWinner is null)

For group stage matches, extraTimeWinner and penaltyWinner must be null.

Also predict the goalscorers (predictedScorers map with player name as key and number of goals as value). Do not predict scorers who are not in the squads above. If you decide to predict only the outcome without an exact scoreline (outcomeOnly: true), set predictedScorers to an empty map.

If you are not confident in predicting an exact scoreline (e.g. if the teams are very evenly matched, or there is extremely high uncertainty), set `outcomeOnly` to true in the JSON response. If `outcomeOnly` is true, you must still provide representative `t1Score` and `t2Score` values representing the direction of the outcome (e.g. 1-0 for team 1 victory, 0-1 for team 2 victory, 1-1 for a draw), but the system will treat it as an outcome-only prediction.

Write analysis paragraphs in the requested language: ${lang == 'fr' ? 'French' : lang == 'es' ? 'Spanish' : 'English'}.
Provide reasoning paragraphs for the following fields:
- rankingAnalysis: Analysis based on FIFA ranks, squad values, and relative strength.
- oddsAnalysis: Analysis based on the betting odds and implied probabilities.
- historyAnalysis: Analysis based on head-to-head history and matchups.
- sentimentAnalysis: Simulated public opinion / social media vibes.
- formAnalysis: Analysis of recent form and tournament momentum.
- scorerReasoning: Explanation of why you selected the predicted scorers.
- summaryLine: A concise one-sentence prediction verdict.

Also provide a confidenceScore between 0.0 and 1.0.
""";

    try {
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": promptText}
            ]
          }
        ],
        "generationConfig": {
          "responseMimeType": "application/json",
          "responseSchema": {
            "type": "OBJECT",
            "properties": {
              "t1Score": {"type": "INTEGER"},
              "t2Score": {"type": "INTEGER"},
              "extraTimeWinner": {"type": "STRING", "description": "t1, t2, or null"},
              "penaltyWinner": {"type": "BOOLEAN", "description": "true if team 1 wins penalties, false if team 2"},
              "predictedScorers": {
                "type": "OBJECT",
                "additionalProperties": {"type": "INTEGER"},
                "description": "Map of player name to goal count, matching keys of team players exactly"
              },
              "outcomeOnly": {"type": "BOOLEAN", "description": "Set to true if you are not confident in predicting an exact scoreline and prefer to predict only the general outcome (victory of t1, victory of t2, or draw)"},
              "confidenceScore": {"type": "NUMBER"},
              "summaryLine": {"type": "STRING"},
              "rankingAnalysis": {"type": "STRING"},
              "oddsAnalysis": {"type": "STRING"},
              "historyAnalysis": {"type": "STRING"},
              "sentimentAnalysis": {"type": "STRING"},
              "formAnalysis": {"type": "STRING"},
              "scorerReasoning": {"type": "STRING"}
            },
            "required": [
              "t1Score",
              "t2Score",
              "confidenceScore",
              "summaryLine",
              "rankingAnalysis",
              "oddsAnalysis",
              "historyAnalysis",
              "sentimentAnalysis",
              "formAnalysis",
              "scorerReasoning"
            ]
          }
        }
      };

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final jsonText = parts[0]['text'] as String?;
            if (jsonText != null) {
              final parsedResult = jsonDecode(jsonText.trim()) as Map<String, dynamic>;
              
              // Validate Scorers: strip out any that are not in the official squad to prevent crashes
              final Map<String, int> validatedScorers = {};
              final rawScorers = parsedResult['predictedScorers'] as Map<String, dynamic>? ?? {};
              rawScorers.forEach((key, value) {
                final canonical = PlayerDatabaseService.findCanonicalName(key);
                if (canonical != null && (team1Players.contains(canonical) || team2Players.contains(canonical))) {
                  validatedScorers[canonical] = (value as num).toInt();
                }
              });

              final pred = MatchPrediction(
                matchId: match.id,
                t1Score: (parsedResult['t1Score'] as num).toInt(),
                t2Score: (parsedResult['t2Score'] as num).toInt(),
                extraTimeWinner: parsedResult['extraTimeWinner'] as String?,
                penaltyWinner: parsedResult['penaltyWinner'] as bool?,
                predictedScorers: validatedScorers,
                outcomeOnly: parsedResult['outcomeOnly'] as bool? ?? false,
              );

              final analysis = GenieAnalysis(
                summaryLine: parsedResult['summaryLine'] as String? ?? '',
                rankingAnalysis: parsedResult['rankingAnalysis'] as String? ?? '',
                oddsAnalysis: parsedResult['oddsAnalysis'] as String? ?? '',
                historyAnalysis: parsedResult['historyAnalysis'] as String? ?? '',
                sentimentAnalysis: parsedResult['sentimentAnalysis'] as String? ?? '',
                formAnalysis: parsedResult['formAnalysis'] as String? ?? '',
                scorerReasoning: parsedResult['scorerReasoning'] as String? ?? '',
                confidenceScore: (parsedResult['confidenceScore'] as num?)?.toDouble() ?? 0.5,
              );

              return (prediction: pred, analysis: analysis);
            }
          }
        }
      }
      
      debugPrint("GenieGeminiService: API returned status ${response.statusCode}. Falling back.");
    } catch (e) {
      debugPrint("GenieGeminiService: API Call failed: $e. Falling back.");
    }

    // Fallback if API fails
    return _generateSeededFallbackPrediction(match, allMatches, lang);
  }

  static Future<void> _fetchOrGenerateTournamentPredictions(
      PredictionData botData, List<WorldCupMatch> allMatches, String lang) async {
    final apiKey = await getApiKey();
    final isLocked = PredictionService.isTournamentPredictionLocked(allMatches);
    if (isLocked && botData.championCode != null) return; // Keep predictions locked

    if (apiKey.isEmpty) {
      _generateSeededFallbackTournament(botData, allMatches, lang);
      return;
    }

    final model = await getModel();
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey");

    // Build context
    final List<String> teamList = [];
    final Map<String, int> teamRanks = {};
    for (final code in WCTeamProfileService.qualifiedTeams) {
      final name = AppTranslations.getTeam(lang, code);
      teamList.add("$name ($code - Rank: ${WCTeamProfileService.getFifaRanking(code)})");
      teamRanks[code] = WCTeamProfileService.getFifaRanking(code);
    }

    final promptText = """
You are "Genie Gemini", predicting the winner and top scorer of the FIFA World Cup 2026 using live tournament context.
Here are the qualified teams:
${teamList.join('\n')}

Select a tournament Champion (must be a valid 2-letter country code from the above list, e.g. 'fr', 'br', 'ar', 'es', etc.).
Select the Golden Boot winner. Select a star forward from one of the top teams, preferably one of:
- Kylian Mbappé (France)
- Vinícius Júnior (Brazil)
- Lionel Messi (Argentina)
- Harry Kane (England)
- Lamine Yamal (Spain)
- Cristiano Ronaldo (Portugal)
Or another actual player from the squad database.

Write reasonings in: ${lang == 'fr' ? 'French' : lang == 'es' ? 'Spanish' : 'English'}.
Provide:
- championCode: lowercase 2-letter code
- goldenBootPlayer: full player name
- championReasoning: reasoning why this team wins.
- goldenBootReasoning: reasoning why this player wins the top scorer.
""";

    try {
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": promptText}
            ]
          }
        ],
        "generationConfig": {
          "responseMimeType": "application/json",
          "responseSchema": {
            "type": "OBJECT",
            "properties": {
              "championCode": {"type": "STRING"},
              "goldenBootPlayer": {"type": "STRING"},
              "championReasoning": {"type": "STRING"},
              "goldenBootReasoning": {"type": "STRING"}
            },
            "required": ["championCode", "goldenBootPlayer", "championReasoning", "goldenBootReasoning"]
          }
        }
      };

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final jsonText = parts[0]['text'] as String?;
            if (jsonText != null) {
              final parsedResult = jsonDecode(jsonText.trim()) as Map<String, dynamic>;
              
              final code = (parsedResult['championCode'] as String? ?? 'fr').toLowerCase();
              if (WCTeamProfileService.qualifiedTeams.contains(code)) {
                botData.championCode = code;
              } else {
                botData.championCode = 'fr'; // Safe fallback
              }

              final scorer = parsedResult['goldenBootPlayer'] as String? ?? 'Kylian Mbappé';
              botData.goldenBootPlayer = PlayerDatabaseService.findCanonicalName(scorer) ?? scorer;
              botData.championPredictedAt = DateTime.now();
              botData.goldenBootPredictedAt = DateTime.now();

              // Cache tournament reasoning paragraphs
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('${_botAnalysisPrefix}champion_reasoning', parsedResult['championReasoning'] as String? ?? '');
              await prefs.setString('${_botAnalysisPrefix}goldenboot_reasoning', parsedResult['goldenBootReasoning'] as String? ?? '');
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("GenieGeminiService: Tournament API Call failed: $e. Falling back.");
    }

    _generateSeededFallbackTournament(botData, allMatches, lang);
  }

  // ─── Seeded Fallback Generators ──────────────────────────────────────────

  static ({MatchPrediction prediction, GenieAnalysis analysis}) _generateSeededFallbackPrediction(
      WorldCupMatch match, List<WorldCupMatch> allMatches, String lang) {
    // Generate deterministic seed based on matchId
    final seed = match.id.hashCode ^ lang.hashCode;
    final rand = math.Random(seed);

    final team1Name = AppTranslations.getTeam(lang, match.t1);
    final team2Name = AppTranslations.getTeam(lang, match.t2);
    final rank1 = WCTeamProfileService.getFifaRanking(match.t1);
    final rank2 = WCTeamProfileService.getFifaRanking(match.t2);
    final odds = WCOddsService.calculateMatchOdds(match.t1, match.t2, allMatches);
    final matchupFact = WCInsightsService.getMatchupFact(match.t1, match.t2);

    // Calculate probabilities from decimal odds
    final odd1 = odds['1'] ?? 2.0;
    final oddX = odds['X'] ?? 3.0;
    final odd2 = odds['2'] ?? 2.0;
    final prob1 = 1.0 / odd1;
    final probX = 1.0 / oddX;
    final prob2 = 1.0 / odd2;
    final totalProb = prob1 + probX + prob2;

    final double roll = rand.nextDouble() * totalProb;
    int t1Score = 0;
    int t2Score = 0;
    String? extraTimeWinner;
    bool? penaltyWinner;

    if (roll < prob1) {
      // Team 1 wins
      t1Score = rand.nextInt(3) + 1;
      t2Score = rand.nextInt(t1Score);
    } else if (roll < prob1 + probX) {
      // Draw
      t1Score = rand.nextInt(3);
      t2Score = t1Score;

      if (match.isKnockout) {
        // Knockout draws need winner resolved
        final etRoll = rand.nextDouble();
        if (etRoll < 0.4) {
          extraTimeWinner = 't1';
        } else if (etRoll < 0.8) {
          extraTimeWinner = 't2';
        } else {
          // Penalties
          extraTimeWinner = null;
          penaltyWinner = rand.nextBool();
        }
      }
    } else {
      // Team 2 wins
      t2Score = rand.nextInt(3) + 1;
      t1Score = rand.nextInt(t2Score);
    }

    // Determine if we should only predict the outcome (without exact score)
    // 25% chance of outcomeOnly, or if odds are extremely close
    final bool outcomeOnly = ((odd1 - odd2).abs() < 0.3 && rand.nextDouble() < 0.5) || (rand.nextDouble() < 0.15);

    // Predicted Scorers
    final Map<String, int> predictedScorers = {};
    if (!outcomeOnly) {
      final t1Players = PlayerDatabaseService.getPlayersForTeam(team1Name);
      final t2Players = PlayerDatabaseService.getPlayersForTeam(team2Name);

      void selectScorers(String team, int score, List<String> playerPool) {
        if (score <= 0 || playerPool.isEmpty) return;
        // Filter for forwards or midfielders if possible
        final forwards = playerPool.where((p) => PlayerDatabaseService.getPlayerPosition(team, p) == 'Forwards').toList();
        final midfielders = playerPool.where((p) => PlayerDatabaseService.getPlayerPosition(team, p) == 'Midfielders').toList();
        final priorityPool = forwards.isNotEmpty ? forwards : (midfielders.isNotEmpty ? midfielders : playerPool);

        for (int i = 0; i < score; i++) {
          final scorer = priorityPool[rand.nextInt(priorityPool.length)];
          predictedScorers[scorer] = (predictedScorers[scorer] ?? 0) + 1;
        }
      }

      selectScorers(team1Name, t1Score, t1Players);
      selectScorers(team2Name, t2Score, t2Players);
    }

    final double confidence = 0.5 + (rand.nextDouble() * 0.4);

    // Multilingual Reasoning Text Generator
    String summaryLine = "";
    String rankingAnalysis = "";
    String oddsAnalysis = "";
    String historyAnalysis = "";
    String sentimentAnalysis = "";
    String formAnalysis = "";
    String scorerReasoning = "";

    if (lang == 'fr') {
      summaryLine = outcomeOnly
          ? (t1Score == t2Score
              ? "Un match nul semble très probable au vu des dynamiques équilibrées."
              : "Je prévois une victoire de ${t1Score > t2Score ? team1Name : team2Name} mais la physionomie reste très incertaine.")
          : (t1Score == t2Score
              ? "Un combat tactique équilibré. Je table sur un score de $t1Score-$t2Score."
              : "Victoire attendue de ${t1Score > t2Score ? team1Name : team2Name} par la plus petite des marges ($t1Score-$t2Score).");

      rankingAnalysis = "Selon les classements FIFA, $team1Name (rang $rank1) fait face à $team2Name (rang $rank2). " +
          (rank1 < rank2
              ? "$team1Name part avec la faveur des chiffres grâce à son meilleur positionnement mondial."
              : "$team2Name possède un léger avantage statistique au classement international.");

      oddsAnalysis = "Les cotes du marché (Victoire 1: $odd1, Nul: $oddX, Victoire 2: $odd2) traduisent une probabilité de victoire de " +
          "${(prob1 / totalProb * 100).round()}% pour $team1Name et ${(prob2 / totalProb * 100).round()}% pour $team2Name. Les bookmakers anticipent un affrontement " +
          ((odd1 - odd2).abs() < 1.0 ? "extrêmement indécis." : "favorable au favori désigné.");

      historyAnalysis = matchupFact ?? "Les confrontations historiques entre ces deux nations sont trop rares pour dégager une tendance nette, ce qui laisse place à toutes les spéculations.";

      sentimentAnalysis = "Les réseaux sociaux et l'opinion générale montrent un engouement particulier pour ce choc. La ferveur populaire semble légèrement pencher pour " +
          (rand.nextBool() ? team1Name : team2Name) + " qui bénéficie d'un fort soutien des supporters neutres.";

      formAnalysis = "L'état de forme des effectifs suggère un match physique. Les séances d'entraînement récentes révèlent une préparation solide et un moral au beau fixe pour les deux groupes.";

      scorerReasoning = outcomeOnly
          ? "Aucun buteur n'est pronostiqué car Genie Gemini a opté pour un pronostic de résultat uniquement."
          : (predictedScorers.isEmpty
              ? "Aucun buteur n'est pronostiqué pour cette rencontre qui s'annonce très défensive."
              : "Pour ce match, des attaquants clés comme ${predictedScorers.keys.first} sont pressentis pour débloquer la situation grâce à leur réalisme face au but.");
    } else if (lang == 'es') {
      summaryLine = outcomeOnly
          ? (t1Score == t2Score
              ? "Un empate táctico parece lo más probable según la forma de ambos equipos."
              : "Espero una victoria de ${t1Score > t2Score ? team1Name : team2Name} sin arriesgar un marcador exacto.")
          : (t1Score == t2Score
              ? "Un duelo táctico muy equilibrado. Pronostico un resultado de $t1Score-$t2Score."
              : "Victoria esperada de ${t1Score > t2Score ? team1Name : team2Name} por un margen estrecho ($t1Score-$t2Score).");

      rankingAnalysis = "El ranking FIFA sitúa a $team1Name (puesto $rank1) frente a $team2Name (puesto $rank2). " +
          (rank1 < rank2
              ? "$team1Name parte con ventaja estadística sobre el papel."
              : "$team2Name tiene la superioridad en el ranking internacional.");

      oddsAnalysis = "Las cuotas (Victoria 1: $odd1, Empate: $oddX, Victoria 2: $odd2) representan una probabilidad implícita del " +
          "${(prob1 / totalProb * 100).round()}% para $team1Name y ${(prob2 / totalProb * 100).round()}% para $team2Name. Esto sugiere un encuentro " +
          ((odd1 - odd2).abs() < 1.0 ? "muy equilibrado y difícil de predecir." : "donde el favorito tiene claras opciones.");

      historyAnalysis = matchupFact ?? "No hay suficientes datos históricos de enfrentamientos entre ambos para prever un patrón claro de comportamiento táctico.";

      sentimentAnalysis = "La afición se muestra dividida, pero la balanza de las redes sociales parece inclinarse levemente hacia " +
          (rand.nextBool() ? team1Name : team2Name) + " debido al carisma de sus jugadores estrella.";

      formAnalysis = "El análisis físico indica que ambos combinados llegan con sus plantillas al 100%, enfocándose en la solidez defensiva.";

      scorerReasoning = outcomeOnly
          ? "No se prevén goleadores ya que Genie Gemini optó por pronosticar solo el resultado."
          : (predictedScorers.isEmpty
              ? "No se prevén goleadores en un encuentro de perfil marcadamente defensivo."
              : "Se espera que delanteros de la calidad de ${predictedScorers.keys.first} lideren la ofensiva y consigan marcar durante el encuentro.");
    } else {
      // Default to English
      summaryLine = outcomeOnly
          ? (t1Score == t2Score
              ? "A tactical draw seems highly likely given the current dynamics."
              : "I predict a victory for ${t1Score > t2Score ? team1Name : team2Name} but the exact score remains highly uncertain.")
          : (t1Score == t2Score
              ? "A highly tactical draw. I predict a $t1Score-$t2Score final score."
              : "Expected victory for ${t1Score > t2Score ? team1Name : team2Name} by a narrow margin ($t1Score-$t2Score).");

      rankingAnalysis = "The FIFA Rankings place $team1Name at #$rank1 and $team2Name at #$rank2. " +
          (rank1 < rank2
              ? "$team1Name has a clear statistical advantage based on their worldwide position."
              : "$team2Name holds the edge in the global standings.");

      oddsAnalysis = "Market odds (1: $odd1, X: $oddX, 2: $odd2) show an implied probability of " +
          "${(prob1 / totalProb * 100).round()}% for $team1Name and ${(prob2 / totalProb * 100).round()}% for $team2Name. The bookmakers expect a " +
          ((odd1 - odd2).abs() < 1.0 ? "very close and competitive match." : "match favoring the designated favorite.");

      historyAnalysis = matchupFact ?? "Head-to-head records between these two sides are sparse, leaving the tactical outcome wide open.";

      sentimentAnalysis = "Social media sentiment is buzzing. Fans are leaning slightly towards " +
          (rand.nextBool() ? team1Name : team2Name) + " expecting a spectacular display.";

      formAnalysis = "Team training reports indicate high levels of fitness and intense preparation, suggesting a high-tempo physical matchup.";

      scorerReasoning = outcomeOnly
          ? "No goalscorers predicted as Genie Gemini opted for an outcome-only prediction."
          : (predictedScorers.isEmpty
              ? "No goalscorers predicted as this match is expected to be a defensive masterclass."
              : "Key attackers like ${predictedScorers.keys.first} are expected to make the difference due to their excellent clinical finishing.");
    }

    final pred = MatchPrediction(
      matchId: match.id,
      t1Score: t1Score,
      t2Score: t2Score,
      extraTimeWinner: extraTimeWinner,
      penaltyWinner: penaltyWinner,
      predictedScorers: predictedScorers,
      outcomeOnly: outcomeOnly,
    );

    final analysis = GenieAnalysis(
      summaryLine: summaryLine,
      rankingAnalysis: rankingAnalysis,
      oddsAnalysis: oddsAnalysis,
      historyAnalysis: historyAnalysis,
      sentimentAnalysis: sentimentAnalysis,
      formAnalysis: formAnalysis,
      scorerReasoning: scorerReasoning,
      confidenceScore: confidence,
    );

    return (prediction: pred, analysis: analysis);
  }

  static void _generateSeededFallbackTournament(
      PredictionData botData, List<WorldCupMatch> allMatches, String lang) {
    // Predict champion based on odds
    final teams = WCTeamProfileService.qualifiedTeams.toList();
    if (teams.isEmpty) return;

    final rand = math.Random('genie_gemini_tournament'.hashCode ^ lang.hashCode);
    
    // Sort teams by FIFA rank (lower is better, e.g. 1, 2, 3)
    teams.sort((a, b) => WCTeamProfileService.getFifaRanking(a).compareTo(WCTeamProfileService.getFifaRanking(b)));
    
    // Weighted selection favoring top 5 ranks
    final int topN = math.min(5, teams.length);
    final selectedChampion = teams[rand.nextInt(topN)];
    
    botData.championCode = selectedChampion;
    botData.championPredictedAt = DateTime.now().subtract(const Duration(days: 2));

    // Choose top forward from champion or top-ranked team
    final champName = AppTranslations.getTeam(lang, selectedChampion);
    final players = PlayerDatabaseService.getPlayersForTeam(champName);
    
    String selectedBoot = "Kylian Mbappé"; // default fallback
    if (players.isNotEmpty) {
      final forwards = players.where((p) => PlayerDatabaseService.getPlayerPosition(champName, p) == 'Forwards').toList();
      if (forwards.isNotEmpty) {
        selectedBoot = forwards[rand.nextInt(forwards.length)];
      } else {
        selectedBoot = players[rand.nextInt(players.length)];
      }
    }
    
    botData.goldenBootPlayer = selectedBoot;
    botData.goldenBootPredictedAt = DateTime.now().subtract(const Duration(days: 2));
  }

  /// Get the cached tournament reasoning (Champion or Golden Boot)
  static Future<String> getTournamentReasoning(String type, String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_botAnalysisPrefix${type}_reasoning');
    if (cached != null && cached.isNotEmpty) return cached;

    if (lang == 'fr') {
      if (type == 'champion') {
        return "Genie Gemini a sélectionné cette équipe en raison de la profondeur exceptionnelle de son effectif et de sa constance dans les grands rendez-vous. Son parcours récent en fait un vainqueur légitime.";
      } else {
        return "Ce joueur réunit toutes les qualités d'un grand finisseur. Soutenu par un milieu créatif, il devrait bénéficier de nombreuses occasions tout au long du tournoi.";
      }
    } else if (lang == 'es') {
      if (type == 'champion') {
        return "Genie Gemini ha seleccionado a este equipo por la increíble profundidad de su plantilla y su experiencia en grandes torneos. Su estado de forma actual los convierte en campeones lógicos.";
      } else {
        return "Este jugador destaca por su instinto goleador. Con el apoyo de un centro del campo creativo, tendrá múltiples oportunidades de marcar en cada fase del torneo.";
      }
    } else {
      if (type == 'champion') {
        return "Genie Gemini selected this team based on their exceptional squad depth and strong record in major tournaments. Their tactical consistency makes them a prime championship contender.";
      } else {
        return "This player possesses all the traits of an elite goalscorer. Backed by a highly creative midfield, he is poised to receive ample opportunities to claim the top spot.";
      }
    }
  }
}
