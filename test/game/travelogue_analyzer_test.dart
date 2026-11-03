import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/lexicon.dart';
import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/clause_check.dart';
import 'package:bridgeit/game/travelogue_analyzer.dart';

const _good =
    'We went to the dunes, and we rode a jeep. '
    'The sand was hot, but the wind was cool. '
    'I wanted to stay, yet we had to go. '
    'I was tired, so I slept in the car. '
    'It was the best trip of my life.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TravelogueAnalyzer analyzer;

  setUpAll(() async {
    final verbs = await loadLexicon(rootBundle, 'assets/lexicon/verbs.txt');
    analyzer = TravelogueAnalyzer(
      ClauseChecker(verbs, minWords: 2),
      const TravelogueRules(
        minSentences: 5,
        maxSentences: 7,
        minConjunctions: 4,
      ),
    );
  });

  test('a good entry can be submitted', () {
    final result = analyzer.analyze(_good);
    expect(result.sentenceCount, 5);
    expect(result.counted, hasLength(4));
    expect(result.uncounted, isEmpty);
    expect(result.canSubmit, isTrue);
  });

  test('counted spans sit on the words', () {
    const text = 'We ran, and they sat.';
    final span = analyzer.analyze(text).counted.single;
    expect(text.substring(span.start, span.end), 'and');
  });

  test('too few sentences cannot be submitted', () {
    final text = _good.split('. ').take(4).join('. ');
    final result = analyzer.analyze('$text.');
    expect(result.sentenceCount, 4);
    expect(result.canSubmit, isFalse);
  });

  test('too many sentences cannot be submitted', () {
    final result = analyzer.analyze('$_good We sang. We ate. We slept.');
    expect(result.sentenceCount, 8);
    expect(result.canSubmit, isFalse);
  });

  test('too few conjunctions cannot be submitted', () {
    final result = analyzer.analyze(
      'We went to the dunes, and we rode a jeep. '
      'The sand was hot, but the wind was cool. '
      'I was tired, so I slept in the car. '
      'We went home. It was fun.',
    );
    expect(result.counted, hasLength(3));
    expect(result.canSubmit, isFalse);
  });

  test('a word that does not join clauses is shown but not counted', () {
    const text = 'We saw birds, and big red crabs.';
    final result = analyzer.analyze(text);
    expect(result.counted, isEmpty);
    final span = result.uncounted.single;
    expect(text.substring(span.start, span.end), 'and');
  });

  test('a clause join without a comma is shown but not counted', () {
    const text =
        'The cool breeze drifted through the courtyard so the atmosphere '
        'felt serene.';
    final result = analyzer.analyze(text);
    expect(result.counted, isEmpty);
    final span = result.uncounted.single;
    expect(text.substring(span.start, span.end), 'so');
  });

  test('two verbs joined without a comma are left unmarked', () {
    final result = analyzer.analyze(
      'John rode his motorcycle along the highway and arrived at the church.',
    );
    expect(result.counted, isEmpty);
    expect(result.uncounted, isEmpty);
  });

  test('words containing a conjunction are ignored', () {
    final result = analyzer.analyze('We ran, android phones were sold.');
    expect(result.counted, isEmpty);
    expect(result.uncounted, isEmpty);
  });

  test('a list before the conjunction still counts the join', () {
    final result = analyzer.analyze('We ran, we sang, and we danced.');
    expect(result.counted, hasLength(1));
  });

  test('two joins in one sentence both count', () {
    final result = analyzer.analyze('We ran, and they sat, but I slept.');
    expect(result.counted, hasLength(2));
  });

  test('titles do not end a sentence', () {
    expect(analyzer.analyze('Mr. Cruz came. We ran.').sentenceCount, 2);
  });

  test('text without an end mark is not a sentence yet', () {
    final result = analyzer.analyze('We ran. They sat, and I');
    expect(result.sentenceCount, 1);
  });

  group('submitLabel', () {
    const rules = TravelogueRules(
      minSentences: 5,
      maxSentences: 7,
      minConjunctions: 4,
    );
    TravelogueResult result(int sentences, int conjunctions) =>
        TravelogueResult(
          sentenceCount: sentences,
          counted: [for (var i = 0; i < conjunctions; i++) EntrySpan(i, i)],
          uncounted: const [],
          canSubmit: sentences >= 5 && sentences <= 7 && conjunctions >= 4,
        );

    test('too few sentences', () {
      expect(
        submitLabel(result(1, 1), rules),
        'Write 4 more sentences to submit',
      );
      expect(
        submitLabel(result(4, 4), rules),
        'Write 1 more sentence to submit',
      );
    });

    test('too few conjunctions', () {
      expect(
        submitLabel(result(5, 3), rules),
        'Use 1 more conjunction to submit',
      );
      expect(
        submitLabel(result(5, 1), rules),
        'Use 3 more conjunctions to submit',
      );
    });

    test('too many sentences', () {
      expect(submitLabel(result(8, 4), rules), 'Remove 1 sentence to submit');
      expect(submitLabel(result(9, 4), rules), 'Remove 2 sentences to submit');
    });

    test('a passing entry', () {
      expect(submitLabel(result(5, 4), rules), 'Submit');
    });
  });

  test('empty text', () {
    final result = analyzer.analyze('   ');
    expect(result.sentenceCount, 0);
    expect(result.canSubmit, isFalse);
  });
}
