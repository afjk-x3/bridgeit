import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridgeit/app.dart';
import 'package:bridgeit/content/content_repository.dart';
import 'package:bridgeit/content/lexicon.dart';
import 'package:bridgeit/progress/progress_store.dart';
import 'package:bridgeit/progress/results_store.dart';
import 'package:bridgeit/report/answer_sender.dart';

/// Records what would go to the share sheet, without touching the platform.
class FakeSender extends AnswerSender {
  FakeSender({this.fails = false});

  final bool fails;
  Map<String, dynamic>? sent;

  @override
  Future<void> send(ResultsStore store) async {
    if (fails) throw Exception('no share sheet');
    sent = store.results;
  }
}

const _profile = {'profile_v1': '{"name":"Ana","section":"A"}'};

/// Pumps the real app (real levels.json, mock prefs) on a phone-sized surface.
/// A saved profile skips the welcome screen unless [newStudent] is true.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool newStudent = false,
  AnswerSender sender = const AnswerSender(),
}) async {
  tester.view.physicalSize = const Size(411, 891);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    if (!newStudent) ..._profile,
    ...prefs,
  });
  final (content, progress, results, writing) = (await tester.runAsync(
    () async {
      final content = await loadGameContent(rootBundle);
      final shared = await SharedPreferences.getInstance();
      return (
        content,
        ProgressStore(shared, content.unlockCodes),
        ResultsStore(shared),
        await loadWritingTools(rootBundle, content),
      );
    },
  ))!;
  await tester.pumpWidget(
    BridgeItApp(
      content: content,
      progress: progress,
      results: results,
      writing: writing,
      sender: sender,
    ),
  );
}

/// Taps play on the start screen to reach the level menu.
Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Play'));
  await tester.pumpAndSettle();
}
