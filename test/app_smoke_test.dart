import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bridgeit/theme/app_theme.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('credits name the photo and word list sources', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Credits'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kevin MacLeod'), findsOneWidget);
    expect(find.textContaining('WordNet'), findsOneWidget);
  });

  test('every montage asset exists', () async {
    final json = jsonDecode(
      File('assets/content/levels.json').readAsStringSync(),
    );
    final level3 = json['level3'];
    expect(File(level3['musicAsset'] as String).existsSync(), isTrue);
    for (final place in level3['places'] as List) {
      for (final picture in place['pictures'] as List) {
        final asset = picture['asset'] as String;
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    }
  });

  testWidgets('app starts on the start screen with the theme', (tester) async {
    await pumpApp(tester);

    final play = find.byTooltip('Play');
    expect(play, findsOneWidget);
    final context = tester.element(play);
    expect(Theme.of(context).colorScheme.primary, AppColors.primary);
  });
}
