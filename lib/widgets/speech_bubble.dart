import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// What the guide says. [strong] marks the last, key line in navy; [color]
/// replaces the light-teal fill of a plain bubble.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(this.text, {super.key, this.strong = false, this.color});

  final String text;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: strong ? AppColors.ink : color ?? AppColors.lightTeal,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: strong ? AppColors.card : AppColors.ink,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          height: 1.35,
        ),
      ),
    );
  }
}
