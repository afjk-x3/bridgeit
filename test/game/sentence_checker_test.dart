import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/lexicon.dart';
import 'package:bridgeit/game/clause_check.dart';
import 'package:bridgeit/game/sentence_checker.dart';

const _pass = 'pass';
const _unsure = 'unsure';

/// Sentence, target word, rule, and the expected result.
const List<(String, String, WordRule, Object)> _table = [
  // Passing: fanboys.
  ('She went to bed early, for she was tired.', 'for', WordRule.fanboys, _pass),
  (
    'The sun was shining, and the birds were singing.',
    'and',
    WordRule.fanboys,
    _pass,
  ),
  (
    'He does not like coffee, nor does he drink tea.',
    'nor',
    WordRule.fanboys,
    _pass,
  ),
  ('I like pizza, but I don\'t like onions.', 'but', WordRule.fanboys, _pass),
  (
    'I can walk to school, or I can take the bus.',
    'or',
    WordRule.fanboys,
    _pass,
  ),
  (
    'The test was very hard, yet she finished it early.',
    'yet',
    WordRule.fanboys,
    _pass,
  ),
  ("I'm very tired, so I will sleep.", 'so', WordRule.fanboys, _pass),
  (
    'Maria sings well, and Ben plays the guitar.',
    'and',
    WordRule.fanboys,
    _pass,
  ),
  (
    'We waited for the bus, for it was raining.',
    'for',
    WordRule.fanboys,
    _pass,
  ),
  (
    'Mr. Cruz teaches math, and he loves his class.',
    'and',
    WordRule.fanboys,
    _pass,
  ),
  (
    'My brother can\'t swim, but he isn\'t afraid.',
    'but',
    WordRule.fanboys,
    _pass,
  ),
  ('It rained all day, SO we stayed home.', 'so', WordRule.fanboys, _pass),
  ('Did you eat lunch, or did you skip it?', 'or', WordRule.fanboys, _pass),
  (
    'What a great day it was, and we had so much fun!',
    'and',
    WordRule.fanboys,
    _pass,
  ),
  ('  She   smiled,  and  he   waved  back. ', 'and', WordRule.fanboys, _pass),
  ('She’s happy, for she won the game.', 'for', WordRule.fanboys, _pass),
  // Passing: joining.
  ('She stayed home because she was sick.', 'because', WordRule.joining, _pass),
  (
    'Because she was sick, she stayed home.',
    'because',
    WordRule.joining,
    _pass,
  ),
  (
    'We left early since the road was closed.',
    'since',
    WordRule.joining,
    _pass,
  ),
  (
    'Since the road was closed, we left early.',
    'since',
    WordRule.joining,
    _pass,
  ),
  ('He smiled as she walked in.', 'as', WordRule.joining, _pass),
  (
    'Although it rained, we played outside.',
    'although',
    WordRule.joining,
    _pass,
  ),
  (
    'I went out even though I was tired.',
    'even though',
    WordRule.joining,
    _pass,
  ),
  (
    'Even though I was tired, I went out.',
    'even though',
    WordRule.joining,
    _pass,
  ),
  // Passing: linking.
  ('It was raining; however, we went out.', 'however', WordRule.linking, _pass),
  (
    'She studied hard; therefore, she passed.',
    'therefore',
    WordRule.linking,
    _pass,
  ),
  (
    'He loves art; moreover, he paints well.',
    'moreover',
    WordRule.linking,
    _pass,
  ),
  (
    'We ran fast; in addition, we saved time.',
    'in addition',
    WordRule.linking,
    _pass,
  ),
  (
    'The bus broke down; as a result, we were late.',
    'as a result',
    WordRule.linking,
    _pass,
  ),
  (
    'It was late; nevertheless, she kept working.',
    'nevertheless',
    WordRule.linking,
    _pass,
  ),
  // Unsure: passes with a hint.
  ('Hurry up now, or you will miss the bus.', 'or', WordRule.fanboys, _unsure),
  ('I like cats, and dogs like me.', 'and', WordRule.fanboys, _unsure),
  ('We flaxed it, and the cat sleeps here.', 'and', WordRule.fanboys, _unsure),
  (
    'My three dogs, and the cat sleeps here.',
    'and',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  // Shape.
  ('', 'and', WordRule.fanboys, CheckFailure.empty),
  ('   ', 'and', WordRule.fanboys, CheckFailure.empty),
  ('she ran, and he walked.', 'and', WordRule.fanboys, CheckFailure.capital),
  (
    'She ran, and he walked',
    'and',
    WordRule.fanboys,
    CheckFailure.endPunctuation,
  ),
  (
    'She ran, and he walked,',
    'and',
    WordRule.fanboys,
    CheckFailure.endPunctuation,
  ),
  (
    'She ran. He walked, and I sat.',
    'and',
    WordRule.fanboys,
    CheckFailure.oneSentence,
  ),
  (
    'I ran! You walked, and I sat.',
    'and',
    WordRule.fanboys,
    CheckFailure.oneSentence,
  ),
  // Junk.
  ('Aaaaaa ran, and he walked.', 'and', WordRule.fanboys, CheckFailure.notReal),
  (
    'Asdfghjklqwertyuiopzxcvb, and he walked.',
    'and',
    WordRule.fanboys,
    CheckFailure.notReal,
  ),
  ('1234 5678 9012, and 345.', 'and', WordRule.fanboys, CheckFailure.notReal),
  // Target word.
  (
    'She ran, but he walked.',
    'and',
    WordRule.fanboys,
    CheckFailure.missingWord,
  ),
  (
    'Sandy ran, then he walked.',
    'and',
    WordRule.fanboys,
    CheckFailure.missingWord,
  ),
  (
    'She ran, so he walked.',
    'in addition',
    WordRule.linking,
    CheckFailure.missingWord,
  ),
  // Punctuation.
  ('She ran and he walked.', 'and', WordRule.fanboys, CheckFailure.comma),
  (
    'I went to school for I like it.',
    'for',
    WordRule.fanboys,
    CheckFailure.comma,
  ),
  (
    'It rained; however we went out.',
    'however',
    WordRule.linking,
    CheckFailure.semicolon,
  ),
  (
    'It rained, however, we went out.',
    'however',
    WordRule.linking,
    CheckFailure.semicolon,
  ),
  (
    'It rained however, we went out.',
    'however',
    WordRule.linking,
    CheckFailure.semicolon,
  ),
  // Left clause.
  (
    'Very happy, and he walked home.',
    'and',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  (
    'In the morning, and he walked home.',
    'and',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  (
    'To the park, for it was sunny.',
    'for',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  (
    'Because the big dog, she stayed home.',
    'because',
    WordRule.joining,
    CheckFailure.leftClause,
  ),
  (
    'A big red house; however, we went out.',
    'however',
    WordRule.linking,
    CheckFailure.leftClause,
  ),
  // Right clause.
  (
    'She left early, for the bus.',
    'for',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'He ate the cake, and the big red apple.',
    'and',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'She went home, and walked to school.',
    'and',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'She went home, but in the morning.',
    'but',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'She stayed home because of the rain.',
    'because',
    WordRule.joining,
    CheckFailure.rightClause,
  ),
  (
    'Because she was sick she stayed home.',
    'because',
    WordRule.joining,
    CheckFailure.comma,
  ),
  // Dependent clauses are not independent clauses.
  (
    'Because she was sick, and he left.',
    'and',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  (
    'She stayed home, and although it rained.',
    'and',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'Even though she was sick, and he left.',
    'and',
    WordRule.fanboys,
    CheckFailure.leftClause,
  ),
  ('When it rained, we ran, and she sang.', 'and', WordRule.fanboys, _pass),
  ('After the game ended, and we left.', 'and', WordRule.fanboys, _unsure),
  // Nor: a negative first, then the auxiliary before the subject.
  ('She never calls, nor does she write.', 'nor', WordRule.fanboys, _pass),
  (
    "We didn't see the castle, nor did we see it.",
    'nor',
    WordRule.fanboys,
    _pass,
  ),
  (
    'He does not like coffee, nor he drinks tea.',
    'nor',
    WordRule.fanboys,
    CheckFailure.norWordOrder,
  ),
  (
    'I like tea, nor do I drink coffee.',
    'nor',
    WordRule.fanboys,
    CheckFailure.norNeedsNegative,
  ),
  // No comma before a joining word in the middle.
  (
    'We stayed home, because it rained.',
    'because',
    WordRule.joining,
    CheckFailure.extraComma,
  ),
  (
    'It rained, although we went out.',
    'although',
    WordRule.joining,
    CheckFailure.extraComma,
  ),
  // Commands have an understood "you".
  ('Open the door, and come in.', 'and', WordRule.fanboys, _unsure),
  (
    'She went home, and walked to school.',
    'and',
    WordRule.fanboys,
    CheckFailure.rightClause,
  ),
  (
    'It rained; however, the very long road.',
    'however',
    WordRule.linking,
    CheckFailure.rightClause,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SentenceChecker checker;

  setUpAll(() async {
    final verbs = await loadLexicon(rootBundle, 'assets/lexicon/verbs.txt');
    checker = SentenceChecker(ClauseChecker(verbs, minWords: 2));
  });

  test('the table covers at least 60 sentences', () {
    expect(_table.length, greaterThanOrEqualTo(60));
  });

  for (final (i, (text, word, rule, expected)) in _table.indexed) {
    test('#$i $text', () {
      final result = checker.check(text, word: word, rule: rule);
      switch (expected) {
        case _pass:
          expect(
            result,
            isA<Passed>().having((p) => p.unsureClause, 'unsure', false),
          );
        case _unsure:
          expect(
            result,
            isA<Passed>().having((p) => p.unsureClause, 'unsure', true),
          );
        case final CheckFailure reason:
          expect(
            result,
            isA<Failed>().having((f) => f.reason, 'reason', reason),
          );
      }
    });
  }

  group('copies', () {
    const forbidden = ['She went to bed early, for she was tired.'];

    test('an exact copy fails, ignoring case and spaces', () {
      for (final text in [
        'She went to bed early, for she was tired.',
        'She  went to bed EARLY,  for she was tired. ',
      ]) {
        expect(
          checker.check(
            text,
            word: 'for',
            rule: WordRule.fanboys,
            forbidden: forbidden,
          ),
          isA<Failed>().having((f) => f.reason, 'reason', CheckFailure.copied),
        );
      }
    });

    test('a changed sentence passes', () {
      expect(
        checker.check(
          'She went to bed early, for she was sleepy.',
          word: 'for',
          rule: WordRule.fanboys,
          forbidden: forbidden,
        ),
        isA<Passed>(),
      );
    });
  });

  test('the lexicon holds all verb forms and skips comments', () async {
    final verbs = await loadLexicon(rootBundle, 'assets/lexicon/verbs.txt');
    expect(
      verbs,
      containsAll(['walk', 'walks', 'walked', 'walking', 'go', 'went', 'gone']),
    );
    expect(verbs.any((v) => v.startsWith('#')), isFalse);
  });
}
