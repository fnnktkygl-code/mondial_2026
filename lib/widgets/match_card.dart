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
  final String? alertType;
  final VoidCallback onAlertToggle;
  final VoidCallback onTap;
  final String? supportedTeamCode;

  const MatchCard({
    super.key,
    required this.match,
    required this.lang,
    required this.hasAlert,
    this.alertType,
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

  /// A match is "live" if it has started but has no score yet.
  bool get _isLive {
    final now = DateTime.now();
    return !widget.match.isPlayed && widget.match.date.isBefore(now);
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
    if ((code.length > 2 && code.toLowerCase() != 'sco') || code.toLowerCase() == 'tbd') {
      return Container(
        width: size * 1.4,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMid, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          'FIFA',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      );
    }
    
    return Container(
      width: size * 1.4,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TeamFlagWidget(
        code: code,
        width: size * 1.4,
        height: size,
        borderRadius: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t1Name = AppTranslations.getTeam(widget.lang, widget.match.t1);
    final t2Name = AppTranslations.getTeam(widget.lang, widget.match.t2);
    final live = _isLive;

    // Check if user's team is playing in this match
    final isUserTeam = widget.supportedTeamCode != null &&
        (widget.match.t1.toLowerCase() == widget.supportedTeamCode!.toLowerCase() ||
         widget.match.t2.toLowerCase() == widget.supportedTeamCode!.toLowerCase());

    final String stageText = widget.match.isKnockout
        ? (widget.match.stage ?? '')
        : '${AppTranslations.get(widget.lang, 'group')} ${widget.match.group ?? ''}';
 
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isUserTeam
                ? AppColors.accent.withValues(alpha: 0.06)
                : AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: live
                  ? AppColors.accent.withValues(alpha: _pulseAnimation.value)
                  : isUserTeam
                      ? AppColors.accent
                      : widget.hasAlert
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border,
              width: (live || isUserTeam) ? 2.0 : 1.5,
            ),
            boxShadow: (live || isUserTeam)
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: (live ? _pulseAnimation.value : 0.4) * 0.35,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.accent.withValues(alpha: 0.05),
          highlightColor: AppColors.accent.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (live) ...[
                          _LiveBadge(animation: _pulseAnimation),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.match.getFormattedTime(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stageText,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Alert Bell
                    IconButton(
                      tooltip: AppTranslations.get(widget.lang, 'toggleAlertTooltip'),
                      icon: Icon(
                        widget.hasAlert
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: widget.hasAlert ? AppColors.accent : AppColors.textDim,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.hasAlert
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.border,
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: widget.onAlertToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Match Teams & Scores
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          WCTeamProfileDialog.show(context, widget.match.t1, widget.lang);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFlag(widget.match.t1, 40),
                            const SizedBox(height: 8),
                            Text(
                              t1Name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Middle: score / LIVE / VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.match.isPlayed
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.match.t1Score}',
                                  style: TextStyle(
                                    color: widget.match.t1Score! >= widget.match.t2Score!
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    ':',
                                    style: TextStyle(
                                      color: AppColors.borderStrong,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${widget.match.t2Score}',
                                  style: TextStyle(
                                    color: widget.match.t2Score! >= widget.match.t1Score!
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            )
                          : live
                              ? AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, _) {
                                    return Text(
                                      '⚽ LIVE',
                                      style: TextStyle(
                                        color: Color.lerp(
                                          AppColors.accent,
                                          AppColors.accentLight,
                                          _pulseAnimation.value,
                                        ),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 1.5,
                                      ),
                                    );
                                  },
                                )
                              : const Text(
                                  'VS',
                                  style: TextStyle(
                                    color: AppColors.borderStrong,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                    ),

                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          WCTeamProfileDialog.show(context, widget.match.t2, widget.lang);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFlag(widget.match.t2, 40),
                            const SizedBox(height: 8),
                            Text(
                              t2Name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Footer: venue & alert badge
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textDim),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.match.venue ?? '',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (widget.hasAlert && widget.alertType != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 12, color: AppColors.accent),
                              const SizedBox(width: 2),
                              Text(
                                widget.alertType == '1d'
                                    ? AppTranslations.get(widget.lang, 'alert1Day')
                                    : widget.alertType == '1h'
                                        ? AppTranslations.get(widget.lang, 'alert1Hour')
                                        : AppTranslations.get(widget.lang, 'alert30Min'),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated LIVE badge with a pulsing neon dot.
class _LiveBadge extends StatelessWidget {
  final Animation<double> animation;
  const _LiveBadge({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: animation.value),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(AppColors.accent, AppColors.accentLight, animation.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: animation.value * 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
