import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';

class MatchCard extends StatefulWidget {
  final WorldCupMatch match;
  final String lang;
  final bool hasAlert;
  final bool hasPrediction;
  final String? Function(WorldCupMatch)? alertType;
  final String? predictionResult; // 'exact' | 'winner' | 'wrong' | null
  final VoidCallback onAlertToggle;
  final VoidCallback onTap;
  final String? supportedTeamCode;

  const MatchCard({
    super.key,
    required this.match,
    required this.lang,
    required this.hasAlert,
    this.hasPrediction = false,
    this.alertType,
    this.predictionResult,
    required this.onAlertToggle,
    required this.onTap,
    this.supportedTeamCode,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isLive {
    final now = DateTime.now();
    return !widget.match.isPlayed &&
        now.isAfter(widget.match.date) &&
        now.isBefore(widget.match.date.add(const Duration(minutes: 105)));
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: kLivePulseDuration,
    );
    _pulseAnimation = Tween<double>(begin: kLivePulseMin, end: kLivePulseMax).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isLive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildFlag(String code, double size) {
    return TeamFlagWidget.flag(
      code,
      width: size * 1.4,
      height: size,
      borderRadius: 8,
      boxShadowOpacity: 0.3,
    );
  }

  String _getFlagcdnUrl(String code) {
    String cleanCode = code.toLowerCase().replaceAll('g_', '');
    if (cleanCode == 'en') cleanCode = 'gb-eng';
    if (cleanCode == 'sco') cleanCode = 'gb-sct';
    if (cleanCode == 'wa') cleanCode = 'gb-wls';
    return 'https://flagcdn.com/w320/$cleanCode.png';
  }

  @override
  Widget build(BuildContext context) {
    final t1Name = AppTranslations.getTeam(widget.lang, widget.match.t1);
    final t2Name = AppTranslations.getTeam(widget.lang, widget.match.t2);
    final live = _isLive;
    final isUserTeam = widget.supportedTeamCode != null &&
        (widget.match.t1.toLowerCase() == widget.supportedTeamCode!.toLowerCase() ||
            widget.match.t2.toLowerCase() == widget.supportedTeamCode!.toLowerCase());

    final String stageText = widget.match.isKnockout
        ? (widget.match.stage ?? '')
        : '${AppTranslations.get(widget.lang, 'group')} ${widget.match.group ?? ''}';

    final String tooltipMessage;
    final IconData predIcon;
    final Color predColor;
    if (widget.match.isPlayed && widget.hasPrediction) {
      switch (widget.predictionResult) {
        case 'exact':
          predIcon = Icons.star_rounded;
          predColor = Colors.amber;
          tooltipMessage = AppTranslations.get(widget.lang, 'exactScoreTooltip');
          break;
        case 'winner':
          predIcon = Icons.check_circle_rounded;
          predColor = Colors.greenAccent;
          tooltipMessage = AppTranslations.get(widget.lang, 'correctWinnerTooltip');
          break;
        default:
          predIcon = Icons.cancel_rounded;
          predColor = Colors.redAccent;
          tooltipMessage = AppTranslations.get(widget.lang, 'wrongPredictionTooltip');
      }
    } else if (widget.hasPrediction) {
      predIcon = Icons.check_circle_rounded;
      predColor = Colors.greenAccent;
      tooltipMessage = AppTranslations.get(widget.lang, 'predictionSavedTooltip');
    } else {
      predIcon = Icons.pending_actions_rounded;
      predColor = Colors.orangeAccent;
      tooltipMessage = AppTranslations.get(widget.lang, 'predictionPendingTooltip');
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isUserTeam ? AppColors.accent.withValues(alpha: 0.06) : AppColors.card,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(
              color: live ? AppColors.accent.withValues(alpha: _pulseAnimation.value) : (isUserTeam ? AppColors.accent : (widget.hasAlert ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border)),
              width: (live || isUserTeam) ? 2.0 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background flags
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.network(
                          _getFlagcdnUrl(widget.match.t1),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.network(
                          _getFlagcdnUrl(widget.match.t2),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Padding(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (live) const _LiveBadge() else Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)),
                          child: Text(widget.match.getFormattedTime(), style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
                          child: Text(stageText, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 11)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Tooltip(
                          message: tooltipMessage,
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            predIcon,
                            color: predColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(widget.hasAlert ? Icons.notifications_active : Icons.notifications_none, color: widget.hasAlert ? AppColors.accent : AppColors.textDim, size: 22),
                          onPressed: widget.onAlertToggle,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Teams
                Row(
                  children: [
                    Expanded(child: _buildTeamSection(widget.match.t1, t1Name, context, true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.match.isPlayed
                          ? Text('${widget.match.t1Score} - ${widget.match.t2Score}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 22))
                          : const Text('VS', style: TextStyle(color: AppColors.borderStrong, fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                    Expanded(child: _buildTeamSection(widget.match.t2, t2Name, context, false)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection(String teamCode, String teamName, BuildContext context, bool isLeft) {
    return GestureDetector(
      onTap: () => WCTeamProfileDialog.show(context, teamCode, widget.lang),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFlag(teamCode, 40),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(kBadgeRadius)),
    child: const Text('⚽ LIVE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
  );
}