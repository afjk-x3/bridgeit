import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridgeit/progress/results_store.dart';
import 'package:bridgeit/report/answer_report.dart';
import 'package:bridgeit/report/answer_sender.dart';

const _profile = Profile(name: 'Ana Reyes', section: 'Grade 7 / B');
final _now = DateTime(2026, 11, 2, 9, 5);

const Map<String, dynamic> _results = {
  '1': {
    'plays': 3,
    'attempts': [
      ['for', 'and'],
      <String>[],
    ],
    'activeMs': 65000,
  },
  '2': {
    'bridges': [
      {
        'conjunction': 'for',
        'wrongTries': 2,
        'collapses': 1,
        'activeMs': 30000,
        'sentences': [
          {
            'text': 'I ran, for it rained.',
            'attempts': 2,
            'spellingWarnings': 1,
            'unsure': true,
          },
        ],
      },
    ],
  },
  '3': {
    'place': 'Saud Beach, Pagudpud',
    'entry': 'We went, and we swam.',
    'sentences': 5,
    'conjunctions': ['and', 'but'],
    'spellingWarnings': 0,
    'activeMs': 5000,
  },
};

void main() {
  List<String> lines(Map<String, dynamic> results) => [
    for (final (_, text) in reportLines(_profile, results, _now)) text,
  ];

  test('the header names the student, date and version', () {
    expect(
      lines({}),
      containsAll([
        'Name: Ana Reyes',
        'Section: Grade 7 / B',
        'Date: 2026-11-02 09:05',
        'App version: $appVersion',
      ]),
    );
  });

  test('level 1 lists plays, attempts and time', () {
    expect(
      lines(_results),
      containsAll([
        'Song plays: 3',
        'MatchIt attempts: 2',
        'Attempt 1, wrong pairs: for, and',
        'Attempt 2, wrong pairs: none',
        'Active time: 1 min 5 s',
      ]),
    );
  });

  test('level 2 lists each bridge and sentence', () {
    expect(
      lines(_results),
      containsAll([
        "Bridge 'for'",
        'Wrong tries: 2, collapses: 1, active time: 0 min 30 s',
        '"I ran, for it rained."',
        'Attempts: 2, spelling warnings: 1, clause not confirmed',
      ]),
    );
  });

  test('level 3 lists the place, entry and counts', () {
    expect(
      lines(_results),
      containsAll([
        'Place: Saud Beach, Pagudpud',
        'We went, and we swam.',
        'Sentences: 5',
        'Conjunctions counted: and, but',
        'Spelling warnings: 0',
      ]),
    );
  });

  test('totals add the levels done so far', () {
    expect(
      lines(_results),
      containsAll([
        'Level 2 active time: 0 min 30 s',
        'Overall active time: 1 min 40 s',
      ]),
    );
    expect(lines({}), contains('Overall active time: 0 min 0 s'));
    expect(lines({}).any((l) => l.startsWith('Level 1')), isFalse);
  });

  test('the file name is safe', () {
    expect(
      reportFileName(
        const Profile(name: 'Ñino / O\'Neil', section: '7-A'),
        _now,
      ),
      'BridgeIt_7-A__ino_O_Neil_2026-11-02.pdf',
    );
  });

  test('builds a PDF, even with text the font cannot show', () async {
    final results = jsonDecode(jsonEncode(_results)) as Map<String, dynamic>;
    (results['3'] as Map)['entry'] = 'We’re here \u{1F600} in Paoay—yes.';

    final bytes = await buildAnswerReport(
      const Profile(name: 'Niño', section: '7'),
      results,
      _now,
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('send writes the file and shares its path', () async {
    final dir = Directory.systemTemp.createTempSync('bridgeit');
    addTearDown(() => dir.deleteSync(recursive: true));
    SharedPreferences.setMockInitialValues({});
    final store = ResultsStore(await SharedPreferences.getInstance());
    await store.saveProfile('Ana', '7');
    await store.saveResult(1, jsonDecode(jsonEncode(_results['1'])));
    String? shared;

    await AnswerSender(
      tempDir: () async => dir,
      share: (path) async => shared = path,
    ).send(store);

    expect(shared, contains('BridgeIt_7_Ana_'));
    expect(File(shared!).lengthSync(), greaterThan(100));
  });
}
