import 'package:flutter/material.dart';
import '../app_colors.dart';

class WCTooltip extends StatelessWidget {
  final String? message;
  final InlineSpan? richMessage;
  final Widget child;
  final TooltipTriggerMode triggerMode;
  final bool preferBelow;
  final String? title;

  const WCTooltip({
    super.key,
    this.message,
    this.richMessage,
    required this.child,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.preferBelow = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final InlineSpan? effectiveRichMessage = richMessage ??
        (title != null || message != null
            ? TextSpan(
                children: [
                  if (title != null)
                    TextSpan(
                      text: '$title\n',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'Syne',
                      ),
                    ),
                  if (message != null)
                    TextSpan(
                      text: message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                ],
              )
            : null);

    if (effectiveRichMessage == null && message == null) {
      return child;
    }

    return Tooltip(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      message: effectiveRichMessage == null ? message : null,
      richMessage: effectiveRichMessage,
      preferBelow: preferBelow,
      verticalOffset: 20,
      triggerMode: triggerMode,
      child: child,
    );
  }
}
