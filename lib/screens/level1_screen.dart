import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/models.dart';
import '../game/blanks_round.dart';
import '../progress/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/hint_card.dart';
import '../widgets/level_done_panel.dart';
import '../widgets/song_player.dart';

/// Level 1: listen to the song, then type the FANBOYS words into its lyrics.
class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen> {
  late final Level1Content _content;
  late final BlanksRound _round;
  final _fields = <int, TextEditingController>{};
  final _focus = <int, FocusNode>{};
  int _verse = 0;
  // The blank that just got a wrong word; drives the red outline and the hint.
  int? _wrongBlank;
  // The instruction shows until the student first types.
  bool _attempted = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _content = context.read<GameContent>().level1;
    _round = BlanksRound(_content.verses);
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Judges a blank as soon as its text is a whole FANBOYS word; part of a
  /// word gets no verdict yet (no FANBOYS word is a prefix of another).
  void _typed(int blank, String text) {
    final word = text.trim().toLowerCase();
    setState(() {
      _attempted = true;
      if (!fanboys.contains(word)) {
        if (_wrongBlank == blank) _wrongBlank = null;
        return;
      }
      switch (_round.place(blank, word)) {
        case BlankResult.correct:
          _wrongBlank = null;
          _focusNextBlank(blank);
        case BlankResult.wrong:
          _wrongBlank = blank;
        case BlankResult.alreadyFilled:
          break;
      }
    });
  }

  /// Pressing Enter on something that isn't a FANBOYS word counts as wrong.
  void _submitted(int blank, String text) {
    final word = text.trim().toLowerCase();
    if (word.isEmpty || fanboys.contains(word)) return;
    setState(() => _wrongBlank = blank);
  }

  /// Moves to the next empty blank of this verse, or closes the keyboard so
  /// the "Next verse" / "Finish" button is visible.
  void _focusNextBlank(int blank) {
    final end = _round.verseStart(_verse) + _verseBlankCount(_verse);
    for (var b = blank + 1; b < end; b++) {
      if (_round.filledAt(b) == null) {
        _focus[b]?.requestFocus();
        return;
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  int _verseBlankCount(int verse) => _content.verses[verse].lines
      .expand((line) => line)
      .whereType<BlankPart>()
      .length;

  Future<void> _next() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_verse < _content.verses.length - 1) {
      setState(() {
        _verse++;
        _wrongBlank = null;
      });
      return;
    }
    await context.read<ProgressStore>().markCompleted(1);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = _content.verses[_verse].title;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _done
            ? const LevelDonePanel(level: 1)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    // Same verse number as the card title below it.
                    'LEVEL 1 · ${title.split(':').first.trim().toUpperCase()}',
                    style: text.labelLarge,
                  ),
                  Text(
                    'Conjunction song',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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
        if (_wrongBlank != null)
          const HintCard(text: 'Not quite. Try again!', correct: false)
        else if (!_attempted)
          const HintCard.prompt(text: 'Type the missing word in each blank.'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verses[_verse].title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
        FilledButton(
          onPressed: _round.isVerseComplete(_verse) ? _next : null,
          child: Text(last ? 'Finish' : 'Next verse'),
        ),
      ],
    );
  }

  InlineSpan _blankSpan(int blank) {
    final filled = _round.filledAt(blank);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: filled != null
            ? _FilledBlank(key: ValueKey('blank-$blank'), word: filled)
            : _blankField(blank),
      ),
    );
  }

  Widget _blankField(int blank) {
    final wrong = _wrongBlank == blank;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
    return SizedBox(
      width: 88,
      height: 48,
      child: TextField(
        key: ValueKey('blank-$blank'),
        controller: _fields.putIfAbsent(blank, TextEditingController.new),
        focusNode: _focus.putIfAbsent(blank, FocusNode.new),
        onChanged: (text) => _typed(blank, text),
        onSubmitted: (text) => _submitted(blank, text),
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.sky,
          hintText: '?',
          semanticCounterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: border(wrong ? AppColors.wrong : AppColors.primary),
          focusedBorder: border(wrong ? AppColors.wrong : AppColors.accent),
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

/// A correctly filled blank: the word in green with a check. It is final.
class _FilledBlank extends StatelessWidget {
  const _FilledBlank({super.key, required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.correct.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.correct, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, size: 20, color: AppColors.cliff),
          const SizedBox(width: 4),
          Text(
            word,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
