import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  const Profile({required this.name, required this.section});

  final String name;
  final String section;
}

/// Owns what the student enters: their profile, shown on the answer report.
class ResultsStore extends ChangeNotifier {
  ResultsStore(this._prefs) : _profile = _readProfile(_prefs);

  static const _profileKey = 'profile_v1';

  final SharedPreferences _prefs;
  Profile? _profile;

  Profile? get profile => _profile;

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
