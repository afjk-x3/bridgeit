import 'package:flutter/widgets.dart';

import '../game/active_timer.dart';

/// An [ActiveTimer] that pauses whenever the app isn't in front.
class LevelClock {
  LevelClock() {
    _listener = AppLifecycleListener(
      onStateChange: (state) =>
          state == AppLifecycleState.resumed ? timer.resume() : timer.pause(),
    );
  }

  final ActiveTimer timer = ActiveTimer();
  late final AppLifecycleListener _listener;

  int get elapsedMs => timer.elapsed.inMilliseconds;

  void dispose() => _listener.dispose();
}
