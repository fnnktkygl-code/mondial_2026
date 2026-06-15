import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../l10n/translations.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import 'team_flag.dart';
import 'wc_tooltip.dart';
import 'profile_dialog.dart';

class PlayerHistoryDialog extends StatefulWidget {
  final PredictionData predictionData;
  final List<WorldCupMatch> allMatches;
  final String lang;
  final bool viewingOwnHistory;

  const PlayerHistoryDialog({
    super.key,
    required this.predictionData,
    required this.allMatches,
    required this.lang,
    required this.viewingOwnHistory,
  });

  static void show({
    required BuildContext context,
    required PredictionData predictionData,
    required List<WorldCupMatch> allMatches,
    required String lang,
    required bool viewingOwnHistory,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => PlayerHistoryDialog(
        predictionData: predictionData,
        allMatches: allMatches,
        lang: lang,
        viewingOwnHistory: viewingOwnHistory,
      ),
    );
  }

  @override
  State<PlayerHistoryDialog> createState() => _PlayerHistoryDialogState();
}

class _PlayerHistoryDialogState extends State<PlayerHistoryDialog> {
  int _activeTabIndex = 0; // 0: Info & Badges, 1: Predictions History
  bool _pronounsHistoryExpanded = false;
  final Set<String> _expandedMatchIds = {};

  @override
  Widget build(BuildContext context) {
    final hasPredictions = widget.predictionData.matchPredictions.isNotEmpty ||
        widget.predictionData.championCode != null ||
        widget.predictionData.goldenBootPlayer != null;
    final totalPoints = hasPredictions
        ? PredictionService.calculateTotalPoints(widget.predictionData, widget.allMatches)
        : (widget.predictionData.points ?? 0);
    final xpInfo = PredictionService.getXpDetails(totalPoints, widget.lang);

    final playedMatches = widget.allMatches.where((m) => widget.predictionData.matchPredictions.containsKey(m.id)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 700;
    final dialogWidth = isDesktop ? 520.0 : double.infinity;
    final dialogHeight = mediaQuery.size.height * 0.82;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // High-Fidelity Header
              _buildHeader(context, totalPoints, xpInfo),

              // Tab navigation
              _buildTabBar(),

              // Content Area
              Expanded(
                child: IndexedStack(
                  index: _activeTabIndex,
                  children: [
                    _buildInfoTab(context),
                    _buildPredictionsTab(playedMatches),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int points, Map<String, dynamic> xp) {
    final hasAvatar = widget.predictionData.avatar.isNotEmpty;
    final hasPronouns = widget.predictionData.pronouns != null && widget.predictionData.pronouns!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
              image: hasAvatar ? DecorationImage(image: AssetImage(widget.predictionData.avatar), fit: BoxFit.cover) : null,
            ),
            child: !hasAvatar
                ? const Icon(Icons.person, color: AppColors.accent, size: 32)
                : null,
          ),
          const SizedBox(width: 14),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.predictionData.username.isEmpty ? AppTranslations.get(widget.lang, 'playerDefault') : widget.predictionData.username,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasPronouns) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _pronounsHistoryExpanded = !_pronounsHistoryExpanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.predictionData.pronouns!,
                                style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.history_rounded, color: AppColors.accent, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  xp['rankName'],
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
              const Text(
                'PTS',
                style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDim),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, AppTranslations.get(widget.lang, 'badgesTab')),
          _buildTabButton(1, AppTranslations.get(widget.lang, 'historyTab')),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.textDim,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pronouns History (Collapsible timeline)
          if (_pronounsHistoryExpanded) ...[
            _buildPronounsHistoryTimeline(context),
            const SizedBox(height: 16),
          ],

          // Tournament Predictions Overview
          Text(
            AppTranslations.get(widget.lang, 'tournamentPredictions').toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _buildPredictionsOverview(),
          const SizedBox(height: 24),

          // Favorite Team
          if (widget.predictionData.supportedTeam != null) ...[
            Text(
              AppTranslations.get(widget.lang, 'favoriteTeamLabel').toUpperCase(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            _buildFavoriteTeamCard(),
            const SizedBox(height: 24),
          ],

          // Badges Grid
          _buildBadgesGrid(context),
        ],
      ),
    );
  }

  Widget _buildPronounsHistoryTimeline(BuildContext context) {
    final history = widget.predictionData.pronounsHistory;
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.textDim, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppTranslations.get(widget.lang, 'noPronounHistory'),
                style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    final sortedHistory = List<PronounsHistoryItem>.from(history)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.get(widget.lang, 'pronounsHistory'),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => setState(() => _pronounsHistoryExpanded = false),
                child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textDim, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final item = sortedHistory[index];
              final dateStr = DateFormat('MMM dd, yyyy - HH:mm', widget.lang).format(item.updatedAt);
              final isLast = index == sortedHistory.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.pronouns.isNotEmpty ? item.pronouns : AppTranslations.get(widget.lang, 'pronounsPreferNotToSay'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(color: AppColors.textDim, fontSize: 9),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsOverview() {
    final isLocked = PredictionService.isTournamentPredictionLocked(widget.allMatches);
    final canSeeWinner = widget.viewingOwnHistory || isLocked;
    final champCode = widget.predictionData.championCode;
    final scorerName = widget.predictionData.goldenBootPlayer;

    return Row(
      children: [
        Expanded(
          child: _buildPredictOverviewCard(
            title: AppTranslations.get(widget.lang, 'winnerPredLabel'),
            child: !canSeeWinner
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.textDim, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.get(widget.lang, 'lockedLabel').toUpperCase(),
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : (champCode != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TeamFlagWidget(code: champCode, width: 22, height: 15, borderRadius: 3),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppTranslations.getTeam(widget.lang, champCode),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        AppTranslations.get(widget.lang, 'none'),
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPredictOverviewCard(
            title: AppTranslations.get(widget.lang, 'goldenBootScorer'),
            child: !canSeeWinner
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.textDim, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.get(widget.lang, 'lockedLabel').toUpperCase(),
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : (scorerName != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚽', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              scorerName,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        AppTranslations.get(widget.lang, 'none'),
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictOverviewCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildFavoriteTeamCard() {
    final teamCode = widget.predictionData.supportedTeam!;
    final teamName = AppTranslations.getTeam(widget.lang, teamCode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          TeamFlagWidget(code: teamCode, width: 36, height: 24, borderRadius: 4),
          const SizedBox(width: 12),
          Text(
            teamName,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(BuildContext context) {
    final earnedBadges = computeEarnedBadges(userPreds: widget.predictionData, matches: widget.allMatches);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.get(widget.lang, 'myBadgesLabel'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            Text(
              '${earnedBadges.length}/${kUserBadgeDefs.length}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: kUserBadgeDefs.length,
          itemBuilder: (context, index) {
            final badge = kUserBadgeDefs[index];
            final isEarned = earnedBadges.contains(badge.id);
            return _buildBadgeChip(badge, isEarned);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeChip(BadgeDef badge, bool isEarned) {
    final Color borderColor = isEarned ? (badge.isRare ? AppColors.purple : AppColors.warning) : AppColors.border;
    final Color bgColor = isEarned ? (badge.isRare ? AppColors.purple.withValues(alpha: 0.10) : AppColors.warning.withValues(alpha: 0.08)) : AppColors.surface;
    final descKey = '${badge.labelKey}Desc';
    final title = AppTranslations.get(widget.lang, badge.labelKey);
    final description = AppTranslations.get(widget.lang, descKey);

    return WCTooltip(
      title: title,
      message: description,
      child: AnimatedOpacity(
        opacity: isEarned ? 1.0 : 0.32,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isEarned
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.12),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(badge.icon, style: const TextStyle(fontSize: 22)),
              if (!isEarned)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: AppColors.textDim, size: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsTab(List<WorldCupMatch> playedMatches) {
    if (playedMatches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: playedMatches.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildMatchItem(context, playedMatches[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: AppColors.borderStrong.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            AppTranslations.get(widget.lang, 'noPrediction'),
            style: const TextStyle(color: AppColors.textDim, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(BuildContext context, WorldCupMatch match) {
    final pred = widget.predictionData.matchPredictions[match.id]!;
    final isFinished = match.isFinished;
    final canSeeDetails = widget.viewingOwnHistory || isFinished;

    final isBooster = widget.predictionData.boosterMatchIds.contains(match.id);
    final points = isFinished ? PredictionService.evaluatePointsWithBooster(match, pred, isBooster) : 0;
    final bool isExpanded = _expandedMatchIds.contains(match.id);

    return InkWell(
      onTap: isFinished
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedMatchIds.remove(match.id);
                } else {
                  _expandedMatchIds.add(match.id);
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border, 
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd - HH:mm', widget.lang).format(match.date),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBooster) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('JOKER 🔥', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isFinished)
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textDim,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTeam(match.t1, true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildScoreDisplay(match, pred, canSeeDetails),
                ),
                Expanded(child: _buildTeam(match.t2, false)),
              ],
            ),
            if (isFinished) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!pred.outcomeOnly)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: pred.predictedScorers.keys.map((s) => _buildScorerChip(s, match)).toList(),
                      ),
                    )
                  else
                    const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '+$points PTS',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              if (isExpanded) _buildPointsBreakdown(match, pred, isBooster),
            ],
            if (!isFinished && !widget.viewingOwnHistory)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppTranslations.get(widget.lang, 'predictionLocked'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeam(String code, bool isHome) {
    final name = AppTranslations.getTeam(widget.lang, code);
    return Row(
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isHome) ...[TeamFlagWidget(code: code, width: 24, height: 18), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            textAlign: isHome ? TextAlign.right : TextAlign.left,
          ),
        ),
        if (isHome) ...[const SizedBox(width: 8), TeamFlagWidget(code: code, width: 24, height: 18)],
      ],
    );
  }

  Widget _buildScoreDisplay(WorldCupMatch match, MatchPrediction pred, bool canSee) {
    if (!canSee) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.lock_outline, color: AppColors.textDim, size: 16),
      );
    }

    final pronoLabel = AppTranslations.get(widget.lang, 'predictionShort').toUpperCase();
    final reelLabel = widget.lang == 'fr' ? 'RÉEL' : (widget.lang == 'es' ? 'REAL' : 'FINAL');

    if (pred.outcomeOnly) {
      String outcomeText = '';
      if (pred.t1Score > pred.t2Score) {
        outcomeText = '1';
      } else if (pred.t1Score < pred.t2Score) {
        outcomeText = '2';
      } else {
        outcomeText = 'N';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Text(
                pronoLabel,
                style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  outcomeText,
                  style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (match.isPlayed) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  reelLabel,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.t1Score} - ${match.t2Score}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Text(
              pronoLabel,
              style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              '${pred.t1Score} - ${pred.t2Score}',
              style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
            ),
          ],
        ),
        if (match.isPlayed) ...[
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                reelLabel,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                '${match.t1Score} - ${match.t2Score}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScorerChip(String name, WorldCupMatch match) {
    final didScore = match.goals.any((g) => PredictionService.isSamePlayer(g.scorer, name));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: didScore ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: didScore ? AppColors.accent : AppColors.border, width: 0.5),
      ),
      child: Text(
        name,
        style: TextStyle(color: didScore ? AppColors.accent : AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPointsBreakdown(WorldCupMatch match, MatchPrediction pred, bool isBooster) {
    final breakdown = PredictionService.evaluatePointsBreakdown(match, pred, isBooster);

    final List<Widget> rows = [];

    void addBreakdownRow(String label, double points, {String? subtitle, String? icon}) {
      if (points == 0.0) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
              Text(
                '+${points.round()} PTS',
                style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      );
    }

    final double oddsMultiplier = breakdown['oddsMultiplier'] ?? 1.0;
    final String oddsStr = '× ${oddsMultiplier.toStringAsFixed(2)}';

    addBreakdownRow(
      widget.lang == 'fr' ? 'Issue du match correcte' : (widget.lang == 'es' ? 'Resultado correcto' : 'Correct match outcome'),
      breakdown['outcomePoints'],
      subtitle: '${widget.lang == 'fr' ? 'Base' : 'Base'} +50 pts $oddsStr',
      icon: '🏆',
    );

    final bool isGdNearMiss = breakdown['isGdNearMiss'] == true;
    final String gdLabel = isGdNearMiss
        ? (widget.lang == 'fr' ? 'Diff. buts : presque parfait !' : (widget.lang == 'es' ? 'Diferencia de goles: ¡casi!' : 'Goal difference: near miss!'))
        : (widget.lang == 'fr' ? 'Différence de buts correcte' : (widget.lang == 'es' ? 'Diferencia de goles' : 'Correct goal difference'));
    final String gdSubtitle = isGdNearMiss
        ? (widget.lang == 'fr' ? '½ bonus (1 but d\'écart) $oddsStr' : (widget.lang == 'es' ? '½ bono (1 gol de diferencia) $oddsStr' : '½ bonus (off by 1 goal) $oddsStr'))
        : '${widget.lang == 'fr' ? 'Bonus' : 'Bonus'} $oddsStr';
    final String gdIcon = isGdNearMiss ? '📊🎯' : '📊';

    addBreakdownRow(
      gdLabel,
      breakdown['gdPoints'],
      subtitle: gdSubtitle,
      icon: gdIcon,
    );

    addBreakdownRow(
      widget.lang == 'fr' ? 'Score exact 💯' : (widget.lang == 'es' ? 'Resultado exacto 💯' : 'Exact score 💯'),
      breakdown['exactScorePoints'],
      subtitle: widget.lang == 'fr'
        ? 'Summum ! Base +200 pts $oddsStr × facteur risque (|GD| × 0.40 + buts × 0.20)'
        : (widget.lang == 'es'
          ? 'Summum ! Base +200 pts $oddsStr × factor riesgo'
          : 'Summum! Base +200 pts $oddsStr × risk factor (|GD| × 0.40 + goals × 0.20)'),
      icon: '🎯',
    );

    addBreakdownRow(
      widget.lang == 'fr' ? 'Total de buts correct' : (widget.lang == 'es' ? 'Total de goles correcto' : 'Correct total goals'),
      breakdown['totalGoalsPoints'],
      subtitle: '${widget.lang == 'fr' ? 'Bonus' : 'Bonus'} +50 pts $oddsStr',
      icon: '⚽',
    );

    addBreakdownRow(
      widget.lang == 'fr' ? 'Bonus Outsider 🦁' : (widget.lang == 'es' ? 'Bono Outsider 🦁' : 'Outsider Bonus 🦁'),
      breakdown['outsiderPoints'],
      subtitle: widget.lang == 'fr'
        ? '+100 pts fixe — victoire surprise (prob. < 30%)'
        : (widget.lang == 'es' ? '+100 pts fijo — victoria sorpresa (prob. < 30%)' : '+100 pts flat — upset win (prob. < 30%)'),
      icon: '⭐',
    );

    final Map<String, dynamic> scorerBreakdown = breakdown['scorerBreakdown'] ?? {};
    scorerBreakdown.forEach((scorerName, pts) {
      addBreakdownRow(
        '${widget.lang == 'fr' ? 'Buteur' : 'Scorer'} : $scorerName',
        pts,
        subtitle: widget.lang == 'fr' ? 'Bonus buteur' : 'Scorer bonus',
        icon: '👟',
      );
    });

    addBreakdownRow(
      widget.lang == 'fr' ? 'Vainqueur en prolongations' : (widget.lang == 'es' ? 'Ganador en prórroga' : 'Extra time winner'),
      breakdown['extraTimePoints'],
      subtitle: '${widget.lang == 'fr' ? 'Bonus' : 'Bonus'} +150 pts $oddsStr',
      icon: '⏰',
    );

    addBreakdownRow(
      widget.lang == 'fr' ? 'Vainqueur aux tirs au but' : (widget.lang == 'es' ? 'Ganador en penaltis' : 'Penalty shootout winner'),
      breakdown['penaltyPoints'],
      subtitle: '${widget.lang == 'fr' ? 'Bonus' : 'Bonus'} +200 pts $oddsStr',
      icon: '🥅',
    );

    if (rows.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.lang == 'fr' ? 'Aucun point marqué sur ce match.' : 'No points earned for this match.',
          style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      );
    }

    final double knockoutMultiplier = breakdown['knockoutMultiplier'] ?? 1.0;
    final double boosterMultiplier = breakdown['boosterMultiplier'] ?? 1.0;
    
    final List<Widget> multiplierChips = [];
    if (knockoutMultiplier > 1.0) {
      multiplierChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            '${widget.lang == 'fr' ? 'Phase finale' : 'Knockout'} (×$knockoutMultiplier)',
            style: const TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (boosterMultiplier > 1.0) {
      multiplierChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            'JOKER (×$boosterMultiplier)',
            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.lang == 'fr' ? 'DÉTAIL DU SCORE' : 'POINTS BREAKDOWN').toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          ...rows,
          if (multiplierChips.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: AppColors.border, height: 1),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: multiplierChips,
            ),
          ],
        ],
      ),
    );
  }
}
