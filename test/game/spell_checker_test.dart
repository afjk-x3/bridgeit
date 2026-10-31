import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/content_repository.dart';
import 'package:bridgeit/content/lexicon.dart';
import 'package:bridgeit/game/spell_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Set<String> words;

  setUpAll(() async {
    words = await loadLexicon(rootBundle, 'assets/lexicon/words.txt');
  });

  List<String> misspelt(String text, {Set<String> allowed = const {}}) => [
    for (final span in SpellChecker(words, allowed: allowed).check(text))
      text.substring(span.start, span.end),
  ];

  test('the dictionary is the expected size and skips comments', () {
    expect(words.length, inInclusiveRange(60000, 90000));
    expect(words.any((w) => w.startsWith('#')), isFalse);
  });

  test('finds misspelt words and their positions', () {
    expect(misspelt('She went too the beech yesturday.'), ['yesturday']);
    expect(misspelt('Teh dog runned fastt.'), ['Teh', 'runned', 'fastt']);
    final span = SpellChecker(words).check('I saw a brid.').single;
    expect((span.start, span.end), (8, 12));
  });

  test('correct sentences give no warnings', () {
    expect(
      misspelt('The children played outside, and they were happy.'),
      isEmpty,
    );
  });

  test('capitalised words mid-sentence are names', () {
    expect(misspelt('We visited Maria and Pagudpud today.'), isEmpty);
  });

  test('the first word of each sentence is checked', () {
    expect(misspelt('Whan we left. Thier car broke.'), ['Whan', 'Thier']);
  });

  test('words with digits are skipped', () {
    expect(misspelt('We rode 4x4 jeeps in 2026.'), isEmpty);
  });

  test('contractions and possessives are checked by their base word', () {
    expect(misspelt("I can't go, and she won't, but we're fine."), isEmpty);
    expect(misspelt("Maria's dog isn't here."), isEmpty);
    expect(misspelt("She said the dogg's bowl is here."), ["dogg's"]);
    expect(misspelt('It’s fine.'), isEmpty);
  });

  test('allowed words are not flagged', () {
    expect(misspelt('we saw paoay.'), ['paoay']);
    expect(misspelt('we saw paoay.', allowed: {'paoay'}), isEmpty);
  });

  test('the bridge sentences in levels.json spell clean', () async {
    final content = await loadGameContent(rootBundle);
    final texts = [
      for (final bridge in content.level2.bridges) ...[
        '${bridge.left}, ${bridge.conjunction} ${bridge.right}',
        ...bridge.examples,
      ],
    ];
    for (final text in texts) {
      expect(misspelt(text), isEmpty, reason: text);
    }
  });
}
