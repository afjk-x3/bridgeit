import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/lyric_sync.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/journey_sheet.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/match_it_board.dart';
import '../widgets/song_player.dart';

/// How long the last lyric line lasts when there is no audio to time it.
const _lastLineMs = 6000;

enum _Step { intro, song, ready, matchIntro, match, done }

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
  _Step _step = _Step.intro;
  int _plays = 0;
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level1;
    _required = context.read<ProgressStore>().isCompleted(1)
        ? 0
        : _content.playsRequired;
  }

  void _go(_Step step) => setState(() {
    _step = step;
    _line = 0;
  });

  void _positionChanged(Duration position) {
    final line = activeLine(_content.lyrics, position.inMilliseconds);
    if (line != _line) setState(() => _line = line);
  }

  Future<void> _finish() async {
    await context.read<ProgressStore>().markCompleted(1);
    if (mounted) _go(_Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LEVEL 1', style: text.labelLarge),
            Text(
              'Conjunction Theme Song',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [JourneyButton()],
      ),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() => switch (_step) {
    _Step.intro => _StoryCard(
      text:
          "Let's turn on some music, shall we?\n\nListen to the "
          "'CONJUNCTION THEME SONG' three times before you can answer the "
          'following activity.',
      button: 'PLAY THE SONG',
      onPressed: () => _go(_Step.song),
    ),
    _Step.song => _buildSong(),
    _Step.ready => _StoryCard(
      text:
          "Now that you know the song, let's see if you learned something "
          'from it.',
      button: 'NEXT',
      onPressed: () => _go(_Step.matchIntro),
    ),
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
          onCompleted: () => setState(() => _plays++),
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
                  Text(
                    '${_plays.clamp(0, _required)}/$_required',
                    key: const ValueKey('play-counter'),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _plays >= _required ? () => _go(_Step.ready) : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.text,
    required this.button,
    required this.onPressed,
  });

  final String text;
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
            Card(
              color: AppColors.primary,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.card),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(button)),
          ],
        ),
      ),
    );
  }
}

class _MatchItIntro extends StatelessWidget {
  const _MatchItIntro({required this.onYes, required this.onListen});

  final VoidCallback onYes;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tealButton = FilledButton.styleFrom(
      backgroundColor: AppColors.lightTeal,
      foregroundColor: AppColors.ink,
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MatchIt',
              textAlign: TextAlign.center,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Instructions:\nDrag the right function to its corresponding '
              'coordinating conjunction, or tap the function and then its '
              'slot.\n\nAre you ready?',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: tealButton,
              onPressed: onYes,
              child: const Text('Yes!'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: tealButton,
              onPressed: onListen,
              child: const Text('No. Let me listen to the song again.'),
            ),
          ],
        ),
      ),
    );
  }
}
