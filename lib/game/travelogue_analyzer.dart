import 'package:bridgeit/content/models.dart';

import 'clause_check.dart';

/// A stretch of the entry, as offsets into its text.
class EntrySpan {
  const EntrySpan(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is EntrySpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '($start, $end)';
}

class TravelogueResult {
  const TravelogueResult({
    required this.sentenceCount,
    required this.counted,
    required this.uncounted,
    required this.canSubmit,
  });

  static const empty = TravelogueResult(
    sentenceCount: 0,
    counted: [],
    uncounted: [],
    canSubmit: false,
  );

  final int sentenceCount;

  /// FANBOYS words that join two clauses.
  final List<EntrySpan> counted;

  /// FANBOYS words after a comma that don't join two clauses.
  final List<EntrySpan> uncounted;
  final bool canSubmit;
}

/// The Submit button's label: what is still missing, or "Submit".
String submitLabel(TravelogueResult result, TravelogueRules rules) {
  String count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';
  if (result.canSubmit) return 'Submit';
  final sentences = result.sentenceCount;
  if (sentences < rules.minSentences) {
    return 'Write ${count(rules.minSentences - sentences, 'more sentence')} '
        'to submit';
  }
  if (sentences > rules.maxSentences) {
    return 'Remove ${count(sentences - rules.maxSentences, 'sentence')} '
        'to submit';
  }
  final missing = rules.minConjunctions - result.counted.length;
  return 'Use ${count(missing, 'more conjunction')} to submit';
}

/// Counts sentences and the coordinating conjunctions that join clauses.
class TravelogueAnalyzer {
  const TravelogueAnalyzer(this._clauses, this._rules);

  final ClauseChecker _clauses;
  final TravelogueRules _rules;

  static final _sentenceEnd = RegExp(
    r'(?<!\b(?:Mr|Mrs|Ms|Dr|St|Sr|Jr))[.!?]+(?=\s|$)',
  );
  static final _candidate = RegExp(
    r',\s*(for|and|nor|but|or|yet|so)\b',
    caseSensitive: false,
  );

  TravelogueResult analyze(String text) {
    final counted = <EntrySpan>[];
    final uncounted = <EntrySpan>[];
    var sentences = 0;
    var start = 0;
    for (final end in _sentenceEnd.allMatches(text)) {
      if (_hasLetters(text.substring(start, end.start))) {
        sentences++;
        _scan(text, start, end.start, counted, uncounted);
      }
      start = end.end;
    }
    // Text after the last end mark is still being written: its conjunctions
    // show, but it isn't a sentence yet.
    if (_hasLetters(text.substring(start))) {
      _scan(text, start, text.length, counted, uncounted);
    }
    return TravelogueResult(
      sentenceCount: sentences,
      counted: counted,
      uncounted: uncounted,
      canSubmit:
          sentences >= _rules.minSentences &&
          sentences <= _rules.maxSentences &&
          counted.length >= _rules.minConjunctions,
    );
  }

  static bool _hasLetters(String text) => text.contains(RegExp('[A-Za-z]'));

  void _scan(
    String text,
    int start,
    int end,
    List<EntrySpan> counted,
    List<EntrySpan> uncounted,
  ) {
    final sentence = text.substring(start, end);
    final candidates = _candidate.allMatches(sentence).toList();
    var boundary = 0;
    for (var i = 0; i < candidates.length; i++) {
      final match = candidates[i];
      final rightEnd = i + 1 < candidates.length
          ? candidates[i + 1].start
          : sentence.length;
      final left = sentence.substring(boundary, match.start);
      final right = sentence.substring(match.end, rightEnd);
      final joins =
          _clauses.check(left, imperativeAllowed: boundary == 0) !=
              ClauseVerdict.fail &&
          _clauses.check(right) != ClauseVerdict.fail;
      final word = match[1]!;
      final range = EntrySpan(
        start + match.end - word.length,
        start + match.end,
      );
      if (joins) {
        counted.add(range);
        boundary = match.end;
      } else {
        uncounted.add(range);
      }
    }
  }
}
