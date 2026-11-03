import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the small car keeps light wheel rims, so it shows on navy', () {
    final svg = File('assets/images/car_small.svg').readAsStringSync();
    for (final cx in ['15', '50']) {
      expect(
        svg,
        matches(
          RegExp(
            '<circle cx="$cx" cy="26" r="[0-9.]+" fill="none" stroke="#E6F5FF"',
          ),
        ),
        reason: 'wheel at $cx',
      );
    }
  });
}
