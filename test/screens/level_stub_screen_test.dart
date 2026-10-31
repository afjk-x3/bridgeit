import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('level 3 has no next level to unlock', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'unlocked_levels': ['3'],
      },
    );
    await openMenu(tester);
    await tester.tap(find.text('Travelogue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Back to levels'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
