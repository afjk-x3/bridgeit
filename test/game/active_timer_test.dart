import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/game/active_timer.dart';

void main() {
  late DateTime now;
  late ActiveTimer timer;

  void wait(int seconds) => now = now.add(Duration(seconds: seconds));

  setUp(() {
    now = DateTime(2026, 11, 1);
    timer = ActiveTimer(now: () => now);
  });

  test('counts while running', () {
    wait(5);
    expect(timer.elapsed, const Duration(seconds: 5));
  });

  test('stops counting while paused', () {
    wait(5);
    timer.pause();
    wait(60);
    expect(timer.elapsed, const Duration(seconds: 5));
  });

  test('resumes where it stopped', () {
    wait(5);
    timer.pause();
    wait(60);
    timer.resume();
    wait(2);
    expect(timer.elapsed, const Duration(seconds: 7));
  });

  test('pausing or resuming twice changes nothing', () {
    wait(5);
    timer
      ..resume()
      ..pause()
      ..pause();
    expect(timer.elapsed, const Duration(seconds: 5));
  });

  test('reset starts over', () {
    wait(5);
    timer.reset();
    wait(1);
    expect(timer.elapsed, const Duration(seconds: 1));
  });

  test('reset while paused stays paused', () {
    timer
      ..pause()
      ..reset();
    wait(5);
    expect(timer.elapsed, Duration.zero);
  });
}
