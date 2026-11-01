import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../content/lexicon.dart';
import '../content/models.dart';
import '../game/spell_checker.dart';
import '../game/travelogue_analyzer.dart';
import '../progress/progress_store.dart';
import '../progress/results_store.dart';
import '../theme/app_theme.dart';
import '../widgets/level_app_bar.dart';
import '../widgets/level_clock.dart';
import '../widgets/montage_player.dart';
import '../widgets/place_map.dart';
import '../widgets/send_answers_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/travelogue_editor.dart';

enum _Step {
  tollGate,
  crossed,
  map,
  montage,
  goodbye,
  instructions,
  travelogue,
  ending,
}

/// Level 3: pass the toll gate, choose a place, watch its montage, then write
/// a travelogue entry.
class Level3Screen extends StatefulWidget {
  const Level3Screen({super.key});

  @override
  State<Level3Screen> createState() => _Level3ScreenState();
}

class _Level3ScreenState extends State<Level3Screen> {
  late final Level3Content _content;
  late final TravelogueAnalyzer _analyzer;
  late final SpellChecker _baseSpelling;
  final _clock = LevelClock();
  _Step _step = _Step.tollGate;
  Place? _place;

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level3;
    final writing = context.read<WritingTools>();
    _analyzer = TravelogueAnalyzer(writing.clauses, _content.travelogue);
    _baseSpelling = writing.spelling;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _go(_Step step) => setState(() => _step = step);

  /// Words a student may copy from the captions, such as "sandboard".
  SpellChecker get _spelling => _baseSpelling.withAllowed({
    for (final picture in _place?.pictures ?? const <PlacePicture>[])
      ...picture.caption.toLowerCase().split(RegExp('[^a-z]+')),
  });

  Future<void> _submit(String entry) async {
    final progress = context.read<ProgressStore>();
    final result = _analyzer.analyze(entry);
    await context.read<ResultsStore>().saveResult(3, {
      'place': _place?.name,
      'entry': entry.trim(),
      'sentences': result.sentenceCount,
      'conjunctions': [
        for (final span in result.counted)
          entry.substring(span.start, span.end),
      ],
      'spellingWarnings': _spelling.check(entry).length,
      'activeMs': _clock.elapsedMs,
    });
    await progress.markCompleted(3);
    if (mounted) _go(_Step.ending);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: levelAppBar(context, 3, 'Travelogue'),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() => switch (_step) {
    _Step.tollGate => _Story(
      lines: const [
        "We've finally arrived at the toll gate. Are you ready to pass "
            'through?',
      ],
      button: 'Next',
      onPressed: () => _go(_Step.crossed),
    ),
    _Step.crossed => _Story(
      lines: const [
        'I have finally crossed the bridge! Thank you, Bridge Builder! Now, '
            "let's go explore, shall we?",
        'Tap the map to choose which place we shall go.',
      ],
      button: 'Proceed',
      onPressed: () => _go(_Step.map),
    ),
    _Step.map => _buildMap(),
    _Step.montage => MontagePlayer(
      place: _place!,
      musicAsset: _content.musicAsset,
      onDone: () => _go(_Step.goodbye),
    ),
    _Step.goodbye => _Story(
      lines: const [
        'Thank you so much for joining me in this amazing experience!',
        "I'll never forget this experience. I'll definitely write about it in "
            'my travelogue journal. I hope you will too.',
      ],
      button: 'Next',
      onPressed: () => _go(_Step.instructions),
    ),
    _Step.instructions => _buildInstructions(),
    _Step.travelogue => Padding(
      padding: const EdgeInsets.all(16),
      child: TravelogueEditor(
        analyzer: _analyzer,
        rules: _content.travelogue,
        spelling: _spelling,
        onSubmit: _submit,
      ),
    ),
    _Step.ending => _buildEnding(),
  };

  Widget _buildMap() {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "LET'S EXPLORE TOGETHER!",
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Choose a place you want to go.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PlaceMap(
              places: _content.places,
              onChosen: (place) => setState(() {
                _place = place;
                _step = _Step.montage;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final text = Theme.of(context).textTheme;
    final rules = _content.travelogue;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Travelogue Entry',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.card,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Instructions:\n\nWrite a travelogue entry describing your '
              'travelling experience. Include where you went, the activities '
              'you enjoyed, the sights you saw, how you felt during the trip, '
              'and the lessons or memories you took away.',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SpeechBubble(
          'Your entry must have ${rules.minSentences} to '
          '${rules.maxSentences} sentences, with at least '
          '${rules.minConjunctions} coordinating conjunctions joining clauses.',
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _go(_Step.travelogue),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildEnding() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SvgPicture.asset(
          'assets/images/girl_wave.svg',
          height: 240,
          semanticsLabel: 'Your guide, waving',
        ),
        const SizedBox(height: 12),
        const SpeechBubble(
          'Congratulations, Bridge Builder! We have finally reached the end '
          'of our journey. I hope you had a fantastic trip and learned a lot '
          'along the way!',
        ),
        const SpeechBubble(
          'May this adventure inspire you to build strong, coherent sentences '
          'using coordinating conjunctions wherever your writing takes you.',
        ),
        const SpeechBubble('Thank you for traveling with me!'),
        const SizedBox(height: 8),
        const SendAnswersButton(),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: () => Navigator.maybePop(context),
          child: const Text('Back to levels'),
        ),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.lines,
    required this.button,
    required this.onPressed,
  });

  final List<String> lines;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SvgPicture.asset(
              'assets/images/girl_wave.svg',
              height: 200,
              semanticsLabel: 'Your guide, waving',
            ),
            const SizedBox(height: 12),
            for (final line in lines) SpeechBubble(line),
            const SizedBox(height: 8),
            FilledButton(onPressed: onPressed, child: Text(button)),
          ],
        ),
      ),
    );
  }
}
