import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';
import 'package:bridgeit/widgets/strength_bar.dart';

void main() {
  testWidgets('8 segments fit a 360dp phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: StrengthBar(wrongCount: 3, max: 8),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(StrengthBar));
    for (var i = 0; i < 8; i++) {
      final box = tester.widget<Container>(find.byKey(ValueKey('strength-$i')));
      final color = (box.decoration! as BoxDecoration).color;
      expect(color, i < 5 ? AppColors.bridge : AppColors.wrong, reason: '$i');
      final rect = tester.getRect(find.byKey(ValueKey('strength-$i')));
      expect(rect.width, greaterThan(0), reason: '$i');
      expect(rect.right, lessThanOrEqualTo(bar.right), reason: '$i');
    }
  });
}
