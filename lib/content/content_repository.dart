import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

const _placeCount = 7;
const _picturesPerPlace = 5;

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
  if (root['schemaVersion'] != 2) {
    throw const ContentException('schemaVersion: expected 2');
  }
  final writing = _obj(root['writing'], 'writing');
  return GameContent(
    unlockCodes: _unlockCodes(_obj(root['unlockCodes'], 'unlockCodes')),
    level1: _level1(_obj(root['level1'], 'level1')),
    level2: _level2(_obj(root['level2'], 'level2')),
    quickFacts: _quickFacts(_obj(root['quickFacts'], 'quickFacts')),
    minClauseWords: _positive(
      writing['minClauseWords'],
      'writing.minClauseWords',
    ),
    level3: _level3(_obj(root['level3'], 'level3')),
  );
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
  final lyrics = _list(raw['lyrics'], 'level1.lyrics');
  final lines = [
    for (var i = 0; i < lyrics.length; i++)
      _lyric(_obj(lyrics[i], 'level1.lyrics[$i]'), 'level1.lyrics[$i]'),
  ];
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].startMs <= lines[i - 1].startMs) {
      throw ContentException(
        'level1.lyrics[$i].startMs: must be after the previous line',
      );
    }
  }

  final rawPairs = _list(raw['matchIt'], 'level1.matchIt');
  final pairs = [
    for (var i = 0; i < rawPairs.length; i++)
      _matchPair(
        _obj(rawPairs[i], 'level1.matchIt[$i]'),
        'level1.matchIt[$i]',
      ),
  ];
  _checkEachFanboysOnce([
    for (final p in pairs) p.conjunction,
  ], 'level1.matchIt');

  return Level1Content(
    audioAsset: _strOrNull(raw['audioAsset'], 'level1.audioAsset'),
    playsRequired: _positive(raw['playsRequired'], 'level1.playsRequired'),
    lyrics: lines,
    matchIt: pairs,
  );
}

LyricLine _lyric(Map<String, dynamic> raw, String path) {
  final start = raw['startMs'];
  if (start is! int || start < 0) {
    throw ContentException('$path.startMs: expected a non-negative integer');
  }
  return LyricLine(
    startMs: start,
    text: _str(raw['text'], '$path.text'),
    image: _strOrNull(raw['image'], '$path.image'),
  );
}

MatchPair _matchPair(Map<String, dynamic> raw, String path) => MatchPair(
  conjunction: _str(raw['conjunction'], '$path.conjunction'),
  function: _str(raw['function'], '$path.function'),
);

Level2Content _level2(Map<String, dynamic> raw) {
  final rawBridges = _list(raw['bridges'], 'level2.bridges');
  final bridges = [
    for (var i = 0; i < rawBridges.length; i++)
      _bridge(_obj(rawBridges[i], 'level2.bridges[$i]'), 'level2.bridges[$i]'),
  ];
  _checkEachFanboysOnce([
    for (final b in bridges) b.conjunction,
  ], 'level2.bridges');
  return Level2Content(
    maxWrongAnswers: _positive(
      raw['maxWrongAnswers'],
      'level2.maxWrongAnswers',
    ),
    bridges: bridges,
  );
}

Bridge _bridge(Map<String, dynamic> raw, String path) {
  final conjunction = _str(raw['conjunction'], '$path.conjunction');
  final rawHints = _obj(raw['hints'], '$path.hints');
  final hints = <String, String>{};
  for (final e in rawHints.entries) {
    if (!fanboys.contains(e.key) || e.key == conjunction) {
      throw ContentException(
        '$path.hints.${e.key}: expected a FANBOYS word other than '
        '"$conjunction"',
      );
    }
    hints[e.key] = _str(e.value, '$path.hints.${e.key}');
  }
  return Bridge(
    conjunction: conjunction,
    left: _str(raw['left'], '$path.left'),
    right: _str(raw['right'], '$path.right'),
    explanation: _str(raw['explanation'], '$path.explanation'),
    hints: hints,
    defaultHint: _str(raw['defaultHint'], '$path.defaultHint'),
    examples: _strings(raw['examples'], '$path.examples'),
  );
}

Map<String, List<QuickFact>> _quickFacts(Map<String, dynamic> raw) {
  final facts = <String, List<QuickFact>>{};
  for (final e in raw.entries) {
    final path = 'quickFacts.${e.key}';
    if (!fanboys.contains(e.key)) {
      throw ContentException('$path: "${e.key}" is not a FANBOYS word');
    }
    final items = e.value is List
        ? e.value as List
        : throw ContentException('$path: expected a list');
    facts[e.key] = [
      for (var i = 0; i < items.length; i++)
        _quickFact(_obj(items[i], '$path[$i]'), '$path[$i]'),
    ];
  }
  return facts;
}

QuickFact _quickFact(Map<String, dynamic> raw, String path) => QuickFact(
  word: _str(raw['word'], '$path.word'),
  rule:
      QuickFactRule.values.asNameMap()[raw['rule']] ??
      (throw ContentException('$path.rule: expected "joining" or "linking"')),
);

Level3Content _level3(Map<String, dynamic> raw) {
  final places = _list(raw['places'], 'level3.places');
  _checkCount(places, _placeCount, 'level3.places');
  return Level3Content(
    musicAsset: _str(raw['musicAsset'], 'level3.musicAsset'),
    travelogue: _travelogue(_obj(raw['travelogue'], 'level3.travelogue')),
    places: [
      for (var i = 0; i < places.length; i++)
        _place(_obj(places[i], 'level3.places[$i]'), 'level3.places[$i]'),
    ],
  );
}

TravelogueRules _travelogue(Map<String, dynamic> raw) {
  const path = 'level3.travelogue';
  final min = _positive(raw['minSentences'], '$path.minSentences');
  final max = _positive(raw['maxSentences'], '$path.maxSentences');
  if (min > max) {
    throw const ContentException(
      '$path.minSentences: must not exceed maxSentences',
    );
  }
  return TravelogueRules(
    minSentences: min,
    maxSentences: max,
    minConjunctions: _positive(raw['minConjunctions'], '$path.minConjunctions'),
  );
}

Place _place(Map<String, dynamic> raw, String path) {
  final pin = _obj(raw['mapPin'], '$path.mapPin');
  final pictures = _list(raw['pictures'], '$path.pictures');
  _checkCount(pictures, _picturesPerPlace, '$path.pictures');
  return Place(
    id: _str(raw['id'], '$path.id'),
    name: _str(raw['name'], '$path.name'),
    pinX: _fraction(pin['x'], '$path.mapPin.x'),
    pinY: _fraction(pin['y'], '$path.mapPin.y'),
    pictures: [
      for (var i = 0; i < pictures.length; i++)
        _picture(_obj(pictures[i], '$path.pictures[$i]'), '$path.pictures[$i]'),
    ],
  );
}

PlacePicture _picture(Map<String, dynamic> raw, String path) => PlacePicture(
  asset: _str(raw['asset'], '$path.asset'),
  caption: _str(raw['caption'], '$path.caption'),
);

void _checkEachFanboysOnce(List<String> words, String path) {
  for (var i = 0; i < words.length; i++) {
    if (!fanboys.contains(words[i])) {
      throw ContentException(
        '$path[$i].conjunction: "${words[i]}" is not a FANBOYS word',
      );
    }
  }
  if (words.length != fanboys.length || words.toSet().length != words.length) {
    throw ContentException('$path: need each FANBOYS word exactly once');
  }
}

void _checkCount(List<dynamic> list, int count, String path) {
  if (list.length != count) {
    throw ContentException('$path: expected exactly $count entries');
  }
}

Map<String, dynamic> _obj(Object? v, String path) => v is Map<String, dynamic>
    ? v
    : throw ContentException('$path: expected an object');

List<dynamic> _list(Object? v, String path) => v is List && v.isNotEmpty
    ? v
    : throw ContentException('$path: expected a non-empty list');

String _str(Object? v, String path) =>
    v is String ? v : throw ContentException('$path: expected a string');

String? _strOrNull(Object? v, String path) => v == null || v is String
    ? v as String?
    : throw ContentException('$path: expected a string or null');

int _positive(Object? v, String path) => v is int && v >= 1
    ? v
    : throw ContentException('$path: expected a positive integer');

double _fraction(Object? v, String path) => v is num && v >= 0 && v <= 1
    ? v.toDouble()
    : throw ContentException('$path: expected a number from 0 to 1');

List<String> _strings(Object? v, String path) {
  final list = _list(v, path);
  return [for (var i = 0; i < list.length; i++) _str(list[i], '$path[$i]')];
}
