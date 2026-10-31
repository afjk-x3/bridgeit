import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/level_summaries.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';

/// The map icon on every level screen: opens the journey so far.
class JourneyButton extends StatelessWidget {
  const JourneyButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.map),
    tooltip: 'Journey',
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      builder: (_) => const JourneySheet(),
    ),
  );
}

class JourneySheet extends StatelessWidget {
  const JourneySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final done = levelSummaries
        .where((l) => progress.isCompleted(l.$1))
        .length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your journey',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: '$done of ${levelSummaries.length} levels done',
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(height: 8, color: AppColors.primary),
                    Align(
                      alignment: Alignment(
                        -1 + 2 * done / levelSummaries.length,
                        0,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        key: ValueKey('journey-car'),
                        size: 36,
                        color: AppColors.vehicle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final (level, title, _) in levelSummaries)
              ListTile(
                dense: true,
                leading: Icon(
                  progress.isCompleted(level)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: progress.isCompleted(level)
                      ? AppColors.correct
                      : AppColors.ink,
                ),
                title: Text(title),
              ),
          ],
        ),
      ),
    );
  }
}
