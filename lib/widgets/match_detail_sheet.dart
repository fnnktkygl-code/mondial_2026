import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';

class MatchDetailSheet extends StatelessWidget {
  final WorldCupMatch match;
  final String lang;
  final String? activeAlert;
  final Function(String alertType) onSaveAlert;

  const MatchDetailSheet({
    super.key,
    required this.match,
    required this.lang,
    required this.activeAlert,
    required this.onSaveAlert,
  });

  Widget _buildFlag(String code, double size) {
    if (code.length > 2 || code == 'tbd') {
      return Container(
        width: size * 1.4,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderMid, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          'FIFA',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.25,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final flagCode = code == 'en' ? 'gb-eng' : code;
    return Container(
      width: size * 1.4,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          '${kFlagCdnUrl}$flagCode.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.border,
              alignment: Alignment.center,
              child: Text(code.toUpperCase()),
            );
          },
        ),
      ),
    );
  }

  Map<String, double> _calculateCrowdProbabilities(String t1, String t2) {
    final int charSum1 = t1.codeUnits.fold(0, (sum, val) => sum + val);
    final int charSum2 = t2.codeUnits.fold(0, (sum, val) => sum + val);

    final r1 = kTeamRatings[t1.replaceAll('g_', '').toLowerCase()]
        ?? (70 + (charSum1 % 15));
    final r2 = kTeamRatings[t2.replaceAll('g_', '').toLowerCase()]
        ?? (70 + (charSum2 % 15));

    final double total = (r1 + r2).toDouble();
    final double p1 = (r1 / total) * kWinProbabilityScale;
    final double p2 = (r2 / total) * kWinProbabilityScale;

    return {
      'home': p1,
      'draw': kDefaultDrawProbability,
      'away': p2,
    };
  }

  Widget _buildWinProbabilityBar(BuildContext context) {
    final cleanT1 = match.t1.replaceFirst('g_', '').toUpperCase();
    final cleanT2 = match.t2.replaceFirst('g_', '').toUpperCase();
    final probs = _calculateCrowdProbabilities(match.t1, match.t2);
    final pHome = (probs['home']! * 100).round();
    final pDraw = (probs['draw']! * 100).round();
    final pAway = 100 - pHome - pDraw;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.get(lang, 'crowdPredictions'),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.analytics_outlined, color: AppColors.accent, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(flex: pHome, child: Container(color: AppColors.accent)),
                  Expanded(flex: pDraw, child: Container(color: AppColors.borderStrong)),
                  Expanded(flex: pAway, child: Container(color: AppColors.info)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$cleanT1 $pHome%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                '${AppTranslations.get(lang, 'drawLabel')} $pDraw%',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                '$cleanT2 $pAway%',
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t1EmblemName = AppTranslations.getTeamWithEmblem(lang, match.t1);
    final t2EmblemName = AppTranslations.getTeamWithEmblem(lang, match.t2);
    final matchJoke = AppTranslations.getJoke(lang, match.t1, match.t2, isKnockout: match.isKnockout);
    final localizedDateTimeStr = DateFormat.yMMMMEEEEd(lang).add_Hm().format(match.date);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderMid,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header: Flags, team names, score/VS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildFlag(match.t1, 48),
                      const SizedBox(height: 10),
                      Text(
                        t1EmblemName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: match.isPlayed
                      ? Text(
                          '${match.t1Score} - ${match.t2Score}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
                        )
                      : const Text(
                          'VS',
                          style: TextStyle(
                            color: AppColors.borderStrong,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildFlag(match.t2, 48),
                      const SizedBox(height: 10),
                      Text(
                        t2EmblemName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date & time banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.textDim, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizedDateTimeStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Win probability bar
                  _buildWinProbabilityBar(context),
                  const SizedBox(height: 20),

                  // Goals / Scorers timeline
                  if (match.isPlayed && match.goals.isNotEmpty) ...[
                    Text(
                      AppTranslations.get(lang, 'scorers').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            top: 8,
                            bottom: 8,
                            left: 100,
                            child: VerticalDivider(color: AppColors.borderMid, width: 2),
                          ),
                          Column(
                            children: match.goals.map((g) {
                              final isT1Goal  = g.team == 't1';
                              final assistText = g.assistant != null ? '\n(ass: ${g.assistant})' : '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      child: isT1Goal
                                          ? Text(
                                              g.scorer + assistText,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            )
                                          : const SizedBox(),
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 14,
                                      child: Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isT1Goal ? AppColors.accent : AppColors.info,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.surface, width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 35,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${g.minute}'",
                                        style: TextStyle(
                                          color: isT1Goal ? AppColors.accent : AppColors.info,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: !isT1Goal
                                          ? Text(
                                              g.scorer + assistText,
                                              textAlign: TextAlign.start,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Match statistics
                  if (match.isPlayed && match.stats != null) ...[
                    Text(
                      AppTranslations.get(lang, 'stats').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'possession'),
                            val1: match.stats!.possessionT1,
                            val2: match.stats!.possessionT2,
                            suffix: '%',
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'shots'),
                            val1: match.stats!.shotsT1,
                            val2: match.stats!.shotsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'shotsOnTarget'),
                            val1: match.stats!.shotsOnTargetT1,
                            val2: match.stats!.shotsOnTargetT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'fouls'),
                            val1: match.stats!.foulsT1,
                            val2: match.stats!.foulsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'yellowCards'),
                            val1: match.stats!.yellowCardsT1,
                            val2: match.stats!.yellowCardsT2,
                            colorT1: AppColors.warningYellow,
                            colorT2: AppColors.warningYellow,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(lang, 'redCards'),
                            val1: match.stats!.redCardsT1,
                            val2: match.stats!.redCardsT2,
                            colorT1: AppColors.danger,
                            colorT2: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Trivia / Joke box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🍿', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              AppTranslations.get(lang, 'triviaTitle'),
                              style: const TextStyle(
                                color: AppColors.rankGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          matchJoke,
                          style: const TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alert section header
                  Text(
                    AppTranslations.get(lang, 'setAlertTitle').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alert buttons
                  Column(
                    children: [
                      _buildAlertButton(context, '1d', AppTranslations.get(lang, 'alert1Day')),
                      const SizedBox(height: 8),
                      _buildAlertButton(context, '1h', AppTranslations.get(lang, 'alert1Hour')),
                      const SizedBox(height: 8),
                      _buildAlertButton(context, '30m', AppTranslations.get(lang, 'alert30Min')),
                    ],
                  ),

                  // Remove alert button
                  if (activeAlert != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        label: Text(
                          AppTranslations.get(lang, 'removeAlert'),
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          onSaveAlert('none');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar({
    required String label,
    required int val1,
    required int val2,
    String suffix = '',
    Color colorT1 = AppColors.accent,
    Color colorT2 = AppColors.info,
  }) {
    final int sum  = val1 + val2;
    final int flex1 = sum == 0 ? 1 : val1;
    final int flex2 = sum == 0 ? 1 : val2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$val1$suffix',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              Text(
                '$val2$suffix',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (val1 > 0 || sum == 0)
                Expanded(
                  flex: flex1,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorT1,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(3),
                        bottomLeft: const Radius.circular(3),
                        topRight: Radius.circular(val2 == 0 ? 3 : 0),
                        bottomRight: Radius.circular(val2 == 0 ? 3 : 0),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 2),
              if (val2 > 0 || sum == 0)
                Expanded(
                  flex: flex2,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorT2,
                      borderRadius: BorderRadius.only(
                        topRight: const Radius.circular(3),
                        bottomRight: const Radius.circular(3),
                        topLeft: Radius.circular(val1 == 0 ? 3 : 0),
                        bottomLeft: Radius.circular(val1 == 0 ? 3 : 0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertButton(BuildContext context, String type, String label) {
    final isSelected = activeAlert == type;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          onSaveAlert(type);
          Navigator.pop(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textBody,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.borderStrong,
                  width: 2,
                ),
                color: isSelected ? AppColors.accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: AppColors.surface)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
