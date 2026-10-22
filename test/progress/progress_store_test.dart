import 'package:bridgeit/progress/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const codes = {2: 'BRIDGE2', 3: 'BRIDGE3'};
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('level 1 unlocked, 2 and 3 locked by default', () {
    final store = ProgressStore(prefs, codes);
    expect(store.isUnlocked(1), isTrue);
    expect(store.isUnlocked(2), isFalse);
    expect(store.isUnlocked(3), isFalse);
  });

  test('correct code unlocks only that level', () {
    final store = ProgressStore(prefs, codes);
    expect(store.tryUnlock(2, 'BRIDGE2'), isTrue);
    expect(store.isUnlocked(2), isTrue);
    expect(store.isUnlocked(3), isFalse);
  });

  test('code is trimmed and case-insensitive', () {
    final store = ProgressStore(prefs, codes);
    expect(store.tryUnlock(2, '  bridge2 '), isTrue);
    expect(store.isUnlocked(2), isTrue);
  });

  test('wrong code returns false and changes nothing', () {
    final store = ProgressStore(prefs, codes);
    expect(store.tryUnlock(2, 'NOPE'), isFalse);
    expect(store.tryUnlock(2, 'BRIDGE3'), isFalse);
    expect(store.isUnlocked(2), isFalse);
    expect(prefs.getStringList('unlocked_levels'), isNull);
  });

  test('level without a code can never be unlocked by a code', () {
    final store = ProgressStore(prefs, const {2: 'BRIDGE2'});
    expect(store.tryUnlock(3, ''), isFalse);
    expect(store.isUnlocked(3), isFalse);
  });

  test('level 1 and out-of-range levels are not unlockable or writable', () {
    final store = ProgressStore(prefs, codes);
    expect(store.tryUnlock(1, 'anything'), isFalse);
    expect(store.tryUnlock(4, 'BRIDGE2'), isFalse);
    expect(store.isUnlocked(4), isFalse);
    expect(prefs.getStringList('unlocked_levels'), isNull);
  });

  test('progress survives a new store instance', () async {
    final store = ProgressStore(prefs, codes);
    store.tryUnlock(2, 'BRIDGE2');
    await store.markCompleted(1);

    final reloaded = ProgressStore(prefs, codes);
    expect(reloaded.isUnlocked(2), isTrue);
    expect(reloaded.isUnlocked(3), isFalse);
    expect(reloaded.isCompleted(1), isTrue);
    expect(reloaded.isCompleted(2), isFalse);
  });

  test('unlocked_levels never contains level 1', () {
    final store = ProgressStore(prefs, codes);
    store.tryUnlock(2, 'BRIDGE2');
    expect(prefs.getStringList('unlocked_levels'), ['2']);
  });

  test('notifies listeners on unlock and on completion', () async {
    final store = ProgressStore(prefs, codes);
    var calls = 0;
    store.addListener(() => calls++);

    store.tryUnlock(2, 'wrong');
    expect(calls, 0);

    store.tryUnlock(2, 'BRIDGE2');
    expect(calls, 1);

    await store.markCompleted(1);
    expect(calls, 2);
  });
}
