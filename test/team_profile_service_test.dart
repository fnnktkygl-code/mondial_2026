import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/team_profile_service.dart';

void main() {
  group('WCTeamProfileService - FIFA World Ranking Tests', () {
    test('returns correct FIFA ranking for major teams', () {
      final fr = WCTeamProfileService.getProfile('fr', 'fr');
      expect(fr.fifaRanking, equals(1));
      expect(fr.profileUrl, contains('/teams/france'));

      final es = WCTeamProfileService.getProfile('es', 'en');
      expect(es.fifaRanking, equals(2));
      expect(es.profileUrl, contains('/teams/spain'));

      final ar = WCTeamProfileService.getProfile('ar', 'es');
      expect(ar.fifaRanking, equals(3));
      expect(ar.profileUrl, contains('/teams/argentina'));

      final ca = WCTeamProfileService.getProfile('ca', 'en');
      expect(ca.fifaRanking, equals(30));
      expect(ca.profileUrl, contains('/teams/canada'));
    });

    test('returns fallback 999 for unknown teams', () {
      final unknown = WCTeamProfileService.getProfile('unknown_code', 'en');
      expect(unknown.fifaRanking, equals(999));
      expect(unknown.profileUrl, contains('unknown_code'));
    });
  });
}
