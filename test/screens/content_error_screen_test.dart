import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/screens/content_error_screen.dart';

void main() {
  testWidgets('content error screen shows the message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ContentErrorScreen(message: 'level3 is missing')),
    );

    expect(find.text('level3 is missing'), findsOneWidget);
  });
}
