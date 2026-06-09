import 'package:benchmark_harness/benchmark_harness.dart';

class DummyMatch {
  final String id;
  DummyMatch(this.id);
}

// 1. Current implementation (baseline) simulating a full build cycle
class UnoptimizedParserBenchmark extends BenchmarkBase {
  UnoptimizedParserBenchmark() : super('UnoptimizedParser');

  late List<DummyMatch> r32Matches;
  late List<DummyMatch> r16Matches;
  late List<DummyMatch> qfMatches;

  @override
  void setup() {
    // Generate matches
    r32Matches = List.generate(
      16,
      (i) => DummyMatch('m${i + 49}'),
    ); // m49 to m64
    r16Matches = List.generate(
      8,
      (i) => DummyMatch('m${i + 65}'),
    ); // m65 to m72
    qfMatches = List.generate(4, (i) => DummyMatch('m${i + 73}')); // m73 to m76
  }

  @override
  void run() {
    r32Matches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 49 && idNum <= 56;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r32Matches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 57 && idNum <= 64;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r16Matches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 65 && idNum <= 68;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r16Matches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 69 && idNum <= 72;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    qfMatches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 73 && idNum <= 74;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    qfMatches
        .where((m) {
          final idNum = int.tryParse(m.id.substring(1)) ?? 0;
          return idNum >= 75 && idNum <= 76;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));
  }
}

// 2. Optimized implementation simulating a full build cycle
class OptimizedParserBenchmark extends BenchmarkBase {
  OptimizedParserBenchmark() : super('OptimizedParser');

  late List<DummyMatch> r32Matches;
  late List<DummyMatch> r16Matches;
  late List<DummyMatch> qfMatches;

  static final Map<String, int> _idCache = {};
  static final RegExp _digitRegex = RegExp(r'\d+');

  static int _getParsedId(String id) {
    return _idCache.putIfAbsent(id, () {
      return int.tryParse(_digitRegex.firstMatch(id)?.group(0) ?? '0') ?? 0;
    });
  }

  @override
  void setup() {
    // Generate matches
    r32Matches = List.generate(
      16,
      (i) => DummyMatch('m${i + 49}'),
    ); // m49 to m64
    r16Matches = List.generate(
      8,
      (i) => DummyMatch('m${i + 65}'),
    ); // m65 to m72
    qfMatches = List.generate(4, (i) => DummyMatch('m${i + 73}')); // m73 to m76

    // Pre-warm the cache slightly or let it run, benchmark_harness runs setup once,
    // and run() 10 times to warm up, then repeatedly. So the cache WILL be warmed up
    // for the measured runs.
  }

  @override
  void run() {
    r32Matches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 49 && idNum <= 56;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r32Matches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 57 && idNum <= 64;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r16Matches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 65 && idNum <= 68;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    r16Matches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 69 && idNum <= 72;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    qfMatches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 73 && idNum <= 74;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));

    qfMatches
        .where((m) {
          final idNum = _getParsedId(m.id);
          return idNum >= 75 && idNum <= 76;
        })
        .toList()
        .sort((a, b) => a.id.compareTo(b.id));
  }
}

void main() {
  // print removed
  UnoptimizedParserBenchmark().report();
  OptimizedParserBenchmark().report();
}
