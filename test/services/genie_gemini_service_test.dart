import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mondial_2026/services/genie_gemini_service.dart';
import 'package:mondial_2026/models/match.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GenieGeminiService - Configuration', () {
    test('Defaults are correctly configured', () async {
      final key = await GenieGeminiService.getApiKey();
      final model = await GenieGeminiService.getModel();
      
      expect(key, isEmpty);
      expect(model, equals('gemini-2.5-flash'));
    });

    test('Saving and retrieving API Key and Model', () async {
      await GenieGeminiService.saveApiKey('test_key');
      await GenieGeminiService.saveModel('gemini-ultra');

      final key = await GenieGeminiService.getApiKey();
      final model = await GenieGeminiService.getModel();

      expect(key, equals('test_key'));
      expect(model, equals('gemini-ultra'));
    });
  });

  group('GenieGeminiService - Seeded Fallback Predictions', () {
    final match = WorldCupMatch(
      id: 'm1',
      date: DateTime.utc(2026, 6, 11, 20, 0),
      t1: 'fr',
      t2: 'ma',
      t1Score: null,
      t2Score: null,
      stage: 'Group Stage',
    );

    final List<WorldCupMatch> allMatches = [match];

    test('Seeded predictions are deterministic (same match ID produces identical result)', () async {
      final analysis1 = await GenieGeminiService.getMatchAnalysis('m1', match, allMatches, lang: 'fr');
      
      // Reset SharedPreferences mock to force regeneration from the same seed
      SharedPreferences.setMockInitialValues({});
      final analysis2 = await GenieGeminiService.getMatchAnalysis('m1', match, allMatches, lang: 'fr');

      expect(analysis1!.summaryLine, equals(analysis2!.summaryLine));
      expect(analysis1.confidenceScore, equals(analysis2.confidenceScore));
    });
  });

  group('GenieGeminiService - Behavior', () {
    final match = WorldCupMatch(
      id: 'm12',
      date: DateTime.utc(2026, 6, 12, 18, 0),
      t1: 'br',
      t2: 'de',
      t1Score: null,
      t2Score: null,
      stage: 'Group Stage',
    );

    final List<WorldCupMatch> allMatches = [match];

    test('Dynamic predictions generation and text validation', () async {
      final analysis = await GenieGeminiService.getMatchAnalysis('m12', match, allMatches, lang: 'en');
      
      expect(analysis, isNotNull);
      expect(analysis!.summaryLine, isNotEmpty);
      expect(analysis.rankingAnalysis, isNotEmpty);
      expect(analysis.oddsAnalysis, isNotEmpty);
      expect(analysis.confidenceScore, isPositive);
    });

    test('Bot PredictionData compiles correctly with points and champion', () async {
      final botData = await GenieGeminiService.loadBotData(allMatches, lang: 'fr');

      expect(botData.username, equals('Genie Gemini'));
      expect(botData.avatar, equals('🧠'));
      expect(botData.championCode, isNotNull);
      expect(botData.goldenBootPlayer, isNotNull);
      expect(botData.matchPredictions.containsKey('m12'), isTrue);
    });
  });
}
