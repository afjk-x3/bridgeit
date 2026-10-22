import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../progress/progress_store.dart';
import '../theme/app_theme.dart';

/// The teacher-code field: tries the code against each locked level, lowest
/// first, and reports the level it unlocked through [onUnlocked].
class UnlockCodeForm extends StatefulWidget {
  const UnlockCodeForm({super.key, this.onUnlocked});

  final ValueChanged<int>? onUnlocked;

  @override
  State<UnlockCodeForm> createState() => _UnlockCodeFormState();
}

class _UnlockCodeFormState extends State<UnlockCodeForm> {
  final _controller = TextEditingController();
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    final progress = context.read<ProgressStore>();
    int? level;
    for (final l in [2, 3]) {
      if (!progress.isUnlocked(l) && progress.tryUnlock(l, _controller.text)) {
        level = l;
        break;
      }
    }
    if (level != null) {
      _controller.clear();
      messenger.showSnackBar(SnackBar(content: Text('Level $level unlocked!')));
      widget.onUnlocked?.call(level);
    }
    if (mounted) setState(() => _failed = level == null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _failed = false),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Got a code from your teacher?',
                helperText: 'Enter it to unlock the next level.',
                errorText: _failed
                    ? "That code didn't work. Check with your teacher."
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Unlock')),
          ],
        ),
      ),
    );
  }
}
