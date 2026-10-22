import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Brown segments for the strength left, red for what wrong guesses cost.
class StrengthBar extends StatelessWidget {
  const StrengthBar({super.key, required this.wrongCount, required this.max});

  final int wrongCount;
  final int max;

  @override
  Widget build(BuildContext context) {
    final left = max - wrongCount;
    return Semantics(
      label: 'Bridge strength, $left of $max',
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            'Bridge strength',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 12),
          // Expanded so any max fits, down to a 360dp phone.
          for (var i = 0; i < max; i++)
            Expanded(
              child: Container(
                key: ValueKey('strength-$i'),
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < left ? AppColors.bridge : AppColors.wrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
