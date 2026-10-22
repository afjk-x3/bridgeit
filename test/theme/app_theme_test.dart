import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

import '../support/pump_app.dart';

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

  testWidgets('intro wordmark uses AbrilFatface', (tester) async {
    await pumpApp(tester);

    final wordmark = tester.widget<Text>(find.text('BridgeIt'));
    expect(wordmark.style!.fontFamily, 'AbrilFatface');
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
