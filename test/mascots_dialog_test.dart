import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/widgets/mascots_dialog.dart';

void main() {
  testWidgets('WCMascotsDialog builds and displays mascots', (
    WidgetTester tester,
  ) async {
    // Build the dialog within a MaterialApp
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WCMascotsDialog(lang: 'en')),
      ),
    );

    // Verify header title
    expect(find.text('Official Mascots'), findsOneWidget);

    // Verify mascot Maple is visible initially
    expect(find.text('Maple'), findsOneWidget);
    expect(
      find.text('Goalkeeper & Creative Artist'.toUpperCase()),
      findsOneWidget,
    );

    // Verify button to watch video
    expect(find.text('Watch Official Trailer'), findsOneWidget);
  });
}
