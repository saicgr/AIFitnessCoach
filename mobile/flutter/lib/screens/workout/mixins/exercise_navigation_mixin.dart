import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../core/providers/tts_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../widgets/barbell_plate_indicator.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../models/workout_state.dart';
import '../widgets/exercise_options_sheet.dart' as options_sheet;
import '../widgets/exercise_options_sheet.dart' show RepProgressionType;
import '../widgets/exercise_analytics_page.dart';
import '../widgets/exercise_info_sheet.dart';
import '../widgets/parsed_exercises_preview_sheet.dart';
import '../widgets/superset_pair_sheet.dart';
import '../widgets/workout_plan_drawer.dart' as plan_drawer;

part 'exercise_navigation_mixin_ui.dart';


/// Mixin providing exercise navigation, reordering, and superset management.
mixin ExerciseNavigationMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
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
  Map<int, double> get exerciseWorkingWeight;
  Map<String, double> get exerciseMaxWeights;
  Map<int, int> get exerciseTimeSeconds;
  DateTime? get currentExerciseStartTime;
  set currentExerciseStartTime(DateTime? value);
  DateTime? get currentSetStartTime;
  set currentSetStartTime(DateTime? value);
  bool get useKg;
  bool get isResting;
  set isResting(bool value);
  bool get showInlineRest;
  set showInlineRest(bool value);
  WorkoutPhase get currentPhase;
  set currentPhase(WorkoutPhase value);
  Map<int, Set<int>> get supersetRoundProgress;
  Map<int, List<int>> get supersetIndicesCache;
  set supersetIndicesCache(Map<int, List<int>> value);
  Set<int> get skippedExercises;

  // Widget access
  dynamic get workoutWidget; // Widget with workout property

  // Cross-mixin method access
  void initControllersForExercise(int exerciseIndex);
  Future<void> fetchMediaForExercise(WorkoutExercise exercise);
  void showCoachTipIfNeeded();
  void startRest(bool betweenExercises, {Duration? overrideDuration});
  void handleStretchComplete();
  void updateWorkoutNotification();
  Future<void> fetchSmartWeightForExercise(WorkoutExercise exercise);
  bool isExerciseCompleted(int exerciseIndex) {
    final completedCount = completedSets[exerciseIndex]?.length ?? 0;
    final totalSets = totalSetsPerExercise[exerciseIndex] ?? 3;
    return completedCount >= totalSets;
  }
  void precomputeSupersetIndicesImpl();
  void showSwapSheetForIndex(int index);
  void showExerciseAddSheetImpl();
  void showQuitDialogImpl();
  void goBackToWarmup();
  Map<String, dynamic>? getLastSessionData(int exerciseIndex);
  Map<String, dynamic>? getPrData(int exerciseIndex);
  void removeExerciseAndDontRecommend(int index, WorkoutExercise exercise) {
    final apiClient = ref.read(apiClientProvider);
    apiClient.getUserId().then((userId) {
      if (userId != null) {
        apiClient.post('/exercises/dont-recommend', data: {
          'user_id': userId,
          'exercise_name': exercise.name,
          'exercise_id': exercise.exerciseId ?? exercise.libraryId,
        }).catchError((e) {
          debugPrint('⚠️ Failed to mark exercise as not recommended: $e');
        });
      }
    });
  }

  // ── Exercise Navigation Methods ──

  /// Move to the next incomplete exercise
  void moveToNextExercise() async {
    ref.read(posthogServiceProvider).capture(
      eventName: 'exercise_completed',
      properties: {
        'exercise_name': exercises[currentExerciseIndex].name,
        'exercise_index': currentExerciseIndex,
      },
    );

    if (currentExerciseStartTime != null) {
      exerciseTimeSeconds[currentExerciseIndex] =
          DateTime.now().difference(currentExerciseStartTime!).inSeconds;
    }

    int? nextIndex;
    for (int i = 1; i <= exercises.length; i++) {
      final candidateIndex = (currentExerciseIndex + i) % exercises.length;
      if (!isExerciseCompleted(candidateIndex) && !skippedExercises.contains(candidateIndex)) {
        nextIndex = candidateIndex;
        break;
      }
    }

    if (nextIndex != null) {
      HapticService.exerciseTransition();

      final nextExercise = exercises[nextIndex];

      ref.read(voiceAnnouncementsProvider.notifier)
          .announceNextExerciseIfEnabled(nextExercise.name);

      setState(() {
        currentExerciseIndex = nextIndex!;
        viewingExerciseIndex = nextIndex;
      });

      updateWorkoutNotification();
      initControllersForExercise(nextIndex);
      fetchSmartWeightForExercise(nextExercise);
      fetchMediaForExercise(nextExercise);
      showCoachTipIfNeeded();
      startRest(true);

      currentExerciseStartTime = DateTime.now();
      currentSetStartTime = DateTime.now(); // First set of new exercise
    } else {
      // All exercises completed or skipped — check for incomplete logs
      final shouldContinue = await _showIncompleteExercisesDialog();
      if (!shouldContinue) {
        // User cancelled — un-skip the current exercise so they stay on it
        skippedExercises.remove(currentExerciseIndex);
        return;
      }

      HapticService.workoutComplete();

      ref.read(voiceAnnouncementsProvider.notifier).announceWorkoutCompleteIfEnabled();

      final stretchEnabled = ref.read(warmupDurationProvider).stretchEnabled;
      if (stretchEnabled) {
        setState(() {
          currentPhase = WorkoutPhase.stretch;
        });
      } else {
        debugPrint('🏋️ [ActiveWorkout] Stretch disabled, skipping to completion');
        handleStretchComplete();
      }
    }
  }

  /// Skip the current exercise
  void skipExercise() {
    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_exercise_skipped',
      properties: {
        'exercise_name': exercises[currentExerciseIndex].name,
        'exercise_index': currentExerciseIndex,
      },
    );
    skippedExercises.add(currentExerciseIndex);
    moveToNextExercise();
  }

  static const _kSkipWarningDismissedKey = 'skip_incomplete_warning_dismissed';

  /// Check if any exercises have incomplete or missing logs
  List<_ExerciseLogStatus> _getExerciseLogStatuses() {
    final statuses = <_ExerciseLogStatus>[];
    for (int i = 0; i < exercises.length; i++) {
      final logged = completedSets[i]?.length ?? 0;
      final total = totalSetsPerExercise[i] ?? 3;
      statuses.add(_ExerciseLogStatus(
        name: exercises[i].name,
        loggedSets: logged,
        totalSets: total,
      ));
    }
    return statuses;
  }

  /// Show dialog listing incomplete exercises before finishing workout.
  /// Returns true if user wants to continue, false to cancel.
  Future<bool> _showIncompleteExercisesDialog() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSkipWarningDismissedKey) == true) return true;

    final statuses = _getExerciseLogStatuses();
    final hasIncomplete = statuses.any((s) => s.loggedSets < s.totalSets);
    if (!hasIncomplete) return true;

    if (!mounted) return false;

    bool dontShowAgain = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.read(accentColorProvider).getColor(isDark);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Text('Incomplete Exercises', style: TextStyle(fontSize: 18))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Some exercises have missing logs:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: statuses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final s = statuses[i];
                      final isComplete = s.loggedSets >= s.totalSets;
                      final isPartial = s.loggedSets > 0 && s.loggedSets < s.totalSets;
                      return Row(
                        children: [
                          Icon(
                            isComplete
                                ? Icons.check_circle
                                : isPartial
                                    ? Icons.remove_circle
                                    : Icons.cancel,
                            size: 18,
                            color: isComplete
                                ? Colors.green
                                : isPartial
                                    ? Colors.orange
                                    : Colors.red.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isComplete ? FontWeight.normal : FontWeight.w600,
                                color: isComplete
                                    ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${s.loggedSets}/${s.totalSets}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isComplete
                                  ? Colors.green
                                  : isPartial
                                      ? Colors.orange
                                      : Colors.red.shade400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setDialogState(() => dontShowAgain = !dontShowAgain),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: dontShowAgain,
                          onChanged: (v) => setDialogState(() => dontShowAgain = v ?? false),
                          activeColor: accentColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Do not show again',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Continue anyway'),
            ),
          ],
        ),
      ),
    );

    if (dontShowAgain && result == true) {
      prefs.setBool(_kSkipWarningDismissedKey, true);
    }

    return result ?? false;
  }

  /// Handle back button press
  void handleBack() {
    final warmupEnabled = ref.read(warmupDurationProvider).warmupEnabled;
    if (warmupEnabled) {
      goBackToWarmup();
    } else {
      showQuitDialogImpl();
    }
  }

  /// Handle chip tapped from action chips row
  void handleChipTapped(String chipId) {
    HapticFeedback.selectionClick();
    final currentExercise = exercises[viewingExerciseIndex];

    switch (chipId) {
      case 'info':
        showExerciseDetailsSheet(currentExercise);
        break;
      case 'warmup':
        showWarmupSheet(currentExercise);
        break;
      case 'targets':
        showTargetsSheet(currentExercise);
        break;
      case 'swap':
        showSwapSheetForIndex(viewingExerciseIndex);
        break;
      case 'note':
        showNotesSheet(currentExercise);
        break;
      case 'superset':
        showSupersetSheet();
        break;
      case 'video':
        showExerciseInfoSheet(
          context: context,
          exercise: currentExercise,
        );
        break;
      case 'history':
        showHistorySheet(currentExercise);
        break;
      case 'skip':
        skipExercise();
        break;
      case 'lr':
        toggleLeftRightMode();
        break;
      case 'increments':
      case 'increments_display':
        showWeightIncrementsSheetImpl();
        break;
      case 'equipment':
        showEquipmentProfileSheetImpl();
        break;
      case 'progression':
        showProgressionSheetImpl();
        break;
      case 'reorder':
        showWorkoutPlanDrawer();
        break;
      case 'more':
        showMoreMenu(currentExercise);
        break;
    }
  }

  // These methods need to be provided by the main class
  void showExerciseDetailsSheet(WorkoutExercise exercise);
  void showWarmupSheet(WorkoutExercise exercise);
  void showTargetsSheet(WorkoutExercise exercise);
  void showNotesSheet(WorkoutExercise exercise);
  void showSupersetSheet();
  void showHistorySheet(WorkoutExercise exercise);
  void toggleLeftRightMode();
  void showWeightIncrementsSheetImpl();
  void showEquipmentProfileSheetImpl();
  void showProgressionSheetImpl();
  void showBarTypeSelectorImpl(WorkoutExercise exercise);

  /// Confirm and delete an exercise from the workout
  void confirmDeleteExercise(int index) {
    if (index >= exercises.length) return;
    final exercise = exercises[index];

    if (exercises.length <= 1) {
      showQuitDialogImpl();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Remove "${exercise.name}" from this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              setState(() {
                exercises.removeAt(index);
                if (viewingExerciseIndex >= exercises.length) {
                  viewingExerciseIndex = exercises.length - 1;
                }
                if (currentExerciseIndex >= exercises.length) {
                  currentExerciseIndex = exercises.length - 1;
                }
                initControllersForExercise(viewingExerciseIndex);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${exercise.name} removed'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Show exercise options sheet
  void showExerciseOptionsSheet(int exerciseIndex) {
    if (exerciseIndex >= exercises.length) return;

    final exercise = exercises[exerciseIndex];
    final currentProgression = repProgressionPerExercise[exerciseIndex] ?? RepProgressionType.straight;

    options_sheet.showExerciseOptionsSheet(
      context: context,
      exercise: exercise,
      currentProgression: currentProgression,
      onProgressionChanged: (newProgression) {
        setState(() {
          repProgressionPerExercise[exerciseIndex] = newProgression;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changed to ${newProgression.displayName}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReplace: () {
        Navigator.pop(context);
        showSwapSheetForIndex(exerciseIndex);
      },
      onViewHistory: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseAnalyticsPage(
              exercise: exercise,
              useKg: useKg,
              lastSessionData: getLastSessionData(exerciseIndex),
              prData: getPrData(exerciseIndex),
            ),
          ),
        );
      },
      onViewInstructions: () {
        showExerciseInfoSheet(
          context: context,
          exercise: exercise,
        );
      },
      onAddNotes: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use the notes section below the sets'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onRemoveFromWorkout: () {
        removeExerciseFromWorkout(exerciseIndex);
      },
      onAddToSuperset: () async {
        HapticFeedback.lightImpact();
        final result = await showSupersetPairSheet(
          context, ref,
          workoutExercises: exercises,
          preselectedExercise: exercise,
        );
        if (result != null && mounted) {
          setState(() {
            precomputeSupersetIndicesImpl();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Superset: ${result.exercise1.name} + ${result.exercise2.name}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onRemoveAndDontRecommend: () {
        removeExerciseFromWorkout(exerciseIndex);
        removeExerciseAndDontRecommend(exerciseIndex, exercise);
      },
      onChangeEquipment: (exercise.equipment != null &&
              exercise.equipment!.isNotEmpty &&
              !exercise.equipment!.toLowerCase().contains('bodyweight') &&
              !exercise.equipment!.toLowerCase().contains('body weight') &&
              exercise.equipment!.toLowerCase() != 'none')
          ? () {
              showEquipmentProfileSheetImpl();
            }
          : null,
    );
  }

  /// Show workout plan drawer with reorderable exercises
  void showWorkoutPlanDrawer() {
    plan_drawer.showWorkoutPlanDrawer(
      context: context,
      exercises: exercises,
      currentExerciseIndex: currentExerciseIndex,
      completedSetsPerExercise: completedSets.map(
        (key, value) => MapEntry(key, value.length),
      ),
      totalSetsPerExercise: totalSetsPerExercise,
      onJumpToExercise: (index) {
        setState(() {
          viewingExerciseIndex = index;
        });
      },
      onReorder: (reorderedExercises) {
        setState(() {
          exercises = List.from(reorderedExercises);
          precomputeSupersetIndicesImpl();
        });
      },
      onSwapExercise: (index) => showSwapSheetForIndex(index),
      onDeleteExercise: (index) {
        setState(() {
          exercises.removeAt(index);
          precomputeSupersetIndicesImpl();

          completedSets.remove(index);
          totalSetsPerExercise.remove(index);
          previousSets.remove(index);

          final newCompletedSets = <int, List<SetLog>>{};
          final newTotalSets = <int, int>{};
          final newPreviousSets = <int, List<Map<String, dynamic>>>{};

          completedSets.forEach((key, value) {
            if (key > index) {
              newCompletedSets[key - 1] = value;
            } else {
              newCompletedSets[key] = value;
            }
          });

          totalSetsPerExercise.forEach((key, value) {
            if (key > index) {
              newTotalSets[key - 1] = value;
            } else {
              newTotalSets[key] = value;
            }
          });

          previousSets.forEach((key, value) {
            if (key > index) {
              newPreviousSets[key - 1] = value;
            } else {
              newPreviousSets[key] = value;
            }
          });

          completedSets
            ..clear()
            ..addAll(newCompletedSets);
          totalSetsPerExercise
            ..clear()
            ..addAll(newTotalSets);
          previousSets
            ..clear()
            ..addAll(newPreviousSets);

          if (currentExerciseIndex >= exercises.length) {
            currentExerciseIndex = exercises.length - 1;
          }
          if (viewingExerciseIndex >= exercises.length) {
            viewingExerciseIndex = exercises.length - 1;
          }
        });
      },
      onAddExercise: () => showExerciseAddSheetImpl(),
    );
  }

  /// Handle parsed exercises from the AI text input bar
  Future<void> handleParsedExercises(List<ParsedExercise> parsedExercises) async {
    if (parsedExercises.isEmpty) return;

    final confirmedExercises = await showParsedExercisesPreview(
      context,
      ref,
      exercises: parsedExercises,
      useKg: useKg,
    );

    if (confirmedExercises == null || confirmedExercises.isEmpty || !mounted) {
      return;
    }

    try {
      if (!mounted) return;
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null || !mounted) return;

      final repo = ref.read(workoutRepositoryProvider);
      final workoutId = (workoutWidget as dynamic).workout.id ?? '';
      final updatedWorkout = await repo.addExercisesBatch(
        workoutId: workoutId,
        userId: userId,
        exercises: confirmedExercises,
        useKg: useKg,
      );

      if (updatedWorkout != null && mounted) {
        final newExercises = updatedWorkout.exercises;
        final addedCount = confirmedExercises.length;
        final startIndex = exercises.length;

        setState(() {
          exercises = List.from(newExercises);
          precomputeSupersetIndicesImpl();

          for (int i = startIndex; i < exercises.length; i++) {
            completedSets[i] = [];
            final ex = exercises[i];
            totalSetsPerExercise[i] = ex.hasSetTargets && ex.setTargets!.isNotEmpty
                ? ex.setTargets!.length
                : ex.sets ?? 3;
            previousSets[i] = [];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount exercise${addedCount == 1 ? '' : 's'}'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        debugPrint('✅ [Workout] Added $addedCount exercises via AI input');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to add exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add exercises: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Add exercises from AI input
  Future<void> addExercisesFromAI(List<ExerciseToAdd> exercisesToAdd) async {
    if (exercisesToAdd.isEmpty || !mounted) return;

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null || !mounted) return;

      final parsedExercises = exercisesToAdd.map((e) {
        return ParsedExercise(
          name: e.name,
          sets: e.sets,
          reps: e.reps,
          weightKg: e.weightKg,
          weightLbs: e.weightLbs,
          restSeconds: e.restSeconds,
          originalText: e.originalText,
          confidence: e.confidence,
          notes: e.notes,
        );
      }).toList();

      final repo = ref.read(workoutRepositoryProvider);
      final workoutId = (workoutWidget as dynamic).workout.id ?? '';
      final updatedWorkout = await repo.addExercisesBatch(
        workoutId: workoutId,
        userId: userId,
        exercises: parsedExercises,
        useKg: useKg,
      );

      if (updatedWorkout != null && mounted) {
        final newExercises = updatedWorkout.exercises;
        final addedCount = exercisesToAdd.length;
        final startIndex = exercises.length;

        setState(() {
          exercises = List.from(newExercises);
          precomputeSupersetIndicesImpl();

          for (int i = startIndex; i < exercises.length; i++) {
            completedSets[i] = [];
            final ex = exercises[i];
            totalSetsPerExercise[i] = ex.hasSetTargets && ex.setTargets!.isNotEmpty
                ? ex.setTargets!.length
                : ex.sets ?? 3;
            previousSets[i] = [];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount exercise${addedCount == 1 ? '' : 's'}'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        debugPrint('✅ [Workout] Added $addedCount exercises via AI input');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to add exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add exercises: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle exercise reorder from thumbnail strip drag
  void onExercisesReordered(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    debugPrint('🔄 Reordering exercise from $oldIndex to $newIndex');

    final draggedExercise = exercises[oldIndex];
    final supersetGroupId = draggedExercise.supersetGroup;
    bool removedFromSuperset = false;

    final reorderedList = List<WorkoutExercise>.from(exercises);
    var exercise = reorderedList.removeAt(oldIndex);
    reorderedList.insert(newIndex, exercise);

    if (supersetGroupId != null) {
      final otherMemberIndices = <int>[];
      for (int i = 0; i < reorderedList.length; i++) {
        if (i != newIndex && reorderedList[i].supersetGroup == supersetGroupId) {
          otherMemberIndices.add(i);
        }
      }

      if (otherMemberIndices.isNotEmpty) {
        final isAdjacentToGroup = otherMemberIndices.any((i) => (i - newIndex).abs() == 1);

        if (!isAdjacentToGroup) {
          exercise = exercise.copyWith(clearSuperset: true);
          reorderedList[newIndex] = exercise;
          removedFromSuperset = true;

          if (otherMemberIndices.length == 1) {
            final lastMemberIndex = otherMemberIndices.first;
            reorderedList[lastMemberIndex] = reorderedList[lastMemberIndex].copyWith(clearSuperset: true);
          }
        }
      }
    }

    final newCompletedSets = _remapIndexMap(completedSets, oldIndex, newIndex);
    final newTotalSets = _remapIndexMap(totalSetsPerExercise, oldIndex, newIndex);
    final newPreviousSets = _remapIndexMap(previousSets, oldIndex, newIndex);
    final newRepProgression = _remapIndexMap(repProgressionPerExercise, oldIndex, newIndex);

    final newCurrentIndex = remapSingleIndex(currentExerciseIndex, oldIndex, newIndex);
    final newViewingIndex = remapSingleIndex(viewingExerciseIndex, oldIndex, newIndex);

    setState(() {
      exercises = reorderedList;
      precomputeSupersetIndicesImpl();

      completedSets
        ..clear()
        ..addAll(newCompletedSets);
      totalSetsPerExercise
        ..clear()
        ..addAll(newTotalSets);
      previousSets
        ..clear()
        ..addAll(newPreviousSets);
      repProgressionPerExercise
        ..clear()
        ..addAll(newRepProgression);

      currentExerciseIndex = newCurrentIndex;
      viewingExerciseIndex = newViewingIndex;
    });

    if (removedFromSuperset) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${draggedExercise.name} removed from superset'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Helper to remap a map's integer keys after reorder
  Map<int, V> _remapIndexMap<V>(Map<int, V> original, int oldIndex, int newIndex) {
    final result = <int, V>{};
    for (final entry in original.entries) {
      final newKey = remapSingleIndex(entry.key, oldIndex, newIndex);
      result[newKey] = entry.value;
    }
    return result;
  }

  /// Helper to remap a single index after reorder
  int remapSingleIndex(int index, int oldIndex, int newIndex) {
    if (index == oldIndex) {
      return newIndex;
    } else if (oldIndex < newIndex) {
      if (index > oldIndex && index <= newIndex) {
        return index - 1;
      }
    } else {
      if (index >= newIndex && index < oldIndex) {
        return index + 1;
      }
    }
    return index;
  }

  /// Helper to move an exercise to be adjacent to a superset group
  void moveExerciseToSuperset(int fromIndex, int toIndex) {
    if ((fromIndex - toIndex).abs() > 1) {
      final exercise = exercises.removeAt(fromIndex);
      final insertAt = fromIndex > toIndex ? toIndex + 1 : toIndex;
      exercises.insert(insertAt, exercise);
      precomputeSupersetIndicesImpl();

      final oldIdx = fromIndex;
      final newIdx = insertAt;
      if (oldIdx != newIdx) {
        final newCompletedSets = _remapIndexMap(completedSets, oldIdx, newIdx);
        final newTotalSets = _remapIndexMap(totalSetsPerExercise, oldIdx, newIdx);
        final newPreviousSets = _remapIndexMap(previousSets, oldIdx, newIdx);
        final newRepProgression = _remapIndexMap(repProgressionPerExercise, oldIdx, newIdx);

        completedSets
          ..clear()
          ..addAll(newCompletedSets);
        totalSetsPerExercise
          ..clear()
          ..addAll(newTotalSets);
        previousSets
          ..clear()
          ..addAll(newPreviousSets);
        repProgressionPerExercise
          ..clear()
          ..addAll(newRepProgression);

        currentExerciseIndex = remapSingleIndex(currentExerciseIndex, oldIdx, newIdx);
        viewingExerciseIndex = remapSingleIndex(viewingExerciseIndex, oldIdx, newIdx);
      }
    }
  }

  /// Break a superset by clearing superset info from all exercises in the group
  void breakSuperset(int groupId) {
    setState(() {
      for (int i = 0; i < exercises.length; i++) {
        if (exercises[i].supersetGroup == groupId) {
          exercises[i] = exercises[i].copyWith(clearSuperset: true);
        }
      }
    });
    HapticFeedback.mediumImpact();
  }

  // ── Superset helper methods ──

  /// Pre-compute superset indices for all groups.
  void precomputeSupersetIndices() {
    var cache = <int, List<int>>{};
    for (int i = 0; i < exercises.length; i++) {
      final groupId = exercises[i].supersetGroup;
      if (groupId != null) {
        cache.putIfAbsent(groupId, () => <int>[]);
        cache[groupId]!.add(i);
      }
    }
    for (final entry in cache.entries) {
      entry.value.sort((a, b) {
        final orderA = exercises[a].supersetOrder ?? 0;
        final orderB = exercises[b].supersetOrder ?? 0;
        return orderA.compareTo(orderB);
      });
    }
    supersetIndicesCache = cache;
  }

  /// Get all exercise indices in a superset group
  List<int> getSupersetIndices(int groupId) {
    return supersetIndicesCache[groupId] ?? [];
  }

  /// Get the next exercise index in the superset round
  int? getNextSupersetExerciseIndex(int currentIndex, int groupId) {
    final supersetIndices = getSupersetIndices(groupId);
    if (supersetIndices.isEmpty) return null;

    final doneInRound = supersetRoundProgress[groupId] ?? <int>{};

    for (final idx in supersetIndices) {
      if (idx != currentIndex &&
          !doneInRound.contains(idx) &&
          !isExerciseCompleted(idx)) {
        return idx;
      }
    }

    return null;
  }

  /// Mark an exercise as done for the current superset round
  void markSupersetExerciseDoneInRound(int exerciseIndex, int groupId) {
    supersetRoundProgress[groupId] ??= <int>{};
    supersetRoundProgress[groupId]!.add(exerciseIndex);
    debugPrint('🔗 [Superset] Marked exercise $exerciseIndex done in round for group $groupId. Progress: ${supersetRoundProgress[groupId]}');
  }

  /// Reset the superset round progress
  void resetSupersetRound(int groupId) {
    supersetRoundProgress[groupId] = <int>{};
    debugPrint('🔗 [Superset] Reset round progress for group $groupId');
  }

  /// Navigate to the next exercise in the superset (no rest timer)
  void advanceToSupersetExercise(int nextIndex) {
    debugPrint('🔗 [Superset] Auto-advancing to exercise $nextIndex: ${exercises[nextIndex].name}');

    if (currentExerciseStartTime != null) {
      exerciseTimeSeconds[currentExerciseIndex] =
          DateTime.now().difference(currentExerciseStartTime!).inSeconds;
    }

    final nextExercise = exercises[nextIndex];

    HapticFeedback.selectionClick();

    setState(() {
      currentExerciseIndex = nextIndex;
      viewingExerciseIndex = nextIndex;
      isResting = false;
      showInlineRest = false;
    });

    updateWorkoutNotification();
    initControllersForExercise(nextIndex);
    fetchSmartWeightForExercise(nextExercise);
    fetchMediaForExercise(nextExercise);

    currentExerciseStartTime = DateTime.now();
    currentSetStartTime = DateTime.now(); // First set of new exercise

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Superset: ${nextExercise.name}')),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.purple,
      ),
    );
  }
}

/// Simple status for each exercise's logging completeness
class _ExerciseLogStatus {
  final String name;
  final int loggedSets;
  final int totalSets;

  const _ExerciseLogStatus({
    required this.name,
    required this.loggedSets,
    required this.totalSets,
  });
}
