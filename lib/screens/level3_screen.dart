import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../content/lexicon.dart';
import '../content/models.dart';
import '../game/spell_checker.dart';
import '../game/travelogue_analyzer.dart';
import '../progress/progress_store.dart';
import '../progress/results_store.dart';
import 'start_screen.dart';
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
      appBar: _step == _Step.montage
          ? levelAppBar(context, 3, _place!.name, kicker: 'LEVEL 3', dark: true)
          : levelAppBar(
              context,
              3,
              'Travelogue',
              journey: _step != _Step.ending,
            ),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() => switch (_step) {
    _Step.tollGate => _Story(
      scene: true,
      picture: 'assets/images/scenes/toll_gate.svg',
      pictureLabel:
          'Through the windshield, a toll booth with an attendant handing '
          'out a ticket, and a striped barrier across the lane',
      lines: const [
        "We've finally arrived at the toll gate. Are you ready to pass "
            'through?',
      ],
      button: 'Next',
      onPressed: () => _go(_Step.crossed),
    ),
    _Step.crossed => _Story(
      footer: const BridgeStrip(crossed: true),
      picture: 'assets/images/girl_drive.svg',
      pictureLabel: 'Your guide, driving',
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
      onMap: () => _go(_Step.map),
    ),
    _Step.goodbye => _Story(
      picture: 'assets/images/girl_journal.svg',
      pictureLabel: 'Your guide, holding her journal',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // With the keyboard open, the journal box gets the room.
          if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
            _JournalPrompt(place: _place?.name),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: TravelogueEditor(
              analyzer: _analyzer,
              rules: _content.travelogue,
              spelling: _spelling,
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    ),
    _Step.ending => _buildEnding(),
  };

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Text(
                  "LET'S EXPLORE TOGETHER!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.card,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Choose a place you want to go.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sky,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    final rules = _content.travelogue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SvgPicture.asset(
                      'assets/images/girl_journal.svg',
                      height: 170,
                      semanticsLabel: 'Your guide, holding her journal',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SpeechBubble(
                          'Your entry must have ${rules.minSentences} to '
                          '${rules.maxSentences} sentences, with at least '
                          '${rules.minConjunctions} coordinating conjunctions '
                          'joining clauses.',
                          strong: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Travelogue Entry',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'INSTRUCTIONS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Write a travelogue entry describing your '
                          'travelling experience. Include where you went, the '
                          'activities you enjoyed, the sights you saw, how you '
                          'felt during the trip, and the lessons or memories '
                          'you took away.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: () => _go(_Step.travelogue),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnding() {
    return Stack(
      fit: StackFit.expand,
      children: [
        SvgPicture.asset(
          'assets/images/scenes/ending.svg',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          excludeFromSemantics: true,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 80,
                      semanticsLabel: 'BridgeIt logo',
                    ),
                    const SizedBox(height: 8),
                    const _LevelSigns(),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SvgPicture.asset(
                          'assets/images/girl_wave.svg',
                          width: 130,
                          semanticsLabel: 'Your guide, waving goodbye',
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SpeechBubble(
                                'Congratulations, Bridge Builder! We have '
                                'finally reached the end of our journey. I '
                                'hope you had a fantastic trip and learned a '
                                'lot along the way!',
                              ),
                              SpeechBubble(
                                'May this adventure inspire you to build '
                                'strong, coherent sentences using '
                                'coordinating conjunctions wherever your '
                                'writing takes you.',
                              ),
                              SpeechBubble(
                                'Thank you for traveling with me!',
                                strong: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(top: BorderSide(color: AppColors.ink, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SendAnswersButton(
                    label: 'Send my answers to my teacher',
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Back to levels'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Three small road signs, one per finished level.
class _LevelSigns extends StatelessWidget {
  const _LevelSigns();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level 1, Level 2 and Level 3 complete',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final level in [1, 2, 3])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightTeal,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEVEL $level',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.check, size: 14, color: AppColors.ink),
                      ],
                    ),
                  ),
                  Container(width: 3, height: 10, color: AppColors.ink),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.picture,
    required this.pictureLabel,
    required this.lines,
    required this.button,
    required this.onPressed,
    this.scene = false,
    this.footer,
  });

  final String picture;
  final String pictureLabel;
  final List<String> lines;
  final String button;
  final VoidCallback onPressed;

  /// [picture] is a full-screen windshield scene, not the guide.
  final bool scene;

  /// Drawn full width under the story, above the button.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (scene) {
      return Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            picture,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            semanticsLabel: pictureLabel,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in lines) SpeechBubble(line, strong: true),
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
              onPressed: onPressed,
              child: Text(button),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset(
                    picture,
                    height: 220,
                    semanticsLabel: pictureLabel,
                  ),
                  const SizedBox(height: 12),
                  for (final (i, line) in lines.indexed)
                    SpeechBubble(line, strong: i == lines.length - 1),
                ],
              ),
            ),
          ),
        ),
        ?footer,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(onPressed: onPressed, child: Text(button)),
        ),
      ],
    );
  }
}

/// Above the journal: the guide with her journal and what to write about.
class _JournalPrompt extends StatelessWidget {
  const _JournalPrompt({required this.place});

  final String? place;

  static const _topics = [
    'where you went',
    'what you did',
    'what you saw',
    'how you felt',
    "what you'll remember",
  ];

  @override
  Widget build(BuildContext context) {
    final place = this.place;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // A framed portrait: face and journal, cropped at the waist.
            Container(
              width: 84,
              height: 116,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ink, width: 3),
              ),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: 200,
                child: SvgPicture.asset(
                  'assets/images/girl_journal.svg',
                  height: 190,
                  semanticsLabel: 'Your guide, holding her journal',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SpeechBubble(
                place == null
                    ? "I'll write about our trip in my journal. I hope you "
                          'will too!'
                    : "I'll write about our trip to $place in my journal. I "
                          'hope you will too!',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Write about:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final topic in _topics)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.lightTeal, width: 2),
                ),
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
