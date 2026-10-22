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
      true => (Icons.check, AppColors.correct),
      false => (Icons.lightbulb, AppColors.bridge),
      null => (Icons.touch_app, AppColors.primary),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: correct == null
              ? AppColors.card
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
