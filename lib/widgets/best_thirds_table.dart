import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';
import '../utils/fifa_rules.dart';
import 'group_table.dart';

class BestThirdsTableWidget extends StatelessWidget {
  final List<WorldCupMatch> matches;
  final String lang;

  const BestThirdsTableWidget({
    super.key,
    required this.matches,
    required this.lang,
  });

  List<GroupEntry> _getBestThirds() {
    final standings = GroupTableWidget.calculateStandings(matches);
    final List<GroupEntry> thirds = [];

    // Extract exactly the 3rd placed team from every group
    standings.forEach((group, teamEntries) {
      if (teamEntries.length >= 3) {
        // Assume teamEntries is already sorted correctly by GroupTableWidget.calculateStandings
        thirds.add(teamEntries[2]);
      }
    });

    // Sort them across all groups using the cross-group rules
    FIFARegulations.sortBestThirds(thirds);

    return thirds;
  }

  Widget _buildFlag(String code) {
    return TeamFlagWidget(code: code, width: 28, height: 18, borderRadius: 4);
  }

  @override
  Widget build(BuildContext context) {
    final thirds = _getBestThirds();

    if (thirds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final double posWidth = 36.0;
    final double playedWidth = 36.0;
    final double gdWidth = 44.0;
    final double ptsWidth = 44.0;
    final double fontSize = 14.0;
    final double headerFontSize = 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            AppTranslations.get(lang, 'bestThirdsExplanation'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: posWidth,
                      child: Text(
                        AppTranslations.get(lang, 'pos'),
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppTranslations.get(lang, 'team'),
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: playedWidth,
                      child: Text(
                        AppTranslations.get(lang, 'played'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: gdWidth,
                      child: Text(
                        AppTranslations.get(lang, 'gd'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ptsWidth,
                      child: Text(
                        AppTranslations.get(lang, 'pts'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontWeight: FontWeight.bold,
                          fontSize: headerFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              // Rows
              ...List.generate(thirds.length, (idx) {
                final entry = thirds[idx];
                final teamName = AppTranslations.getTeam(lang, entry.teamCode);
                final isQualified = idx < 8; // Top 8 qualify
                
                final statusColor = isQualified ? AppColors.accent : AppColors.danger;

                return Container(
                  decoration: BoxDecoration(
                    color: isQualified
                        ? AppColors.accent.withValues(alpha: 0.05)
                        : AppColors.danger.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            // Pos
                            SizedBox(
                              width: posWidth,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 22.0,
                                  height: 22.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor.withValues(alpha: 0.15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize - 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Flag + Team name
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  WCTeamProfileDialog.show(
                                    context,
                                    entry.teamCode,
                                    lang,
                                    matches,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFlag(entry.teamCode),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teamName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Played
                            SizedBox(
                              width: playedWidth,
                              child: Text(
                                '${entry.played}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                            // GD
                            SizedBox(
                              width: gdWidth,
                              child: Text(
                                '${entry.goalDifference > 0 ? '+' : ''}${entry.goalDifference}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: entry.goalDifference > 0
                                      ? AppColors.accent
                                      : entry.goalDifference < 0
                                      ? AppColors.danger
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                            // Pts
                            SizedBox(
                              width: ptsWidth,
                              child: Text(
                                '${entry.points}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize + 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (idx < thirds.length - 1)
                        const Divider(color: AppColors.border, height: 1),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
