import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../services/prediction_service.dart';
import 'team_flag.dart';
import 'team_selector.dart';
import '../services/player_database_service.dart';
import '../services/api_service.dart';

// ─── Top-level name resolver (shared by all widgets in this file) ─────────────

/// Returns the best display name for a [PlayerStat].
/// Resolution order:
///   1. findCanonicalName — exact/accent-insensitive DB match
///   2. getBestMatchingName — fuzzy/partial match within the team squad
///   3. raw name as-is (if non-empty)
///   4. localised team name as last resort (when name is blank)
String _resolvePlayerName(PlayerStat player, String lang) {
  final raw = player.name.trim();
  final teamEn = AppTranslations.getTeam('en', player.teamCode);

  final canonical = PlayerDatabaseService.findCanonicalName(raw) ??
      PlayerDatabaseService.getBestMatchingName(teamEn, raw);

  return canonical ?? raw;
}

// ─── Shared leaderboard view (scorers & assists) ──────────────────────────────

class _LeaderboardView extends StatefulWidget {
  final List<PlayerStat> fullList;
  final List<WorldCupMatch> matches;
  final String lang;
  final String suffixIcon;
  final String emptyIcon;
  final String emptyTitleKey;
  final String emptySubtitleKey;
  final String? userPickName;
  final bool isFinished;

  const _LeaderboardView({
    required this.fullList,
    required this.matches,
    required this.lang,
    required this.suffixIcon,
    required this.emptyIcon,
    required this.emptyTitleKey,
    required this.emptySubtitleKey,
    this.userPickName,
    this.isFinished = false,
  });

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  String? _filterTeam;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Implements environment-aware sanitization to drop simulator artifacts.
  List<PlayerStat> get _sanitizedList {
    final bool isStaging = ApiService.isStagingMode;

    return widget.fullList.where((p) {
      final raw = p.name.trim();
      if (raw.isEmpty) return false;

      final teamEn = AppTranslations.getTeam('en', p.teamCode);
      final hasMatch = PlayerDatabaseService.findCanonicalName(raw) != null ||
          PlayerDatabaseService.getBestMatchingName(teamEn, raw) != null;

      // STAGING: Strict firewall - drop non-human entities
      if (isStaging) return hasMatch;

      // PRODUCTION: Permissive - keep all but try to resolve name
      return true;
    }).toList();
  }

  /// Convenience wrapper so widget methods don't need to pass lang explicitly.
  String _resolveDisplayName(PlayerStat player) =>
      _resolvePlayerName(player, widget.lang);

  List<String> get _nations {
    final seen = <String>{};
    final result = <String>[];
    for (final p in _sanitizedList) {
      if (seen.add(p.teamCode)) result.add(p.teamCode);
    }
    result.sort((a, b) => AppTranslations.getTeam(widget.lang, a)
        .compareTo(AppTranslations.getTeam(widget.lang, b)));
    return result;
  }

  List<PlayerStat> get _filtered {
    final sanitized = _sanitizedList;
    if (_filterTeam == null) return sanitized;
    return sanitized.where((p) => p.teamCode == _filterTeam).toList();
  }

  bool _isTeamActive(String teamCode) {
    for (final m in widget.matches) {
      if (m.isKnockout && m.isPlayed) {
        final winner = m.getWinner();
        if (m.t1.toLowerCase() == teamCode.toLowerCase() && winner != m.t1) {
          return false;
        }
        if (m.t2.toLowerCase() == teamCode.toLowerCase() && winner != m.t2) {
          return false;
        }
      }
    }
    return true;
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emptyIcon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              AppTranslations.get(widget.lang, widget.emptyTitleKey),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.get(widget.lang, widget.emptySubtitleKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Nation filter bar ──────────────────────────────────────────────────────

// ─── Nation filter bar (Improved UX) ────────────────────────────────────────

  Widget _buildFilterBar() {
    final nations = _nations;
    if (nations.length < 2) return const SizedBox.shrink();

    final hasFilter = _filterTeam != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          TeamSelectorBottomSheet.show(
            context: context,
            lang: widget.lang,
            title: AppTranslations.get(widget.lang, 'selectTeam'),
            selectedTeamCode: _filterTeam ?? nations.first,
            teamCodes: nations,
            onTeamSelected: (val) => setState(() => _filterTeam = val),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasFilter
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFilter ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (hasFilter)
                TeamFlagWidget(
                  code: _filterTeam!,
                  width: 28,
                  height: 18,
                  borderRadius: 4,
                )
              else
                const Icon(
                  Icons.public,
                  color: AppColors.textDim,
                  size: 22,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasFilter
                      ? AppTranslations.getTeam(widget.lang, _filterTeam!)
                      : AppTranslations.get(widget.lang, 'allNations'),
                  style: TextStyle(
                    color: hasFilter ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (hasFilter)
                GestureDetector(
                  onTap: () => setState(() => _filterTeam = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textDim,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Podium (top 3) ─────────────────────────────────────────────────────────

  Widget _buildPodium(List<PlayerStat> list) {
    if (_filterTeam != null || list.isEmpty) return const SizedBox.shrink();

    final podiumColors = [
      AppColors.warning,
      AppColors.textBody,
      AppColors.rankGold,
    ];
    final podiumBg = widget.isFinished
        ? [
      AppColors.warning.withValues(alpha: 0.12),
      AppColors.textMuted.withValues(alpha: 0.08),
      AppColors.rankGold.withValues(alpha: 0.10),
    ]
        : [AppColors.surface, AppColors.surface, AppColors.surface];

    // Visual order: 2nd | 1st | 3rd
    const podiumOrder = [1, 0, 2];
    const podiumHeights = [92.0, 116.0, 80.0];
    final available = list.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (vi) {
            final li = podiumOrder[vi];
            if (li >= available) return const Expanded(child: SizedBox());

            final player = list[li];
            final displayName = _resolveDisplayName(player);
            final teamNameEn =
            AppTranslations.getTeam('en', player.teamCode);
            final position = PlayerDatabaseService.getPlayerPosition(
              teamNameEn,
              displayName,
            );
            final isUserPick = PredictionService.isSamePlayer(
              widget.userPickName,
              player.name,
            );
            final isActive = _isTeamActive(player.teamCode);
            final color = widget.isFinished
                ? podiumColors[li]
                : (isActive
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.textDim);
            final bg = widget.isFinished
                ? podiumBg[li]
                : (isActive
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.surface);
            final colHeight = podiumHeights[vi];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Flag
                    TeamFlagWidget(
                      code: player.teamCode,
                      width: 28,
                      height: 19,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 6),
                    // Full name — wraps to 2 lines if needed
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: li == 0 ? 11.5 : 10.5,
                        height: 1.15,
                      ),
                    ),
                    // Position badge
                    if (position != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        position.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Podium block — full width, score centred
                    Container(
                      width: double.infinity,
                      height: colHeight,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        border: Border.all(
                          color: isUserPick
                              ? AppColors.accent
                              : color.withValues(
                              alpha: isActive ? 0.6 : 0.2),
                          width: isUserPick ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.suffixIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${player.value}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: li == 0 ? 24 : 19,
                              height: 1.0,
                            ),
                          ),
                          if (isUserPick) ...[
                            const SizedBox(height: 2),
                            Builder(builder: (context) {
                              final bool isCorrect = PredictionService.isScorerPredictionCorrect(player.name, widget.matches);
                              return Text(
                                isCorrect ? '✅' : '🎯',
                                style: const TextStyle(fontSize: 12),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Stat row (rank 4+) ─────────────────────────────────────────────────────

  Widget _buildStatRow(
      BuildContext context,
      int index,
      int globalIndex,
      PlayerStat item,
      int maxValue,
      bool isUserChoice,
      ) {
    final teamName = AppTranslations.getTeam(widget.lang, item.teamCode);
    final barRatio = maxValue > 0 ? item.value / maxValue : 0.0;

    // Removed the isActive variable here

    final displayName = _resolveDisplayName(item);
    final teamNameEn = AppTranslations.getTeam('en', item.teamCode);
    final position =
    PlayerDatabaseService.getPlayerPosition(teamNameEn, displayName);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isUserChoice
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUserChoice
              ? AppColors.accent
              : AppColors.border,
          width: isUserChoice ? 2.0 : 1.5,
        ),
        boxShadow: isUserChoice
            ? [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Rank badge ──────────────────────────────────────────────
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: globalIndex == 0
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : globalIndex == 1
                      ? AppColors.textMuted.withValues(alpha: 0.15)
                      : globalIndex == 2
                      ? AppColors.rankGold.withValues(alpha: 0.15)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${globalIndex + 1}',
                  style: TextStyle(
                    color: globalIndex == 0
                        ? AppColors.warning
                        : globalIndex == 1
                        ? AppColors.textBody
                        : globalIndex == 2
                        ? AppColors.rankGold
                        : AppColors.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Flag ────────────────────────────────────────────────────
              TeamFlagWidget(
                code: item.teamCode,
                width: 24,
                height: 16,
                borderRadius: 4,
              ),
              const SizedBox(width: 12),

              // ── Name + position badge + prono tag ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (position != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              AppColors.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              AppTranslations.get(widget.lang, 'pos_$position').toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        if (isUserChoice) ...[
                          const SizedBox(width: 6),
                          Builder(builder: (context) {
                            final bool isCorrect = PredictionService.isScorerPredictionCorrect(item.name, widget.matches);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCorrect ? AppColors.warning : AppColors.accent).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: isCorrect ? Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1) : null,
                              ),
                              child: Text(
                                isCorrect ? 'CORRECT ✅' : 'MY PRONO 🎯',
                                style: TextStyle(
                                  color: isCorrect ? AppColors.warning : AppColors.accent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      teamName,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ── Score pill ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.suffixIcon,
                        style: const TextStyle(fontSize: 11)),
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

          // ── Progress bar ────────────────────────────────────────────────
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: constraints.maxWidth * barRatio,
                    decoration: BoxDecoration(
                      color: isUserChoice
                          ? AppColors.accent
                          : globalIndex == 0
                          ? AppColors.warning
                          : globalIndex == 1
                          ? AppColors.textBody
                          : globalIndex == 2
                          ? AppColors.rankGold
                          : AppColors.accent
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sanitized = _sanitizedList;
    if (sanitized.isEmpty) return _buildEmptyState();

    final filtered = _filtered;
    final displayList =
    filtered.length > 25 ? filtered.sublist(0, 25) : filtered;
    final maxValue =
    displayList.isNotEmpty ? displayList.first.value : 1;
    final showPodium = _filterTeam == null;

    return Column(
      children: [
        const SizedBox(height: 12),
        _buildFilterBar(),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: displayList.length + (showPodium ? 1 : 0),
            itemBuilder: (context, i) {
              if (showPodium && i == 0) {
                return _buildPodium(sanitized);
              }
              final listIndex = showPodium ? i - 1 : i;
              final item = displayList[listIndex];
              final globalIndex = sanitized.indexOf(item);
              final isUserChoice = PredictionService.isSamePlayer(
                  widget.userPickName, item.name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildStatRow(
                  context,
                  listIndex,
                  globalIndex,
                  item,
                  maxValue,
                  isUserChoice,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Public leaderboard widgets ───────────────────────────────────────────────

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
    final list = TournamentStats.compute(matches).scorers;
    final isFinished =
    matches.any((m) => m.id == 'm80' && m.isPlayed);
    return _LeaderboardView(
      fullList: list,
      matches: matches,
      lang: lang,
      suffixIcon: '⚽',
      emptyIcon: '⚽',
      emptyTitleKey: 'leaderboardUnavailable',
      emptySubtitleKey: 'statsUnlockGoals',
      userPickName: userPreds?.goldenBootPlayer,
      isFinished: isFinished,
    );
  }
}

// ─── Team stats widget ────────────────────────────────────────────────────────

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
    _initializeDefaultTeam();
  }

  void _initializeDefaultTeam() {
    // Try to find the first team that has played a match
    String? firstPlayedTeam;
    for (final m in widget.matches) {
      if (m.isPlayed) {
        firstPlayedTeam = m.t1.toLowerCase();
        break;
      }
    }
    _selectedTeam = firstPlayedTeam ?? 'fr';
  }

  List<String> _getSortedQualifiedTeams() {
    final Set<String> qualifiedCodes = {};
    for (final m in widget.matches) {
      bool isValidCountryCode(String code) {
        final c = code.toLowerCase();
        if (c == 'tbd') return false;
        if (c.contains(RegExp(r'[0-9]'))) return false;
        if ((c.startsWith('w') || c.startsWith('l')) && c.length > 3) {
          return false;
        }
        return true;
      }

      if (isValidCountryCode(m.t1)) qualifiedCodes.add(m.t1.toLowerCase());
      if (isValidCountryCode(m.t2)) qualifiedCodes.add(m.t2.toLowerCase());
    }
    return qualifiedCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));
  }

  String _getTeamGroup(String teamCode) {
    for (final m in widget.matches) {
      if (m.group != null && m.group!.isNotEmpty) {
        if (m.t1.toLowerCase() == teamCode.toLowerCase() ||
            m.t2.toLowerCase() == teamCode.toLowerCase()) {
          return m.group!;
        }
      }
    }
    return '';
  }

  Widget _buildFormBadge(String result) {
    Color color;
    final label = result.toUpperCase();
    if (label == 'W' || label == 'V') {
      color = AppColors.accent;
    } else if (label == 'D' || label == 'N') {
      color = AppColors.textMuted;
    } else {
      color = AppColors.danger;
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
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedTeams = _getSortedQualifiedTeams();
    final currentTeam = _selectedTeam ?? 'fr';

    final teamMatches = widget.matches
        .where((m) => m.t1 == currentTeam || m.t2 == currentTeam)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int goalsScored = 0;
    int goalsConceded = 0;
    int played = 0;
    final formHistory = <String>[];

    for (final m in teamMatches) {
      if (m.isPlayed) {
        played++;
        final isT1 = m.t1 == currentTeam;
        final scoreSelf = isT1 ? m.t1Score! : m.t2Score!;
        final scoreOpp = isT1 ? m.t2Score! : m.t1Score!;
        goalsScored += scoreSelf;
        goalsConceded += scoreOpp;
        if (scoreSelf > scoreOpp) {
          formHistory.add(AppTranslations.get(widget.lang, 'formWin'));
        } else if (scoreSelf < scoreOpp) {
          formHistory.add('L');
        } else {
          formHistory.add(AppTranslations.get(widget.lang, 'formDraw'));
        }
      }
    }

    final teamEmblemName =
    AppTranslations.getTeamWithEmblem(widget.lang, currentTeam);
    final teamRealGroup = _getTeamGroup(currentTeam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Team selector
          GestureDetector(
            onTap: () {
              TeamSelectorBottomSheet.show(
                context: context,
                lang: widget.lang,
                title: AppTranslations.get(widget.lang, 'selectTeam'),
                selectedTeamCode: currentTeam,
                teamCodes: sortedTeams,
                onTeamSelected: (val) => setState(() => _selectedTeam = val),
              );
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      borderRadius: 6),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.getTeam(widget.lang, currentTeam),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textDim, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Team banner
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
                    borderRadius: 4),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teamEmblemName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      if (teamRealGroup.isNotEmpty)
                        Text(
                          '${AppTranslations.get(widget.lang, 'group')} $teamRealGroup',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Stats grid
          Row(
            children: [
              _buildStatCard(
                AppTranslations.get(widget.lang, 'matchesPlayed'),
                '$played',
                Icons.sports_soccer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(widget.lang, 'recentForm'),
                        style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      formHistory.isEmpty
                          ? Text(
                        AppTranslations.get(
                            widget.lang, 'noMatchesPlayed'),
                        style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      )
                          : Row(
                        children: formHistory
                            .map(_buildFormBadge)
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                AppTranslations.get(widget.lang, 'goalsScored'),
                '$goalsScored',
                Icons.arrow_upward,
                color: AppColors.accent,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                AppTranslations.get(widget.lang, 'goalsConceded'),
                '$goalsConceded',
                Icons.arrow_downward,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Team matches
          Text(
            AppTranslations.get(widget.lang, 'allMatches'),
            style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teamMatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (c, i) =>
                _buildCompactMatchCard(context, teamMatches[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon, {
        Color? color,
      }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
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
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            TeamFlagWidget(
                code: m.t1, width: 18, height: 12, borderRadius: 2),
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
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.isPlayed)
                        Text('${m.t1Score}',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(t2Name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.isPlayed)
                        Text('${m.t2Score}',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TeamFlagWidget(
                code: m.t2, width: 18, height: 12, borderRadius: 2),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 12),
            if (m.isPlayed)
              const Text('FIN',
                  style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 10))
            else
              Text(m.getFormattedTime(),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
          ],
        ),
      ),
    );
  }
}