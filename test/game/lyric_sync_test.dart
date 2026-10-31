import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/content/models.dart';
import 'package:bridgeit/game/lyric_sync.dart';

LyricLine _line(int startMs) =>
    LyricLine(startMs: startMs, text: '$startMs', image: null);

void main() {
  final lyrics = [_line(500), _line(1000), _line(2000)];

  test('follows the last line that has started', () {
    expect(activeLine(lyrics, 0), 0);
    expect(activeLine(lyrics, 999), 0);
    expect(activeLine(lyrics, 1000), 1);
    expect(activeLine(lyrics, 1999), 1);
    expect(activeLine(lyrics, 9999), 2);
  });
}
