import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  const Profile({required this.name, required this.section});

  final String name;
  final String section;
}

/// Where a student stopped in Level 2. [written] holds each bridge's accepted
/// sentences, one list per bridge so far.
class Level2Resume {
  const Level2Resume({
    required this.bridgeIndex,
    required this.written,
    this.stats = const [],
  });

  final int bridgeIndex;
  final List<List<String>> written;

  /// Each bridge's numbers for the report, one map per bridge so far.
  final List<Map<String, dynamic>> stats;
}

/// Owns what the student enters: their profile, shown on the answer report,
/// and their place in Level 2.
class ResultsStore extends ChangeNotifier {
  ResultsStore(this._prefs) : _profile = _readProfile(_prefs);

  static const _profileKey = 'profile_v1';
  static const _level2Key = 'level2_resume_v1';
  static const _resultsKey = 'results_v1';

  final SharedPreferences _prefs;
  Profile? _profile;

  Profile? get profile => _profile;

  /// A corrupt value reads as a fresh start.
  Level2Resume? get level2Resume {
    final raw = _prefs.getString(_level2Key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Level2Resume(
        bridgeIndex: json['bridgeIndex'] as int,
        written: [
          for (final bridge in json['written'] as List)
            [for (final sentence in bridge as List) sentence as String],
        ],
        stats: [
          for (final bridge in json['stats'] as List? ?? const [])
            bridge as Map<String, dynamic>,
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLevel2Resume(Level2Resume resume) => _prefs.setString(
    _level2Key,
    jsonEncode({
      'bridgeIndex': resume.bridgeIndex,
      'written': resume.written,
      'stats': resume.stats,
    }),
  );

  Future<void> clearLevel2Resume() => _prefs.remove(_level2Key);

  /// Finished levels' results for the report, keyed by level number. A
  /// corrupt value reads as no results.
  Map<String, dynamic> get results {
    final raw = _prefs.getString(_resultsKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Keeps the first completed attempt: a replay doesn't overwrite it.
  Future<void> saveResult(int level, Map<String, dynamic> result) async {
    final all = results;
    if (all.containsKey('$level')) return;
    all['$level'] = result;
    await _prefs.setString(_resultsKey, jsonEncode(all));
  }

  /// A corrupt value reads as no profile, so it can't brick the app.
  static Profile? _readProfile(SharedPreferences prefs) {
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Profile(
        name: json['name'] as String,
        section: json['section'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(String name, String section) async {
    final profile = Profile(name: name.trim(), section: section.trim());
    await _prefs.setString(
      _profileKey,
      jsonEncode({'name': profile.name, 'section': profile.section}),
    );
    _profile = profile;
    notifyListeners();
  }
}
