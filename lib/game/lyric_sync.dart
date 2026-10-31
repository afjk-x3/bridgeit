import 'package:bridgeit/content/models.dart';

/// Index of the line being sung at [positionMs]: the last one already started.
int activeLine(List<LyricLine> lyrics, int positionMs) {
  var line = 0;
  for (var i = 1; i < lyrics.length; i++) {
    if (lyrics[i].startMs <= positionMs) line = i;
  }
  return line;
}
