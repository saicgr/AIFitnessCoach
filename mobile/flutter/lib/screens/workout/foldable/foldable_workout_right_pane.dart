/// Foldable Workout Right Pane
///
/// Right pane for foldable/tablet tri-layout containing:
/// - Top portion (~60%): Exercise title, heart rate, action chips,
///   SetTrackingTable, AiTextInputBar in a scrollable column
/// - Bottom portion (~40%): InlineWorkoutChat
///
/// Uses ResizableSplitView so the user can drag the divider.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/workout_design.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../widgets/heart_rate_display.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../widgets/action_chips_row.dart';
import '../widgets/ai_text_input_bar.dart';
import '../widgets/inline_workout_chat.dart';
import '../widgets/set_tracking_table.dart';
import 'resizable_split_view.dart';

/// Right pane of the foldable workout layout.
///
/// Top: set tracking with exercise header and action chips.
/// Bottom: inline AI workout chat.
class FoldableWorkoutRightPane extends ConsumerWidget {
  // ── Exercise context ──────────────────────────────────────────────────

  /// The exercise currently being viewed
  final WorkoutExercise exercise;

  /// All exercises in the workout
  final List<WorkoutExercise> exercises;

  /// Index of the exercise being viewed
  final int viewingExerciseIndex;

  /// Index of the exercise currently being performed
  final int currentExerciseIndex;

  // ── Set tracking ──────────────────────────────────────────────────────

  /// Set row data for the current exercise
  final List<SetRowData> setRows;

  /// Whether using kg or lbs
  final bool useKg;

  /// Number of completed sets for the viewed exercise
  final int completedSets;

  /// Total sets per exercise (map by index)
  final Map<int, int> totalSetsPerExercise;

  /// Weight text controller for the active set
  final TextEditingController weightController;

  /// Reps text controller for the active set
  final TextEditingController repsController;

  /// Right reps controller for L/R mode
  final TextEditingController? repsRightController;

  /// Whether left/right mode is enabled
  final bool isLeftRightMode;

  /// Whether to show the inline rest row
  final bool showInlineRest;

  /// The inline rest row widget (passed from parent for centralized state)
  final Widget? inlineRestRowWidget;

  // ── Set tracking callbacks ────────────────────────────────────────────

  /// Called when a set checkbox is completed
  final void Function(int setIndex) onSetCompleted;

  /// Called when a completed set is edited
  final void Function(int setIndex, double weight, int reps)? onSetUpdated;

  /// Called to add a new set
  final VoidCallback onAddSet;

  /// Called when a set is deleted via swipe
  final void Function(int setIndex)? onSetDeleted;

  /// Called to toggle kg/lbs
  final VoidCallback? onToggleUnit;

  /// Called when RIR badge is tapped
  final void Function(int setIndex, int? currentRir)? onRirTapped;

  /// Current RIR selection for the active set
  final int? activeRir;

  /// Called when user picks a new RIR value
  final ValueChanged<int>? onActiveRirChanged;

  /// Whether all sets for the viewed exercise are completed
  final bool allSetsCompleted;

  /// Called when select-all checkbox is tapped
  final VoidCallback? onSelectAllTapped;

  // ── Action chips ──────────────────────────────────────────────────────

  /// Chip data list for ActionChipsRow
  final List<ActionChipData> actionChips;

  /// Called when an action chip is tapped
  final void Function(String chipId) onChipTapped;

  /// Whether the AI chip is shown
  final bool showAiChip;

  /// Whether AI has a pending notification
  final bool hasAiNotification;

  /// Called when the AI chip is tapped
  final VoidCallback? onAiChipTapped;

  // ── AI text input bar ─────────────────────────────────────────────────

  /// Workout ID for the AI text input bar
  final String workoutId;

  /// Current exercise name for AI context
  final String? currentExerciseName;

  /// Current exercise index for AI context
  final int? currentExerciseIndexForAi;

  /// Last logged weight for AI shortcuts
  final double? lastSetWeight;

  /// Last logged reps for AI shortcuts
  final int? lastSetReps;

  /// Called when V2 AI parsing completes
  final void Function(ParseWorkoutInputV2Response result)? onV2Parsed;

  /// Called when exercises are parsed from AI input
  final void Function(List<ParsedExercise> exercises) onExercisesParsed;

  // ── Chat context ──────────────────────────────────────────────────────

  /// Remaining exercises after the current one (for chat context)
  final List<WorkoutExercise> remainingExercises;

  /// Current weight being used (for chat context)
  final double currentWeight;

  /// Total sets for the current exercise (for chat context)
  final int totalSets;

  /// Whether to hide the AI coach chat section for this session
  final bool hideAICoachForSession;

  // ── Info button ───────────────────────────────────────────────────────

  /// Called when the info pill next to the exercise title is tapped
  final VoidCallback? onInfoTap;

  const FoldableWorkoutRightPane({
    super.key,
    required this.exercise,
    required this.exercises,
    required this.viewingExerciseIndex,
    required this.currentExerciseIndex,
    required this.setRows,
    required this.useKg,
    required this.completedSets,
    required this.totalSetsPerExercise,
    required this.weightController,
    required this.repsController,
    this.repsRightController,
    this.isLeftRightMode = false,
    this.showInlineRest = false,
    this.inlineRestRowWidget,
    required this.onSetCompleted,
    this.onSetUpdated,
    required this.onAddSet,
    this.onSetDeleted,
    this.onToggleUnit,
    this.onRirTapped,
    this.activeRir,
    this.onActiveRirChanged,
    this.allSetsCompleted = false,
    this.onSelectAllTapped,
    required this.actionChips,
    required this.onChipTapped,
    this.showAiChip = false,
    this.hasAiNotification = false,
    this.onAiChipTapped,
    required this.workoutId,
    this.currentExerciseName,
    this.currentExerciseIndexForAi,
    this.lastSetWeight,
    this.lastSetReps,
    this.onV2Parsed,
    required this.onExercisesParsed,
    required this.remainingExercises,
    required this.currentWeight,
    required this.totalSets,
    this.hideAICoachForSession = false,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? WorkoutDesign.background : Colors.grey.shade50;
    final showChat = !hideAICoachForSession &&
        ref.watch(aiSettingsProvider).showAICoachDuringWorkouts;

    return Container(
      color: bgColor,
      child: showChat
          ? ResizableSplitView(
              initialTopRatio: 0.6,
              minTopRatio: 0.3,
              maxTopRatio: 0.8,
              topChild: _buildTrackingSection(context, isDark),
              bottomChild: _buildChatSection(),
            )
          : _buildTrackingSection(context, isDark),
    );
  }

  /// Top section: exercise header + action chips + set table + AI input
  Widget _buildTrackingSection(BuildContext context, bool isDark) {
    final totalForExercise = totalSetsPerExercise[viewingExerciseIndex] ?? 3;

    return Column(
      children: [
        // Exercise title row + heart rate + info pill
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name + set counter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: WorkoutDesign.titleStyle.copyWith(
                        fontSize: 22,
                        color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set ${completedSets + 1} of $totalForExercise',
                      style: WorkoutDesign.subtitleStyle.copyWith(
                        color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Heart rate display
              HeartRateDisplay(
                iconSize: 20,
                fontSize: 16,
                showZoneLabel: false,
              ),
              const SizedBox(width: 8),
              // Info pill
              if (onInfoTap != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onInfoTap!();
                  },
                  child: Container(
                    height: WorkoutDesign.chipHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? WorkoutDesign.surface : Colors.white,
                      borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
                      border: Border.all(
                        color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Info',
                          style: WorkoutDesign.chipStyle.copyWith(
                            fontSize: 12,
                            color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Action chips row
        ActionChipsRow(
          chips: actionChips,
          onChipTapped: onChipTapped,
          showAiChip: showAiChip,
          hasAiNotification: hasAiNotification,
          onAiChipTapped: onAiChipTapped,
        ),

        const SizedBox(height: 4),

        // Set tracking table + AI input bar (scrollable)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SetTrackingTable(
                  key: ValueKey('foldable_set_tracking_$viewingExerciseIndex'),
                  exercise: exercise,
                  sets: setRows,
                  useKg: useKg,
                  activeSetIndex: completedSets,
                  weightController: weightController,
                  repsController: repsController,
                  repsRightController: isLeftRightMode ? repsRightController : null,
                  onSetCompleted: onSetCompleted,
                  onSetUpdated: onSetUpdated,
                  onAddSet: onAddSet,
                  isLeftRightMode: isLeftRightMode,
                  allSetsCompleted: allSetsCompleted,
                  onSelectAllTapped: onSelectAllTapped,
                  onSetDeleted: onSetDeleted,
                  onToggleUnit: onToggleUnit,
                  onRirTapped: onRirTapped,
                  activeRir: activeRir,
                  onActiveRirChanged: onActiveRirChanged,
                  showInlineRest: showInlineRest,
                  inlineRestRowWidget: inlineRestRowWidget,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AiTextInputBar(
                    workoutId: workoutId,
                    useKg: useKg,
                    currentExerciseName: currentExerciseName,
                    currentExerciseIndex: currentExerciseIndexForAi,
                    lastSetWeight: lastSetWeight,
                    lastSetReps: lastSetReps,
                    onV2Parsed: onV2Parsed,
                    onExercisesParsed: onExercisesParsed,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom section: inline workout chat
  Widget _buildChatSection() {
    return InlineWorkoutChat(
      currentExercise: exercise,
      completedSets: completedSets,
      totalSets: totalSets,
      currentWeight: currentWeight,
      useKg: useKg,
      remainingExercises: remainingExercises,
    );
  }
}
