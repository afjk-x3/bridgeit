import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

const _pictureTime = Duration(seconds: 4);
const _zoom = 0.12;

/// Plays a place's pictures with a slow zoom, a fade and captions, looping
/// over background music. [onMap] goes back to the map until one full pass
/// has played; then [onPassed] is called, the Map button goes and [onDone]
/// is offered, since the student must write about this place.
class MontagePlayer extends StatefulWidget {
  const MontagePlayer({
    super.key,
    required this.place,
    required this.musicAsset,
    required this.onDone,
    required this.onMap,
    this.onPassed,
    this.passed = false,
  });

  final Place place;
  final String musicAsset;
  final VoidCallback onDone;
  final VoidCallback onMap;
  final VoidCallback? onPassed;

  /// A pass already played earlier, so Next shows from the start.
  final bool passed;

  @override
  State<MontagePlayer> createState() => _MontagePlayerState();
}

class _MontagePlayerState extends State<MontagePlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  AudioPlayer? _music;
  int _index = 0;
  late bool _passed = widget.passed;

  List<PlacePicture> get _pictures => widget.place.pictures;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // preserve: reduce motion must not make each picture flash past.
    _clock =
        AnimationController(
            vsync: this,
            duration: _pictureTime,
            animationBehavior: AnimationBehavior.preserve,
          )
          ..addStatusListener(_pictureEnded)
          ..forward();
    _playMusic();
  }

  Future<void> _playMusic() async {
    try {
      final player = AudioPlayer();
      _music = player;
      await player.setAsset(widget.musicAsset);
      await player.setLoopMode(LoopMode.all);
      if (mounted) player.play();
    } catch (_) {
      // Missing or unplayable track: the montage runs without music.
    }
  }

  void _pictureEnded(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final firstPass = !_passed && _index == _pictures.length - 1;
    setState(() {
      _index = (_index + 1) % _pictures.length;
      if (_index == 0) _passed = true;
    });
    if (firstPass) widget.onPassed?.call();
    _clock.forward(from: 0);
  }

  // The music must not keep playing once the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _music?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _music?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    _music?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picture = _pictures[_index];
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.primary),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _Picture(
            key: ValueKey(_index),
            asset: picture.asset,
            clock: _clock,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  label: 'Photo ${_index + 1} of ${_pictures.length}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pictures.length; i++)
                        Container(
                          width: i == _index ? 24 : 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.card
                                : AppColors.lightTeal,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  picture.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.card, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!_passed)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onMap,
                          child: const Text('Map'),
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lightTeal,
                            foregroundColor: AppColors.ink,
                          ),
                          onPressed: widget.onDone,
                          child: const Text('Next'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({super.key, required this.asset, required this.clock});

  final String asset;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1 + _zoom).animate(clock),
      child: Image.asset(
        asset,
        // Whole photo: most are landscape, and a phone is tall.
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: AppColors.lightTeal,
          child: Center(
            child: Icon(Icons.landscape, size: 96, color: AppColors.teal),
          ),
        ),
      ),
    );
  }
}
