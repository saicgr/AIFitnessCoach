/// Active Workout Body V2
///
/// MacroFactor Workouts 2026 inspired active workout layout.
/// Composes the new design system components:
/// - Exercise thumbnail strip at top
/// - Exercise title + subtitle
/// - Action chips row
/// - Set tracking table with checkbox completion
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/workout_design.dart';
import '../../../data/models/exercise.dart';
import '../models/workout_state.dart';
import 'exercise_thumbnail_strip_v2.dart';
import 'action_chips_row.dart';
import 'set_tracking_table.dart';

/// MacroFactor-style active workout body
class ActiveWorkoutBodyV2 extends StatelessWidget {
  /// All exercises in the workout
  final List<WorkoutExercise> exercises;

  /// Currently active exercise index
  final int currentExerciseIndex;

  /// Set of completed exercise indices
  final Set<int> completedExercises;

  /// Current exercise
  final WorkoutExercise currentExercise;

  /// All sets data for current exercise
  final List<SetRowData> sets;

  /// Active set index
  final int activeSetIndex;

  /// Whether using kg or lbs
  final bool useKg;

  /// Weight controller
  final TextEditingController weightController;

  /// Reps controller
  final TextEditingController repsController;

  /// Whether L/R mode is enabled
  final bool isLeftRightMode;

  /// Whether all sets are completed
  final bool allSetsCompleted;

  /// Whether AI has a suggestion available
  final bool hasAiSuggestion;

  // Callbacks
  final void Function(int index) onExerciseTap;
  final VoidCallback? onAddExerciseTap;
  final void Function(String chipId) onChipTapped;
  final VoidCallback? onAiChipTapped;
  final void Function(int setIndex) onSetCompleted;
  final void Function(int setIndex, double weight, int reps)? onSetUpdated;
  final VoidCallback onAddSet;
  final VoidCallback? onSelectAllTapped;

  const ActiveWorkoutBodyV2({
    super.key,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.completedExercises,
    required this.currentExercise,
    required this.sets,
    required this.activeSetIndex,
    required this.useKg,
    required this.weightController,
    required this.repsController,
    this.isLeftRightMode = false,
    this.allSetsCompleted = false,
    this.hasAiSuggestion = false,
    required this.onExerciseTap,
    this.onAddExerciseTap,
    required this.onChipTapped,
    this.onAiChipTapped,
    required this.onSetCompleted,
    this.onSetUpdated,
    required this.onAddSet,
    this.onSelectAllTapped,
  });

  @override
  Widget build(BuildContext context) {
    final completedSets = sets.where((s) => s.isCompleted).length;
    final totalSets = sets.length;

    return Container(
      color: WorkoutDesign.background,
      child: SafeArea(
        top: false, // Top bar handles this
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise thumbnail strip
            ExerciseThumbnailStripV2(
              exercises: exercises,
              currentIndex: currentExerciseIndex,
              completedExercises: completedExercises,
              onExerciseTap: onExerciseTap,
              onAddTap: onAddExerciseTap,
              showAddButton: onAddExerciseTap != null,
            ),

            const SizedBox(height: 16),

            // Exercise title and set counter
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WorkoutDesign.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentExercise.name,
                    style: WorkoutDesign.titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set ${completedSets + 1} of $totalSets',
                    style: WorkoutDesign.subtitleStyle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action chips row
            ActionChipsRow(
              chips: _buildChips(),
              onChipTapped: onChipTapped,
              showAiChip: true,
              hasAiNotification: hasAiSuggestion,
              onAiChipTapped: onAiChipTapped,
            ),

            const SizedBox(height: 8),

            // Set tracking table
            Expanded(
              child: SingleChildScrollView(
                child: SetTrackingTable(
                  exercise: currentExercise,
                  sets: sets,
                  useKg: useKg,
                  activeSetIndex: activeSetIndex,
                  weightController: weightController,
                  repsController: repsController,
                  onSetCompleted: onSetCompleted,
                  onSetUpdated: onSetUpdated,
                  onAddSet: onAddSet,
                  isLeftRightMode: isLeftRightMode,
                  allSetsCompleted: allSetsCompleted,
                  onSelectAllTapped: onSelectAllTapped,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ActionChipData> _buildChips() {
    return [
      WorkoutActionChips.info,
      WorkoutActionChips.warmUp,
      WorkoutActionChips.targets,
      WorkoutActionChips.swap,
      WorkoutActionChips.note,
      WorkoutActionChips.superset,
      if (isLeftRightMode) WorkoutActionChips.leftRight(isActive: true),
    ];
  }
}
