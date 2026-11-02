import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/bridge_round.dart';

const so = Bridge(
  conjunction: 'so',
  left: 'I was tired',
  right: 'I kept going',
  explanation: 'Going on is the result.',
  hints: {'and': 'That adds. Does it add here?'},
  defaultHint: 'Try again.',
  examples: ['It rained, so we stayed in.'],
);

void main() {
  group('BridgeRound', () {
    test('correct answer builds', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(round.drop('so'), DropResult.correct);
      expect(round.isBuilt, isTrue);
      expect(round.isBroken, isFalse);
      expect(round.wrongCount, 0);
    });

    test('answers match case-insensitively', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(round.drop('So'), DropResult.correct);
      expect(round.isBuilt, isTrue);
      expect(round.hintFor('AND'), 'That adds. Does it add here?');
    });

    test('wrong answers crack then break at max', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(round.drop('and'), DropResult.wrong);
      expect(round.drop('or'), DropResult.wrong);
      expect(round.drop('nor'), DropResult.broken);
      expect(round.wrongCount, 3);
      expect(round.isBroken, isTrue);
      expect(round.isBuilt, isFalse);
      expect(round.triedWrong, {'and', 'or', 'nor'});
    });

    test('same wrong word twice is ignored and counted once', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(round.drop('and'), DropResult.wrong);
      expect(round.drop('AND'), DropResult.ignored);
      expect(round.wrongCount, 1);
      expect(round.triedWrong, {'and'});
    });

    test('drop after built is ignored', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      round.drop('so');
      expect(round.drop('and'), DropResult.ignored);
      expect(round.wrongCount, 0);
    });

    test('drop after broken is ignored', () {
      final round = BridgeRound(so, maxWrongAnswers: 1);
      expect(round.drop('and'), DropResult.broken);
      expect(round.drop('so'), DropResult.ignored);
      expect(round.isBuilt, isFalse);
    });

    test('hint falls back to defaultHint', () {
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(round.hintFor('and'), 'That adds. Does it add here?');
      expect(round.hintFor('or'), 'Try again.');
    });

    test('a word with no hint of its own says what it does', () {
      final round = BridgeRound(
        so,
        maxWrongAnswers: 3,
        functions: {
          'nor': 'Connects negative alternatives.',
          'and': 'Adds or connects related ideas.',
        },
      );
      expect(round.hintFor('nor'), "'nor' connects negative alternatives.");
      expect(round.hintFor('and'), 'That adds. Does it add here?');
      expect(round.hintFor('or'), 'Try again.');
    });

    test('reset restores a fresh round', () {
      final round = BridgeRound(so, maxWrongAnswers: 2);
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
      final round = BridgeRound(so, maxWrongAnswers: 3);
      expect(() => round.triedWrong.add('x'), throwsUnsupportedError);
    });

    test('maxWrongAnswers below 1 throws', () {
      expect(() => BridgeRound(so, maxWrongAnswers: 0), throwsArgumentError);
    });
  });
}
