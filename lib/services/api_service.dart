import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match.dart';
import '../app_constants.dart';

class ApiService {
  static const String _cacheKey = kMatchesCacheKey;
  static const String _lastUpdatedKey = 'wc_matches_last_updated';

  /// Load tournament matches. Priority:
  /// 1. Local SharedPreferences cache (if fresh enough)
  /// 2. Remote GitHub raw JSON (committed by GitHub Actions)
  /// 3. Bundled asset initial_matches.json
  static Future<List<WorldCupMatch>> loadMatches({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

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
          DateTime.now().toIso8601String(),
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
  static Future<List<WorldCupMatch>> fetchRemoteMatches() async {
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
      }
    } catch (_) {
      // Return empty list on failure; caller will use cache
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
