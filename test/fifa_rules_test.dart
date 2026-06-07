import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/models/match.dart';
import 'package:mondial_2026/utils/fifa_rules.dart';
import 'package:mondial_2026/widgets/group_table.dart';

void main() {
  group('FIFARegulations Card Deduction Tests', () {
    test('Yellow card is -1 point', () {
      expect(FIFARegulations.calculateDisciplinaryDeduction(1, 0), 1);
      expect(FIFARegulations.calculateDisciplinaryDeduction(3, 0), 3);
    });

    test('Direct red card is -4 points', () {
      expect(FIFARegulations.calculateDisciplinaryDeduction(0, 1), 4);
    });

    test('Indirect red card (2 yellows) is -3 points', () {
      // 2 yellows and 1 red represents 1 indirect red card
      expect(FIFARegulations.calculateDisciplinaryDeduction(2, 1), 3);
      // 3 yellows and 1 red represents 1 indirect red (-3) and 1 yellow (-1) = -4
      expect(FIFARegulations.calculateDisciplinaryDeduction(3, 1), 4);
    });

    test('Yellow card + direct red is -5 points', () {
      // 1 yellow and 1 red represents 1 yellow + 1 direct red = -5
      expect(FIFARegulations.calculateDisciplinaryDeduction(1, 1), 5);
    });
  });

  group('FIFARegulations Standings Sorting Tests', () {
    test('Sorts by overall points', () {
      final teams = [
        GroupEntry('A')..wins = 1, // 3 points
        GroupEntry('B')..wins = 2, // 6 points
      ];
      FIFARegulations.sortStandings(teams, []);
      expect(teams[0].teamCode, 'B');
      expect(teams[1].teamCode, 'A');
    });

    test('Sorts by goal difference', () {
      final teams = [
        GroupEntry('A')
          ..wins = 1
          ..goalsFor = 2
          ..goalsAgainst = 1, // +1 GD
        GroupEntry('B')
          ..wins = 1
          ..goalsFor = 3
          ..goalsAgainst = 1, // +2 GD
      ];
      FIFARegulations.sortStandings(teams, []);
      expect(teams[0].teamCode, 'B');
      expect(teams[1].teamCode, 'A');
    });

    test('Sorts by goals scored', () {
      final teams = [
        GroupEntry('A')
          ..wins = 1
          ..goalsFor = 2
          ..goalsAgainst = 1, // 2 GF
        GroupEntry('B')
          ..wins = 1
          ..goalsFor = 3
          ..goalsAgainst = 2, // 3 GF
      ];
      FIFARegulations.sortStandings(teams, []);
      expect(teams[0].teamCode, 'B');
      expect(teams[1].teamCode, 'A');
    });

    test('Sorts by head-to-head points', () {
      final teams = [
        GroupEntry('US')
          ..played = 2
          ..wins = 1
          ..goalsFor = 2
          ..goalsAgainst = 2, // 3 pts, 0 GD, 2 GF
        GroupEntry('MX')
          ..played = 2
          ..wins = 1
          ..goalsFor = 2
          ..goalsAgainst = 2, // 3 pts, 0 GD, 2 GF
      ];

      // Match where US beats MX
      final matches = [
        WorldCupMatch(
          id: '1',
          date: DateTime.now(),
          t1: 'US',
          t2: 'MX',
          t1Score: 1,
          t2Score: 0,
          status: 'FINISHED',
          group: 'A',
        ),
      ];

      FIFARegulations.sortStandings(teams, matches);
      expect(teams[0].teamCode, 'US');
      expect(teams[1].teamCode, 'MX');
    });
  });
}
