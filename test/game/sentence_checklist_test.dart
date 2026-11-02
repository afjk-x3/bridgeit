import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/game/sentence_checklist.dart';

List<bool> _met(String text, [String word = 'for']) => [
  for (final item in sentenceChecklist(text, word)) item.met,
];

void main() {
  test('labels name the word, in order', () {
    expect(sentenceChecklist('', 'for').map((i) => i.label), [
      'Starts with a capital',
      "Uses 'for'",
      "Comma right before 'for'",
      'Ends with . ! or ?',
    ]);
  });

  test('an empty box meets nothing', () {
    expect(_met(''), [false, false, false, false]);
  });

  test('a good sentence meets everything', () {
    expect(_met('I stayed inside, for it was raining.'), [
      true,
      true,
      true,
      true,
    ]);
  });

  test('missing capital, comma and end mark', () {
    expect(_met('i stayed inside for it was raining'), [
      false,
      true,
      false,
      false,
    ]);
  });

  test('any occurrence with the comma counts', () {
    expect(_met('For now, I wait, for she is late.')[2], isTrue);
  });

  test('the word must be whole', () {
    expect(_met('Before dinner, we ate.')[1], isFalse);
  });

  test('leading spaces are skipped', () {
    expect(_met('  It ran , for it was late!  '), [true, true, true, true]);
  });
}
