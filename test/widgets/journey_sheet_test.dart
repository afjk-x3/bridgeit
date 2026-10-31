import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('map icon opens the journey with levels done and the car', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {
        'unlocked_levels': ['2'],
        'completed_levels': ['1'],
      },
    );
    await openMenu(tester);
    await tester.tap(find.text('Building Bridges'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Journey'));
    await tester.pumpAndSettle();

    expect(find.text('Your journey'), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-car')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Travelogue'), findsOneWidget);
  });
}
