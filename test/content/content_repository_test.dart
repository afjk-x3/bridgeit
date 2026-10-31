import 'dart:convert';

import 'package:bridgeit/content/content_repository.dart';
import 'package:bridgeit/content/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

List<dynamic> _lyrics(Map<String, dynamic> j) => j['level1']['lyrics'];
List<dynamic> _matchIt(Map<String, dynamic> j) => j['level1']['matchIt'];
List<dynamic> _bridges(Map<String, dynamic> j) => j['level2']['bridges'];
List<dynamic> _places(Map<String, dynamic> j) => j['level3']['places'];
Map<String, dynamic> _travelogue(Map<String, dynamic> j) =>
    j['level3']['travelogue'];

/// One way to break the JSON, and the path the error must name.
typedef _Case = (String path, void Function(Map<String, dynamic> json) breakIt);

final List<_Case> _cases = [
  ('schemaVersion', (j) => j['schemaVersion'] = 1),
  ('unlockCodes.3', (j) => j['unlockCodes'].remove('3')),
  ('unlockCodes.x', (j) => j['unlockCodes']['x'] = 'CODE'),
  ('level1.audioAsset', (j) => j['level1']['audioAsset'] = 3),
  ('level1.playsRequired', (j) => j['level1']['playsRequired'] = 0),
  ('level1.lyrics', (j) => j['level1']['lyrics'] = []),
  ('level1.lyrics[0].startMs', (j) => _lyrics(j)[0]['startMs'] = -1),
  ('level1.lyrics[1].startMs', (j) => _lyrics(j)[1]['startMs'] = 0),
  ('level1.lyrics[0].image', (j) => _lyrics(j)[0]['image'] = 1),
  ('level1.matchIt[0].conjunction', (j) {
    _matchIt(j)[0]['conjunction'] = 'because';
  }),
  ('level1.matchIt', (j) => _matchIt(j).removeLast()),
  ('level1.matchIt', (j) => _matchIt(j)[1]['conjunction'] = 'for'),
  ('level2.maxWrongAnswers', (j) => j['level2']['maxWrongAnswers'] = 0),
  ('level2.bridges[0].conjunction', (j) {
    _bridges(j)[0]['conjunction'] = 'because';
  }),
  ('level2.bridges', (j) => _bridges(j).removeLast()),
  ('level2.bridges', (j) => _bridges(j)[1]['conjunction'] = 'for'),
  ('level2.bridges[0].hints.for', (j) => _bridges(j)[0]['hints']['for'] = 'x'),
  ('level2.bridges[0].hints.nope', (j) {
    _bridges(j)[0]['hints']['nope'] = 'x';
  }),
  ('level2.bridges[0].examples', (j) => _bridges(j)[0]['examples'] = []),
  ('quickFacts.because', (j) => j['quickFacts']['because'] = []),
  ('quickFacts.for', (j) => j['quickFacts']['for'] = 'because'),
  ('quickFacts.for[0].rule', (j) => j['quickFacts']['for'][0]['rule'] = 'x'),
  ('writing.minClauseWords', (j) => j['writing']['minClauseWords'] = 0),
  ('level3', (j) => j.remove('level3')),
  ('level3.musicAsset', (j) => j['level3']['musicAsset'] = null),
  ('level3.travelogue.minSentences', (j) => _travelogue(j)['minSentences'] = 0),
  ('level3.travelogue.maxSentences', (j) => _travelogue(j)['maxSentences'] = 0),
  ('level3.travelogue.minSentences', (j) => _travelogue(j)['minSentences'] = 8),
  ('level3.travelogue.minConjunctions', (j) {
    _travelogue(j)['minConjunctions'] = 0;
  }),
  ('level3.places', (j) => _places(j).removeLast()),
  ('level3.places[0].pictures', (j) => _places(j)[0]['pictures'].removeLast()),
  ('level3.places[0].mapPin.x', (j) => _places(j)[0]['mapPin']['x'] = 1.5),
  ('level3.places[0].mapPin.y', (j) => _places(j)[0]['mapPin']['y'] = -0.1),
  ('level3.places[0].pictures[0].caption', (j) {
    _places(j)[0]['pictures'][0].remove('caption');
  }),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the bundled levels.json', () async {
    final content = await loadGameContent(rootBundle);
    expect(content.unlockCodes[2], 'BRIDGE2');
    expect(content.level1.playsRequired, 3);
    expect(content.level1.audioAsset, isNull);
    expect(content.level1.matchIt, hasLength(7));
    expect(content.level2.maxWrongAnswers, 3);
    expect(content.level2.bridges.map((b) => b.conjunction), fanboys);
    expect(content.minClauseWords, 2);
    expect(content.level3.places, hasLength(7));
    expect(content.level3.travelogue.maxSentences, 7);

    final first = content.quickFacts['for']!.first;
    expect(first.word, 'because');
    expect(first.rule, QuickFactRule.joining);
    expect(content.quickFacts['so']!.first.rule, QuickFactRule.linking);

    final place = content.level3.places.first;
    expect(place.id, 'la_paz');
    expect(place.pinX, 0.38);
    expect(place.pictures, hasLength(5));
  });

  test('the bridges ask for 12 written sentences', () async {
    final content = await loadGameContent(rootBundle);
    final sentences = content.level2.bridges.fold<int>(
      0,
      (sum, b) => sum + (content.quickFacts.containsKey(b.conjunction) ? 2 : 1),
    );
    expect(sentences, 12);
  });

  test('an empty quickFacts list means one sentence only', () async {
    final json = await _bundledJson();
    json['quickFacts']['nor'] = [];
    final content = parseGameContent(jsonEncode(json));
    expect(content.quickFacts['nor'], isEmpty);
  });

  test('rejects invalid JSON', () {
    expect(() => parseGameContent('{not json'), _contentError('invalid JSON'));
  });

  for (final (i, (path, breakIt)) in _cases.indexed) {
    test('rejects broken content #$i: $path', () async {
      final json = await _bundledJson();
      breakIt(json);
      expect(() => parseGameContent(jsonEncode(json)), _contentError(path));
    });
  }
}
