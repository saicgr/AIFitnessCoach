// Easy tier — FULL-SCREEN rest countdown.
//
// Unlike Simple's inline rest bar, Easy hides the whole workout surface
// behind a calm full-screen overlay during rest. The only affordance
// is a big countdown number + a single "Skip rest" text button. On
// countdown zero the screen auto-dismisses (caller pops and advances).
//
// Pushed via `Navigator.of(context).push(PageRouteBuilder(...))` with
// a transparent opaque=false route so the underlying Easy screen stays
// alive in the tree (controllers, timers, provider subscriptions).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/exercise.dart';

/// Full-screen rest countdown overlay.
///
/// Wire-up (call-site):
///   Navigator.of(context).push(
///     PageRouteBuilder(
///       opaque: false,
///       barrierColor: Colors.black.withValues(alpha: 0.92),
///       pageBuilder: (_, __, ___) => EasyRestOverlay(...),
///     ),
///   );
class EasyRestOverlay extends ConsumerStatefulWidget {
  final int initialSeconds;

  /// Stream of remaining seconds from the parent's WorkoutTimerController.
  /// The overlay listens and pops automatically when this hits 0.
  final Stream<int> remainingStream;

  final WorkoutExercise nextExercise;
  final int nextSetNumber;
  final int totalSets;
  final double nextTargetWeightKg; // already in kg; display converts if needed
  final int nextTargetReps;
  final bool useKg;

  final VoidCallback onSkip;
  final VoidCallback onDone;

  const EasyRestOverlay({
    super.key,
    required this.initialSeconds,
    required this.remainingStream,
    required this.nextExercise,
    required this.nextSetNumber,
    required this.totalSets,
    required this.nextTargetWeightKg,
    required this.nextTargetReps,
    required this.useKg,
    required this.onSkip,
    required this.onDone,
  });

  @override
  ConsumerState<EasyRestOverlay> createState() => _EasyRestOverlayState();
}

class _EasyRestOverlayState extends ConsumerState<EasyRestOverlay> {
  late int _remaining;
  late final Stream<int> _stream;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _stream = widget.remainingStream;
    _stream.listen((s) {
      if (!mounted) return;
      setState(() => _remaining = s);
      if (s <= 0) {
        widget.onDone();
      }
    });
  }

  String _fmtWeight(double kg) {
    final v = widget.useKg ? kg : kg * 2.20462;
    if (v <= 0) return '—';
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final unit = widget.useKg ? 'kg' : 'lb';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _remaining.toString(),
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'seconds',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(height: 36),
              Icon(
                Icons.fitness_center_rounded,
                size: 24,
                color: accent,
              ),
              const SizedBox(height: 10),
              Text(
                widget.nextExercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Set ${widget.nextSetNumber} of ${widget.totalSets}'
                '  ·  '
                '${_fmtWeight(widget.nextTargetWeightKg)} $unit × ${widget.nextTargetReps}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 36),
              TextButton(
                onPressed: () async {
                  await HapticService.instance.tap();
                  widget.onSkip();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Skip rest',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.84),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
