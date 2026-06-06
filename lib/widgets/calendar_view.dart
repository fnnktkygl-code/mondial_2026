import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';

class CalendarViewWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final bool Function(WorldCupMatch) hasAlert;
  final Function(WorldCupMatch match) onMatchTap;

  const CalendarViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.hasAlert,
    required this.onMatchTap,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  final DateTime _tournamentStart = DateTime.parse('2026-06-08T00:00:00Z').toLocal();
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _tournamentStart;
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
    });
  }

  void _resetToTournament() {
    setState(() {
      _currentWeekStart = _tournamentStart;
    });
  }

  String _getWeekLabel() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    final startLabel = DateFormat.MMMd(widget.lang).format(_currentWeekStart);
    final endLabel = DateFormat.yMMMd(widget.lang).format(end);
    return '$startLabel - $endLabel';
  }

  Widget _buildFlag(String code) {
    if (code.length > 2 || code == 'tbd') {
      return Container(
        width: 20,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.borderStrong, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          'F',
          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    }
    final flagCode = code == 'en' ? 'gb-eng' : code;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        'https://flagcdn.com/w40/$flagCode.png',
        width: 20,
        height: 14,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 20,
          height: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double rowHeight = 90.0;
    const double matchDuration = 1.75; // Matches last 1.75 hours roughly (105 mins)

    // Calculate dates of the visible week (Monday to Sunday)
    final weekDates = List.generate(7, (i) {
      return _currentWeekStart.add(Duration(days: i));
    });

    final weekEnd = _currentWeekStart.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));

    // Filter matches for the selected week
    final weekMatches = widget.matches.where((m) {
      return m.date.isAfter(_currentWeekStart.subtract(const Duration(milliseconds: 1))) &&
          m.date.isBefore(weekEnd);
    }).toList();

    // Determine hour boundaries to optimize space
    int minHour = 10;
    int maxHour = 22;
    if (weekMatches.isNotEmpty) {
      final hours = weekMatches.map((m) => m.date.hour).toList();
      final min = hours.reduce((a, b) => a < b ? a : b) - 1;
      final max = hours.reduce((a, b) => a > b ? a : b) + 2;
      minHour = min.clamp(0, 23);
      maxHour = max.clamp(0, 23);
    }
    final int hoursCount = maxHour - minHour + 1;
    final double gridHeight = hoursCount * rowHeight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Navigation Header
          Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
                  onPressed: () => _changeWeek(-7),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _getWeekLabel(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _resetToTournament,
                      child: Text(
                        AppTranslations.get(widget.lang, 'today').toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onPressed: () => _changeWeek(7),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Grid Layout
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: 960, // Width for columns
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hours label column (Left sticky replacement)
                      Container(
                        width: 50,
                        color: AppColors.surface.withOpacity(0.5),
                        child: Column(
                          children: [
                            const SizedBox(height: 48), // Match Day header gap
                            SizedBox(
                              height: gridHeight,
                              child: Stack(
                                children: List.generate(hoursCount, (idx) {
                                  final hr = minHour + idx;
                                  return Positioned(
                                    top: idx * rowHeight,
                                    right: 6,
                                    child: Text(
                                      '${hr.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(
                                        color: AppColors.textDim,
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Day columns
                      ...List.generate(7, (dayIdx) {
                        final date = weekDates[dayIdx];
                        final dateStr = DateFormat('yyyy-MM-dd').format(date);
                        final localizedDayLabel =
                            DateFormat('E d MMM', widget.lang).format(date);

                        // Day's matches
                        final dayMatches = weekMatches.where((m) {
                          return DateFormat('yyyy-MM-dd').format(m.date) == dateStr;
                        }).toList();

                        return Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: AppColors.border, width: 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Day Header
                                Container(
                                  height: 48,
                                  width: double.infinity,
                                  color: dayMatches.isNotEmpty
                                      ? AppColors.border.withOpacity(0.4)
                                      : Colors.transparent,
                                  alignment: Alignment.center,
                                  child: Text(
                                    localizedDayLabel,
                                    style: TextStyle(
                                      color: dayMatches.isNotEmpty
                                          ? AppColors.accent
                                          : AppColors.textDim,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // Hours Grid Stack
                                SizedBox(
                                  height: gridHeight,
                                  child: Stack(
                                    children: [
                                      // Hour separator lines
                                      ...List.generate(hoursCount, (idx) {
                                        return Positioned(
                                          top: idx * rowHeight,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: rowHeight,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: AppColors.border,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),

                                      // Match Blocks
                                      ...dayMatches.map((m) {
                                        final double topOffset =
                                            ((m.date.hour - minHour) +
                                                    (m.date.minute / 60)) *
                                                rowHeight;
                                        final double blockHeight =
                                            matchDuration * rowHeight;

                                        // Resolve collision formatting
                                        final simultaneous = dayMatches
                                            .where((x) =>
                                                x.date.hour == m.date.hour &&
                                                x.date.minute == m.date.minute)
                                            .toList();
                                        final isCollision = simultaneous.length > 1;
                                        final colIndex =
                                            simultaneous.indexWhere((x) => x.id == m.id);

                                        final widthFactor = isCollision ? 0.48 : 0.94;
                                        final leftMargin = isCollision
                                            ? (colIndex == 0 ? 0.02 : 0.5)
                                            : 0.03;

                                        final hasAlert = widget.hasAlert(m);

                                        return Positioned(
                                          top: topOffset,
                                          left: 130 * leftMargin,
                                          width: 130 * widthFactor,
                                          height: blockHeight - 4,
                                          child: GestureDetector(
                                            onTap: () => widget.onMatchTap(m),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: hasAlert
                                                    ? const Color(0xFF0F2D21)
                                                    : AppColors.border,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: hasAlert
                                                      ? AppColors.accent
                                                      : AppColors.borderMid,
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        m.getFormattedTime(),
                                                        style: const TextStyle(
                                                          color: AppColors.textMuted,
                                                          fontSize: 9,
                                                          fontFamily: 'monospace',
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (hasAlert)
                                                        const Icon(
                                                          Icons.notifications_active,
                                                          color: AppColors.accent,
                                                          size: 10,
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Team 1
                                                  Row(
                                                    children: [
                                                      _buildFlag(m.t1),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          AppTranslations.getTeam(
                                                              widget.lang, m.t1),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Team 2
                                                  Row(
                                                    children: [
                                                      _buildFlag(m.t2),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          AppTranslations.getTeam(
                                                              widget.lang, m.t2),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
