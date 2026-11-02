import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Feedback under the scene: a hint for a wrong word, a success message for
/// a right one, or (via [HintCard.prompt]) a neutral instruction.
class HintCard extends StatelessWidget {
  const HintCard({super.key, required this.text, required bool this.correct});

  const HintCard.prompt({super.key, required this.text}) : correct = null;

  final String text;

  /// true: success, false: hint, null: neutral prompt.
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (correct) {
      true => (Icons.check, AppColors.teal),
      false => (Icons.lightbulb_outline, AppColors.accent),
      null => (Icons.touch_app, AppColors.ink),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: correct == null ? AppColors.ink : color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
