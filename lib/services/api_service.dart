import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../app_constants.dart';

class ApiService {
  static const String _cacheKey = kMatchesCacheKey;
  static const String _lastUpdatedKey = 'wc_matches_last_updated';

  // Toggle this from your Staging Panel to intercept live calls
  static bool isStagingMode = false;

  /// Load tournament matches. Priority:
  /// 1. Local SharedPreferences cache (if fresh enough)
  /// 2. Remote GitHub raw JSON (committed by GitHub Actions)
  /// 3. Bundled asset initial_matches.json
  static Future<List<WorldCupMatch>> loadMatches({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Read bundled metadata to know minimum required lastUpdated timestamp
    DateTime? assetLastUpdated;
    try {
      final metaStr = await rootBundle.loadString('assets/matches_meta.json');
      final meta = jsonDecode(metaStr);
      if (meta['lastUpdated'] != null) {
        assetLastUpdated = DateTime.tryParse(meta['lastUpdated'] as String);
      }
    } catch (_) {}

    final cacheTimeStr = prefs.getString(_lastUpdatedKey);
    DateTime? cacheTime = cacheTimeStr != null ? DateTime.tryParse(cacheTimeStr) : null;

    // Discard local cache if it is older than the bundled asset metadata
    if (cacheTime != null && assetLastUpdated != null && cacheTime.isBefore(assetLastUpdated)) {
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdatedKey);
    }

    // 1. Try local cache
    final cachedJson = prefs.getString(_cacheKey);
    List<WorldCupMatch>? matches;
    if (cachedJson != null && !forceRefresh) {
      try {
        matches = _parseMatchesJson(cachedJson);
      } catch (_) {
        // Cache corrupted – fall through
      }
    }

    // 2. Fall back to bundled asset if cache is empty
    if (matches == null || matches.isEmpty) {
      try {
        final assetJson = await rootBundle.loadString(
          'assets/initial_matches.json',
        );
        matches = _parseMatchesJson(assetJson);
        await prefs.setString(_cacheKey, assetJson);
        await prefs.setString(
          _lastUpdatedKey,
          assetLastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
        );
      } catch (e) {
        matches = [];
      }
    }

    // 3. Fetch remote update (always try, skip if cached < 5 min old and not forced)
    final lastFetch = prefs.getString(_lastUpdatedKey);
    final bool shouldFetch =
        forceRefresh ||
            cachedJson == null ||
            (lastFetch != null &&
                DateTime.now().difference(DateTime.parse(lastFetch)) >
                    kCacheRefreshInterval);

    if (shouldFetch) {
      try {
        final remoteMatches = await fetchRemoteMatches();
        if (remoteMatches.isNotEmpty) {
          matches = remoteMatches;
        }
      } catch (_) {
        // Keep using cached / asset matches if network is offline
      }
    }

    return matches ?? [];
  }

  /// Fetch schedule updates from the remote GitHub JSON.
  /// Includes Exponential Backoff and Staging Interceptor.
  static Future<List<WorldCupMatch>> fetchRemoteMatches() async {
    if (isStagingMode) {
      return _fetchMockStagingMatches();
    }

    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final response = await http.get(Uri.parse(kApiUrl)).timeout(kApiTimeout);
        if (response.statusCode == 200) {
          final jsonStr = response.body;
          final matches = _parseMatchesJson(jsonStr);
          if (matches.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cacheKey, jsonStr);
            await prefs.setString(
              _lastUpdatedKey,
              DateTime.now().toIso8601String(),
            );
            return matches;
          }
        } else {
          throw Exception('Non-200 status code: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          break;
        }
        // Exponential backoff: 1s, 2s, 4s
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