import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A draggable conjunction tile. Tapping it (see [onTap]) is the
/// accessibility fallback: select it, then tap the gap.
class ConjunctionPiece extends StatelessWidget {
  const ConjunctionPiece({
    super.key,
    required this.word,
    required this.enabled,
    this.selected = false,
    this.onTap,
  });

  final String word;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  Widget _face() {
    final (fill, border, text) = !enabled
        ? (
            AppColors.ink.withValues(alpha: 0.08),
            AppColors.ink.withValues(alpha: 0.2),
            AppColors.ink.withValues(alpha: 0.35),
          )
        : (
            selected ? AppColors.piece.withValues(alpha: 0.15) : AppColors.card,
            AppColors.piece,
            AppColors.ink,
          );
    return Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: selected ? 4 : 2),
      ),
      // A Row, not Container.alignment, so the piece keeps its own width.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word,
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: word,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: enabled
          ? Draggable<String>(
              data: word,
              feedback: Material(
                type: MaterialType.transparency,
                child: _face(),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: _face()),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: _face(),
              ),
            )
          : _face(),
    );
  }
}
