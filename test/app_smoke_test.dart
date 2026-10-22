import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('app starts and shows BridgeIt title', (tester) async {
    await pumpApp(tester);

    expect(find.text('BridgeIt'), findsOneWidget);
    final context = tester.element(find.text('BridgeIt'));
    expect(Theme.of(context).colorScheme.primary, AppColors.primary);
  });
}
