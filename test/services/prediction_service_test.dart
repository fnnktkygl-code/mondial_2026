import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/prediction_service.dart';
import 'package:mondial_2026/models/match.dart';
import 'package:mondial_2026/app_constants.dart';

void main() {
  group('PredictionService.evaluatePoints', () {
    test('Unplayed match always returns 0 points', () {
      final unplayedMatch = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: null,
        t2Score: null,
        stage: '', // empty stage indicates group stage
      );

      final pred = MatchPrediction(matchId: '1', t1Score: 2, t2Score: 1);

      expect(PredictionService.evaluatePoints(unplayedMatch, pred), 0);
    });

    group('Group Stage Matches', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: 2,
        t2Score: 1,
        stage: '', // empty stage indicates group stage
      );

      test('Exact scoreline returns exact points', () {
        final pred = MatchPrediction(matchId: '1', t1Score: 2, t2Score: 1);
        expect(
          PredictionService.evaluatePoints(match, pred),
          kExactScorePoints,
        );
      });

      test(
        'Correct outcome (win) but wrong scoreline returns correct outcome points',
        () {
          final pred = MatchPrediction(matchId: '1', t1Score: 3, t2Score: 0);
          expect(
            PredictionService.evaluatePoints(match, pred),
            kCorrectOutcomePoints,
          );
        },
      );

      test('Incorrect outcome returns 0 points', () {
        final pred = MatchPrediction(
          matchId: '1',
          t1Score: 1,
          t2Score: 2,
        ); // predicted loss
        expect(PredictionService.evaluatePoints(match, pred), 0);

        final pred2 = MatchPrediction(
          matchId: '1',
          t1Score: 1,
          t2Score: 1,
        ); // predicted draw
        expect(PredictionService.evaluatePoints(match, pred2), 0);
      });

      test(
        'Correct outcome (draw) but wrong scoreline returns correct outcome points',
        () {
          final drawMatch = match.copyWith(t1Score: 1, t2Score: 1);
          final pred = MatchPrediction(matchId: '1', t1Score: 0, t2Score: 0);
          expect(
            PredictionService.evaluatePoints(drawMatch, pred),
            kCorrectOutcomePoints,
          );
        },
      );

      test(
        'Correct outcome (loss) but wrong scoreline returns correct outcome points',
        () {
          final lossMatch = match.copyWith(t1Score: 0, t2Score: 2);
          final pred = MatchPrediction(matchId: '1', t1Score: 1, t2Score: 3);
          expect(
            PredictionService.evaluatePoints(lossMatch, pred),
            kCorrectOutcomePoints,
          );
        },
      );
    });

    group('Knockout Stage Matches (90 minutes)', () {
      final knockoutMatch = WorldCupMatch(
        id: '2',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: 2,
        t2Score: 1,
        stage: 'Round of 16', // non-empty stage indicates knockout stage
        wentToET: false,
        wentToPK: false,
      );

      test('Exact 90-min scoreline returns exact knockout points', () {
        final pred = MatchPrediction(matchId: '2', t1Score: 2, t2Score: 1);
        expect(
          PredictionService.evaluatePoints(knockoutMatch, pred),
          kExactScoreKnockoutPoints,
        );
      });

      test(
        'Correct 90-min outcome but wrong scoreline returns correct outcome knockout points',
        () {
          final pred = MatchPrediction(matchId: '2', t1Score: 3, t2Score: 0);
          expect(
            PredictionService.evaluatePoints(knockoutMatch, pred),
            kCorrectOutcomeKnockoutPts,
          );
        },
      );

      test('Incorrect 90-min outcome returns 0 points', () {
        final pred1 = MatchPrediction(matchId: '2', t1Score: 0, t2Score: 1);
        expect(PredictionService.evaluatePoints(knockoutMatch, pred1), 0);

        final pred2 = MatchPrediction(matchId: '2', t1Score: 1, t2Score: 1);
        expect(PredictionService.evaluatePoints(knockoutMatch, pred2), 0);
      });

      test(
        'Correct 90-min outcome (draw that goes to ET) but wrong scoreline returns correct outcome knockout points',
        () {
          final drawMatch = knockoutMatch.copyWith(
            t1Score: 1,
            t2Score: 1,
            wentToET: true,
            etWinner: 'FRA',
          );
          final pred = MatchPrediction(matchId: '2', t1Score: 0, t2Score: 0);
          // User predicted draw at 90m, match drew at 90m (1-1), so they get 90m outcome points
          // We do not add ET points here because `extraTimeWinner` is null
          expect(
            PredictionService.evaluatePoints(drawMatch, pred),
            kCorrectOutcomeKnockoutPts,
          );
        },
      );
    });

    group('Knockout Stage Matches (Beyond 90 minutes)', () {
      final etMatch = WorldCupMatch(
        id: '3',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: 1,
        t2Score: 1, // Drew at 90m
        stage: 'Quarter-Final',
        wentToET: true,
        etWinner: 'FRA',
        wentToPK: false,
      );

      final pkMatch = WorldCupMatch(
        id: '4',
        date: DateTime.now(),
        t1: 'FRA',
        t2: 'ARG',
        t1Score: 1,
        t2Score: 1, // Drew at 90m
        stage: 'Quarter-Final',
        wentToET: true,
        etWinner: 'ARG',
        wentToPK: true,
        pkWinner: 'ARG',
      );

      test(
        'Correct 90-min outcome + correct extra-time winner returns outcome points + ET bonus',
        () {
          final pred = MatchPrediction(
            matchId: '3',
            t1Score: 0,
            t2Score: 0,
            extraTimeWinner: 'FRA',
          );
          expect(
            PredictionService.evaluatePoints(etMatch, pred),
            kCorrectOutcomeKnockoutPts + kExtraTimeBonusPoints,
          );
        },
      );

      test(
        'Correct 90-min outcome + wrong extra-time winner returns only outcome points',
        () {
          final pred = MatchPrediction(
            matchId: '3',
            t1Score: 0,
            t2Score: 0,
            extraTimeWinner: 'ARG',
          );
          expect(
            PredictionService.evaluatePoints(etMatch, pred),
            kCorrectOutcomeKnockoutPts,
          );
        },
      );

      test(
        'Correct 90-min outcome + correct penalty shootout winner returns outcome + PK bonus (+ ET bonus if applicable)',
        () {
          // Here the user predicts ARG to win in ET (which gives ET points since etWinner = ARG)
          // AND predicts ARG to win on PKs.
          // In this specific edge case, etWinner is populated if PK follows ET, and wentToPK=true.
          // Penalty winner mapping: `pred.penaltyWinner == false` implies t2 (ARG).
          final pred = MatchPrediction(
            matchId: '4',
            t1Score: 0,
            t2Score: 0,
            extraTimeWinner: 'ARG',
            penaltyWinner: false, // false maps to t2 (ARG)
          );
          expect(
            PredictionService.evaluatePoints(pkMatch, pred),
            kCorrectOutcomeKnockoutPts +
                kExtraTimeBonusPoints +
                kPenaltyShootoutBonusPoints,
          );
        },
      );

      test(
        'Correct 90-min outcome + wrong penalty shootout winner returns no PK bonus',
        () {
          final pred = MatchPrediction(
            matchId: '4',
            t1Score: 0,
            t2Score: 0,
            extraTimeWinner: 'ARG',
            penaltyWinner: true, // true maps to t1 (FRA)
          );
          expect(
            PredictionService.evaluatePoints(pkMatch, pred),
            kCorrectOutcomeKnockoutPts + kExtraTimeBonusPoints,
          );
        },
      );

      test(
        'Exact 90-min scoreline + correct ET/PK bonuses returns exact points + bonuses',
        () {
          final pred = MatchPrediction(
            matchId: '4',
            t1Score: 1,
            t2Score: 1, // Exact 90m scoreline
            extraTimeWinner: 'ARG',
            penaltyWinner: false, // ARG
          );
          expect(
            PredictionService.evaluatePoints(pkMatch, pred),
            kExactScoreKnockoutPoints +
                kExtraTimeBonusPoints +
                kPenaltyShootoutBonusPoints,
          );
        },
      );

      test(
        'Incorrect 90-min outcome but correct ET winner returns 0 points (bonuses only apply if 90-min outcome is correct)',
        () {
          final pred = MatchPrediction(
            matchId: '3',
            t1Score: 2, // Pred win for FRA at 90m
            t2Score: 1,
            extraTimeWinner: 'FRA',
          );
          expect(PredictionService.evaluatePoints(etMatch, pred), 0);
        },
      );
    });
  });
}
