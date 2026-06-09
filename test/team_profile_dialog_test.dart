import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/team_profile_service.dart';
import 'package:mondial_2026/widgets/team_profile_dialog.dart';

void main() {
  testWidgets('WCTeamProfileDialog renders', (WidgetTester tester) async {
    // Manually load or mock media map to ensure 'de' has the preview image
    await WCTeamProfileService.loadMediaMap();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Pump WCTeamProfileDialog for Germany 'de'
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WCTeamProfileDialog(teamCode: 'de', lang: 'fr'),
        ),
      ),
    );

    // Verify the dialog elements are shown
    expect(find.byType(WCTeamProfileDialog), findsOneWidget);
  });
}
