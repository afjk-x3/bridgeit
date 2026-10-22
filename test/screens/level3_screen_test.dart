import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/screens/level3_screen.dart';
import 'package:bridgeit/theme/app_theme.dart';
import 'package:bridgeit/widgets/bridge_scene.dart';
import 'package:bridgeit/widgets/conjunction_piece.dart';

import '../support/pump_app.dart';

const _prompt =
    'Which conjunction connects these two clauses? Drag a piece into the gap.';
const _broke = "The bridge broke! Let's try this sentence again.";
const _right = "That's right! Now reinforce the bridge.";
const _done = 'You reached the destination!';

final _gap = find.byKey(const ValueKey('gap'));
Finder _piece(String word) => find.byKey(ValueKey('piece-$word'));
Finder _choice(String word) => find.byKey(ValueKey('synonym-$word'));
Finder _pill(String step) => find.byKey(ValueKey('step-$step'));

String _question(String word) =>
    'Pick the word that means the same as "$word".';
String _noMatch(String word) =>
    'That word doesn\'t mean the same as "$word". Try another one.';

Future<void> _openLevel3(WidgetTester tester) async {
  await pumpApp(
    tester,
    prefs: {
      'unlocked_levels': ['2', '3'],
    },
  );
  await openMenu(tester);
  await tester.tap(find.text('Strengthening the bridge'));
  await tester.pumpAndSettle();
}

BridgeLevelContent _content(WidgetTester tester) =>
    tester.element(find.byType(Level3Screen)).read<GameContent>().level3;

/// Words that are not answers for [sentence], in FANBOYS order.
List<String> _wrongWords(BridgeSentence sentence) =>
    fanboys.where((w) => !sentence.answers.contains(w)).toList();

/// Synonym choices other than the answer, in content order.
List<String> _wrongChoices(BridgeSentence sentence) =>
    sentence.synonymChoices.where((c) => c != sentence.synonymAnswer).toList();

/// The accessibility fallback: tap the piece, then tap the gap.
Future<void> _tapPlace(WidgetTester tester, String word) async {
  await tester.tap(_piece(word));
  await tester.pump();
  await tester.tap(_gap);
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, String word) async {
  final offset = tester.getCenter(_gap) - tester.getCenter(_piece(word));
  await tester.timedDrag(
    _piece(word),
    offset,
    const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, String word) async {
  await tester.ensureVisible(_choice(word));
  await tester.tap(_choice(word));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
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

bool _pieceEnabled(WidgetTester tester, String word) =>
    tester.widget<ConjunctionPiece>(_piece(word)).enabled;

bool _choiceEnabled(WidgetTester tester, String word) =>
    tester.widget<ButtonStyleButton>(_choice(word)).enabled;

/// -1 while the vehicle waits on the left cliff, 1 once it is on the right.
double _carX(WidgetTester tester) =>
    (tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
            as Alignment)
        .x;

Color _segment(WidgetTester tester, int i) =>
    (tester.widget<Container>(find.byKey(ValueKey('strength-$i'))).decoration!
            as BoxDecoration)
        .color!;

Color _pillFill(WidgetTester tester, String step) =>
    (tester
                .widget<Container>(
                  find.descendant(
                    of: _pill(step),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration)
        .color!;

Finder _check(String step) =>
    find.descendant(of: _pill(step), matching: find.byIcon(Icons.check));

/// Builds sentence [i] and picks its synonym, leaving "Reinforce" to tap.
Future<void> _buildAndPick(WidgetTester tester, BridgeSentence s) async {
  await _tapPlace(tester, s.answers.last);
  await _pick(tester, s.synonymAnswer!);
}

void main() {
  testWidgets('shows header, clauses, step pills, prompt and the tray', (
    tester,
  ) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final first = content.sentences.first;

    expect(
      find.text('LEVEL 3 · SENTENCE 1 OF ${content.sentences.length}'),
      findsOneWidget,
    );
    expect(find.text('Strengthening the bridge'), findsOneWidget);
    expect(find.text(first.left), findsOneWidget);
    expect(find.text(first.right), findsOneWidget);
    expect(find.text(_prompt), findsOneWidget);
    expect(find.text('Bridge strength'), findsOneWidget);
    expect(find.text('1 · Build'), findsOneWidget);
    expect(find.text('2 · Strengthen'), findsOneWidget);
    expect(_pillFill(tester, 'build'), AppColors.primary);
    expect(_pillFill(tester, 'strengthen'), isNot(AppColors.primary));
    expect(_check('build'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
    for (final word in fanboys) {
      expect(_pieceEnabled(tester, word), isTrue, reason: word);
    }
    expect(_choice(first.synonymChoices.first), findsNothing);
  });

  testWidgets('wrong piece shows the hint, three break the bridge', (
    tester,
  ) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final wrong = _wrongWords(sentence).take(content.maxWrongAnswers).toList();

    await _drag(tester, sentence.hints.keys.first);

    expect(find.text(sentence.hints.values.first), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    await _expectBridge(tester, 'Bridge cracked');

    for (final word in wrong) {
      if (_pieceEnabled(tester, word)) await _tapPlace(tester, word);
    }

    expect(find.text(_broke), findsOneWidget);
    await _expectBridge(tester, 'Bridge broken');
    expect(find.text('Try again'), findsOneWidget);
    for (final word in fanboys) {
      expect(_pieceEnabled(tester, word), isFalse, reason: word);
    }

    await _tap(tester, 'Try again');

    expect(find.text(_prompt), findsOneWidget);
    await _expectBridge(tester, 'Bridge open');
    expect(_pieceEnabled(tester, wrong.first), isTrue);
  });

  testWidgets('build then pick synonym reinforces', (tester) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final answer = sentence.answers.first;

    await _drag(tester, answer);

    // Step 2: the bridge is whole but wobbly, and the vehicle waits.
    await _expectBridge(tester, 'Bridge wobbly');
    expect(find.text(_question(answer)), findsOneWidget);
    expect(find.text(_prompt), findsNothing);
    expect(_carX(tester), -1);
    expect(_check('build'), findsOneWidget);
    expect(_check('strengthen'), findsNothing);
    expect(_pillFill(tester, 'strengthen'), AppColors.primary);
    expect(
      find.descendant(
        of: find.byType(BridgeScene),
        matching: find.text(answer),
      ),
      findsOneWidget,
    );
    expect(_gap, findsNothing);
    expect(_piece(answer), findsNothing, reason: 'tray is hidden');
    expect(find.text('Reinforce the bridge'), findsNothing);
    // 2x2 grid of big buttons, in content order.
    final choices = sentence.synonymChoices;
    expect(choices, hasLength(4));
    for (final word in choices) {
      final size = tester.getSize(_choice(word));
      expect(size.width, greaterThanOrEqualTo(48), reason: word);
      expect(size.height, greaterThanOrEqualTo(48), reason: word);
      expect(_choiceEnabled(tester, word), isTrue, reason: word);
    }
    final centers = [for (final w in choices) tester.getCenter(_choice(w))];
    expect(centers[0].dy, centers[1].dy);
    expect(centers[2].dy, centers[3].dy);
    expect(centers[2].dy, greaterThan(centers[0].dy));
    expect(centers[0].dx, centers[2].dx);
    expect(centers[1].dx, centers[3].dx);
    expect(centers[1].dx, greaterThan(centers[0].dx));

    await _pick(tester, sentence.synonymAnswer!);

    // Right synonym: the vehicle still waits until the bridge is reinforced.
    expect(find.text(_right), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(2)); // card + build pill
    await _expectBridge(tester, 'Bridge wobbly');
    expect(_carX(tester), -1);
    expect(find.text('Next sentence'), findsNothing);

    await _tap(tester, 'Reinforce the bridge');

    await _expectBridge(tester, 'Bridge reinforced');
    expect(_carX(tester), 1);
    expect(find.text('Reinforce the bridge'), findsNothing);
    expect(find.text('Next sentence'), findsOneWidget);
    expect(_check('strengthen'), findsOneWidget);
  });

  testWidgets('wrong synonym shows hint', (tester) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final answer = sentence.answers.first;
    final wrong = _wrongChoices(sentence).first;
    await _tapPlace(tester, answer);

    await _pick(tester, wrong);

    expect(find.text(_noMatch(answer)), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    expect(find.text(_question(answer)), findsOneWidget);
    await _expectBridge(tester, 'Bridge wobbly');
    expect(_carX(tester), -1);
    expect(_choiceEnabled(tester, wrong), isFalse);
    expect(_choiceEnabled(tester, sentence.synonymAnswer!), isTrue);
    // One segment lost, counted from the synonym round (the build was clean).
    final max = content.maxWrongAnswers;
    for (var i = 0; i < max - 1; i++) {
      expect(_segment(tester, i), AppColors.bridge);
    }
    expect(_segment(tester, max - 1), AppColors.wrong);
  });

  testWidgets('wrong synonyms break the bridge and Try again starts over', (
    tester,
  ) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final sentence = content.sentences.first;
    final answer = sentence.answers.first;
    final wrong = _wrongChoices(sentence).take(content.maxWrongAnswers);
    await _tapPlace(tester, answer);

    for (final word in wrong) {
      await _pick(tester, word);
    }

    expect(find.text(_broke), findsOneWidget);
    await _expectBridge(tester, 'Bridge broken');
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Next sentence'), findsNothing);
    expect(find.text('Reinforce the bridge'), findsNothing);
    expect(_choice(sentence.synonymAnswer!), findsNothing);
    for (var i = 0; i < content.maxWrongAnswers; i++) {
      expect(_segment(tester, i), AppColors.wrong);
    }

    await _tap(tester, 'Try again');

    // Back to Build, with both rounds reset.
    expect(find.text(_broke), findsNothing);
    expect(find.text(_prompt), findsOneWidget);
    await _expectBridge(tester, 'Bridge open');
    expect(_pillFill(tester, 'build'), AppColors.primary);
    expect(_check('build'), findsNothing);
    for (final word in fanboys) {
      expect(_pieceEnabled(tester, word), isTrue, reason: word);
    }
    for (var i = 0; i < content.maxWrongAnswers; i++) {
      expect(_segment(tester, i), AppColors.bridge);
    }

    await _tapPlace(tester, answer);

    for (final word in sentence.synonymChoices) {
      expect(_choiceEnabled(tester, word), isTrue, reason: word);
    }
    expect(find.text(_noMatch(answer)), findsNothing);
  });

  testWidgets('the next sentence starts over on the left cliff', (
    tester,
  ) async {
    await _openLevel3(tester);
    final content = _content(tester);
    final car = find.descendant(
      of: find.byType(AnimatedAlign),
      matching: find.byType(CustomPaint),
    );
    final sceneCenter = tester.getCenter(find.byType(BridgeScene)).dx;
    await _buildAndPick(tester, content.sentences.first);
    await _tap(tester, 'Reinforce the bridge');
    expect(tester.getCenter(car).dx, greaterThan(sceneCenter));

    await tester.ensureVisible(find.text('Next sentence'));
    await tester.tap(find.text('Next sentence'));
    await tester.pump(); // one frame: no time for a drive back across the gap

    expect(tester.getCenter(car).dx, lessThan(sceneCenter));
    await tester.pumpAndSettle();
    expect(
      find.text('LEVEL 3 · SENTENCE 2 OF ${content.sentences.length}'),
      findsOneWidget,
    );
    expect(find.text(content.sentences[1].left), findsOneWidget);
    expect(find.text(_prompt), findsOneWidget);
    expect(_pillFill(tester, 'build'), AppColors.primary);
    expect(_check('build'), findsNothing);
    expect(_check('strengthen'), findsNothing);
    expect(find.text('Reinforce the bridge'), findsNothing);
  });

  testWidgets('finishing marks level 3 completed', (tester) async {
    await _openLevel3(tester);
    final sentences = _content(tester).sentences;
    final progress = tester
        .element(find.byType(Level3Screen))
        .read<ProgressStore>();
    expect(progress.isCompleted(3), isFalse);

    for (var i = 0; i < sentences.length; i++) {
      expect(
        find.text('LEVEL 3 · SENTENCE ${i + 1} OF ${sentences.length}'),
        findsOneWidget,
      );
      await _buildAndPick(tester, sentences[i]);
      await _tap(tester, 'Reinforce the bridge');
      final last = i == sentences.length - 1;
      expect(find.text(last ? 'Finish' : 'Next sentence'), findsOneWidget);
      await _tap(tester, last ? 'Finish' : 'Next sentence');
    }

    expect(find.text(_done), findsOneWidget);
    expect(
      find.text('Level 3 done! Ask your teacher for the code.'),
      findsNothing,
    );
    expect(progress.isCompleted(3), isTrue);

    await tester.tap(find.text('Back to levels'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a level'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('BridgeScene draws a wobbly bridge with the word in it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BridgeScene(
            state: BridgeState.wobbly,
            left: 'It was raining,',
            right: 'we went out.',
            placedWord: 'but',
            gap: SizedBox(key: ValueKey('scene-gap')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _expectBridge(tester, 'Bridge wobbly');
    expect(find.text('but'), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-gap')), findsNothing);
    expect(_carX(tester), -1);
  });
}
