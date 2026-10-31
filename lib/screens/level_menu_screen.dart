import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../content/level_summaries.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/unlock_code_form.dart';

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
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filled(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 80,
                  semanticsLabel: 'BridgeIt logo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a level',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final (level, title, subtitle) in levelSummaries)
              _LevelCard(
                level: level,
                title: title,
                subtitle: subtitle,
                locked: !progress.isUnlocked(level),
                completed: progress.isCompleted(level),
              ),
            if (anyLocked) ...[
              const SizedBox(height: 4),
              const UnlockCodeForm(),
            ],
          ],
        ),
      ),
    );
  }
}

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

  void _open(BuildContext context) =>
      Navigator.pushNamed(context, '/level/$level');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: AppColors.lightTeal,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _LevelTile(level: level, locked: locked),
              const SizedBox(width: 12),
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
                    Text(subtitle, style: text.bodySmall),
                    if (completed)
                      Text('Completed', style: text.labelSmall)
                    else if (!locked) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () => _open(context),
                        child: Text('Play Level $level'),
                      ),
                    ],
                  ],
                ),
              ),
              if (completed) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The square at the start of a card: the level number, or a lock.
class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.locked});

  static const _colors = {
    1: (AppColors.primary, AppColors.card),
    2: (AppColors.accent, AppColors.ink),
    3: (AppColors.card, AppColors.ink),
  };

  final int level;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors[level]!;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: locked
          ? Icon(Icons.lock, color: foreground, semanticLabel: 'Locked')
          : Text(
              '$level',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
