import 'package:benchmark_harness/benchmark_harness.dart';
import '../../lib/models/match.dart';

class MockMatch extends WorldCupMatch {
  MockMatch(String id, String stage)
    : super(id: id, stage: stage, date: DateTime.now(), t1: 'a', t2: 'b');
}

final List<WorldCupMatch> allMatches = [
  for (var i = 1; i <= 48; i++) MockMatch('m$i', 'Group Stage'),
  for (var i = 49; i <= 64; i++) MockMatch('m$i', 'Round of 32'),
  for (var i = 65; i <= 72; i++) MockMatch('m$i', 'Round of 16'),
  for (var i = 73; i <= 76; i++) MockMatch('m$i', 'Quarter-Final'),
  for (var i = 77; i <= 78; i++) MockMatch('m$i', 'Semi-Final'),
  MockMatch('m79', 'Third Place'),
  MockMatch('m80', 'Final'),
];

final r32Matches = allMatches.where((m) => m.stage == 'Round of 32').toList()
  ..sort((a, b) => a.id.compareTo(b.id));
final r16Matches = allMatches.where((m) => m.stage == 'Round of 16').toList()
  ..sort((a, b) => a.id.compareTo(b.id));
final qfMatches = allMatches.where((m) => m.stage == 'Quarter-Final').toList()
  ..sort((a, b) => a.id.compareTo(b.id));
final sfMatches = allMatches.where((m) => m.stage == 'Semi-Final').toList()
  ..sort((a, b) => a.id.compareTo(b.id));

class BaselineFilterBenchmark extends BenchmarkBase {
  BaselineFilterBenchmark() : super('BaselineFilterBenchmark');

  @override
  void run() {
    final leftR32 = r32Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 49 && idNum <= 56;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightR32 = r32Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 57 && idNum <= 64;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftR16 = r16Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 65 && idNum <= 68;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightR16 = r16Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 69 && idNum <= 72;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftQF = qfMatches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 73 && idNum <= 74;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightQF = qfMatches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 75 && idNum <= 76;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftSF = sfMatches.where((m) => m.id == 'm77').toList();
    final rightSF = sfMatches.where((m) => m.id == 'm78').toList();
  }
}

int _fastParseId(String id) {
  for (int i = 0; i < id.length; i++) {
    final code = id.codeUnitAt(i);
    if (code >= 48 && code <= 57) {
      // ASCII '0'-'9'
      return int.tryParse(id.substring(i)) ?? 0;
    }
  }
  return 0;
}

class OptimizedFilterBenchmark extends BenchmarkBase {
  OptimizedFilterBenchmark() : super('OptimizedFilterBenchmark');

  @override
  void run() {
    final List<WorldCupMatch> leftR32 = [];
    final List<WorldCupMatch> rightR32 = [];
    for (final m in r32Matches) {
      final idNum = _fastParseId(m.id);
      if (idNum >= 49 && idNum <= 56) {
        leftR32.add(m);
      } else if (idNum >= 57 && idNum <= 64) {
        rightR32.add(m);
      }
    }

    final List<WorldCupMatch> leftR16 = [];
    final List<WorldCupMatch> rightR16 = [];
    for (final m in r16Matches) {
      final idNum = _fastParseId(m.id);
      if (idNum >= 65 && idNum <= 68) {
        leftR16.add(m);
      } else if (idNum >= 69 && idNum <= 72) {
        rightR16.add(m);
      }
    }

    final List<WorldCupMatch> leftQF = [];
    final List<WorldCupMatch> rightQF = [];
    for (final m in qfMatches) {
      final idNum = _fastParseId(m.id);
      if (idNum >= 73 && idNum <= 74) {
        leftQF.add(m);
      } else if (idNum >= 75 && idNum <= 76) {
        rightQF.add(m);
      }
    }

    final List<WorldCupMatch> leftSF = [];
    final List<WorldCupMatch> rightSF = [];
    for (final m in sfMatches) {
      final idNum = _fastParseId(m.id);
      if (idNum == 77) {
        leftSF.add(m);
      } else if (idNum == 78) {
        rightSF.add(m);
      }
    }
  }
}

void main() {
  BaselineFilterBenchmark().report();
  OptimizedFilterBenchmark().report();
}
