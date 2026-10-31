import 'dart:collection';

import 'package:bridgeit/content/models.dart';

enum DropResult { correct, wrong, broken, ignored }

/// Rules for one bridge. Words match case-insensitively; tried words are
/// stored lowercased.
class _Rules {
  _Rules(this._isAnswer, this._max) {
    if (_max < 1) {
      throw ArgumentError.value(_max, 'maxWrongAnswers', 'must be >= 1');
    }
  }

  final bool Function(String lower) _isAnswer;
  final int _max;
  final Set<String> _tried = {};
  bool _solved = false;

  bool get isSolved => _solved;
  int get wrongCount => _tried.length;
  bool get isBroken => wrongCount >= _max;
  Set<String> get triedWrong => UnmodifiableSetView(_tried);

  DropResult play(String word) {
    final lower = word.toLowerCase();
    if (_solved || isBroken || _tried.contains(lower)) {
      return DropResult.ignored;
    }
    if (_isAnswer(lower)) {
      _solved = true;
      return DropResult.correct;
    }
    _tried.add(lower);
    return isBroken ? DropResult.broken : DropResult.wrong;
  }

  void reset() {
    _tried.clear();
    _solved = false;
  }
}

/// Level 2: drop a conjunction onto the gap between two clauses.
class BridgeRound {
  BridgeRound(Bridge bridge, {required int maxWrongAnswers})
    : _bridge = bridge,
      _rules = _Rules(
        (lower) => bridge.conjunction.toLowerCase() == lower,
        maxWrongAnswers,
      );

  final Bridge _bridge;
  final _Rules _rules;

  DropResult drop(String word) => _rules.play(word);

  int get wrongCount => _rules.wrongCount;
  bool get isBuilt => _rules.isSolved;
  bool get isBroken => _rules.isBroken;
  Set<String> get triedWrong => _rules.triedWrong;

  String hintFor(String word) {
    final lower = word.toLowerCase();
    for (final entry in _bridge.hints.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return _bridge.defaultHint;
  }

  void reset() => _rules.reset();
}
