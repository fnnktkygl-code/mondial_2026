import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
String finalCode = code.toLowerCase() == 'gb-sct' ? 'sco' : code.toLowerCase();
    final cleanCode = code.toLowerCase().replaceAll('g_', '');
    if (cleanCode.length > 2 && cleanCode != 'sco') return const SizedBox.shrink();

    final Widget flagImg = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        getTeamLogoPath(code),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade800,
          alignment: Alignment.center,
          child: Text(
            cleanCode.toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: (width * 0.35).clamp(8.0, 12.0), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    if (code.toLowerCase() == 'sn') {
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
