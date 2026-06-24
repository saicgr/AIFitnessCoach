// Easy tier — presentational view.
//
// Pure `StatelessWidget` that composes the fixed-height column + the
// bottom-right chat pill Stack. Split from the State class so the state
// file stays under the 300-line budget.
//
// This widget holds zero state; the owning State class passes every value
// and callback explicitly. That means it's trivial to wrap in a golden
// test (no providers needed to reproduce a pixel-perfect SE frame).

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../models/workout_state.dart';
import '../widgets/workout_stats_strip.dart';
import 'easy_active_workout_state_models.dart';
import 'score_target_service.dart';
import 'widgets/easy_chat_pill.dart';
import 'widgets/easy_completed_dots.dart';
import 'widgets/easy_exercise_header.dart';
import 'widgets/easy_focal_column.dart';
import 'widgets/easy_top_bar.dart';

class EasyActiveWorkoutView extends StatelessWidget {
  final WorkoutExercise exercise;
  final EasyExerciseState state;
  final String? nextExerciseName;
  final String? nextExerciseImageUrl;
  final int currentSetNumber;

  final int workoutSeconds;
  final bool useKg;
  final bool compact;
  final double weightStep;
  final Color accent;
  final bool isDark;

  /// Engine-computed pre-set insight for the current focal row. Null when
  /// the engine has nothing meaningful to say (no history, signal-quiet,
  /// dismissed). The banner collapses to zero height on null, keeping the
  /// Easy layout scroll-free on iPhone SE.
  final String? preSetInsight;

  final VoidCallback onBack;
  final VoidCallback onShowVideo;
  final VoidCallback onOpenPlan;
  final VoidCallback onShowInfo;

  /// Opens the AI Form-Check sheet for the current exercise (pre-filled name,
  /// editable). Drives the accent "Form" chip in the header media row.
  final VoidCallback? onFormCheck;

  /// Opens the "How did I do?" AI critique for the sets just logged on the
  /// current exercise. Null until ≥1 working set is logged.
  final VoidCallback? onHowDidIDo;

  final VoidCallback? onMinimize;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onRepsChanged;
  final ValueChanged<double> onDurationChanged;
  final Future<void> Function() onLogSet;

  /// 0-indexed past set currently being edited; null ⇒ live set.
  final int? editingSetIndex;
  final ValueChanged<int>? onEditSet;
  final VoidCallback? onReturnToCurrent;
  final ValueChanged<int>? onSkipToSet;

  /// Tap + / − on the "Set N of M" row. Null disables the respective side.
  final VoidCallback? onAddSet;
  final VoidCallback? onRemoveSet;

  /// Cached "last time" data for the current exercise, or null if the user
  /// hasn't done this exercise before. Drives the `EasyLastTimeChip`.
  final ({double weightKg, int reps, DateTime when})? lastSet;

  /// B6 — Strength-Score target for the current exercise's primary muscle,
  /// or null when there's no target (already elite / excluded / unavailable).
  /// Drives the `EasyScoreTargetPill`.
  final ScoreTarget? scoreTarget;

  /// Opens the shared `EnhancedNotesSheet` for the current focal set.
  final VoidCallback? onEditNote;

  /// True when the current focal set has any note / audio / photo attached.
  final bool hasNote;

  /// Skip the current exercise and jump to the next. Null disables (e.g.
  /// final exercise of the workout).
  final VoidCallback? onSkipToNext;

  /// Opens the History sheet — wired to the set-ledger pill taps (spec).
  final VoidCallback? onShowHistory;

  /// Open the per-exercise actions sheet (Swap / Report pain / Change
  /// equipment / Skip / Video). Wired by the state to the new
  /// `EasyExerciseActionsSheet.show()` helper. Reachable via the "•••"
  /// chip in the header AND a long-press anywhere on the focal card.
  final VoidCallback? onShowExerciseActions;

  /// Quit the whole workout — confirms + pops back to the list.
  final VoidCallback? onQuitWorkout;

  /// Finalize the workout NOW. Any remaining unlogged sets get auto-stamped
  /// as zero (weight 0, reps 0, is_completed: false) and the user lands on
  /// the completion screen with whatever they've actually logged.
  final VoidCallback? onCompleteWorkoutNow;

  /// Every completed set across every exercise in this session. Flattened
  /// view of `_perExercise.values.expand((e) => e.completed)`. Drives the
  /// live Calories + Volume numbers in the stats strip.
  final List<SetLog> allCompletedSets;

  const EasyActiveWorkoutView({
    super.key,
    required this.exercise,
    required this.state,
    required this.nextExerciseName,
    this.nextExerciseImageUrl,
    required this.currentSetNumber,
    required this.workoutSeconds,
    required this.useKg,
    required this.compact,
    required this.weightStep,
    required this.accent,
    required this.isDark,
    required this.preSetInsight,
    required this.onBack,
    required this.onShowVideo,
    required this.onOpenPlan,
    required this.onShowInfo,
    this.onFormCheck,
    this.onHowDidIDo,
    this.onMinimize,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDurationChanged,
    required this.onLogSet,
    this.editingSetIndex,
    this.onEditSet,
    this.onReturnToCurrent,
    this.onSkipToSet,
    this.onAddSet,
    this.onRemoveSet,
    this.lastSet,
    this.scoreTarget,
    this.onEditNote,
    this.hasNote = false,
    this.onSkipToNext,
    this.onShowHistory,
    this.onShowExerciseActions,
    this.onQuitWorkout,
    this.onCompleteWorkoutNow,
    this.allCompletedSets = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.background : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            EasyTopBar(
              workoutSeconds: workoutSeconds,
              onBack: onBack,
              onMinimize: onMinimize,
              onCompleteNow: onCompleteWorkoutNow,
              onQuit: onQuitWorkout,
              onSkipToNext: onSkipToNext,
              exercise: exercise,
              // Single ⋯ opens the full actions sheet (mockup).
              onShowActions: onShowExerciseActions,
            ),
            WorkoutStatsStrip(
              workoutSeconds: workoutSeconds,
              setLogs: allCompletedSets,
              useKg: useKg,
              isDark: isDark,
              // EFFORT (live HR) as the mockup's 2nd stat — shows "—" without
              // a wearable streaming, never a fabricated number.
              showEffort: true,
            ),
            EasyExerciseHeader(
              exercise: exercise,
              currentSet: currentSetNumber,
              totalSets: state.totalSets,
              compact: compact,
              onShowVideo: onShowVideo,
              onOpenPlan: onOpenPlan,
              onShowInfo: onShowInfo,
              onFormCheck: onFormCheck,
              onAddSet: onAddSet,
              onRemoveSet: onRemoveSet,
              onEditNote: onEditNote,
              hasNote: hasNote,
              onShowMore: onShowExerciseActions,
            ),
            EasyCompletedDots(
              completedSetsForCurrentExercise: state.completed,
              currentSetIndex: state.completedCount,
              totalSets: state.totalSets,
              useKg: useKg,
              currentWeightDisplay: state.displayWeight,
              currentReps: state.reps,
              editingSetIndex: editingSetIndex,
              onEditSet: onEditSet,
              onReturnToCurrent: onReturnToCurrent,
              onSkipToSet: onSkipToSet,
              // Spec: tap any ledger pill → History sheet.
              onOpenHistory: onShowHistory,
            ),
            // EASY REDESIGN: the five stacked insight cards (pre-set coach
            // tip / last-time / score-target / how-did-I-do) were REMOVED from
            // the log surface — they crowded the focal action. Their content
            // now lives behind the "↺ History" affordance + the Ask-coach
            // footer (see easy-redesign.html). The EasyCompletedDots strip
            // above already shows the per-set ledger (previous sets inline).
            // The focal poster + LOG SET now own the residual height.
            Expanded(
              // Long-press anywhere on the focal column body opens the same
              // actions sheet as the "•••" header chip. `behavior: deferToChild`
              // ensures the inner +/− stepper buttons and the big Log set CTA
              // still get their own taps before this gesture wins.
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onLongPress: onShowExerciseActions,
                child: EasyFocalColumn(
                  state: state,
                  exerciseName: exercise.name,
                  useKg: useKg,
                  weightStep: weightStep,
                  accent: accent,
                  compact: compact,
                  onWeightChanged: onWeightChanged,
                  onRepsChanged: onRepsChanged,
                  onDurationChanged: onDurationChanged,
                  onLogSet: onLogSet,
                  editingSetIndex: editingSetIndex,
                  // "Next: <name>" preview shown just above LOG SET (mockup).
                  nextExerciseName: nextExerciseName,
                ),
              ),
            ),
            // Full-width "✦ Ask coach" below LOG SET — the only secondary CTA,
            // visually lighter than the primary Log Set (per the mockup). Skip
            // to the next exercise lives in the ⋯ menu.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: EasyChatPill(
                currentExercise: exercise,
                currentSetNumber: currentSetNumber,
                totalSets: state.totalSets,
                expand: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
