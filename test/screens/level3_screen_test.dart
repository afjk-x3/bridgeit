import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/progress/results_store.dart';
import 'package:bridgeit/screens/level3_screen.dart';
import 'package:bridgeit/screens/start_screen.dart';
import 'package:bridgeit/widgets/travelogue_editor.dart';

import '../support/pump_app.dart';

const _entry =
    'We went to the dunes, and we rode a jeep. '
    'The sand was hot, but the wind was cool. '
    'I wanted to stay, yet we had to go. '
    'I was tired, so I slept in the car. '
    'It was the best trip of my life.';

Future<void> _open(WidgetTester tester) async {
  await pumpApp(
    tester,
    prefs: {
      'unlocked_levels': ['3'],
    },
  );
  await openMenu(tester);
  await tester.tap(find.text('Travelogue'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Level3Content _content(WidgetTester tester) =>
    tester.element(find.byType(Level3Screen)).read<GameContent>().level3;

Future<void> _reachMap(WidgetTester tester) async {
  await _open(tester);
  await _tap(tester, 'Next');
  await _tap(tester, 'Proceed');
}

/// Chooses the first place. The montage loops, so only pump its frames.
/// Picks La Paz on the map and drives there.
Future<void> _driveToLaPaz(WidgetTester tester) async {
  final pin = find.byKey(const ValueKey('pin-la_paz'));
  await tester.ensureVisible(pin);
  await tester.pump();
  await tester.tap(pin);
  await tester.pump();
  await tester.tap(find.textContaining('Drive to'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

Future<void> _reachMontage(WidgetTester tester) async {
  await _reachMap(tester);
  await _driveToLaPaz(tester);
}

Future<void> _pumpPass(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _reachEditor(WidgetTester tester) async {
  await _reachMontage(tester);
  await _pumpPass(tester);
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await _tap(tester, 'Next');
  await _tap(tester, 'Next');
}

// The button's label says what is missing, so find it by its place.
bool _submitEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(
      find.descendant(
        of: find.byType(TravelogueEditor),
        matching: find.byType(FilledButton),
      ),
    )
    .enabled;

void main() {
  testWidgets('toll gate, then the crossing, then the map', (tester) async {
    await _open(tester);
    expect(find.textContaining('toll gate'), findsOneWidget);

    await _tap(tester, 'Next');
    expect(find.textContaining('I have finally crossed'), findsOneWidget);
    expect(find.textContaining('Tap the map'), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is BridgeStrip && w.crossed),
      findsOneWidget,
    );

    await _tap(tester, 'Proceed');
    expect(find.text("LET'S EXPLORE TOGETHER!"), findsOneWidget);
    for (final place in _content(tester).places) {
      expect(find.text(place.name), findsOneWidget);
    }
  });

  testWidgets('a pin opens that place with its first caption', (tester) async {
    await _reachMontage(tester);

    final place = _content(tester).places.first;
    expect(find.text(place.pictures.first.caption), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('the montage shows its place, progress and a way back to the '
      'map', (tester) async {
    await _reachMontage(tester);
    final place = _content(tester).places.first;

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text(place.name)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Photo 1 of ${place.pictures.length}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Map'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("LET'S EXPLORE TOGETHER!"), findsOneWidget);
  });

  testWidgets('captions change and Next appears after one pass', (
    tester,
  ) async {
    await _reachMontage(tester);
    final pictures = _content(tester).places.first.pictures;

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(pictures[1].caption), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await _pumpPass(tester);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('I hope you will too.'), findsOneWidget);
  });

  testWidgets('the instructions state the limits from content', (tester) async {
    await _reachMontage(tester);
    await _pumpPass(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await _tap(tester, 'Next');

    expect(find.textContaining('5 to 7 sentences'), findsOneWidget);
    expect(
      find.textContaining('at least 4 coordinating conjunctions'),
      findsOneWidget,
    );
    expect(
      find.textContaining('a comma before each conjunction'),
      findsOneWidget,
    );
  });

  testWidgets('Submit opens when the counters are met, and the level ends', (
    tester,
  ) async {
    await _reachEditor(tester);
    final progress = tester
        .element(find.byType(Level3Screen))
        .read<ProgressStore>();
    expect(_submitEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), 'We ran, and they sat.');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Sentences: 1 of 5–7'), findsOneWidget);
    expect(find.textContaining('Conjunctions: 1 of 4'), findsOneWidget);
    expect(_submitEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), _entry);
    await tester.pump(const Duration(milliseconds: 350));
    expect(_submitEnabled(tester), isTrue);

    await _tap(tester, 'Submit');

    expect(find.textContaining('Congratulations'), findsOneWidget);
    expect(progress.isCompleted(3), isTrue);
    expect(
      tester
          .element(find.byType(Level3Screen))
          .read<ResultsStore>()
          .level3Resume,
      isNull,
    );

    final result =
        tester
                .element(find.byType(Level3Screen))
                .read<ResultsStore>()
                .results['3']
            as Map<String, dynamic>;
    expect(result['place'], 'Laoag La Paz Sand Dunes');
    expect(result['entry'], _entry);
    expect(result['sentences'], 5);
    expect(result['conjunctions'], ['and', 'but', 'yet', 'so']);
    expect(result['spellingWarnings'], 0);
    expect(find.text('Send my answers to my teacher'), findsOneWidget);
    expect(find.byTooltip('Journey'), findsNothing);

    await _tap(tester, 'Back to levels');
    expect(find.text('Choose a level'), findsOneWidget);
  });

  testWidgets('conjunctions are colored and unknown words underlined', (
    tester,
  ) async {
    await _reachEditor(tester);
    await tester.enterText(
      find.byType(TextField),
      'We ran, and the crabz sandboard sat. We saw birds, and big crabs.',
    );
    await tester.pump(const Duration(milliseconds: 350));

    final span = tester
        .widget<TextField>(find.byType(TextField))
        .controller!
        .buildTextSpan(
          context: tester.element(find.byType(TextField)),
          withComposing: false,
        );
    final parts = span.children!.whereType<TextSpan>();
    expect(
      parts
          .where((s) => s.style?.fontWeight == FontWeight.bold)
          .map((s) => s.text),
      ['and'],
    );
    expect(
      parts
          .where((s) => s.style?.decoration == TextDecoration.underline)
          .map((s) => s.text),
      ['crabz'],
    );
  });

  testWidgets('the map and editor fit a 360x640 phone', (tester) async {
    await _open(tester);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump();
    await _tap(tester, 'Next');
    await _tap(tester, 'Proceed');
    expect(tester.takeException(), isNull);

    await _driveToLaPaz(tester);
    await _pumpPass(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the journal keeps its room while typing', (tester) async {
    await _reachEditor(tester);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Write about:'), findsNothing);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
  });

  testWidgets('Drive to stops taking taps once the car sets off', (
    tester,
  ) async {
    await _reachMap(tester);
    final pin = find.byKey(const ValueKey('pin-la_paz'));
    await tester.ensureVisible(pin);
    await tester.pump();
    await tester.tap(pin);
    await tester.pump();
    final drive = find.ancestor(
      of: find.textContaining('Drive to'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    await tester.tap(drive);
    await tester.pump();

    expect(tester.widget<ButtonStyleButton>(drive).onPressed, isNull);
  });

  testWidgets('back from the travelogue returns to the instructions', (
    tester,
  ) async {
    await _reachEditor(tester);
    await tester.enterText(find.byType(TextField), 'We went to the dunes.');
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(TravelogueEditor), findsNothing);
    expect(find.byType(Level3Screen), findsOneWidget);
    expect(find.text('YOUR ENTRY NEEDS'), findsOneWidget);

    await _tap(tester, 'Next');
    expect(find.text('We went to the dunes.'), findsOneWidget);
  });

  testWidgets('after one pass the place is held: no Map, only Next', (
    tester,
  ) async {
    await _reachMontage(tester);
    expect(find.text('Map'), findsOneWidget);

    await _pumpPass(tester);
    expect(find.text('Map'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
    expect(
      tester
          .element(find.byType(Level3Screen))
          .read<ResultsStore>()
          .level3Resume
          ?.placeId,
      'la_paz',
    );
  });

  testWidgets('a held place reopens at its instructions with the draft', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {
        'unlocked_levels': ['3'],
        'level3_resume_v1':
            '{"placeId":"la_paz","draft":"We went to the dunes."}',
      },
    );
    await openMenu(tester);
    await tester.tap(find.text('Travelogue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR ENTRY NEEDS'), findsOneWidget);
    await _tap(tester, 'Next');
    expect(find.text('We went to the dunes.'), findsOneWidget);
    expect(find.textContaining('Laoag La Paz Sand Dunes'), findsOneWidget);
  });
}
