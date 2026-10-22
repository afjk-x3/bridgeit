import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  const wrongCode = "That code didn't work. Check with your teacher.";

  testWidgets('locked level cannot be opened', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);

    await tester.tap(find.text('Strengthening the bridge'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a level'), findsOneWidget);
    expect(find.text('Level 3 is coming soon'), findsNothing);
  });

  testWidgets('unlocked level opens its route', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);

    await tester.tap(find.text('Conjunction song'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1 is coming soon'), findsOneWidget);
  });

  testWidgets('entering the right code unlocks level 2', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);
    expect(find.text('Play level 2'), findsNothing);

    await tester.enterText(find.byType(TextField), 'bridge2');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Play level 2'), findsOneWidget);
    expect(find.text('Level 2 unlocked!'), findsOneWidget);
    expect(find.text(wrongCode), findsNothing);
  });

  testWidgets('wrong code shows an error and keeps the text', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);

    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text(wrongCode), findsOneWidget);
    expect(find.text('NOPE'), findsOneWidget);
    expect(find.text('Play level 2'), findsNothing);
  });

  testWidgets('code only unlocks the lowest locked level', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);

    await tester.enterText(find.byType(TextField), 'BRIDGE3');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text(wrongCode), findsOneWidget);
    expect(find.text('Play level 3'), findsNothing);
  });

  testWidgets('code section is hidden once levels 2 and 3 are unlocked', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {
        'unlocked_levels': ['2', '3'],
        'completed_levels': ['1'],
      },
    );
    await openMenu(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Unlock'), findsNothing);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Play level 3'), findsOneWidget);
  });

  testWidgets('back button returns to the intro', (tester) async {
    await pumpApp(tester);
    await openMenu(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text("Let's start"), findsOneWidget);
  });
}
