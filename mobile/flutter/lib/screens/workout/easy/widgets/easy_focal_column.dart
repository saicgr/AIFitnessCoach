// Easy tier — focal card interior.
//
// Signature-v2 poster composition (sec-workout · EASY frame):
//   • Anton "poster" target — the huge `60 LB × 8` masthead numeral
//     (`.rw-poster`), the single dominant element of the screen.
//   • Fraunces "whisper" — the italic human encouragement line
//     (`.rw-whisper`), sourced from target-vs-current delta.
//   • Weight + Reps steppers (the editable controls feeding the poster).
//   • Rounded accent CTA pill (`.rw-cta`) — uppercase Barlow, the only
//     primary action.
// The poster+steppers are centered in the residual height so the focal card
// breathes up on iPhone Pro Max and compacts down on iPhone SE. When the
// residual budget is genuinely too small (SE with every insight card present)
// it scrolls a few px as a last-resort safety net instead of overflowing —
// the LOG button below stays pinned and fully visible.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../shared/focal_stepper.dart';
import '../../widgets/timed_exercise_timer.dart';
import '../easy_active_workout_state_models.dart';

import '../../../../l10n/generated/app_localizations.dart';

class EasyFocalColumn extends StatelessWidget {
  final EasyExerciseState state;
  /// Current exercise name — used to key the timed-move countdown so it resets
  /// when the exercise changes.
  final String exerciseName;
  final bool useKg;
  final double weightStep;
  final Color accent;
  final bool compact;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onRepsChanged;
  final ValueChanged<double> onDurationChanged;
  final Future<void> Function() onLogSet;

  /// When non-null, the user is editing a previously-logged set. The Log
  /// button re-captions to "Update set N" so the action is obvious.
  final int? editingSetIndex;

  /// "Next: [name] · [detail]" preview line shown just above LOG SET (per the
  /// approved mockup). Null hides the line (e.g. final exercise).
  final String? nextExerciseName;

  /// Short detail for the Next line, e.g. "15 reps" or "Rest · 1 min".
  final String? nextDetail;

  const EasyFocalColumn({
    super.key,
    required this.state,
    required this.exerciseName,
    required this.useKg,
    required this.weightStep,
    required this.accent,
    required this.compact,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDurationChanged,
    required this.onLogSet,
    this.editingSetIndex,
    this.nextExerciseName,
    this.nextDetail,
  });

  /// Builds the signature-v2 poster + whisper block (`.rw-poster` /
  /// `.rw-whisper`). The poster is the screen's dominant element: the live
  /// `weight × reps` (or hold seconds) rendered huge in Anton. The whisper is
  /// the Fraunces italic line beneath it. Returns the composed column so the
  /// LayoutBuilder can decide its surrounding spacing.
  Widget _poster(BuildContext context, {required bool tight}) {
    final colors = ThemeColors.of(context);
    final posterSize = tight ? 52.0 : 66.0;
    final unitSize = tight ? 18.0 : 24.0;
    final xSize = tight ? 40.0 : 54.0;
    final unit = useKg ? 'KG' : 'LB';

    final String wTok = state.displayWeight <= 0
        ? 'BW'
        : (state.displayWeight % 1 == 0
              ? state.displayWeight.toStringAsFixed(0)
              : state.displayWeight.toStringAsFixed(1));

    // Timed exercises poster: a single big seconds numeral.
    final List<Widget> posterChildren = state.isTimed
        ? [
            Text(
              '${state.durationSeconds}',
              style: ZType.disp(
                posterSize,
                color: colors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: EdgeInsets.only(bottom: posterSize * 0.10),
              child: Text(
                'SEC',
                style: ZType.lbl(
                  unitSize,
                  color: colors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ]
        : [
            Text(
              wTok,
              style: ZType.disp(
                posterSize,
                color: colors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            if (state.displayWeight > 0) ...[
              const SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: posterSize * 0.10),
                child: Text(
                  unit,
                  style: ZType.lbl(
                    unitSize,
                    color: colors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
            // The faint Anton "×" between weight and reps (`.rw-poster .x`).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '×',
                style: ZType.disp(
                  xSize,
                  color: colors.textMuted.withValues(alpha: 0.55),
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              '${state.reps}',
              style: ZType.disp(
                posterSize,
                color: colors.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ];

    final whisper = _whisperLine(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: posterChildren,
          ),
        ),
        if (whisper != null) ...[
          SizedBox(height: tight ? 5 : 8),
          Text(
            whisper,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ZType.ser(tight ? 14 : 15.5, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }

  /// The Fraunces whisper copy. Derived from the live target vs. the value
  /// the user is about to log — no new data dependency, no provider read.
  /// Returns null when there's nothing meaningful to whisper (keeps the
  /// poster block tight on SE).
  String? _whisperLine(BuildContext context) {
    if (state.isTimed) {
      final t = state.durationSeconds;
      return t > 0 ? 'Hold the line. $t seconds.' : null;
    }
    final targetDisplay = useKg
        ? state.targetWeightKg
        : state.targetWeightKg * 2.20462;
    if (targetDisplay > 0 && state.displayWeight > targetDisplay + 0.01) {
      return 'Above target. Own it.';
    }
    if (targetDisplay > 0 && state.displayWeight + 0.01 < targetDisplay) {
      final tok = targetDisplay % 1 == 0
          ? targetDisplay.toStringAsFixed(0)
          : targetDisplay.toStringAsFixed(1);
      return 'Target is $tok. Push.';
    }
    return 'Hit your target. Push.';
  }

  /// The uppercase CTA caption for the `.rw-cta` pill. Restates the live
  /// poster value ("LOG SET — 60 × 8") so the button reads as the commit of
  /// what's on screen; falls back to "UPDATE SET N" when re-editing a logged
  /// set, and to a hold caption for timed exercises.
  String _ctaLabel() {
    if (editingSetIndex != null) {
      return 'UPDATE SET ${editingSetIndex! + 1}';
    }
    if (state.isTimed) {
      return 'LOG SET — ${state.durationSeconds}s';
    }
    final wTok = state.displayWeight <= 0
        ? 'BW'
        : (state.displayWeight % 1 == 0
              ? state.displayWeight.toStringAsFixed(0)
              : state.displayWeight.toStringAsFixed(1));
    return '✓  LOG SET — $wTok × ${state.reps}';
  }

  @override
  Widget build(BuildContext context) {
    // Breakpoints pick sizes from the actual available height, not the
    // device. Parent `compact` flag still forces compact for explicit SE-class
    // devices; otherwise we compact when vertical slack is < 280pt (happens
    // on taller phones too when the header gets a 2-line title).
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final colors = ThemeColors.of(ctx);
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 320.0;
        final tight = compact || availableHeight < 340.0;
        final stepperCompact = compact || availableHeight < 380.0;
        final gapBetweenSteppers = tight ? 6.0 : 12.0;
        final logBtnHeight = tight ? 56.0 : 64.0;
        final verticalPad = tight ? 4.0 : 8.0;
        final logFontSize = tight ? 15.0 : 17.0;

        // Timed exercises (planks, wall sits, dead-hangs) measure hold
        // duration, not weight × reps. Render a single seconds stepper
        // and write the user's value into SetLog.durationSeconds.
        // Timed move (warm-up hold / plank / wall-sit): a LIVE countdown with
        // built-in play/pause (TimedExerciseTimer). Starts paused — tap ▶ to
        // begin the hold, ⏸ to pause/resume. The big LOG SET below commits the
        // hold (reachable any time); the timer's completion just buzzes. The
        // ValueKey resets the countdown when the exercise OR set changes.
        final timedBody = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TimedExerciseTimer(
              // Key includes the duration so the ±5s nudges below reset the
              // countdown to the new hold target.
              key: ValueKey(
                  'easytimed_${exerciseName}_${state.completedCount}_${state.durationSeconds}'),
              durationSeconds: state.durationSeconds,
              exerciseName: exerciseName,
              setNumber: state.completedCount + 1,
              totalSets: state.totalSets,
              autoStart: false,
              onComplete: () => HapticService.instance.success(),
            ),
            const SizedBox(height: 16),
            // ±5s nudges either side of the hold target (spec).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NudgePill(
                  label: '−5s',
                  color: colors.textPrimary,
                  onTap: () {
                    HapticService.instance.tick();
                    onDurationChanged(
                        (state.durationSeconds - 5).clamp(5, 3600).toDouble());
                  },
                ),
                const SizedBox(width: 16),
                _NudgePill(
                  label: '+5s',
                  color: colors.textPrimary,
                  onTap: () {
                    HapticService.instance.tick();
                    onDurationChanged(
                        (state.durationSeconds + 5).clamp(5, 3600).toDouble());
                  },
                ),
              ],
            ),
          ],
        );

        // Caption rendered BELOW each stepper (per the approved mockup): the
        // value stays bare ("60" / "12") inside the −/+ controls and the unit
        // lives in the label below ("WEIGHT (LB)" / "REPS"). The two steppers
        // sit SIDE BY SIDE on one row (not stacked) so the focal block never
        // pushes the LOG button off-screen. The kg|lb toggle lives in the
        // header tab row.
        final stepLabel = ZType.lbl(11, color: colors.textMuted, letterSpacing: 1.5);
        Widget stepperColumn(Widget stepper, String label) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                stepper,
                const SizedBox(height: 5),
                Text(label, style: stepLabel, textAlign: TextAlign.center),
              ],
            );
        final repsBody = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Anton poster (`.rw-poster`) + Fraunces whisper — the huge
            // `weight × reps` masthead — dominate the top of the focal column.
            _poster(ctx, tight: tight),
            SizedBox(height: tight ? 14 : 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: stepperColumn(
                    FocalStepper(
                      value: state.displayWeight,
                      step: weightStep,
                      unit: '',
                      min: 0,
                      max: 999,
                      compact: stepperCompact,
                      dense: true,
                      onChanged: onWeightChanged,
                    ),
                    'WEIGHT (${useKg ? 'KG' : 'LB'})',
                  ),
                ),
                SizedBox(width: gapBetweenSteppers + 8),
                Expanded(
                  child: stepperColumn(
                    FocalStepper(
                      value: state.reps.toDouble(),
                      step: 1,
                      unit: '',
                      integerOnly: true,
                      min: 0,
                      max: 99,
                      compact: stepperCompact,
                      dense: true,
                      onChanged: onRepsChanged,
                    ),
                    AppLocalizations.of(context)
                        .workoutSummaryGeneralReps
                        .toUpperCase(),
                  ),
                ),
              ],
            ),
          ],
        );

        // Helper line under the steppers: increment + interaction affordances.
        final stepTok = weightStep % 1 == 0
            ? weightStep.toStringAsFixed(0)
            : weightStep.toStringAsFixed(1);
        final helperLine = state.isTimed
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+$stepTok ${useKg ? 'kg' : 'lb'} · tap = haptic tick · hold = ramp faster',
                  textAlign: TextAlign.center,
                  style: ZType.sans(11.5, color: colors.textMuted),
                ),
              );

        // "Next: <name> · <detail>" preview just above LOG SET.
        final nextLine = (nextExerciseName == null || nextExerciseName!.isEmpty)
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: RichText(
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: ZType.sans(13.5, color: colors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Next: ',
                        style: ZType.sans(13.5, color: colors.textMuted),
                      ),
                      TextSpan(
                        text: nextExerciseName!,
                        style: ZType.sans(13.5,
                            color: colors.textPrimary, weight: FontWeight.w700),
                      ),
                      if (nextDetail != null && nextDetail!.isNotEmpty)
                        TextSpan(
                          text: ' · ${nextDetail!}',
                          style: ZType.sans(13.5, color: colors.textSecondary),
                        ),
                    ],
                  ),
                ),
              );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Center the poster+steppers in the residual space but scroll
              // instead of overflowing when the budget is genuinely too small.
              Expanded(
                child: LayoutBuilder(
                  builder: (innerCtx, innerC) => SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: innerC.maxHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [state.isTimed ? timedBody : repsBody],
                      ),
                    ),
                  ),
                ),
              ),
              if (helperLine != null) helperLine,
              if (nextLine != null) nextLine,
              SizedBox(height: tight ? 8 : 12),
              // The rounded accent CTA pill (`.rw-cta`): caption restates the
              // live `weight × reps` ("LOG SET — 60 × 12"), matching the frame.
              SizedBox(
                height: logBtnHeight,
                child: ElevatedButton(
                  onPressed: onLogSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentContrast,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    _ctaLabel(),
                    style: ZType.lbl(
                      logFontSize,
                      color: colors.accentContrast,
                      weight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: tight ? 4 : 8),
            ],
          ),
        );
      },
    );
  }
}

/// Compact ±5s nudge pill flanking the timed-move countdown.
class _NudgePill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NudgePill(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: ZType.data(16, color: color, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Minimal fullscreen media viewer used when "Show video" is tapped.
/// TODO(shared-agent): replace with shared video sheet once exposed.
class EasyFullscreenMediaViewer extends StatelessWidget {
  final String url;
  const EasyFullscreenMediaViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
