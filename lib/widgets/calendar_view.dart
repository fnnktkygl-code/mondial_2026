import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'wc_tooltip.dart';

class CalendarViewWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final bool Function(WorldCupMatch) hasAlert;
  final bool Function(WorldCupMatch) hasPredicted;
  final Map<String, MatchPrediction>? userPredictions;
  final String? Function(WorldCupMatch)? alertType;
  final Function(WorldCupMatch match) onMatchTap;
  final String? supportedTeamCode;

  const CalendarViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.hasAlert,
    required this.hasPredicted,
    this.userPredictions,
    this.alertType,
    required this.onMatchTap,
    this.supportedTeamCode,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  final DateTime _tournamentStart = DateTime.parse(
    '2026-06-08T00:00:00Z',
  ).toLocal();
  late DateTime _currentWeekStart;
  DateTime? _targetMatchDate;
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _setInitialWeekToNextMatch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstMatchOfTargetDay();
      _scrollToTargetDayHorizontal();
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  bool _isPlaceholder(String code) {
    return (code.length > 2 && code.toLowerCase() != 'sco' && code.toLowerCase() != 'gb-sct') ||
        code.toLowerCase() == 'tbd' ||
        code.contains(RegExp(r'\d'));
  }

  void _setInitialWeekToNextMatch() {
    final now = DateTime.now();
    if (widget.matches.isEmpty) {
      _currentWeekStart = _tournamentStart;
      _targetMatchDate = _tournamentStart;
      return;
    }

    WorldCupMatch? targetMatch;
    
    // 1. Look for a live match (currently playing)
    try {
      targetMatch = widget.matches.firstWhere((m) {
        final localDate = m.date.toLocal();
        final duration = m.isKnockout 
            ? const Duration(minutes: 180) 
            : const Duration(minutes: 120);
        return !m.isPlayed && 
            m.status != 'FINISHED' && 
            now.isAfter(localDate) && 
            now.isBefore(localDate.add(duration));
      });
    } catch (_) {
      // 2. If no live match, look for the next upcoming match
      try {
        targetMatch = widget.matches.firstWhere(
          (m) => !m.isPlayed && m.status != 'FINISHED' && m.date.isAfter(now),
        );
      } catch (_) {
        // 3. Fallback to the last match if all are played
        if (widget.matches.isNotEmpty) {
          targetMatch = widget.matches.last;
        }
      }
    }

    final targetDate = targetMatch != null ? targetMatch.date : _tournamentStart;
    _targetMatchDate = targetDate;

    final daysSinceMonday = targetDate.weekday - DateTime.monday;
    _currentWeekStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    ).subtract(Duration(days: daysSinceMonday));
  }

  void _scrollToFirstMatchOfTargetDay() {
    if (_targetMatchDate == null ||
        widget.matches.isEmpty ||
        !_verticalScrollController.hasClients) {
      return;
    }

    final now = DateTime.now();
    final dayFormat = DateFormat('yyyy-MM-dd');
    final targetDayStr = dayFormat.format(_targetMatchDate!);

    final targetDayMatches = widget.matches
        .where((m) => dayFormat.format(m.date) == targetDayStr)
        .toList();
    if (targetDayMatches.isEmpty) return;

    targetDayMatches.sort((a, b) => a.date.compareTo(b.date));
    int targetHour = targetDayMatches.first.date.hour;

    try {
      final relevantMatch = targetDayMatches.firstWhere((m) {
        final duration = m.isKnockout 
            ? const Duration(minutes: 180) 
            : const Duration(minutes: 120);
        final matchEndThreshold = m.date.add(duration);
        return !m.isPlayed && now.isBefore(matchEndThreshold);
      });
      targetHour = relevantMatch.date.hour;
    } catch (_) {
      targetHour = targetDayMatches.last.date.hour;
    }

    const double rowHeight = 110.0;
    final hoursList = widget.matches
        .where((m) {
      final end = _currentWeekStart.add(const Duration(days: 6));
      return m.date.isAfter(
        _currentWeekStart.subtract(const Duration(milliseconds: 1)),
      ) &&
          m.date.isBefore(end.add(const Duration(days: 1)));
    })
        .map((m) => m.date.hour)
        .toList();

    final currentMinHour = hoursList.isNotEmpty
        ? hoursList.reduce((a, b) => a < b ? a : b) - 1
        : 10;
    final int minHourClamped = currentMinHour.clamp(0, 23);

    double viewportHeight = 400.0;
    if (_verticalScrollController.hasClients) {
      viewportHeight = _verticalScrollController.position.viewportDimension;
      if (viewportHeight < 100.0) {
        viewportHeight = 400.0; // fallback if layout not fully complete
      }
    }

    double scrollOffset = (targetHour - minHourClamped) * rowHeight - (viewportHeight / 2) + (rowHeight / 2);
    final maxScroll = _verticalScrollController.position.maxScrollExtent;
    scrollOffset = scrollOffset.clamp(0.0, maxScroll);

    _verticalScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollToTargetDayHorizontal() {
    if (_targetMatchDate == null || !_horizontalScrollController.hasClients) return;

    final targetDate = DateTime(_targetMatchDate!.year, _targetMatchDate!.month, _targetMatchDate!.day);
    final weekStartDate = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    
    final dayIndex = targetDate.difference(weekStartDate).inDays;
    
    if (dayIndex >= 0 && dayIndex < 7) {
      const double colWidth = 175.0;
      
      double viewportWidth = 320.0;
      if (_horizontalScrollController.hasClients) {
        viewportWidth = _horizontalScrollController.position.viewportDimension;
        if (viewportWidth < 100.0) {
          viewportWidth = 320.0; // fallback
        }
      }

      double scrollOffset = (dayIndex * colWidth) - (viewportWidth / 2) + (colWidth / 2);
      
      final maxScroll = _horizontalScrollController.position.maxScrollExtent;
      scrollOffset = scrollOffset.clamp(0.0, maxScroll);

      _horizontalScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstMatchOfTargetDay();
      _scrollToTargetDayHorizontal();
    });
  }

  String _getWeekLabel() {
    final end = _currentWeekStart.add(const Duration(days: 6));
    final startLabel = DateFormat.MMMd(widget.lang).format(_currentWeekStart);
    final endLabel = DateFormat.yMMMd(widget.lang).format(end);
    return '$startLabel - $endLabel';
  }

  Widget _buildFlag(String code) {
    return TeamFlagWidget.flag(code, width: 24, height: 16, borderRadius: 4);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duration = now.timeZoneOffset;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).abs();
    final sign = duration.isNegative ? '-' : '+';

    final String localTimeZoneLabel = hours == 0
        ? 'GMT'
        : 'GMT$sign${hours.abs()}:${minutes.toString().padLeft(2, '0')}';

    String tzSubtitle = AppTranslations.get(
      widget.lang,
      'allTimesIn',
    ).replaceAll('{tz}', localTimeZoneLabel);

    const double rowHeight = 110.0;
    const double colWidth = 175.0;


    final dayFormat = DateFormat('yyyy-MM-dd');
    final localizedDayFormat = DateFormat('E d MMM', widget.lang);
    final targetMatchStr = _targetMatchDate != null
        ? dayFormat.format(_targetMatchDate!)
        : '';

    final weekDates = List.generate(7, (i) {
      return _currentWeekStart.add(Duration(days: i));
    });

    final weekEnd = _currentWeekStart
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));

    final weekMatches = widget.matches.where((m) {
      return m.date.isAfter(
        _currentWeekStart.subtract(const Duration(milliseconds: 1)),
      ) &&
          m.date.isBefore(weekEnd);
    }).toList();

    int minHour = 10;
    int maxHour = 22;
    if (weekMatches.isNotEmpty) {
      final hoursList = weekMatches.map((m) => m.date.hour).toList();
      final min = hoursList.reduce((a, b) => a < b ? a : b) - 1;
      final max = hoursList.reduce((a, b) => a > b ? a : b) + 3;
      minHour = min.clamp(0, 23);
      maxHour = max.clamp(0, 23);
    }
    final int hoursCount = maxHour - minHour + 1;
    final double gridHeight = hoursCount * rowHeight;

    double? timelineNowTop;
    int? timelineNowDayIdx;
    if (now.isAfter(
      _currentWeekStart.subtract(const Duration(milliseconds: 1)),
    ) &&
        now.isBefore(weekEnd)) {
      timelineNowDayIdx = now.weekday - DateTime.monday;
      timelineNowTop = ((now.hour - minHour) + (now.minute / 60)) * rowHeight;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => _changeWeek(-7),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getWeekLabel(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tzSubtitle,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => _changeWeek(7),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 65,
                    color: AppColors.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48,
                          width: 65,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.cardDark,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              right: BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textDim,
                            size: 16,
                          ),
                        ),
                        SizedBox(
                          height: gridHeight + 100,
                          width: 65,
                          child: Stack(
                            children: List.generate(hoursCount, (idx) {
                              final hr = minHour + idx;
                              return Positioned(
                                top: idx * rowHeight + 8,
                                right: 10,
                                child: Text(
                                  '${hr.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(7, (dayIdx) {
                            final date = weekDates[dayIdx];
                            final dateStr = dayFormat.format(date);
                            final localizedDayLabel = localizedDayFormat.format(
                              date,
                            );
                            final isTargetDay = dateStr == targetMatchStr;

                            final dayMatches = widget.matches
                                .where(
                                  (m) => dayFormat.format(m.date) == dateStr,
                            )
                                .toList();

                            return Container(
                              width: colWidth,
                              decoration: BoxDecoration(
                                color: isTargetDay
                                    ? AppColors.accent.withValues(alpha: 0.02)
                                    : Colors.transparent,
                                border: Border(
                                  right: BorderSide(
                                    color: isTargetDay
                                        ? AppColors.accent.withValues(alpha: 0.3)
                                        : AppColors.border,
                                    width: isTargetDay ? 1.5 : 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 48,
                                    width: colWidth,
                                    decoration: BoxDecoration(
                                      color: isTargetDay
                                          ? AppColors.accent.withValues(alpha: 0.08)
                                          : (dayMatches.isNotEmpty
                                          ? AppColors.border.withValues(alpha:
                                      0.2,
                                      )
                                          : Colors.transparent),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isTargetDay
                                              ? AppColors.accent
                                              : AppColors.border,
                                          width: isTargetDay ? 2 : 1.5,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      localizedDayLabel,
                                      style: TextStyle(
                                        color: isTargetDay
                                            ? AppColors.accent
                                            : (dayMatches.isNotEmpty
                                            ? Colors.white
                                            : AppColors.textDim),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: gridHeight + 100,
                                    width: colWidth,
                                    child: Stack(
                                      children: [
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

                        ...dayMatches.map((m) {
                                          final topOffset =
                                              ((m.date.hour - minHour) +
                                                  (m.date.minute / 60)) *
                                                  rowHeight;
                                          final double dynamicDuration = (m.wentToET == true || m.wentToPK == true) ? 3.0 : 2.0;
                                          final blockHeight =
                                              dynamicDuration * rowHeight;
                                          final simultaneous = dayMatches
                                              .where(
                                                (x) =>
                                            x.date.hour ==
                                                m.date.hour &&
                                                x.date.minute ==
                                                    m.date.minute,
                                          )
                                              .toList();
                                          final int totalSimultaneous =
                                              simultaneous.length;
                                          final colIndex = simultaneous
                                              .indexWhere((x) => x.id == m.id);

                                          final widthFactor =
                                          (0.94 / totalSimultaneous);
                                          final leftMargin =
                                              0.03 + (colIndex * widthFactor);

                                          final hasAlert = widget.hasAlert(m);
                                          final hasPredicted = widget
                                              .hasPredicted(m);

                                          final live =
                                              !m.isPlayed &&
                                                  now.isAfter(m.date) &&
                                                  now.isBefore(
                                                    m.date.add(
                                                      m.isKnockout 
                                                          ? const Duration(minutes: 180) 
                                                          : const Duration(minutes: 120),
                                                    ),
                                                  );

                                          final isUserTeam =
                                              widget.supportedTeamCode !=
                                                  null &&
                                                  (m.t1.toLowerCase() ==
                                                      widget.supportedTeamCode!
                                                          .toLowerCase() ||
                                                      m.t2.toLowerCase() ==
                                                          widget.supportedTeamCode!
                                                              .toLowerCase());

                                          final stageText = m.isKnockout
                                              ? (m.stage ?? '')
                                              : '${AppTranslations.get(widget.lang, 'group')} ${m.group ?? ''}';

                                          final IconData predIcon;
                                          final Color predColor;
                                          final String tooltipMessage;

                                          if (m.isPlayed && hasPredicted) {
                                            // Correction logic Pronostic
                                            final predResult = PredictionService.getPredictionResult(
                                              m,
                                              PredictionData(preds: widget.userPredictions ?? {}),
                                            );

                                            if (predResult == 'exact') {
                                              predIcon = Icons.star_rounded;
                                              predColor = Colors.amber;
                                              tooltipMessage =
                                                  AppTranslations.get(
                                                    widget.lang,
                                                    'exactScoreTooltip',
                                                  );
                                            } else if (predResult == 'winner') {
                                              predIcon =
                                                  Icons.check_circle_rounded;
                                              predColor = Colors.greenAccent;
                                              tooltipMessage =
                                                  AppTranslations.get(
                                                    widget.lang,
                                                    'correctWinnerTooltip',
                                                  );
                                            } else {
                                              predIcon = Icons.cancel_rounded;
                                              predColor = Colors.redAccent;
                                              tooltipMessage =
                                                  AppTranslations.get(
                                                    widget.lang,
                                                    'wrongPredictionTooltip',
                                                  );
                                            }
                                          } else if (hasPredicted) {
                                            predIcon =
                                                Icons.check_circle_rounded;
                                            predColor = Colors.greenAccent;
                                            tooltipMessage =
                                                AppTranslations.get(
                                                  widget.lang,
                                                  'predictionSavedTooltip',
                                                );
                                          } else {
                                            predIcon =
                                                Icons.pending_actions_rounded;
                                            predColor = Colors.orangeAccent;
                                            tooltipMessage =
                                                AppTranslations.get(
                                                  widget.lang,
                                                  'predictionPendingTooltip',
                                                );
                                          }

                                          final blockColor = isUserTeam
                                              ? AppColors.accent.withValues(alpha:
                                          0.06,
                                          )
                                              : (hasAlert
                                              ? const Color(0xFF0F2D21)
                                              : AppColors.border);
                                          final borderColor = live
                                              ? AppColors.accent
                                              : (isUserTeam
                                              ? AppColors.accent
                                              : (hasAlert
                                              ? AppColors.accent
                                              : AppColors
                                              .borderMid));
                                          final borderWidth =
                                          (live || isUserTeam) ? 2.0 : 1.5;

                                          return Positioned(
                                            top: topOffset + 2,
                                            left: colWidth * leftMargin,
                                            width:
                                            colWidth * (widthFactor - 0.02),
                                            height: blockHeight - 4,
                                            child: GestureDetector(
                                              onTap: () => widget.onMatchTap(m),
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: blockColor,
                                                  borderRadius:
                                                  BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: borderColor,
                                                    width: borderWidth,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxHeight: blockHeight - 20,
                                                        maxWidth: colWidth * widthFactor - 16,
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment.center,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.center,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              if (live)
                                                                const Text(
                                                                  '⚽ LIVE',
                                                                  style: TextStyle(
                                                                    color: AppColors.accent,
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.w900,
                                                                    letterSpacing: 0.8,
                                                                  ),
                                                                )
                                                              else
                                                                Text(
                                                                  m.getFormattedTime(),
                                                                  style: const TextStyle(
                                                                    color: AppColors.textMuted,
                                                                    fontSize: 10,
                                                                    fontFamily: 'monospace',
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              const SizedBox(width: 4),
                                                              WCTooltip(
                                                                message: tooltipMessage,
                                                                triggerMode: TooltipTriggerMode.tap,
                                                                preferBelow: false,
                                                                child: Icon(
                                                                  predIcon,
                                                                  color: predColor,
                                                                  size: 12,
                                                                ),
                                                              ),
                                                              if (hasAlert) ...[
                                                                const SizedBox(width: 4),
                                                                const Icon(
                                                                  Icons.notifications_active,
                                                                  color: AppColors.accent,
                                                                  size: 10,
                                                                ),
                                                              ],
                                                            ],
                                                          ),

                                                          if (stageText.isNotEmpty) ...[
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              stageText,
                                                              style: const TextStyle(
                                                                color: AppColors.textMuted,
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],

                                                          const SizedBox(height: 6),
                                                          Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              _buildFlag(m.t1),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                AppTranslations.getTeam(widget.lang, m.t1),
                                                                style: TextStyle(
                                                                  color: _isPlaceholder(m.t1) ? AppColors.textDim : Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                  height: 1.1,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),

                                                          const SizedBox(height: 4),
                                                          m.isPlayed
                                                              ? Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                '${m.t1Score ?? '-'} - ${m.t2Score ?? '-'}',
                                                                style: const TextStyle(
                                                                  color: AppColors.accent,
                                                                  fontWeight: FontWeight.w900,
                                                                  fontSize: 12,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                              if (m.wentToPK == true && m.t1ScorePK != null)
                                                                Text(
                                                                  '(${m.t1ScorePK}-${m.t2ScorePK} PK)',
                                                                  style: TextStyle(
                                                                    color: AppColors.accent.withValues(alpha: 0.7),
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 8,
                                                                  ),
                                                                )
                                                              else if (m.wentToET == true)
                                                                const Text(
                                                                  '(AET)',
                                                                  style: TextStyle(
                                                                    color: AppColors.warning,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 8,
                                                                  ),
                                                                ),
                                                            ],
                                                          )
                                                              : Text(
                                                            'VS',
                                                            style: TextStyle(
                                                              color: AppColors.accent.withValues(alpha: 0.5),
                                                              fontWeight: FontWeight.w900,
                                                              fontSize: 8.5,
                                                              letterSpacing: 0.5,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),

                                                          const SizedBox(height: 4),
                                                          Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              _buildFlag(m.t2),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                AppTranslations.getTeam(widget.lang, m.t2),
                                                                style: TextStyle(
                                                                  color: _isPlaceholder(m.t2) ? AppColors.textDim : Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                  height: 1.1,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),

                                        if (timelineNowTop != null &&
                                            timelineNowDayIdx == dayIdx)
                                          Positioned(
                                            top: timelineNowTop,
                                            left: 0,
                                            right: 0,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  height: 2,
                                                  color: Colors.redAccent,
                                                ),
                                                Positioned(
                                                  top: -4,
                                                  left: -3,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration:
                                                    const BoxDecoration(
                                                      color:
                                                      Colors.redAccent,
                                                      shape:
                                                      BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}