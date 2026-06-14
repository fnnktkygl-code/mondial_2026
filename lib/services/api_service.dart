import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../app_constants.dart';
import 'espn_api_service.dart';

class ApiService {
  static const String _cacheKey = kMatchesCacheKey;
  static const String _lastUpdatedKey = 'wc_matches_last_updated';

  // Toggle this from your Staging Panel to intercept live calls
  static bool isStagingMode = false;

  /// Fetch live matches from ESPN to update scores/stats in real-time.
  static Future<List<WorldCupMatch>> fetchEspnLive() async {
    return EspnApiService.fetchLiveMatches();
  }

  /// Load tournament matches. Priority:
  /// 1. Local SharedPreferences cache (if fresh enough)
  /// 2. Remote ESPN sync merged into schedule
  /// 3. Bundled asset initial_matches.json
  static Future<List<WorldCupMatch>> loadMatches({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<WorldCupMatch> baseMatches = [];

    // 1. Load Base Schedule from Assets
    try {
      final jsonStr = await rootBundle.loadString('assets/initial_matches.json');
      baseMatches = _parseMatchesJson(jsonStr);
    } catch (e) {
      debugPrint("API: Asset load error: $e");
    }

    // 2. Try Cache (if not forcing refresh)
    if (!forceRefresh) {
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        try {
          final cachedMatches = _parseMatchesJson(cachedJson);
          // We merge the cache into the base schedule to ensure we have all matches
          baseMatches = _patchMatches(baseMatches, cachedMatches);
        } catch (_) {}
      }
    }

    // 3. Fetch Remote Updates from ESPN and PATCH
    try {
      final remoteUpdates = await fetchRemoteMatches();
      if (remoteUpdates.isNotEmpty) {
        final patched = _patchMatches(baseMatches, remoteUpdates);
        
        // Save patched results to cache
        final jsonToCache = jsonEncode(patched.map((m) => m.toJson()).toList());
        await prefs.setString(_cacheKey, jsonToCache);
        await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
        
        return patched;
      }
    } catch (e) {
      debugPrint("API: Remote sync error: $e");
    }

    return baseMatches;
  }

  /// Merges remote results into the base schedule using team matching and date logic.
  static List<WorldCupMatch> _patchMatches(List<WorldCupMatch> base, List<WorldCupMatch> updates) {
    final List<WorldCupMatch> patched = List.from(base);
    
    for (final update in updates) {
      for (int i = 0; i < patched.length; i++) {
        final local = patched[i];
        
        // Match by teams and approximate date (within 24h)
        final sameTeams = (local.t1 == update.t1 && local.t2 == update.t2) ||
                         (local.t1 == update.t2 && local.t2 == update.t1);
        
        if (sameTeams) {
          final dateDiff = local.date.difference(update.date).abs();
          if (dateDiff.inHours < 24) {
            patched[i] = local.copyWith(
              espnId: update.id.replaceFirst('espn_', ''),
              t1Score: update.t1Score,
              t2Score: update.t2Score,
              status: update.status,
              venue: update.venue ?? local.venue,
              goals: update.goals,
              stats: update.stats,
              lastUpdated: DateTime.now(),
            );
            break;
          }
        }
      }
    }
    return patched;
  }

  /// Fetch tournament updates from ESPN.
  /// Includes Exponential Backoff and Staging Interceptor.
  static Future<List<WorldCupMatch>> fetchRemoteMatches() async {
    if (isStagingMode) {
      return _fetchMockStagingMatches();
    }

    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // We fetch the entire tournament scoreboard range to get all results
        // 2026 dates: June 11 to July 19
        final espnMatches = await EspnApiService.fetchLiveMatches();
        
        if (espnMatches.isNotEmpty) {
          // We don't save to _cacheKey here because the ESPN structure 
          // is converted to WorldCupMatch models already.
          // The local cache expects the original JSON format for _parseMatchesJson.
          // Instead, we return them and main.dart will handle the merging/patching.
          return espnMatches;
        }
        break;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          break;
        }
        await Future.delayed(Duration(seconds: math.pow(2, retryCount - 1).toInt()));
      }
    }
    return [];
  }

  /// Staging interceptor to simulate live matches without real network calls
  static Future<List<WorldCupMatch>> _fetchMockStagingMatches() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
        bool modified = false;

        // Find the first TIMED match and transition it to IN_PLAY to simulate live staging
        for (var item in decoded) {
          if (item['status'] == 'TIMED') {
            item['status'] = 'IN_PLAY';
            item['t1Score'] = 1; // Simulate a goal
            item['t2Score'] = 0;
            modified = true;
            break;
          }
        }

        if (modified) {
          final newJsonStr = jsonEncode(decoded);
          // Temporarily save to cache so UI updates naturally in staging
          await prefs.setString(_cacheKey, newJsonStr);
          await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
          return _parseMatchesJson(newJsonStr);
        } else {
          return _parseMatchesJson(cachedJson);
        }
      } catch (e) {
        debugPrint('Error in staging mock: $e');
      }
    }
    return [];
  }

  /// Returns the last time matches were fetched from the network.
  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastUpdatedKey);
    if (str == null) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }

  /// Save matches to the local cache (used by the simulator).
  static Future<void> saveMatchesToCache(List<WorldCupMatch> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(matches.map((m) => m.toJson()).toList());
    await prefs.setString(_cacheKey, jsonStr);
    // Force la date de mise à jour loin dans le futur pour que le staging garde son cache !
    await prefs.setString(_lastUpdatedKey, DateTime.now().add(const Duration(days: 365)).toIso8601String());
  }

  /// Reset cache back to the initial bundled matches.
  static Future<List<WorldCupMatch>> resetCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastUpdatedKey);
    return loadMatches();
  }

  static List<WorldCupMatch> _parseMatchesJson(String jsonStr) {
    final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
    int r32Count = 0;
    int r16Count = 0;
    int qfCount = 0;
    int sfCount = 0;

    return decoded.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final stage = map['stage'] as String?;
      final isKnockout =
          map['isKnockout'] as bool? ?? (stage != null && stage.isNotEmpty);

      if (isKnockout) {
        String newId = map['id'] as String;
        if (stage == 'Round of 32') {
          newId = 'm${49 + r32Count}';
          r32Count++;
        } else if (stage == 'Round of 16') {
          newId = 'm${65 + r16Count}';
          r16Count++;
        } else if (stage == 'Quarter-Final') {
          newId = 'm${73 + qfCount}';
          qfCount++;
        } else if (stage == 'Semi-Final') {
          newId = 'm${77 + sfCount}';
          sfCount++;
        } else if (stage == 'Play-off for third place') {
          newId = 'm79';
        } else if (stage == 'Final') {
          newId = 'm80';
        }
        map['id'] = newId;
        map['isKnockout'] = true;
      } else {
        final id = map['id'] as String;
        if (!id.startsWith(kGroupMatchIdPrefix)) {
          map['id'] = '$kGroupMatchIdPrefix$id';
        }
        map['isKnockout'] = false;
      }
      return WorldCupMatch.fromJson(map);
    }).toList();
  }
}