import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondial_2026/services/team_profile_service.dart';
import 'package:mondial_2026/widgets/team_profile_dialog.dart';

void main() {
  testWidgets('WCTeamProfileDialog renders preview image for Germany', (WidgetTester tester) async {
    // Manually load or mock media map to ensure 'de' has the preview image
    await WCTeamProfileService.loadMediaMap();

    // Pump WCTeamProfileDialog for Germany 'de'
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WCTeamProfileDialog(
            teamCode: 'de',
            lang: 'fr',
          ),
        ),
      ),
    );

    // Verify the dialog elements are shown
    expect(find.byType(WCTeamProfileDialog), findsOneWidget);
    
    // Find the media card image
    final imageFinder = find.byType(Image);
    bool foundPreview = false;
    for (final element in imageFinder.evaluate()) {
      final widget = element.widget as Image;
      if (widget.image is AssetImage) {
        final assetImage = widget.image as AssetImage;
        if (assetImage.assetName == 'assets/logos/de_preview.png') {
          foundPreview = true;
        }
      }
    }
    expect(foundPreview, isTrue);
  });
}
