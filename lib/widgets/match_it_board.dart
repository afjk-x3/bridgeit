import 'dart:math';

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../game/match_it_round.dart';
import '../theme/app_theme.dart';

/// The MatchIt activity: slots for the conjunctions and a tray of functions.
/// A function is dragged into a slot, or tapped and then the slot tapped.
/// Tapping a filled slot sends its function back to the tray.
class MatchItBoard extends StatefulWidget {
  const MatchItBoard({
    super.key,
    required this.pairs,
    required this.onDone,
    this.random,
  });

  final List<MatchPair> pairs;
  final VoidCallback onDone;
  final Random? random;

  @override
  State<MatchItBoard> createState() => _MatchItBoardState();
}

class _MatchItBoardState extends State<MatchItBoard> {
  late final MatchItRound _round;
  String? _selected;
  String? _message;

  @override
  void initState() {
    super.initState();
    _round = MatchItRound(widget.pairs, random: widget.random);
  }

  void _place(String conjunction, String function) => setState(() {
    _round.place(conjunction, function);
    _selected = null;
    _message = null;
  });

  void _tapSlot(String conjunction) {
    final function = _selected;
    if (function != null) {
      _place(conjunction, function);
    } else {
      setState(() => _round.remove(conjunction));
    }
  }

  void _submit() {
    final wrong = _round.submit().length;
    setState(() {
      _message = wrong == 1
          ? 'One pair went back to the bottom. Try it again.'
          : '$wrong pairs went back to the bottom. Try them again.';
    });
    if (_round.isDone) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MatchIt',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Only the slots scroll: a scroll view around the tray would take the
        // vertical drags away from the functions.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final pair in widget.pairs)
                  _SlotRow(
                    conjunction: pair.conjunction,
                    function: _round.placed[pair.conjunction],
                    locked: _round.isLocked(pair.conjunction),
                    armed: _selected != null,
                    onDrop: (function) => _place(pair.conjunction, function),
                    onTap: () => _tapSlot(pair.conjunction),
                  ),
              ],
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(message, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final function in _round.tray)
              _FunctionChip(
                key: ValueKey('fn-$function'),
                function: function,
                selected: _selected == function,
                onTap: () => setState(
                  () => _selected = _selected == function ? null : function,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _round.canSubmit ? _submit : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.conjunction,
    required this.function,
    required this.locked,
    required this.armed,
    required this.onDrop,
    required this.onTap,
  });

  final String conjunction;
  final String? function;
  final bool locked;
  final bool armed;
  final ValueChanged<String> onDrop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placed = function;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              conjunction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails: (_) => !locked,
              onAcceptWithDetails: (details) => onDrop(details.data),
              builder: (context, hovering, _) => Semantics(
                button: true,
                label: 'Slot for $conjunction: ${placed ?? 'empty'}',
                excludeSemantics: true,
                onTap: onTap,
                child: GestureDetector(
                  key: ValueKey('slot-$conjunction'),
                  behavior: HitTestBehavior.opaque,
                  onTap: locked ? null : onTap,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: locked
                            ? AppColors.correct
                            : hovering.isNotEmpty || armed
                            ? AppColors.accent
                            : AppColors.teal,
                        width: hovering.isNotEmpty || locked ? 3 : 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(placed ?? '')),
                        if (locked)
                          const Icon(Icons.check, color: AppColors.correct),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunctionChip extends StatelessWidget {
  const _FunctionChip({
    super.key,
    required this.function,
    required this.selected,
    required this.onTap,
  });

  final String function;
  final bool selected;
  final VoidCallback onTap;

  Widget _face() => Container(
    width: 160,
    constraints: const BoxConstraints(minHeight: 48),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: selected
          ? AppColors.piece.withValues(alpha: 0.15)
          : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.piece, width: selected ? 4 : 2),
    ),
    child: Text(
      function,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.ink, fontSize: 13),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: function,
    excludeSemantics: true,
    onTap: onTap,
    child: Draggable<String>(
      data: function,
      feedback: Material(type: MaterialType.transparency, child: _face()),
      childWhenDragging: Opacity(opacity: 0.3, child: _face()),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _face(),
      ),
    ),
  );
}
