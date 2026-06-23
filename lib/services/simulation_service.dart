import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/match.dart';
import 'odds_service.dart';

class SimulatedScore {
  int t1;
  int t2;
  SimulatedScore(this.t1, this.t2);
}

class SimulationService extends ChangeNotifier {
  static final SimulationService instance = SimulationService();

  bool _isSimulationMode = false;
  bool get isSimulationMode => _isSimulationMode;

  final Map<String, SimulatedScore> _simulatedScores = {};

  SimulatedScore? getSimulatedScore(String matchId) {
    if (!_isSimulationMode) return null;
    return _simulatedScores[matchId];
  }

  void toggleSimulation(List<WorldCupMatch> allMatches) {
    _isSimulationMode = !_isSimulationMode;
    _simulatedScores.clear();

    if (_isSimulationMode) {
      final random = Random();
      for (final match in allMatches) {
        // Uniquement phase de poules
        if (match.isGroupStage && !match.isPlayed) {
          if (match.t1 == 'tbd' || match.t2 == 'tbd') continue;
          if (match.t1.contains(RegExp(r'\d')) || match.t2.contains(RegExp(r'\d'))) continue;

          final odds = WCOddsService.calculateMatchOdds(match.t1, match.t2, allMatches);
          final prob1 = 1 / odds['1']!;
          final probX = 1 / odds['X']!;
          final prob2 = 1 / odds['2']!;
          
          final total = prob1 + probX + prob2;
          double p1 = prob1 / total;
          double px = probX / total;
          double p2 = prob2 / total;

          // Exagérer les probabilités pour que le favori gagne beaucoup plus souvent
          // (Évite les surprises irréalistes d'un point de vue prono "logique")
          p1 = pow(p1, 3).toDouble();
          px = pow(px, 3).toDouble();
          p2 = pow(p2, 3).toDouble();

          final newTotal = p1 + px + p2;
          p1 /= newTotal;
          px /= newTotal;
          // p2 /= newTotal; (not strictly needed as it's the remainder)

          final r = random.nextDouble();
          int t1Goals = 0;
          int t2Goals = 0;
          
          if (r < p1) { // T1 wins
            t1Goals = random.nextInt(3) + 1; // 1 to 3
            t2Goals = t1Goals > 1 ? random.nextInt(t1Goals) : 0;
            if (random.nextDouble() > 0.8) t1Goals++;
          } else if (r < p1 + px) { // Draw
            t1Goals = random.nextInt(3); // 0 to 2
            t2Goals = t1Goals;
            if (random.nextDouble() > 0.9) { t1Goals++; t2Goals++; }
          } else { // T2 wins
            t2Goals = random.nextInt(3) + 1; // 1 to 3
            t1Goals = t2Goals > 1 ? random.nextInt(t2Goals) : 0;
            if (random.nextDouble() > 0.8) t2Goals++;
          }
          
          _simulatedScores[match.id] = SimulatedScore(t1Goals, t2Goals);
        }
      }
    }
    notifyListeners();
  }

  void updateSimulatedScore(String matchId, int t1, int t2) {
    if (_isSimulationMode) {
      _simulatedScores[matchId] = SimulatedScore(t1, t2);
      notifyListeners();
    }
  }
}
