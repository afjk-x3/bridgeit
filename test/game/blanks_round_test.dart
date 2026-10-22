import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/blanks_round.dart';

void main() {
  // Blank indexes: 0 for, 1 And (verse 0); 2 so (verse 1).
  late BlanksRound round;

  setUp(() {
    round = BlanksRound(const [
      Verse(
        title: 'one',
        lines: [
          [
            TextPart('F is '),
            BlankPart('for'),
            TextPart(', '),
            BlankPart('And'),
          ],
        ],
      ),
      Verse(
        title: 'two',
        lines: [
          [BlankPart('so'), TextPart('!')],
        ],
      ),
    ]);
  });

  test('counts blanks across all verses', () {
    expect(round.blankCount, 3);
    expect(round.filledAt(0), isNull);
  });

  test('correct word fills blank', () {
    expect(round.place(0, 'for'), BlankResult.correct);
    expect(round.filledAt(0), 'for');
  });

  test('comparison ignores case and keeps the answer casing', () {
    expect(round.place(1, 'and'), BlankResult.correct);
    expect(round.filledAt(1), 'And');
  });

  test('wrong word leaves blank empty and can retry forever', () {
    for (var i = 0; i < 10; i++) {
      expect(round.place(0, 'but'), BlankResult.wrong);
      expect(round.filledAt(0), isNull);
    }
    expect(round.place(0, 'for'), BlankResult.correct);
    expect(round.filledAt(0), 'for');
  });

  test('filled blank reports alreadyFilled', () {
    round.place(0, 'for');
    expect(round.place(0, 'for'), BlankResult.alreadyFilled);
    expect(round.place(0, 'but'), BlankResult.alreadyFilled);
    expect(round.filledAt(0), 'for');
  });

  test('isComplete after all blanks', () {
    round.place(0, 'for');
    round.place(1, 'and');
    expect(round.isComplete, isFalse);
    round.place(2, 'so');
    expect(round.isComplete, isTrue);
  });

  test('verse helpers map verses to blank indexes', () {
    expect(round.verseStart(0), 0);
    expect(round.verseStart(1), 2);
    expect(round.isVerseComplete(0), isFalse);
    round.place(0, 'for');
    round.place(1, 'and');
    expect(round.isVerseComplete(0), isTrue);
    expect(round.isVerseComplete(1), isFalse);
  });
}
