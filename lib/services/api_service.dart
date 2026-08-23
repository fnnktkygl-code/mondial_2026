import '../models/match.dart';
import '../utils/fifa_rules.dart';
import '../data/official_tournament_archive.dart';

class ApiService {
  // Staging Mode Flag
  static bool isStagingMode = false;

  /// Fetch live matches (empty in archive mode).
  static Future<List<WorldCupMatch>> fetchEspnLive() async {
    return [];
  }

  /// Load tournament matches from official immutable static archive.
  static Future<List<WorldCupMatch>> loadMatches({
    bool forceRefresh = false,
  }) async {
    final matches = OfficialTournamentArchive.getMatches();
    return FIFARegulations.resolveMatchesPlaceholders(matches);
  }

  /// Save matches to cache (no-op in archive mode).
  static Future<void> saveMatchesToCache(List<WorldCupMatch> matches) async {}

  /// Returns the last time matches were fetched from the network.
  static Future<DateTime?> getLastUpdated() async {
    return DateTime.now();
  }

  /// Reset cache back to the initial bundled matches.
  static Future<List<WorldCupMatch>> resetCache() async {
    return loadMatches();
  }
}