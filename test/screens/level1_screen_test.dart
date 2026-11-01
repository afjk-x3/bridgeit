import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/screens/level1_screen.dart';

import '../support/pump_app.dart';

const _done = 'Level 1 done! Ask your teacher for the code.';
const _listen = 'No. Let me listen to the song again.';

Finder _slot(String conjunction) => find.byKey(ValueKey('slot-$conjunction'));
Finder _function(String function) => find.byKey(ValueKey('fn-$function'));

Level1Content _content(WidgetTester tester) =>
    tester.element(find.byType(Level1Screen)).read<GameContent>().level1;

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _openLevel(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  await pumpApp(tester, prefs: prefs);
  await openMenu(tester);
  await tester.tap(find.text('Conjunction Theme Song'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('PLAY THE SONG'));
  await tester.pumpAndSettle();
}

/// Plays the silent song through once.
Future<void> _playOnce(WidgetTester tester) async {
  final content = _content(tester);
  await tester.tap(find.byTooltip('Play'));
  await tester.pump();
  await tester.pump(Duration(milliseconds: content.lyrics.last.startMs + 7000));
}

Future<void> _reachMatchIt(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await _playOnce(tester);
  }
  await _tapText(tester, 'Next');
  await _tapText(tester, 'NEXT');
  await _tapText(tester, 'Yes!');
}

Future<void> _tapPlace(
  WidgetTester tester,
  String conjunction,
  String function,
) async {
  await tester.ensureVisible(_function(function));
  await tester.pumpAndSettle();
  await tester.tap(_function(function));
  await tester.pump();
  await tester.ensureVisible(_slot(conjunction));
  await tester.pumpAndSettle();
  await tester.tap(_slot(conjunction));
  await tester.pumpAndSettle();
}

Future<void> _placeAllRight(WidgetTester tester) async {
  for (final pair in _content(tester).matchIt) {
    await _tapPlace(tester, pair.conjunction, pair.function);
  }
}

void main() {
  testWidgets('Next waits for three full plays and the counter moves', (
    tester,
  ) async {
    await _openLevel(tester);

    bool nextEnabled() => tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
        .enabled;
    expect(find.text('0/3'), findsOneWidget);
    expect(nextEnabled(), isFalse);

    await _playOnce(tester);
    expect(find.text('1/3'), findsOneWidget);
    expect(nextEnabled(), isFalse);

    await _playOnce(tester);
    await _playOnce(tester);
    expect(find.text('3/3'), findsOneWidget);
    expect(nextEnabled(), isTrue);
  });

  testWidgets('the lyric card follows the song', (tester) async {
    await _openLevel(tester);
    final lyrics = _content(tester).lyrics;
    Text now() => tester.widget<Text>(find.byKey(const ValueKey('lyric-now')));
    expect(now().data, lyrics.first.text);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.pump(Duration(milliseconds: lyrics[2].startMs + 200));

    expect(now().data, lyrics[2].text);
    expect(find.text(lyrics[3].text), findsOneWidget);
  });

  testWidgets('MatchIt can go back to the song without replaying 3 times', (
    tester,
  ) async {
    await _openLevel(tester);
    for (var i = 0; i < 3; i++) {
      await _playOnce(tester);
    }
    await _tapText(tester, 'Next');
    await _tapText(tester, 'NEXT');

    await _tapText(tester, _listen);
    expect(find.text('SING ALONG!'), findsOneWidget);

    await _tapText(tester, 'Next');
    await _tapText(tester, 'NEXT');
    expect(find.text('Yes!'), findsOneWidget);
  });

  testWidgets('a finished level needs no plays on a replay', (tester) async {
    await _openLevel(
      tester,
      prefs: {
        'completed_levels': ['1'],
      },
    );

    expect(find.byKey(const ValueKey('play-counter')), findsNothing);
    await _tapText(tester, 'Next');
    expect(find.text('NEXT'), findsOneWidget);
  });

  testWidgets('tray lists every function and Submit needs all seven', (
    tester,
  ) async {
    await _openLevel(tester);
    await _reachMatchIt(tester);

    bool submitEnabled() => tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'))
        .enabled;
    final pairs = _content(tester).matchIt;
    for (final pair in pairs) {
      expect(find.text(pair.conjunction), findsOneWidget);
      expect(_function(pair.function), findsOneWidget);
    }
    expect(submitEnabled(), isFalse);

    await _placeAllRight(tester);
    expect(submitEnabled(), isTrue);
  });

  testWidgets('dragging a function fills its slot', (tester) async {
    await _openLevel(tester);
    await _reachMatchIt(tester);
    final pair = _content(tester).matchIt.first;
    await tester.ensureVisible(_function(pair.function));
    await tester.pumpAndSettle();

    await tester.timedDrag(
      _function(pair.function),
      tester.getCenter(_slot(pair.conjunction)) -
          tester.getCenter(_function(pair.function)),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(_function(pair.function), findsNothing);
    expect(
      find.descendant(
        of: _slot(pair.conjunction),
        matching: find.text(pair.function),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a filled slot sends the function back', (tester) async {
    await _openLevel(tester);
    await _reachMatchIt(tester);
    final pair = _content(tester).matchIt.first;
    await _tapPlace(tester, pair.conjunction, pair.function);

    await tester.tap(_slot(pair.conjunction));
    await tester.pumpAndSettle();

    expect(_function(pair.function), findsOneWidget);
  });

  testWidgets('Submit keeps right pairs and returns wrong ones', (
    tester,
  ) async {
    await _openLevel(tester);
    await _reachMatchIt(tester);
    final pairs = _content(tester).matchIt;
    final (a, b) = (pairs[0], pairs[1]);
    await _tapPlace(tester, a.conjunction, b.function);
    await _tapPlace(tester, b.conjunction, a.function);
    for (final pair in pairs.skip(2)) {
      await _tapPlace(tester, pair.conjunction, pair.function);
    }

    await _tapText(tester, 'Submit');

    expect(
      find.text('2 pairs went back to the bottom. Try them again.'),
      findsOneWidget,
    );
    expect(_function(a.function), findsOneWidget);
    expect(_function(b.function), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(5));
    expect(find.text(_done), findsNothing);

    await _tapPlace(tester, a.conjunction, a.function);
    await _tapPlace(tester, b.conjunction, b.function);
    await _tapText(tester, 'Submit');
    expect(find.text(_done), findsOneWidget);
  });

  testWidgets('finishing asks for the code and goes straight to level 2', (
    tester,
  ) async {
    await _openLevel(tester);
    await _reachMatchIt(tester);
    await _placeAllRight(tester);
    await _tapText(tester, 'Submit');

    await tester.enterText(find.byType(TextField), 'BRIDGE2');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play level 2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Oh no! The bridge is broken'), findsOneWidget);
  });

  testWidgets('Send my answers shares the recorded result', (tester) async {
    final sender = FakeSender();
    await pumpApp(tester, sender: sender);
    await openMenu(tester);
    await tester.tap(find.text('Conjunction Theme Song'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY THE SONG'));
    await tester.pumpAndSettle();
    await _reachMatchIt(tester);
    await _placeAllRight(tester);
    await _tapText(tester, 'Submit');

    await _tapText(tester, 'Send my answers');

    final result = sender.sent!['1'] as Map<String, dynamic>;
    expect(result['plays'], 3);
    expect(result['attempts'], [<String>[]]);
    expect(result['activeMs'], isA<int>());
  });

  testWidgets('a failed send says so', (tester) async {
    await pumpApp(tester, sender: FakeSender(fails: true));
    await openMenu(tester);
    await tester.tap(find.text('Conjunction Theme Song'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLAY THE SONG'));
    await tester.pumpAndSettle();
    await _reachMatchIt(tester);
    await _placeAllRight(tester);
    await _tapText(tester, 'Submit');

    await _tapText(tester, 'Send my answers');

    expect(find.text("Couldn't send your answers. Try again."), findsOneWidget);
  });

  testWidgets('MatchIt fits a 360x640 phone', (tester) async {
    await _openLevel(tester);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump();
    await _reachMatchIt(tester);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Submit').hitTestable(), findsOneWidget);
  });
}
