import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('finishing asks for the code and goes straight to level 2', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMenu(tester);
    await tester.tap(find.text('Conjunction Theme Song'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(
      find.text('Level 1 done! Ask your teacher for the code.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'BRIDGE2');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play level 2'));
    await tester.pumpAndSettle();

    expect(find.text('Building the bridge'), findsOneWidget);
  });

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
