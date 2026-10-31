import 'dart:collection';
import 'dart:math';

import 'package:bridgeit/content/models.dart';

/// MatchIt: put each function into its conjunction's slot. Drag and tap-tap
/// both go through [place] and [remove].
class MatchItRound {
  MatchItRound(List<MatchPair> pairs, {Random? random})
    : _answers = {for (final p in pairs) p.conjunction: p.function},
      _functions = [for (final p in pairs) p.function]..shuffle(random);

  final Map<String, String> _answers;
  // Shuffled, or the tray would list the functions in answer order.
  final List<String> _functions;
  final Map<String, String> _placed = {};
  final Set<String> _locked = {};
  final List<List<String>> _attempts = [];

  /// Conjunction → the function now in its slot.
  Map<String, String> get placed => UnmodifiableMapView(_placed);

  /// Functions not in a slot, in display order.
  List<String> get tray =>
      _functions.where((f) => !_placed.containsValue(f)).toList();

  /// The wrong conjunctions of each submit, in order.
  List<List<String>> get attempts => UnmodifiableListView(_attempts);

  bool isLocked(String conjunction) => _locked.contains(conjunction);

  bool get canSubmit => _placed.length == _answers.length;
  bool get isDone => _locked.length == _answers.length;

  /// Fills a slot. A function already in another slot moves here, and one
  /// already in this slot goes back to the tray.
  void place(String conjunction, String function) {
    final holder = _placed.entries.where((e) => e.value == function);
    if (!_answers.containsKey(conjunction) || isLocked(conjunction)) return;
    if (holder.any((e) => isLocked(e.key))) return;
    _placed.removeWhere((_, f) => f == function);
    _placed[conjunction] = function;
  }

  void remove(String conjunction) {
    if (!isLocked(conjunction)) _placed.remove(conjunction);
  }

  /// Keeps the right pairs, returns the wrong ones to the tray and returns
  /// their conjunctions. Does nothing until every slot is filled.
  List<String> submit() {
    if (!canSubmit || isDone) return const [];
    final wrong = [
      for (final MapEntry(key: conjunction, value: function) in _placed.entries)
        if (_answers[conjunction] != function) conjunction,
    ];
    _locked.addAll(_placed.keys.where((c) => !wrong.contains(c)));
    _placed.removeWhere((c, _) => wrong.contains(c));
    _attempts.add(wrong);
    return wrong;
  }
}
