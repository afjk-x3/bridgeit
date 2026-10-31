import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../progress/progress_store.dart';
import '../widgets/level_done_panel.dart';

/// shortcut: stands in for levels 1 and 3 so the menu and codes stay playable,
/// replace with the real screens in DEV-PRD tasks 3 and 7.
class LevelStubScreen extends StatefulWidget {
  const LevelStubScreen({super.key, required this.level});

  final int level;

  @override
  State<LevelStubScreen> createState() => _LevelStubScreenState();
}

class _LevelStubScreenState extends State<LevelStubScreen> {
  bool _done = false;

  Future<void> _finish() async {
    await context.read<ProgressStore>().markCompleted(widget.level);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: _done
          ? LevelDonePanel(level: widget.level)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Level ${widget.level} is being rebuilt.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _finish, child: const Text('Finish')),
                ],
              ),
            ),
    ),
  );
}
