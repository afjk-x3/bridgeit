import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/app.dart';
import 'package:bridgeit/theme/app_theme.dart';

void main() {
  testWidgets('app starts and shows BridgeIt title', (tester) async {
    await tester.pumpWidget(const BridgeItApp());

    expect(find.text('BridgeIt'), findsOneWidget);
    final context = tester.element(find.text('BridgeIt'));
    expect(Theme.of(context).colorScheme.primary, AppColors.primary);
  });
}
