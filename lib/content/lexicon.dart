import 'package:flutter/services.dart';

/// Loads a word list: one lowercase word per line, `#` lines are comments.
Future<Set<String>> loadLexicon(AssetBundle bundle, String path) async =>
    parseLexicon(await bundle.loadString(path));

Set<String> parseLexicon(String text) => {
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty && !line.startsWith('#')) line.trim(),
};
