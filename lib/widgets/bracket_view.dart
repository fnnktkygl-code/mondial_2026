import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../theme/team_colors.dart';
import '../services/prediction_service.dart';
import 'team_flag.dart';
import 'wc_tooltip.dart';

class BracketViewWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final Function(WorldCupMatch match) onMatchTap;
  final String? supportedTeamCode;
  final Map<String, MatchPrediction>? predictions;

  static final Map<String, int> _idCache = {};
  static final RegExp _digitRegex = RegExp(r'\d+');

  const BracketViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.onMatchTap,
    this.supportedTeamCode,
    this.predictions,
  });

  static int _getParsedId(String id) {
    return _idCache.putIfAbsent(id, () {
      return int.tryParse(_digitRegex.firstMatch(id)?.group(0) ?? '0') ?? 0;
    });
  }

  @override
  State<BracketViewWidget> createState() => _BracketViewWidgetState();
}

class _BracketViewWidgetState extends State<BracketViewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  Timer? _liveCheckTimer;

  bool get _hasLiveMatch {
    final now = DateTime.now();
    return widget.matches.any((m) {
      final localDate = m.date.toLocal();
      return !m.isPlayed &&
          now.isAfter(localDate) &&
          now.isBefore(localDate.add(const Duration(minutes: 105)));
    });
  }

  bool get _hasChampion {
    try {
      final fMatch = widget.matches.firstWhere((m) => m.stage == 'Final');
      return fMatch.isPlayed;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_hasLiveMatch || _hasChampion) _pulseController.repeat(reverse: true);

    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    if (_hasChampion) {
      _confettiController.play();
    }

    _liveCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      if ((_hasLiveMatch || _hasChampion) && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!(_hasLiveMatch || _hasChampion) && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _liveCheckTimer?.cancel();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  bool _isLive(WorldCupMatch m) {
    final now = DateTime.now();
    final localDate = m.date.toLocal();
    return !m.isPlayed &&
        now.isAfter(localDate) &&
        now.isBefore(localDate.add(const Duration(minutes: 105)));
  }

  bool _isPlaceholder(String code) {
    return (code.length > 2 && code.toLowerCase() != 'sco') ||
        code.toLowerCase() == 'tbd' ||
        code.contains(RegExp(r'\d'));
  }

  Set<String> _getFinalists() {
    final finalists = <String>{};
    try {
      final fMatch = widget.matches.firstWhere((m) => m.stage == 'Final');
      if (fMatch.t1.isNotEmpty && !_isPlaceholder(fMatch.t1)) finalists.add(fMatch.t1);
      if (fMatch.t2.isNotEmpty && !_isPlaceholder(fMatch.t2)) finalists.add(fMatch.t2);
    } catch (_) {}
    return finalists;
  }

  bool _shouldHighlightConnector(WorldCupMatch m) {
    if (!m.isPlayed) return false;
    final finalists = _getFinalists();
    return finalists.contains(m.getWinner());
  }

  static int _getParsedId(String id) => BracketViewWidget._getParsedId(id);

  List<WorldCupMatch> _getMatchesForStage(String stageName) =>
      widget.matches.where((m) => m.stage == stageName).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  String _getFlagCdnUrl(String code) {
    String c = code.toLowerCase().replaceAll('g_', '');

    final Map<String, String> fifaToIsoMap = {
      'fra': 'fr', 'sen': 'sn', 'mar': 'ma', 'arg': 'ar', 'bra': 'br',
      'esp': 'es', 'ger': 'de', 'ita': 'it', 'por': 'pt', 'usa': 'us',
      'mex': 'mx', 'can': 'ca', 'bel': 'be', 'cro': 'hr', 'ned': 'nl',
      'jpn': 'jp', 'eng': 'gb-eng', 'sco': 'gb-sct', 'wal': 'gb-wls',
      'en': 'gb-eng', 'wa': 'gb-wls'
    };

    if (fifaToIsoMap.containsKey(c)) {
      c = fifaToIsoMap[c]!;
    }

    if (c == 'gb-eng') return 'https://flagcdn.com/w1280/gb-eng.png';
    if (c == 'gb-sct') return 'https://flagcdn.com/w1280/gb-sct.png';
    if (c == 'gb-wls') return 'https://flagcdn.com/w1280/gb-wls.png';
    return 'https://flagcdn.com/w1280/$c.png';
  }

  List<Color> _getConfettiColors(String teamCode) {
    final code = teamCode.toUpperCase();
    switch (code) {
      case 'SEN':
        return [Colors.green, Colors.yellow, Colors.red];
      case 'FRA':
        return [Colors.blue, Colors.white, Colors.red];
      case 'MAR':
        return [Colors.red, Colors.green];
      case 'ARG':
        return [Colors.blue[300]!, Colors.white, Colors.amber];
      case 'BRA':
        return [Colors.yellow, Colors.green, Colors.blue];
      case 'ESP':
        return [Colors.red, Colors.yellow];
      case 'GER':
        return [Colors.black, Colors.red, Colors.yellow];
      case 'ITA':
        return [Colors.green, Colors.white, Colors.red];
      case 'ENG':
        return [Colors.white, Colors.red];
      case 'POR':
        return [Colors.green, Colors.red, Colors.yellow];
      case 'USA':
        return [Colors.blue[900]!, Colors.white, Colors.red];
      case 'MEX':
        return [Colors.green[800]!, Colors.white, Colors.red[800]!];
      case 'CAN':
        return [Colors.red, Colors.white];
      case 'BEL':
        return [Colors.black, Colors.yellow, Colors.red];
      case 'CRO':
        return [Colors.red, Colors.white, Colors.blue];
      case 'NED':
        return [Colors.orange, Colors.white, Colors.blue];
      case 'JPN':
        return [Colors.white, Colors.red];
      default:
        try {
          final colors = TeamColors.getColors(teamCode);
          if (colors.isNotEmpty) return colors;
        } catch (_) {}
        return [Colors.amber, Colors.white];
    }
  }

  Widget _buildProgressBar() {
    final stages = [
      ('r32', 'Round of 32', 16),
      ('r16', 'Round of 16', 8),
      ('qf', 'Quarter-Final', 4),
      ('sf', 'Semi-Final', 2),
      ('f', 'Final', 1),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: stages.map((s) {
          final (key, stageName, total) = s;
          final stageMatches = _getMatchesForStage(stageName);
          final played = stageMatches.where((m) => m.isPlayed).length;
          final hasLive = stageMatches.any(_isLive);
          final progress = total == 0 ? 0.0 : played / total;
          final isDone = played == total && total > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasLive)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.warning.withValues(
                                    alpha: _pulseAnimation.value),
                              ),
                            ),
                          ),
                        Text(
                          AppTranslations.get(widget.lang, key).toUpperCase(),
                          style: TextStyle(
                            color: isDone
                                ? AppColors.warning
                                : hasLive
                                ? AppColors.warning
                                : AppColors.textDim,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? AppColors.warning : hasLive
                            ? AppColors.warning.withValues(alpha: 0.7)
                            : AppColors.borderStrong,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stageMatches.isEmpty
                        ? '-'
                        : '$played/$total',
                    style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 8,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r32Matches = _getMatchesForStage('Round of 32');
    final r16Matches = _getMatchesForStage('Round of 16');
    final qfMatches = _getMatchesForStage('Quarter-Final');
    final sfMatches = _getMatchesForStage('Semi-Final');
    final fMatches = _getMatchesForStage('Final');

    final champion = fMatches.isNotEmpty && fMatches[0].isPlayed ? fMatches[0].getWinner() : null;
    final confettiColors = champion != null ? _getConfettiColors(champion) : [Colors.amber];

    final leftR32 = r32Matches.where((m) => _getParsedId(m.id) >= 49 && _getParsedId(m.id) <= 56).toList()..sort((a, b) => a.id.compareTo(b.id));
    final rightR32 = r32Matches.where((m) => _getParsedId(m.id) >= 57 && _getParsedId(m.id) <= 64).toList()..sort((a, b) => a.id.compareTo(b.id));
    final leftR16 = r16Matches.where((m) => _getParsedId(m.id) >= 65 && _getParsedId(m.id) <= 68).toList()..sort((a, b) => a.id.compareTo(b.id));
    final rightR16 = r16Matches.where((m) => _getParsedId(m.id) >= 69 && _getParsedId(m.id) <= 72).toList()..sort((a, b) => a.id.compareTo(b.id));
    final leftQF = qfMatches.where((m) => _getParsedId(m.id) >= 73 && _getParsedId(m.id) <= 74).toList()..sort((a, b) => a.id.compareTo(b.id));
    final rightQF = qfMatches.where((m) => _getParsedId(m.id) >= 75 && _getParsedId(m.id) <= 76).toList()..sort((a, b) => a.id.compareTo(b.id));
    final leftSF = sfMatches.where((m) => m.id == 'm77').toList();
    final rightSF = sfMatches.where((m) => m.id == 'm78').toList();

    const double cardHeight = 96.0;
    const double r32BlockHeight = 120.0;

    return Stack(
      children: [
        // Arrière-plan : Image du vrai drapeau national officiel plus visible
        if (champion != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.28,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black38,
                      Colors.black,
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.network(
                  _getFlagCdnUrl(champion),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(40.0),
                minScale: 0.2,
                maxScale: 1.5,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'r32'), matches: leftR32, blockHeight: r32BlockHeight, cardHeight: cardHeight),
                      _buildColumnConnector(leftR32, r32BlockHeight, isLeftHandSide: true),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'r16'), matches: leftR16, blockHeight: r32BlockHeight * 2, cardHeight: cardHeight),
                      _buildColumnConnector(leftR16, r32BlockHeight * 2, isLeftHandSide: true),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'qf'), matches: leftQF, blockHeight: r32BlockHeight * 4, cardHeight: cardHeight),
                      _buildColumnConnector(leftQF, r32BlockHeight * 4, isLeftHandSide: true),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'sf'), matches: leftSF, blockHeight: r32BlockHeight * 8, cardHeight: cardHeight),
                      _buildStraightConnector(leftSF.isNotEmpty ? leftSF[0] : null, r32BlockHeight * 4),
                      _buildCenterColumn(finalTitle: AppTranslations.get(widget.lang, 'f'), finalMatch: fMatches.isNotEmpty ? fMatches[0] : null, blockHeight: r32BlockHeight * 8, cardHeight: cardHeight),
                      _buildStraightConnector(rightSF.isNotEmpty ? rightSF[0] : null, r32BlockHeight * 4),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'sf'), matches: rightSF, blockHeight: r32BlockHeight * 8, cardHeight: cardHeight),
                      _buildColumnConnector(rightQF, r32BlockHeight * 4, isLeftHandSide: false),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'qf'), matches: rightQF, blockHeight: r32BlockHeight * 4, cardHeight: cardHeight),
                      _buildColumnConnector(rightR16, r32BlockHeight * 2, isLeftHandSide: false),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'r16'), matches: rightR16, blockHeight: r32BlockHeight * 2, cardHeight: cardHeight),
                      _buildColumnConnector(rightR32, r32BlockHeight, isLeftHandSide: false),
                      _buildBracketColumn(title: AppTranslations.get(widget.lang, 'r32'), matches: rightR32, blockHeight: r32BlockHeight, cardHeight: cardHeight),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (champion != null)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
              colors: confettiColors,
              numberOfParticles: 25,
              gravity: 0.15,
            ),
          ),
      ],
    );
  }

  Widget _buildBracketColumn({required String title, required List<WorldCupMatch> matches, required double blockHeight, required double cardHeight}) {
    return SizedBox(width: 170, child: Column(children: [
      const SizedBox(height: 30),
      ...matches.map((m) => SizedBox(height: blockHeight, child: Center(child: _buildBracketCard(m, cardHeight)))),
    ]));
  }

  Widget _buildCenterColumn({required String finalTitle, required WorldCupMatch? finalMatch, required double blockHeight, required double cardHeight}) {
    final champion = finalMatch != null && finalMatch.isPlayed ? finalMatch.getWinner() : null;

    return SizedBox(width: 170, child: Column(children: [
      const SizedBox(height: 30),
      SizedBox(height: blockHeight, child: Stack(clipBehavior: Clip.none, children: [
        if (champion != null)
          Positioned(
            top: (blockHeight / 2) - (cardHeight / 2) - 15,
            left: 85 - 0.75,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, val, _) => Container(
                width: 1.5,
                height: 15,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: val),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.3 * val),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (champion != null)
          Positioned(
            bottom: (blockHeight / 2) + (cardHeight / 2) + 15,
            left: -60,
            right: -60,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) => Stack(
                          alignment: Alignment.center,
                          children: List.generate(6, (i) {
                            final angle = (i * 60) * math.pi / 180;
                            final pulse = _pulseAnimation.value;
                            final radius = 45 + (pulse * 15);
                            return Transform.translate(
                              offset: Offset(
                                math.cos(angle + pulse) * radius,
                                math.sin(angle + pulse) * radius,
                              ),
                              child: Opacity(
                                opacity: (1 - pulse).clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: pulse * math.pi,
                                  child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 12),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.warning.withValues(alpha: 0.5 * _pulseAnimation.value),
                                AppColors.warning.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Text('🏆', style: TextStyle(fontSize: 56)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.get(widget.lang, 'champion').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final pulse = _pulseAnimation.value;
                      final double t = (pulse - 0.3) / 0.7;
                      final double sweepPos = -0.2 + (t * 1.4);

                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: const [AppColors.warning, Colors.white, AppColors.warning],
                          stops: [
                            (sweepPos - 0.2).clamp(0.0, 1.0),
                            sweepPos.clamp(0.0, 1.0),
                            (sweepPos + 0.2).clamp(0.0, 1.0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: child,
                      );
                    },
                    child: Text(
                      AppTranslations.getTeam(widget.lang, champion).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Positioned(bottom: (blockHeight / 2) + (cardHeight / 2) + 10, left: 0, right: 0, child: const Center(child: Text('🏆', style: TextStyle(fontSize: 24)))),

        if (finalMatch != null) Positioned(top: (blockHeight / 2) - (cardHeight / 2), left: 0, right: 0, child: _buildBracketCard(finalMatch, cardHeight)),
      ])),
    ]));
  }

  Widget _buildBracketCard(WorldCupMatch m, double height) {
    final pred = widget.predictions?[m.id];
    final predResult = PredictionService.getPredictionResult(
      m,
      PredictionData(matchPredictions: widget.predictions ?? {}),
    );
    final isCorrect = predResult == 'exact' || predResult == 'winner';
    final isWrong = m.isPlayed && predResult == 'wrong';

    final bool hasPrediction = pred != null;
    final IconData predIcon;
    final Color predColor;
    final String tooltipMsg;

    if (m.isPlayed && hasPrediction) {
      switch (predResult) {
        case 'exact':
          predIcon = Icons.star_rounded;
          predColor = Colors.amber;
          tooltipMsg = AppTranslations.get(widget.lang, 'exactScoreTooltip');
          break;
        case 'winner':
          predIcon = Icons.check_circle_rounded;
          predColor = AppColors.accent;
          tooltipMsg = AppTranslations.get(widget.lang, 'correctWinnerTooltip');
          break;
        default:
          predIcon = Icons.cancel_rounded;
          predColor = AppColors.danger;
          tooltipMsg = AppTranslations.get(widget.lang, 'wrongPredictionTooltip');
      }
    } else if (hasPrediction) {
      predIcon = Icons.check_circle_rounded;
      predColor = AppColors.accent;
      tooltipMsg = AppTranslations.get(widget.lang, 'predictionSavedTooltip');
    } else {
      predIcon = Icons.pending_actions_rounded;
      predColor = AppColors.warning;
      tooltipMsg = AppTranslations.get(widget.lang, 'predictionPendingTooltip');
    }

    int? pointsGained;
    if (m.isPlayed && pred != null) {
      pointsGained = PredictionService.evaluatePoints(m, pred);
    }

    final isT1Winner = m.isWinner(m.t1);
    final isT2Winner = m.isWinner(m.t2);
    final isUserTeam = widget.supportedTeamCode != null &&
        (m.t1.toLowerCase() == widget.supportedTeamCode!.toLowerCase() ||
            m.t2.toLowerCase() == widget.supportedTeamCode!.toLowerCase());
    final live = _isLive(m);

    final isOfficialPath = _shouldHighlightConnector(m);
    final isFinalMatch = m.stage == 'Final';
    final isChampionDecided = isFinalMatch && m.isPlayed;

    final borderColor = live
        ? AppColors.accent
        : isUserTeam
        ? AppColors.info
        : isOfficialPath
        ? AppColors.warning
        : isCorrect
        ? AppColors.accent
        : isWrong
        ? AppColors.danger.withValues(alpha: 0.4)
        : (m.isPlayed ? AppColors.border : AppColors.borderMid);

    final cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 170,
      height: height,
      decoration: BoxDecoration(
        color: isUserTeam ? AppColors.info.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: live ? AppColors.accent.withValues(alpha: _pulseAnimation.value) : borderColor,
          width: (isUserTeam || isCorrect || live || isChampionDecided) ? 2.2 : 1.5,
        ),
        boxShadow: isChampionDecided
            ? [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ]
            : isCorrect
            ? [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildCardContent(m, isT1Winner, isT2Winner, live),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => widget.onMatchTap(m),
          child: live
              ? RepaintBoundary(
            child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => cardWidget
            ),
          )
              : cardWidget,
        ),
        Positioned(
          top: 5,
          right: 5,
          child: WCTooltip(
            message: tooltipMsg,
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(predIcon, color: predColor.withValues(alpha: 0.9), size: 14),
          ),
        ),
        if (pointsGained != null && pointsGained > 0)
          Positioned(
            top: -8,
            left: -8,
            child: WCTooltip(
              message: "+$pointsGained ${AppTranslations.get(widget.lang, 'pts')}",
              triggerMode: TooltipTriggerMode.tap,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.scale(
                  scale: val,
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    '+$pointsGained',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardContent(WorldCupMatch m, bool isT1Winner, bool isT2Winner, bool live) {
    final pred = widget.predictions?[m.id];

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (live)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 2),
          color: AppColors.accent.withValues(alpha: 0.15),
          child: const Center(
            child: Text(
              '⚽ LIVE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      _buildBracketTeamRow(
        code: m.t1,
        score: m.t1Score,
        pkScore: m.t1ScorePK,
        isWinner: isT1Winner,
        isLoser: m.isPlayed && !isT1Winner,
        isET: m.wentToET ?? false,
        isPK: m.wentToPK ?? false,
        predScore: pred?.t1Score,
        predPK: pred?.penaltyWinner == true,
        match: m,
      ),
      Container(height: 1.5, color: AppColors.border),
      _buildBracketTeamRow(
        code: m.t2,
        score: m.t2Score,
        pkScore: m.t2ScorePK,
        isWinner: isT2Winner,
        isLoser: m.isPlayed && !isT2Winner,
        isET: m.wentToET ?? false,
        isPK: m.wentToPK ?? false,
        predScore: pred?.t2Score,
        predPK: pred?.penaltyWinner == false,
        match: m,
      ),
    ]);
  }

  Widget _buildBracketTeamRow({
    required String code,
    required int? score,
    int? pkScore,
    required bool isWinner,
    required bool isLoser,
    required bool isET,
    required bool isPK,
    int? predScore,
    bool? predPK,
    required WorldCupMatch match,
  }) {
    final isPlaceholder = _isPlaceholder(code);
    final isSupported = widget.supportedTeamCode != null &&
        code.toLowerCase() == widget.supportedTeamCode!.toLowerCase();

    final pred = widget.predictions?[match.id];
    bool predictedToWin = false;
    if (pred != null) {
      if (pred.t1Score > pred.t2Score) {
        predictedToWin = (code == match.t1);
      } else if (pred.t1Score < pred.t2Score) {
        predictedToWin = (code == match.t2);
      } else if (pred.penaltyWinner != null) {
        predictedToWin = (pred.penaltyWinner! ? match.t1 : match.t2) == code;
      }
    }

    return Expanded(
      child: Stack(
        children: [
          if (!isPlaceholder)
            Positioned(
              left: 20, top: 0, bottom: 0,
              child: Opacity(
                opacity: 0.04,
                child: Transform.scale(
                  scale: 3.5,
                  alignment: Alignment.centerLeft,
                  child: TeamFlagWidget.flag(code, width: 40, height: 25),
                ),
              ),
            ),
          Container(
            color: isWinner ? AppColors.warning.withValues(alpha: 0.08) : Colors.transparent,
            padding: const EdgeInsets.only(left: 10, right: 28),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildMiniFlag(code),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppTranslations.getTeam(widget.lang, code),
                          style: TextStyle(
                            color: isPlaceholder
                                ? AppColors.textDim
                                : isSupported
                                ? AppColors.info
                                : (isWinner ? Colors.white : isLoser ? AppColors.borderStrong : AppColors.textSecondary),
                            fontWeight: (isWinner || isSupported) ? FontWeight.bold : FontWeight.w500,
                            fontSize: 11,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (predScore != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: predictedToWin
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.textDim.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: predictedToWin
                                  ? AppColors.accent.withValues(alpha: 0.4)
                                  : AppColors.border,
                              width: 0.5
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$predScore',
                              style: TextStyle(
                                  color: predictedToWin ? AppColors.accent : AppColors.textDim,
                                  fontSize: 9,
                                  fontWeight: predictedToWin ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                            if (predPK == true)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Icon(
                                    Icons.star,
                                    color: predictedToWin ? AppColors.accent : AppColors.textDim,
                                    size: 8
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (isPK && pkScore != null)
                      Text(
                        '($pkScore) ',
                        style: TextStyle(
                          color: isWinner ? AppColors.warning.withValues(alpha: 0.7) : AppColors.textMuted.withValues(alpha: 0.5),
                          fontWeight: FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      score != null ? '$score' : '',
                      style: TextStyle(
                        color: isWinner ? AppColors.warning : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (isET && !isPK)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'ET',
                          style: TextStyle(
                            color: AppColors.warning.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFlag(String code) {
    if (_isPlaceholder(code)) {
      String label = '?';
      if (code.startsWith('1') || code.startsWith('2')) label = code.substring(0, 1);
      if (code.startsWith('3rd')) label = '3';
      if (code.startsWith('w')) label = 'W';
      if (code.startsWith('l')) label = 'L';
      return Container(width: 18, height: 12, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(2), border: Border.all(color: AppColors.borderStrong, width: 0.5)), alignment: Alignment.center, child: Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 7, fontWeight: FontWeight.bold)));
    }
    return TeamFlagWidget.flag(code, width: 18, height: 12, borderRadius: 2);
  }

  Widget _buildColumnConnector(List<WorldCupMatch> matches, double blockHeight, {required bool isLeftHandSide}) {
    return Container(
      width: 30,
      height: matches.length * blockHeight,
      margin: const EdgeInsets.only(top: 60),
      child: Stack(
        children: [
          for (int i = 0; i < matches.length; i += 2)
            Positioned(
              top: i * blockHeight,
              left: 0,
              right: 0,
              child: _AnimatedBracketConnector(
                isCorrect1: _shouldHighlightConnector(matches[i]),
                isCorrect2: (i + 1) < matches.length ? _shouldHighlightConnector(matches[i + 1]) : false,
                blockHeight: blockHeight,
                isLeftHandSide: isLeftHandSide,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStraightConnector(WorldCupMatch? match, double yPosition) {
    final isActive = match != null && _shouldHighlightConnector(match);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, val, _) => Container(
        width: 30,
        height: 960.0,
        margin: const EdgeInsets.only(top: 60),
        child: CustomPaint(
          painter: StraightConnectorPainter(yPosition: yPosition, activation: val),
        ),
      ),
    );
  }
}

class _AnimatedBracketConnector extends StatelessWidget {
  final bool isCorrect1;
  final bool isCorrect2;
  final double blockHeight;
  final bool isLeftHandSide;

  const _AnimatedBracketConnector({
    required this.isCorrect1,
    required this.isCorrect2,
    required this.blockHeight,
    required this.isLeftHandSide,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isCorrect1 ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, val1, _) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: isCorrect2 ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, val2, _) => CustomPaint(
          size: Size(30, blockHeight * 2),
          painter: BracketConnectorPainter(
            blockHeight: blockHeight,
            isLeftHandSide: isLeftHandSide,
            val1: val1,
            val2: val2,
          ),
        ),
      ),
    );
  }
}

class BracketConnectorPainter extends CustomPainter {
  final double blockHeight;
  final bool isLeftHandSide;
  final double val1;
  final double val2;

  BracketConnectorPainter({
    required this.blockHeight,
    required this.isLeftHandSide,
    required this.val1,
    required this.val2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double halfBlock = blockHeight / 2;
    final double y1 = halfBlock;
    final double y2 = blockHeight + halfBlock;
    final double yMid = blockHeight;

    final color1 = Color.lerp(AppColors.border, AppColors.warning, val1)!;
    final color2 = Color.lerp(AppColors.border, AppColors.warning, val2)!;

    final p1 = Paint()
      ..color = color1
      ..strokeWidth = 1.5 + (val1 * 0.5)
      ..style = PaintingStyle.stroke;
    final p2 = Paint()
      ..color = color2
      ..strokeWidth = 1.5 + (val2 * 0.5)
      ..style = PaintingStyle.stroke;

    final double midVal = val1 > val2 ? val1 : val2;
    final pMid = Paint()
      ..color = Color.lerp(AppColors.border, AppColors.warning, midVal)!
      ..strokeWidth = 1.5 + (midVal * 0.5)
      ..style = PaintingStyle.stroke;

    if (isLeftHandSide) {
      canvas.drawLine(Offset(0, y1), Offset(size.width / 2, y1), p1);
      canvas.drawLine(Offset(0, y2), Offset(size.width / 2, y2), p2);
      canvas.drawLine(Offset(size.width / 2, y1), Offset(size.width / 2, yMid), p1);
      canvas.drawLine(Offset(size.width / 2, y2), Offset(size.width / 2, yMid), p2);
      canvas.drawLine(Offset(size.width / 2, yMid), Offset(size.width, yMid), pMid);

      if (midVal > 0.5) {
        final glowPaint = Paint()
          ..color = AppColors.warning.withValues(alpha: 0.15 * midVal)
          ..strokeWidth = 3.0 * midVal
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawLine(Offset(size.width / 2, yMid), Offset(size.width, yMid), glowPaint);
      }
    } else {
      canvas.drawLine(Offset(size.width, y1), Offset(size.width / 2, y1), p1);
      canvas.drawLine(Offset(size.width, y2), Offset(size.width / 2, y2), p2);
      canvas.drawLine(Offset(size.width / 2, y1), Offset(size.width / 2, yMid), p1);
      canvas.drawLine(Offset(size.width / 2, y2), Offset(size.width / 2, yMid), p2);
      canvas.drawLine(Offset(size.width / 2, yMid), Offset(0, yMid), pMid);

      if (midVal > 0.5) {
        final glowPaint = Paint()
          ..color = AppColors.warning.withValues(alpha: 0.15 * midVal)
          ..strokeWidth = 3.0 * midVal
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawLine(Offset(size.width / 2, yMid), Offset(0, yMid), glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorPainter oldDelegate) =>
      oldDelegate.val1 != val1 || oldDelegate.val2 != val2;
}

class StraightConnectorPainter extends CustomPainter {
  final double yPosition;
  final double activation;
  StraightConnectorPainter({required this.yPosition, required this.activation});

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(AppColors.border, AppColors.warning, activation)!;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5 + (activation * 0.5)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), paint);

    if (activation > 0.5) {
      final glowPaint = Paint()
        ..color = AppColors.warning.withValues(alpha: 0.15 * activation)
        ..strokeWidth = 4.0 * activation
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StraightConnectorPainter oldDelegate) =>
      oldDelegate.activation != activation;
}