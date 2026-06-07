import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';
import '../utils/fifa_rules.dart';

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

class GroupTableWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final String? supportedTeamCode;

  const GroupTableWidget({
    super.key,
    required this.matches,
    required this.lang,
    this.supportedTeamCode,
  });

  @override
  State<GroupTableWidget> createState() => _GroupTableWidgetState();
}

class _GroupTableWidgetState extends State<GroupTableWidget> {
  String _selectedGroup = 'A';

  Map<String, List<GroupEntry>> _calculateStandings() {
    final Map<String, List<GroupEntry>> standings = {};

    // First pass: scan all matches to discover which teams belong to which groups
    for (final match in widget.matches) {
      if (match.group == null || match.group!.isEmpty) continue;
      final grp = match.group!;

      standings.putIfAbsent(grp, () => []);

      final groupTeams = standings[grp]!;
      if (!groupTeams.any((e) => e.teamCode == match.t1)) {
        groupTeams.add(GroupEntry(match.t1));
      }
      if (!groupTeams.any((e) => e.teamCode == match.t2)) {
        groupTeams.add(GroupEntry(match.t2));
      }
    }

    // Second pass: compile match scores for played matches
    for (final match in widget.matches) {
      if (match.group == null || match.group!.isEmpty || !match.isPlayed) continue;
      final grp = match.group!;

      final t1Entry = standings[grp]!.firstWhere((e) => e.teamCode == match.t1);
      final t2Entry = standings[grp]!.firstWhere((e) => e.teamCode == match.t2);

      t1Entry.played++;
      t2Entry.played++;

      t1Entry.goalsFor += match.t1Score!;
      t1Entry.goalsAgainst += match.t2Score!;
      t2Entry.goalsFor += match.t2Score!;
      t2Entry.goalsAgainst += match.t1Score!;

      if (match.t1Score! > match.t2Score!) {
        t1Entry.wins++;
        t2Entry.losses++;
      } else if (match.t1Score! < match.t2Score!) {
        t2Entry.wins++;
        t1Entry.losses++;
      } else {
        t1Entry.draws++;
        t2Entry.draws++;
      }

      if (match.stats != null) {
        t1Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          match.stats!.yellowCardsT1,
          match.stats!.redCardsT1,
        );
        t2Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          match.stats!.yellowCardsT2,
          match.stats!.redCardsT2,
        );
      }
    }

    // Sort teams inside each group
    standings.forEach((group, teamEntries) {
      FIFARegulations.sortStandings(teamEntries, widget.matches);
    });

    return standings;
  }

  Widget _buildFlag(String code) {
    return TeamFlagWidget(
      code: code,
      width: 28,
      height: 18,
      borderRadius: 4,
    );
  }

  Widget _buildMinimalistTable(List<GroupEntry> groupTeams, {bool compact = false}) {
    final double posWidth = compact ? 24.0 : 36.0;
    final double playedWidth = compact ? 28.0 : 36.0;
    final double gdWidth = compact ? 36.0 : 44.0;
    final double ptsWidth = compact ? 36.0 : 44.0;
    final double fontSize = compact ? 11.0 : 14.0;
    final double headerFontSize = compact ? 10.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12.0 : 16.0, vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: posWidth,
                child: Text(
                  AppTranslations.get(widget.lang, 'pos'),
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: headerFontSize,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  AppTranslations.get(widget.lang, 'team'),
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
                  AppTranslations.get(widget.lang, 'played'),
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
                  AppTranslations.get(widget.lang, 'gd'),
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
                  AppTranslations.get(widget.lang, 'pts'),
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
        ...List.generate(groupTeams.length, (idx) {
          final entry = groupTeams[idx];
          final teamName = AppTranslations.getTeam(widget.lang, entry.teamCode);
          final isTopTwo = idx < 2;
          final isUserSupported = widget.supportedTeamCode?.toLowerCase() == entry.teamCode.toLowerCase();

          return Container(
            decoration: BoxDecoration(
              color: isUserSupported 
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: isUserSupported
                  ? const Border(
                      left: BorderSide(color: AppColors.accent, width: 4),
                    )
                  : null,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12.0 : 16.0,
                    vertical: compact ? 8.0 : 12.0,
                  ),
                  child: Row(
                    children: [
                      // Pos
                      SizedBox(
                        width: posWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: compact ? 18.0 : 22.0,
                            height: compact ? 18.0 : 22.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTopTwo
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: isTopTwo ? AppColors.accent : AppColors.textMuted,
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
                              widget.lang,
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
                                    color: isUserSupported ? AppColors.accent : AppColors.textSecondary,
                                    fontWeight: isUserSupported ? FontWeight.bold : FontWeight.w600,
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                              if (isUserSupported) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: AppColors.accent, size: 12),
                              ]
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
                          (entry.goalDifference > 0 ? '+' : '') + '${entry.goalDifference}',
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
                            color: isUserSupported ? AppColors.accent : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < groupTeams.length - 1)
                  const Divider(color: AppColors.border, height: 1),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final standings = _calculateStandings();
    final groups = standings.keys.toList()..sort();

    // Default select first group if current selected isn't in standings
    if (groups.isNotEmpty && !groups.contains(_selectedGroup)) {
      _selectedGroup = groups.first;
    }

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            AppTranslations.get(widget.lang, 'noAlerts'),
            style: const TextStyle(color: AppColors.textDim),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) {
      return _buildDesktopGrid(standings, groups, screenWidth);
    }

    String? favGroup;
    if (widget.supportedTeamCode != null) {
      final favCode = widget.supportedTeamCode!.toLowerCase();
      for (final match in widget.matches) {
        if (match.group != null && match.group!.isNotEmpty) {
          if (match.t1.toLowerCase() == favCode || match.t2.toLowerCase() == favCode) {
            favGroup = match.group;
            break;
          }
        }
      }
    }

    final selectedGroupTeams = standings[_selectedGroup] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Select Tab bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: groups.map((g) {
              final isSelected = g == _selectedGroup;
              final isFavGroup = g == favGroup;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppTranslations.get(widget.lang, 'group')} $g',
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : (isFavGroup ? AppColors.accent : AppColors.textMuted),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (isFavGroup) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedGroup = g;
                      });
                    }
                  },
                  selectedColor: AppColors.border,
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? AppColors.accent 
                          : (isFavGroup ? Colors.amber.withValues(alpha: 0.6) : AppColors.border),
                      width: isFavGroup || isSelected ? 2.0 : 1.5,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Standings Card Table
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _buildMinimalistTable(selectedGroupTeams, compact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(Map<String, List<GroupEntry>> standings, List<String> groups, double screenWidth) {
    final crossAxisCount = screenWidth > 1300 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        final groupTeams = standings[g] ?? [];
        return _buildGroupCard(g, groupTeams);
      },
    );
  }

  Widget _buildGroupCard(String g, List<GroupEntry> groupTeams) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Group Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.cardDark,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppTranslations.get(widget.lang, 'group')} $g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Standings Table
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildMinimalistTable(groupTeams, compact: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
