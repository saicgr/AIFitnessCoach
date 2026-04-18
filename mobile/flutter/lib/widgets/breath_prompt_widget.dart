import 'dart:async';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Lightweight breath-pacing widget used as the mood workout "pre-start"
/// screen for Anxious / Stressed / Angry sessions.
///
/// [config] is the map produced by `MoodWorkoutWrapper._breathConfig`:
///   { pattern, label, inhale_s, hold1_s, exhale_s, hold2_s, duration_s }.
///
/// [onDone] fires when the timer completes OR the user taps Skip.
class BreathPromptWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final Color accentColor;
  final VoidCallback onDone;

  const BreathPromptWidget({
    super.key,
    required this.config,
    required this.accentColor,
    required this.onDone,
  });

  @override
  State<BreathPromptWidget> createState() => _BreathPromptWidgetState();
}

class _BreathPromptWidgetState extends State<BreathPromptWidget>
    with SingleTickerProviderStateMixin {
  late final int _inhale;
  late final int _hold1;
  late final int _exhale;
  late final int _hold2;
  late final AnimationController _controller;
  Timer? _phaseTimer;
  Timer? _countdownTimer;
  String _phaseLabel = 'Inhale';
  int _phaseSecondsLeft = 0;
  int _sessionSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _inhale = (widget.config['inhale_s'] as num?)?.toInt() ?? 4;
    _hold1 = (widget.config['hold1_s'] as num?)?.toInt() ?? 0;
    _exhale = (widget.config['exhale_s'] as num?)?.toInt() ?? 4;
    _hold2 = (widget.config['hold2_s'] as num?)?.toInt() ?? 0;
    final totalSec = (widget.config['duration_s'] as num?)?.toInt() ?? 30;
    _sessionSecondsLeft = totalSec;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhale + _hold1 + _exhale + _hold2),
    );

    _startCycle();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _sessionSecondsLeft = (_sessionSecondsLeft - 1).clamp(0, 999);
      });
      if (_sessionSecondsLeft == 0) _finish();
    });
  }

  void _startCycle() {
    _controller.reset();
    _runPhase('Inhale', _inhale, 0.0, 1.0, onDone: () {
      if (_hold1 > 0) {
        _runPhase('Hold', _hold1, 1.0, 1.0, onDone: _exhalePhase);
      } else {
        _exhalePhase();
      }
    });
  }

  void _exhalePhase() {
    _runPhase('Exhale', _exhale, 1.0, 0.0, onDone: () {
      if (_hold2 > 0) {
        _runPhase('Hold', _hold2, 0.0, 0.0, onDone: _startCycle);
      } else {
        _startCycle();
      }
    });
  }

  void _runPhase(String label, int seconds, double from, double to,
      {required VoidCallback onDone}) {
    if (!mounted) return;
    setState(() {
      _phaseLabel = label;
      _phaseSecondsLeft = seconds;
    });
    _controller.value = from;
    _controller.animateTo(to, duration: Duration(seconds: seconds));
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _phaseSecondsLeft = (_phaseSecondsLeft - 1).clamp(0, 99);
      });
      if (_phaseSecondsLeft == 0) {
        t.cancel();
        onDone();
      }
    });
  }

  void _finish() {
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.stop();
    widget.onDone();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final label = widget.config['label'] as String? ?? 'Breath';

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        final t = _controller.value; // 0..1
                        final diameter = 120 + 140 * t;
                        return Container(
                          width: diameter,
                          height: diameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor.withValues(alpha: 0.18),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 40 + 60 * t,
                                spreadRadius: 10 + 20 * t,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _phaseLabel,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    Text(
                      '$_phaseSecondsLeft',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Starts in ${_sessionSecondsLeft}s',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
