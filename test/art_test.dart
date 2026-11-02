import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  const strips = [
    'assets/images/scenes/bridge_strip.svg',
    'assets/images/scenes/bridge_strip_crossed.svg',
  ];
  // App colours, plus the deck's lighter top and the driver from the guide art.
  final allowed = {
    for (final c in [
      AppColors.primary,
      AppColors.accent,
      AppColors.teal,
      AppColors.lightTeal,
      AppColors.sky,
      AppColors.ink,
      AppColors.deck,
      AppColors.stone,
      AppColors.water,
      AppColors.card,
      AppColors.tower,
      AppColors.vehicle,
    ])
      _hex(c),
    '#8A93A0',
    '#5A3825',
    '#F4C7A1',
  };

  for (final path in strips) {
    test('$path draws the finished bridge with flutter_svg-safe markup', () {
      final svg = File(path).readAsStringSync();
      expect(svg, isNot(contains('<filter')));
      expect(svg, isNot(contains('<mask')));
      // Stone piers under the deck.
      expect(svg.toUpperCase(), contains('#6F7F9E'));
    });
  }

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

  for (final path in strips) {
    test('$path uses only app colours', () {
      final svg = File(path).readAsStringSync();
      for (final m in RegExp(r'#[0-9A-Fa-f]{6}\b').allMatches(svg)) {
        expect(allowed, contains(m[0]!.toUpperCase()), reason: m[0]);
      }
    });
  }
}
