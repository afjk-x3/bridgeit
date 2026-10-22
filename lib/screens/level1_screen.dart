import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/blanks_round.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/song_player.dart';

/// Level 1: listen to the song, then fill the FANBOYS words into its lyrics.
class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen> {
  late final Level1Content _content;
  late final BlanksRound _round;
  int _verse = 0;
  String? _selected;
  // The blank that just got a wrong word; drives the red flash and the hint.
  int? _wrongBlank;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level1;
    _round = BlanksRound(_content.verses);
  }

  void _selectWord(String word) => setState(() {
    _selected = word;
    _wrongBlank = null;
  });

  void _tapBlank(int blank) {
    final word = _selected;
    if (word == null) return;
    setState(() {
      switch (_round.place(blank, word)) {
        case BlankResult.correct:
          _selected = null;
          _wrongBlank = null;
        case BlankResult.wrong:
          _wrongBlank = blank;
        case BlankResult.alreadyFilled:
          break;
      }
    });
  }

  Future<void> _next() async {
    if (_verse < _content.verses.length - 1) {
      setState(() {
        _verse++;
        _selected = null;
        _wrongBlank = null;
      });
      return;
    }
    await context.read<ProgressStore>().markCompleted(1);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level 1')),
      body: SafeArea(
        child: _done
            ? const LevelDonePanel(level: 1)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _StepTitle('1 · Listen'),
                  SongPlayer(assetPath: _content.audioAsset),
                  const SizedBox(height: 24),
                  const _StepTitle('2 · Fill in the blanks'),
                  _buildVerse(context),
                ],
              ),
      ),
    );
  }

  Widget _buildVerse(BuildContext context) {
    final verses = _content.verses;
    final last = _verse == verses.length - 1;
    var blank = _round.verseStart(_verse);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verse ${_verse + 1} of ${verses.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.card,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in verses[_verse].lines)
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final part in line)
                          switch (part) {
                            TextPart(:final text) => TextSpan(text: text),
                            BlankPart() => _blankSpan(blank++),
                          },
                      ],
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(height: 1.6),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in fanboys)
              _Tile(
                key: ValueKey('word-$word'),
                label: word,
                fill: _selected == word ? AppColors.primary : AppColors.card,
                textColor: _selected == word ? AppColors.card : AppColors.ink,
                border: AppColors.primary,
                onTap: () => _selectWord(word),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wrongBlank != null)
          Semantics(
            liveRegion: true,
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.bridge),
                SizedBox(width: 8),
                Text('Not quite. Try again!'),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _round.isVerseComplete(_verse) ? _next : null,
          child: Text(last ? 'Finish' : 'Next verse'),
        ),
      ],
    );
  }

  InlineSpan _blankSpan(int blank) {
    final filled = _round.filledAt(blank);
    final wrong = _wrongBlank == blank;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _Tile(
          key: ValueKey('blank-$blank'),
          label: filled,
          semanticLabel: 'Empty blank',
          icon: filled == null ? null : Icons.check,
          fill: filled == null
              ? AppColors.sky
              : AppColors.correct.withValues(alpha: 0.25),
          textColor: AppColors.ink,
          border: filled != null
              ? AppColors.correct
              : wrong
              ? AppColors.wrong
              : AppColors.primary,
          // A filled blank is final; ignoring taps is the rules' alreadyFilled.
          onTap: () => _tapBlank(blank),
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

/// A tappable 48dp+ box: a bank word, or a lyric blank (empty or filled).
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.fill,
    required this.textColor,
    required this.border,
    required this.onTap,
    this.icon,
    this.semanticLabel,
  });

  final String? label;
  final String? semanticLabel;
  final IconData? icon;
  final Color fill;
  final Color textColor;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return Semantics(
      button: true,
      label: label == null ? semanticLabel : null,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.cliff),
                    const SizedBox(width: 4),
                  ],
                  if (label != null)
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
