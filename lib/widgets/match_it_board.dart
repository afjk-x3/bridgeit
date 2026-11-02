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

  /// Gets the wrong conjunctions of each attempt.
  final ValueChanged<List<List<String>>> onDone;
  final Random? random;

  @override
  State<MatchItBoard> createState() => _MatchItBoardState();
}

class _MatchItBoardState extends State<MatchItBoard> {
  late final MatchItRound _round;
  String? _selected;
  String? _message;
  Set<String> _wrong = const {};

  @override
  void initState() {
    super.initState();
    _round = MatchItRound(widget.pairs, random: widget.random);
  }

  void _place(String conjunction, String function) => setState(() {
    _round.place(conjunction, function);
    _selected = null;
    _message = null;
    _wrong = {..._wrong}..remove(conjunction);
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
    final wrong = _round.submit();
    setState(() {
      _wrong = wrong.toSet();
      _message = wrong.length == 1
          ? 'One pair went back to the bottom. Try it again.'
          : '${wrong.length} pairs went back to the bottom. Try them again.';
    });
    if (_round.isDone) widget.onDone(_round.attempts);
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only the slots scroll: a scroll view around the tray would take the
        // vertical drags away from the functions.
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text(
                            'Coordinating Conjunctions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Functions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final pair in widget.pairs)
                    _SlotRow(
                      conjunction: pair.conjunction,
                      function: _round.placed[pair.conjunction],
                      locked: _round.isLocked(pair.conjunction),
                      wrong: _wrong.contains(pair.conjunction),
                      armed: _selected != null,
                      onDrop: (function) => _place(pair.conjunction, function),
                      onTap: () => _tapSlot(pair.conjunction),
                    ),
                ],
              ),
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
    required this.wrong,
    required this.armed,
    required this.onDrop,
    required this.onTap,
  });

  final String conjunction;
  final String? function;
  final bool locked;
  final bool wrong;
  final bool armed;
  final ValueChanged<String> onDrop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placed = function;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              conjunction,
              style: const TextStyle(
                color: AppColors.card,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DragTarget<String>(
              onWillAcceptWithDetails: (_) => !locked,
              onAcceptWithDetails: (details) => onDrop(details.data),
              builder: (context, hovering, _) => Semantics(
                button: true,
                label:
                    'Slot for $conjunction: ${placed ?? 'empty'}'
                    '${wrong ? ', wrong, try again' : ''}',
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
                      color: wrong
                          ? AppColors.wrong.withValues(alpha: 0.12)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: locked
                            ? AppColors.correct
                            : wrong
                            ? AppColors.wrong
                            : hovering.isNotEmpty || armed
                            ? AppColors.accent
                            : AppColors.teal,
                        width: hovering.isNotEmpty || locked || wrong ? 3 : 2,
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
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
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
