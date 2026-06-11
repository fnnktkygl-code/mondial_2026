import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import '../services/audio_service.dart';
import '../services/insights_service.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';

class MatchDetailSheet extends StatefulWidget {
  final WorldCupMatch match;
  final String lang;
  final String? activeAlert;
  final Function(String alertType) onSaveAlert;
  final MatchPrediction? prediction;
  final Function(int t1Score, int t2Score)? onPredictionChanged;

  const MatchDetailSheet({
    super.key,
    required this.match,
    required this.lang,
    required this.activeAlert,
    required this.onSaveAlert,
    this.prediction,
    this.onPredictionChanged,
  });

  @override
  State<MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<MatchDetailSheet> with SingleTickerProviderStateMixin {
  int? _localT1Score;
  int? _localT2Score;
  bool _isEditing = false;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initLocalScores();
    _startCountdown();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Helper localisé pour garantir la robustesse sans chaînes codées en dur
  String _t(String key, {Map<String, String>? namedArgs}) {
    String res = AppTranslations.get(widget.lang, key);
    if (res == key) {
      final Map<String, Map<String, String>> fallbacks = {
        'fr': {
          'probabilityTitle': 'PROBABILITÉS THÉORIQUES (INDEX FIFA)',
          'probabilityExplanation': 'Calculé de manière transparente et déterministe en comparant l\'indice de force officiel FIFA de chaque nation.',
          'alertsUnavailable': 'Les rappels d\'alertes ne sont plus disponibles car le coup d\'envoi est imminent.',
          'predictButton': 'Saisir mon pronostic',
        },
        'en': {
          'probabilityTitle': 'AI WIN PROBABILITIES (FIFA RATING)',
          'probabilityExplanation': 'Calculated transparently and deterministically by comparing the official FIFA strength ratings of both nations.',
          'alertsUnavailable': 'Alert reminders are no longer available because kickoff is imminent.',
          'predictButton': 'Enter my prediction',
        },
        'es': {
          'probabilityTitle': 'PROBABILIDADES TEÓRICAS (ÍNDICE FIFA)',
          'probabilityExplanation': 'Calculado de manera transparente y determinante comparando el índice de fuerza oficial de la FIFA de cada nación.',
          'alertsUnavailable': 'Los recordatorios de alerta ya no están disponibles porque el comienzo es inminente.',
          'predictButton': 'Guardar Pronóstico',
        }
      };
      res = fallbacks[widget.lang]?[key] ?? fallbacks['en']?[key] ?? key;
    }
    if (namedArgs != null) {
      namedArgs.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    return res;
  }

  Widget _buildProInsightsSection() {
    final history1 = WCInsightsService.getHistory(widget.match.t1);
    final history2 = WCInsightsService.getHistory(widget.match.t2);
    final funFact1 = WCInsightsService.getRandomFunFact(widget.match.t1);
    final funFact2 = WCInsightsService.getRandomFunFact(widget.match.t2);

    if (history1 == null && history2 == null && funFact1 == null && funFact2 == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              _t('worldCupHistoryTitle'),
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5,
                fontFamily: 'Syne',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // --- DEUX CARTES SÉPARÉES (Une par équipe) ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (history1 != null) Expanded(child: _buildTeamHistoryCard(widget.match.t1, history1, funFact1)),
            if (history1 != null && history2 != null) const SizedBox(width: 12),
            if (history2 != null) Expanded(child: _buildTeamHistoryCard(widget.match.t2, history2, funFact2)),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamHistoryCard(String teamCode, TeamHistory history, String? funFact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamFlagWidget(code: teamCode, width: 18, height: 12, borderRadius: 2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppTranslations.getTeam(widget.lang, teamCode).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSmallStatRow(_t('playedShort'), history.played),
          _buildSmallStatRow(_t('winsShort'), history.wins),
          _buildSmallStatRow(_t('goalsShort'), history.goalsFor),
          if (funFact != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.border, height: 1),
            ),
            Text(
              funFact,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 9, height: 1.3, fontStyle: FontStyle.italic),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSmallStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w600)),
          Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _initLocalScores() {
    if (widget.prediction != null) {
      _localT1Score = widget.prediction!.t1Score;
      _localT2Score = widget.prediction!.t2Score;
      _isEditing = true;
    } else {
      _localT1Score = 0;
      _localT2Score = 0;
      _isEditing = false;
    }
  }

  void _startCountdown() {
    final now = DateTime.now();
    final difference = widget.match.date.difference(now);
    if (!difference.isNegative && difference.inHours < 24) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
        title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        content: Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                AppTranslations.get(widget.lang, 'cancel').toUpperCase(),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)
            ),
          ),
        ],
      ),
    );
  }

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
      child: TeamFlagWidget(
        code: code,
        width: size * 1.4,
        height: size,
        borderRadius: 10,
      ),
    );
  }

  Map<String, double> _calculateProbability(String t1, String t2) {
    final int charSum1 = t1.codeUnits.fold(0, (sum, val) => sum + val);
    final int charSum2 = t2.codeUnits.fold(0, (sum, val) => sum + val);

    final double r1 = kTeamRatings[t1.replaceAll('g_', '').toLowerCase()] ?? (1300.0 + (charSum1 % 100));
    final double r2 = kTeamRatings[t2.replaceAll('g_', '').toLowerCase()] ?? (1300.0 + (charSum2 % 100));

    const double eloDivisor = 600.0;
    final double diff = r1 - r2;
    final double pHome = 1.0 / (1.0 + _pow10(-diff / eloDivisor));
    final double pAway = 1.0 / (1.0 + _pow10(diff / eloDivisor));

    final double pDraw = (0.28 - (diff.abs() / 3000.0)).clamp(0.16, 0.28);
    final double scale = (1.0 - pDraw) / (pHome + pAway);

    return {
      'home': pHome * scale,
      'draw': pDraw,
      'away': pAway * scale,
    };
  }

  double _pow10(double x) => math.pow(10.0, x).toDouble();

  Widget _buildCountdownWidget() {
    final now = DateTime.now();
    if (widget.match.date.isBefore(now)) {
      return const SizedBox.shrink();
    }

    final difference = widget.match.date.difference(now);
    String label = '';
    bool isUrgent = false;

    if (difference.inDays >= 1) {
      label = _t('locksInDays', namedArgs: {'days': '${difference.inDays}'});
    } else {
      isUrgent = true;
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
      label = _t('locksInTime', namedArgs: {'time': '$hours:$minutes:$seconds'});
    }

    final String tooltipMsg = AppTranslations.get(widget.lang, 'predictionLockMsg');

    return GestureDetector(
      onTap: () => _showInfoDialog(
          AppTranslations.get(widget.lang, 'aboutLocking'),
          tooltipMsg
      ),
      child: FadeTransition(
        opacity: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isUrgent ? AppColors.danger.withValues(alpha: 0.12) : AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUrgent ? AppColors.danger : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUrgent ? Icons.timer_outlined : Icons.lock_clock,
                color: isUrgent ? AppColors.danger : AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isUrgent ? AppColors.danger : AppColors.warning,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                  Icons.info_outline,
                  color: (isUrgent ? AppColors.danger : AppColors.warning).withValues(alpha: 0.8),
                  size: 13
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilityBar(BuildContext context) {
    final cleanT1 = widget.match.t1.replaceFirst('g_', '').toUpperCase();
    final cleanT2 = widget.match.t2.replaceFirst('g_', '').toUpperCase();
    final probs = _calculateProbability(widget.match.t1, widget.match.t2);
    final pHome = (probs['home']! * 100).round();
    final pDraw = (probs['draw']! * 100).round();
    final pAway = 100 - pHome - pDraw;

    final String titleLabel = _t('probabilityTitle');
    final String tooltipMsg = _t('probabilityExplanation');

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
                titleLabel,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => _showInfoDialog(
                    AppTranslations.get(widget.lang, 'aboutProbabilities'),
                    tooltipMsg
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
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
                  fontSize: 13,
                ),
              ),
              Text(
                '${AppTranslations.get(widget.lang, 'drawLabel')} $pDraw%',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '$cleanT2 $pAway%',
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionControlCard() {
    final bool isMatchStarted = widget.match.date.isBefore(DateTime.now());
    final bool isLocked = widget.match.isPlayed || isMatchStarted;

    if (isLocked) {
      return GestureDetector(
        onTap: () => _showInfoDialog(
            AppTranslations.get(widget.lang, 'predictionLocked'),
            AppTranslations.get(widget.lang, 'predictionLockMsg')
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.get(widget.lang, 'predictionLocked'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.prediction != null
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.prediction != null
                      ? 'Prono : ${widget.prediction!.t1Score} - ${widget.prediction!.t2Score}'
                      : AppTranslations.get(widget.lang, 'noPrediction'),
                  style: TextStyle(
                    color: widget.prediction != null ? AppColors.accent : AppColors.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontStyle: widget.prediction == null ? FontStyle.italic : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isEditing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.edit_note, size: 22),
          label: Text(
            _t('predictButton'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
            widget.onPredictionChanged?.call(_localT1Score!, _localT2Score!);
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_calendar, color: AppColors.accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.get(widget.lang, 'myPrediction').toUpperCase(),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = false;
                    _localT1Score = 0;
                    _localT2Score = 0;
                  });
                  widget.onPredictionChanged?.call(0, 0);
                },
                child: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreAdjuster(_localT1Score!, (val) => setState(() => _localT1Score = val), true),
              const Text(
                '-',
                style: TextStyle(color: AppColors.borderStrong, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              _buildScoreAdjuster(_localT2Score!, (val) => setState(() => _localT2Score = val), false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAdjuster(int score, Function(int) onChanged, bool isT1) {
    return Row(
      children: [
        IconButton(
          onPressed: score > 0
              ? () {
            onChanged(score - 1);
            widget.onPredictionChanged?.call(_localT1Score!, _localT2Score!);
          }
              : null,
          icon: const Icon(Icons.remove_circle_outline, color: AppColors.textDim, size: 30),
        ),
        const SizedBox(width: 4),
        Text(
          '$score',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: score < 9
              ? () {
            onChanged(score + 1);
            widget.onPredictionChanged?.call(_localT1Score!, _localT2Score!);
          }
              : null,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 30),
        ),
      ],
    );
  }

  Widget _buildSmartAlerts(BuildContext context) {
    final now = DateTime.now();

    final oneDayAlertDate = widget.match.date.subtract(const Duration(days: 1));
    final oneHourAlertDate = widget.match.date.subtract(const Duration(hours: 1));
    final thirtyMinAlertDate = widget.match.date.subtract(const Duration(minutes: 30));

    final bool showOneDay = now.isBefore(oneDayAlertDate);
    final bool showOneHour = now.isBefore(oneHourAlertDate);
    final bool showThirtyMin = now.isBefore(thirtyMinAlertDate);

    if (!showOneDay && !showOneHour && !showThirtyMin) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined, color: AppColors.textDim, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _t('alertsUnavailable'),
                style: const TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showOneDay) ...[
          _buildAlertButton(context, '1d', AppTranslations.get(widget.lang, 'alert1Day')),
          const SizedBox(height: 8),
        ],
        if (showOneHour) ...[
          _buildAlertButton(context, '1h', AppTranslations.get(widget.lang, 'alert1Hour')),
          const SizedBox(height: 8),
        ],
        if (showThirtyMin) ...[
          _buildAlertButton(context, '30m', AppTranslations.get(widget.lang, 'alert30Min')),
        ],
      ],
    );
  }

  Widget _buildAlertButton(BuildContext context, String type, String label) {
    final isSelected = widget.activeAlert == type;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          widget.onSaveAlert(type);
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
                fontSize: 14,
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

  Widget _buildStatBar({required String label, required int val1, required int val2, String suffix = '', Color colorT1 = AppColors.accent, Color colorT2 = AppColors.info}) {
    final int sum = val1 + val2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$val1$suffix', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              Text('$val2$suffix', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(flex: sum == 0 ? 1 : val1, child: Container(height: 6, color: colorT1)),
              const SizedBox(width: 2),
              Expanded(flex: sum == 0 ? 1 : val2, child: Container(height: 6, color: colorT2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnthemPlayButton(String teamCode) {
    final audioService = WCAudioService.instance;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<String?>(
        valueListenable: audioService.currentPlayingTeamCode,
        builder: (context, playingCode, _) {
          final isThis = playingCode == teamCode.toLowerCase().replaceAll('g_', '');
          return ValueListenableBuilder<PlayerState>(
            valueListenable: audioService.playerState,
            builder: (context, state, _) {
              final isPlaying = isThis && state == PlayerState.playing;
              return InkWell(
                onTap: () => audioService.playAnthem(teamCode),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isThis ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isThis ? AppColors.accent : AppColors.border)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: isThis ? AppColors.accent : AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(isPlaying ? "Pause" : "Hymn", style: TextStyle(color: isThis ? AppColors.accent : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamDetailSection(String teamCode, String emblemName) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => WCTeamProfileDialog.show(context, teamCode, widget.lang),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle Background Flag
            Opacity(
              opacity: 0.04,
              child: Transform.scale(
                scale: 3.0,
                child: TeamFlagWidget.flag(
                  teamCode,
                  width: 60,
                  height: 40,
                ),
              ),
            ),
            // Team Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFlag(teamCode, 48),
                  const SizedBox(height: 10),
                  Text(
                    emblemName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildAnthemPlayButton(teamCode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t1EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, widget.match.t1);
    final t2EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, widget.match.t2);
    final localizedDateTimeStr = DateFormat.yMMMMEEEEd(widget.lang).add_Hm().format(widget.match.date);

    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.borderMid, borderRadius: BorderRadius.circular(2.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildTeamDetailSection(widget.match.t1, t1EmblemName)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: widget.match.isPlayed
                      ? Text(
                    '${widget.match.t1Score} - ${widget.match.t2Score}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  )
                      : const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.borderStrong,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ),
                Expanded(child: _buildTeamDetailSection(widget.match.t2, t2EmblemName)),
              ],
            ),
          ),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildCountdownWidget()),
                  const SizedBox(height: 4),
                  _buildPredictionControlCard(),
                  const SizedBox(height: 20),
                  _buildProbabilityBar(context),
                  const SizedBox(height: 20),
                  if (widget.match.isPlayed && widget.match.goals.isNotEmpty) ...[
                    Text(
                      AppTranslations.get(widget.lang, 'scorers').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
                          const Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: VerticalDivider(color: AppColors.borderMid, width: 2),
                            ),
                          ),
                          Column(
                            children: widget.match.goals.map((g) {
                              final isT1Goal = g.team == 't1';
                              final assistText = g.assistant != null ? '\n(ass: ${g.assistant})' : '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: isT1Goal
                                          ? Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              g.scorer + assistText,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${g.minute}'",
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      )
                                          : const SizedBox.shrink(),
                                    ),
                                    Container(
                                      width: 30,
                                      alignment: Alignment.center,
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
                                    Expanded(
                                      child: !isT1Goal
                                          ? Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${g.minute}'",
                                            style: const TextStyle(
                                              color: AppColors.info,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              g.scorer + assistText,
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                          : const SizedBox.shrink(),
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
                  if (widget.match.isPlayed && widget.match.stats != null) ...[
                    Text(
                      AppTranslations.get(widget.lang, 'stats').toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
                            label: AppTranslations.get(widget.lang, 'possession'),
                            val1: widget.match.stats!.possessionT1,
                            val2: widget.match.stats!.possessionT2,
                            suffix: '%',
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'shots'),
                            val1: widget.match.stats!.shotsT1,
                            val2: widget.match.stats!.shotsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'shotsOnTarget'),
                            val1: widget.match.stats!.shotsOnTargetT1,
                            val2: widget.match.stats!.shotsOnTargetT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'fouls'),
                            val1: widget.match.stats!.foulsT1,
                            val2: widget.match.stats!.foulsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'yellowCards'),
                            val1: widget.match.stats!.yellowCardsT1,
                            val2: widget.match.stats!.yellowCardsT2,
                            colorT1: AppColors.warningYellow,
                            colorT2: AppColors.warningYellow,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'redCards'),
                            val1: widget.match.stats!.redCardsT1,
                            val2: widget.match.stats!.redCardsT2,
                            colorT1: AppColors.danger,
                            colorT2: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    AppTranslations.get(widget.lang, 'setAlertTitle').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSmartAlerts(context),
                  if (widget.activeAlert != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        label: Text(
                          AppTranslations.get(widget.lang, 'removeAlert'),
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
                          widget.onSaveAlert('none');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],

                  // --- SECTION PRO INSIGHTS (TOUT EN BAS) ---
                  _buildProInsightsSection(),
                  const SizedBox(height: 48), // Espace final pour ne pas être collé au bord
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}