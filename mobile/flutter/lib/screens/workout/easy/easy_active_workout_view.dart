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
import '../shared/pre_set_insight_banner.dart';
import '../widgets/workout_stats_strip.dart';
import 'easy_active_workout_state_models.dart';
import 'widgets/easy_chat_pill.dart';
import 'widgets/easy_completed_dots.dart';
import 'widgets/easy_exercise_header.dart';
import 'widgets/easy_focal_column.dart';
import 'widgets/easy_last_time_chip.dart';
import 'widgets/easy_top_bar.dart';
import 'widgets/easy_up_next_chip.dart';

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
  final VoidCallback? onMinimize;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onRepsChanged;
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

  /// Opens the shared `EnhancedNotesSheet` for the current focal set.
  final VoidCallback? onEditNote;

  /// True when the current focal set has any note / audio / photo attached.
  final bool hasNote;

  /// Skip the current exercise and jump to the next. Null disables (e.g.
  /// final exercise of the workout).
  final VoidCallback? onSkipToNext;

  /// Quit the whole workout — confirms + pops back to the list.
  final VoidCallback? onQuitWorkout;

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
    this.onMinimize,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onLogSet,
    this.editingSetIndex,
    this.onEditSet,
    this.onReturnToCurrent,
    this.onSkipToSet,
    this.onAddSet,
    this.onRemoveSet,
    this.lastSet,
    this.onEditNote,
    this.hasNote = false,
    this.onSkipToNext,
    this.onQuitWorkout,
    this.allCompletedSets = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.background : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          EasyTopBar(
            workoutSeconds: workoutSeconds,
            onBack: onBack,
            onMinimize: onMinimize,
            onQuit: onQuitWorkout,
            onSkipToNext: onSkipToNext,
            exercise: exercise,
          ),
          WorkoutStatsStrip(
            workoutSeconds: workoutSeconds,
            setLogs: allCompletedSets,
            useKg: useKg,
            isDark: isDark,
          ),
          EasyExerciseHeader(
            exercise: exercise,
            currentSet: currentSetNumber,
            totalSets: state.totalSets,
            compact: compact,
            onShowVideo: onShowVideo,
            onOpenPlan: onOpenPlan,
            onShowInfo: onShowInfo,
            onAddSet: onAddSet,
            onRemoveSet: onRemoveSet,
            onEditNote: onEditNote,
            hasNote: hasNote,
          ),
          EasyCompletedDots(
            completedSetsForCurrentExercise: state.completed,
            currentSetIndex: state.completedCount,
            totalSets: state.totalSets,
            useKg: useKg,
            editingSetIndex: editingSetIndex,
            onEditSet: onEditSet,
            onReturnToCurrent: onReturnToCurrent,
            onSkipToSet: onSkipToSet,
          ),
          // Pre-set AI insight banner. Renders between the completed-dots
          // strip and the focal stepper column. Collapses to zero height
          // when `preSetInsight` is null (no history / dismissed /
          // nothing-to-say), so the fixed-heights budget stays predictable
          // on iPhone SE.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PreSetInsightBanner(
              exerciseId: exercise.exerciseId ??
                  exercise.libraryId ??
                  exercise.name,
              setIndex: currentSetNumber - 1,
              insight: preSetInsight,
              tone: InsightTone.easy,
            ),
          ),
          EasyLastTimeChip(
            weight: lastSet == null
                ? null
                : (useKg
                    ? lastSet!.weightKg
                    : lastSet!.weightKg * 2.20462),
            reps: lastSet?.reps,
            unit: useKg ? 'kg' : 'lb',
            when: lastSet?.when,
          ),
          Expanded(
            child: EasyFocalColumn(
              state: state,
              useKg: useKg,
              weightStep: weightStep,
              accent: accent,
              compact: compact,
              onWeightChanged: onWeightChanged,
              onRepsChanged: onRepsChanged,
              onLogSet: onLogSet,
              editingSetIndex: editingSetIndex,
            ),
          ),
          // Up next + Ask-coach share one row so Log Set stays the only
          // primary CTA. Tap the Up-next chip to SKIP to the next exercise.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: EasyUpNextChip(
                    nextExerciseName: nextExerciseName,
                    nextExerciseImageUrl: nextExerciseImageUrl,
                    onSkipToNext: onSkipToNext,
                  ),
                ),
                const SizedBox(width: 8),
                EasyChatPill(
                  currentExercise: exercise,
                  currentSetNumber: currentSetNumber,
                  totalSets: state.totalSets,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
