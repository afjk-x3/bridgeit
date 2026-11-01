import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../progress/results_store.dart';

/// Keep in step with `version` in pubspec.yaml.
const appVersion = '0.2.0';

enum ReportStyle { title, heading, subheading, body }

typedef ReportLine = (ReportStyle, String);

/// The report's text, kept apart from the PDF so it can be tested.
List<ReportLine> reportLines(
  Profile? profile,
  Map<String, dynamic> results,
  DateTime now,
) {
  final lines = <ReportLine>[
    (ReportStyle.title, 'BridgeIt answers'),
    (ReportStyle.body, 'Name: ${profile?.name ?? '-'}'),
    (ReportStyle.body, 'Section: ${profile?.section ?? '-'}'),
    (ReportStyle.body, 'Date: ${_date(now)} ${_time(now)}'),
    (ReportStyle.body, 'App version: $appVersion'),
  ];

  final level1 = results['1'] as Map<String, dynamic>?;
  if (level1 != null) lines.addAll(_level1(level1));
  final level2 = results['2'] as Map<String, dynamic>?;
  if (level2 != null) lines.addAll(_level2(level2));
  final level3 = results['3'] as Map<String, dynamic>?;
  if (level3 != null) lines.addAll(_level3(level3));

  final times = [
    if (level1 != null) ('Level 1', level1['activeMs'] as int),
    if (level2 != null) ('Level 2', _level2Ms(level2)),
    if (level3 != null) ('Level 3', level3['activeMs'] as int),
  ];
  lines.add((ReportStyle.heading, 'Totals'));
  for (final (name, ms) in times) {
    lines.add((ReportStyle.body, '$name active time: ${_duration(ms)}'));
  }
  final total = times.fold(0, (sum, t) => sum + t.$2);
  lines.add((ReportStyle.body, 'Overall active time: ${_duration(total)}'));
  return lines;
}

List<ReportLine> _level1(Map<String, dynamic> result) {
  final attempts = result['attempts'] as List;
  return [
    (ReportStyle.heading, 'Level 1: Conjunction Theme Song'),
    (ReportStyle.body, 'Song plays: ${result['plays']}'),
    (ReportStyle.body, 'MatchIt attempts: ${attempts.length}'),
    for (var i = 0; i < attempts.length; i++)
      (
        ReportStyle.body,
        'Attempt ${i + 1}, wrong pairs: '
            '${(attempts[i] as List).isEmpty ? 'none' : (attempts[i] as List).join(', ')}',
      ),
    (ReportStyle.body, 'Active time: ${_duration(result['activeMs'] as int)}'),
  ];
}

int _level2Ms(Map<String, dynamic> result) => (result['bridges'] as List).fold(
  0,
  (sum, bridge) => sum + (bridge as Map)['activeMs'] as int,
);

List<ReportLine> _level2(Map<String, dynamic> result) {
  final lines = <ReportLine>[
    (ReportStyle.heading, 'Level 2: Building Bridges'),
  ];
  for (final bridge
      in (result['bridges'] as List).cast<Map<String, dynamic>>()) {
    lines
      ..add((ReportStyle.subheading, "Bridge '${bridge['conjunction']}'"))
      ..add((
        ReportStyle.body,
        'Wrong tries: ${bridge['wrongTries']}, collapses: '
            '${bridge['collapses']}, active time: '
            '${_duration(bridge['activeMs'] as int)}',
      ));
    for (final sentence
        in (bridge['sentences'] as List).cast<Map<String, dynamic>>()) {
      lines
        ..add((ReportStyle.body, '"${sentence['text']}"'))
        ..add((
          ReportStyle.body,
          'Attempts: ${sentence['attempts']}, spelling warnings: '
              '${sentence['spellingWarnings']}'
              '${sentence['unsure'] == true ? ', clause not confirmed' : ''}',
        ));
    }
  }
  return lines;
}

List<ReportLine> _level3(Map<String, dynamic> result) => [
  (ReportStyle.heading, 'Level 3: Travelogue'),
  (ReportStyle.body, 'Place: ${result['place']}'),
  (ReportStyle.body, '${result['entry']}'),
  (ReportStyle.body, 'Sentences: ${result['sentences']}'),
  (
    ReportStyle.body,
    'Conjunctions counted: ${(result['conjunctions'] as List).join(', ')}',
  ),
  (ReportStyle.body, 'Spelling warnings: ${result['spellingWarnings']}'),
  (ReportStyle.body, 'Active time: ${_duration(result['activeMs'] as int)}'),
];

String _two(int n) => n.toString().padLeft(2, '0');

String _date(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String _duration(int ms) {
  final seconds = ms ~/ 1000;
  return '${seconds ~/ 60} min ${seconds % 60} s';
}

/// `BridgeIt_<section>_<name>_<yyyy-mm-dd>.pdf`, safe for any file system.
String reportFileName(Profile? profile, DateTime now) {
  String safe(String? text) =>
      (text ?? '').trim().replaceAll(RegExp('[^A-Za-z0-9_-]+'), '_');
  return 'BridgeIt_${safe(profile?.section)}_${safe(profile?.name)}_'
      '${_date(now)}.pdf';
}

/// The built-in font only covers Latin-1, and student text can hold anything.
String _printable(String text) => text
    .replaceAll(RegExp('[‘’]'), "'")
    .replaceAll(RegExp('[“”]'), '"')
    .replaceAll(RegExp('[–—]'), '-')
    .replaceAll(RegExp('[^\\x09\\x0A\\x0D\\x20-\\x7E\\xA0-\\xFF]+'), '?');

Future<Uint8List> buildAnswerReport(
  Profile? profile,
  Map<String, dynamic> results,
  DateTime now,
) {
  pw.Widget line(ReportLine line) {
    final (style, text) = line;
    final (size, bold, gap) = switch (style) {
      ReportStyle.title => (20.0, true, 8.0),
      ReportStyle.heading => (14.0, true, 12.0),
      ReportStyle.subheading => (11.0, true, 6.0),
      ReportStyle.body => (10.0, false, 2.0),
    };
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: gap),
      child: pw.Text(
        _printable(text),
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  final document = pw.Document(title: 'BridgeIt answers')
    ..addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          for (final item in reportLines(profile, results, now)) line(item),
        ],
      ),
    );
  return document.save();
}
