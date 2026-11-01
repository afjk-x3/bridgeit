import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

double _width(TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: 'Complete each level and build', style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  test('theme uses bundled Nunito', () {
    expect(buildAppTheme().textTheme.bodyMedium!.fontFamily, 'Nunito');
  });

  test('text colors reach 4.5:1 contrast on their backgrounds', () {
    double contrast(Color a, Color b) {
      final (l1, l2) = (a.computeLuminance(), b.computeLuminance());
      return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
    }

    const pairs = [
      (AppColors.ink, AppColors.sky),
      (AppColors.ink, AppColors.card),
      (AppColors.ink, AppColors.lightTeal),
      (AppColors.card, AppColors.primary),
    ];
    for (final (text, background) in pairs) {
      expect(
        contrast(text, background),
        greaterThanOrEqualTo(4.5),
        reason: '$text on $background',
      );
    }
    // Only the large bold level number sits on orange: 3:1 is enough.
    expect(contrast(AppColors.ink, AppColors.accent), greaterThanOrEqualTo(3));
  });

  testWidgets('bundled Nunito is variable: fontWeight moves the wght axis', (
    tester,
  ) async {
    // flutter test does not load pubspec fonts, so load the bundled file by hand.
    final data = rootBundle.load('assets/fonts/Nunito-Variable.ttf');
    await (FontLoader('NunitoVar')..addFont(data)).load();
    const base = TextStyle(fontFamily: 'NunitoVar', fontSize: 20);

    final regular = _width(base.copyWith(fontWeight: FontWeight.w400));
    final bold = _width(base.copyWith(fontWeight: FontWeight.w700));
    final viaAxis = _width(
      base.copyWith(fontVariations: [const FontVariation.weight(700)]),
    );

    expect(bold, greaterThan(regular));
    expect(bold, viaAxis);
  });
}
