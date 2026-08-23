import '../models/match.dart';
import '../services/team_profile_service.dart';

class H2HStats {
  int points = 0;
  int gd = 0;
  int gf = 0;
}

class GroupEntry {
  final String teamCode;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int fairPlay = 0;

  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;

  GroupEntry(this.teamCode);
}

class FIFARegulations {
  static const Map<String, List<String>> knockoutRouting = {
    'm73': ['2A', '2B'],
    'm74': ['1E', '3rd1'],
    'm75': ['1F', '2C'],
    'm76': ['1C', '2F'],
    'm77': ['1I', '3rd2'],
    'm78': ['2E', '2I'],
    'm79': ['1A', '3rd3'],
    'm80': ['1L', '3rd4'],
    'm81': ['1G', '3rd5'],
    'm82': ['1D', '3rd6'],
    'm83': ['1H', '2J'],
    'm84': ['2K', '2L'],
    'm85': ['1B', '3rd7'],
    'm86': ['2D', '2G'],
    'm87': ['1J', '2H'],
    'm88': ['1K', '3rd8'],
    'm89': ['w74', 'w77'],
    'm90': ['w73', 'w75'],
    'm91': ['w76', 'w78'],
    'm92': ['w79', 'w80'],
    'm93': ['w83', 'w84'],
    'm94': ['w81', 'w82'],
    'm95': ['w85', 'w86'],
    'm96': ['w87', 'w88'],
    'm97': ['w89', 'w90'],
    'm98': ['w93', 'w94'],
    'm99': ['w91', 'w92'],
    'm100': ['w95', 'w96'],
    'm101': ['w97', 'w98'],
    'm102': ['w99', 'w100'],
    'm103': ['l101', 'l102'],
    'm104': ['w101', 'w102'],
  };

  /// Calculates disciplinary points for a team in a match based on yellow/red card counts.
  /// Deductions:
  /// - Yellow card: -1 point
  /// - Indirect red card (second yellow card): -3 points
  /// - Direct red card: -4 points
  /// - Yellow card and direct red card: -5 points
  /// Returns a positive integer representing the deduction (points subtracted).
  static int calculateDisciplinaryDeduction(int yellow, int red) {
    int points = yellow * 1 + red * 4;
    int indirectReds = 0;
    if (red > 0 && yellow >= 2) {
      indirectReds = red < (yellow ~/ 2) ? red : (yellow ~/ 2);
    }
    points -= indirectReds * 3;
    return points;
  }

  /// Helper to calculate head-to-head stats for a specific team code among a set of tied team codes.
  static H2HStats calculateH2HStats(
    String teamCode,
    Set<String> tiedTeamCodes,
    List<WorldCupMatch> matches,
  ) {
    final stats = H2HStats();
    final teamLower = teamCode.toLowerCase();
    final tiedLower = tiedTeamCodes.map((c) => c.toLowerCase()).toSet();

    for (final m in matches) {
      if (m.group == null || m.group!.isEmpty || !m.isPlayed) continue;

      final t1Lower = m.t1.toLowerCase();
      final t2Lower = m.t2.toLowerCase();

      if (tiedLower.contains(t1Lower) && tiedLower.contains(t2Lower)) {
        if (t1Lower == teamLower) {
          stats.gf += m.t1Score!;
          stats.gd += (m.t1Score! - m.t2Score!);
          if (m.t1Score! > m.t2Score!) {
            stats.points += 3;
          } else if (m.t1Score! == m.t2Score!) {
            stats.points += 1;
          }
        } else if (t2Lower == teamLower) {
          stats.gf += m.t2Score!;
          stats.gd += (m.t2Score! - m.t1Score!);
          if (m.t2Score! > m.t1Score!) {
            stats.points += 3;
          } else if (m.t1Score! == m.t2Score!) {
            stats.points += 1;
          }
        }
      }
    }
    return stats;
  }

  /// Sorts a group's standing entries in-place using the official FIFA 2026 tie-breakers.
  /// Works dynamically on lists of `GroupEntry` or `TeamGroupStats` (using dynamic type).
  static void sortStandings(List<dynamic> teams, List<WorldCupMatch> matches) {
    if (teams.isEmpty) return;

    teams.sort((a, b) {
      // 0. Overall Points
      if (b.points != a.points) return b.points.compareTo(a.points);

      // --- Étape 1: Confrontations directes (H2H) ---
      final tiedTeamCodes = teams
          .where((t) => t.points == a.points)
          .map<String>((t) => t.teamCode as String)
          .toSet();

      if (tiedTeamCodes.length > 1) {
        final statsA = calculateH2HStats(a.teamCode as String, tiedTeamCodes, matches);
        final statsB = calculateH2HStats(b.teamCode as String, tiedTeamCodes, matches);

        // 1. H2H Points
        if (statsB.points != statsA.points) {
          return statsB.points.compareTo(statsA.points);
        }
        // 2. H2H Goal Difference
        if (statsB.gd != statsA.gd) return statsB.gd.compareTo(statsA.gd);
        // 3. H2H Goals For
        if (statsB.gf != statsA.gf) return statsB.gf.compareTo(statsA.gf);
      }

      // --- Étape 2: Critères généraux ---
      // 4. Overall Goal Difference
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }

      // 5. Overall Goals For
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);

      // 6. Fair Play points (closer to 0 is better, e.g. -1 is better than -3)
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);

      // --- Étape 3: Classement FIFA ---
      // 7. FIFA World Ranking
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode as String);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode as String);
      if (rankA != rankB) {
        return rankA.compareTo(rankB); // Lower rank is better (1st is better than 2nd)
      }

      // 8. Alphabetical fallback
      return (a.teamCode as String).compareTo(b.teamCode as String);
    });
  }

  /// Sorts third-placed teams across different groups.
  /// Omits Head-to-Head criteria since they haven't played each other.
  static void sortBestThirds(List<dynamic> teams) {
    if (teams.isEmpty) return;

    teams.sort((a, b) {
      // 1. Overall Points
      if (b.points != a.points) return b.points.compareTo(a.points);

      // 2. Overall Goal Difference
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }

      // 3. Overall Goals For
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);

      // 4. Fair Play points (closer to 0 is better, e.g. -1 is better than -3)
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);

      // 5. FIFA World Ranking
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode as String);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode as String);
      if (rankA != rankB) {
        return rankA.compareTo(rankB); // Lower rank is better (1st is better than 2nd)
      }

      // 6. Alphabetical fallback
      return (a.teamCode as String).compareTo(b.teamCode as String);
    });
  }

  static List<WorldCupMatch> resolveMatchesPlaceholders(
    List<WorldCupMatch> rawMatches,
  ) {
    final Map<String, List<GroupEntry>> groupStandings = {};
    for (final m in rawMatches) {
      if (m.group == null || m.group!.isEmpty) continue;
      final grp = m.group!;
      groupStandings.putIfAbsent(grp, () => []);
      final list = groupStandings[grp]!;
      if (!list.any((e) => e.teamCode == m.t1)) list.add(GroupEntry(m.t1));
      if (!list.any((e) => e.teamCode == m.t2)) list.add(GroupEntry(m.t2));
    }

    for (final m in rawMatches) {
      if (m.group == null || m.group!.isEmpty || !m.isPlayed) continue;
      final grp = m.group!;
      final t1Entry = groupStandings[grp]!.firstWhere(
        (e) => e.teamCode == m.t1,
      );
      final t2Entry = groupStandings[grp]!.firstWhere(
        (e) => e.teamCode == m.t2,
      );

      t1Entry.played++;
      t2Entry.played++;
      t1Entry.goalsFor += m.t1Score!;
      t1Entry.goalsAgainst += m.t2Score!;
      t2Entry.goalsFor += m.t2Score!;
      t2Entry.goalsAgainst += m.t1Score!;

      if (m.t1Score! > m.t2Score!) {
        t1Entry.wins++;
        t2Entry.losses++;
      } else if (m.t1Score! < m.t2Score!) {
        t2Entry.wins++;
        t1Entry.losses++;
      } else {
        t1Entry.draws++;
        t2Entry.draws++;
      }

      if (m.stats != null) {
        t1Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          m.stats!.yellowCardsT1,
          m.stats!.redCardsT1,
        );
        t2Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          m.stats!.yellowCardsT2,
          m.stats!.redCardsT2,
        );
      }
    }

    groupStandings.forEach((group, teamEntries) {
      FIFARegulations.sortStandings(teamEntries, rawMatches);
    });

    final List<GroupEntry> thirdPlaces = [];
    groupStandings.forEach((g, list) {
      if (list.length >= 3) {
        thirdPlaces.add(list[2]);
      }
    });
    thirdPlaces.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.teamCode.compareTo(b.teamCode);
    });

    List<WorldCupMatch> resolved = List.from(rawMatches);

    // We run multiple passes because later rounds depend on earlier rounds being resolved first.
    // In each pass:
    //   Step 1: Resolve all placeholder team codes (group positions, 3rd places, knockoutRouting)
    //   Step 2: THEN collect winners/losers from the now-resolved matches
    //   Step 3: Use those winners/losers to resolve w## and l## references
    // This ensures matchWinners always contains real team codes (e.g., 'us'), never placeholders (e.g., '1D').
    for (int pass = 0; pass < 6; pass++) {
      final Map<String, String> matchWinners = {};
      final Map<String, String> matchLosers = {};

      // Step 1: Resolve group/3rd-place placeholders for ALL knockout matches first
      for (int i = 0; i < resolved.length; i++) {
        final m = resolved[i];
        if (!m.isKnockout) continue;

        String newT1 = m.t1;
        String newT2 = m.t2;

        // Only reset if the routing points to group/3rd placeholders (not w## or l##)
        if (knockoutRouting.containsKey(m.id)) {
          final routing = knockoutRouting[m.id]!;
          if (!routing[0].startsWith('w') && !routing[0].startsWith('l')) {
            newT1 = routing[0];
          }
          if (!routing[1].startsWith('w') && !routing[1].startsWith('l')) {
            newT2 = routing[1];
          }
        }

        if (newT1.toLowerCase() == 'tbd') newT1 = 'TBD';
        if (newT2.toLowerCase() == 'tbd') newT2 = 'TBD';

        // Resolve group position placeholders (e.g., '1D' → 'us', '2K' → 'co')
        if (newT1.length == 2 &&
            (newT1.startsWith('1') || newT1.startsWith('2'))) {
          final pos = newT1.substring(0, 1);
          final grp = newT1.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final idx = int.parse(pos) - 1;
            if (idx < groupList.length) newT1 = groupList[idx].teamCode;
          }
        }
        if (newT2.length == 2 &&
            (newT2.startsWith('1') || newT2.startsWith('2'))) {
          final pos = newT2.substring(0, 1);
          final grp = newT2.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final idx = int.parse(pos) - 1;
            if (idx < groupList.length) newT2 = groupList[idx].teamCode;
          }
        }

        // Resolve 3rd-place placeholders (e.g., '3rd5' → 'sn')
        if (newT1.startsWith('3rd') && newT1.length > 3) {
          final idx = int.parse(newT1.substring(3)) - 1;
          if (idx >= 0 && idx < thirdPlaces.length) {
            newT1 = thirdPlaces[idx].teamCode;
          }
        }
        if (newT2.startsWith('3rd') && newT2.length > 3) {
          final idx = int.parse(newT2.substring(3)) - 1;
          if (idx >= 0 && idx < thirdPlaces.length) {
            newT2 = thirdPlaces[idx].teamCode;
          }
        }

        if (newT1 != m.t1 || newT2 != m.t2) {
          resolved[i] = m.copyWith(t1: newT1, t2: newT2);
        }
      }

      // Step 2: Now that R32 matches have real team codes, collect winners/losers
      for (final m in resolved) {
        if (m.isPlayed) {
          final winner = m.getWinner();
          if (winner.isNotEmpty) {
            matchWinners[m.id] = winner;
            matchLosers[m.id] = (winner == m.t1) ? m.t2 : m.t1;
          } else {
            // Draw (shouldn't happen in knockout, but handle gracefully)
            matchWinners[m.id] = m.t1;
            matchLosers[m.id] = m.t2;
          }
        }
      }

      // Step 3: Resolve w## and l## references using the now-correct winners/losers
      for (int i = 0; i < resolved.length; i++) {
        final m = resolved[i];
        if (!m.isKnockout) continue;

        String newT1 = m.t1;
        String newT2 = m.t2;

        if (knockoutRouting.containsKey(m.id)) {
          final routing = knockoutRouting[m.id]!;

          if (routing[0].startsWith('w') && routing[0].length > 1) {
            final refId = 'm${routing[0].substring(1)}';
            if (matchWinners.containsKey(refId)) {
              newT1 = matchWinners[refId]!;
            } else if (newT1.isEmpty || newT1.toUpperCase() == 'TBD' || newT1.startsWith('w')) {
              newT1 = routing[0];
            }
          } else if (routing[0].startsWith('l') && routing[0].length > 1) {
            final refId = 'm${routing[0].substring(1)}';
            if (matchLosers.containsKey(refId)) {
              newT1 = matchLosers[refId]!;
            } else if (newT1.isEmpty || newT1.toUpperCase() == 'TBD' || newT1.startsWith('l')) {
              newT1 = routing[0];
            }
          }

          if (routing[1].startsWith('w') && routing[1].length > 1) {
            final refId = 'm${routing[1].substring(1)}';
            if (matchWinners.containsKey(refId)) {
              newT2 = matchWinners[refId]!;
            } else if (newT2.isEmpty || newT2.toUpperCase() == 'TBD' || newT2.startsWith('w')) {
              newT2 = routing[1];
            }
          } else if (routing[1].startsWith('l') && routing[1].length > 1) {
            final refId = 'm${routing[1].substring(1)}';
            if (matchLosers.containsKey(refId)) {
              newT2 = matchLosers[refId]!;
            } else if (newT2.isEmpty || newT2.toUpperCase() == 'TBD' || newT2.startsWith('l')) {
              newT2 = routing[1];
            }
          }
        }

        if (newT1 != m.t1 || newT2 != m.t2) {
          resolved[i] = m.copyWith(t1: newT1, t2: newT2);
        }
      }
    }

    return resolved;
  }
}
