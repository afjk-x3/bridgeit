import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/screens/level2_screen.dart';
import 'package:bridgeit/theme/app_theme.dart';
import 'package:bridgeit/widgets/bridge_scene.dart';
import 'package:bridgeit/widgets/conjunction_piece.dart';

import '../support/pump_app.dart';

const _prompt =
    'Which conjunction connects these two clauses? Drag a piece into the gap.';
const _built = 'Bridge built! The vehicle can cross.';
const _broke = "The bridge broke! Let's try this sentence again.";
const _done = 'Level 2 done! Ask your teacher for the code.';

final _gap = find.byKey(const ValueKey('gap'));
Finder _piece(String word) => find.byKey(ValueKey('piece-$word'));

Future<void> _openLevel2(WidgetTester tester) async {
  await pumpApp(
    tester,
    prefs: {
      'unlocked_levels': ['2'],
    },
  );
  await openMenu(tester);
  await tester.tap(find.text('Building the bridge'));
  await tester.pumpAndSettle();
}

BridgeLevelContent _content(WidgetTester tester) =>
    tester.element(find.byType(Level2Screen)).read<GameContent>().level2;

/// Words that are not answers for [sentence], in FANBOYS order.
List<String> _wrongWords(BridgeSentence sentence) =>
    fanboys.where((w) => !sentence.answers.contains(w)).toList();

/// The real thing: drag the piece onto the gap.
Future<void> _drag(WidgetTester tester, String word) async {
  final offset = tester.getCenter(_gap) - tester.getCenter(_piece(word));
  await tester.timedDrag(
    _piece(word),
    offset,
    const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
}

/// The accessibility fallback: tap the piece, then tap the gap.
Future<void> _tapPlace(WidgetTester tester, String word) async {
  await tester.tap(_piece(word));
  await tester.pump();
  await tester.tap(_gap);
  await tester.pumpAndSettle();
}

/// The scene announces its state to screen readers.
Future<void> _expectBridge(WidgetTester tester, String label) async {
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    expect(find.bySemanticsLabel(label), findsOneWidget);
  } finally {
    handle.dispose();
  }
}

bool _enabled(WidgetTester tester, String word) =>
    tester.widget<ConjunctionPiece>(_piece(word)).enabled;

/// -1 while the vehicle waits on the left cliff, 1 once it is on the right.
double _carX(WidgetTester tester) =>
    (tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
            as Alignment)
        .x;

Color _segment(WidgetTester tester, int i) =>
    (tester.widget<Container>(find.byKey(ValueKey('strength-$i'))).decoration!
            as BoxDecoration)
        .color!;

void main() {
  testWidgets('shows header, clauses, neutral prompt and 7 big pieces', (
    tester,
  ) async {
    await _openLevel2(tester);
    final content = _content(tester);
    final first = content.sentences.first;

    expect(
      find.text('LEVEL 2 · SENTENCE 1 OF ${content.sentences.length}'),
      findsOneWidget,
    );
    expect(find.text('Building the bridge'), findsOneWidget);
    // One sentence card, the missing conjunction as an inline blank.
    expect(
      find.text('${first.left} _____ ${first.right}', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(_prompt), findsOneWidget);
    expect(find.text('Bridge strength'), findsOneWidget);
    expect(find.text('Next sentence'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    for (final word in fanboys) {
      final size = tester.getSize(_piece(word));
      expect(size.width, greaterThanOrEqualTo(48), reason: word);
      expect(size.height, greaterThanOrEqualTo(48), reason: word);
      expect(_enabled(tester, word), isTrue, reason: word);
    }
  });

  testWidgets('dragging the correct piece builds the bridge', (tester) async {
    await _openLevel2(tester);
    final answer = _content(tester).sentences.first.answers.first;

    await _drag(tester, answer);

    expect(find.text(_built), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text(_prompt), findsNothing);
    expect(find.text('Next sentence'), findsOneWidget);
    await _expectBridge(tester, 'Bridge built');
    // The sentence card now reads as one sentence with the word in its blank.
    final first = _content(tester).sentences.first;
    expect(
      find.text('${first.left} $answer ${first.right}', findRichText: true),
      findsOneWidget,
    );
    // The word sits in the bridge, and the vehicle is on the far cliff.
    expect(
      find.descendant(
        of: find.byType(BridgeScene),
        matching: find.text(answer),
      ),
      findsOneWidget,
    );
    expect(_carX(tester), 1);
    for (final word in fanboys) {
      expect(_enabled(tester, word), isFalse, reason: word);
    }
  });

  testWidgets('wrong piece shows the hint and greys out', (tester) async {
    await _openLevel2(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final wrong = sentence.hints.keys.first;

    await _drag(tester, wrong);

    expect(find.text(sentence.hints[wrong]!), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    expect(find.text(_prompt), findsNothing);
    await _expectBridge(tester, 'Bridge cracked');
    expect(_enabled(tester, wrong), isFalse);
    expect(_enabled(tester, sentence.answers.first), isTrue);
    // One of the segments is lost: brown for what is left, red for the loss.
    final max = content.maxWrongAnswers;
    for (var i = 0; i < max - 1; i++) {
      expect(_segment(tester, i), AppColors.bridge);
    }
    expect(_segment(tester, max - 1), AppColors.wrong);
    expect(_carX(tester), -1);
  });

  testWidgets('a wrong piece without its own hint shows the default one', (
    tester,
  ) async {
    await _openLevel2(tester);
    final sentence = _content(tester).sentences.first;
    final wrong = _wrongWords(sentence)
        .firstWhere((w) => !sentence.hints.containsKey(w));

    await _tapPlace(tester, wrong);

    expect(find.text(sentence.defaultHint), findsOneWidget);
  });

  testWidgets('three wrong pieces break the bridge', (tester) async {
    await _openLevel2(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final wrong = _wrongWords(sentence).take(content.maxWrongAnswers).toList();

    for (final word in wrong) {
      await _tapPlace(tester, word);
    }

    expect(find.text(_broke), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await _expectBridge(tester, 'Bridge broken');
    expect(find.text('Next sentence'), findsNothing);
    for (var i = 0; i < content.maxWrongAnswers; i++) {
      expect(_segment(tester, i), AppColors.wrong);
    }
    for (final word in fanboys) {
      expect(_enabled(tester, word), isFalse, reason: word);
    }

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text(_broke), findsNothing);
    expect(find.text(_prompt), findsOneWidget);
    await _expectBridge(tester, 'Bridge open');
    for (final word in fanboys) {
      expect(_enabled(tester, word), isTrue, reason: word);
    }
    for (var i = 0; i < content.maxWrongAnswers; i++) {
      expect(_segment(tester, i), AppColors.bridge);
    }
    // And the sentence can still be solved afterwards.
    await _tapPlace(tester, sentence.answers.first);
    expect(find.text(_built), findsOneWidget);
  });

  testWidgets('tapping the gap with no piece selected does nothing', (
    tester,
  ) async {
    await _openLevel2(tester);

    await tester.tap(_gap);
    await tester.pumpAndSettle();

    expect(find.text(_prompt), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsNothing);
  });

  testWidgets('the next sentence starts with the vehicle on the left cliff', (
    tester,
  ) async {
    await _openLevel2(tester);
    final car = find.descendant(
      of: find.byType(AnimatedAlign),
      matching: find.byType(CustomPaint),
    );
    final sceneCenter = tester.getCenter(find.byType(BridgeScene)).dx;
    final answer = _content(tester).sentences.first.answers.first;
    await _tapPlace(tester, answer);
    expect(tester.getCenter(car).dx, greaterThan(sceneCenter));

    await tester.tap(find.text('Next sentence'));
    await tester.pump(); // one frame: no time for a drive back across the gap

    expect(tester.getCenter(car).dx, lessThan(sceneCenter));
  });

  testWidgets('finishing all sentences marks level 2 completed', (
    tester,
  ) async {
    await _openLevel2(tester);
    final sentences = _content(tester).sentences;
    final progress = tester
        .element(find.byType(Level2Screen))
        .read<ProgressStore>();
    expect(progress.isCompleted(2), isFalse);

    for (var i = 0; i < sentences.length; i++) {
      expect(
        find.text('LEVEL 2 · SENTENCE ${i + 1} OF ${sentences.length}'),
        findsOneWidget,
      );
      expect(
        find.textContaining(sentences[i].left, findRichText: true),
        findsOneWidget,
      );
      // .last also exercises the second accepted answer where there is one.
      await _tapPlace(tester, sentences[i].answers.last);
      final last = i == sentences.length - 1;
      expect(find.text(last ? 'Finish' : 'Next sentence'), findsOneWidget);
      await tester.tap(find.text(last ? 'Finish' : 'Next sentence'));
      await tester.pumpAndSettle();
    }

    expect(find.text(_done), findsOneWidget);
    expect(progress.isCompleted(2), isTrue);

    await tester.tap(find.text('Back to levels'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('BridgeScene paints and labels every state', (tester) async {
    const labels = {
      BridgeState.open: 'Bridge open',
      BridgeState.cracked: 'Bridge cracked',
      BridgeState.built: 'Bridge built',
      BridgeState.broken: 'Bridge broken',
      BridgeState.reinforced: 'Bridge reinforced',
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
              gap: const SizedBox(key: ValueKey('scene-gap')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _expectBridge(tester, label);
      // The sentence card fills its blank only once the bridge is complete.
      final complete = {
        BridgeState.built,
        BridgeState.wobbly,
        BridgeState.reinforced,
      }.contains(state);
      expect(
        find.text(
          'It was raining, ${complete ? 'but' : '_____'} we went out.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      // The gap is gone once the bridge is broken; a built bridge shows the word.
      expect(
        find.byKey(const ValueKey('scene-gap')),
        state == BridgeState.open || state == BridgeState.cracked
            ? findsOneWidget
            : findsNothing,
        reason: '$state',
      );
      expect(
        find.text('but'),
        state == BridgeState.built || state == BridgeState.reinforced
            ? findsOneWidget
            : findsNothing,
        reason: '$state',
      );
    }
  });
}
