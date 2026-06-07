import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../services/team_profile_service.dart';
import 'team_flag.dart';
import 'team_selector.dart';

class PlayerStat {
  final String name;
  final int value;
  final String teamCode;

  PlayerStat({
    required this.name,
    required this.value,
    required this.teamCode,
  });
}

class TournamentStats {
  final List<PlayerStat> scorers;
  final List<PlayerStat> assists;

  TournamentStats({
    required this.scorers,
    required this.assists,
  });

  factory TournamentStats.compute(List<WorldCupMatch> matches) {
    final Map<String, int> goalCounts = {};
    final Map<String, int> assistCounts = {};
    final Map<String, String> playerTeams = {};

    for (final match in matches) {
      if (match.isPlayed) {
        for (final goal in match.goals) {
          final scorerName = goal.scorer.trim();
          if (scorerName.isNotEmpty) {
            goalCounts[scorerName] = (goalCounts[scorerName] ?? 0) + 1;
            playerTeams[scorerName] = goal.team == 't1' ? match.t1 : match.t2;
          }

          final assistantName = goal.assistant?.trim();
          if (assistantName != null && assistantName.isNotEmpty) {
            assistCounts[assistantName] = (assistCounts[assistantName] ?? 0) + 1;
            playerTeams[assistantName] = goal.team == 't1' ? match.t1 : match.t2;
          }
        }
      }
    }

    final List<PlayerStat> scorersList = goalCounts.entries.map((e) {
      return PlayerStat(
        name: e.key,
        value: e.value,
        teamCode: playerTeams[e.key] ?? 'tbd',
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<PlayerStat> assistsList = assistCounts.entries.map((e) {
      return PlayerStat(
        name: e.key,
        value: e.value,
        teamCode: playerTeams[e.key] ?? 'tbd',
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return TournamentStats(scorers: scorersList, assists: assistsList);
  }
}

class ScorersLeaderboardWidget extends StatelessWidget {
  final List<WorldCupMatch> matches;
  final String lang;

  const ScorersLeaderboardWidget({
    super.key,
    required this.matches,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final stats = TournamentStats.compute(matches);
    final list = stats.scorers;

    if (list.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length > 25 ? 25 : list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildStatRow(context, index, item, '⚽');
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, size: 48, color: AppColors.borderStrong),
          const SizedBox(height: 16),
          Text(
            AppTranslations.get(lang, 'loading'),
            style: const TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, int index, PlayerStat item, String suffixIcon) {
    final teamName = AppTranslations.getTeam(lang, item.teamCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index == 0
                  ? AppColors.rankGold.withOpacity(0.2)
                  : index == 1
                      ? AppColors.textMuted.withOpacity(0.2)
                      : index == 2
                          ? AppColors.rankGold.withOpacity(0.2)
                          : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: index == 0
                    ? AppColors.warning
                    : index == 1
                        ? AppColors.textBody
                        : index == 2
                            ? AppColors.rankGold
                            : AppColors.textDim,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Flag Image
          TeamFlagWidget(
            code: item.teamCode,
            width: 22,
            height: 14,
            borderRadius: 2,
          ),
          const SizedBox(width: 12),

          // Player Name & Team Nickname
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Value Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suffixIcon,
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.value}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssistsLeaderboardWidget extends StatelessWidget {
  final List<WorldCupMatch> matches;
  final String lang;

  const AssistsLeaderboardWidget({
    super.key,
    required this.matches,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final stats = TournamentStats.compute(matches);
    final list = stats.assists;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_outline, size: 48, color: AppColors.borderStrong),
            const SizedBox(height: 16),
            Text(
              AppTranslations.get(lang, 'loading'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length > 25 ? 25 : list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        // Using running shoes / boots or star emoji for assists
        return ScorersLeaderboardWidget(matches: matches, lang: lang)
            ._buildStatRow(context, index, item, '👟');
      },
    );
  }
}

class TeamStatsWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final Function(WorldCupMatch match) onMatchTap;

  const TeamStatsWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.onMatchTap,
  });

  @override
  State<TeamStatsWidget> createState() => _TeamStatsWidgetState();
}

class _TeamStatsWidgetState extends State<TeamStatsWidget> {
  String? _selectedTeam;

  @override
  void initState() {
    super.initState();
    // Default to the first team alphabetically, e.g., 'de' or 'ar'
    _selectedTeam = 'fr'; // France by default
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sortedTeams = WCTeamProfileService.allTeams
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));

    final currentTeam = _selectedTeam ?? 'fr';

    // Compute stats for currentTeam
    final teamMatches = widget.matches.where((m) => m.t1 == currentTeam || m.t2 == currentTeam).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int goalsScored = 0;
    int goalsConceded = 0;
    int wins = 0;
    int draws = 0;
    int losses = 0;
    int played = 0;

    for (final m in teamMatches) {
      if (m.isPlayed) {
        played++;
        final isT1 = m.t1 == currentTeam;
        final scoreSelf = isT1 ? m.t1Score! : m.t2Score!;
        final scoreOpp = isT1 ? m.t2Score! : m.t1Score!;
        goalsScored += scoreSelf;
        goalsConceded += scoreOpp;
        
        if (scoreSelf > scoreOpp) {
          wins++;
        } else if (scoreSelf < scoreOpp) {
          losses++;
        } else {
          draws++;
        }
      }
    }

    final stats = TournamentStats.compute(widget.matches);
    final teamScorers = stats.scorers.where((p) => p.teamCode == currentTeam).toList();
    final teamAssists = stats.assists.where((p) => p.teamCode == currentTeam).toList();

    final teamEmblemName = AppTranslations.getTeamWithEmblem(widget.lang, currentTeam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector Dropdown
          GestureDetector(
            onTap: () {
              TeamSelectorBottomSheet.show(
                context: context,
                lang: widget.lang,
                title: widget.lang == 'fr' ? 'Sélectionner une équipe' : 'Select a team',
                selectedTeamCode: currentTeam,
                teamCodes: sortedTeams,
                onTeamSelected: (val) {
                  setState(() {
                    _selectedTeam = val;
                  });
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  TeamFlagWidget(
                    code: currentTeam,
                    width: 32,
                    height: 22,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.getTeam(widget.lang, currentTeam),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Team Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                TeamFlagWidget(
                  code: currentTeam,
                  width: 52,
                  height: 32,
                  borderRadius: 4,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamEmblemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppTranslations.get(widget.lang, 'group')} ${currentTeam == 'en' ? 'B' : currentTeam.toUpperCase()}', // Simplified group mapping
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Stats Grid
          Row(
            children: [
              _buildStatCard(AppTranslations.get(widget.lang, 'matchesPlayed'), '$played', Icons.sports_soccer),
              const SizedBox(width: 12),
              _buildStatCard('W - D - L', '$wins - $draws - $losses', Icons.insights),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(AppTranslations.get(widget.lang, 'goalsScored'), '$goalsScored', Icons.arrow_upward, color: AppColors.accent),
              const SizedBox(width: 12),
              _buildStatCard(AppTranslations.get(widget.lang, 'goalsConceded'), '$goalsConceded', Icons.arrow_downward, color: AppColors.danger),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Squad Leaders
          Text(
            AppTranslations.get(widget.lang, 'squadStats'),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scorers List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(widget.lang, 'scorers'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      if (teamScorers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('-', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                        )
                      else
                        ...teamScorers.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${p.value} ⚽',
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Assists List
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(widget.lang, 'assists'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      if (teamAssists.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('-', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                        )
                      else
                        ...teamAssists.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${p.value} 👟',
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Team Matches List
          Text(
            AppTranslations.get(widget.lang, 'allMatches'),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teamMatches.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final m = teamMatches[i];
              return _buildCompactMatchCard(context, m);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMatchCard(BuildContext context, WorldCupMatch m) {
    final t1Name = AppTranslations.getTeamWithEmblem(widget.lang, m.t1);
    final t2Name = AppTranslations.getTeamWithEmblem(widget.lang, m.t2);

    return GestureDetector(
      onTap: () => widget.onMatchTap(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Team 1 flag
            TeamFlagWidget(
              code: m.t1,
              width: 18,
              height: 12,
              borderRadius: 2,
            ),
            const SizedBox(width: 8),

            // Teams Names & Scores
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t1Name,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.isPlayed)
                        Text(
                          '${m.t1Score}',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t2Name,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.isPlayed)
                        Text(
                          '${m.t2Score}',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Team 2 flag
            TeamFlagWidget(
              code: m.t2,
              width: 18,
              height: 12,
              borderRadius: 2,
            ),
            const SizedBox(width: 12),

            // Divider line
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 12),

            // Time or Play Status indicator
            if (m.isPlayed)
              const Text(
                'FIN',
                style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 10),
              )
            else
              Text(
                m.getFormattedTime(),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
