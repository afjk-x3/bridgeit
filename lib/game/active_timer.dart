/// A stopwatch for time spent in a level. It runs from creation until
/// [pause], and [now] can be replaced in tests.
class ActiveTimer {
  ActiveTimer({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _startedAt = _now();
  }

  final DateTime Function() _now;
  DateTime? _startedAt;
  Duration _banked = Duration.zero;

  Duration get elapsed {
    final started = _startedAt;
    return started == null ? _banked : _banked + _now().difference(started);
  }

  void pause() {
    _banked = elapsed;
    _startedAt = null;
  }

  void resume() => _startedAt ??= _now();

  /// Starts over from zero, keeping the running or paused state.
  void reset() {
    _banked = Duration.zero;
    if (_startedAt != null) _startedAt = _now();
  }
}
