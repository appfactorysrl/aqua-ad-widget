import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  testWidgets('AquaAdWidget shows loading initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaAdWidget(zoneId: 123),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
