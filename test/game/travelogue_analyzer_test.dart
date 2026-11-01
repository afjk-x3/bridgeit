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

  test('a conjunction without a comma is ignored', () {
    final result = analyzer.analyze('We ran and they sat.');
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

  test('empty text', () {
    final result = analyzer.analyze('   ');
    expect(result.sentenceCount, 0);
    expect(result.canSubmit, isFalse);
  });
}
