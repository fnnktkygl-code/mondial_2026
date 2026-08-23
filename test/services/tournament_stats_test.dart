import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/models/match.dart';

void main() {
  group('TournamentStats Tests', () {
    test('computes both scorers and assists accurately', () {
      final matches = [
        WorldCupMatch(
          id: 'm1',
          date: DateTime.now(),
          t1: 'fr',
          t2: 'ar',
          t1Score: 3,
          t2Score: 2,
          status: 'FINISHED',
          goals: [
            GoalEvent(team: 't1', scorer: 'Kylian Mbappé', assistant: 'Antoine Griezmann', minute: 28),
            GoalEvent(team: 't2', scorer: 'Lionel Messi', assistant: 'Ángel Di María', minute: 42),
            GoalEvent(team: 't2', scorer: 'Lautaro Martínez', assistant: 'Enzo Fernández', minute: 67),
            GoalEvent(team: 't1', scorer: 'Kylian Mbappé', assistant: 'Bradley Barcola', minute: 81),
            GoalEvent(team: 't1', scorer: 'Bradley Barcola', assistant: 'Kylian Mbappé', minute: 112),
          ],
        ),
      ];

      final stats = TournamentStats.compute(matches);

      // Scorers verification
      expect(stats.scorers.isNotEmpty, true);
      expect(stats.scorers.first.name, 'Kylian Mbappé');
      expect(stats.scorers.first.value, 2);
      expect(stats.scorers.first.teamCode, 'fr');

      // Assists verification
      expect(stats.assists.isNotEmpty, true);
      expect(stats.assists.length, 5);
      final assistsMap = {for (var p in stats.assists) p.name: p.value};
      expect(assistsMap['Antoine Griezmann'], 1);
      expect(assistsMap['Kylian Mbappé'], 1);
      expect(assistsMap['Bradley Barcola'], 1);
      expect(assistsMap['Enzo Fernández'], 1);
    });

    test('ignores own goals in scorers leaderboard', () {
      final matches = [
        WorldCupMatch(
          id: 'm2',
          date: DateTime.now(),
          t1: 'de',
          t2: 'es',
          t1Score: 1,
          t2Score: 1,
          status: 'FINISHED',
          goals: [
            GoalEvent(team: 't1', scorer: 'Unfortunate Defender', minute: 12, isOwnGoal: true),
            GoalEvent(team: 't2', scorer: 'Lamine Yamal', assistant: 'Pedri', minute: 45, isOwnGoal: false),
          ],
        ),
      ];

      final stats = TournamentStats.compute(matches);
      expect(stats.scorers.any((p) => p.name == 'Unfortunate Defender'), false);
      expect(stats.scorers.any((p) => p.name == 'Lamine Yamal'), true);
      expect(stats.assists.any((p) => p.name == 'Pedri'), true);
    });
  });
}
