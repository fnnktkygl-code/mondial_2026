import 'package:flutter/material.dart';
import '../models/prediction_trend.dart';
import '../l10n/translations.dart';

class PredictionTrendBar extends StatelessWidget {
  final PredictionTrend trend;
  final String t1;
  final String t2;

  const PredictionTrendBar({
    super.key,
    required this.trend,
    required this.t1,
    required this.t2,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.total == 0) return const SizedBox.shrink();

    final t1Pct = trend.t1Percentage;
    final drawPct = trend.drawPercentage;
    final t2Pct = trend.t2Percentage;
    
    final t1Flex = (t1Pct * 100).round();
    final drawFlex = (drawPct * 100).round();
    final t2Flex = (t2Pct * 100).round();

    final lang = Localizations.localeOf(context).languageCode;
    final t1Name = AppTranslations.getTeam(lang, t1);
    final t2Name = AppTranslations.getTeam(lang, t2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$t1Flex% $t1Name', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('$drawFlex% Nul', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('$t2Flex% $t2Name', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (t1Flex > 0)
                Expanded(
                  flex: t1Flex,
                  child: Container(color: Colors.blueAccent),
                ),
              if (drawFlex > 0)
                Expanded(
                  flex: drawFlex,
                  child: Container(color: Colors.grey.shade400),
                ),
              if (t2Flex > 0)
                Expanded(
                  flex: t2Flex,
                  child: Container(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
