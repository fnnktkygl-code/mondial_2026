import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_constants.dart';

class TeamFlagWidget extends StatelessWidget {
  final String code;
  final double width;
  final double height;
  final double borderRadius;

  const TeamFlagWidget({
    super.key,
    required this.code,
    this.width = 24,
    this.height = 16,
    this.borderRadius = 4,
  });

  /// Normalise un code équipe : strip g_, gb-sct → sco, lowercase.
  static String normalizeCode(String code) {
    final clean = code.toLowerCase().replaceAll('g_', '');
    return clean == 'gb-sct' ? 'sco' : clean;
  }

  /// Retourne true si le code est un vrai drapeau connu.
  static bool _isKnownCode(String normalized) {
    return normalized.length <= 2 || normalized == 'sco';
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

    if (!_isKnownCode(normalized) || normalized == 'tbd') {
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

    if (!_isKnownCode(resolvedCode)) {
      return const SizedBox.shrink();
    }

    final Widget flagImg = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        getTeamLogoPath(resolvedCode),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade800,
          alignment: Alignment.center,
          child: Text(
            resolvedCode.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: (width * 0.35).clamp(8.0, 12.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    // Special case: Senegal gets champion stars
    if (resolvedCode == 'sn') {
      final double starSize = (width * 0.35).clamp(8.0, 12.0);
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
