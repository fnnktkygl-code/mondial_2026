import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../services/odds_service.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import '../services/audio_service.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';
import '../services/insights_service.dart';
import '../services/player_database_service.dart';
import '../services/espn_api_service.dart';

class MatchDetailSheet extends StatefulWidget {
  final WorldCupMatch match;
  final List<WorldCupMatch> allMatches;
  final String lang;
  final String? activeAlert;
  final Function(String alertType) onSaveAlert;
  final MatchPrediction? prediction;
  final List<String> boosterMatchIds;
  final Function(bool isBoosterActive)? onBoosterChanged;
  final Function(WorldCupMatch updatedMatch)? onMatchUpdated;
  final Function(int t1Score, int t2Score, String? etWinner, bool? pkWinner, Map<String, int>? predictedScorers)? onPredictionChanged;

  const MatchDetailSheet({
    super.key,
    required this.match,
    required this.allMatches,
    required this.lang,
    required this.activeAlert,
    required this.onSaveAlert,
    this.prediction,
    this.boosterMatchIds = const [],
    this.onBoosterChanged,
    this.onMatchUpdated,
    this.onPredictionChanged,
  });

  @override
  State<MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<MatchDetailSheet> with TickerProviderStateMixin {
  late WorldCupMatch _matchState;
  bool _isRefreshing = false;
  int? _localT1Score;
  int? _localT2Score;
  String? _localEtWinner;
  bool? _localPkWinner;
  bool _isEditing = false;
  Timer? _countdownTimer;
  Timer? _funFactTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _factFadeController;
  late Animation<double> _factFadeAnimation;

  int _activeFactTeam = 0;
  Map<String, int> _localPredictedScorers = {};
  bool _localBoosterActive = false;

  @override
  void initState() {
    super.initState();
    _matchState = widget.match;
    _initLocalScores();
    // Gère l'état initial d'édition
    _isEditing = widget.prediction == null;
    _localPredictedScorers = Map.from(widget.prediction?.predictedScorers ?? {});
    _localBoosterActive = widget.boosterMatchIds.contains(_matchState.id);
    _startCountdown();
    _refreshMatchData(); // Immediate fetch for the latest details

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _factFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _factFadeAnimation = CurvedAnimation(
      parent: _factFadeController,
      curve: Curves.easeInOut,
    );
    _factFadeController.forward();

    _funFactTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _cycleFactTeam();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _funFactTimer?.cancel();
    _pulseController.dispose();
    _factFadeController.dispose();
    super.dispose();
  }

  void _initLocalScores() {
    if (widget.prediction != null) {
      _localT1Score = widget.prediction!.t1Score;
      _localT2Score = widget.prediction!.t2Score;
      _localEtWinner = widget.prediction!.extraTimeWinner;
      _localPkWinner = widget.prediction!.penaltyWinner;
    } else {
      _localT1Score = 0;
      _localT2Score = 0;
      _localEtWinner = null;
      _localPkWinner = null;
    }
  }

  Future<void> _refreshMatchData() async {
    if (_isRefreshing) return;
    
    // Determine the ESPN ID. If our internal ID is 'espn_123', use '123'.
    // If it's a regular ID, we might not have a direct mapping unless we search.
    String? espnId;
    if (_matchState.id.startsWith('espn_')) {
      espnId = _matchState.id.replaceFirst('espn_', '');
    } else {
      // Fallback: try to find it in the global scoreboard first
      final liveMatches = await EspnApiService.fetchLiveMatches();
      try {
        final found = liveMatches.firstWhere((m) => 
          (m.t1 == _matchState.t1 && m.t2 == _matchState.t2) ||
          (m.t1 == _matchState.t2 && m.t2 == _matchState.t1)
        );
        espnId = found.id.replaceFirst('espn_', '');
      } catch (_) {}
    }

    if (espnId == null) {
      debugPrint("Could not find ESPN ID for match ${_matchState.id}");
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final summary = await EspnApiService.fetchMatchSummary(espnId);
      if (summary != null && mounted) {
        setState(() {
          _matchState = summary;
          _isRefreshing = false;
        });
        if (widget.onMatchUpdated != null) {
          widget.onMatchUpdated!(summary);
        }
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint("Error refreshing match: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  bool _isPlaceholder(String code) {
    final c = code.toLowerCase().replaceAll('g_', '');
    return (c.length > 2 && c != 'sco' && c != 'gb-sct') || c == 'tbd' || c.contains(RegExp(r'\d'));
  }

  void _cycleFactTeam() async {
    await _factFadeController.reverse();
    if (mounted) {
      setState(() {
        _activeFactTeam = 1 - _activeFactTeam;
      });
      _factFadeController.forward();
    }
  }

  Widget _buildFunFactChip() {
    final teamCode = _activeFactTeam == 0 ? _matchState.t1 : _matchState.t2;
    final otherCode = _activeFactTeam == 0 ? _matchState.t2 : _matchState.t1;

    if (_isPlaceholder(teamCode) && _isPlaceholder(otherCode)) {
      return const SizedBox.shrink();
    }

    final matchupFact = WCInsightsService.getMatchupFact(
      _matchState.t1,
      _matchState.t2,
    );
    final isMatchupMode = matchupFact != null;

    final fact = isMatchupMode ? matchupFact : WCInsightsService.getRandomFunFact(teamCode);

    Widget dots() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(0),
          const SizedBox(width: 6),
          _dot(1),
        ],
      );
    }

    final hasFact = fact != null || WCInsightsService.getRandomFunFact(otherCode) != null;
    if (!hasFact) return const SizedBox.shrink();

    final Map<String, String> labels = {
      'fr': isMatchupMode ? 'FACE-À-FACE' : 'LE SAVIEZ-VOUS ?',
      'en': isMatchupMode ? 'HEAD-TO-HEAD' : 'DID YOU KNOW?',
      'es': isMatchupMode ? 'CARA A CARA' : '¿SABÍAS QUE?',
    };
    final headerLabel = labels[widget.lang] ?? labels['en']!;

    return GestureDetector(
      onTap: isMatchupMode ? null : _cycleFactTeam,
      child: FadeTransition(
        opacity: _factFadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isMatchupMode) ...[
                          _buildTeamCodeBadge(_matchState.t1),
                          const SizedBox(width: 4),
                          const Text(
                            'vs',
                            style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildTeamCodeBadge(_matchState.t2),
                        ] else
                          _buildTeamCodeBadge(teamCode),
                        const SizedBox(width: 8),
                        Text(
                          headerLabel,
                          style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (fact != null)
                      _buildFactRichText(fact)
                    else
                      const SizedBox.shrink(),
                    if (!isMatchupMode && !_isPlaceholder(otherCode)) ...[
                      const SizedBox(height: 8),
                      dots(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCodeBadge(String code) {
    if (_isPlaceholder(code)) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code.replaceAll('g_', '').toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00BCD4),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _dot(int index) {
    final isActive = _activeFactTeam == index;
    final code = index == 0 ? _matchState.t1 : _matchState.t2;
    if (_isPlaceholder(code)) return const SizedBox.shrink();

    return GestureDetector(
      onTap: isActive ? null : _cycleFactTeam,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isActive ? 1.0 : 0.35,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00BCD4)
                  : AppColors.borderStrong,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: TeamFlagWidget.flag(
            code,
            width: 22,
            height: 15,
            borderRadius: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFactRichText(String text) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: i.isEven ? AppColors.textSecondary : Colors.white,
          fontWeight: i.isEven ? FontWeight.normal : FontWeight.bold,
          fontSize: 13,
          height: 1.45,
          fontStyle: i.isEven ? FontStyle.italic : FontStyle.normal,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

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

  void _startCountdown() {
    final now = DateTime.now();
    final difference = _matchState.date.difference(now);
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
    return TeamFlagWidget.flag(
      code,
      width: size * 1.4,
      height: size,
      borderRadius: 10,
      boxShadowOpacity: 0.3,
    );
  }

  Widget _buildCountdownWidget() {
    final now = DateTime.now();
    final difference = _matchState.date.difference(now);
    if (difference.isNegative) {
      return const SizedBox.shrink();
    }
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
    final cleanT1 = _isPlaceholder(_matchState.t1) ? 'TBD' : _matchState.t1.replaceFirst('g_', '').toUpperCase();
    final cleanT2 = _isPlaceholder(_matchState.t2) ? 'TBD' : _matchState.t2.replaceFirst('g_', '').toUpperCase();

    final matchOdds = WCOddsService.calculateMatchOdds(_matchState.t1, _matchState.t2, widget.allMatches);

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
                AppTranslations.get(widget.lang, 'matchOddsTitle').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => _showInfoDialog(
                  AppTranslations.get(widget.lang, 'matchOddsTitle'),
                  AppTranslations.get(widget.lang, 'matchOddsExpl'),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildOddBox(cleanT1, matchOdds['1']!, AppColors.accent),
              const SizedBox(width: 12),
              _buildOddBox(AppTranslations.get(widget.lang, 'drawLabel').toUpperCase(), matchOdds['X']!, AppColors.textMuted),
              const SizedBox(width: 12),
              _buildOddBox(cleanT2, matchOdds['2']!, AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOddBox(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionControlCard() {
    final bool isLocked = PredictionService.isPredictionLocked(widget.match);

    if (isLocked) {
      String predText = widget.prediction != null
          ? 'Prono : ${widget.prediction!.t1Score} - ${widget.prediction!.t2Score}'
          : AppTranslations.get(widget.lang, 'noPrediction');

      if (widget.prediction != null) {
        if (widget.prediction!.penaltyWinner != null) {
          predText += ' (PK)';
        } else if (widget.prediction!.extraTimeWinner != null) {
          predText += ' (ET)';
        }
      }

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
          child: Column(
            children: [
              Row(
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
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.prediction != null
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  predText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.prediction != null ? AppColors.accent : AppColors.textDim,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontStyle: widget.prediction == null ? FontStyle.italic : null,
                  ),
                ),
              ),
              _buildBoosterSection(),
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
              _initLocalScores();
            });
          },
        ),
      );
    }

    final errorMsg = _validatePredictionLogic();

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
                  widget.onPredictionChanged?.call(0, 0, null, null, null);
                },
                child: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreAdjuster(_localT1Score!, (val) => setState(() {
                _localT1Score = val;
                if (_localT1Score != _localT2Score) {
                  _localEtWinner = null;
                  _localPkWinner = null;
                }
              }), true),
              const Text(
                '-',
                style: TextStyle(color: AppColors.borderStrong, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              _buildScoreAdjuster(_localT2Score!, (val) => setState(() {
                _localT2Score = val;
                if (_localT1Score != _localT2Score) {
                  _localEtWinner = null;
                  _localPkWinner = null;
                }
              }), false),
            ],
          ),
          const SizedBox(height: 20),
          _buildScorerPredictionSection(),
          if (_matchState.isKnockout && _localT1Score == _localT2Score) ...[
            const SizedBox(height: 20),
            _buildKnockoutPredictionControls(),
          ],
          const SizedBox(height: 20),
          _buildBoosterSection(),
          if (_scorerWarning() != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scorerWarning()!,
                      style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveLocalPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                AppTranslations.get(widget.lang, widget.prediction != null ? 'updatePrediction' : 'predictButton').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _scorerWarning() {
    if (_localPredictedScorers.isEmpty) return null;
    final t1En = AppTranslations.getTeam('en', _matchState.t1);
    final t2En = AppTranslations.getTeam('en', _matchState.t2);

    int t1ScorerGoals = 0;
    int t2ScorerGoals = 0;

    for (final entry in _localPredictedScorers.entries) {
      final team = PlayerDatabaseService.getTeamForPlayer(entry.key);
      if (team == t1En) {
        t1ScorerGoals += entry.value;
      } else if (team == t2En) {
        t2ScorerGoals += entry.value;
      }
    }

    final expectedT1 = _localT1Score ?? 0;
    final expectedT2 = _localT2Score ?? 0;

    if (t1ScorerGoals > expectedT1) {
      final teamName = AppTranslations.getTeam(widget.lang, _matchState.t1);
      if (widget.lang == 'fr') return '⚠️ Buteurs $teamName : $t1ScorerGoals buts saisis > $expectedT1 prédit';
      if (widget.lang == 'es') return '⚠️ Goleadores $teamName : $t1ScorerGoals > $expectedT1 previsto';
      return '⚠️ $teamName scorers: $t1ScorerGoals goals entered > $expectedT1 predicted';
    }
    if (t2ScorerGoals > expectedT2) {
      final teamName = AppTranslations.getTeam(widget.lang, _matchState.t2);
      if (widget.lang == 'fr') return '⚠️ Buteurs $teamName : $t2ScorerGoals buts saisis > $expectedT2 prédit';
      if (widget.lang == 'es') return '⚠️ Goleadores $teamName : $t2ScorerGoals > $expectedT2 previsto';
      return '⚠️ $teamName scorers: $t2ScorerGoals goals entered > $expectedT2 predicted';
    }
    return null;
  }

  String? _validatePredictionLogic() => null;

  void _onPredictionChanged() {
    if (_localT1Score != _localT2Score) {
      _localEtWinner = null;
      _localPkWinner = null;
    }
    if (widget.onPredictionChanged != null) {
      widget.onPredictionChanged!(
        _localT1Score ?? 0,
        _localT2Score ?? 0,
        _localEtWinner,
        _localPkWinner,
        _localPredictedScorers,
      );
    }
  }

  void _saveLocalPrediction() async {
    final error = _validatePredictionLogic();
    if (error != null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            error,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    if (widget.onPredictionChanged != null) {
      widget.onPredictionChanged!(
        _localT1Score ?? 0,
        _localT2Score ?? 0,
        _localEtWinner,
        _localPkWinner,
        _localPredictedScorers,
      );
    }

    if (widget.onBoosterChanged != null) {
      widget.onBoosterChanged!(_localBoosterActive);
    }

    if (mounted) {
      setState(() => _isEditing = false);
      Navigator.pop(context);
    }
  }

  Widget _buildBoosterSection() {
    final bool isLocked = PredictionService.isPredictionLocked(widget.match);
    if (isLocked) {
      if (!_localBoosterActive) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              AppTranslations.get(widget.lang, 'boosterLabel').toUpperCase(),
              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
            ),
          ],
        ),
      );
    }

    final String phase = PredictionService.getMatchPhase(widget.match);
    final int limit = PredictionService.getAvailableBoostersForPhase(phase);
    
    // Count how many boosters are used in this phase by looking up the matches
    int boostersUsedInPhase = 0;
    for (String id in widget.boosterMatchIds) {
      final m = widget.allMatches.firstWhere((element) => element.id == id, orElse: () => widget.allMatches.first);
      if (PredictionService.getMatchPhase(m) == phase) {
        boostersUsedInPhase++;
      }
    }
    
    final bool canAddBooster = _localBoosterActive || boostersUsedInPhase < limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.get(widget.lang, 'boosterLabel').toUpperCase(),
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                ),
              ],
            ),
            Switch(
              value: _localBoosterActive,
              activeColor: AppColors.warning,
              onChanged: (val) {
                if (val && !canAddBooster) {
                  _showInfoDialog(
                    AppTranslations.get(widget.lang, 'boosterLabel'),
                    widget.lang == 'fr' 
                      ? "Vous avez atteint la limite de Jokers ($limit) pour cette phase ! Désactivez-en un d'abord." 
                      : (widget.lang == 'es' ? "¡Has alcanzado el límite de comodines ($limit) para esta fase! Desactiva uno primero." : "You have reached the booster limit ($limit) for this phase! Disable one first."),
                  );
                  return;
                }
                HapticFeedback.selectionClick();
                setState(() {
                  _localBoosterActive = val;
                });
              },
            ),
          ],
        ),
        if (canAddBooster)
          Text(
            widget.lang == 'fr' 
                ? "Joker (x2 sur Score Exact, x1.5 sur Bon Résultat). Sans malus en cas d'erreur ! Limite : $limit par phase."
                : (widget.lang == 'es' ? "Comodín (x2 en Resultado Exacto, x1.5 en Resultado Correcto). ¡Sin penalización! Límite: $limit." : "Booster (x2 on Exact Score, x1.5 on Correct Outcome). No penalty! Limit: $limit."),
            style: const TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.4),
          )
        else
          Text(
            widget.lang == 'fr' 
                ? "Limite de Jokers atteinte pour cette phase ($limit)."
                : (widget.lang == 'es' ? "Límite de comodines alcanzado para esta fase ($limit)." : "Booster limit reached for this phase ($limit)."),
            style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
          ),
      ],
    );
  }

  Widget _buildScorerPredictionSection() {
    final bool isLocked = PredictionService.isPredictionLocked(widget.match);
    final t1En = AppTranslations.getTeam('en', _matchState.t1);
    final t2En = AppTranslations.getTeam('en', _matchState.t2);
    final squad = [
      ...PlayerDatabaseService.getPlayersForTeam(t1En),
      ...PlayerDatabaseService.getPlayersForTeam(t2En)
    ]..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.get(widget.lang, 'scorerPrediction').toUpperCase(),
              style: const TextStyle(
                color: AppColors.textDim,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.lang == 'fr' ? 'OPTIONNEL' : (widget.lang == 'es' ? 'OPCIONAL' : 'OPTIONAL'),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.lang == 'fr'
              ? 'Bonus Buteur : Att: 30, Mil: 60, Def: 120 pts'
              : (widget.lang == 'es'
              ? 'Bono Goleador: Del: 30, Med: 60, Def: 120 pts'
              : 'Scorer Bonus: Fwd: 30, Mid: 60, Def: 120 pts'),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
        if (isLocked)
          Column(
            children: _localPredictedScorers.entries.map((e) => _buildScorerResultBadge(e.key, e.value)).toList(),
          )
        else
          Column(
            children: [
              ..._localPredictedScorers.entries.map((entry) => _buildScorerInputRow(entry.key, entry.value)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showScorerPicker(squad),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(AppTranslations.get(widget.lang, 'selectScorer')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildScorerInputRow(String playerName, int goalCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.textDim),
            onPressed: () => setState(() {
              if (goalCount > 1) {
                _localPredictedScorers[playerName] = goalCount - 1;
              } else {
                _localPredictedScorers.remove(playerName);
              }
              _onPredictionChanged();
            }),
          ),
          Text('$goalCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            onPressed: () => setState(() {
              _localPredictedScorers[playerName] = goalCount + 1;
              _onPredictionChanged();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => setState(() {
              _localPredictedScorers.remove(playerName);
              _onPredictionChanged();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScorerResultBadge(String playerName, int predictedCount) {
    final actualCount = _matchState.goals.where((g) => PredictionService.isSamePlayer(g.scorer, playerName)).length;
    final bool hasScored = actualCount > 0;
    
    int points = 0;
    if (hasScored) {
       final goalEvent = _matchState.goals.firstWhere((g) => PredictionService.isSamePlayer(g.scorer, playerName));
       final teamStr = goalEvent.team == 't1' ? _matchState.t1 : _matchState.t2;
       final position = PlayerDatabaseService.getPlayerPosition(AppTranslations.getTeam('en', teamStr), playerName);
       
       int ptsPerGoal = kScorerBonusMidfielder;
       if (position == 'Forwards') { ptsPerGoal = kScorerBonusForward; }
       else if (position == 'Defenders' || position == 'Goalkeepers') { ptsPerGoal = kScorerBonusDefenderOrGK; }
       
       points = ptsPerGoal;
       if (actualCount == predictedCount) { points += kScorerExactCountBonus; }
    }

    final color = hasScored ? AppColors.accent : AppColors.danger;
    final icon = hasScored ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final text = hasScored ? '$actualCount goals (+ $points pts)' : AppTranslations.get(widget.lang, 'wrongScorer');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showScorerPicker(List<String> squad) {
    final t1En = AppTranslations.getTeam('en', _matchState.t1);
    final t2En = AppTranslations.getTeam('en', _matchState.t2);
    final s1 = PlayerDatabaseService.getPlayersForTeam(t1En)..sort();
    final s2 = PlayerDatabaseService.getPlayersForTeam(t2En)..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        String searchQuery = '';
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: DefaultTabController(
            length: 2,
            child: StatefulBuilder(
              builder: (context, setPickerState) {
                final f1 = s1.where((p) => p.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                final f2 = s2.where((p) => p.toLowerCase().contains(searchQuery.toLowerCase())).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: false,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: AppTranslations.get(widget.lang, 'searchPlayer'),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textDim),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => setPickerState(() => searchQuery = val),
                      ),
                    ),
                    TabBar(
                      indicatorColor: AppColors.accent,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textDim,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TeamFlagWidget.flag(_matchState.t1, width: 20, height: 14),
                              const SizedBox(width: 8),
                              Flexible(child: Text(AppTranslations.getTeam(widget.lang, _matchState.t1), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TeamFlagWidget.flag(_matchState.t2, width: 20, height: 14),
                              const SizedBox(width: 8),
                              Flexible(child: Text(AppTranslations.getTeam(widget.lang, _matchState.t2), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildScorerList(f1, _matchState.t1, setPickerState),
                          _buildScorerList(f2, _matchState.t2, setPickerState),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static const Map<String, Color> _positionColors = {
    'Goalkeepers': Color(0xFFFFC107),
    'Defenders':   Color(0xFF4CAF50),
    'Midfielders': Color(0xFF2196F3),
    'Forwards':    Color(0xFFF44336),
  };
  static const Map<String, String> _positionAbbr = {
    'Goalkeepers': 'GK',
    'Defenders':   'DEF',
    'Midfielders': 'MID',
    'Forwards':    'FWD',
  };

  Widget _buildScorerList(List<String> players, String teamCode, StateSetter setPickerState) {
    if (players.isEmpty) {
      return Center(child: Text(AppTranslations.get(widget.lang, 'scorerNotFound'), style: const TextStyle(color: AppColors.textDim)));
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        final isSelected = _localPredictedScorers.containsKey(p);

        final dbTeam = PlayerDatabaseService.getTeamForPlayer(p);
        final position = dbTeam != null ? PlayerDatabaseService.getPlayerPosition(dbTeam, p) : null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // 1. Le drapeau placé en premier
          leading: TeamFlagWidget.flag(teamCode, width: 28, height: 20, borderRadius: 2),
          title: Row(
            children: [
              // 2. Le nom du joueur
              Flexible(
                child: Text(
                  p,
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 3. Le tag de position stylisé comme dans stats_view.dart
              if (position != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
            ],
          ),
          trailing: isSelected
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                Text('${_localPredictedScorers[p]}g', style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
              : null,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _localPredictedScorers[p] = (_localPredictedScorers[p] ?? 0) + 1);
            setPickerState(() {});
            _onPredictionChanged();
          },
        );
      },
    );
  }

  Widget _buildScoreAdjuster(int score, Function(int) onChanged, bool isT1, {bool small = false}) {
    return Row(
      children: [
        IconButton(
          onPressed: score > 0
              ? () {
            HapticFeedback.selectionClick();
            onChanged(score - 1);
          }
              : null,
          icon: Icon(Icons.remove_circle_outline, color: AppColors.textDim, size: small ? 24 : 30),
        ),
        const SizedBox(width: 4),
        Text(
          '$score',
          style: TextStyle(color: Colors.white, fontSize: small ? 22 : 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: score < 9
              ? () {
            HapticFeedback.selectionClick();
            onChanged(score + 1);
          }
              : null,
          icon: Icon(Icons.add_circle_outline, color: isT1 ? AppColors.accent : AppColors.info, size: small ? 24 : 30),
        ),
      ],
    );
  }

  Widget _buildKnockoutPredictionControls() {
    return Column(
      children: [
        const Divider(color: AppColors.border, height: 32),
        Text(
          AppTranslations.get(widget.lang, 'whoQualifies').toUpperCase(),
          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildWinnerChip(_matchState.t1, AppTranslations.getTeam(widget.lang, _matchState.t1)),
            const SizedBox(width: 12),
            _buildWinnerChip(_matchState.t2, AppTranslations.getTeam(widget.lang, _matchState.t2)),
          ],
        ),
        if (_localEtWinner != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppTranslations.get(widget.lang, 'viaPenalties'),
                style: const TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _localPkWinner != null,
                activeThumbColor: AppColors.accent,
                onChanged: (val) {
                  setState(() {
                    _localPkWinner = val ? (_localEtWinner == _matchState.t1) : null;
                  });
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWinnerChip(String teamCode, String teamName) {
    final isSelected = _localEtWinner == teamCode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _localEtWinner = isSelected ? null : teamCode;
            if (_localEtWinner == null) _localPkWinner = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
          ),
          child: Column(
            children: [
              TeamFlagWidget.flag(teamCode, width: 24, height: 16, borderRadius: 2),
              const SizedBox(height: 4),
              Text(
                teamName,
                style: TextStyle(color: isSelected ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartAlerts(BuildContext context) {
    final now = DateTime.now();

    final oneDayAlertDate = _matchState.date.subtract(const Duration(days: 1));
    final oneHourAlertDate = _matchState.date.subtract(const Duration(hours: 1));
    final thirtyMinAlertDate = _matchState.date.subtract(const Duration(minutes: 30));

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
    if (_isPlaceholder(teamCode)) return const SizedBox.shrink();

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
      onTap: () => WCTeamProfileDialog.show(context, teamCode, widget.lang, widget.allMatches),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
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

  Widget _buildScoreBreakdown() {
    final has90 = _matchState.t1Score90 != null;
    final hasPK = _matchState.t1ScorePK != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.get(widget.lang, 'matchFlow').toUpperCase(),
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (has90) ...[
            _buildBreakdownRow('90 min', _matchState.t1Score90, _matchState.t2Score90),
          ],
          if (_matchState.wentToET == true) ...[
            if (has90) const Divider(color: AppColors.border, height: 16),
            _buildBreakdownRow(AppTranslations.get(widget.lang, 'extraTimeLabel'), _matchState.t1ScoreET ?? _matchState.t1Score, _matchState.t2ScoreET ?? _matchState.t2Score),
          ],
          if (_matchState.wentToPK == true) ...[
            const Divider(color: AppColors.border, height: 16),
            if (hasPK)
              _buildBreakdownRow(AppTranslations.get(widget.lang, 'penaltiesLabel'), _matchState.t1ScorePK, _matchState.t2ScorePK, isAccent: true)
            else if (_matchState.pkWinner != null)
              _buildWinnerRow(AppTranslations.get(widget.lang, 'penaltiesLabel'), _matchState.pkWinner!, isAccent: true),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int? s1, int? s2, {bool isAccent = false}) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              color: isAccent ? AppColors.accent : AppColors.textDim,
              fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        _buildMiniFlag(_matchState.t1),
        const SizedBox(width: 8),
        Text(
          s1 != null && s2 != null ? '$s1 - $s2' : '-',
          style: TextStyle(
            color: isAccent ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        _buildMiniFlag(_matchState.t2),
      ],
    );
  }

  Widget _buildWinnerRow(String label, String winnerCode, {bool isAccent = false}) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              color: isAccent ? AppColors.accent : AppColors.textDim,
              fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        Text(
          AppTranslations.get(widget.lang, 'winner').toUpperCase(),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        _buildMiniFlag(winnerCode),
        const SizedBox(width: 6),
        Text(
          AppTranslations.getTeam(widget.lang, winnerCode),
          style: TextStyle(
            color: isAccent ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFlag(String code) {
    return TeamFlagWidget.flag(code, width: 20, height: 14, borderRadius: 4);
  }

  @override
  Widget build(BuildContext context) {
    final t1EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, _matchState.t1);
    final t2EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, _matchState.t2);
    final localizedDateTimeStr = DateFormat.yMMMMEEEEd(widget.lang).add_Hm().format(_matchState.date);

    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderMid,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Positioned(
                right: 48,
                top: 12,
                child: _matchState.isLive ? const _LivePulseBadge() : const SizedBox.shrink(),
              ),
              Positioned(
                right: 8,
                top: 0,
                child: IconButton(
                  icon: _isRefreshing 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.accent)))
                    : const Icon(Icons.refresh_rounded, color: AppColors.textDim, size: 20),
                  onPressed: _refreshMatchData,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildTeamDetailSection(_matchState.t1, t1EmblemName)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _matchState.isPlayed
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_matchState.t1Score ?? '-'} - ${_matchState.t2Score ?? '-'}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                      if (_matchState.wentToPK == true && _matchState.t1ScorePK != null)
                        Text(
                          '(${_matchState.t1ScorePK} - ${_matchState.t2ScorePK} ${AppTranslations.get(widget.lang, 'penaltiesLabel')})',
                          style: TextStyle(
                            color: AppColors.accent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      else if (_matchState.wentToET == true)
                        Text(
                          '(${AppTranslations.get(widget.lang, 'extraTimeLabel')})',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
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
                Expanded(child: _buildTeamDetailSection(_matchState.t2, t2EmblemName)),
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
          _buildFunFactChip(),
          const SizedBox(height: 4),
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
                  if (_matchState.isPlayed && _matchState.isKnockout && (_matchState.wentToET == true || _matchState.wentToPK == true)) ...[
                    _buildScoreBreakdown(),
                    const SizedBox(height: 20),
                  ],
                  _buildProbabilityBar(context),
                  const SizedBox(height: 20),
                  if (_matchState.isPlayed && _matchState.goals.isNotEmpty) ...[
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
                            children: _matchState.goals.map((g) {
                              final isT1Goal = g.team == 't1';
                              final assistText = g.assistant != null ? '\n(ass: ${g.assistant})' : '';
                              final ogText = g.isOwnGoal ? ' (${AppTranslations.get(widget.lang, 'ownGoal')})' : '';
                              
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
                                              g.scorer + ogText + assistText,
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: g.isOwnGoal ? AppColors.danger : AppColors.textPrimary,
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
                                              g.scorer + ogText + assistText,
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                color: g.isOwnGoal ? AppColors.danger : AppColors.textPrimary,
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
                  if (_matchState.isPlayed && _matchState.stats != null) ...[
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
                            val1: _matchState.stats!.possessionT1,
                            val2: _matchState.stats!.possessionT2,
                            suffix: '%',
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'shots'),
                            val1: _matchState.stats!.shotsT1,
                            val2: _matchState.stats!.shotsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'shotsOnTarget'),
                            val1: _matchState.stats!.shotsOnTargetT1,
                            val2: _matchState.stats!.shotsOnTargetT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'fouls'),
                            val1: _matchState.stats!.foulsT1,
                            val2: _matchState.stats!.foulsT2,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'yellowCards'),
                            val1: _matchState.stats!.yellowCardsT1,
                            val2: _matchState.stats!.yellowCardsT2,
                            colorT1: AppColors.warningYellow,
                            colorT2: AppColors.warningYellow,
                          ),
                          _buildStatBar(
                            label: AppTranslations.get(widget.lang, 'redCards'),
                            val1: _matchState.stats!.redCardsT1,
                            val2: _matchState.stats!.redCardsT2,
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
                  const SizedBox(height: 48),
                  ],
                  ),
                  ),
                  ),
                  ],
                  ),
                  );
                  }
                  }

                  class _LivePulseBadge extends StatefulWidget {
                  const _LivePulseBadge();

                  @override
                  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
                  }

                  class _LivePulseBadgeState extends State<_LivePulseBadge> with SingleTickerProviderStateMixin {
                  late AnimationController _controller;
                  late Animation<double> _animation;

                  @override
                  void initState() {
                  super.initState();
                  _controller = AnimationController(
                  duration: const Duration(milliseconds: 1000),
                  vsync: this,
                  )..repeat(reverse: true);
                  _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
                  }

                  @override
                  void dispose() {
                  _controller.dispose();
                  super.dispose();
                  }

                  @override
                  Widget build(BuildContext context) {
                  return FadeTransition(
                  opacity: _animation,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                  'LIVE',
                  style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  ),
                  ),
                  ),
                  );
                  }
                  }