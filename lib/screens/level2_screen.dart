import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/bridge_round.dart';
import '../progress/progress_store.dart';
import '../widgets/bridge_gap.dart';
import '../widgets/bridge_scene.dart';
import '../widgets/hint_card.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/piece_tray.dart';
import '../widgets/strength_bar.dart';

/// Level 2: drag the right conjunction into the gap to build the bridge.
class Level2Screen extends StatefulWidget {
  const Level2Screen({super.key});

  @override
  State<Level2Screen> createState() => _Level2ScreenState();
}

class _Level2ScreenState extends State<Level2Screen> {
  late final BridgeLevelContent _content;
  late BridgeRound _round;
  int _index = 0;
  // Tap-to-select fallback: the piece waiting for a tap on the gap.
  String? _selected;
  // The wrong word whose hint is showing, and the word that built the bridge.
  String? _lastWrong;
  String? _placed;
  bool _done = false;

  BridgeSentence get _sentence => _content.sentences[_index];

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level2;
    _round = _newRound();
  }

  BridgeRound _newRound() =>
      BridgeRound(_sentence, maxWrongAnswers: _content.maxWrongAnswers);

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
    _selected = _lastWrong = null;
  });

  Future<void> _next() async {
    if (_index < _content.sentences.length - 1) {
      setState(() {
        _index++;
        _round = _newRound();
        _selected = _lastWrong = _placed = null;
      });
      return;
    }
    await context.read<ProgressStore>().markCompleted(2);
    if (mounted) setState(() => _done = true);
  }

  BridgeState get _bridgeState => _round.isBuilt
      ? BridgeState.built
      : _round.isBroken
      ? BridgeState.broken
      : _round.wrongCount > 0
      ? BridgeState.cracked
      : BridgeState.open;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _done
            ? const LevelDonePanel(level: 2)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'LEVEL 2 · SENTENCE ${_index + 1} OF '
                    '${_content.sentences.length}',
                    style: text.labelLarge,
                  ),
                  Text(
                    'Building the bridge',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    wrongCount: _round.wrongCount,
                    max: _content.maxWrongAnswers,
                  ),
                  const SizedBox(height: 12),
                  _buildFeedback(),
                  const SizedBox(height: 12),
                  PieceTray(
                    enabled: !_round.isBuilt && !_round.isBroken,
                    tried: _round.triedWrong,
                    selected: _selected,
                    onToggle: (word) => setState(
                      () => _selected = _selected == word ? null : word,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_round.isBroken)
                    FilledButton(
                      onPressed: _tryAgain,
                      child: const Text('Try again'),
                    ),
                  if (_round.isBuilt)
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

  Widget _buildFeedback() {
    final wrong = _lastWrong;
    if (_round.isBroken) {
      return const HintCard(
        correct: false,
        text: "The bridge broke! Let's try this sentence again.",
      );
    }
    if (_round.isBuilt) {
      return const HintCard(
        correct: true,
        text: 'Bridge built! The vehicle can cross.',
      );
    }
    if (wrong != null) {
      return HintCard(correct: false, text: _round.hintFor(wrong));
    }
    return const HintCard.prompt(
      text:
          'Which conjunction connects these two clauses? '
          'Drag a piece into the gap.',
    );
  }
}
