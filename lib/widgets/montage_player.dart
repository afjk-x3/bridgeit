import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

const _pictureTime = Duration(seconds: 4);
const _zoom = 0.12;

/// Plays a place's pictures with a slow zoom, a fade and captions, looping
/// over background music. [onDone] is offered once after one full pass.
class MontagePlayer extends StatefulWidget {
  const MontagePlayer({
    super.key,
    required this.place,
    required this.musicAsset,
    required this.onDone,
  });

  final Place place;
  final String musicAsset;
  final VoidCallback onDone;

  @override
  State<MontagePlayer> createState() => _MontagePlayerState();
}

class _MontagePlayerState extends State<MontagePlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  AudioPlayer? _music;
  int _index = 0;
  bool _passed = false;

  List<PlacePicture> get _pictures => widget.place.pictures;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(vsync: this, duration: _pictureTime)
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
    setState(() {
      _index = (_index + 1) % _pictures.length;
      if (_index == 0) _passed = true;
    });
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
                Text(
                  picture.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.card, fontSize: 16),
                ),
                if (_passed) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: widget.onDone,
                    child: const Text('Next'),
                  ),
                ],
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
