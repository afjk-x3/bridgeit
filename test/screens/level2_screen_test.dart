import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/sentence_checker.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/progress/results_store.dart';
import 'package:bridgeit/screens/level2_screen.dart';
import 'package:bridgeit/widgets/bridge_scene.dart';
import 'package:bridgeit/widgets/conjunction_piece.dart';
import 'package:bridgeit/widgets/writing_panel.dart';

import '../support/pump_app.dart';

const _broke = "The bridge collapsed! Let's try this bridge again.";
const _done = 'Level 2 done! Ask your teacher for the code.';
const _sturdy = 'Now the bridge seems sturdy. I can finally cross!';
const _factsTask = 'Task: Use one of these words to write another sentence.';
const _animals = ['dog', 'cat', 'bird', 'horse', 'pig', 'duck', 'goat'];

final _gap = find.byKey(const ValueKey('gap'));
Finder _piece(String word) => find.byKey(ValueKey('piece-$word'));

Future<void> _open(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  await pumpApp(
    tester,
    prefs: {
      'unlocked_levels': ['2'],
      ...prefs,
    },
  );
  await openMenu(tester);
  await tester.tap(find.text('Building Bridges'));
  await tester.pumpAndSettle();
}

Future<void> _openBridge(WidgetTester tester) async {
  await _open(tester);
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

GameContent _game(WidgetTester tester) =>
    tester.element(find.byType(Level2Screen)).read<GameContent>();

Bridge _first(WidgetTester tester) => _game(tester).level2.bridges.first;

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _tryPiece(WidgetTester tester, String word) async {
  await tester.tap(_piece(word));
  await tester.pump();
  await tester.tap(_gap);
  await tester.pump();
  await _tap(tester, 'Cross the bridge');
}

Future<void> _write(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await _tap(tester, 'Submit');
}

String _sentence(int i, String word) {
  final (a, b) = (_animals[i], _animals[(i + 1) % 7]);
  return word == 'nor'
      ? 'The $a did not run, nor did the $b sit.'
      : 'The $a ran far, $word the $b sat down.';
}

String _similar(int i, QuickFact fact) {
  final (a, b) = (_animals[i], _animals[(i + 1) % 7]);
  return fact.rule == QuickFactRule.linking
      ? 'The $a ran far; ${fact.word}, the $b sat down.'
      : 'The $a ran far ${fact.word} the $b sat down.';
}

/// Plays one bridge from the tray to the far cliff.
Future<void> _playBridge(WidgetTester tester, int i) async {
  final game = _game(tester);
  final bridge = game.level2.bridges[i];
  await _tryPiece(tester, bridge.conjunction);
  await _tap(tester, 'Strengthen the Bridge');
  await _write(tester, _sentence(i, bridge.conjunction));
  final facts = game.quickFacts[bridge.conjunction];
  if (facts != null) {
    await _write(tester, _similar(i, facts.last));
  }
  await _tap(tester, 'Cross the Bridge');
}

bool _enabled(WidgetTester tester, String word) =>
    tester.widget<ConjunctionPiece>(_piece(word)).enabled;

Finder _inBar(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

bool _crossEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Cross the bridge'))
    .enabled;

void main() {
  testWidgets('starts with the story, then the first bridge', (tester) async {
    await _open(tester);
    expect(find.textContaining('Oh no! The bridge is broken'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final first = _first(tester);
    expect(_inBar('LEVEL 2 · BRIDGE 1 OF 7'), findsOneWidget);
    expect(find.text('Building Bridges'), findsOneWidget);
    expect(find.byTooltip('Journey'), findsOneWidget);
    expect(
      find.bySemanticsLabel('${first.left}, _____ ${first.right}'),
      findsOneWidget,
    );
    for (final clause in [first.left, first.right]) {
      expect(
        find.descendant(
          of: find.byType(BridgeScene),
          matching: find.text(clause),
        ),
        findsOneWidget,
      );
    }
    expect(_crossEnabled(tester), isFalse);
    for (final word in fanboys) {
      expect(_enabled(tester, word), isTrue, reason: word);
    }
  });

  testWidgets('dragging a piece fills the gap until Cross is pressed', (
    tester,
  ) async {
    await _openBridge(tester);
    final word = _first(tester).conjunction;

    await tester.timedDrag(
      _piece(word),
      tester.getCenter(_gap) - tester.getCenter(_piece(word)),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: _gap, matching: find.text(', $word')),
      findsOneWidget,
    );
    expect(_crossEnabled(tester), isTrue);
    expect(find.text('Strengthen the Bridge'), findsNothing);
  });

  testWidgets('a wrong piece stays in the gap with its hint', (tester) async {
    await _openBridge(tester);
    final bridge = _first(tester);
    final wrong = bridge.hints.keys.first;

    await _tryPiece(tester, wrong);

    expect(
      find.descendant(of: _gap, matching: find.text(', $wrong')),
      findsOneWidget,
    );
    expect(find.text(bridge.hints[wrong]!), findsOneWidget);
    expect(_enabled(tester, wrong), isFalse);
    expect(_enabled(tester, bridge.conjunction), isTrue);
    expect(find.bySemanticsLabel('Bridge cracked'), findsOneWidget);
    expect(_crossEnabled(tester), isFalse);
  });

  testWidgets('another piece replaces the wrong one', (tester) async {
    await _openBridge(tester);
    final bridge = _first(tester);
    await _tryPiece(tester, bridge.hints.keys.first);

    await tester.tap(_piece(bridge.conjunction));
    await tester.pump();
    await tester.tap(_gap);
    await tester.pump();

    expect(
      find.descendant(of: _gap, matching: find.text(', ${bridge.conjunction}')),
      findsOneWidget,
    );
    expect(_crossEnabled(tester), isTrue);
  });

  testWidgets('the checklist follows the sentence as it is typed', (
    tester,
  ) async {
    await _openBridge(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');
    bool met(String label) => find
        .byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '$label: done',
        )
        .evaluate()
        .isNotEmpty;

    expect(find.text("Comma right before 'for'"), findsOneWidget);
    expect(met("Uses 'for'"), isFalse);

    await tester.enterText(find.byType(TextField), 'I ran, for');
    await tester.pump();

    expect(met('Starts with a capital'), isTrue);
    expect(met("Uses 'for'"), isTrue);
    expect(met("Comma right before 'for'"), isTrue);
    expect(met('Ends with . ! or ?'), isFalse);
  });

  testWidgets('a wrong sentence shows the hint once', (tester) async {
    await _openBridge(tester);
    final bridge = _first(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');
    expect(find.textContaining('Another example:'), findsNothing);

    await _write(tester, 'bad');

    expect(
      find.textContaining('Another example: ${bridge.examples.first}'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'bad, more');
    await tester.pump();
    expect(find.textContaining('Another example:'), findsOneWidget);
  });

  testWidgets('three wrong tries collapse the bridge, and it restarts', (
    tester,
  ) async {
    await _openBridge(tester);
    final bridge = _first(tester);
    final wrong = fanboys.where((w) => w != bridge.conjunction).take(3);

    for (final word in wrong) {
      await _tryPiece(tester, word);
    }

    expect(find.text(_broke), findsOneWidget);
    expect(find.bySemanticsLabel('Bridge broken'), findsOneWidget);
    expect(find.text('Cross the bridge'), findsNothing);

    await _tap(tester, 'Try again');

    expect(_inBar('LEVEL 2 · BRIDGE 1 OF 7'), findsOneWidget);
    for (final word in fanboys) {
      expect(_enabled(tester, word), isTrue, reason: word);
    }
  });

  testWidgets('the right piece explains why, then asks for a sentence', (
    tester,
  ) async {
    await _openBridge(tester);
    final bridge = _first(tester);

    await _tryPiece(tester, bridge.conjunction);

    expect(find.text('That is correct! ${bridge.explanation}'), findsOneWidget);
    await _tap(tester, 'Strengthen the Bridge');
    expect(_inBar('Strengthen the bridge'), findsOneWidget);
    expect(
      find.textContaining("coordinating conjunction, 'for'."),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a failed sentence says what to fix and adds no foundation', (
    tester,
  ) async {
    await _openBridge(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');

    await _write(tester, 'the dog ran far, for it was late.');

    expect(
      find.text('Start your sentence with a capital letter.'),
      findsOneWidget,
    );
    expect(find.text('the dog ran far, for it was late.'), findsOneWidget);
    expect(find.text('Quick Facts'), findsNothing);
  });

  testWidgets('a copied example is rejected', (tester) async {
    await _openBridge(tester);
    final bridge = _first(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');

    await _write(tester, bridge.examples.first);

    expect(find.textContaining("Don't copy"), findsOneWidget);
  });

  testWidgets('sentences become foundations and Quick Facts follow '
      'the first', (tester) async {
    await _openBridge(tester);
    final facts = _game(tester).quickFacts['for']!;
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');
    final first = _sentence(0, 'for');

    await _write(tester, first);

    expect(find.text(first), findsOneWidget);
    for (final fact in facts) {
      expect(find.textContaining(fact.word, findRichText: true), findsWidgets);
    }

    await _write(tester, 'The dog ran far, for the cat sat down.');
    expect(find.textContaining('Quick Facts in your'), findsOneWidget);

    await _write(tester, 'The dog ran far because the cat sat down.');
    expect(
      find.text('The dog ran far because the cat sat down.'),
      findsOneWidget,
    );
    expect(find.text(_sturdy), findsOneWidget);
  });

  testWidgets('tapping a filled gap empties it', (tester) async {
    await _openBridge(tester);
    await tester.tap(_piece('for'));
    await tester.pump();
    await tester.tap(_gap);
    await tester.pump();
    expect(_crossEnabled(tester), isTrue);

    await tester.tap(_gap);
    await tester.pump();

    expect(_crossEnabled(tester), isFalse);
    expect(find.descendant(of: _gap, matching: find.text('?')), findsOneWidget);
  });

  testWidgets('the Quick Facts words stay on the writing screen', (
    tester,
  ) async {
    await _open(
      tester,
      prefs: {
        'level2_resume_v1':
            '{"bridgeIndex":1,"written":[["A"],["The dog ran, and I sat."]]}',
      },
    );

    for (final fact in _game(tester).quickFacts['and']!) {
      expect(find.text(fact.word), findsOneWidget);
    }
  });

  testWidgets('a similar word follows its own punctuation', (tester) async {
    await _open(
      tester,
      prefs: {
        'level2_resume_v1':
            '{"bridgeIndex":1,"written":[["A"],["The dog ran, and I sat."]]}',
      },
    );

    await _write(tester, 'The dog ran, moreover the cat sat.');

    expect(
      find.text("Put a semicolon before 'moreover' and a comma after it."),
      findsOneWidget,
    );
  });

  testWidgets('nor has one sentence only', (tester) async {
    await _open(
      tester,
      prefs: {'level2_resume_v1': '{"bridgeIndex":2,"written":[[],[],[]]}'},
    );
    await _tryPiece(tester, 'nor');
    await _tap(tester, 'Strengthen the Bridge');

    await _write(tester, _sentence(2, 'nor'));

    expect(find.text(_sturdy), findsOneWidget);
    expect(find.text('Quick Facts'), findsNothing);
  });

  testWidgets('all 7 bridges take 12 sentences and finish the level', (
    tester,
  ) async {
    await _openBridge(tester);
    final progress = tester
        .element(find.byType(Level2Screen))
        .read<ProgressStore>();

    for (var i = 0; i < 7; i++) {
      expect(_inBar('LEVEL 2 · BRIDGE ${i + 1} OF 7'), findsOneWidget);
      await _playBridge(tester, i);
    }

    expect(find.text(_done), findsOneWidget);
    expect(progress.isCompleted(2), isTrue);

    final results = tester
        .element(find.byType(Level2Screen))
        .read<ResultsStore>();
    expect(results.level2Resume, isNull);
    final bridges = (results.results['2'] as Map)['bridges'] as List;
    expect(bridges, hasLength(7));
    final sentences = bridges.expand((b) => (b as Map)['sentences'] as List);
    expect(sentences, hasLength(12));
    expect((bridges.first as Map)['conjunction'], 'for');
    expect((sentences.first as Map)['attempts'], 1);
  });

  testWidgets('wrong tries, collapses and attempts are recorded and kept', (
    tester,
  ) async {
    await _openBridge(tester);
    for (final word in ['and', 'nor', 'but']) {
      await _tryPiece(tester, word);
    }
    await _tap(tester, 'Try again');
    await _tryPiece(tester, 'so');
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');
    await _write(tester, 'the dog ran far, for it was late.');
    await _write(tester, 'The dogg ran far, for it was late.');

    // Leave and come back: the numbers must survive a resume.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Building Bridges'));
    await tester.pumpAndSettle();
    await _write(tester, 'The dog ran far because the cat sat down.');

    final results = tester
        .element(find.byType(Level2Screen))
        .read<ResultsStore>();
    final stats = results.level2Resume!.stats.first;
    expect(stats['wrongTries'], 4);
    expect(stats['collapses'], 1);
    final sentences = stats['sentences'] as List;
    expect(sentences.first, {
      'text': 'The dogg ran far, for it was late.',
      'attempts': 2,
      'spellingWarnings': 1,
      'unsure': false,
    });
    expect(sentences, hasLength(2));
  });

  testWidgets('a student continues at the bridge where they stopped', (
    tester,
  ) async {
    await _openBridge(tester);
    await _playBridge(tester, 0);
    expect(_inBar('LEVEL 2 · BRIDGE 2 OF 7'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Building Bridges'));
    await tester.pumpAndSettle();

    expect(_inBar('LEVEL 2 · BRIDGE 2 OF 7'), findsOneWidget);
  });

  testWidgets('a student continues after an accepted sentence', (tester) async {
    await _open(
      tester,
      prefs: {
        'level2_resume_v1':
            '{"bridgeIndex":0,"written":[["The dog ran, for I came."]]}',
      },
    );

    expect(find.text('The dog ran, for I came.'), findsOneWidget);
    expect(find.text('Quick Facts'), findsOneWidget);
  });

  testWidgets('a bad resume value starts fresh', (tester) async {
    await _open(tester, prefs: {'level2_resume_v1': '{nope'});

    expect(find.textContaining('Oh no! The bridge is broken'), findsOneWidget);
  });

  testWidgets('every step fits a 360x640 phone', (tester) async {
    await _open(tester);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await _tryPiece(tester, 'for');
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Strengthen the Bridge');
    await tester.scrollUntilVisible(
      find.text('Submit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _write(tester, _sentence(0, 'for'));
    // The list builds lazily, so scroll the way a student would.
    await tester.scrollUntilVisible(
      find.text('Submit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Submit').hitTestable(), findsOneWidget);
  });

  testWidgets('the first sentence leads straight to Write with Quick Facts', (
    tester,
  ) async {
    await _openBridge(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');

    await _write(tester, _sentence(0, 'for'));

    expect(find.text(_factsTask), findsOneWidget);
    expect(find.text('Write now'), findsNothing);
  });

  testWidgets('saved progress from the old Quick Facts step reopens on '
      'Write with Quick Facts', (tester) async {
    await _open(
      tester,
      prefs: {
        'level2_resume_v1':
            '{"bridgeIndex":0,"written":[["I stayed inside, for it was '
            'raining."],[],[],[],[],[],[]],"stats":[]}',
      },
    );

    expect(find.text(_factsTask), findsOneWidget);
  });

  testWidgets('the placed piece keeps its comma', (tester) async {
    await _openBridge(tester);
    await _tryPiece(tester, 'for');

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('placed-word')),
        matching: find.text(', for'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('misspelt words are underlined and do not block', (tester) async {
    await _openBridge(tester);
    await _tryPiece(tester, 'for');
    await _tap(tester, 'Strengthen the Bridge');

    await tester.enterText(find.byType(TextField), 'The dogg ran, for I came.');
    await tester.pump();

    final context = tester.element(find.byType(WritingPanel));
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    final span = controller.buildTextSpan(
      context: context,
      withComposing: false,
    );
    final marked = span.children!
        .whereType<TextSpan>()
        .where((s) => s.style?.decoration == TextDecoration.underline)
        .map((s) => s.text);
    expect(marked, ['dogg']);

    await _tap(tester, 'Submit');
    expect(find.text('Quick Facts'), findsOneWidget);
  });

  test('every failure has a message', () {
    for (final failure in CheckFailure.values) {
      expect(checkMessage(failure, 'for', WordRule.fanboys), isNotEmpty);
    }
    expect(
      checkMessage(CheckFailure.comma, 'because', WordRule.joining),
      contains('after the part'),
    );
  });

  test('findQuickFact prefers the longest word', () {
    const facts = [
      QuickFact(word: 'as', rule: QuickFactRule.joining),
      QuickFact(word: 'as a result', rule: QuickFactRule.linking),
    ];
    expect(findQuickFact('We won; as a result, we sang.', facts), facts[1]);
    expect(findQuickFact('We won as we sang.', facts), facts[0]);
    expect(findQuickFact('We won.', facts), isNull);
  });

  testWidgets('BridgeScene paints and labels every state', (tester) async {
    const labels = {
      BridgeState.open: 'Bridge open',
      BridgeState.cracked: 'Bridge cracked',
      BridgeState.built: 'Bridge built',
      BridgeState.broken: 'Bridge broken',
    };
    for (final MapEntry(key: state, value: label) in labels.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BridgeScene(
              state: state,
              left: 'It was raining,',
              right: 'we went out.',
              placedWord: 'but',
              foundations: const ['One beam.'],
              gap: const SizedBox(key: ValueKey('scene-gap')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(find.text('One beam.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'It was raining, '
          '${state == BridgeState.built ? 'but' : '_____'} we went out.',
        ),
        state == BridgeState.broken ? findsNothing : findsOneWidget,
        reason: '$state',
      );
      expect(
        find.byKey(const ValueKey('scene-gap')),
        state == BridgeState.open || state == BridgeState.cracked
            ? findsOneWidget
            : findsNothing,
        reason: '$state',
      );
    }
  });
}
