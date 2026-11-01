import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../progress/results_store.dart';
import 'answer_report.dart';

/// Writes the report to a temp file and opens the system share sheet. Tests
/// replace the two platform steps.
class AnswerSender {
  const AnswerSender({
    this.tempDir = getTemporaryDirectory,
    this.share = _openShareSheet,
  });

  final Future<Directory> Function() tempDir;
  final Future<void> Function(String path) share;

  static Future<void> _openShareSheet(String path) => SharePlus.instance.share(
    ShareParams(files: [XFile(path, mimeType: 'application/pdf')]),
  );

  Future<void> send(ResultsStore store) async {
    final now = DateTime.now();
    final bytes = await buildAnswerReport(store.profile, store.results, now);
    final dir = await tempDir();
    final file = File('${dir.path}/${reportFileName(store.profile, now)}');
    await file.writeAsBytes(bytes);
    await share(file.path);
  }
}
