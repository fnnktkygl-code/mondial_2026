import 'dart:math';
import '../models/match.dart';
import '../app_constants.dart';
import '../utils/fifa_rules.dart';

class TeamGroupStats {
  final String teamCode;
  int played = 0;
  int points = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int fairPlay = 0;
  int get goalDifference => goalsFor - goalsAgainst;

  TeamGroupStats(this.teamCode);
}

class WCOddsService {
  /// Calculates title winning odds (probabilities) for all teams based on current match states.
  static Map<String, double> calculateOdds(List<WorldCupMatch> resolvedMatches) {
    // 1. Gather all unique team codes
    final Set<String> allTeams = {};
    for (final m in resolvedMatches) {
      if (m.group != null && m.group!.isNotEmpty) {
        allTeams.add(m.t1.toLowerCase());
        allTeams.add(m.t2.toLowerCase());
      }
    }

    if (allTeams.isEmpty) return {};

    // 2. Identify winner and losers of played knockout matches
    final Map<String, String> matchWinners = {};
    final Map<String, String> matchLosers = {};
    for (final m in resolvedMatches) {
      if (m.isKnockout && m.isPlayed) {
        if (m.t1Score! > m.t2Score!) {
          matchWinners[m.id] = m.t1.toLowerCase();
          matchLosers[m.id] = m.t2.toLowerCase();
        } else if (m.t2Score! > m.t1Score!) {
          matchWinners[m.id] = m.t2.toLowerCase();
          matchLosers[m.id] = m.t1.toLowerCase();
        } else {
          // If a knockout match is played and somehow tied, check shootout winner or fallback
          final winner = m.pkWinner ?? m.etWinner ?? m.t1;
          matchWinners[m.id] = winner.toLowerCase();
          matchLosers[m.id] = (winner.toLowerCase() == m.t1.toLowerCase()) 
              ? m.t2.toLowerCase() 
              : m.t1.toLowerCase();
        }
      }
    }

    // 3. Short-circuit: If the Final (m80) is finished, that team is 100%, others 0%
    final finalMatch = resolvedMatches.firstWhere(
      (m) => m.id == kFinalMatchId,
      orElse: () => resolvedMatches.lastWhere((m) => m.isKnockout, orElse: () => resolvedMatches.last),
    );

    if (finalMatch.id == kFinalMatchId && finalMatch.isPlayed) {
      final Map<String, double> result = {};
      final winner = matchWinners[kFinalMatchId] ?? (finalMatch.pkWinner ?? finalMatch.etWinner)?.toLowerCase() ?? (finalMatch.t1Score! > finalMatch.t2Score! ? finalMatch.t1 : finalMatch.t2).toLowerCase();
      
      for (final t in allTeams) {
        result[t] = (t == winner) ? 100.0 : 0.0;
      }
      return result;
    }

    // 4. Calculate Group Standings to check group progression & points boost
    final Map<String, List<TeamGroupStats>> groupStandings = {};
    int totalGroupMatchesPlayed = 0;
    int totalGroupMatches = 0;

    for (final m in resolvedMatches) {
      if (m.group != null && m.group!.isNotEmpty) {
        totalGroupMatches++;
        if (m.isPlayed) {
          totalGroupMatchesPlayed++;
        }
        final grp = m.group!;
        groupStandings.putIfAbsent(grp, () => []);
        final list = groupStandings[grp]!;
        if (!list.any((e) => e.teamCode.toLowerCase() == m.t1.toLowerCase())) {
          list.add(TeamGroupStats(m.t1.toLowerCase()));
        }
        if (!list.any((e) => e.teamCode.toLowerCase() == m.t2.toLowerCase())) {
          list.add(TeamGroupStats(m.t2.toLowerCase()));
        }

        if (m.isPlayed) {
          final t1Entry = list.firstWhere((e) => e.teamCode.toLowerCase() == m.t1.toLowerCase());
          final t2Entry = list.firstWhere((e) => e.teamCode.toLowerCase() == m.t2.toLowerCase());
          t1Entry.played++;
          t2Entry.played++;
          t1Entry.goalsFor += m.t1Score!;
          t1Entry.goalsAgainst += m.t2Score!;
          t2Entry.goalsFor += m.t2Score!;
          t2Entry.goalsAgainst += m.t1Score!;

          if (m.t1Score! > m.t2Score!) {
            t1Entry.points += 3;
          } else if (m.t1Score! < m.t2Score!) {
            t2Entry.points += 3;
          } else {
            t1Entry.points += 1;
            t2Entry.points += 1;
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
      }
    }

    // Sort group standings
    groupStandings.forEach((grp, list) {
      FIFARegulations.sortStandings(list, resolvedMatches);
    });

    // 5. Build list of eliminated teams
    final Set<String> eliminatedTeams = {};

    // A. Lost in any played knockout match
    eliminatedTeams.addAll(matchLosers.values);

    // B. Group finished and team is 4th
    groupStandings.forEach((grp, list) {
      final int groupPlayedCount = resolvedMatches.where((m) => m.group == grp && m.isPlayed).length;
      if (groupPlayedCount == 6 && list.length >= 4) {
        eliminatedTeams.add(list[3].teamCode.toLowerCase());
      }
    });

    // C. Group Stage entirely finished and team not in Round of 32
    final bool groupStageFinished = totalGroupMatchesPlayed == totalGroupMatches && totalGroupMatches > 0;
    if (groupStageFinished) {
      final Set<String> r32Teams = {};
      for (final m in resolvedMatches) {
        if (m.stage == 'Round of 32') {
          if (m.t1.toLowerCase() != 'tbd') r32Teams.add(m.t1.toLowerCase());
          if (m.t2.toLowerCase() != 'tbd') r32Teams.add(m.t2.toLowerCase());
        }
      }
      for (final t in allTeams) {
        if (!r32Teams.contains(t.toLowerCase())) {
          eliminatedTeams.add(t.toLowerCase());
        }
      }
    }

    // 6. Find highest stage reached by active teams
    final Map<String, int> teamHighestStage = {};
    for (final t in allTeams) {
      teamHighestStage[t.toLowerCase()] = 0; // default 0: Group Stage
    }

    for (final m in resolvedMatches) {
      if (m.isKnockout) {
        final t1 = m.t1.toLowerCase();
        final t2 = m.t2.toLowerCase();
        
        int stageVal = 1; // Round of 32
        if (m.stage == 'Round of 16') stageVal = 2;
        else if (m.stage == 'Quarter-Final') stageVal = 3;
        else if (m.stage == 'Semi-Final') stageVal = 4;
        else if (m.stage == 'Final') stageVal = 5;

        if (t1 != 'tbd') {
          teamHighestStage[t1] = max(teamHighestStage[t1] ?? 0, stageVal);
        }
        if (t2 != 'tbd') {
          teamHighestStage[t2] = max(teamHighestStage[t2] ?? 0, stageVal);
        }
      }
    }

    // 7. Calculate weight for each team
    final Map<String, double> weights = {};
    double totalWeight = 0.0;

    for (final t in allTeams) {
      final lowerTeam = t.toLowerCase();
      if (eliminatedTeams.contains(lowerTeam)) {
        weights[lowerTeam] = 0.0;
        continue;
      }

      final rating = kTeamRatings[lowerTeam] ?? 70;
      // Weight proportional to rating^4.5 (rewards elite teams more realistically)
      final double basePower = pow(rating.toDouble(), 4.5).toDouble();

      final stage = teamHighestStage[lowerTeam] ?? 0;
      double multiplier = 1.0;

      if (stage == 0) {
        // Group stage: boost based on points
        int points = 0;
        for (final list in groupStandings.values) {
          final found = list.where((e) => e.teamCode == lowerTeam);
          if (found.isNotEmpty) {
            points = found.first.points;
            break;
          }
        }
        multiplier = 1.0 + (points * 0.15); // max 2.35x for 9 points
      } else if (stage == 1) {
        multiplier = 3.5;
      } else if (stage == 2) {
        multiplier = 9.0;
      } else if (stage == 3) {
        multiplier = 24.0;
      } else if (stage == 4) {
        multiplier = 65.0;
      } else if (stage == 5) {
        multiplier = 180.0;
      }

      final double w = basePower * multiplier;
      weights[lowerTeam] = w;
      totalWeight += w;
    }

    // 8. Normalize to 100%
    final Map<String, double> normalizedOdds = {};
    final activeCount = allTeams.length - eliminatedTeams.length;

    for (final t in allTeams) {
      final lowerTeam = t.toLowerCase();
      if (eliminatedTeams.contains(lowerTeam)) {
        normalizedOdds[lowerTeam] = 0.0;
      } else {
        if (totalWeight > 0.0) {
          normalizedOdds[lowerTeam] = (weights[lowerTeam]! / totalWeight) * 100.0;
        } else {
          normalizedOdds[lowerTeam] = 100.0 / (activeCount > 0 ? activeCount : 1);
        }
      }
    }

    return normalizedOdds;
  }
}
