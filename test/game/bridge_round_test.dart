import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/bridge_round.dart';

BridgeSentence bridge(List<String> answers) => BridgeSentence(
  left: 'I was tired',
  right: 'I kept going',
  answers: answers,
  hints: const {'and': 'That adds. Does it add here?'},
  defaultHint: 'Try again.',
  synonymChoices: const [],
  synonymAnswer: null,
);

const synonym = BridgeSentence(
  left: 'I was tired',
  right: 'I kept going',
  answers: ['but'],
  hints: {},
  defaultHint: 'Try again.',
  synonymChoices: ['however', 'because', 'also'],
  synonymAnswer: 'however',
);

void main() {
  group('BridgeRound', () {
    test('correct answer builds', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(round.drop('so'), DropResult.correct);
      expect(round.isBuilt, isTrue);
      expect(round.isBroken, isFalse);
      expect(round.wrongCount, 0);
    });

    test('either of two answers builds', () {
      for (final word in ['but', 'yet']) {
        final round = BridgeRound(bridge(['but', 'yet']), maxWrongAnswers: 3);
        expect(round.drop(word), DropResult.correct);
        expect(round.isBuilt, isTrue);
      }
    });

    test('answers match case-insensitively', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(round.drop('So'), DropResult.correct);
      expect(round.isBuilt, isTrue);
      expect(round.hintFor('AND'), 'That adds. Does it add here?');
    });

    test('wrong answers crack then break at max', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(round.drop('and'), DropResult.wrong);
      expect(round.drop('or'), DropResult.wrong);
      expect(round.drop('nor'), DropResult.broken);
      expect(round.wrongCount, 3);
      expect(round.isBroken, isTrue);
      expect(round.isBuilt, isFalse);
      expect(round.triedWrong, {'and', 'or', 'nor'});
    });

    test('same wrong word twice is ignored and counted once', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(round.drop('and'), DropResult.wrong);
      expect(round.drop('AND'), DropResult.ignored);
      expect(round.wrongCount, 1);
      expect(round.triedWrong, {'and'});
    });

    test('drop after built is ignored', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      round.drop('so');
      expect(round.drop('and'), DropResult.ignored);
      expect(round.wrongCount, 0);
    });

    test('drop after broken is ignored', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 1);
      expect(round.drop('and'), DropResult.broken);
      expect(round.drop('so'), DropResult.ignored);
      expect(round.isBuilt, isFalse);
    });

    test('hint falls back to defaultHint', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(round.hintFor('and'), 'That adds. Does it add here?');
      expect(round.hintFor('or'), 'Try again.');
    });

    test('reset restores a fresh round', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 2);
      round.drop('and');
      round.drop('or');
      round.reset();
      expect(round.isBroken, isFalse);
      expect(round.wrongCount, 0);
      expect(round.triedWrong, isEmpty);
      expect(round.drop('and'), DropResult.wrong);
      round.reset();
      expect(round.drop('so'), DropResult.correct);
      expect(round.isBuilt, isTrue);
      round.reset();
      expect(round.isBuilt, isFalse);
    });

    test('triedWrong is unmodifiable', () {
      final round = BridgeRound(bridge(['so']), maxWrongAnswers: 3);
      expect(() => round.triedWrong.add('x'), throwsUnsupportedError);
    });

    test('maxWrongAnswers below 1 throws', () {
      expect(
        () => BridgeRound(bridge(['so']), maxWrongAnswers: 0),
        throwsArgumentError,
      );
    });
  });

  group('SynonymRound', () {
    test('synonym correct reinforces', () {
      final round = SynonymRound(synonym, maxWrongAnswers: 3);
      expect(round.choose('However'), DropResult.correct);
      expect(round.isReinforced, isTrue);
      expect(round.isBroken, isFalse);
    });

    test('synonym wrong breaks at max', () {
      final round = SynonymRound(synonym, maxWrongAnswers: 2);
      expect(round.choose('because'), DropResult.wrong);
      expect(round.choose('because'), DropResult.ignored);
      expect(round.choose('also'), DropResult.broken);
      expect(round.isBroken, isTrue);
      expect(round.isReinforced, isFalse);
      expect(round.triedWrong, {'because', 'also'});
      expect(round.choose('however'), DropResult.ignored);
    });

    test('reset restores a fresh round', () {
      final round = SynonymRound(synonym, maxWrongAnswers: 1);
      round.choose('also');
      round.reset();
      expect(round.isBroken, isFalse);
      expect(round.triedWrong, isEmpty);
      expect(round.choose('however'), DropResult.correct);
    });

    test('null synonymAnswer throws', () {
      expect(
        () => SynonymRound(bridge(['so']), maxWrongAnswers: 3),
        throwsArgumentError,
      );
    });

    test('maxWrongAnswers below 1 throws', () {
      expect(
        () => SynonymRound(synonym, maxWrongAnswers: 0),
        throwsArgumentError,
      );
    });
  });
}
