import 'package:flutter/material.dart';

import '../content/models.dart';
import 'conjunction_piece.dart';

/// The seven FANBOYS pieces. Pieces in [tried] stay greyed out, and nothing
/// can be picked up unless [enabled]. [onToggle] selects (or deselects) a
/// piece for the tap-then-tap-the-gap fallback.
class PieceTray extends StatelessWidget {
  const PieceTray({
    super.key,
    required this.enabled,
    required this.tried,
    required this.selected,
    required this.onToggle,
  });

  final bool enabled;
  final Set<String> tried;
  final String? selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final word in fanboys)
          ConjunctionPiece(
            key: ValueKey('piece-$word'),
            word: word,
            enabled: enabled && !tried.contains(word),
            selected: selected == word,
            onTap: () => onToggle(word),
          ),
      ],
    );
  }
}
