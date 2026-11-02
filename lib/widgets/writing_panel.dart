import 'package:flutter/material.dart';

import '../game/spell_checker.dart';
import '../theme/app_theme.dart';

/// Underlines unknown words as the student types.
class SpellingController extends TextEditingController {
  SpellingController(this._spelling);

  final SpellChecker _spelling;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <TextSpan>[];
    var at = 0;
    for (final span in _spelling.check(text)) {
      children
        ..add(TextSpan(text: text.substring(at, span.start)))
        ..add(
          TextSpan(
            text: text.substring(span.start, span.end),
            style: const TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.wrong,
              decorationStyle: TextDecorationStyle.wavy,
            ),
          ),
        );
      at = span.end;
    }
    children.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: children);
  }
}

/// One free-text box for a student sentence. [onSubmit] returns what to fix,
/// or null when the sentence is accepted.
class WritingPanel extends StatefulWidget {
  const WritingPanel({
    super.key,
    required this.spelling,
    required this.onSubmit,
  });

  final SpellChecker spelling;
  final String? Function(String text) onSubmit;

  @override
  State<WritingPanel> createState() => _WritingPanelState();
}

class _WritingPanelState extends State<WritingPanel> {
  late final SpellingController _controller;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _controller = SpellingController(widget.spelling);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Your sentence',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 4,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          // The capital and spelling are the student's to get right.
          autocorrect: false,
          enableSuggestions: false,
          // Keeps Submit above the keyboard.
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          onChanged: (_) => setState(() => _problem = null),
          decoration: const InputDecoration(
            hintText: 'Write your own sentence here.',
          ),
        ),
        if (problem != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                left: BorderSide(color: AppColors.wrong, width: 5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.wrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    problem,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () =>
              setState(() => _problem = widget.onSubmit(_controller.text)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
