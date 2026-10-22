import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "?" slot in the bridge. Accepts a dragged piece, or, as the
/// accessibility fallback, a tap while a piece is [selected].
class BridgeGap extends StatelessWidget {
  const BridgeGap({super.key, required this.selected, required this.onDrop});

  final String? selected;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final word = selected;
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, hovering, _) => Semantics(
        button: true,
        label: 'Gap in the bridge',
        excludeSemantics: true,
        onTap: word == null ? null : () => onDrop(word),
        child: GestureDetector(
          key: const ValueKey('gap'),
          onTap: word == null ? null : () => onDrop(word),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering.isNotEmpty || word != null
                    ? AppColors.accent
                    : AppColors.ink.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: const Text(
              '?',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
