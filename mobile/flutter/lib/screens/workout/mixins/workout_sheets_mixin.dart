import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/providers/exercise_bar_type_provider.dart';
import '../../../core/providers/exercise_progression_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/hydration.dart';
import '../../../data/models/smart_weight_suggestion.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../models/equipment_item.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/log_1rm_sheet.dart';
import '../models/workout_state.dart';
import '../widgets/breathing_guide_sheet.dart';
import '../widgets/barbell_plate_indicator.dart';
import '../widgets/edit_workout_equipment_sheet.dart';
import '../widgets/enhanced_notes_sheet.dart';
import '../widgets/exercise_options_sheet.dart' show RepProgressionType, RepProgressionTypeExtension;
import '../widgets/hydration_dialog.dart';
import '../widgets/workout_ai_coach_sheet.dart';
import '../../../widgets/weight_increments_sheet.dart';

part 'workout_sheets_mixin_ui.dart';


/// Mixin providing sheet/dialog/picker display and utility methods
/// for the active workout screen.
mixin WorkoutSheetsMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  List<WorkoutExercise> get exercises;
  set exercises(List<WorkoutExercise> value);
  int get currentExerciseIndex;
  int get viewingExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, List<Map<String, dynamic>>> get previousSets;
  Map<int, RepProgressionType> get repProgressionPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  Map<int, double> get exerciseWorkingWeight;
  Map<int, String> get exerciseBarType;
  Map<String, double> get exerciseMaxWeights;
  TextEditingController get weightController;
  TextEditingController get repsController;
  TextEditingController get repsRightController;
  bool get useKg;
  set useKg(bool value);
  double get weightIncrement;
  List<WarmupExerciseData>? get warmupExercises;
  set warmupExercises(List<WarmupExerciseData>? value);
  List<StretchExerciseData>? get stretchExercises;
  set stretchExercises(List<StretchExerciseData>? value);
  bool get isWarmupLoading;
  set isWarmupLoading(bool value);
  VideoPlayerController? get videoController;
  bool get isVideoInitialized;
  set isVideoInitialized(bool value);
  bool get isVideoPlaying;
  set isVideoPlaying(bool value);
  int get totalDrinkIntakeMl;
  set totalDrinkIntakeMl(int value);
  bool get hideAICoachForSession;
  set hideAICoachForSession(bool value);
  dynamic get workoutWidget;
  void breakSuperset(int groupId);
  void applyProgressionTargets(int exerciseIndex, SetProgressionPattern pattern);

  /// Show the 1RM logging sheet
  void showLog1RMSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Log1RMSheet(
          exerciseName: exercise.name,
          exerciseId: exercise.id ?? exercise.libraryId ?? '',
        ),
      ),
    );
  }

  /// Show hydration dialog and sync with nutrition tab
  Future<void> showHydrationDialogImpl([DrinkType initialType = DrinkType.water]) async {
    final result = await showHydrationDialog(
      context: context,
      totalIntakeMl: totalDrinkIntakeMl,
      initialDrinkType: initialType,
    );

    if (result != null && result.amountMl > 0) {
      // Update local workout state
      setState(() => totalDrinkIntakeMl = totalDrinkIntakeMl + result.amountMl);

      // Sync with hydration provider (nutrition tab)
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final success = await ref.read(hydrationProvider.notifier).logHydration(
          userId: userId,
          drinkType: result.drinkType.value,
          amountMl: result.amountMl,
          workoutId: (workoutWidget as dynamic).workout.id,
          notes: 'Logged during workout',
        );

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '${result.amountMl}ml ${result.drinkType.label} logged'
                  : '${result.drinkType.label} logged locally (sync failed)'),
              duration: const Duration(seconds: 2),
              backgroundColor: success ? AppColors.success : AppColors.orange,
            ),
          );
        }
      } else {
        // User not logged in, just show local confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.amountMl}ml ${result.drinkType.label} logged'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Show breathing guide for the current exercise
  void showBreathingGuideImpl(WorkoutExercise exercise) {
    showBreathingGuide(
      context: context,
      exercise: exercise,
    );
  }

  /// Show AI coach chat sheet
  void showAICoachSheet(WorkoutExercise exercise) {
    final currentWeight = double.tryParse(weightController.text) ?? exercise.weight ?? 0;
    final completedSetsCount = completedSets[currentExerciseIndex]?.length ?? 0;
    final totalSetsCount = totalSetsPerExercise[currentExerciseIndex] ?? 3;
    final remainingExercises = exercises.sublist(currentExerciseIndex + 1);

    showWorkoutAICoachSheet(
      context: context,
      ref: ref,
      currentExercise: exercise,
      completedSets: completedSetsCount,
      totalSets: totalSetsCount,
      currentWeight: currentWeight,
      useKg: useKg,
      remainingExercises: remainingExercises,
    );
  }

  /// Show dialog to confirm hiding AI Coach for this session
  void showHideCoachDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: ref.watch(accentColorProvider).getColor(isDark),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Hide AI Coach?',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'The AI Coach will be hidden for this workout session. You can still access it from Settings.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                hideAICoachForSession = true;
              });
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('AI Coach hidden for this session'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        hideAICoachForSession = false;
                      });
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Hide',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Video Utility Methods ──

  /// Handle video area tap
  void handleVideoAreaTap() {
    // No action needed - set tracking is always visible
  }

  /// Toggle video play/pause
  void toggleVideoPlayPause() {
    if (videoController == null || !isVideoInitialized) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (isVideoPlaying) {
        videoController!.pause();
        isVideoPlaying = false;
      } else {
        videoController!.play();
        isVideoPlaying = true;
      }
    });
  }

  // ── Data Fetching Methods ──

  /// Fetch exercise history for all exercises in the workout
  Future<void> fetchExerciseHistory() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      return;
    }

    final repository = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      await fetchSingleExerciseHistory(repository, userId, exercise, i);
    }
  }

  /// Fetch history for a single exercise
  Future<void> fetchSingleExerciseHistory(
    WorkoutRepository repository,
    String userId,
    WorkoutExercise exercise,
    int exerciseIndex,
  ) async {
    try {
      final lastPerformance = await repository.getExerciseLastPerformance(
        userId: userId,
        exerciseName: exercise.name,
      );

      if (lastPerformance != null && lastPerformance['sets'] != null) {
        final sets = lastPerformance['sets'] as List;
        if (mounted) {
          setState(() {
            previousSets[exerciseIndex] = sets
                .map((s) => {
                      'set': s['set_number'] ?? 1,
                      'weight': (s['weight_kg'] as num?)?.toDouble() ?? 0.0,
                      'reps': s['reps_completed'] ?? 10,
                      'rir': s['rir'] as int?,
                      'rpe': s['rpe'] as int?,
                    })
                .toList();
          });
        }

        for (final set in sets) {
          final weight = (set['weight_kg'] as num?)?.toDouble() ?? 0.0;
          final currentMax = exerciseMaxWeights[exercise.name] ?? 0.0;
          if (weight > currentMax) {
            exerciseMaxWeights[exercise.name] = weight;
          }
        }

        // If this is the currently viewed exercise and weight controller is at 0
        // or below bar minimum, use previous session's weight
        if (exerciseIndex == viewingExerciseIndex && mounted) {
          final currentWeight = double.tryParse(weightController.text) ?? 0;
          final minBar = isBarbell(exercise.equipment, exerciseName: exercise.name)
              ? getBarWeight(exercise.equipment, useKg: useKg)
              : 0.0;
          if (currentWeight < minBar && sets.isNotEmpty) {
            final prevWeightKg = (sets.last['weight_kg'] as num?)?.toDouble() ?? 0.0;
            if (prevWeightKg > 0) {
              final displayWeight = useKg
                  ? prevWeightKg
                  : kgToDisplayLbs(prevWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
              weightController.text = displayWeight.toStringAsFixed(1);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load history for ${exercise.name}: $e');
    }
  }

  /// Handle warmup intervals being logged
  void handleWarmupIntervalsLogged(Map<String, List<WarmupInterval>> logs) {
    if (logs.isEmpty) return;
    debugPrint('🏋️ [ActiveWorkout] Warmup intervals logged: ${logs.length} exercises');

    // Save warmup interval logs to backend
    final workoutId = (workoutWidget as dynamic).workout.id;
    if (workoutId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final intervalData = logs.map((exerciseName, intervals) => MapEntry(
      exerciseName,
      intervals.map((i) => i.toJson()).toList(),
    ));

    // Fire-and-forget background save
    apiClient.post(
      '${ApiConstants.workouts}/$workoutId/warmup-logs',
      data: {'intervals': intervalData},
    ).then((_) {
      debugPrint('✅ [ActiveWorkout] Warmup intervals saved to backend');
    }).catchError((e) {
      debugPrint('⚠️ [ActiveWorkout] Failed to save warmup intervals: $e');
    });
  }

  /// Go back to warmup phase from active workout
  void goBackToWarmup();

  /// Load personalized warmup and stretch exercises from API
  Future<void> loadWarmupAndStretches() async {
    debugPrint('🔥 [Warmup] loadWarmupAndStretches ENTERED');
    try {
      final workoutId = (workoutWidget as dynamic).workout.id;
      debugPrint('🔥 [Warmup] loadWarmupAndStretches called, workoutId=$workoutId');
      if (workoutId == null) {
        debugPrint('🔥 [Warmup] workoutId is null — skipping warmup load');
        if (mounted) setState(() => isWarmupLoading = false);
        return;
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      debugPrint('🔥 [Warmup] Calling generateWarmupAndStretches API...');
      final data = await workoutRepo.generateWarmupAndStretches(workoutId);
      debugPrint('🔥 [Warmup] API returned: warmup=${data['warmup']?.length ?? 'null'}, stretches=${data['stretches']?.length ?? 'null'}');

      if (!mounted) return;

      final warmupData = data['warmup'] ?? [];
      final stretchData = data['stretches'] ?? [];
      debugPrint('🔥 [Warmup] warmupData.length=${warmupData.length}, stretchData.length=${stretchData.length}');

      setState(() {
        if (warmupData.isNotEmpty) {
          warmupExercises = warmupData.map<WarmupExerciseData>((e) => WarmupExerciseData(
            name: e['name']?.toString() ?? 'Exercise',
            duration: (e['duration_seconds'] as num?)?.toInt() ?? 30,
            icon: _getIconForExercise(e['name']?.toString() ?? ''),
            inclinePercent: (e['incline_percent'] as num?)?.toDouble(),
            speedMph: (e['speed_mph'] as num?)?.toDouble(),
            rpm: (e['rpm'] as num?)?.toInt(),
            resistanceLevel: (e['resistance_level'] as num?)?.toInt(),
            strokeRateSpm: (e['stroke_rate_spm'] as num?)?.toInt(),
            equipment: e['equipment']?.toString(),
            isStaple: e['is_staple'] == true,
          )).toList();
        }

        if (stretchData.isNotEmpty) {
          stretchExercises = stretchData.map<StretchExerciseData>((e) => StretchExerciseData(
            name: e['name']?.toString() ?? 'Stretch',
            duration: (e['duration_seconds'] as num?)?.toInt() ?? 30,
            icon: _getIconForStretch(e['name']?.toString() ?? ''),
            inclinePercent: (e['incline_percent'] as num?)?.toDouble(),
            speedMph: (e['speed_mph'] as num?)?.toDouble(),
            rpm: (e['rpm'] as num?)?.toInt(),
            resistanceLevel: (e['resistance_level'] as num?)?.toInt(),
            strokeRateSpm: (e['stroke_rate_spm'] as num?)?.toInt(),
            equipment: e['equipment']?.toString(),
          )).toList();
        }

        isWarmupLoading = false;
      });

      debugPrint('✅ [Warmup] Loaded ${warmupExercises?.length ?? 0} warmup exercises');
      debugPrint('✅ [Stretch] Loaded ${stretchExercises?.length ?? 0} stretch exercises');
    } catch (e, stackTrace) {
      debugPrint('❌ [Warmup] Error loading warmup/stretches: $e');
      debugPrint('❌ [Warmup] StackTrace: $stackTrace');
      if (mounted) {
        setState(() => isWarmupLoading = false);
      }
    }
  }

  /// Map exercise name to appropriate icon for warmup
  IconData _getIconForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('jump') || lower.contains('jack') || lower.contains('cardio') || lower.contains('run')) {
      return Icons.directions_run;
    }
    if (lower.contains('circle') || lower.contains('rotation') || lower.contains('twist')) {
      return Icons.loop;
    }
    if (lower.contains('swing') || lower.contains('lunge') || lower.contains('step')) {
      return Icons.swap_horiz;
    }
    if (lower.contains('squat') || lower.contains('leg')) {
      return Icons.airline_seat_legroom_extra;
    }
    if (lower.contains('arm') || lower.contains('shoulder') || lower.contains('push')) {
      return Icons.fitness_center;
    }
    if (lower.contains('cat') || lower.contains('cow') || lower.contains('spine')) {
      return Icons.pets;
    }
    if (lower.contains('hip') || lower.contains('glute')) {
      return Icons.sports_gymnastics;
    }
    return Icons.whatshot; // Default warmup icon
  }

  /// Map exercise name to appropriate icon for stretches
  IconData _getIconForStretch(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('quad') || lower.contains('leg') || lower.contains('hamstring')) {
      return Icons.airline_seat_legroom_extra;
    }
    if (lower.contains('chest') || lower.contains('pec')) {
      return Icons.open_with;
    }
    if (lower.contains('back') || lower.contains('lat') || lower.contains('spine')) {
      return Icons.accessibility_new;
    }
    if (lower.contains('shoulder') || lower.contains('arm') || lower.contains('tricep')) {
      return Icons.fitness_center;
    }
    if (lower.contains('hip') || lower.contains('glute') || lower.contains('piriformis')) {
      return Icons.sports_gymnastics;
    }
    if (lower.contains('calf') || lower.contains('ankle')) {
      return Icons.directions_walk;
    }
    return Icons.self_improvement; // Default stretch icon
  }

  /// Fetch smart weight suggestion for an exercise based on historical data
  Future<void> fetchSmartWeightForExercise(WorkoutExercise exercise) async {
    // Check if previous session data already provides a better weight
    final prevSets = previousSets[currentExerciseIndex];
    if (prevSets != null && prevSets.isNotEmpty) {
      final prevWeight = (prevSets.last['weight'] as num?)?.toDouble() ?? 0.0;
      if (prevWeight > 0) {
        final currentWeight = double.tryParse(weightController.text) ?? 0;
        final minBar = isBarbell(exercise.equipment, exerciseName: exercise.name)
            ? getBarWeight(exercise.equipment, useKg: useKg)
            : 0.0;
        if (currentWeight < minBar && mounted) {
          final displayWeight = useKg
              ? prevWeight
              : kgToDisplayLbs(prevWeight, exercise.equipment,
                exerciseName: exercise.name,);
          weightController.text = displayWeight.toStringAsFixed(1);
        }
        return; // Previous session data is more reliable than API guess
      }
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      final suggestion = await WeightSuggestionService.getSmartWeight(
        dio: apiClient.dio,
        userId: userId,
        exerciseId: exercise.exerciseId ?? exercise.libraryId ?? '',
        exerciseName: exercise.name,
        targetReps: exercise.reps ?? 10,
        goal: TrainingGoal.fromString(
          ref.read(activeGymProfileProvider)?.goals.firstOrNull ?? 'hypertrophy',
        ),
        equipment: exercise.equipment ?? 'dumbbell',
      );

      if (mounted && suggestion != null && suggestion.suggestedWeight > 0) {
        // Enforce bar minimum and convert to display unit
        var suggestedKg = suggestion.suggestedWeight;
        final isBarbellExercise = isBarbell(exercise.equipment, exerciseName: exercise.name);
        final minBarKg = isBarbellExercise
            ? getBarWeight(exercise.equipment, useKg: true)
            : 0.0;
        if (suggestedKg < minBarKg) suggestedKg = minBarKg;
        final displaySuggested = useKg
            ? suggestedKg
            : kgToDisplayLbs(suggestedKg, exercise.equipment,
                exerciseName: exercise.name,);
        final displayMinBar = useKg
            ? minBarKg
            : kgToDisplayLbs(minBarKg, exercise.equipment,
                exerciseName: exercise.name,);

        // Only update if current weight is truly unset or below bar minimum
        // Do NOT override a valid planned weight (e.g., 45 lbs == bar weight)
        final currentWeight = double.tryParse(weightController.text) ?? 0;
        if (currentWeight <= 0 || currentWeight < displayMinBar) {
          setState(() {
            weightController.text = displaySuggested.toStringAsFixed(1);
          });
          debugPrint('✅ [SmartWeight] ${exercise.name}: ${suggestion.suggestedWeight}kg '
              '(confidence: ${(suggestion.confidence * 100).toInt()}%, '
              'source: ${suggestion.reasoning})');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmartWeight] Failed for ${exercise.name}: $e');
      // Fall back to planned weight - already set in controller
    }
  }

  /// Preload per-exercise progression patterns and bar types from SharedPreferences.
  Future<void> preloadProgressionPatterns() async {
    try {
      final exerciseNames = exercises.map((e) => e.name).toList();
      await ref.read(exerciseProgressionProvider.notifier)
          .preloadPatterns(exerciseNames);
      await ref.read(exerciseBarTypeProvider.notifier)
          .preloadBarTypes(exerciseNames);

      // Populate the in-memory maps from the providers
      final providerState = ref.read(exerciseProgressionProvider);
      final barTypeState = ref.read(exerciseBarTypeProvider);
      for (int i = 0; i < exercises.length; i++) {
        final key = exercises[i].name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
        if (providerState.containsKey(key)) {
          exerciseProgressionPattern[i] = providerState[key]!;
        }
        if (barTypeState.containsKey(key)) {
          exerciseBarType[i] = barTypeState[key]!;
        }
      }

      // Auto-apply patterns to update TARGET column immediately for ALL exercises
      debugPrint('📋 [Preload] Applying targets for ${exercises.length} exercises...');
      for (int i = 0; i < exercises.length; i++) {
        try {
          final pattern = exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;
          // Always populate map so hasProgression is true in buildSetRowsForExercise
          exerciseProgressionPattern[i] = pattern;
          debugPrint('📋 [Preload] ex $i: "${exercises[i].name}" → ${pattern.displayName}');
          applyProgressionTargets(i, pattern);
        } catch (e) {
          debugPrint('❌ [Preload] Failed for ex $i "${exercises[i].name}": $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [Progression] Error preloading patterns: $e');
    }
  }

  /// Apply a newly selected progression pattern to the current exercise.
  void applyProgressionPattern(SetProgressionPattern pattern) {
    final exerciseIndex = viewingExerciseIndex;

    // Save to state
    setState(() {
      exerciseProgressionPattern[exerciseIndex] = pattern;
    });

    // Persist to SharedPreferences
    ref.read(exerciseProgressionProvider.notifier)
        .setPattern(exercises[exerciseIndex].name, pattern);

    // Recalculate and apply targets
    applyProgressionTargets(exerciseIndex, pattern);

    HapticFeedback.mediumImpact();
  }

  // ── Sheet implementations for ExerciseNavigationMixin abstract methods ──

  /// Show progression model selector bottom sheet.
  /// Must be implemented in the main class (uses private _ProgressionSelectorSheet widget).
  void showProgressionSheetImpl();

  /// Show exercise details sheet (muscles, description, etc.)
  /// Must be implemented in the main class (uses private _ExerciseDetailsSheetContent widget).
  void showExerciseDetailsSheet(WorkoutExercise exercise);

  /// Show weight increments sheet
  void showWeightIncrementsSheetImpl() {
    showWeightIncrementsSheet(context);
  }

  /// Show equipment profile sheet — lets user view/edit their gym equipment
  void showEquipmentProfileSheetImpl() {
    final activeProfile = ref.read(activeGymProfileProvider);
    if (activeProfile == null) return;

    // Get current equipment details from profile
    final currentEquipmentDetails = (activeProfile.equipmentDetails ?? [])
        .map((detail) {
          if (detail is Map<String, dynamic>) {
            return EquipmentItem.fromJson(detail);
          }
          return null;
        })
        .whereType<EquipmentItem>()
        .toList();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: EditWorkoutEquipmentSheet(
          currentEquipment: activeProfile.equipment,
          equipmentDetails: currentEquipmentDetails,
          onApply: (selectedEquipment) async {
            Navigator.pop(context);
            // Save to gym profile via API
            try {
              final apiClient = ref.read(apiClientProvider);
              await apiClient.put(
                '/gym-profiles/${activeProfile.id}',
                data: {'equipment': selectedEquipment},
              );
              ref.read(gymProfilesProvider.notifier).refresh();
              if (mounted) {
                setState(() {}); // Rebuild to reflect new equipment
              }
              debugPrint('✅ [Equipment] Updated gym profile');
            } catch (e) {
              debugPrint('⚠️ [Equipment] Failed to save: $e');
            }
          },
        ),
      ),
    );
  }

  /// Show warmup sheet
  void showWarmupSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: buildInfoSheet(
          title: 'Warm Up',
          content: 'Warming up helps prevent injury and improves performance.\n\nRecommended: 1-2 lighter sets before working sets.',
          icon: Icons.whatshot_outlined,
        ),
      ),
    );
  }

  /// Show targets sheet
  void showTargetsSheet(WorkoutExercise exercise) {
    final setTargets = exercise.setTargets ?? [];
    showGlassSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Set Targets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (setTargets.isEmpty)
                Text(
                  'AI targets will be generated based on your history.',
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                  ),
                )
              else
                ...setTargets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final target = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Set ${i + 1}: ${target.targetWeightKg?.toStringAsFixed(1) ?? '-'} kg × ${target.targetReps} @ ${target.targetRir ?? '-'} RIR',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
        );
      },
    );
  }

  /// Show enhanced notes sheet with audio, photo, and voice-to-text
  void showNotesSheet(WorkoutExercise exercise) {
    // Get existing notes for this exercise if any
    final exerciseIndex = exercises.indexOf(exercise);
    String existingNotes = '';
    if (exerciseIndex >= 0 && completedSets.containsKey(exerciseIndex)) {
      final sets = completedSets[exerciseIndex]!;
      // Get notes from the most recent set with notes
      for (final set in sets.reversed) {
        if (set.notes != null && set.notes!.isNotEmpty) {
          existingNotes = set.notes!;
          break;
        }
      }
    }

    showEnhancedNotesSheet(
      context,
      initialNotes: existingNotes,
      onSave: (notes, audioPath, photoPaths) {
        // Store notes - could be applied to current set or exercise-level
        debugPrint('📝 Notes saved: $notes');
        if (audioPath != null) debugPrint('🎤 Audio: $audioPath');
        if (photoPaths.isNotEmpty) debugPrint('📷 Photos: ${photoPaths.length}');

        // Notes are saved via the callback - can extend to store audio/photos as needed
      },
    );
  }

  /// Build instruction row for superset sheet
  Widget _buildInstructionRow({
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

  /// Show history sheet
  void showHistorySheet(WorkoutExercise exercise) {
    final prevSets = previousSets[viewingExerciseIndex] ?? [];
    showGlassSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Last Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (prevSets.isEmpty)
                Text(
                  'No previous data for this exercise.',
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                  ),
                )
              else
                ...prevSets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final set = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Set ${i + 1}: ${set['weight']?.toStringAsFixed(1) ?? '-'} kg × ${set['reps'] ?? '-'} reps',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
        );
      },
    );
  }

  /// Build a simple info sheet
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
}
