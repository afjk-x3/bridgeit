import 'clause_check.dart';

enum WordRule { fanboys, joining, linking }

enum CheckFailure {
  empty,
  capital,
  endPunctuation,
  oneSentence,
  notReal,
  missingWord,
  comma,
  extraComma,
  semicolon,
  leftClause,
  rightClause,
  norNeedsNegative,
  norWordOrder,
  copied,
}

sealed class CheckResult {
  const CheckResult();
}

final class Passed extends CheckResult {
  const Passed({required this.unsureClause});

  /// The sentence passes, but a clause couldn't be confirmed: show a hint.
  final bool unsureClause;
}

final class Failed extends CheckResult {
  const Failed(this.reason);

  final CheckFailure reason;
}

/// Checks one student-written sentence. Stops at the first failure.
class SentenceChecker {
  const SentenceChecker(this._clauses);

  final ClauseChecker _clauses;

  CheckResult check(
    String input, {
    required String word,
    required WordRule rule,
    List<String> forbidden = const [],
  }) {
    final text = _normalise(input);

    final shape = _checkShape(text);
    if (shape != null) return Failed(shape);
    if (_isJunk(text)) return const Failed(CheckFailure.notReal);

    final hits = RegExp(
      "(?<![A-Za-z'])${RegExp.escape(word)}(?![A-Za-z'])",
      caseSensitive: false,
    ).allMatches(text).toList();
    if (hits.isEmpty) return const Failed(CheckFailure.missingWord);

    final String left;
    final String right;
    var leftStartsSentence = true;
    switch (rule) {
      case WordRule.fanboys:
        final hit = hits.where(
          (m) => text.substring(0, m.start).trimRight().endsWith(','),
        );
        if (hit.isEmpty) return const Failed(CheckFailure.comma);
        left = text.substring(0, hit.first.start);
        right = text.substring(hit.first.end);
      case WordRule.linking:
        final hit = hits.where(
          (m) =>
              text.substring(0, m.start).trimRight().endsWith(';') &&
              text.substring(m.end).trimLeft().startsWith(','),
        );
        if (hit.isEmpty) return const Failed(CheckFailure.semicolon);
        left = text.substring(0, hit.first.start);
        right = text.substring(hit.first.end);
      case WordRule.joining:
        final hit = hits.first;
        if (hit.start == 0) {
          final comma = text.indexOf(',', hit.end);
          if (comma < 0) return const Failed(CheckFailure.comma);
          left = text.substring(hit.end, comma);
          right = text.substring(comma);
          leftStartsSentence = false;
        } else {
          left = text.substring(0, hit.start);
          right = text.substring(hit.end);
          if (left.trimRight().endsWith(',')) {
            return const Failed(CheckFailure.extraComma);
          }
        }
    }

    final leftVerdict = _clauses.check(
      left,
      imperativeAllowed: leftStartsSentence,
    );
    if (leftVerdict == ClauseVerdict.fail) {
      return const Failed(CheckFailure.leftClause);
    }
    // Two commands can be joined: "Open the door, and come in."
    final rightVerdict = _clauses.check(
      right,
      imperativeAllowed: leftStartsSentence && _clauses.startsWithVerb(left),
    );
    if (rightVerdict == ClauseVerdict.fail) {
      return const Failed(CheckFailure.rightClause);
    }

    if (rule == WordRule.fanboys && word.toLowerCase() == 'nor') {
      if (!ClauseChecker.isNegative(left)) {
        return const Failed(CheckFailure.norNeedsNegative);
      }
      if (!_clauses.isInverted(right)) {
        return const Failed(CheckFailure.norWordOrder);
      }
    }

    final lower = text.toLowerCase();
    if (forbidden.any((f) => _normalise(f).toLowerCase() == lower)) {
      return const Failed(CheckFailure.copied);
    }
    return Passed(
      unsureClause:
          leftVerdict == ClauseVerdict.unsure ||
          rightVerdict == ClauseVerdict.unsure,
    );
  }

  static String _normalise(String input) => input
      .replaceAll(RegExp('[‘’]'), "'")
      .replaceAll(RegExp('[“”]'), '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static CheckFailure? _checkShape(String text) {
    if (text.isEmpty) return CheckFailure.empty;
    if (RegExp('^[a-z]').hasMatch(text)) return CheckFailure.capital;
    if (!RegExp(r'[.!?]$').hasMatch(text)) return CheckFailure.endPunctuation;
    final withoutTitles = text.replaceAll(
      RegExp(r'\b(?:Mr|Mrs|Ms|Dr|St|Sr|Jr)\.\s', caseSensitive: false),
      '',
    );
    if (RegExp(r'[.!?]\s+\S').hasMatch(withoutTitles)) {
      return CheckFailure.oneSentence;
    }
    return null;
  }

  static bool _isJunk(String text) {
    if (RegExp(r'([a-z])\1{3}', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    if (RegExp('[A-Za-z]{21}').hasMatch(text)) return true;
    final letters = RegExp('[A-Za-z]').allMatches(text).length;
    return letters / text.replaceAll(' ', '').length < 0.6;
  }
}
