import '../content/models.dart';

enum BlankResult { correct, wrong, alreadyFilled }

/// Fill-in-the-blanks rules for Level 1. Blanks are numbered 0.. across all
/// verses in reading order. Words match case-insensitively.
class BlanksRound {
  BlanksRound(List<Verse> verses) {
    for (final verse in verses) {
      _verseStarts.add(_answers.length);
      for (final line in verse.lines) {
        for (final part in line) {
          if (part is BlankPart) _answers.add(part.answer);
        }
      }
    }
    _verseStarts.add(_answers.length);
    _filled = List.filled(_answers.length, false);
  }

  final List<String> _answers = [];
  // _verseStarts[v] is the first blank of verse v; the last entry is the end.
  final List<int> _verseStarts = [];
  late final List<bool> _filled;

  int get blankCount => _answers.length;

  bool get isComplete => _filled.every((f) => f);

  /// The blank's own answer (original casing) once filled, else null.
  String? filledAt(int blankIndex) =>
      _filled[blankIndex] ? _answers[blankIndex] : null;

  int verseStart(int verse) => _verseStarts[verse];

  bool isVerseComplete(int verse) => _filled
      .sublist(_verseStarts[verse], _verseStarts[verse + 1])
      .every((f) => f);

  BlankResult place(int blankIndex, String word) {
    if (_filled[blankIndex]) return BlankResult.alreadyFilled;
    if (word.toLowerCase() != _answers[blankIndex].toLowerCase()) {
      return BlankResult.wrong;
    }
    _filled[blankIndex] = true;
    return BlankResult.correct;
  }
}
