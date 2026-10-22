import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';

/// Plays the Level 1 song. Without an asset, or if it cannot be loaded, shows
/// "Song coming soon" and no controls. [assetPath] is fixed for the widget's
/// life; no AudioPlayer is created when it is null.
class SongPlayer extends StatefulWidget {
  const SongPlayer({super.key, this.assetPath});

  final String? assetPath;

  @override
  State<SongPlayer> createState() => _SongPlayerState();
}

class _SongPlayerState extends State<SongPlayer> with WidgetsBindingObserver {
  AudioPlayer? _player;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final path = widget.assetPath;
    if (path != null) _load(path);
  }

  Future<void> _load(String path) async {
    try {
      final player = AudioPlayer();
      _player = player;
      await player.setAsset(path);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Missing or unplayable asset: stay in the "Song coming soon" state.
    }
  }

  // The song must not keep playing once the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _player?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle(PlayerState state) async {
    final player = _player!;
    if (state.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
      await player.play();
    } else if (state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: !_ready || player == null
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Song coming soon'),
                  ],
                ),
              )
            : StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data ?? player.playerState;
                  final playing =
                      state.playing &&
                      state.processingState != ProcessingState.completed;
                  return Row(
                    children: [
                      IconButton(
                        iconSize: 32,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        color: AppColors.primary,
                        tooltip: playing ? 'Pause' : 'Play',
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () => _toggle(state),
                      ),
                      Expanded(child: _Progress(player: player)),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final total = player.duration?.inMilliseconds ?? 0;
        final position = (snapshot.data ?? Duration.zero).inMilliseconds;
        return LinearProgressIndicator(
          value: total == 0 ? 0 : (position / total).clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: AppColors.primary,
          backgroundColor: AppColors.sky,
        );
      },
    );
  }
}
