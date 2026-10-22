import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import 'unlock_code_form.dart';

/// Shown when a level is finished: a check, the teacher-code message and a
/// way back to the level menu. Levels 1 and 2 also ask for the teacher's code
/// right here, then offer to play the level it unlocked.
class LevelDonePanel extends StatefulWidget {
  const LevelDonePanel({super.key, required this.level, this.message});

  final int level;

  /// Replaces the default "Level N done!" text.
  final String? message;

  @override
  State<LevelDonePanel> createState() => _LevelDonePanelState();
}

class _LevelDonePanelState extends State<LevelDonePanel> {
  int? _unlocked;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final next = widget.level + 1;
    final hasNext = next <= 3;
    final play = _unlocked ?? (hasNext && progress.isUnlocked(next) ? next : null);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, size: 72, color: AppColors.correct),
        const SizedBox(height: 16),
        Text(
          widget.message ??
              'Level ${widget.level} done! Ask your teacher for the code.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        if (play != null)
          FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/level/$play'),
            child: Text('Play level $play'),
          )
        else if (hasNext)
          UnlockCodeForm(onUnlocked: (l) => setState(() => _unlocked = l)),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => Navigator.maybePop(context),
          child: const Text('Back to levels'),
        ),
      ],
    );
  }
}
