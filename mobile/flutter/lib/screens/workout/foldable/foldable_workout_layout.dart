/// Foldable Workout Layout
///
/// Main tri-layout container for foldable/tablet workout screens.
/// Composes FoldableWorkoutLeftPane and FoldableWorkoutRightPane in a
/// side-by-side Row with a hinge gap, plus full-screen overlays on top
/// (RestTimerOverlay, FatigueAlertModal).
///
/// Follows the same hinge calculation pattern as FoldableQuizScaffold.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/workout_design.dart';
import '../../../core/providers/window_mode_provider.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/rest_suggestion.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/models/parsed_exercise.dart';
import '../models/workout_state.dart';
import '../widgets/set_tracking_table.dart';
import '../widgets/action_chips_row.dart';
import '../widgets/rest_timer_overlay.dart';
import '../widgets/fatigue_alert_modal.dart';
import 'foldable_workout_left_pane.dart';
import 'foldable_workout_right_pane.dart';

/// Main foldable workout layout that arranges left and right panes
/// around the device hinge, with full-screen overlays on top.
/// Includes a Samsung-style swap button on the hinge to flip pane sides.
class FoldableWorkoutLayout extends ConsumerStatefulWidget {
  // ── Window state ──
  final WindowModeState windowState;

  // ── Exercise state ──
  final List<WorkoutExercise> exercises;
  final int currentExerciseIndex;
  final int viewingExerciseIndex;
  final Set<int> completedExerciseIndices;
  final Map<int, List<SetLog>> completedSets;
  final Map<int, int> totalSetsPerExercise;

  // ── Video / media state ──
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final String? imageUrl;

  // ── Timer state ──
  final int workoutSeconds;
  final int restSecondsRemaining;
  final int initialRestDuration;
  final bool isPaused;

  // ── Rest state ──
  final bool isResting;
  final bool isRestingBetweenExercises;
  final String currentRestMessage;

  // ── Set tracking state ──
  final List<SetRowData> setRows;
  final bool useKg;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController? repsRightController;
  final bool isLeftRightMode;
  final bool isExerciseCompleted;

  // ── Inline rest state ──
  final bool showInlineRest;
  final Widget? inlineRestRowWidget;

  // ── RIR / RPE state ──
  final int? lastSetRpe;
  final int? lastSetRir;

  // ── Weight suggestion state ──
  final WeightSuggestion? currentWeightSuggestion;
  final bool isLoadingWeightSuggestion;

  // ── Rest suggestion state ──
  final RestSuggestion? restSuggestion;
  final bool isLoadingRestSuggestion;

  // ── Fatigue alert state ──
  final FatigueAlertData? fatigueAlertData;
  final bool showFatigueAlert;

  // ── Coach persona ──
  final CoachPersona? coachPersona;

  // ── AI text input bar state ──
  final String workoutId;

  // ── Action chips ──
  final List<ActionChipData> actionChips;

  // ── AI coach visibility ──
  final bool hideAICoachForSession;

  // ── Callbacks: Exercise navigation ──
  final void Function(int index) onExerciseTap;
  final VoidCallback onAddExercise;
  final VoidCallback onQuitRequested;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int draggedIndex, int targetIndex)? onCreateSuperset;
  final VoidCallback? onVideoTap;
  final VoidCallback? onInfoTap;

  // ── Callbacks: Set tracking ──
  final void Function(int setIndex) onSetCompleted;
  final void Function(int setIndex, double weight, int reps)? onSetUpdated;
  final VoidCallback onAddSet;
  final void Function(int index)? onSetDeleted;
  final VoidCallback? onToggleUnit;
  final void Function(int setIndex, int? currentRir)? onRirTapped;
  final ValueChanged<int?>? onActiveRirChanged;
  final VoidCallback? onSelectAllTapped;

  // ── Callbacks: Action chips ──
  final void Function(String chipId) onChipTapped;
  final VoidCallback? onAiChipTapped;

  // ── Callbacks: Rest overlay ──
  final VoidCallback onSkipRest;
  final VoidCallback? onLog1RM;
  final ValueChanged<double>? onAcceptWeightSuggestion;
  final VoidCallback? onDismissWeightSuggestion;
  final ValueChanged<int>? onAcceptRestSuggestion;
  final VoidCallback? onDismissRestSuggestion;
  final ValueChanged<int?>? onRpeChanged;
  final ValueChanged<int?>? onRirChanged;

  // ── Callbacks: Fatigue ──
  final VoidCallback onAcceptFatigueSuggestion;
  final VoidCallback onDismissFatigueAlert;
  final VoidCallback onStopExercise;

  // ── Callbacks: AI text input ──
  final void Function(List<ParsedExercise> exercises) onExercisesParsed;
  final void Function(ParseWorkoutInputV2Response result)? onV2Parsed;

  const FoldableWorkoutLayout({
    super.key,
    required this.windowState,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.viewingExerciseIndex,
    required this.completedExerciseIndices,
    required this.completedSets,
    required this.totalSetsPerExercise,
    this.videoController,
    this.isVideoInitialized = false,
    this.imageUrl,
    required this.workoutSeconds,
    required this.restSecondsRemaining,
    required this.initialRestDuration,
    required this.isPaused,
    required this.isResting,
    required this.isRestingBetweenExercises,
    required this.currentRestMessage,
    required this.setRows,
    required this.useKg,
    required this.weightController,
    required this.repsController,
    this.repsRightController,
    this.isLeftRightMode = false,
    this.isExerciseCompleted = false,
    required this.showInlineRest,
    this.inlineRestRowWidget,
    this.lastSetRpe,
    this.lastSetRir,
    this.currentWeightSuggestion,
    this.isLoadingWeightSuggestion = false,
    this.restSuggestion,
    this.isLoadingRestSuggestion = false,
    this.fatigueAlertData,
    this.showFatigueAlert = false,
    this.coachPersona,
    required this.workoutId,
    required this.actionChips,
    this.hideAICoachForSession = false,
    required this.onExerciseTap,
    required this.onAddExercise,
    required this.onQuitRequested,
    this.onReorder,
    this.onCreateSuperset,
    this.onVideoTap,
    this.onInfoTap,
    required this.onSetCompleted,
    this.onSetUpdated,
    required this.onAddSet,
    this.onSetDeleted,
    this.onToggleUnit,
    this.onRirTapped,
    this.onActiveRirChanged,
    this.onSelectAllTapped,
    required this.onChipTapped,
    this.onAiChipTapped,
    required this.onSkipRest,
    this.onLog1RM,
    this.onAcceptWeightSuggestion,
    this.onDismissWeightSuggestion,
    this.onAcceptRestSuggestion,
    this.onDismissRestSuggestion,
    this.onRpeChanged,
    this.onRirChanged,
    required this.onAcceptFatigueSuggestion,
    required this.onDismissFatigueAlert,
    required this.onStopExercise,
    required this.onExercisesParsed,
    this.onV2Parsed,
  });

  @override
  ConsumerState<FoldableWorkoutLayout> createState() =>
      _FoldableWorkoutLayoutState();
}

class _FoldableWorkoutLayoutState
    extends ConsumerState<FoldableWorkoutLayout> {
  bool _isSwapped = false;

  void _toggleSwap() {
    HapticFeedback.mediumImpact();
    setState(() => _isSwapped = !_isSwapped);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? WorkoutDesign.background : Colors.grey.shade50;

    // Hinge calculation (same pattern as FoldableQuizScaffold)
    final hingeBounds = widget.windowState.hingeBounds;
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft =
        hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft =
        (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final rightPaneWidth = screenWidth - hingeLeft - hingeWidth - safeLeft;

    // Derived values for child panes
    final viewingIdx =
        widget.viewingExerciseIndex.clamp(0, widget.exercises.length - 1);
    final currentIdx =
        widget.currentExerciseIndex.clamp(0, widget.exercises.length - 1);
    final currentExercise =
        widget.exercises.isNotEmpty ? widget.exercises[currentIdx] : null;
    final viewingExercise =
        widget.exercises.isNotEmpty ? widget.exercises[viewingIdx] : null;
    final nextExercise = currentIdx < widget.exercises.length - 1
        ? widget.exercises[currentIdx + 1]
        : null;
    final completedSetsCount =
        widget.completedSets[viewingIdx]?.length ?? 0;
    final totalSetsForViewing =
        widget.totalSetsPerExercise[viewingIdx] ?? 3;
    final currentWeight =
        double.tryParse(widget.weightController.text) ?? 0;
    final remainingExercises = viewingIdx < widget.exercises.length - 1
        ? widget.exercises.sublist(viewingIdx + 1)
        : <WorkoutExercise>[];

    // Build the two pane widgets
    final leftPaneWidget = FoldableWorkoutLeftPane(
      exercises: widget.exercises,
      currentExerciseIndex: currentIdx,
      viewingExerciseIndex: viewingIdx,
      videoController: widget.videoController,
      isVideoInitialized: widget.isVideoInitialized,
      imageUrl: widget.imageUrl,
      completedExerciseIndices: widget.completedExerciseIndices,
      workoutSeconds: widget.workoutSeconds,
      onExerciseTap: widget.onExerciseTap,
      onAddExercise: widget.onAddExercise,
      onQuitRequested: widget.onQuitRequested,
      onReorder: widget.onReorder,
      onCreateSuperset: widget.onCreateSuperset,
      onVideoTap: widget.onVideoTap,
      onInfoTap: widget.onInfoTap,
    );

    final rightPaneWidget = viewingExercise != null
        ? FoldableWorkoutRightPane(
            exercise: viewingExercise,
            exercises: widget.exercises,
            viewingExerciseIndex: viewingIdx,
            currentExerciseIndex: currentIdx,
            setRows: widget.setRows,
            useKg: widget.useKg,
            completedSets: completedSetsCount,
            totalSetsPerExercise: widget.totalSetsPerExercise,
            weightController: widget.weightController,
            repsController: widget.repsController,
            repsRightController: widget.repsRightController,
            isLeftRightMode: widget.isLeftRightMode,
            showInlineRest: widget.showInlineRest &&
                viewingIdx == currentIdx &&
                !widget.isRestingBetweenExercises,
            inlineRestRowWidget: widget.inlineRestRowWidget,
            onSetCompleted: widget.onSetCompleted,
            onSetUpdated: widget.onSetUpdated,
            onAddSet: widget.onAddSet,
            onSetDeleted: widget.onSetDeleted,
            onToggleUnit: widget.onToggleUnit,
            onRirTapped: widget.onRirTapped,
            activeRir: widget.lastSetRir,
            onActiveRirChanged: widget.onActiveRirChanged,
            allSetsCompleted: widget.isExerciseCompleted,
            onSelectAllTapped: widget.onSelectAllTapped,
            actionChips: widget.actionChips,
            onChipTapped: widget.onChipTapped,
            showAiChip: false,
            hasAiNotification: widget.currentWeightSuggestion != null,
            onAiChipTapped: widget.onAiChipTapped,
            workoutId: widget.workoutId,
            currentExerciseName: viewingExercise.name,
            currentExerciseIndexForAi: viewingIdx,
            lastSetWeight:
                widget.completedSets[viewingIdx]?.isNotEmpty == true
                    ? widget.completedSets[viewingIdx]!.last.weight
                    : null,
            lastSetReps:
                widget.completedSets[viewingIdx]?.isNotEmpty == true
                    ? widget.completedSets[viewingIdx]!.last.reps
                    : null,
            onV2Parsed: widget.onV2Parsed,
            onExercisesParsed: widget.onExercisesParsed,
            remainingExercises: remainingExercises,
            currentWeight: currentWeight,
            totalSets: totalSetsForViewing,
            hideAICoachForSession: widget.hideAICoachForSession,
            onInfoTap: widget.onInfoTap,
          )
        : const SizedBox.shrink();

    // Determine which widget goes where based on swap state
    final firstPane = _isSwapped ? rightPaneWidget : leftPaneWidget;
    final secondPane = _isSwapped ? leftPaneWidget : rightPaneWidget;
    final firstWidth = _isSwapped ? rightPaneWidth : hingeLeft;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onQuitRequested();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Main Row: Pane 1 | Hinge | Pane 2 ──
              Row(
                children: [
                  SizedBox(
                    width: firstWidth,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_isSwapped ? 'right_on_left' : 'left'),
                        child: firstPane,
                      ),
                    ),
                  ),

                  // Hinge gap
                  SizedBox(width: hingeWidth),

                  // Second pane
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_isSwapped ? 'left_on_right' : 'right'),
                        child: secondPane,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Samsung-style swap button on hinge ──
              Positioned(
                left: hingeLeft + (hingeWidth / 2) - 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleSwap,
                    child: AnimatedRotation(
                      turns: _isSwapped ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 22,
                          color: isDark
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Full-screen overlays ──

              // Rest timer overlay (between exercises only)
              if (widget.isResting &&
                  widget.isRestingBetweenExercises &&
                  currentExercise != null)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: RestTimerOverlay(
                      restSecondsRemaining: widget.restSecondsRemaining,
                      initialRestDuration: widget.initialRestDuration,
                      restMessage: widget.currentRestMessage,
                      currentExercise: currentExercise,
                      completedSetsCount:
                          widget.completedSets[currentIdx]?.length ?? 0,
                      totalSets:
                          widget.totalSetsPerExercise[currentIdx] ?? 3,
                      nextExercise: nextExercise,
                      isRestBetweenExercises:
                          widget.isRestingBetweenExercises,
                      onSkipRest: widget.onSkipRest,
                      onLog1RM: widget.onLog1RM,
                      weightSuggestion: widget.currentWeightSuggestion,
                      isLoadingWeightSuggestion:
                          widget.isLoadingWeightSuggestion,
                      onAcceptWeightSuggestion:
                          widget.onAcceptWeightSuggestion,
                      onDismissWeightSuggestion:
                          widget.onDismissWeightSuggestion,
                      restSuggestion: widget.restSuggestion,
                      isLoadingRestSuggestion:
                          widget.isLoadingRestSuggestion,
                      onAcceptRestSuggestion:
                          widget.onAcceptRestSuggestion,
                      onDismissRestSuggestion:
                          widget.onDismissRestSuggestion,
                      currentRpe: widget.lastSetRpe,
                      currentRir: widget.lastSetRir,
                      onRpeChanged: widget.onRpeChanged,
                      onRirChanged: widget.onRirChanged,
                      lastSetReps:
                          widget.completedSets[currentIdx]?.isNotEmpty ==
                                  true
                              ? widget.completedSets[currentIdx]!.last.reps
                              : null,
                      lastSetTargetReps:
                          widget.completedSets[currentIdx]?.isNotEmpty ==
                                  true
                              ? widget.completedSets[currentIdx]!
                                  .last
                                  .targetReps
                              : null,
                      lastSetWeight:
                          widget.completedSets[currentIdx]?.isNotEmpty ==
                                  true
                              ? widget.completedSets[currentIdx]!
                                  .last
                                  .weight
                              : null,
                      onAskAICoach: widget.onAiChipTapped,
                      coachPersona: widget.coachPersona,
                    ),
                  ),
                ),

              // Fatigue alert modal
              if (widget.showFatigueAlert &&
                  widget.fatigueAlertData != null &&
                  currentExercise != null)
                Positioned.fill(
                  child: FatigueAlertModal(
                    alertData: widget.fatigueAlertData!,
                    currentWeight: currentWeight,
                    exerciseName: currentExercise.name,
                    onAcceptSuggestion: widget.onAcceptFatigueSuggestion,
                    onContinueAsPlanned: widget.onDismissFatigueAlert,
                    onStopExercise: widget.onStopExercise,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
