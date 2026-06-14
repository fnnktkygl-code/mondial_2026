import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/notification_service.dart';

void main() {
  group('WCNotificationService score formatting', () {
    test('French score formatting contains team names and flags', () {
      final formatted = WCNotificationService.formatScoreNotificationBody(
        lang: 'fr',
        t1Code: 'fr',
        t2Code: 'br',
        t1Score: 2,
        t2Score: 1,
        isFinished: true,
      );

      // Verify that it contains flags/emojis and team names or nicknames
      expect(formatted, contains('🇫🇷'));
      expect(formatted, contains('🇧🇷'));
    });

    test('English score formatting contains correct indicators', () {
      final formatted = WCNotificationService.formatScoreNotificationBody(
        lang: 'en',
        t1Code: 'mx',
        t2Code: 'us',
        t1Score: 2,
        t2Score: 2,
        isFinished: true,
      );

      expect(formatted, contains('🇲🇽'));
      expect(formatted, contains('🇺🇸'));
    });
  });
}
