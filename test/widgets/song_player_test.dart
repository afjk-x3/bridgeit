import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/widgets/song_player.dart';

void main() {
  testWidgets('song player without audio shows Song coming soon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SongPlayer(assetPath: null))),
    );

    expect(find.text('Song coming soon'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('going to the background without a player does nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SongPlayer(assetPath: null))),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Disposed players stop listening to the app lifecycle.
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(tester.takeException(), isNull);
  });

  testWidgets('song player falls back when the audio cannot load', (
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

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SongPlayer(assetPath: 'assets/audio/gone.mp3')),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('Song coming soon'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
