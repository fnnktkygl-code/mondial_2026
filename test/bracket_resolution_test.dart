import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/models/match.dart';
import 'package:mondial_2026/utils/fifa_rules.dart';

void main() {
  group('104 Matches Dataset & Bracket Resolution Tests', () {
    late List<WorldCupMatch> matches;

    setUp(() {
      final file = File('assets/initial_matches.json');
      final jsonList = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      matches = jsonList.map((m) => WorldCupMatch.fromJson(m as Map<String, dynamic>)).toList();
    });

    test('All 104 matches exist and are marked FINISHED', () {
      expect(matches.length, 104);
      final finishedCount = matches.where((m) => m.isPlayed && m.isFinished).length;
      expect(finishedCount, 104);
    });

    test('72 Group stage matches have valid scores and groups A to L', () {
      final groupMatches = matches.where((m) => !m.isKnockout).toList();
      expect(groupMatches.length, 72);
      
      final groups = groupMatches.map((m) => m.group).toSet();
      expect(groups.containsAll(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']), true);
    });

    test('32 Knockout stage matches are complete from R32 to Final without TBD', () {
      final knockoutMatches = matches.where((m) => m.isKnockout).toList();
      expect(knockoutMatches.length, 32);

      for (final m in knockoutMatches) {
        expect(m.t1 != 'TBD' && m.t1.isNotEmpty, true, reason: 'Match ${m.id} t1 is TBD');
        expect(m.t2 != 'TBD' && m.t2.isNotEmpty, true, reason: 'Match ${m.id} t2 is TBD');
        expect(m.t1Score != null, true, reason: 'Match ${m.id} t1Score is null');
        expect(m.t2Score != null, true, reason: 'Match ${m.id} t2Score is null');
        expect(m.getWinner().isNotEmpty, true, reason: 'Match ${m.id} has no winner');
      }
    });

    test('FIFARegulations.resolveMatchesPlaceholders produces completely resolved teams for all 32 knockout matches', () {
      final resolved = FIFARegulations.resolveMatchesPlaceholders(matches);
      final knockout = resolved.where((m) => m.isKnockout).toList();
      expect(knockout.length, 32);

      for (final m in knockout) {
        expect(m.t1.startsWith('w') || m.t1.startsWith('l') || m.t1.startsWith('3rd') || m.t1 == 'TBD', false,
            reason: 'Match ${m.id} t1 is unresolved placeholder: ${m.t1}');
        expect(m.t2.startsWith('w') || m.t2.startsWith('l') || m.t2.startsWith('3rd') || m.t2 == 'TBD', false,
            reason: 'Match ${m.id} t2 is unresolved placeholder: ${m.t2}');
        expect(m.getWinner().isNotEmpty, true, reason: 'Match ${m.id} has no winner');
      }
    });

    test('Topological Invariance: Every knockout match strictly features the verified winners/losers of its parent matches', () {
      final matchMap = {for (final m in matches) m.id: m};
      final routing = FIFARegulations.knockoutRouting;

      for (final entry in routing.entries) {
        final matchId = entry.key;
        final parentCodes = entry.value;
        final currentMatch = matchMap[matchId]!;

        // Resolve expected team 1
        String expectedT1;
        if (parentCodes[0].startsWith('w')) {
          final parentId = 'm${parentCodes[0].substring(1)}';
          expectedT1 = matchMap[parentId]!.getWinner();
        } else if (parentCodes[0].startsWith('l')) {
          final parentId = 'm${parentCodes[0].substring(1)}';
          final parent = matchMap[parentId]!;
          expectedT1 = parent.getWinner() == parent.t1 ? parent.t2 : parent.t1;
        } else {
          continue; // Group placeholder
        }

        // Resolve expected team 2
        String expectedT2;
        if (parentCodes[1].startsWith('w')) {
          final parentId = 'm${parentCodes[1].substring(1)}';
          expectedT2 = matchMap[parentId]!.getWinner();
        } else if (parentCodes[1].startsWith('l')) {
          final parentId = 'm${parentCodes[1].substring(1)}';
          final parent = matchMap[parentId]!;
          expectedT2 = parent.getWinner() == parent.t1 ? parent.t2 : parent.t1;
        } else {
          continue; // Group placeholder
        }

        final actualTeams = {currentMatch.t1.toLowerCase(), currentMatch.t2.toLowerCase()};
        final expectedTeams = {expectedT1.toLowerCase(), expectedT2.toLowerCase()};

        expect(actualTeams, equals(expectedTeams),
            reason: 'Match $matchId (${currentMatch.stage}) has topological mismatch! Expected $expectedTeams from parents, but found $actualTeams');
      }
    });

    test('Final match m104 crowns Spain as World Champion and Argentina as Finalist', () {
      final finalMatch = matches.firstWhere((m) => m.id == 'm104');
      expect(finalMatch.stage, 'Final');
      expect(finalMatch.isPlayed, true);
      expect(finalMatch.getWinner(), 'es');
      expect({finalMatch.t1.toLowerCase(), finalMatch.t2.toLowerCase()}, equals({'es', 'ar'}));
    });

    test('3rd place match m103 features France vs England with France winning', () {
      final thirdMatch = matches.firstWhere((m) => m.id == 'm103');
      expect(thirdMatch.stage, 'Play-off for third place');
      expect(thirdMatch.isPlayed, true);
      expect(thirdMatch.getWinner(), 'fr');
      expect({thirdMatch.t1.toLowerCase(), thirdMatch.t2.toLowerCase()}, equals({'fr', 'en'}));
    });
  });
}
