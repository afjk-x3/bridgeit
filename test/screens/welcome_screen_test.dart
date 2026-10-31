import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const _go = "Let's get started, Bridge Builder!";

Future<void> _openForm(WidgetTester tester) async {
  await openMenu(tester);
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new student sees the greeting, then the form', (tester) async {
    await pumpApp(tester, newStudent: true);
    await openMenu(tester);

    expect(find.textContaining('Hi, Bridge Builder!'), findsOneWidget);
    expect(find.text(_go), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text(_go), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('name and section are both required', (tester) async {
    await pumpApp(tester, newStudent: true);
    await _openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.enterText(find.byType(TextFormField).last, '   ');
    await tester.tap(find.text(_go));
    await tester.pumpAndSettle();

    expect(find.text('Please fill this in.'), findsOneWidget);
    expect(find.text('Choose a level'), findsNothing);
  });

  testWidgets('a saved profile opens the menu and is never asked again', (
    tester,
  ) async {
    await pumpApp(tester, newStudent: true);
    await _openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.enterText(find.byType(TextFormField).last, 'Grade 7');
    await tester.tap(find.text(_go));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await openMenu(tester);
    expect(find.text('Choose a level'), findsOneWidget);
  });

  testWidgets('fits a 360x640 phone', (tester) async {
    await pumpApp(tester, newStudent: true);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    await openMenu(tester);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Next').hitTestable(), findsOneWidget);
  });
}
