import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/unlock_code_form.dart';

const _levels = [
  (1, 'Conjunction song', 'Sing along, then fill in the blanks'),
  (2, 'Building the bridge', 'Drag the right conjunction into the gap'),
  (3, 'Strengthening the bridge', 'Pick a word with the same meaning'),
];

class LevelMenuScreen extends StatelessWidget {
  const LevelMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final anyLocked = [2, 3].any((l) => !progress.isUnlocked(l));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose a level',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final (level, title, subtitle) in _levels)
              _LevelCard(
                level: level,
                title: title,
                subtitle: subtitle,
                locked: !progress.isUnlocked(level),
                completed: progress.isCompleted(level),
              ),
            if (anyLocked) const UnlockCodeForm(),
          ],
        ),
      ),
    );
  }
}

RoundedRectangleBorder get _cardShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.locked,
    required this.completed,
  });

  final int level;
  final String title;
  final String subtitle;
  final bool locked;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, status) = locked
        ? (Icons.lock, 'Ask your teacher for the code')
        : completed
        ? (Icons.check_circle, 'Completed')
        : (Icons.lock_open, 'Unlocked');
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: _cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked
            ? null
            : () => Navigator.pushNamed(context, '/level/$level'),
        child: Opacity(
          opacity: locked ? 0.7 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.card,
                  child: Text('$level'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(subtitle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: completed
                                ? AppColors.correct
                                : AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(status)),
                        ],
                      ),
                      if (!locked) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Play level $level',
                          style: text.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
