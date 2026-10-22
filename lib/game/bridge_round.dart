import 'dart:collection';

import 'package:bridgeit/content/models.dart';

enum DropResult { correct, wrong, broken, ignored }

/// Shared rules for one bridge or synonym round. Words match
/// case-insensitively; tried words are stored lowercased.
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
  BridgeRound(BridgeSentence sentence, {required int maxWrongAnswers})
    : _sentence = sentence,
      _rules = _Rules(
        (lower) => sentence.answers.any((a) => a.toLowerCase() == lower),
        maxWrongAnswers,
      );

  final BridgeSentence _sentence;
  final _Rules _rules;

  DropResult drop(String word) => _rules.play(word);

  int get wrongCount => _rules.wrongCount;
  bool get isBuilt => _rules.isSolved;
  bool get isBroken => _rules.isBroken;
  Set<String> get triedWrong => _rules.triedWrong;

  String hintFor(String word) {
    final lower = word.toLowerCase();
    for (final entry in _sentence.hints.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return _sentence.defaultHint;
  }

  void reset() => _rules.reset();
}

/// Level 3: pick the synonym of the conjunction that bridges the sentence.
class SynonymRound {
  SynonymRound(BridgeSentence sentence, {required int maxWrongAnswers})
    : _rules = _Rules(_matcher(sentence), maxWrongAnswers);

  static bool Function(String) _matcher(BridgeSentence sentence) {
    final answer = sentence.synonymAnswer?.toLowerCase();
    if (answer == null) {
      throw ArgumentError.value(sentence, 'sentence', 'synonymAnswer is null');
    }
    return (lower) => lower == answer;
  }

  final _Rules _rules;

  DropResult choose(String option) => _rules.play(option);

  bool get isReinforced => _rules.isSolved;
  bool get isBroken => _rules.isBroken;
  Set<String> get triedWrong => _rules.triedWrong;

  void reset() => _rules.reset();
}
