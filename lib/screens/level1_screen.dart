import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/lyric_sync.dart';
import '../progress/progress_store.dart';
import '../progress/results_store.dart';
import '../theme/app_theme.dart';
import '../widgets/level_app_bar.dart';
import '../widgets/level_clock.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/match_it_board.dart';
import '../widgets/song_player.dart';
import '../widgets/speech_bubble.dart';

/// How long the last lyric line lasts when there is no audio to time it.
const _lastLineMs = 6000;

enum _Step { intro, song, matchIntro, match, done }

/// Level 1: listen to the song, sing along, then match each conjunction to
/// its function.
class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen> {
  late final Level1Content _content;
  // A finished level can be replayed without the required plays.
  late final int _required;
  final _clock = LevelClock();
  _Step _step = _Step.intro;
  int _plays = 0;
  int _line = 0;
  bool _songEnded = false;

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level1;
    _required = context.read<ProgressStore>().isCompleted(1)
        ? 0
        : _content.playsRequired;
    // Plays from an earlier visit still count.
    _plays = context.read<ResultsStore>().level1Plays;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _go(_Step step) => setState(() {
    _step = step;
    _line = 0;
  });

  void _positionChanged(Duration position) {
    final line = activeLine(_content.lyrics, position.inMilliseconds);
    if (line != _line || _songEnded) {
      setState(() {
        _line = line;
        _songEnded = false;
      });
    }
  }

  Future<void> _finish(List<List<String>> attempts) async {
    final progress = context.read<ProgressStore>();
    await context.read<ResultsStore>().saveResult(1, {
      'plays': _plays,
      'attempts': attempts,
      'activeMs': _clock.elapsedMs,
    });
    await progress.markCompleted(1);
    if (mounted) await context.read<ResultsStore>().clearLevel1Plays();
    if (mounted) _go(_Step.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: levelAppBar(context, 1, 'Conjunction Theme Song'),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_step == _Step.song)
              SvgPicture.asset(
                'assets/images/scenes/drive.svg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                excludeFromSemantics: true,
              ),
            _buildStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    _Step.intro => _SongIntro(
      required: _content.playsRequired,
      onPlay: () => _go(_Step.song),
    ),
    _Step.song => _buildSong(),
    _Step.matchIntro => _MatchItIntro(
      onYes: () => _go(_Step.match),
      onListen: () => _go(_Step.song),
    ),
    _Step.match => Padding(
      padding: const EdgeInsets.all(16),
      child: MatchItBoard(pairs: _content.matchIt, onDone: _finish),
    ),
    _Step.done => const LevelDonePanel(level: 1),
  };

  Widget _buildSong() {
    final text = Theme.of(context).textTheme;
    final lyrics = _content.lyrics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'SING ALONG!',
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SongPlayer(
          assetPath: _content.audioAsset,
          silentLength: Duration(
            milliseconds: lyrics.last.startMs + _lastLineMs,
          ),
          onPosition: _positionChanged,
          autoPlay: true,
          onCompleted: () {
            setState(() {
              _plays++;
              _songEnded = true;
            });
            context.read<ResultsStore>().saveLevel1Plays(_plays);
          },
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.card,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (lyrics[_line].image case final image?) ...[
                  SvgPicture.asset(
                    image,
                    height: 96,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  lyrics[_line].text,
                  key: const ValueKey('lyric-now'),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final line in lyrics.skip(_line + 1).take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line.text,
                      style: text.titleSmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_required > 0)
                  Row(
                    children: [
                      Expanded(
                        child: _PlaysRoad(plays: _plays, required: _required),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_plays.clamp(0, _required)}/$_required',
                        key: const ValueKey('play-counter'),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                if (_songEnded && _plays < _required) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: const BoxDecoration(
                      color: AppColors.note,
                      border: Border(
                        left: BorderSide(color: AppColors.accent, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.replay, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The song has ended. Tap play to hear it again: '
                            '${_required - _plays} more to go.',
                            key: const ValueKey('song-ended'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            onPressed: _plays >= _required ? () => _go(_Step.matchIntro) : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}

/// A car that moves one numbered stop along a road with each full play.
class _PlaysRoad extends StatelessWidget {
  const _PlaysRoad({required this.plays, required this.required});

  final int plays;
  final int required;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.lightTeal,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          for (var stop = 1; stop <= required; stop++)
            Align(
              alignment: Alignment(stop / required * 2 - 1, 1),
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                child: Text(
                  '$stop',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: Alignment(
              plays.clamp(0, required) / required * 2 - 1,
              -1,
            ),
            child: SvgPicture.asset(
              'assets/images/car_small.svg',
              width: 40,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Before the song: the guide in her car and the three-plays rule.
class _SongIntro extends StatelessWidget {
  const _SongIntro({required this.required, required this.onPlay});

  final int required;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 236,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SvgPicture.asset(
                          'assets/images/scenes/road_strip.svg',
                          fit: BoxFit.fill,
                          height: 70,
                          excludeFromSemantics: true,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 18,
                        child: SvgPicture.asset(
                          'assets/images/girl_drive.svg',
                          width: 200,
                          semanticsLabel: 'Your guide, driving her car',
                        ),
                      ),
                      const Positioned(
                        left: 196,
                        right: 16,
                        top: 44,
                        child: SpeechBubble(
                          "Let's turn on some music, shall we?",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Listen to the '),
                            TextSpan(
                              text: 'CONJUNCTION THEME SONG',
                              style: TextStyle(color: AppColors.lightTeal),
                            ),
                            TextSpan(
                              text:
                                  ' three times before you can answer the '
                                  'following activity.',
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: AppColors.card,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PlaysRoad(plays: 0, required: required),
                      const SizedBox(height: 8),
                      Text(
                        'The car moves one stop each time the song ends. Next '
                        'unlocks at $required.',
                        style: const TextStyle(
                          color: AppColors.sky,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('PLAY THE SONG'),
            onPressed: onPlay,
          ),
        ),
      ],
    );
  }
}

class _MatchItIntro extends StatelessWidget {
  const _MatchItIntro({required this.onYes, required this.onListen});

  final VoidCallback onYes;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
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
                      'assets/images/girl_wave.svg',
                      height: 170,
                      semanticsLabel: 'Your guide, waving',
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: SpeechBubble(
                          "Now that you know the song, let's see if you "
                          'learned something from it.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MatchIt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'INSTRUCTIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Drag the right function to its corresponding '
                        'coordinating conjunction, or tap the function and '
                        'then its slot.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 12),
                      _MatchExample(),
                      SizedBox(height: 12),
                      Text(
                        'Are you ready?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: onYes, child: const Text('Yes!')),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.replay),
                onPressed: onListen,
                label: const Text('No. Let me listen to the song again.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The drag shown in the instructions: a function moves into a slot.
class _MatchExample extends StatelessWidget {
  const _MatchExample();

  @override
  Widget build(BuildContext context) {
    Widget box(String text, {bool slot = false, bool conj = false}) =>
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: conj ? AppColors.ink : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: slot
                  ? AppColors.lightTeal
                  : (conj ? AppColors.ink : AppColors.piece),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: conj ? AppColors.card : AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    return Semantics(
      label: "Example: the function 'to add' moves into the slot next to 'and'",
      excludeSemantics: true,
      // Scales down on narrow phones instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box('to add'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: AppColors.ink),
            ),
            box('and', conj: true),
            const SizedBox(width: 6),
            box('to add', slot: true),
          ],
        ),
      ),
    );
  }
}
