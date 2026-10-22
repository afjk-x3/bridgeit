import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown when a level is finished: a check, the teacher-code message and a
/// way back to the level menu.
class LevelDonePanel extends StatelessWidget {
  const LevelDonePanel({super.key, required this.level, this.message});

  final int level;

  /// Replaces the default "Level N done!" text.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, size: 72, color: AppColors.correct),
          const SizedBox(height: 16),
          Text(
            message ?? 'Level $level done! Ask your teacher for the code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Back to levels'),
          ),
        ],
      ),
    );
  }
}
