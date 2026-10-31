import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';

/// Plays the Level 1 song. Without an asset, or if it cannot be loaded, it
/// plays silently for [silentLength], so the level stays playable.
/// [assetPath] is fixed for the widget's life.
class SongPlayer extends StatefulWidget {
  const SongPlayer({
    super.key,
    this.assetPath,
    required this.silentLength,
    this.onPosition,
    this.onCompleted,
  });

  final String? assetPath;
  final Duration silentLength;

  /// Called as playback moves; drives the lyric card.
  final ValueChanged<Duration>? onPosition;

  /// Called each time the song plays through to its end.
  final VoidCallback? onCompleted;

  @override
  State<SongPlayer> createState() => _SongPlayerState();
}

class _SongPlayerState extends State<SongPlayer> with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 100);

  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _silentTimer;
  bool _loading = false;
  bool _playing = false;
  bool _ended = false;
  Duration _position = Duration.zero;

  Duration get _length => _player?.duration ?? widget.silentLength;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final path = widget.assetPath;
    if (path != null) {
      _loading = true;
      _load(path);
    }
  }

  Future<void> _load(String path) async {
    final player = AudioPlayer();
    _player = player;
    try {
      await player.setAsset(path);
      _subscriptions
        ..add(player.positionStream.listen(_moved))
        ..add(player.playerStateStream.listen(_stateChanged));
    } catch (_) {
      // Missing or unplayable asset: fall back to silent playback.
      _player = null;
      unawaited(player.dispose());
    }
    if (mounted) setState(() => _loading = false);
  }

  void _moved(Duration position) {
    if (!mounted) return;
    setState(() => _position = position);
    widget.onPosition?.call(position);
  }

  void _stateChanged(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _finish();
    } else if (mounted && !_ended) {
      setState(() => _playing = state.playing);
    }
  }

  void _finish() {
    _silentTimer?.cancel();
    if (_ended || !mounted) return;
    _ended = true;
    _moved(_length);
    setState(() => _playing = false);
    widget.onCompleted?.call();
  }

  void _play() {
    if (_ended) {
      _ended = false;
      _moved(Duration.zero);
      _player?.seek(Duration.zero);
    }
    setState(() => _playing = true);
    final player = _player;
    if (player != null) {
      // Not awaited: play() only completes when playback stops.
      player.play();
      return;
    }
    _silentTimer = Timer.periodic(_tick, (_) {
      final next = _position + _tick;
      if (next >= _length) {
        _finish();
      } else {
        _moved(next);
      }
    });
  }

  void _pause() {
    _silentTimer?.cancel();
    _player?.pause();
    setState(() => _playing = false);
  }

  // The song must not keep playing once the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _playing) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _silentTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = _length.inMilliseconds;
    return Card(
      color: AppColors.lightTeal,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton.filled(
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.card,
              ),
              tooltip: _playing ? 'Pause' : 'Play',
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              onPressed: _loading ? null : (_playing ? _pause : _play),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _player == null
                        ? 'BridgeIt Song (no sound yet)'
                        : 'BridgeIt Song',
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: total == 0
                        ? 0
                        : (_position.inMilliseconds / total).clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_clock(_position), style: text.labelSmall),
                      Text(_clock(_length), style: text.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
