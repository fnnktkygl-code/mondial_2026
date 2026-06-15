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

    test('lineups serialization and copyWith tests', () {
      final player1 = MatchLineupPlayer(name: 'Kylian Mbappé', jersey: '10', position: 'Forward', starter: true);
      final player2 = MatchLineupPlayer(name: 'Antoine Griezmann', jersey: '7', position: 'Midfielder', starter: false);
      final lineups = MatchLineups(
        t1Players: [player1],
        t2Players: [player2],
        t1Formation: '4-3-3',
        t2Formation: '4-4-2',
      );

      final match = WorldCupMatch(
        id: '1',
        date: DateTime.now(),
        t1: 'fr',
        t2: 'de',
        lineups: lineups,
      );

      // Verify toJson & fromJson
      final json = match.toJson();
      final matchFromJson = WorldCupMatch.fromJson(json);

      expect(matchFromJson.lineups, isNotNull);
      expect(matchFromJson.lineups!.t1Formation, '4-3-3');
      expect(matchFromJson.lineups!.t2Formation, '4-4-2');
      expect(matchFromJson.lineups!.t1Players.length, 1);
      expect(matchFromJson.lineups!.t1Players[0].name, 'Kylian Mbappé');
      expect(matchFromJson.lineups!.t1Players[0].starter, true);
      expect(matchFromJson.lineups!.t2Players.length, 1);
      expect(matchFromJson.lineups!.t2Players[0].name, 'Antoine Griezmann');
      expect(matchFromJson.lineups!.t2Players[0].starter, false);

      // Verify copyWith
      final updatedMatch = match.copyWith(
        lineups: MatchLineups(
          t1Players: [],
          t2Players: [],
        ),
      );
      expect(updatedMatch.lineups!.t1Players, isEmpty);
    });
  });
}
