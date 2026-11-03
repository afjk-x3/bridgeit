import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridgeit/progress/results_store.dart';

Future<ResultsStore> _store(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  return ResultsStore(await SharedPreferences.getInstance());
}

void main() {
  test('starts with no profile', () async {
    expect((await _store({})).profile, isNull);
  });

  test('saves a trimmed profile that survives a restart', () async {
    final store = await _store({});
    await store.saveProfile('  Ana ', ' Grade 7 ');
    expect(store.profile!.name, 'Ana');

    final prefs = await SharedPreferences.getInstance();
    final reloaded = ResultsStore(prefs).profile!;
    expect(reloaded.name, 'Ana');
    expect(reloaded.section, 'Grade 7');
  });

  test('level 2 resume survives a restart and can be cleared', () async {
    final store = await _store({});
    expect(store.level2Resume, isNull);

    await store.saveLevel2Resume(
      const Level2Resume(
        bridgeIndex: 1,
        written: [
          ['One.', 'Two.'],
          [],
        ],
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resume = ResultsStore(prefs).level2Resume!;
    expect(resume.bridgeIndex, 1);
    expect(resume.written, [
      ['One.', 'Two.'],
      <String>[],
    ]);

    await store.clearLevel2Resume();
    expect(store.level2Resume, isNull);
  });

  test('the first result of a level is kept', () async {
    final store = await _store({});
    expect(store.results, isEmpty);

    await store.saveResult(1, {'plays': 3});
    await store.saveResult(1, {'plays': 9});
    await store.saveResult(2, {'bridges': []});

    expect(store.results['1'], {'plays': 3});
    expect(store.results.keys, ['1', '2']);
  });

  test('corrupt results read as none', () async {
    for (final bad in ['{not json', '[]']) {
      final store = await _store({'results_v1': bad});
      expect(store.results, isEmpty, reason: bad);
    }
  });

  test('corrupt level 2 resume reads as a fresh start', () async {
    for (final bad in [
      '{not json',
      '[]',
      '{"bridgeIndex":"x","written":[]}',
      '{"bridgeIndex":1,"written":[1]}',
    ]) {
      final store = await _store({'level2_resume_v1': bad});
      expect(store.level2Resume, isNull, reason: bad);
    }
  });

  test('corrupt profile JSON reads as no profile', () async {
    for (final bad in ['{not json', '[]', '{"name":1,"section":"A"}']) {
      expect((await _store({'profile_v1': bad})).profile, isNull, reason: bad);
    }
  });

  test(
    'the Level 3 place and draft are kept, and a corrupt one reads as none',
    () async {
      final store = await _store({});
      expect(store.level3Resume, isNull);
      await store.saveLevel3Resume(
        const Level3Resume(placeId: 'la_paz', draft: 'We went.'),
      );
      expect(store.level3Resume?.placeId, 'la_paz');
      expect(store.level3Resume?.draft, 'We went.');
      await store.clearLevel3Resume();
      expect(store.level3Resume, isNull);
      expect(
        (await _store({'level3_resume_v1': '{nope'})).level3Resume,
        isNull,
      );
    },
  );
}
