import 'package:flutter/services.dart';

import '../game/clause_check.dart';
import '../game/sentence_checker.dart';
import '../game/spell_checker.dart';
import 'models.dart';

/// The checkers for student writing, built once at startup.
class WritingTools {
  const WritingTools({
    required this.clauses,
    required this.sentences,
    required this.spelling,
  });

  final ClauseChecker clauses;
  final SentenceChecker sentences;
  final SpellChecker spelling;
}

Future<WritingTools> loadWritingTools(
  AssetBundle bundle,
  GameContent content,
) async {
  final verbs = await loadLexicon(bundle, 'assets/lexicon/verbs.txt');
  final words = await loadLexicon(bundle, 'assets/lexicon/words.txt');
  final clauses = ClauseChecker(verbs, minWords: content.minClauseWords);
  return WritingTools(
    clauses: clauses,
    sentences: SentenceChecker(clauses),
    spelling: SpellChecker(
      words,
      allowed: {
        for (final facts in content.quickFacts.values)
          for (final fact in facts) ...fact.word.split(' '),
        for (final place in content.level3.places)
          ...place.name.toLowerCase().split(RegExp('[^a-z]+')),
      },
    ),
  );
}

/// Loads a word list: one lowercase word per line, `#` lines are comments.
Future<Set<String>> loadLexicon(AssetBundle bundle, String path) async =>
    parseLexicon(await bundle.loadString(path));

Set<String> parseLexicon(String text) => {
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty && !line.startsWith('#')) line.trim(),
};
