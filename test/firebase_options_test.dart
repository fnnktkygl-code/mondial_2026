import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('returns macos config for iOS platform', () {
      // It's a little tricky to mock defaultTargetPlatform directly in a normal unit test
      // because it's determined by the environment.
      // However, we can use debugDefaultTargetPlatformOverride to test the switch statement.

      final originalPlatform = debugDefaultTargetPlatformOverride;

      try {
        // Force the platform to iOS
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        // When we get currentPlatform, it should return the macos config
        final options = DefaultFirebaseOptions.currentPlatform;

        expect(options.appId, equals(DefaultFirebaseOptions.macos.appId));
        expect(
          options.iosBundleId,
          equals(DefaultFirebaseOptions.macos.iosBundleId),
        );
        expect(options, equals(DefaultFirebaseOptions.macos));
      } finally {
        // Restore the original platform
        debugDefaultTargetPlatformOverride = originalPlatform;
      }
    });

    test('returns android config for android platform', () {
      final originalPlatform = debugDefaultTargetPlatformOverride;

      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final options = DefaultFirebaseOptions.currentPlatform;
        expect(options, equals(DefaultFirebaseOptions.android));
      } finally {
        debugDefaultTargetPlatformOverride = originalPlatform;
      }
    });

    test('throws UnsupportedError for windows platform', () {
      final originalPlatform = debugDefaultTargetPlatformOverride;

      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsUnsupportedError,
        );
      } finally {
        debugDefaultTargetPlatformOverride = originalPlatform;
      }
    });
  });
}
