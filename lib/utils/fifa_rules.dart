import '../models/match.dart';
import '../services/team_profile_service.dart';

class H2HStats {
  int points = 0;
  int gd = 0;
  int gf = 0;
}

class FIFARegulations {
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
      // 1. Overall Points
      if (b.points != a.points) return b.points.compareTo(a.points);

      // 2. Overall Goal Difference
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }

      // 3. Overall Goals For
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);

      // 4. Head-to-Head criteria
      final tiedTeamCodes = teams
          .where(
            (t) =>
                t.points == a.points &&
                t.goalDifference == a.goalDifference &&
                t.goalsFor == a.goalsFor,
          )
          .map<String>((t) => t.teamCode as String)
          .toSet();

      if (tiedTeamCodes.length > 1) {
        final statsA = calculateH2HStats(
          a.teamCode as String,
          tiedTeamCodes,
          matches,
        );
        final statsB = calculateH2HStats(
          b.teamCode as String,
          tiedTeamCodes,
          matches,
        );

        if (statsB.points != statsA.points) {
          return statsB.points.compareTo(statsA.points);
        }
        if (statsB.gd != statsA.gd) return statsB.gd.compareTo(statsA.gd);
        if (statsB.gf != statsA.gf) return statsB.gf.compareTo(statsA.gf);
      }

      // 5. Fair Play points (closer to 0 is better, e.g. -1 is better than -3)
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);

      // 6. FIFA World Ranking
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode as String);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode as String);
      if (rankA != rankB) {
        return rankA.compareTo(
          rankB,
        ); // Lower rank is better (1st is better than 2nd)
      }

      // 7. Alphabetical fallback
      return (a.teamCode as String).compareTo(b.teamCode as String);
    });
  }
}
