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
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/exercise.dart';

import '../../../../l10n/generated/app_localizations.dart';
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

    // Draining-bar fraction (`.ir-strip`'s bar). 1.0 at start → 0.0 at zero.
    final double frac = widget.initialSeconds <= 0
        ? 0.0
        : (_remaining / widget.initialSeconds).clamp(0.0, 1.0);

    // The overlay still sits over a dimmed scrim (pushed opaque:false), but
    // the composition now mirrors the signature-v2 rest treatment: a Barlow
    // "REST" kicker, the big Anton countdown numeral, a draining accent bar,
    // the next-set ledger row (`.rw-led` idiom), and a rounded "Skip" pill
    // (`.ctl sk`). Wiring is unchanged — same remaining stream, onSkip, onDone.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // REST kicker — Barlow Condensed uppercase (`.rl`).
              Text(
                AppLocalizations.of(context).workoutSummaryAdvancedRest.toUpperCase(),
                style: ZType.lbl(
                  14,
                  color: Colors.white.withValues(alpha: 0.62),
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 14),
              // The big Anton countdown numeral — the poster of the rest view.
              Text(
                _remaining.toString(),
                style: ZType.disp(96, color: Colors.white, letterSpacing: 0),
              ),
              const SizedBox(height: 18),
              // Draining accent bar — the `.ir-strip` progress, recolours with
              // the user's accent.
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Next-set ledger row (`.rw-led`): the upcoming exercise + its
              // target, the "what's coming" line that stays visible during rest.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.nextExercise.name.toUpperCase(),
                      style: ZType.lbl(13,
                          color: Colors.white, letterSpacing: 1.0),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'SET ${widget.nextSetNumber} OF ${widget.totalSets}'
                '  ·  '
                '${_fmtWeight(widget.nextTargetWeightKg)} $unit × ${widget.nextTargetReps}',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Skip pill — the single rest affordance, styled as a rounded
              // `.ctl sk` chip (the v2 rest controls' Skip).
              OutlinedButton(
                onPressed: () async {
                  await HapticService.instance.tap();
                  widget.onSkip();
                },
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.26)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                ),
                child: Text(
                  AppLocalizations.of(context).easyRestOverlaySkipRest.toUpperCase(),
                  style: ZType.lbl(
                    13,
                    color: Colors.white.withValues(alpha: 0.88),
                    weight: FontWeight.w700,
                    letterSpacing: 2.0,
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
