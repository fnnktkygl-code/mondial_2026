import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/models/match.dart';

void main() {
  group('WorldCupMatch', () {
    test('isPlayed should return true when both scores are not null', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        t1Score: 1,
        t2Score: 2,
        status: 'IN_PLAY',
      );

      expect(match.isPlayed, true);
    });

    test('isPlayed should return false when t1Score is null', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        t2Score: 2,
        status: 'IN_PLAY',
      );

      expect(match.isPlayed, false);
    });

    test('isPlayed should return false when t2Score is null', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        t1Score: 1,
        status: 'IN_PLAY',
      );

      expect(match.isPlayed, false);
    });

    test('isPlayed should return false when both scores are null', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        status: 'IN_PLAY',
      );

      expect(match.isPlayed, false);
    });

    test('isPlayed handles missing score regardless of status FINISHED', () {
      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        status: 'FINISHED',
      );

      expect(match.isPlayed, false);
    });

    test('isPlayed should return false when status is TIMED or SCHEDULED even with scores', () {
      final matchTimed = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        t1Score: 0,
        t2Score: 0,
        status: 'TIMED',
      );
      final matchScheduled = WorldCupMatch(
        id: '2',
        date: DateTime.now(),
        t1: 'Team A',
        t2: 'Team B',
        t1Score: 0,
        t2Score: 0,
        status: 'SCHEDULED',
      );

      expect(matchTimed.isPlayed, false);
      expect(matchScheduled.isPlayed, false);
    });
  });
}
