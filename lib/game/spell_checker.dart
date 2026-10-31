const _contractionEndings = ["n't", "'s", "'re", "'ve", "'ll", "'d", "'m"];
const _irregularNegatives = {"can't", "won't", "shan't", "ain't"};

/// A word the dictionary doesn't know, as offsets into the checked text.
class SpellSpan {
  const SpellSpan(this.start, this.end);

  final int start;
  final int end;
}

/// Finds words to underline. A warning only: it never blocks the student.
/// [allowed] holds lowercase extras, such as place names and Quick Facts.
class SpellChecker {
  const SpellChecker(this._dictionary, {this.allowed = const {}});

  final Set<String> _dictionary;
  final Set<String> allowed;

  List<SpellSpan> check(String text) {
    final spans = <SpellSpan>[];
    final pattern = RegExp(r"[A-Za-z0-9]+(?:['’][A-Za-z]+)?");
    for (final match in pattern.allMatches(text)) {
      final word = match[0]!.replaceAll('’', "'");
      if (word.contains(RegExp('[0-9]'))) continue;
      final capitalized = word[0] != word[0].toLowerCase();
      if (capitalized && !_startsSentence(text, match.start)) continue;
      if (!_known(word.toLowerCase())) {
        spans.add(SpellSpan(match.start, match.end));
      }
    }
    return spans;
  }

  bool _known(String lower) {
    if (_irregularNegatives.contains(lower)) return true;
    for (final ending in _contractionEndings) {
      if (lower.endsWith(ending)) {
        return _isWord(lower.substring(0, lower.length - ending.length));
      }
    }
    return _isWord(lower);
  }

  bool _isWord(String lower) =>
      _dictionary.contains(lower) || allowed.contains(lower);

  static bool _startsSentence(String text, int index) =>
      RegExp(r'(?:^|[.!?])["\s]*$').hasMatch(text.substring(0, index));
}
