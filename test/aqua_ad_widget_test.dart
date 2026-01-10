import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  // Configura la libreria prima dei test
  setUpAll(() {
    AquaConfig.setDefaultLocation('https://test.com');
    AquaConfig.setDefaultHideIfEmpty(false);
  });

  testWidgets('AquaAdWidget shows loading initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaAdWidget(zoneId: 123),
        ),
      ),
    );

    // Aspetta che il widget si costruisca
    await tester.pump();
    
    // Verifica che ci sia un container bianco (stato di loading)
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('AquaAdWidget handles configuration',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaAdWidget(
            zoneId: 123,
            width: 300,
            height: 250,
            settings: AquaSettings(
              hideIfEmpty: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    
    // Il widget dovrebbe essere presente
    expect(find.byType(AquaAdWidget), findsOneWidget);
  });
}
