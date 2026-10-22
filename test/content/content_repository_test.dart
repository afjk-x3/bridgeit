import 'dart:convert';

import 'package:bridgeit/content/content_repository.dart';
import 'package:bridgeit/content/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _text(String text) =>
    isA<TextPart>().having((p) => p.text, 'text', text);
Matcher _blank(String answer) =>
    isA<BlankPart>().having((p) => p.answer, 'answer', answer);

Matcher _contentError(String pathPart) => throwsA(
  isA<ContentException>().having(
    (e) => e.message,
    'message',
    contains(pathPart),
  ),
);

/// The bundled JSON as a mutable map, so each test can break one thing.
Future<Map<String, dynamic>> _bundledJson() async =>
    jsonDecode(await rootBundle.loadString('assets/content/levels.json'))
        as Map<String, dynamic>;

Map<String, dynamic> _sentence(
  Map<String, dynamic> json,
  String level,
  int i,
) =>
    ((json[level] as Map<String, dynamic>)['sentences'] as List)[i]
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseLyricLine', () {
    test('splits text and blanks', () {
      final parts = parseLyricLine('B is {but}, O is {or},');
      expect(parts, [
        _text('B is '),
        _blank('but'),
        _text(', O is '),
        _blank('or'),
        _text(','),
      ]);
    });

    test('throws on unclosed brace', () {
      expect(
        () => parseLyricLine('B is {but'),
        throwsA(isA<ContentException>()),
      );
    });

    test('keeps capitalized blank text', () {
      expect(parseLyricLine('{And} adds ideas'), [
        _blank('And'),
        _text(' adds ideas'),
      ]);
    });
  });

  group('parseGameContent', () {
    test('parses the bundled levels.json', () async {
      final content = await loadGameContent(rootBundle);
      expect(content.level2.maxWrongAnswers, 3);
      expect(content.unlockCodes[2], 'BRIDGE2');
      expect(content.level2.sentences, hasLength(3));
      expect(content.level3.sentences, hasLength(2));
      // Level 2 omits synonyms; they default.
      expect(content.level2.sentences[0].synonymChoices, isEmpty);
      expect(content.level2.sentences[0].synonymAnswer, isNull);
      // One level 2 sentence accepts two answers.
      expect(
        content.level2.sentences.map((s) => s.answers),
        anyElement(equals(['but', 'yet'])),
      );
    });

    test('rejects non-FANBOYS answer', () async {
      final json = await _bundledJson();
      _sentence(json, 'level2', 0)['answers'] = ['because'];
      expect(
        () => parseGameContent(jsonEncode(json)),
        _contentError('level2.sentences[0].answers'),
      );
    });

    test('rejects non-FANBOYS blank in a lyric line', () async {
      final json = await _bundledJson();
      final verse = ((json['level1'] as Map)['verses'] as List)[0] as Map;
      (verse['lines'] as List)[2] = 'B is {because}, O is {or},';
      expect(
        () => parseGameContent(jsonEncode(json)),
        _contentError('level1.verses[0].lines[2]'),
      );
    });

    test('rejects missing field', () async {
      final json = await _bundledJson()
        ..remove('level3');
      expect(() => parseGameContent(jsonEncode(json)), _contentError('level3'));
    });

    test('rejects invalid JSON', () {
      expect(
        () => parseGameContent('{not json'),
        throwsA(isA<ContentException>()),
      );
    });

    test('rejects synonymAnswer not in synonymChoices', () async {
      final json = await _bundledJson();
      _sentence(json, 'level3', 1)['synonymAnswer'] = 'banana';
      expect(
        () => parseGameContent(jsonEncode(json)),
        _contentError('level3.sentences[1].synonymAnswer'),
      );
    });

    test('level 3 requires synonymAnswer', () async {
      final json = await _bundledJson();
      _sentence(json, 'level3', 1).remove('synonymAnswer');
      expect(
        () => parseGameContent(jsonEncode(json)),
        _contentError('level3.sentences[1].synonymAnswer'),
      );
    });

    test('level 3 requires at least 2 synonymChoices', () async {
      final json = await _bundledJson();
      _sentence(json, 'level3', 1)['synonymChoices'] = ['however'];
      expect(
        () => parseGameContent(jsonEncode(json)),
        _contentError('level3.sentences[1].synonymChoices'),
      );
    });
  });
}
