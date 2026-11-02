import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/widgets/song_player.dart';

const _length = Duration(seconds: 2);

Widget _player({
  String? asset,
  ValueChanged<Duration>? onPosition,
  VoidCallback? onCompleted,
}) => MaterialApp(
  home: Scaffold(
    body: SongPlayer(
      assetPath: asset,
      silentLength: _length,
      onPosition: onPosition,
      onCompleted: onCompleted,
    ),
  ),
);

void main() {
  testWidgets('the player is a bare strip for the lyrics card to hold', (
    tester,
  ) async {
    await tester.pumpWidget(_player());
    expect(
      find.descendant(of: find.byType(SongPlayer), matching: find.byType(Card)),
      findsNothing,
    );
  });

  testWidgets('without audio it plays silently and reports each full play', (
    tester,
  ) async {
    var completed = 0;
    final positions = <Duration>[];
    await tester.pumpWidget(
      _player(onPosition: positions.add, onCompleted: () => completed++),
    );
    expect(find.text('BridgeIt Song (no sound yet)'), findsOneWidget);
    expect(find.text('0:02'), findsOneWidget);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(positions.last, const Duration(seconds: 1));
    expect(completed, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(completed, 1);
    expect(find.byTooltip('Play'), findsOneWidget);

    // Playing again starts over and counts again.
    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(positions.last, lessThan(const Duration(seconds: 1)));
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 2);
  });

  testWidgets('pause stops the song without counting a play', (tester) async {
    var completed = 0;
    await tester.pumpWidget(_player(onCompleted: () => completed++));

    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump(const Duration(seconds: 5));

    expect(completed, 0);
    expect(find.byTooltip('Play'), findsOneWidget);
  });

  testWidgets('going to the background pauses, and disposing stops listening', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_player(onCompleted: () => completed++));
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
    expect(find.byTooltip('Play'), findsOneWidget);

    // Disposed players stop listening to the app lifecycle.
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to silent playback when the audio cannot load', (
    tester,
  ) async {
    // Stand-in for the audio plugin: loading fails, as for a missing asset.
    const channel = MethodChannel('com.ryanheise.just_audio.methods');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'init') throw PlatformException(code: 'no audio');
      return <String, dynamic>{};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(_player(asset: 'assets/audio/gone.mp3'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('BridgeIt Song (no sound yet)'), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);
  });
}
