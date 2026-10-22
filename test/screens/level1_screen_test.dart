import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/screens/level1_screen.dart';
import 'package:bridgeit/widgets/hint_card.dart';

import '../support/pump_app.dart';

const _hint = 'Not quite. Try again!';
const _prompt = 'Type the missing word in each blank.';
const _done = 'Level 1 done! Ask your teacher for the code.';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Types [word] straight into the blank's text field.
Future<void> _place(WidgetTester tester, int blank, String word) async {
  final field = find.byKey(ValueKey('blank-$blank'));
  await tester.ensureVisible(field);
  await tester.enterText(field, word);
  await tester.pumpAndSettle();
}

/// The header label for a verse, e.g. "Verse 2: The FANBOYS" → "LEVEL 1 · VERSE 2".
String _header(String title) =>
    'LEVEL 1 · ${title.split(':').first.trim().toUpperCase()}';

/// The blank answers of one verse, in order, from the app's own content.
List<String> _answers(WidgetTester tester, int verse) {
  final content = tester.element(find.byType(Level1Screen)).read<GameContent>();
  return [
    for (final line in content.level1.verses[verse].lines)
      for (final part in line)
        if (part is BlankPart) part.answer,
  ];
}

String _title(WidgetTester tester, int verse) => tester
    .element(find.byType(Level1Screen))
    .read<GameContent>()
    .level1
    .verses[verse]
    .title;

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
  testWidgets('shows both steps and the first verse, with no word bank', (
    tester,
  ) async {
    await _openLevel1(tester);

    expect(find.text('1 · Listen'), findsOneWidget);
    expect(find.text('2 · Fill in the blanks'), findsOneWidget);
    expect(find.text('Song coming soon'), findsOneWidget);
    for (final word in fanboys) {
      expect(find.byKey(ValueKey('word-$word')), findsNothing);
    }
  });

  testWidgets('header uses the same verse number as the card title', (
    tester,
  ) async {
    await _openLevel1(tester);
    final title = _title(tester, 0);

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text(_header(title)), findsOneWidget);
    expect(find.textContaining('PART'), findsNothing);
    expect(find.text('Conjunction song'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
  });

  testWidgets('blanks are text fields at least 48dp, with no pop-up menu', (
    tester,
  ) async {
    await _openLevel1(tester);
    final blank = find.byKey(const ValueKey('blank-0'));

    expect(tester.widget(blank), isA<TextField>());
    final size = tester.getSize(blank);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('a partly typed word gets no verdict yet', (tester) async {
    await _openLevel1(tester);
    final answer = _answers(tester, 0).first.toLowerCase();

    await _place(tester, 0, answer.substring(0, answer.length - 1));

    expect(find.text(_hint), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('wrong word shows the hint and can retry; right word fills', (
    tester,
  ) async {
    await _openLevel1(tester);
    final answer = _answers(tester, 0).first.toLowerCase();
    final wrong = fanboys.firstWhere((w) => w != answer);
    expect(find.text(_prompt), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);

    await _place(tester, 0, wrong);
    // The instruction goes away once the first placement is attempted.
    expect(find.text(_prompt), findsNothing);
    expect(find.text(_hint), findsOneWidget);
    expect(
      find.ancestor(of: find.text(_hint), matching: find.byType(HintCard)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await _place(tester, 0, wrong);
    await _place(tester, 0, answer);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text(_hint), findsNothing);
    expect(find.text(_prompt), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('blank-0')),
        matching: find.text(answer),
      ),
      findsOneWidget,
    );

    // A filled blank is final: it is no longer a text field.
    expect(tester.widget(find.byKey(const ValueKey('blank-0'))), isNot(isA<TextField>()));
  });

  testWidgets('typed words ignore case and surrounding spaces', (tester) async {
    await _openLevel1(tester);
    final answer = _answers(tester, 0).first;

    await _place(tester, 0, '  ${answer.toUpperCase()} ');

    expect(find.byIcon(Icons.check), findsOneWidget);
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
    expect(find.text('Finish'), findsOneWidget);
    expect(button().onPressed, isNull);
    await _fillVerse(tester, 1, 7);
    expect(button().onPressed, isNotNull);

    // The list is still scrolled down; the header follows the verse.
    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
    await tester.pump();
    expect(find.text(_header(_title(tester, 1))), findsOneWidget);
    expect(find.text(_title(tester, 1)), findsOneWidget);
    expect(find.text(_title(tester, 0)), findsNothing);
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

  testWidgets('finishing asks for the code and goes straight to level 2', (
    tester,
  ) async {
    await _openLevel1(tester);
    await _fillVerse(tester, 0, 0);
    await _tap(tester, find.text('Next verse'));
    await _fillVerse(tester, 1, 7);
    await _tap(tester, find.text('Finish'));

    expect(find.text('Got a code from your teacher?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'bridge2');
    await _tap(tester, find.text('Unlock'));

    expect(find.text('Level 2 unlocked!'), findsWidgets);
    await _tap(tester, find.text('Play level 2'));
    expect(find.text('Building the bridge'), findsOneWidget);
  });
}
