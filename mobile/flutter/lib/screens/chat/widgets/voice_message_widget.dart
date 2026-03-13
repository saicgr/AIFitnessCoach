import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/theme/theme_colors.dart';

// ---------------------------------------------------------------------------
// VoiceRecorderButton
// ---------------------------------------------------------------------------

/// A mic button that starts recording on long-press and stops on release.
class VoiceRecorderButton extends StatefulWidget {
  final void Function(File audioFile, int durationMs)? onRecordingComplete;

  const VoiceRecorderButton({super.key, this.onRecordingComplete});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStart;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingStart = DateTime.now();
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    final path = await _recorder.stop();
    final durationMs = _recordingStart != null
        ? DateTime.now().difference(_recordingStart!).inMilliseconds
        : 0;

    setState(() {
      _isRecording = false;
      _recordingStart = null;
      _elapsedSeconds = 0;
    });

    if (path != null && widget.onRecordingComplete != null) {
      widget.onRecordingComplete!(File(path), durationMs);
    }
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isRecording ? AppColors.red.withValues(alpha: 0.15) : colors.glassSurface,
          shape: BoxShape.circle,
        ),
        child: _isRecording
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatSeconds(_elapsedSeconds),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Icon(Icons.mic, color: colors.textSecondary, size: 22),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VoiceMessageBubble
// ---------------------------------------------------------------------------

/// Displays a voice message with play/pause and a progress bar.
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationMs;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationMs,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: widget.durationMs);

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
      if (state == PlayerState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) {
        setState(() => _duration = d);
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: colors.accent,
            size: 32,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: colors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isPlaying
                    ? _formatDuration(_position)
                    : _formatDuration(_duration),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
