import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/providers/ble_heart_rate_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/hydration.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../data/models/rest_suggestion.dart';
import '../../../core/services/weight_suggestion_service.dart' show WeightSuggestion;
import '../../../data/services/ble_heart_rate_service.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/heart_rate_display.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../controllers/workout_timer_controller.dart';
import '../foldable/foldable_workout_layout.dart';
import '../models/workout_state.dart';
import '../widgets/action_chips_row.dart';
import '../widgets/ai_text_input_bar.dart';
import '../widgets/barbell_plate_indicator.dart';
import '../widgets/exercise_options_sheet.dart' show RepProgressionType, RepProgressionTypeExtension;
import '../widgets/exercise_thumbnail_strip_v2.dart';
import '../widgets/breathing_guide_sheet.dart';
import '../widgets/exercise_info_sheet.dart';
import '../widgets/fatigue_alert_modal.dart';
import '../widgets/hydration_quick_actions.dart';
import '../widgets/rest_timer_overlay.dart';
import '../widgets/set_tracking_overlay.dart';
import '../widgets/set_tracking_table.dart';
import '../widgets/workout_bottom_bar.dart';
import '../widgets/workout_top_bar_v2.dart';
import '../widgets/workout_top_overlay.dart';
import '../../../core/providers/window_mode_provider.dart';
import '../../../core/models/set_progression.dart';

part 'workout_ui_builders_mixin_part_drag_action_zone.dart';

part 'workout_ui_builders_mixin_ui_1.dart';
part 'workout_ui_builders_mixin_ui_2.dart';


/// Mixin providing all `Widget _build*()` UI builder methods for the active
/// workout screen.
///
/// Follows the same pattern as [TimerRestMixin]: abstract getters for state,
/// public method names, `mixin XxxMixin<T extends StatefulWidget> on State<T>`.
mixin WorkoutUIBuildersMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  WorkoutTimerController get timerController;
  List<WorkoutExercise> get exercises;

  set exercises(List<WorkoutExercise> value);
  int get currentExerciseIndex;
  set currentExerciseIndex(int value);
  int get viewingExerciseIndex;
  set viewingExerciseIndex(int value);
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, List<Map<String, dynamic>>> get previousSets;
  Map<int, RepProgressionType> get repProgressionPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  Map<int, String> get exerciseBarType;
  Map<String, double> get exerciseMaxWeights;
  List<Map<String, dynamic>> get restIntervals;
  TextEditingController get weightController;
  TextEditingController get repsController;
  TextEditingController get repsRightController;

  bool get useKg;
  double get weightIncrement;
  set weightIncrement(double value);
  bool get isResting;
  set isResting(bool value);
  bool get isRestingBetweenExercises;
  set isRestingBetweenExercises(bool value);
  String get currentRestMessage;
  bool get isPaused;
  bool get showInlineRest;
  int get inlineRestDuration;
  String? get inlineRestAiTip;
  bool get isLoadingAiTip;
  String? get inlineRestAchievementPrompt;
  int? get inlineRestCurrentRpe;
  int? get lastSetRpe;
  set lastSetRpe(int? value);
  int? get lastSetRir;
  set lastSetRir(int? value);
  WeightSuggestion? get currentWeightSuggestion;
  bool get isLoadingWeightSuggestion;
  RestSuggestion? get restSuggestion;
  bool get isLoadingRestSuggestion;
  FatigueAlertData? get fatigueAlertData;
  bool get showFatigueAlert;
  bool get showCoachTip;
  set showCoachTip(bool value);
  String? get coachTipMessage;

  VideoPlayerController? get videoController;
  bool get isVideoInitialized;
  bool get isVideoPlaying;
  String? get imageUrl;
  bool get isLoadingMedia;

  bool get isLeftRightMode;
  bool get isDoneButtonPressed;
  set isDoneButtonPressed(bool value);
  int? get justCompletedSetIndex;

  // State specific to UI builders (not in other mixins)
  bool get showInstructions;
  set showInstructions(bool value);
  bool get hideAICoachForSession;
  set hideAICoachForSession(bool value);
  bool get isWarmupLoading;
  List<WarmupExerciseData>? get warmupExercises;
  List<StretchExerciseData>? get stretchExercises;
  bool get useV2Design;
  int get exerciseInfoOpened;
  set exerciseInfoOpened(int value);
  int get breathingGuideOpened;
  set breathingGuideOpened(int value);
  bool get isActiveRowExpanded;
  set isActiveRowExpanded(bool value);
  bool get isDragActive;
  set isDragActive(bool value);
  int? get draggedExerciseIndex;
  set draggedExerciseIndex(int? value);

  dynamic get workoutWidget;

  // Cross-mixin method access
  void showQuitDialog();
  void togglePause();
  void skipExercise();
  void handleWarmupComplete();
  void handleSkipWarmup();
  void handleStretchComplete();
  void handleSkipStretch();
  void goBackToWarmup();
  void minimizeWorkout();
  void initControllersForExercise(int exerciseIndex);
  bool isExerciseCompleted(int exerciseIndex);
  Future<void> completeSet();
  void handleSetCompletedV2(int setIndex);
  void updateCompletedSet(int setIndex, double weight, int reps);
  void deleteCompletedSet(int setIndex);
  void quickCompleteSet(int setIndex, bool complete);
  void editCompletedSet(int setIndex);
  void toggleUnit();
  void showRirPicker(int setIndex, int? currentRir);
  void handleChipTapped(String chipId);
  void showExerciseDetailsSheet(WorkoutExercise exercise);
  void showExerciseOptionsSheet(int exerciseIndex);
  void showExerciseAddSheetImpl();
  Future<void> showSwapSheetForIndex(int index);
  void showWorkoutPlanDrawer();
  void showNotesSheet(WorkoutExercise exercise);
  // showExerciseInfoSheet is a top-level function from exercise_info_sheet.dart
  void showBarTypeSelectorImpl(WorkoutExercise exercise);
  void showProgressionSheetImpl();
  void confirmDeleteExercise(int index);
  void onExercisesReordered(int oldIndex, int newIndex);
  void onSupersetFromDrag(int sourceIndex, int targetIndex);
  void acceptWeightSuggestion(double newWeight);
  void dismissWeightSuggestion();
  void acceptRestSuggestion(int seconds);
  void dismissRestSuggestion();
  void handleAcceptFatigueSuggestion();
  void handleDismissFatigueAlert();
  Future<void> handleParsedExercises(List<ParsedExercise> exercises);
  Widget buildInlineRestRowV2();
  void handleInlineRestComplete();
  void handleInlineRestSkip();
  void handleInlineRestTimeAdjust(int adjustment);
  void handleInlineRestRpeRating(int rpe);
  void handleInlineRestNote(String note);
  Future<void> fetchMediaForExercise(WorkoutExercise exercise);
  Future<void> saveWeightUnitPreference(String unit);
  void precomputeSupersetIndices();
  Map<String, dynamic>? getLastSessionData(int exerciseIndex);
  Map<String, dynamic>? getPrData(int exerciseIndex);

  // Private helpers that remain in the main class (declared abstract here)
  void handleVideoAreaTap();
  void toggleVideoPlayPause();
  void showAICoachSheet(WorkoutExercise exercise);
  void showLog1RMSheet(WorkoutExercise exercise);
  Future<void> showHydrationDialogImpl([DrinkType initialType = DrinkType.water]);
  void showBreathingGuideImpl(WorkoutExercise exercise);
  void showNumberInputDialogImpl(TextEditingController controller, bool isDecimal);
  void showProgressionPicker(int exerciseIndex);
  void handleWarmupIntervalsLogged(Map<String, List<WarmupInterval>> logs);
  void handleV2Parsed(ParseWorkoutInputV2Response response);
  Future<void> toggleFavoriteExercise();
  void showHideCoachDialog();
  String formatDuration(int seconds);
  List<SetRowData> buildSetRowsForExercise(int exerciseIndex);
  Set<int> getCompletedExerciseIndices();
  List<ActionChipData> buildActionChipsForCurrentExercise();


  /// Build foldable-optimized active workout layout.
  Widget buildFoldableActiveWorkout(WindowModeState windowState) {
    final setRows = buildSetRowsForExercise(viewingExerciseIndex);
    final completedExerciseIndices = getCompletedExerciseIndices();
    final currentExercise = exercises[currentExerciseIndex];

    return FoldableWorkoutLayout(
      windowState: windowState,
      exercises: exercises,
      currentExerciseIndex: currentExerciseIndex,
      viewingExerciseIndex: viewingExerciseIndex,
      completedExerciseIndices: completedExerciseIndices,
      completedSets: completedSets,
      totalSetsPerExercise: totalSetsPerExercise,
      videoController: videoController,
      isVideoInitialized: isVideoInitialized,
      imageUrl: imageUrl,
      workoutSeconds: timerController.workoutSeconds,
      restSecondsRemaining: timerController.restSecondsRemaining,
      initialRestDuration: timerController.initialRestDuration,
      isPaused: isPaused,
      isResting: isResting,
      isRestingBetweenExercises: isRestingBetweenExercises,
      currentRestMessage: currentRestMessage,
      setRows: setRows,
      useKg: useKg,
      weightController: weightController,
      repsController: repsController,
      repsRightController: isLeftRightMode ? repsRightController : null,
      isLeftRightMode: isLeftRightMode,
      isExerciseCompleted: isExerciseCompleted(viewingExerciseIndex),
      showInlineRest: showInlineRest,
      inlineRestRowWidget: buildInlineRestRowV2(),
      lastSetRpe: lastSetRpe,
      lastSetRir: lastSetRir,
      currentWeightSuggestion: currentWeightSuggestion,
      isLoadingWeightSuggestion: isLoadingWeightSuggestion,
      restSuggestion: restSuggestion,
      isLoadingRestSuggestion: isLoadingRestSuggestion,
      fatigueAlertData: fatigueAlertData,
      showFatigueAlert: showFatigueAlert,
      coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
      workoutId: (workoutWidget as dynamic).workout.id ?? '',
      actionChips: buildActionChipsForCurrentExercise()
          .where((chip) => chip.label != 'Video' && chip.label != 'Info')
          .toList(),
      hideAICoachForSession: hideAICoachForSession,
      onExerciseTap: (index) {
        HapticFeedback.selectionClick();
        setState(() {
          viewingExerciseIndex = index;
          currentExerciseIndex = index;
        });
        initControllersForExercise(index);
      },
      onAddExercise: showExerciseAddSheetImpl,
      onQuitRequested: showQuitDialog,
      onReorder: onExercisesReordered,
      onCreateSuperset: onSupersetFromDrag,
      onVideoTap: toggleVideoPlayPause,
      onInfoTap: () => showExerciseDetailsSheet(exercises[viewingExerciseIndex]),
      onSetCompleted: handleSetCompletedV2,
      onSetUpdated: updateCompletedSet,
      onAddSet: () => setState(() {
        totalSetsPerExercise[viewingExerciseIndex] =
            (totalSetsPerExercise[viewingExerciseIndex] ?? 3) + 1;
      }),
      onSetDeleted: (index) => deleteCompletedSet(index),
      onToggleUnit: toggleUnit,
      onRirTapped: (setIndex, currentRir) => showRirPicker(setIndex, currentRir),
      onActiveRirChanged: (rir) => setState(() => lastSetRir = rir),
      onSelectAllTapped: () {
        if (isExerciseCompleted(viewingExerciseIndex)) {
          HapticFeedback.lightImpact();
        }
      },
      onChipTapped: handleChipTapped,
      onAiChipTapped: () => showAICoachSheet(currentExercise),
      onSkipRest: () => timerController.skipRest(),
      onLog1RM: () => showLog1RMSheet(currentExercise),
      onAcceptWeightSuggestion: acceptWeightSuggestion,
      onDismissWeightSuggestion: dismissWeightSuggestion,
      onAcceptRestSuggestion: acceptRestSuggestion,
      onDismissRestSuggestion: dismissRestSuggestion,
      onRpeChanged: (rpe) => setState(() => lastSetRpe = rpe),
      onRirChanged: (rir) => setState(() => lastSetRir = rir),
      onAcceptFatigueSuggestion: handleAcceptFatigueSuggestion,
      onDismissFatigueAlert: handleDismissFatigueAlert,
      onStopExercise: skipExercise,
      onExercisesParsed: (exercises) => handleParsedExercises(exercises),
      onV2Parsed: (response) => handleV2Parsed(response),
    );
  }

  /// Build simple solid media background.
  Widget buildMediaBackground() {
    // Simple solid background - no video/GIF in background to keep UI clean
    // User can tap "Instructions" button to see exercise video on-demand
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.pureBlack : Colors.grey.shade100,
    );
  }

  /// Landscape video player - uses already-loaded video from state.
  Widget buildLandscapeVideoPlayer(bool isDark) {
    final exercise = exercises[viewingExerciseIndex];
    final backgroundColor = isDark ? AppColors.surface : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Center the media content with proper aspect ratio
            Positioned.fill(
              child: Center(
                child: buildLandscapeMediaContent(exercise, isDark),
              ),
            ),

            // Tap overlay for pausing video / opening full screen
            if (isVideoInitialized && videoController != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: toggleVideoPlayPause,
                  behavior: HitTestBehavior.translucent,
                  child: AnimatedOpacity(
                    opacity: !isVideoPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Exercise name overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the media content (video or image) with proper aspect ratio.
  Widget buildLandscapeMediaContent(dynamic exercise, bool isDark) {
    // Priority 1: Show video if initialized
    if (isVideoInitialized && videoController != null) {
      return AspectRatio(
        aspectRatio: videoController!.value.aspectRatio,
        child: VideoPlayer(videoController!),
      );
    }

    // Priority 2: Show loaded image/GIF with natural aspect ratio
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain, // Maintain aspect ratio
        errorBuilder: (_, __, ___) => buildVideoPlaceholder(exercise, isDark),
      );
    }

    // Priority 3: Show loading indicator
    if (isLoadingMedia) {
      return CircularProgressIndicator(
        color: isDark ? Colors.white70 : Colors.black54,
        strokeWidth: 2,
      );
    }

    // Priority 4: Show placeholder
    return buildVideoPlaceholder(exercise, isDark);
  }

  /// Build a placeholder widget for exercises without video.
  Widget buildVideoPlaceholder(dynamic exercise, bool isDark) {
    return Container(
      color: isDark ? AppColors.surface : Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape thumbnail strip - reuses the same component as portrait.
  Widget buildLandscapeThumbnailStrip({
    required bool isDark,
    required Set<int> completedExerciseIndices,
    required Color accentColor,
  }) {
    // Reuse the same ExerciseThumbnailStripV2 component for consistent behavior
    // This ensures thumbnails load correctly from API/cache
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: ExerciseThumbnailStripV2(
        key: ValueKey('thumb_strip_landscape_${exercises.map((e) => e.id ?? e.name).join('_')}'),
        exercises: exercises.toList(), // Create new list instance
        currentIndex: viewingExerciseIndex,
        completedExercises: completedExerciseIndices,
        onExerciseTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            viewingExerciseIndex = index;
            currentExerciseIndex = index;
          });
          initControllersForExercise(index);
          fetchMediaForExercise(exercises[index]);
        },
        onAddTap: () => showExerciseAddSheetImpl(),
        showAddButton: true,
        onReorder: onExercisesReordered,
        onCreateSuperset: onSupersetFromDrag,
      ),
    );
  }

  /// Landscape top bar - compact with all info in one row.
  Widget buildLandscapeTopBar({
    required bool isDark,
    required Color accentColor,
  }) {
    final exercise = exercises[viewingExerciseIndex];
    final completedSetsCount = completedSets[viewingExerciseIndex]?.length ?? 0;
    final totalSets = totalSetsPerExercise[viewingExerciseIndex] ?? 3;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, size: 20, color: textPrimary),
            onPressed: handleBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Timer (uses direct getter, UI rebuilds via setState from timer callback)
          // Wrapped in RepaintBoundary to isolate per-second timer repaints
          RepaintBoundary(
            child: Text(
              formatDuration(timerController.workoutSeconds),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Exercise name (truncated)
          Expanded(
            child: Text(
              exercise.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Set counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Set ${completedSetsCount + 1}/$totalSets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Pause/Play button
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              size: 20,
              color: textSecondary,
            ),
            onPressed: togglePause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Close button
          IconButton(
            icon: Icon(Icons.close, size: 20, color: textSecondary),
            onPressed: showQuitDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // Cross-mixin reference
  void handleBack();

  /// Landscape action chips - wrapped layout, no Video chip.
  Widget buildLandscapeActions({
    required bool isDark,
    required Color accentColor,
  }) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final chipBackground = isDark ? AppColors.surface : Colors.grey.shade100;

    // Filter out Video chip - it's always visible in left panel
    final landscapeChips = buildActionChipsForCurrentExercise()
        .where((chip) => chip.label != 'Video')
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(top: BorderSide(color: cardBorder)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          // Action chips
          ...landscapeChips.map((chip) => buildLandscapeMiniChip(
                icon: chip.icon,
                label: chip.label,
                onTap: () => handleChipTapped(chip.id),
                isDark: isDark,
                chipBackground: chipBackground,
                textColor: textSecondary,
              )),
          // Quick actions
          buildLandscapeMiniChip(
            icon: Icons.water_drop,
            label: 'Drink',
            onTap: showHydrationDialogImpl,
            isDark: isDark,
            chipBackground: chipBackground,
            textColor: AppColors.quickActionWater,
            iconColor: AppColors.quickActionWater,
          ),
          buildLandscapeMiniChip(
            icon: Icons.sticky_note_2_outlined,
            label: 'Note',
            onTap: () => showNotesSheet(exercises[viewingExerciseIndex]),
            isDark: isDark,
            chipBackground: chipBackground,
            textColor: const Color(0xFFF59E0B),
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  /// Build a compact mini chip for landscape action bar.
  Widget buildLandscapeMiniChip({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color chipBackground,
    required Color textColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the drag-to-action overlay zones (Delete + Swap).
  /// Shown at the top of the screen when the user long-press-drags a thumbnail.
  Widget buildDragActionZones(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                // Delete zone
                Expanded(
                  child: _DragActionZone(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    isDark: isDark,
                    onAccept: (draggedIndex) {
                      setState(() {
                        isDragActive = false;
                        draggedExerciseIndex = null;
                      });
                      confirmDeleteExercise(draggedIndex);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Swap zone
                Expanded(
                  child: _DragActionZone(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Swap',
                    color: AppColors.orange,
                    isDark: isDark,
                    onAccept: (draggedIndex) {
                      setState(() {
                        isDragActive = false;
                        draggedExerciseIndex = null;
                      });
                      if (draggedIndex < exercises.length) {
                        showSwapSheetForIndex(draggedIndex);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a numbered instruction row for superset creation guide.
  Widget buildInstructionRow({
    required bool isDark,
    required String step,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Build a simple info sheet widget.
  Widget buildInfoSheet({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? WorkoutDesign.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Build the workout completion screen (brief saving state).
  Widget buildCompletionScreen(bool isDark, Color backgroundColor) {
    // This shows briefly while saving to backend before navigating to WorkoutCompleteScreen
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 80,
                color: ref.watch(accentColorProvider).getColor(isDark),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms)
                  .then()
                  .shake(duration: 300.ms),
              const SizedBox(height: 24),
              Text(
                'Saving workout...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ref.watch(accentColorProvider).getColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build floating AI Coach FAB - always visible above bottom bar.
  /// Long press to hide for this session.
  Widget buildFloatingAICoachButton(WorkoutExercise currentExercise) {
    // Use ref.watch to reactively update when coach changes
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = aiSettings.getCurrentCoach();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        showHideCoachDialog();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CoachAvatar(
            coach: coach,
            size: 56,
            showBorder: true,
            borderWidth: 3,
            showShadow: true,
            enableTapToView: false,
            onTap: () {
              setState(() => showCoachTip = false);
              showAICoachSheet(currentExercise);
            },
          ),
          // Notification badge
          if (showCoachTip)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppColors.pureBlack : Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          // Coach tip bubble (Messenger-style, positioned above avatar)
          if (showCoachTip && coachTipMessage != null)
            Positioned(
              bottom: 64, // Above the 56px avatar + 8px gap
              right: 0,
              child: GestureDetector(
                onTap: () => setState(() => showCoachTip = false),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.elevated : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    coachTipMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
