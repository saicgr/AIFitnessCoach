/// Lightweight mindfulness session player — a guided breathing timer that
/// records a real `mindfulness_sessions` row on completion so the home ring
/// and the metrics "Mindfulness minutes" card reflect actual practice (not the
/// old hardcoded 0).
///
/// Two modes, chosen by the route params:
///   • meditation — seeded from a daily meditation pick (slug + duration +
///     optional audio_url). Plays audio if present, else a silent guided timer.
///   • breathwork — box-breathing preset (4-4-4-4) when no pick is supplied.
///
/// Logging rules (plan edge case B5/B6): a session logs ONLY on natural
/// completion OR an explicit "End early" past a 60s floor, and logs the ACTUAL
/// elapsed seconds (never the target). Backgrounding pauses; force-quit logs
/// nothing. The complete-button is guarded so a double tap / retry can't
/// double-log.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/providers/mindfulness_provider.dart';
import '../../data/services/mindfulness_service.dart';
import '../../data/services/haptic_service.dart';

/// Minimum elapsed seconds before an early exit counts as a logged session.
const int _kMinLoggableSeconds = 60;

class MindfulnessSessionScreen extends ConsumerStatefulWidget {
  /// 'meditation' | 'breathwork'.
  final String source;

  /// Meditation slug (null for breathwork).
  final String? slug;

  /// Display title.
  final String title;

  /// Target duration in minutes.
  final int durationMinutes;

  /// Optional audio URL (guided meditation). Empty/null → silent timer.
  final String? audioUrl;

  const MindfulnessSessionScreen({
    super.key,
    required this.source,
    this.slug,
    required this.title,
    required this.durationMinutes,
    this.audioUrl,
  });

  @override
  ConsumerState<MindfulnessSessionScreen> createState() =>
      _MindfulnessSessionScreenState();
}

class _MindfulnessSessionScreenState
    extends ConsumerState<MindfulnessSessionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  bool _running = false;
  bool _completed = false;
  bool _logging = false; // guards against double-log (edge case B6)

  AudioPlayer? _player;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = (widget.durationMinutes.clamp(1, 60)) * 60;
    _remaining = _totalSeconds;
    // Box-breathing-ish 8s cycle (4s inhale / 4s exhale) drives the ring pulse.
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  int get _elapsed => _totalSeconds - _remaining;

  bool get _canLogEarly => _elapsed >= _kMinLoggableSeconds;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _breath.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when backgrounded; do NOT auto-resume (user re-taps play). A
    // force-quit therefore logs nothing — no partial row (edge case B5).
    if (state != AppLifecycleState.resumed && _running) {
      _pause();
    }
  }

  Future<void> _start() async {
    if (_completed) return;
    setState(() => _running = true);
    _breath.repeat(reverse: true);
    HapticService.light();

    final url = widget.audioUrl;
    if (url != null && url.isNotEmpty && _player == null) {
      try {
        _player = AudioPlayer();
        // Don't let the timer / silence be interrupted by other app audio.
        await _player!.play(UrlSource(url));
      } catch (_) {
        // Audio is optional — fall back to a silent guided timer.
        _player = null;
      }
    } else {
      await _player?.resume();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _onComplete();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    _breath.stop();
    _player?.pause();
    if (mounted) setState(() => _running = false);
  }

  Future<void> _onComplete() async {
    _timer?.cancel();
    _timer = null;
    _breath.stop();
    await _player?.stop();
    if (mounted) {
      setState(() {
        _remaining = 0;
        _running = false;
        _completed = true;
      });
    }
    HapticService.success();
    await _logAndExit(_totalSeconds, completed: true);
  }

  /// Early exit. Logs only if past the 60s floor; otherwise just leaves.
  Future<void> _endEarly() async {
    _pause();
    if (_canLogEarly) {
      await _logAndExit(_elapsed, completed: false);
    } else if (mounted) {
      context.pop();
    }
  }

  Future<void> _logAndExit(int seconds, {required bool completed}) async {
    if (_logging) return;
    _logging = true;
    MindfulnessToday? result;
    try {
      result = await logMindfulnessSession(
        ref,
        source: widget.source,
        meditationSlug: widget.slug,
        durationSeconds: seconds,
      );
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    final minutes = (seconds / 60).round();
    final c = ThemeColors.of(context);
    if (result == null) {
      // No silent success — tell the user it didn't save (edge case B8).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't save this session. Please try again."),
          backgroundColor: c.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(completed
              ? 'Nice work — $minutes min logged.'
              : '$minutes min logged.'),
          backgroundColor: c.accent,
        ),
      );
    }
    context.pop();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final progress =
        _totalSeconds > 0 ? (_elapsed / _totalSeconds).clamp(0.0, 1.0) : 0.0;
    final isBreathwork = widget.source == 'breathwork';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.textPrimary),
          onPressed: () {
            // Closing via X before the floor discards; past the floor it logs.
            if (_running || _elapsed > 0) {
              _endEarly();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isBreathwork
                    ? 'Breathe in… and out. Follow the circle.'
                    : '${widget.durationMinutes} min · guided',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
              const SizedBox(height: 40),
              // Breathing ring — pulses while running, shows time + progress.
              AnimatedBuilder(
                animation: _breath,
                builder: (context, _) {
                  final scale = _running ? 0.88 + (_breath.value * 0.18) : 1.0;
                  return SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.accent.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: c.cardBorder,
                            valueColor: AlwaysStoppedAnimation(c.accent),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fmt(_remaining),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              _completed ? 'Done' : 'remaining',
                              style: TextStyle(
                                  fontSize: 12, color: c.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              if (!_completed) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _running ? _pause : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _running
                          ? 'Pause'
                          : (_elapsed > 0 ? 'Resume' : 'Begin'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _elapsed > 0 ? _endEarly : () => context.pop(),
                  child: Text(
                    _canLogEarly ? 'End & log' : 'End',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
