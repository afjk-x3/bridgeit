/// The seven coordinating conjunctions; the only words the game teaches.
const List<String> fanboys = ['for', 'and', 'nor', 'but', 'or', 'yet', 'so'];

/// Thrown when levels.json is malformed. [message] names the JSON path.
class ContentException implements Exception {
  const ContentException(this.message);

  final String message;

  @override
  String toString() => 'ContentException: $message';
}

/// One line of the sing-along card.
class LyricLine {
  const LyricLine({
    required this.startMs,
    required this.text,
    required this.image,
  });

  final int startMs;
  final String text;
  final String? image;
}

class MatchPair {
  const MatchPair({required this.conjunction, required this.function});

  final String conjunction;
  final String function;
}

class Level1Content {
  const Level1Content({
    required this.audioAsset,
    required this.playsRequired,
    required this.lyrics,
    required this.matchIt,
  });

  final String? audioAsset;
  final int playsRequired;
  final List<LyricLine> lyrics;
  final List<MatchPair> matchIt;
}

class Bridge {
  const Bridge({
    required this.conjunction,
    required this.left,
    required this.right,
    required this.explanation,
    required this.hints,
    required this.defaultHint,
    required this.examples,
  });

  final String conjunction;
  final String left;
  final String right;

  /// Shown when the right piece is placed.
  final String explanation;

  /// Hint shown after a wrong guess, keyed by the wrong word.
  final Map<String, String> hints;
  final String defaultHint;
  final List<String> examples;
}

class Level2Content {
  const Level2Content({required this.maxWrongAnswers, required this.bridges});

  final int maxWrongAnswers;
  final List<Bridge> bridges;
}

/// Linking words take `;` when they join two clauses, joining words usually
/// take no comma.
enum QuickFactRule { joining, linking }

class QuickFact {
  const QuickFact({required this.word, required this.rule});

  final String word;
  final QuickFactRule rule;
}

class TravelogueRules {
  const TravelogueRules({
    required this.minSentences,
    required this.maxSentences,
    required this.minConjunctions,
  });

  final int minSentences;
  final int maxSentences;
  final int minConjunctions;
}

class PlacePicture {
  const PlacePicture({required this.asset, required this.caption});

  final String asset;
  final String caption;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.pinX,
    required this.pinY,
    required this.pictures,
  });

  final String id;
  final String name;

  /// Pin position as a fraction of the map image.
  final double pinX;
  final double pinY;
  final List<PlacePicture> pictures;
}

class Level3Content {
  const Level3Content({
    required this.musicAsset,
    required this.travelogue,
    required this.places,
  });

  final String musicAsset;
  final TravelogueRules travelogue;
  final List<Place> places;
}

class GameContent {
  const GameContent({
    required this.unlockCodes,
    required this.level1,
    required this.level2,
    required this.quickFacts,
    required this.minClauseWords,
    required this.level3,
  });

  final Map<int, String> unlockCodes;
  final Level1Content level1;
  final Level2Content level2;

  /// Keyed by conjunction; no entry means one written sentence only.
  final Map<String, List<QuickFact>> quickFacts;
  final int minClauseWords;
  final Level3Content level3;
}
