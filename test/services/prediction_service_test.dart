import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/prediction_service.dart';
import 'package:mondial_2026/models/match.dart';
import 'package:mondial_2026/app_constants.dart';

void main() {
  group('PredictionService.evaluatePoints (Exponential)', () {
    test('Unplayed match always returns 0 points', () {
      final unplayedMatch = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: null,
        t2Score: null,
        stage: '',
      );

      final pred = MatchPrediction(matchId: '1', t1Score: 2, t2Score: 1);

      expect(PredictionService.evaluatePoints(unplayedMatch, pred), 0);
    });

    group('Group Stage Matches', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'de',
        t2: 'cw',
        t1Score: 4,
        t2Score: 1,
        stage: '',
      );

      test('Exact scoreline (4-1) returns outcome + GD bonus + exact bonus (scaled by betting odds & risk)', () {
        final pred = MatchPrediction(matchId: '1', t1Score: 4, t2Score: 1);
        expect(PredictionService.evaluatePoints(match, pred), 1344);
      });

      test('Correct outcome (win) but wrong scoreline (2-0) returns outcome points (scaled by betting odds)', () {
        final pred = MatchPrediction(matchId: '1', t1Score: 2, t2Score: 0);
        // GD is 2 in prediction, 3 in actual match. No GD bonus if GD doesn't match.
        // Actual GD = 3. Pred GD = 2. So 0 GD bonus.
        expect(PredictionService.evaluatePoints(match, pred), 76);
      });

      test('Correct outcome (win) and matching GD (3-0) returns outcome + GD points (scaled by betting odds)', () {
        final pred = MatchPrediction(matchId: '1', t1Score: 3, t2Score: 0);
        // Actual GD = 3. Pred GD = 3. 
        expect(PredictionService.evaluatePoints(match, pred), 378);
      });
      
      test('Incorrect outcome returns 0 points', () {
        final pred = MatchPrediction(matchId: '1', t1Score: 1, t2Score: 4);
        expect(PredictionService.evaluatePoints(match, pred), 0);
      });
    });
  });
}
