import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/screens/level1_screen.dart';

import '../support/pump_app.dart';

const _hint = 'Not quite. Try again!';
const _done = 'Level 1 done! Ask your teacher for the code.';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _place(WidgetTester tester, int blank, String word) async {
  await _tap(tester, find.byKey(ValueKey('word-$word')));
  await _tap(tester, find.byKey(ValueKey('blank-$blank')));
}

/// The blank answers of one verse, in order, from the app's own content.
List<String> _answers(WidgetTester tester, int verse) {
  final content = tester.element(find.byType(Level1Screen)).read<GameContent>();
  return [
    for (final line in content.level1.verses[verse].lines)
      for (final part in line)
        if (part is BlankPart) part.answer,
  ];
}

Future<void> _openLevel1(WidgetTester tester) async {
  await pumpApp(tester);
  await openMenu(tester);
  await tester.tap(find.text('Conjunction song'));
  await tester.pumpAndSettle();
}

Future<void> _fillVerse(WidgetTester tester, int verse, int firstBlank) async {
  final answers = _answers(tester, verse);
  for (var i = 0; i < answers.length; i++) {
    await _place(tester, firstBlank + i, answers[i].toLowerCase());
  }
}

void main() {
  testWidgets('shows both steps, the first verse and the 7 word bank', (
    tester,
  ) async {
    await _openLevel1(tester);

    expect(find.text('1 · Listen'), findsOneWidget);
    expect(find.text('2 · Fill in the blanks'), findsOneWidget);
    expect(find.text('Song coming soon'), findsOneWidget);
    expect(find.text('Verse 1 of 2'), findsOneWidget);
    for (final word in fanboys) {
      expect(find.byKey(ValueKey('word-$word')), findsOneWidget);
    }
  });

  testWidgets('word bank words and blanks are at least 48dp', (tester) async {
    await _openLevel1(tester);

    for (final key in [const ValueKey('word-so'), const ValueKey('blank-0')]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('tapping a blank with no word selected does nothing', (
    tester,
  ) async {
    await _openLevel1(tester);

    await _tap(tester, find.byKey(const ValueKey('blank-0')));

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text(_hint), findsNothing);
  });

  testWidgets('wrong word shows the hint and can retry; right word fills', (
    tester,
  ) async {
    await _openLevel1(tester);
    final answer = _answers(tester, 0).first.toLowerCase();
    final wrong = fanboys.firstWhere((w) => w != answer);

    await _place(tester, 0, wrong);
    expect(find.text(_hint), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await _place(tester, 0, wrong);
    await _place(tester, 0, answer);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text(_hint), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('blank-0')),
        matching: find.text(answer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a capitalized blank is filled by the lowercase word', (
    tester,
  ) async {
    await _openLevel1(tester);
    await _fillVerse(tester, 0, 0);
    await _tap(tester, find.text('Next verse'));
    // Verse 2 opens with the blank {And}.
    await _place(tester, 7, 'and');

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('blank-7')),
        matching: find.text('And'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('next verse waits for every blank, last verse says Finish', (
    tester,
  ) async {
    await _openLevel1(tester);
    FilledButton button() => tester.widget(find.byType(FilledButton));

    expect(find.text('Next verse'), findsOneWidget);
    expect(button().onPressed, isNull);
    await _fillVerse(tester, 0, 0);
    expect(button().onPressed, isNotNull);

    await _tap(tester, find.text('Next verse'));
    expect(find.text('Verse 2 of 2'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(button().onPressed, isNull);
    await _fillVerse(tester, 1, 7);
    expect(button().onPressed, isNotNull);
  });

  testWidgets('finishing marks level 1 done and returns to the menu', (
    tester,
  ) async {
    await _openLevel1(tester);
    final progress = tester
        .element(find.byType(Level1Screen))
        .read<ProgressStore>();
    expect(progress.isCompleted(1), isFalse);

    await _fillVerse(tester, 0, 0);
    await _tap(tester, find.text('Next verse'));
    await _fillVerse(tester, 1, 7);
    await _tap(tester, find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text(_done), findsOneWidget);
    expect(progress.isCompleted(1), isTrue);

    await _tap(tester, find.text('Back to levels'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
