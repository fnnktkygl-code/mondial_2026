import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';

class GroupEntry {
  final String teamCode;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;

  GroupEntry(this.teamCode);
}

class GroupTableWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;

  const GroupTableWidget({
    super.key,
    required this.matches,
    required this.lang,
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
    }

    // Sort teams inside each group
    standings.forEach((group, teamEntries) {
      teamEntries.sort((a, b) {
        // 1. Points
        if (b.points != a.points) {
          return b.points.compareTo(a.points);
        }
        // 2. Goal Difference
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        // 3. Goals For
        if (b.goalsFor != a.goalsFor) {
          return b.goalsFor.compareTo(a.goalsFor);
        }
        // 4. Alphabetical code
        return a.teamCode.compareTo(b.teamCode);
      });
    });

    return standings;
  }

  Widget _buildFlag(String code) {
    if (code.length > 2) return const SizedBox.shrink();
    final flagCode = code == 'en' ? 'gb-eng' : code;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://flagcdn.com/w40/$flagCode.png',
        width: 24,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 24,
          height: 16,
          color: Colors.grey,
        ),
      ),
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
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    '${AppTranslations.get(widget.lang, 'group')} $g',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 1.5,
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 20,
              headingRowColor: WidgetStateProperty.all(AppColors.cardDark),
              headingRowHeight: 52,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: [
                DataColumn(
                  label: Text(
                    AppTranslations.get(widget.lang, 'pos'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    AppTranslations.get(widget.lang, 'team'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'played'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'wins'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'draws'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'losses'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'gd'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    AppTranslations.get(widget.lang, 'pts'),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              rows: List.generate(selectedGroupTeams.length, (idx) {
                final entry = selectedGroupTeams[idx];
                final teamName = AppTranslations.getTeam(widget.lang, entry.teamCode);
                final isTopTwo = idx < 2;

                return DataRow(
                  cells: [
                    // Pos
                    DataCell(
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTopTwo
                              ? AppColors.accent.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: isTopTwo ? AppColors.accent : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Team Name with Flag
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFlag(entry.teamCode),
                          const SizedBox(width: 8),
                          Text(
                            teamName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Played
                    DataCell(
                      Text(
                        '${entry.played}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                    // W
                    DataCell(
                      Text(
                        '${entry.wins}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                      ),
                    ),
                    // D
                    DataCell(
                      Text(
                        '${entry.draws}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                      ),
                    ),
                    // L
                    DataCell(
                      Text(
                        '${entry.losses}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                      ),
                    ),
                    // GD
                    DataCell(
                      Text(
                        (entry.goalDifference > 0 ? '+' : '') + '${entry.goalDifference}',
                        style: TextStyle(
                          color: entry.goalDifference > 0
                              ? AppColors.accent
                              : entry.goalDifference < 0
                                  ? AppColors.danger
                                  : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // PTS
                    DataCell(
                      Text(
                        '${entry.points}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
