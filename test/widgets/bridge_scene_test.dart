import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/widgets/bridge_scene.dart';

const _wobble = ValueKey('wobble');

Future<void> _pump(
  WidgetTester tester, {
  BridgeState state = BridgeState.built,
  List<BridgePier> piers = const [],
  int piersNeeded = 2,
  int cracks = 0,
  bool still = false,
  bool screenReader = false,
}) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: still,
          accessibleNavigation: screenReader,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: BridgeScene(
              state: state,
              left: 'She went to bed early',
              right: 'she was tired.',
              placedWord: 'for',
              piers: piers,
              piersNeeded: piersNeeded,
              cracks: cracks,
              gap: const SizedBox(key: ValueKey('scene-gap')),
            ),
          ),
        ),
      ),
    ),
  );
}

double _amplitude(WidgetTester tester) =>
    tester.widget<BridgeWobble>(find.byKey(_wobble)).amplitude;

Finder _pier(int n) => find.byKey(ValueKey('pier-$n'));

void main() {
  testWidgets('built with no piers shakes fully', (tester) async {
    await _pump(tester);
    expect(_amplitude(tester), 1.0);
    expect(find.byKey(const ValueKey('pier-caption')), findsNothing);
  });

  testWidgets('one of two piers shakes half and tags the pier', (tester) async {
    await _pump(
      tester,
      piers: const [BridgePier('for', 'I stayed in, for it rained.')],
    );
    expect(_amplitude(tester), 0.5);
    expect(
      find.descendant(of: _pier(1), matching: find.text('1 · for')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pier-caption')),
        matching: find.textContaining('I stayed in, for it rained.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('all piers in: still, two tags, numbered caption', (
    tester,
  ) async {
    await _pump(
      tester,
      piers: const [
        BridgePier('for', 'I stayed in, for it rained.'),
        BridgePier('because', 'I stayed in because it rained.'),
      ],
    );
    expect(_amplitude(tester), 0);
    expect(find.text('1 · for'), findsOneWidget);
    expect(find.text('2 · because'), findsOneWidget);
    expect(_pier(3), findsNothing);
  });

  testWidgets('nor needs one centred pier', (tester) async {
    await _pump(
      tester,
      piers: const [BridgePier('nor', 'I did not run, nor did I walk.')],
      piersNeeded: 1,
    );
    expect(_amplitude(tester), 0);
    final scene = tester.getCenter(find.byType(BridgeScene)).dx;
    expect(tester.getCenter(_pier(1)).dx, closeTo(scene, 2));
    expect(_pier(2), findsNothing);
  });

  testWidgets('no movement when animations are off', (tester) async {
    await _pump(tester, still: true);
    final deck = find.byKey(const ValueKey('deck-layer'));
    final before = tester.getTopLeft(deck);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getTopLeft(deck), before);
    }
  });

  testWidgets('no movement while a screen reader is on', (tester) async {
    await _pump(tester, screenReader: true);
    final deck = find.byKey(const ValueKey('deck-layer'));
    final before = tester.getTopLeft(deck);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getTopLeft(deck), before);
    }
  });

  testWidgets('the deck moves while it shakes', (tester) async {
    await _pump(tester);
    final deck = find.byKey(const ValueKey('deck-layer'));
    final seen = <Offset>{};
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      seen.add(tester.getTopLeft(deck));
    }
    expect(seen.length, greaterThan(1));
  });

  testWidgets('the first wrong try cracks the left support', (tester) async {
    await _pump(tester, state: BridgeState.cracked, cracks: 1);
    expect(find.bySemanticsLabel('Left support cracked'), findsOneWidget);
    expect(find.bySemanticsLabel('Right support cracked'), findsNothing);
  });

  testWidgets('the second wrong try cracks the right support too', (
    tester,
  ) async {
    await _pump(tester, state: BridgeState.cracked, cracks: 2);
    expect(find.bySemanticsLabel('Left support cracked'), findsOneWidget);
    expect(find.bySemanticsLabel('Right support cracked'), findsOneWidget);
  });

  testWidgets('the car falls into the river when the bridge collapses', (
    tester,
  ) async {
    await _pump(tester, state: BridgeState.broken, cracks: 2);
    await tester.pump(const Duration(seconds: 3));
    final scene = tester.getRect(find.byType(AspectRatio));
    final car = tester.getCenter(find.byKey(const ValueKey('bridge-car')));
    // The river starts at 196 of the 232-high scene.
    expect(car.dy, greaterThan(scene.top + scene.height * 196 / 232));
    expect(
      find.bySemanticsLabel('The car fell into the river'),
      findsOneWidget,
    );
  });

  testWidgets('after Try again the car is back on the road at once', (
    tester,
  ) async {
    await _pump(tester, state: BridgeState.broken, cracks: 3);
    await tester.pump(const Duration(seconds: 3));
    await _pump(tester, state: BridgeState.open);
    await tester.pump(const Duration(milliseconds: 100));
    final scene = tester.getRect(find.byType(AspectRatio));
    final car = tester.getCenter(find.byKey(const ValueKey('bridge-car')));
    expect(car.dy, lessThan(scene.top + scene.height * 108 / 232));
  });

  testWidgets('the car stays on the road while the bridge stands', (
    tester,
  ) async {
    await _pump(tester, state: BridgeState.cracked, cracks: 2);
    await tester.pump(const Duration(seconds: 3));
    final scene = tester.getRect(find.byType(AspectRatio));
    final car = tester.getCenter(find.byKey(const ValueKey('bridge-car')));
    expect(car.dy, lessThan(scene.top + scene.height * 108 / 232));
  });

  testWidgets('BridgeScene labels every state', (tester) async {
    const labels = {
      BridgeState.open: 'Bridge open',
      BridgeState.cracked: 'Bridge cracked',
      BridgeState.built: 'Bridge built',
      BridgeState.broken: 'Bridge broken',
    };
    for (final MapEntry(key: state, value: label) in labels.entries) {
      await _pump(
        tester,
        state: state,
        piers: const [BridgePier('but', 'One beam.')],
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'She went to bed early, '
          '${state == BridgeState.built ? 'for' : '_____'} she was tired.',
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
