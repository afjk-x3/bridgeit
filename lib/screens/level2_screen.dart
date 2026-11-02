import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/lexicon.dart';
import '../content/models.dart';
import '../game/bridge_round.dart';
import '../game/sentence_checker.dart';
import '../progress/progress_store.dart';
import '../progress/results_store.dart';
import '../theme/app_theme.dart';
import '../widgets/bridge_gap.dart';
import '../widgets/bridge_scene.dart';
import '../widgets/hint_card.dart';
import '../widgets/level_app_bar.dart';
import '../widgets/level_clock.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/piece_tray.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/writing_panel.dart';

enum _Step {
  story,
  build,
  built,
  writeConjunction,
  writeSimilar,
  sturdy,
  crossing,
  done,
}

/// What a student should fix, for each [CheckFailure].
String checkMessage(CheckFailure failure, String word, WordRule rule) =>
    switch (failure) {
      CheckFailure.empty => 'Write your sentence first.',
      CheckFailure.capital => 'Start your sentence with a capital letter.',
      CheckFailure.endPunctuation => 'End your sentence with . ! or ?',
      CheckFailure.oneSentence => 'Write only one sentence.',
      CheckFailure.notReal => "Those don't look like real words. Try again.",
      CheckFailure.missingWord => "Use '$word' in your sentence.",
      CheckFailure.comma =>
        rule == WordRule.joining
            ? "Put a comma after the part that starts with '$word'."
            : "Put a comma right before '$word'.",
      CheckFailure.extraComma => "Remove the comma before '$word'.",
      CheckFailure.semicolon =>
        "Put a semicolon before '$word' and a comma after it.",
      CheckFailure.notClause =>
        'Your sentence must be a full clause, with a subject and a verb.',
      CheckFailure.leftClause =>
        "The part before '$word' must be a full clause, with a subject and a "
            'verb.',
      CheckFailure.rightClause =>
        "The part after '$word' must be a full clause, with a subject and a "
            'verb.',
      CheckFailure.norNeedsNegative =>
        "Use 'nor' after a negative idea, such as 'did not' or 'never'.",
      CheckFailure.norWordOrder =>
        "After 'nor', put the helping verb before the subject: 'nor did she "
            "go'.",
      CheckFailure.copied =>
        "Write your own sentence. Don't copy one from the screen or use one "
            'again.',
    };

/// The Quick Facts word used in [text], or null. Longest first, because
/// "as a result" holds "as".
QuickFact? findQuickFact(String text, List<QuickFact> facts) {
  final byLength = [...facts]
    ..sort((a, b) => b.word.length.compareTo(a.word.length));
  for (final fact in byLength) {
    final pattern = RegExp(
      "(?<![A-Za-z'])${RegExp.escape(fact.word)}(?![A-Za-z'])",
      caseSensitive: false,
    );
    if (pattern.hasMatch(text)) return fact;
  }
  return null;
}

/// Level 2: seven bridges. Build each with the right conjunction, strengthen
/// it with the student's own sentences, then drive across.
class Level2Screen extends StatefulWidget {
  const Level2Screen({super.key});

  @override
  State<Level2Screen> createState() => _Level2ScreenState();
}

class _Level2ScreenState extends State<Level2Screen> {
  late final Level2Content _content;
  late final Map<String, List<QuickFact>> _quickFacts;
  late final WritingTools _writing;
  late final List<List<String>> _written;
  // Each bridge's numbers for the report.
  late final List<Map<String, dynamic>> _stats;
  final _clock = LevelClock();
  // This bridge's time from before the clock started.
  int _earlierMs = 0;
  int _attempts = 0;
  late BridgeRound _round;
  // What each conjunction does, from Level 1's MatchIt.
  late final Map<String, String> _functions;
  int _index = 0;
  _Step _step = _Step.story;
  // Tap-to-select fallback: the piece waiting for a tap on the gap.
  String? _selected;
  // The piece in the gap, and the wrong word whose hint is showing.
  String? _placed;
  String? _lastWrong;
  // Passed, but a clause couldn't be confirmed.
  bool _unsure = false;

  Bridge get _bridge => _content.bridges[_index];

  static String _triesLeft(int n) => '$n ${n == 1 ? 'try' : 'tries'} left';
  bool get _placedWrong =>
      _placed != null && _round.triedWrong.contains(_placed!.toLowerCase());
  List<QuickFact> get _facts => _quickFacts[_bridge.conjunction] ?? const [];
  List<String> get _foundations => _written[_index];

  /// The written sentences as piers: the first uses the conjunction, the
  /// second the Quick Facts word it was written with.
  List<BridgePier> get _piers => [
    for (final (i, text) in _foundations.indexed)
      BridgePier(
        i == 0
            ? _bridge.conjunction
            : findQuickFact(text, _facts)?.word ?? _bridge.conjunction,
        text,
      ),
  ];

  @override
  void initState() {
    super.initState();
    final game = context.read<GameContent>();
    _content = game.level2;
    _quickFacts = game.quickFacts;
    _functions = {
      for (final pair in game.level1.matchIt) pair.conjunction: pair.function,
    };
    _writing = context.read<WritingTools>();
    _written = [for (final _ in _content.bridges) <String>[]];
    _stats = [
      for (final bridge in _content.bridges)
        {
          'conjunction': bridge.conjunction,
          'wrongTries': 0,
          'collapses': 0,
          'activeMs': 0,
          'sentences': <Map<String, dynamic>>[],
        },
    ];
    final resume = context.read<ResultsStore>().level2Resume;
    if (resume != null && resume.bridgeIndex < _content.bridges.length) {
      _index = resume.bridgeIndex;
      for (var i = 0; i < resume.written.length; i++) {
        if (i < _written.length) _written[i].addAll(resume.written[i]);
      }
      for (var i = 0; i < resume.stats.length; i++) {
        if (i < _stats.length) _stats[i] = resume.stats[i];
      }
      _earlierMs = _stats[_index]['activeMs'] as int;
      _step = _Step.build;
    }
    _round = _newRound();
    if (_foundations.isNotEmpty) {
      _round.drop(_bridge.conjunction);
      _placed = _bridge.conjunction;
      _step = _afterSentence();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  BridgeRound _newRound() => BridgeRound(
    _bridge,
    maxWrongAnswers: _content.maxWrongAnswers,
    functions: _functions,
  );

  _Step _afterSentence() => _foundations.length == 1 && _facts.isNotEmpty
      ? _Step.writeSimilar
      : _Step.sturdy;

  void _count(String stat) =>
      _stats[_index][stat] = (_stats[_index][stat] as int) + 1;

  void _recordTime() =>
      _stats[_index]['activeMs'] = _earlierMs + _clock.elapsedMs;

  Future<void> _save() {
    _recordTime();
    return context.read<ResultsStore>().saveLevel2Resume(
      Level2Resume(bridgeIndex: _index, written: _written, stats: _stats),
    );
  }

  void _place(String word) => setState(() {
    _placed = word;
    _selected = null;
    _lastWrong = null;
  });

  void _cross() {
    final word = _placed;
    if (word == null) return;
    setState(() {
      switch (_round.drop(word)) {
        case DropResult.correct:
          _step = _Step.built;
        case DropResult.wrong:
          _count('wrongTries');
          _lastWrong = word;
        case DropResult.broken:
          _count('wrongTries');
          _count('collapses');
          _lastWrong = word;
          _placed = null;
        case DropResult.ignored:
          _placed = null;
      }
    });
  }

  void _tryAgain() => setState(() {
    _round.reset();
    _selected = _placed = _lastWrong = null;
  });

  /// Everything a student may not hand in as their own sentence.
  List<String> get _forbidden => [
    '${_bridge.left}, ${_bridge.conjunction} ${_bridge.right}',
    ..._bridge.examples,
    for (final sentences in _written) ...sentences,
  ];

  String? _submit(String text, String word, WordRule rule) {
    _attempts++;
    final result = _writing.sentences.check(
      text,
      word: word,
      rule: rule,
      forbidden: _forbidden,
    );
    switch (result) {
      case Failed(:final reason):
        return checkMessage(reason, word, rule);
      case Passed(:final unsureClause):
        (_stats[_index]['sentences'] as List).add({
          'text': text.trim(),
          'attempts': _attempts,
          'spellingWarnings': _writing.spelling.check(text).length,
          'unsure': unsureClause,
        });
        _attempts = 0;
        setState(() {
          _foundations.add(text.trim());
          _unsure = unsureClause;
          _step = _afterSentence();
        });
        _save();
        return null;
    }
  }

  String? _submitSimilar(String text) {
    final fact = findQuickFact(text, _facts);
    if (fact == null) {
      return 'Use one of the words from Quick Facts in your sentence.';
    }
    final rule = fact.rule == QuickFactRule.linking
        ? WordRule.linking
        : WordRule.joining;
    return _submit(text, fact.word, rule);
  }

  Future<void> _crossed() async {
    if (_step != _Step.crossing) return;
    _recordTime();
    if (_index == _content.bridges.length - 1) {
      final results = context.read<ResultsStore>();
      final progress = context.read<ProgressStore>();
      await results.saveResult(2, {'bridges': _stats});
      await progress.markCompleted(2);
      await results.clearLevel2Resume();
      if (mounted) setState(() => _step = _Step.done);
      return;
    }
    setState(() {
      _index++;
      _earlierMs = 0;
      _clock.timer.reset();
      _round = _newRound();
      _selected = _placed = _lastWrong = null;
      _unsure = false;
      _step = _Step.build;
    });
    await _save();
  }

  BridgeState get _bridgeState => _step != _Step.build
      ? BridgeState.built
      : _round.isBroken
      ? BridgeState.broken
      : _round.wrongCount > 0
      ? BridgeState.cracked
      : BridgeState.open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: switch (_step) {
        // The story and the level's end are not about one bridge.
        _Step.story ||
        _Step.done => levelAppBar(context, 2, 'Building Bridges'),
        _ => levelAppBar(
          context,
          2,
          _step == _Step.build ? 'Building Bridges' : 'Strengthen the bridge',
          kicker:
              'LEVEL 2 · BRIDGE ${_index + 1} OF ${_content.bridges.length}',
        ),
      },
      body: SafeArea(
        child: switch (_step) {
          _Step.story => _buildStory(),
          _Step.done => const LevelDonePanel(level: 2),
          _Step.build => _buildBridge(),
          _ => _buildAfterBridge(),
        },
      ),
    );
  }

  Widget _buildStory() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Scrolls for large text; the bottom padding keeps it clear of Next.
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BridgeScene(
                state: BridgeState.open,
                left: _bridge.left,
                right: _bridge.right,
                gap: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              const SpeechBubble(
                'Oh no! The bridge is broken, so I cannot cross.',
                strong: true,
              ),
              const SpeechBubble(
                'To cross the broken bridge, drag the right coordinating '
                'conjunction to connect the two independent clauses from each '
                'side of the bridge.',
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 52),
              backgroundColor: AppColors.lightTeal,
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
            onPressed: () => setState(() => _step = _Step.build),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _scene({Widget gap = const SizedBox.shrink()}) => BridgeScene(
    // New bridge, new scene: the vehicle must not drive back.
    key: ValueKey(_index),
    state: _bridgeState,
    // While building, the comma is on the piece; after, it joins the clauses.
    left: _step == _Step.build ? _bridge.left : '${_bridge.left},',
    right: _bridge.right,
    placedWord: _placed,
    gap: gap,
    piers: _piers,
    // nor has no Quick Facts, so it takes one sentence.
    piersNeeded: _facts.isEmpty ? 1 : 2,
    cracks: _round.wrongCount,
    crossed: _step == _Step.crossing,
    onCrossed: _crossed,
  );

  // The tray stays outside the scroll view, which would take its drags.
  Widget _buildBridge() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_round.wrongCount > 0 && !_round.isBroken)
                    Text(
                      _triesLeft(_content.maxWrongAnswers - _round.wrongCount),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _scene(
                    gap: BridgeGap(
                      selected: _selected,
                      placed: _placed,
                      wrong: _placedWrong,
                      onDrop: _place,
                      onClear: () => setState(() => _placed = null),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedback(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PieceTray(
            enabled: !_round.isBroken,
            tried: _round.triedWrong,
            selected: _selected,
            onToggle: (word) =>
                setState(() => _selected = _selected == word ? null : word),
          ),
          const SizedBox(height: 12),
          if (_round.isBroken)
            FilledButton(onPressed: _tryAgain, child: const Text('Try again'))
          else
            FilledButton(
              onPressed: _placed == null || _placedWrong ? null : _cross,
              child: const Text('Cross the bridge'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final wrong = _lastWrong;
    if (_round.isBroken) {
      return const HintCard(
        correct: false,
        text: "The bridge collapsed! Let's try this bridge again.",
      );
    }
    if (wrong != null) {
      return HintCard(correct: false, text: _round.hintFor(wrong));
    }
    return const HintCard.prompt(
      text:
          'Drag a piece onto the bridge to connect the two clauses, then '
          'cross it.',
    );
  }

  Widget _buildAfterBridge() {
    final conjunction = _bridge.conjunction;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...switch (_step) {
          _Step.built => [
            const SpeechBubble(
              'Yay! But the bridge still seems unstable. Can you make it '
              'sturdier?',
            ),
            _scene(),
            const SizedBox(height: 12),
            HintCard(
              correct: true,
              text: 'That is correct! ${_bridge.explanation}',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() => _step = _Step.writeConjunction),
              child: const Text('Strengthen the Bridge'),
            ),
          ],
          _Step.writeConjunction => [
            SpeechBubble(
              'To strengthen the bridge, you must write your own sentence '
              "using the coordinating conjunction, '$conjunction'.",
            ),
            _scene(),
            const SizedBox(height: 12),
            WritingPanel(
              key: const ValueKey('write-conjunction'),
              spelling: _writing.spelling,
              checklistWord: conjunction,
              hint: [
                describeWord(conjunction, _functions[conjunction] ?? ''),
                if (_bridge.examples.isNotEmpty)
                  'Another example: ${_bridge.examples.first}',
              ].join(' '),
              onSubmit: (text) => _submit(text, conjunction, WordRule.fanboys),
            ),
          ],
          _Step.writeSimilar => [
            _QuickFactsCard(conjunction: conjunction, facts: _facts),
            const SizedBox(height: 12),
            _scene(),
            const SizedBox(height: 12),
            if (_unsure) ...[_unsureHint, const SizedBox(height: 12)],
            WritingPanel(
              key: const ValueKey('write-similar'),
              spelling: _writing.spelling,
              onSubmit: _submitSimilar,
            ),
          ],
          _ => [
            const SpeechBubble(
              'Now the bridge seems sturdy. I can finally cross!',
            ),
            _scene(),
            const SizedBox(height: 12),
            if (_unsure) _unsureHint,
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _step == _Step.sturdy
                  ? () => setState(() => _step = _Step.crossing)
                  : null,
              child: const Text('Cross the Bridge'),
            ),
          ],
        },
      ],
    );
  }

  Widget get _unsureHint => const HintCard.prompt(
    text:
        'Your sentence is in. Check that both parts are full clauses, each '
        'with a subject and a verb.',
  );
}

class _FactWord extends StatelessWidget {
  const _FactWord(this.word);

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

/// Quick Facts kept on screen while the student writes the second sentence.
class _QuickFactsCard extends StatelessWidget {
  const _QuickFactsCard({required this.conjunction, required this.facts});

  final String conjunction;
  final List<QuickFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Facts',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            "Aside from '$conjunction', you may also use these words, but "
            'they are not coordinating conjunctions.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final fact in facts) _FactWord(fact.word)],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Task: Use one of these words to write another sentence.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
