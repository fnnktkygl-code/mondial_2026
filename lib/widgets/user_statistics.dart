import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import '../app_constants.dart';

class WCUserStatisticsWidget extends StatelessWidget {
  final PredictionData userPreds;
  final List<WorldCupMatch> matches;
  final String lang;

  const WCUserStatisticsWidget({
    super.key,
    required this.userPreds,
    required this.matches,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final playedMatches = matches.where((m) => m.isPlayed).toList();
    if (playedMatches.isEmpty) {
      return _buildEmptyState();
    }

    int exactScores = 0;
    int correctWinners = 0;
    int wrongPreds = 0;
    int noPreds = 0;
    int totalPoints = PredictionService.calculateTotalPoints(userPreds, matches);

    for (final m in playedMatches) {
      final pred = userPreds.matchPredictions[m.id];
      if (pred == null) {
        noPreds++;
        continue;
      }
      final res = PredictionService.getPredictionResult(m, userPreds);
      if (res == 'exact') {
        exactScores++;
      } else if (res == 'winner') {
        correctWinners++;
      } else {
        wrongPreds++;
      }
    }

    final totalPreds = exactScores + correctWinners + wrongPreds;
    final accuracy = totalPreds > 0 ? (exactScores + correctWinners) / totalPreds : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                AppTranslations.get(lang, 'myPerformance'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatSquare(
                label: AppTranslations.get(lang, 'accuracy'),
                value: '${(accuracy * 100).toStringAsFixed(1)}%',
                color: AppColors.accent,
                icon: Icons.track_changes_rounded,
              ),
              const SizedBox(width: 12),
              _buildStatSquare(
                label: AppTranslations.get(lang, 'avgPoints'),
                value: (totalPreds > 0 ? (totalPoints / totalPreds).toStringAsFixed(1) : '0'),
                color: Colors.amber,
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            label: AppTranslations.get(lang, 'exactScores'),
            count: exactScores,
            total: playedMatches.length,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: AppTranslations.get(lang, 'correctWinners'),
            count: correctWinners,
            total: playedMatches.length,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: AppTranslations.get(lang, 'wrongOrMissed'),
            count: wrongPreds + noPreds,
            total: playedMatches.length,
            color: AppColors.danger.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSquare({required String label, required String value, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({required String label, required int count, required int total, required Color color}) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.bar_chart_rounded, color: AppColors.textDim, size: 40),
          const SizedBox(height: 12),
          Text(
            'Les statistiques de performance apparaîtront après le premier match.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
