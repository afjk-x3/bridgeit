import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridgeit/app.dart';
import 'package:bridgeit/content/content_repository.dart';
import 'package:bridgeit/progress/progress_store.dart';

/// Pumps the real app (real levels.json, mock prefs) on a phone-sized surface.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(411, 891);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final (content, progress) = (await tester.runAsync(() async {
    final content = await loadGameContent(rootBundle);
    final store = ProgressStore(
      await SharedPreferences.getInstance(),
      content.unlockCodes,
    );
    return (content, store);
  }))!;
  await tester.pumpWidget(BridgeItApp(content: content, progress: progress));
}

/// Taps "Let's start" on the intro to reach the level menu.
Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.text("Let's start"));
  await tester.pumpAndSettle();
}
