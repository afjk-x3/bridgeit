import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/match_it_round.dart';

const _pairs = [
  MatchPair(conjunction: 'for', function: 'reason'),
  MatchPair(conjunction: 'and', function: 'adds'),
  MatchPair(conjunction: 'but', function: 'contrast'),
];

MatchItRound _round() => MatchItRound(_pairs, random: Random(1));

void main() {
  test('starts with every function in the tray and nothing placed', () {
    final round = _round();
    expect(round.tray.toSet(), {'reason', 'adds', 'contrast'});
    expect(round.placed, isEmpty);
    expect(round.canSubmit, isFalse);
  });

  test('place moves a function out of the tray', () {
    final round = _round()..place('for', 'adds');
    expect(round.placed, {'for': 'adds'});
    expect(round.tray, isNot(contains('adds')));
  });

  test('placing over a filled slot returns the old function', () {
    final round = _round()
      ..place('for', 'adds')
      ..place('for', 'reason');
    expect(round.placed, {'for': 'reason'});
    expect(round.tray, contains('adds'));
  });

  test('a function moved to another slot leaves its old slot', () {
    final round = _round()
      ..place('for', 'adds')
      ..place('and', 'adds');
    expect(round.placed, {'and': 'adds'});
  });

  test('remove returns a function to the tray', () {
    final round = _round()
      ..place('for', 'adds')
      ..remove('for');
    expect(round.placed, isEmpty);
    expect(round.tray, contains('adds'));
  });

  test('unknown conjunction is ignored', () {
    final round = _round()..place('yet', 'adds');
    expect(round.placed, isEmpty);
  });

  test('submit waits until every slot is filled', () {
    final round = _round()..place('for', 'reason');
    expect(round.submit(), isEmpty);
    expect(round.attempts, isEmpty);
    expect(round.isLocked('for'), isFalse);
  });

  test('submit keeps right pairs and returns wrong ones', () {
    final round = _round()
      ..place('for', 'reason')
      ..place('and', 'contrast')
      ..place('but', 'adds');

    expect(round.submit(), ['and', 'but']);
    expect(round.placed, {'for': 'reason'});
    expect(round.isLocked('for'), isTrue);
    expect(round.tray.toSet(), {'adds', 'contrast'});
    expect(round.isDone, isFalse);
    expect(round.attempts, [
      ['and', 'but'],
    ]);
  });

  test('a locked pair cannot be changed or moved', () {
    final round = _round()
      ..place('for', 'reason')
      ..place('and', 'contrast')
      ..place('but', 'adds')
      ..submit()
      ..remove('for')
      ..place('for', 'adds')
      ..place('and', 'reason');

    expect(round.placed, {'for': 'reason'});
  });

  test('done when all pairs are right, with every attempt logged', () {
    final round = _round()
      ..place('for', 'reason')
      ..place('and', 'contrast')
      ..place('but', 'adds')
      ..submit()
      ..place('and', 'adds')
      ..place('but', 'contrast');

    expect(round.submit(), isEmpty);
    expect(round.isDone, isTrue);
    expect(round.attempts, [
      ['and', 'but'],
      <String>[],
    ]);
    expect(round.submit(), isEmpty);
    expect(round.attempts, hasLength(2));
  });

  test('the tray order does not follow the answers', () {
    final orders = {
      for (var seed = 0; seed < 8; seed++)
        MatchItRound(_pairs, random: Random(seed)).tray.join(),
    };
    expect(orders.length, greaterThan(1));
  });
}
