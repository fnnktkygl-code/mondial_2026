import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import '../services/team_profile_service.dart';
import '../services/prediction_service.dart';
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
  final PredictionData? userPreds;

  const ScorersLeaderboardWidget({
    super.key,
    required this.matches,
    required this.lang,
    this.userPreds,
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
        final isUserChoice = userPreds?.goldenBootPlayer?.trim().toLowerCase() == item.name.trim().toLowerCase();
        return _buildStatRow(context, index, item, '⚽', isUserChoice);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer_rounded, size: 56, color: AppColors.borderStrong),
            const SizedBox(height: 16),
            Text(
              AppTranslations.get(lang, 'leaderboardUnavailable'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.get(lang, 'statsUnlockGoals'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, int index, PlayerStat item, String suffixIcon, bool isUserChoice) {
    final teamName = AppTranslations.getTeam(lang, item.teamCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isUserChoice ? AppColors.accent : AppColors.border,
            width: isUserChoice ? 2.0 : 1.5
        ),
        boxShadow: isUserChoice ? [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)
        ] : null,
      ),
      child: Row(
        children: [
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

          TeamFlagWidget(
            code: item.teamCode,
            width: 24,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUserChoice) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MY PRONO 🎯',
                          style: TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
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
  final PredictionData? userPreds;

  const AssistsLeaderboardWidget({
    super.key,
    required this.matches,
    required this.lang,
    this.userPreds,
  });

  @override
  Widget build(BuildContext context) {
    final stats = TournamentStats.compute(matches);
    final list = stats.assists;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_outline_rounded, size: 56, color: AppColors.borderStrong),
              const SizedBox(height: 16),
              Text(
                AppTranslations.get(lang, 'leaderboardUnavailable'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.get(lang, 'statsUnlockAssists'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length > 25 ? 25 : list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        final isUserChoice = userPreds?.topAssisterPlayer?.trim().toLowerCase() == item.name.trim().toLowerCase();
        return ScorersLeaderboardWidget(matches: matches, lang: lang, userPreds: userPreds)
            ._buildStatRow(context, index, item, '👟', isUserChoice);
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
    _selectedTeam = 'fr'; // France par défaut
  }

  // Permet d'extraire uniquement les équipes qualifiées (pour éviter les équipes fantômes)
  List<String> _getSortedQualifiedTeams() {
    final Set<String> qualifiedCodes = {};
    for (final m in widget.matches) {
      bool isValidCountryCode(String code) {
        final c = code.toLowerCase();
        if (c == 'tbd') return false;
        if (c.contains(RegExp(r'[0-9]'))) return false;
        if ((c.startsWith('w') || c.startsWith('l')) && c.length > 3) return false;
        return true;
      }

      if (isValidCountryCode(m.t1)) qualifiedCodes.add(m.t1.toLowerCase());
      if (isValidCountryCode(m.t2)) qualifiedCodes.add(m.t2.toLowerCase());
    }
    return qualifiedCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));
  }

  // Algorithme d'extraction du vrai groupe de l'équipe à partir des matchs
  String _getTeamGroup(String teamCode) {
    for (final m in widget.matches) {
      if (m.group != null && m.group!.isNotEmpty) {
        if (m.t1.toLowerCase() == teamCode.toLowerCase() || m.t2.toLowerCase() == teamCode.toLowerCase()) {
          return m.group!;
        }
      }
    }
    return '';
  }

  // Construit les badges de forme colorés (Standard UX Sofascore/Flashscore)
  Widget _buildFormBadge(String result) {
    Color color;
    String label = result.toUpperCase();

    if (label == 'W' || label == 'V') {
      color = AppColors.accent; // Vert
    } else if (label == 'D' || label == 'N') {
      color = AppColors.textMuted; // Gris
    } else {
      color = AppColors.danger; // Rouge
    }

    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sortedTeams = _getSortedQualifiedTeams();
    final currentTeam = _selectedTeam ?? 'fr';

    final teamMatches = widget.matches
        .where((m) => m.t1 == currentTeam || m.t2 == currentTeam)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int goalsScored = 0;
    int goalsConceded = 0;
    int wins = 0;
    int draws = 0;
    int losses = 0;
    int played = 0;
    List<String> formHistory = [];

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
          formHistory.add(AppTranslations.get(widget.lang, 'formWin'));
        } else if (scoreSelf < scoreOpp) {
          losses++;
          formHistory.add('L');
        } else {
          draws++;
          formHistory.add(AppTranslations.get(widget.lang, 'formDraw'));
        }
      }
    }

    final stats = TournamentStats.compute(widget.matches);
    final teamScorers = stats.scorers.where((p) => p.teamCode == currentTeam).toList();
    final teamAssists = stats.assists.where((p) => p.teamCode == currentTeam).toList();
    final teamEmblemName = AppTranslations.getTeamWithEmblem(widget.lang, currentTeam);
    final teamRealGroup = _getTeamGroup(currentTeam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector
          GestureDetector(
            onTap: () {
              TeamSelectorBottomSheet.show(
                context: context,
                lang: widget.lang,
                title: AppTranslations.get(widget.lang, 'selectTeam'),
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
                      // Correction : Affichage dynamique du groupe réel du tournoi
                      if (teamRealGroup.isNotEmpty)
                        Text(
                          '${AppTranslations.get(widget.lang, 'group')} $teamRealGroup',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
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

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(widget.lang, 'recentForm'),
                        style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      formHistory.isEmpty
                          ? Text(AppTranslations.get(widget.lang, 'noMatchesPlayed'), style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontStyle: FontStyle.italic))
                          : Row(children: formHistory.map((res) => _buildFormBadge(res)).toList()),
                    ],
                  ),
                ),
              ),
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
                      Text(AppTranslations.get(widget.lang, 'scorers'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                child: Text(p.name,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('${p.value} ⚽',
                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      Text(AppTranslations.get(widget.lang, 'assists'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                child: Text(p.name,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('${p.value} 👟',
                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
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

          // 5. Team Matches
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
            itemBuilder: (c, i) => _buildCompactMatchCard(context, teamMatches[i]),
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
                  Text(label,
                      style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
            TeamFlagWidget(code: m.t1, width: 18, height: 12, borderRadius: 2),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(t1Name,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.isPlayed)
                        Text('${m.t1Score}',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(t2Name,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.isPlayed)
                        Text('${m.t2Score}',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TeamFlagWidget(code: m.t2, width: 18, height: 12, borderRadius: 2),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 12),
            if (m.isPlayed)
              const Text('FIN',
                  style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 10))
            else
              Text(m.getFormattedTime(),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}