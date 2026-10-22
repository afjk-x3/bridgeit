/// The seven coordinating conjunctions; the only words the game teaches.
const List<String> fanboys = ['for', 'and', 'nor', 'but', 'or', 'yet', 'so'];

/// Thrown when levels.json is malformed. [message] names the JSON path.
class ContentException implements Exception {
  const ContentException(this.message);

  final String message;

  @override
  String toString() => 'ContentException: $message';
}

sealed class LyricPart {
  const LyricPart();
}

final class TextPart extends LyricPart {
  const TextPart(this.text);

  final String text;
}

/// A word the player fills in. [answer] keeps the lyric's original casing.
final class BlankPart extends LyricPart {
  const BlankPart(this.answer);

  final String answer;
}

class Verse {
  const Verse({required this.title, required this.lines});

  final String title;
  final List<List<LyricPart>> lines;
}

class Level1Content {
  const Level1Content({required this.audioAsset, required this.verses});

  final String? audioAsset;
  final List<Verse> verses;
}

class BridgeSentence {
  const BridgeSentence({
    required this.left,
    required this.right,
    required this.answers,
    required this.hints,
    required this.defaultHint,
    required this.synonymChoices,
    required this.synonymAnswer,
  });

  final String left;
  final String right;
  final List<String> answers;

  /// Hint shown after a wrong guess, keyed by the wrong word.
  final Map<String, String> hints;
  final String defaultHint;
  final List<String> synonymChoices;
  final String? synonymAnswer;
}

class BridgeLevelContent {
  const BridgeLevelContent({
    required this.maxWrongAnswers,
    required this.sentences,
  });

  final int maxWrongAnswers;
  final List<BridgeSentence> sentences;
}

class GameContent {
  const GameContent({
    required this.unlockCodes,
    required this.level1,
    required this.level2,
    required this.level3,
  });

  final Map<int, String> unlockCodes;
  final Level1Content level1;
  final BridgeLevelContent level2;
  final BridgeLevelContent level3;
}
