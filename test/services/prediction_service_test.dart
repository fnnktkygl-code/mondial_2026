import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/prediction_service.dart';
import 'package:mondial_2026/models/match.dart';

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

  group('PredictionService - Joker & Phase Validation', () {
    test('Group stage sessions correctly split into group_1, group_2, group_3 based on date order', () {
      final List<WorldCupMatch> allMatches = List.generate(72, (i) {
        return WorldCupMatch(
          id: 'm$i',
          date: DateTime(2026, 6, 1 + i), // sequential dates
          t1: 'Team A',
          t2: 'Team B',
          stage: '',
        );
      });

      // Match at index 10 should be group_1
      expect(PredictionService.getMatchPhase(allMatches[10], allMatches), 'group_1');

      // Match at index 30 should be group_2
      expect(PredictionService.getMatchPhase(allMatches[30], allMatches), 'group_2');

      // Match at index 60 should be group_3
      expect(PredictionService.getMatchPhase(allMatches[60], allMatches), 'group_3');
    });

    test('Knockout stages correctly mapped by stage string', () {
      final round32 = WorldCupMatch(id: 'm100', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Round of 32');
      final round16 = WorldCupMatch(id: 'm101', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Round of 16');
      final quarter = WorldCupMatch(id: 'm102', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Quarter-Final');
      final semi = WorldCupMatch(id: 'm103', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Semi-Final');
      final playOff3rd = WorldCupMatch(id: 'm104', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Play-off for third place');
      final finalMatch = WorldCupMatch(id: 'm105', date: DateTime.now(), t1: 'T1', t2: 'T2', stage: 'Final');

      final emptyList = <WorldCupMatch>[];

      expect(PredictionService.getMatchPhase(round32, emptyList), 'round_32');
      expect(PredictionService.getMatchPhase(round16, emptyList), 'round_16');
      expect(PredictionService.getMatchPhase(quarter, emptyList), 'quarter');
      expect(PredictionService.getMatchPhase(semi, emptyList), 'semi');
      expect(PredictionService.getMatchPhase(playOff3rd, emptyList), 'final');
      expect(PredictionService.getMatchPhase(finalMatch, emptyList), 'final');
    });

    test('Available boosters limit is 1 for all phases', () {
      expect(PredictionService.getAvailableBoostersForPhase('group_1'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('group_2'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('group_3'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('round_32'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('round_16'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('quarter'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('semi'), 1);
      expect(PredictionService.getAvailableBoostersForPhase('final'), 1);
    });

    test('evaluatePointsBreakdown returns correct breakdown details consistent with evaluatePoints', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: 3,
        t2Score: 1,
        stage: '',
      );

      final pred = MatchPrediction(matchId: '1', t1Score: 3, t2Score: 1);
      final breakdown = PredictionService.evaluatePointsBreakdown(match, pred, false);

      expect(breakdown['totalPoints'], PredictionService.evaluatePoints(match, pred));
      expect(breakdown['isOutcomeCorrect'], true);
      expect(breakdown['isScoreExact'], true);
      expect(breakdown['exactScorePoints'] > 0.0, true);
    });

    test('Odds multiplier is clamped to kMaxOddsMultiplier (5.0) and outsider points is a flat 100', () {
      // Argentina (ar, rating 1876.12) vs Kosovo (xk, rating 1319.12)
      // Kosovo win odds will be > 5.0 (approx 28.0)
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'ar',
        t2: 'xk',
        t1Score: 0,
        t2Score: 1,
        stage: '',
      );

      // We predict Kosovo wins 0-1 (exact score)
      final pred = MatchPrediction(matchId: '1', t1Score: 0, t2Score: 1);
      
      final points = PredictionService.evaluatePoints(match, pred);
      final breakdown = PredictionService.evaluatePointsBreakdown(match, pred, false);

      // Verify oddsMultiplier is reported as capped at 5.0 in the breakdown
      expect(breakdown['oddsMultiplier'], 5.0);
      
      // Verify outsiderPoints is exactly 100.0 (flat) and NOT scaled by odds (100 * 5.0 would be 500)
      expect(breakdown['outsiderPoints'], 100.0);
      
      // Points check:
      // outcomePoints = 50 * 5 = 250
      // gdPoints = 20 * 5 = 100 (diff is 1)
      // exactScorePoints = 200 * 5 * (1.0 + 1 * 0.40 + 1 * 0.20 = 1.6) = 1600
      // outsiderPoints = 100
      // Total = 250 + 100 + 1600 + 100 = 2050
      expect(points, 2050);
      expect(breakdown['totalPoints'], 2050);
    });
  });
}
