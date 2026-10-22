import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/bridge_round.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/bridge_gap.dart';
import '../widgets/bridge_scene.dart';
import '../widgets/hint_card.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/piece_tray.dart';
import '../widgets/strength_bar.dart';

/// Level 3: build the bridge like in Level 2, then strengthen it by picking
/// a word with the same meaning as the conjunction. Only a reinforced bridge
/// carries the vehicle.
class Level3Screen extends StatefulWidget {
  const Level3Screen({super.key});

  @override
  State<Level3Screen> createState() => _Level3ScreenState();
}

class _Level3ScreenState extends State<Level3Screen> {
  late final BridgeLevelContent _content;
  late BridgeRound _round;
  late SynonymRound _synonyms;
  int _index = 0;
  // Tap-to-select fallback: the piece waiting for a tap on the gap.
  String? _selected;
  // The wrong word whose hint is showing, and the word that built the bridge.
  String? _lastWrong;
  String? _placed;
  bool _reinforced = false;
  bool _done = false;

  BridgeSentence get _sentence => _content.sentences[_index];

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level3;
    _newRounds();
  }

  void _newRounds() {
    final max = _content.maxWrongAnswers;
    _round = BridgeRound(_sentence, maxWrongAnswers: max);
    _synonyms = SynonymRound(_sentence, maxWrongAnswers: max);
  }

  void _drop(String word) => setState(() {
    _selected = null;
    switch (_round.drop(word)) {
      case DropResult.correct:
        _placed = word;
      case DropResult.wrong || DropResult.broken:
        _lastWrong = word;
      case DropResult.ignored:
        break;
    }
  });

  void _tryAgain() => setState(() {
    _round.reset();
    _synonyms.reset();
    _selected = _lastWrong = _placed = null;
  });

  Future<void> _next() async {
    if (_index < _content.sentences.length - 1) {
      setState(() {
        _index++;
        _newRounds();
        _selected = _lastWrong = _placed = null;
        _reinforced = false;
      });
      return;
    }
    await context.read<ProgressStore>().markCompleted(3);
    if (mounted) setState(() => _done = true);
  }

  bool get _broken => _round.isBroken || _synonyms.isBroken;

  BridgeState get _bridgeState => _reinforced
      ? BridgeState.reinforced
      : _broken
      ? BridgeState.broken
      : _round.isBuilt
      ? BridgeState.wobbly
      : _round.wrongCount > 0
      ? BridgeState.cracked
      : BridgeState.open;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strengthening = _round.isBuilt;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _done
            ? const LevelDonePanel(
                level: 3,
                message: 'You reached the destination!',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'LEVEL 3 · SENTENCE ${_index + 1} OF '
                    '${_content.sentences.length}',
                    style: text.labelLarge,
                  ),
                  Text(
                    'Strengthening the bridge',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StepPill(
                          key: const ValueKey('step-build'),
                          label: '1 · Build',
                          done: strengthening,
                          current: !strengthening,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StepPill(
                          key: const ValueKey('step-strengthen'),
                          label: '2 · Strengthen',
                          done: _reinforced,
                          current: strengthening && !_reinforced,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BridgeScene(
                    // New sentence, new scene: the vehicle must not drive back.
                    key: ValueKey(_index),
                    state: _bridgeState,
                    left: _sentence.left,
                    right: _sentence.right,
                    placedWord: _placed,
                    gap: BridgeGap(selected: _selected, onDrop: _drop),
                  ),
                  const SizedBox(height: 12),
                  StrengthBar(
                    wrongCount: strengthening
                        ? _synonyms.triedWrong.length
                        : _round.wrongCount,
                    max: _content.maxWrongAnswers,
                  ),
                  const SizedBox(height: 12),
                  ..._buildFeedback(),
                  const SizedBox(height: 12),
                  if (!strengthening)
                    PieceTray(
                      enabled: !_round.isBroken,
                      tried: _round.triedWrong,
                      selected: _selected,
                      onToggle: (word) => setState(
                        () => _selected = _selected == word ? null : word,
                      ),
                    )
                  else if (!_broken && !_synonyms.isReinforced)
                    _buildChoices(),
                  const SizedBox(height: 16),
                  if (_broken)
                    FilledButton(
                      onPressed: _tryAgain,
                      child: const Text('Try again'),
                    ),
                  if (_synonyms.isReinforced && !_reinforced)
                    FilledButton(
                      onPressed: () => setState(() => _reinforced = true),
                      child: const Text('Reinforce the bridge'),
                    ),
                  if (_reinforced)
                    FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index == _content.sentences.length - 1
                            ? 'Finish'
                            : 'Next sentence',
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildFeedback() {
    if (_broken) {
      return const [
        HintCard(
          correct: false,
          text: "The bridge broke! Let's try this sentence again.",
        ),
      ];
    }
    if (_reinforced) {
      return const [
        HintCard(
          correct: true,
          text: 'Bridge reinforced! The vehicle can cross.',
        ),
      ];
    }
    if (_synonyms.isReinforced) {
      return const [
        HintCard(
          correct: true,
          text: "That's right! Now reinforce the bridge.",
        ),
      ];
    }
    final placed = _placed;
    if (placed != null) {
      return [
        HintCard.prompt(
          text: 'Pick the word that means the same as "$placed".',
        ),
        if (_synonyms.triedWrong.isNotEmpty) ...[
          const SizedBox(height: 8),
          HintCard(
            correct: false,
            text:
                'That word doesn\'t mean the same as "$placed". '
                'Try another one.',
          ),
        ],
      ];
    }
    final wrong = _lastWrong;
    return [
      if (wrong != null)
        HintCard(correct: false, text: _round.hintFor(wrong))
      else
        const HintCard.prompt(
          text:
              'Which conjunction connects these two clauses? '
              'Drag a piece into the gap.',
        ),
    ];
  }

  /// The synonym options as a 2x2 grid; a wrong pick greys its button out.
  Widget _buildChoices() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 56,
      ),
      children: [
        for (final word in _sentence.synonymChoices)
          OutlinedButton(
            key: ValueKey('synonym-$word'),
            style: _choiceStyle,
            onPressed: _synonyms.triedWrong.contains(word.toLowerCase())
                ? null
                : () => setState(() => _synonyms.choose(word)),
            child: Text(word),
          ),
      ],
    );
  }
}

final _choiceStyle =
    OutlinedButton.styleFrom(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.ink,
      disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.08),
      disabledForegroundColor: AppColors.ink.withValues(alpha: 0.35),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? AppColors.ink.withValues(alpha: 0.2)
              : AppColors.piece,
          width: 2,
        ),
      ),
    );

/// "1 · Build" / "2 · Strengthen": filled while [current], a check once [done].
class _StepPill extends StatelessWidget {
  const _StepPill({
    super.key,
    required this.label,
    required this.done,
    required this.current,
  });

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final (fill, border, ink) = current
        ? (AppColors.primary, AppColors.primary, AppColors.card)
        : done
        ? (
            AppColors.correct.withValues(alpha: 0.15),
            AppColors.correct,
            AppColors.ink,
          )
        : (AppColors.card, AppColors.ink.withValues(alpha: 0.3), AppColors.ink);
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
      ),
      // Shrinks instead of overflowing at large text sizes.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done) ...[
              const Icon(Icons.check, size: 18, color: AppColors.correct),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(color: ink, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
