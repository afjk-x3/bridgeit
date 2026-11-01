import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The slot in the bridge. Accepts a dragged piece, or, as the accessibility
/// fallback, a tap while a piece is [selected]. Shows the [placed] piece;
/// tapping it with nothing selected calls [onClear].
class BridgeGap extends StatelessWidget {
  const BridgeGap({
    super.key,
    required this.selected,
    required this.onDrop,
    this.placed,
    this.onClear,
  });

  final String? selected;
  final String? placed;
  final ValueChanged<String> onDrop;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final word = selected;
    final VoidCallback? onTap = word != null
        ? () => onDrop(word)
        : placed != null
        ? onClear
        : null;
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, hovering, _) => Semantics(
        button: true,
        label: placed == null ? 'Gap in the bridge' : 'Remove $placed',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          key: const ValueKey('gap'),
          onTap: onTap,
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
            child: Text(
              placed ?? '?',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
