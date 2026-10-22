import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

Future<GameContent> loadGameContent(
  AssetBundle bundle, {
  String path = 'assets/content/levels.json',
}) async => parseGameContent(await bundle.loadString(path));

GameContent parseGameContent(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw ContentException('invalid JSON: ${e.message}');
  }
  final root = _obj(decoded, 'levels.json');
  return GameContent(
    unlockCodes: _unlockCodes(_obj(root['unlockCodes'], 'unlockCodes')),
    level1: _level1(_obj(root['level1'], 'level1')),
    level2: _bridgeLevel(_obj(root['level2'], 'level2'), 'level2', false),
    level3: _bridgeLevel(_obj(root['level3'], 'level3'), 'level3', true),
  );
}

/// Splits `B is {but}, O is {or},` into text and blank parts.
/// [path] prefixes error messages.
List<LyricPart> parseLyricLine(String line, {String path = 'line'}) {
  final parts = <LyricPart>[];
  final text = StringBuffer();
  StringBuffer? blank;

  void flushText() {
    if (text.isEmpty) return;
    parts.add(TextPart(text.toString()));
    text.clear();
  }

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '{') {
      if (blank != null) throw ContentException('$path: nested "{" in "$line"');
      flushText();
      blank = StringBuffer();
    } else if (ch == '}') {
      if (blank == null) throw ContentException('$path: stray "}" in "$line"');
      final word = blank.toString();
      _checkFanboys(word, path);
      parts.add(BlankPart(word));
      blank = null;
    } else {
      (blank ?? text).write(ch);
    }
  }
  if (blank != null) throw ContentException('$path: unclosed "{" in "$line"');
  flushText();
  return parts;
}

/// Case-insensitive: lyrics may capitalize a blank at the start of a line.
void _checkFanboys(String word, String path) {
  if (!fanboys.contains(word.toLowerCase())) {
    throw ContentException('$path: "$word" is not a FANBOYS word');
  }
}

Map<int, String> _unlockCodes(Map<String, dynamic> raw) {
  final codes = <int, String>{};
  for (final entry in raw.entries) {
    final level = int.tryParse(entry.key);
    if (level == null) {
      throw ContentException(
        'unlockCodes.${entry.key}: key must be a level number',
      );
    }
    codes[level] = _str(entry.value, 'unlockCodes.${entry.key}');
  }
  for (final level in [2, 3]) {
    if (!codes.containsKey(level)) {
      throw ContentException('unlockCodes.$level: missing');
    }
  }
  return codes;
}

Level1Content _level1(Map<String, dynamic> raw) {
  final audio = raw['audioAsset'];
  if (audio != null && audio is! String) {
    throw const ContentException(
      'level1.audioAsset: expected a string or null',
    );
  }
  final verses = _list(raw['verses'], 'level1.verses');
  return Level1Content(
    audioAsset: audio as String?,
    verses: [
      for (var v = 0; v < verses.length; v++)
        _verse(_obj(verses[v], 'level1.verses[$v]'), 'level1.verses[$v]'),
    ],
  );
}

Verse _verse(Map<String, dynamic> raw, String path) {
  final lines = _list(raw['lines'], '$path.lines');
  return Verse(
    title: _str(raw['title'], '$path.title'),
    lines: [
      for (var l = 0; l < lines.length; l++)
        parseLyricLine(
          _str(lines[l], '$path.lines[$l]'),
          path: '$path.lines[$l]',
        ),
    ],
  );
}

BridgeLevelContent _bridgeLevel(
  Map<String, dynamic> raw,
  String path,
  bool requireSynonyms,
) {
  final max = raw['maxWrongAnswers'];
  if (max is! int || max < 1) {
    throw ContentException(
      '$path.maxWrongAnswers: expected a positive integer',
    );
  }
  final sentences = _list(raw['sentences'], '$path.sentences');
  return BridgeLevelContent(
    maxWrongAnswers: max,
    sentences: [
      for (var s = 0; s < sentences.length; s++)
        _sentence(
          _obj(sentences[s], '$path.sentences[$s]'),
          '$path.sentences[$s]',
          requireSynonyms,
        ),
    ],
  );
}

/// Level 3 sentences must carry synonym fields; level 2 may omit them.
BridgeSentence _sentence(
  Map<String, dynamic> raw,
  String path,
  bool requireSynonyms,
) {
  final answers = _strings(raw['answers'], '$path.answers');
  for (var a = 0; a < answers.length; a++) {
    _checkFanboys(answers[a], '$path.answers[$a]');
  }

  final rawHints = _obj(raw['hints'], '$path.hints');
  final hints = {
    for (final e in rawHints.entries)
      e.key: _str(e.value, '$path.hints.${e.key}'),
  };

  final omitted = !requireSynonyms;
  final choices = omitted && raw['synonymChoices'] == null
      ? <String>[]
      : _strings(raw['synonymChoices'], '$path.synonymChoices');
  final synonymAnswer = omitted && raw['synonymAnswer'] == null
      ? null
      : _str(raw['synonymAnswer'], '$path.synonymAnswer');
  if (requireSynonyms && choices.length < 2) {
    throw ContentException('$path.synonymChoices: need at least 2 choices');
  }
  if (synonymAnswer != null && !choices.contains(synonymAnswer)) {
    throw ContentException(
      '$path.synonymAnswer: "$synonymAnswer" is not in synonymChoices',
    );
  }

  return BridgeSentence(
    left: _str(raw['left'], '$path.left'),
    right: _str(raw['right'], '$path.right'),
    answers: answers,
    hints: hints,
    defaultHint: _str(raw['defaultHint'], '$path.defaultHint'),
    synonymChoices: choices,
    synonymAnswer: synonymAnswer,
  );
}

Map<String, dynamic> _obj(Object? v, String path) => v is Map<String, dynamic>
    ? v
    : throw ContentException('$path: expected an object');

List<dynamic> _list(Object? v, String path) => v is List && v.isNotEmpty
    ? v
    : throw ContentException('$path: expected a non-empty list');

String _str(Object? v, String path) =>
    v is String ? v : throw ContentException('$path: expected a string');

List<String> _strings(Object? v, String path) {
  final list = _list(v, path);
  return [for (var i = 0; i < list.length; i++) _str(list[i], '$path[$i]')];
}
