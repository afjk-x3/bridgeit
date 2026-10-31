import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('app starts on the start screen with the theme', (tester) async {
    await pumpApp(tester);

    final play = find.byTooltip('Play');
    expect(play, findsOneWidget);
    final context = tester.element(play);
    expect(Theme.of(context).colorScheme.primary, AppColors.primary);
  });
}
