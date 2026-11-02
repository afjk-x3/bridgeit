import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import 'send_answers_button.dart';
import 'unlock_code_form.dart';

/// Shown when level 1 or 2 is finished: a check, the teacher-code message, a
/// way to send the answers and a way back to the level menu. It also asks for
/// the teacher's code right here, then offers to play the level it unlocked.
class LevelDonePanel extends StatefulWidget {
  const LevelDonePanel({super.key, required this.level});

  final int level;

  @override
  State<LevelDonePanel> createState() => _LevelDonePanelState();
}

class _LevelDonePanelState extends State<LevelDonePanel> {
  int? _unlocked;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final next = widget.level + 1;
    final play = _unlocked ?? (progress.isUnlocked(next) ? next : null);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SvgPicture.asset(
          'assets/images/girl_wave.svg',
          height: 200,
          semanticsLabel: 'Your guide, waving',
        ),
        const SizedBox(height: 12),
        Text(
          'LEVEL ${widget.level} COMPLETE',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Level ${widget.level} done! Ask your teacher for the code.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        const SendAnswersButton(),
        const SizedBox(height: 12),
        if (play != null)
          FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/level/$play'),
            child: Text('Play level $play'),
          )
        else
          UnlockCodeForm(onUnlocked: (l) => setState(() => _unlocked = l)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.maybePop(context),
          child: const Text('Back to levels'),
        ),
      ],
    );
  }
}
