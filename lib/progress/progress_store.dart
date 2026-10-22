import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which levels are unlocked (via teacher codes) and completed.
/// Level 1 is always unlocked and is never written to prefs.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs, this._unlockCodes)
      : _unlocked = _read(_prefs, _unlockedKey),
        _completed = _read(_prefs, _completedKey);

  static const _unlockedKey = 'unlocked_levels';
  static const _completedKey = 'completed_levels';

  final SharedPreferences _prefs;
  final Map<int, String> _unlockCodes;
  final Set<int> _unlocked;
  final Set<int> _completed;

  static Set<int> _read(SharedPreferences prefs, String key) =>
      (prefs.getStringList(key) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  static bool _validLevel(int level) => level >= 1 && level <= 3;

  static String _normalize(String s) => s.trim().toUpperCase();

  bool isUnlocked(int level) => level == 1 || _unlocked.contains(level);

  bool isCompleted(int level) => _completed.contains(level);

  /// Unlocks [level] if [code] matches its teacher code. Returns true only
  /// when the level is newly unlocked by this call.
  bool tryUnlock(int level, String code) {
    final expected = _unlockCodes[level];
    if (level == 1 || !_validLevel(level) || expected == null) return false;
    final want = _normalize(expected);
    // A blank configured code means "no code": never unlockable.
    if (want.isEmpty || _normalize(code) != want) return false;
    if (!_unlocked.add(level)) return false;
    _prefs.setStringList(_unlockedKey, _sorted(_unlocked));
    notifyListeners();
    return true;
  }

  Future<void> markCompleted(int level) async {
    if (!_validLevel(level) || !_completed.add(level)) return;
    await _prefs.setStringList(_completedKey, _sorted(_completed));
    notifyListeners();
  }

  static List<String> _sorted(Set<int> levels) =>
      (levels.toList()..sort()).map((l) => '$l').toList();
}
