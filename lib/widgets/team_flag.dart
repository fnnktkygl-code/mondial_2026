import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_constants.dart';

class TeamFlagWidget extends StatelessWidget {
  final String code;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const TeamFlagWidget({
    super.key,
    required this.code,
    this.width = 24,
    this.height = 16,
    this.borderRadius = 4,
    this.fit = BoxFit.contain,
  });

  /// Normalise un code équipe : strip g_, gb-sct → sco, lowercase.
  static String normalizeCode(String code) {
    final clean = code.toLowerCase().replaceAll('g_', '');
    return clean == 'gb-sct' ? 'sco' : clean;
  }

  /// Factory centralisée — à utiliser partout à la place de _buildFlag().
  /// Gère le placeholder "FIFA" et le cas TBD de façon unique.
  static Widget flag(
      String code, {
        required double width,
        required double height,
        double borderRadius = 8,
        double boxShadowOpacity = 0.0,
      }) {
    final normalized = normalizeCode(code);

    // Safeguard for purely unknown/unresolved teams
    if (normalized == 'tbd') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderMid, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          'FIFA',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }

    Widget flag = TeamFlagWidget(
      code: normalized,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: (width == double.infinity) ? BoxFit.cover : BoxFit.contain,
    );

    if (boxShadowOpacity > 0) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: boxShadowOpacity),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: flag,
      );
    }

    return flag;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCode = normalizeCode(code);

    if (resolvedCode == 'tbd') {
      return const SizedBox.shrink();
    }

    final Widget flagImg = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        getTeamLogoPath(resolvedCode),
        width: width == double.infinity ? null : width,
        height: height == double.infinity ? null : height,
        fit: fit,
        // The errorBuilder acts as a perfect fallback for knockout placeholders (e.g., '1A', 'W49')
        // that do not have physical PNG assets but need to be displayed as text.
        errorBuilder: (context, error, stackTrace) => Container(
          width: width == double.infinity ? null : width,
          height: height == double.infinity ? null : height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderStrong, width: 1.0),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            resolvedCode.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: width == double.infinity ? 24 : (width * 0.35).clamp(8.0, 12.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    // Special case: Senegal gets champion stars
    if (resolvedCode == 'sn') {
      final double starSize = width == double.infinity ? 40 : (width * 0.35).clamp(8.0, 12.0);
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          flagImg,
          Positioned(
            top: -starSize * 0.8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: starSize, color: Colors.amber),
                Icon(Icons.star, size: starSize, color: Colors.amber),
              ],
            ),
          ),
        ],
      );
    }

    return flagImg;
  }
}
