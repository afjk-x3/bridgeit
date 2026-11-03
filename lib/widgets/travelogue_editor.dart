import 'dart:async';

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../game/spell_checker.dart';
import '../game/travelogue_analyzer.dart';
import '../theme/app_theme.dart';

/// Colors the conjunctions as they count and underlines unknown words.
class TravelogueController extends TextEditingController {
  TravelogueController(this._spelling);

  final SpellChecker _spelling;
  TravelogueResult result = TravelogueResult.empty;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Results lag the text by the debounce, so skip spans past its end.
    final length = text.length;
    final counted = result.counted.where((r) => r.end <= length);
    final uncounted = result.uncounted.where((r) => r.end <= length);
    final misspelt = _spelling.check(text);
    final cuts = {
      0,
      length,
      for (final r in [...counted, ...uncounted]) ...[r.start, r.end],
      for (final s in misspelt) ...[s.start, s.end],
    }.toList()..sort();

    bool within(int at, int start, int end) => at >= start && at < end;
    final children = <TextSpan>[];
    for (var i = 0; i + 1 < cuts.length; i++) {
      final at = cuts[i];
      final isCounted = counted.any((r) => within(at, r.start, r.end));
      final isUncounted = uncounted.any((r) => within(at, r.start, r.end));
      final isMisspelt = misspelt.any((s) => within(at, s.start, s.end));
      children.add(
        TextSpan(
          text: text.substring(at, cuts[i + 1]),
          style: TextStyle(
            color: isCounted
                ? AppColors.cliff
                : isUncounted
                ? AppColors.ink.withValues(alpha: 0.5)
                : null,
            fontWeight: isCounted ? FontWeight.bold : null,
            decoration: isMisspelt ? TextDecoration.underline : null,
            decorationColor: isMisspelt ? AppColors.wrong : null,
            decorationStyle: isMisspelt ? TextDecorationStyle.wavy : null,
          ),
        ),
      );
    }
    return TextSpan(style: style, children: children);
  }
}

/// The travelogue box, a counter of what's still needed, and Submit.
class TravelogueEditor extends StatefulWidget {
  const TravelogueEditor({
    super.key,
    required this.analyzer,
    required this.rules,
    required this.spelling,
    required this.onSubmit,
    this.initialText = '',
    this.onChanged,
  });

  final TravelogueAnalyzer analyzer;
  final TravelogueRules rules;
  final SpellChecker spelling;
  final ValueChanged<String> onSubmit;

  /// A draft to continue, and where each change is reported to keep it.
  final String initialText;
  final ValueChanged<String>? onChanged;

  @override
  State<TravelogueEditor> createState() => _TravelogueEditorState();
}

class _TravelogueEditorState extends State<TravelogueEditor> {
  late final TravelogueController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TravelogueController(widget.spelling)
      ..text = widget.initialText
      ..result = widget.analyzer.analyze(widget.initialText);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    widget.onChanged?.call(text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _controller.result = widget.analyzer.analyze(text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _controller.result;
    final rules = widget.rules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            autocorrect: false,
            enableSuggestions: false,
            textAlignVertical: TextAlignVertical.top,
            onChanged: _changed,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Write your travelogue entry here.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          key: const ValueKey('travelogue-counter'),
          children: [
            _Meter(
              label:
                  'Sentences: ${result.sentenceCount} of '
                  '${rules.minSentences}–${rules.maxSentences}',
              value: result.sentenceCount / rules.minSentences,
            ),
            const SizedBox(width: 8),
            _Meter(
              label:
                  'Conjunctions: ${result.counted.length} of '
                  '${rules.minConjunctions}',
              value: result.counted.length / rules.minConjunctions,
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: result.canSubmit
              ? () => widget.onSubmit(_controller.text)
              : null,
          child: Text(submitLabel(result, rules)),
        ),
      ],
    );
  }
}

/// One progress box under the journal: a label and a bar toward the minimum.
class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.teal,
              backgroundColor: AppColors.sky,
            ),
          ],
        ),
      ),
    );
  }
}
