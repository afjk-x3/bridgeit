import 'package:bridgeit/widgets/place_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the road starts where the car waits', () {
    expect(roadPoint(0).dx, closeTo(30, 0.1));
    expect(roadPoint(0).dy, closeTo(21, 0.1));
  });

  test('a point near the road maps to the closest stretch of it', () {
    final on = roadPoint(300);

    expect(roadDistanceTo(on), closeTo(300, 2));
    expect(roadDistanceTo(on + const Offset(4, 0)), closeTo(300, 12));
  });
}
