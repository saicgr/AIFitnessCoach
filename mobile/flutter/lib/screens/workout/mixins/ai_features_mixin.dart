import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/workout_design.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/services/exercise_tip_service.dart';
import '../../../core/services/fatigue_service.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../core/providers/user_provider.dart';
import '../models/workout_state.dart';
import '../widgets/fatigue_alert_modal.dart';
import '../widgets/set_row.dart'; // For WeightIncrements
import '../../ai_settings/ai_settings_screen.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../widgets/barbell_plate_indicator.dart';

/// Mixin providing AI-powered features for the active workout screen:
/// weight suggestions, fatigue detection, media fetching, coach tips.
mixin AIFeaturesMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  Map<int, double> get exerciseWorkingWeight;
  Map<int, String> get exerciseBarType;
  TextEditingController get weightController;
  bool get useKg;
  int? get lastSetRpe;
  int? get lastSetRir;
  Map<int, List<Map<String, dynamic>>> get previousSets;
  Map<String, double> get exerciseMaxWeights;

  WeightSuggestion? get currentWeightSuggestion;
  set currentWeightSuggestion(WeightSuggestion? value);
  bool get isLoadingWeightSuggestion;
  set isLoadingWeightSuggestion(bool value);
  FatigueAlertData? get fatigueAlertData;
  set fatigueAlertData(FatigueAlertData? value);
  bool get showFatigueAlert;
  set showFatigueAlert(bool value);
  bool get showCoachTip;
  set showCoachTip(bool value);
  String? get coachTipMessage;
  set coachTipMessage(String? value);
  VideoPlayerController? get videoController;
  set videoController(VideoPlayerController? value);
  bool get isVideoInitialized;
  set isVideoInitialized(bool value);
  bool get isVideoPlaying;
  set isVideoPlaying(bool value);
  String? get imageUrl;
  set imageUrl(String? value);
  bool get isLoadingMedia;
  set isLoadingMedia(bool value);

  // ── AI Feature Methods ──

  /// Fetch AI-powered weight suggestion from the backend
  Future<void> fetchAIWeightSuggestion(SetLog setLog) async {
    final exercise = exercises[currentExerciseIndex];
    final isLastSet = (completedSets[currentExerciseIndex]?.length ?? 0) >=
        (totalSetsPerExercise[currentExerciseIndex] ?? 3);
    final equipmentIncrement = WeightIncrements.getIncrement(exercise.equipment);

    setState(() => isLoadingWeightSuggestion = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
        return;
      }

      final aiSettings = ref.read(aiSettingsProvider);

      final aiSuggestion = await WeightSuggestionService.getAISuggestion(
        dio: apiClient.dio,
        userId: userId,
        exerciseName: exercise.name,
        exerciseId: exercise.id,
        equipment: exercise.equipment ?? 'dumbbell',
        muscleGroup: exercise.muscleGroup ?? 'unknown',
        setNumber: completedSets[currentExerciseIndex]?.length ?? 1,
        totalSets: totalSetsPerExercise[currentExerciseIndex] ?? 3,
        repsCompleted: setLog.reps,
        targetReps: setLog.targetReps,
        weightKg: setLog.weight,
        rpe: lastSetRpe,
        rir: lastSetRir,
        isLastSet: isLastSet,
        fitnessLevel: ref.read(scoresProvider).fitnessScore?.level.name ?? 'intermediate',
        goals: ref.read(activeGymProfileProvider)?.goals ?? [],
        coachingStyle: aiSettings.coachingStyle,
        communicationTone: aiSettings.communicationTone,
        encouragementLevel: aiSettings.encouragementLevel,
        responseLength: aiSettings.responseLength,
      );

      if (!mounted) return;

      if (aiSuggestion != null) {
        setState(() {
          currentWeightSuggestion = aiSuggestion;
          isLoadingWeightSuggestion = false;
        });
        debugPrint('✅ [AI Weight] Got AI suggestion: ${aiSuggestion.type} '
            'to ${aiSuggestion.suggestedWeight}kg');
      } else {
        useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
      }
    } catch (e) {
      debugPrint('❌ [AI Weight] Error fetching suggestion: $e');
      if (!mounted) return;
      useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
    }
  }

  /// Fallback to rule-based suggestion when AI is unavailable
  void useRuleBasedSuggestion(
    SetLog setLog,
    WorkoutExercise exercise,
    bool isLastSet,
    double equipmentIncrement,
  ) {
    setState(() {
      currentWeightSuggestion = WeightSuggestionService.generateSuggestion(
        currentWeight: setLog.weight,
        targetReps: setLog.targetReps,
        actualReps: setLog.reps,
        rpe: lastSetRpe,
        rir: lastSetRir,
        equipmentIncrement: equipmentIncrement,
        isLastSet: isLastSet,
      );
      isLoadingWeightSuggestion = false;
    });
  }

  /// Handle accepting a weight suggestion
  void acceptWeightSuggestion(double newWeight) {
    setState(() {
      weightController.text = newWeight.toStringAsFixed(1);
      currentWeightSuggestion = null;
    });
    HapticFeedback.mediumImpact();
  }

  /// Handle dismissing a weight suggestion
  void dismissWeightSuggestion() {
    setState(() {
      currentWeightSuggestion = null;
    });
  }

  /// Auto-adjust weight for next set based on RIR-first logic.
  void autoAdjustWeightIfNeeded(SetLog setLog, WorkoutExercise exercise) {
    final currentWeightKg = setLog.weight;

    if (currentWeightKg <= 0) {
      debugPrint('🔧 [AutoAdjust] SKIP — bodyweight (weight=$currentWeightKg)');
      return;
    }

    final completedCount = completedSets[currentExerciseIndex]?.length ?? 0;
    final setTargetsList = exercise.setTargets;
    if (setTargetsList != null && completedCount > 0) {
      final justCompletedIdx = completedCount - 1;
      if (justCompletedIdx < setTargetsList.length &&
          setTargetsList[justCompletedIdx].setType.toLowerCase() == 'warmup') {
        debugPrint('🔧 [AutoAdjust] SKIP — warmup set');
        return;
      }
    }

    final pattern = exerciseProgressionPattern[currentExerciseIndex]
        ?? SetProgressionPattern.pyramidUp;
    if (pattern == SetProgressionPattern.dropSets ||
        pattern == SetProgressionPattern.restPause ||
        pattern == SetProgressionPattern.myoReps) {
      debugPrint('🔧 [AutoAdjust] SKIP — pattern $pattern manages own weights');
      return;
    }

    final targetReps = setLog.targetReps > 0 ? setLog.targetReps : (exercise.reps ?? 10);
    final actualReps = setLog.reps;

    if (actualReps >= targetReps) {
      debugPrint('🔧 [AutoAdjust] SKIP — hit target ($actualReps >= $targetReps)');
      return;
    }

    final repRatio = actualReps / targetReps;

    int? effectiveRir = setLog.rir;
    if (effectiveRir == null && setLog.rpe != null) {
      effectiveRir = (10 - setLog.rpe!).clamp(0, 5);
    }

    final incState = ref.read(weightIncrementsProvider);
    final equipmentIncrementKg = incState.getIncrementKg(exercise.equipment);

    debugPrint('🔧 [AutoAdjust] weightKg=$currentWeightKg, reps=$actualReps/$targetReps, '
        'repRatio=${repRatio.toStringAsFixed(2)}, RIR=$effectiveRir, '
        'incKg=$equipmentIncrementKg, pattern=$pattern');

    int incrementsToDrop = 0;
    String? message;

    if (effectiveRir != null) {
      if (effectiveRir >= 2 || repRatio >= 0.9) {
        debugPrint('🔧 [AutoAdjust] SKIP — good perf (RIR=$effectiveRir, ratio=${repRatio.toStringAsFixed(2)})');
        return;
      } else if (effectiveRir == 1 && repRatio >= 0.7) {
        debugPrint('🔧 [AutoAdjust] SKIP — marginal OK (RIR=1, ratio=${repRatio.toStringAsFixed(2)})');
        return;
      } else if (repRatio < 0.5 && effectiveRir == 0) {
        incrementsToDrop = 2;
        message = 'Weight too heavy';
      } else if (effectiveRir == 0 || repRatio < 0.7) {
        incrementsToDrop = 1;
        message = 'Adjusting weight';
      }
    } else {
      if (repRatio >= 0.7) {
        debugPrint('🔧 [AutoAdjust] SKIP — no RIR, ratio OK (${repRatio.toStringAsFixed(2)})');
        return;
      }
      incrementsToDrop = 1;
      message = 'Adjusting weight';
    }

    if (incrementsToDrop == 0) return;

    final minWeightKg = isBarbell(exercise.equipment, exerciseName: exercise.name)
        ? getBarWeight(exercise.equipment, useKg: true)
        : equipmentIncrementKg;

    final adjustedWeightKg = (currentWeightKg - (equipmentIncrementKg * incrementsToDrop))
        .clamp(minWeightKg, 999.0);

    if ((adjustedWeightKg - currentWeightKg).abs() < 0.01) {
      debugPrint('🔧 [AutoAdjust] SKIP — no real change after clamp');
      return;
    }

    final displayAdjusted = useKg
        ? adjustedWeightKg
        : kgToDisplayLbs(adjustedWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
    final inc = incState.getIncrement(exercise.equipment);
    final incrementUnit = incState.unit;
    double displayInc = inc;
    if (useKg && incrementUnit == 'lbs') {
      displayInc = inc * 0.453592;
    } else if (!useKg && incrementUnit == 'kg') {
      displayInc = (inc * 2.20462).roundToDouble();
    }

    final snappedDisplay = displayInc > 0
        ? (displayAdjusted / displayInc).round() * displayInc
        : displayAdjusted;

    debugPrint('🔧 [AutoAdjust] DROP $incrementsToDrop inc(s): '
        '${currentWeightKg.toStringAsFixed(1)}kg → ${adjustedWeightKg.toStringAsFixed(1)}kg, '
        'display=${snappedDisplay.toStringAsFixed(1)} ${useKg ? "kg" : "lb"}');

    weightController.text = snappedDisplay.toStringAsFixed(snappedDisplay % 1 == 0 ? 0 : 1);

    if (mounted && message != null) {
      final unit = useKg ? 'kg' : 'lb';
      final displayCurrent = useKg
          ? currentWeightKg
          : kgToDisplayLbs(currentWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$message: ${displayCurrent.toStringAsFixed(1)} → ${snappedDisplay.toStringAsFixed(1)} $unit',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WorkoutDesign.rir2,
        ),
      );
    }
  }

  /// Check for fatigue after completing a set
  Future<void> checkFatigue() async {
    if (!ref.read(fatigueAlertsEnabledProvider)) return;

    final exercise = exercises[currentExerciseIndex];
    final completedSetsList = completedSets[currentExerciseIndex] ?? [];

    if (completedSetsList.length < 2) return;

    final setTargetsForCheck = exercise.setTargets;
    if (setTargetsForCheck != null) {
      final workingSetsCompleted = completedSetsList.asMap().entries.where((e) {
        final idx = e.key;
        if (idx >= setTargetsForCheck.length) return true;
        return setTargetsForCheck[idx].setType.toLowerCase() != 'warmup';
      }).length;
      if (workingSetsCompleted < 2) return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final currentWeight = double.tryParse(weightController.text) ?? 0;

      final pattern = exerciseProgressionPattern[currentExerciseIndex]
          ?? SetProgressionPattern.pyramidUp;
      final setTargets = exercise.setTargets;

      final setsData = <FatigueSetData>[];
      for (int i = 0; i < completedSetsList.length; i++) {
        final s = completedSetsList[i];
        final target = (setTargets != null && i < setTargets.length) ? setTargets[i] : null;
        if (target != null && target.setType.toLowerCase() == 'warmup') continue;
        setsData.add(FatigueSetData(
          reps: s.reps,
          weight: s.weight,
          rpe: s.rpe,
          rir: s.rir,
          targetReps: target?.targetReps ?? exercise.reps,
          targetWeight: target?.targetWeightKg,
          targetRir: target?.targetRir,
        ));
      }
      if (setsData.length < 2) return;

      final exerciseType = FatigueService.getExerciseType(
        exercise.muscleGroup,
        exercise.name,
      );

      final alertData = await FatigueService.checkFatigue(
        dio: apiClient.dio,
        setsData: setsData,
        currentWeight: currentWeight,
        exerciseType: exerciseType,
        targetReps: exercise.reps,
        progressionPattern: pattern.name,
      );

      if (!mounted) return;

      if (alertData != null && alertData.fatigueDetected) {
        setState(() {
          fatigueAlertData = alertData;
          showFatigueAlert = true;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('❌ [Fatigue] Error checking fatigue: $e');
    }
  }

  /// Handle accepting fatigue suggestion (reduce weight)
  void handleAcceptFatigueSuggestion() {
    if (fatigueAlertData != null && fatigueAlertData!.suggestedWeight > 0) {
      weightController.text = fatigueAlertData!.suggestedWeight.toStringAsFixed(1);
    }
    setState(() {
      showFatigueAlert = false;
      fatigueAlertData = null;
    });
    HapticFeedback.mediumImpact();
  }

  /// Handle dismissing fatigue alert (continue as planned)
  void handleDismissFatigueAlert() {
    setState(() {
      showFatigueAlert = false;
      fatigueAlertData = null;
    });
  }

  /// Fetch media (video/image) for an exercise
  Future<void> fetchMediaForExercise(WorkoutExercise exercise) async {
    setState(() => isLoadingMedia = true);

    videoController?.dispose();
    videoController = null;
    isVideoInitialized = false;
    imageUrl = null;

    final apiClient = ref.read(apiClientProvider);
    final exerciseName = exercise.name;

    final modelVideoUrl = exercise.videoUrl;
    final modelImageUrl = exercise.gifUrl;

    if (modelImageUrl != null && modelImageUrl.isNotEmpty) {
      setState(() {
        imageUrl = modelImageUrl;
        isLoadingMedia = false;
      });
    }

    if (modelVideoUrl != null && modelVideoUrl.isNotEmpty && !modelVideoUrl.startsWith('s3://')) {
      try {
        videoController = VideoPlayerController.networkUrl(Uri.parse(modelVideoUrl));
        await videoController!.initialize();
        videoController!.setLooping(true);
        videoController!.setVolume(0);
        videoController!.play();

        if (mounted) {
          setState(() {
            isVideoInitialized = true;
            isVideoPlaying = true;
          });
        }
        return;
      } catch (e) {
        debugPrint('❌ [Media] Model video failed: $e');
      }
    }

    try {
      final imageResponse = await apiClient.dio.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );
      if (imageResponse.data?['url'] != null && mounted) {
        setState(() {
          imageUrl = imageResponse.data['url'];
          isLoadingMedia = false;
        });
        debugPrint('✅ [Media] Image loaded from API: $imageUrl');
      }
    } catch (e) {
      debugPrint('❌ [Media] Image API fetch failed: $e');
    }

    try {
      final videoResponse = await apiClient.dio.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );
      if (videoResponse.data?['url'] != null) {
        final videoUrl = videoResponse.data['url'];
        videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await videoController!.initialize();
        videoController!.setLooping(true);
        videoController!.setVolume(0);
        videoController!.play();

        if (mounted) {
          setState(() {
            isVideoInitialized = true;
            isVideoPlaying = true;
          });
        }
        debugPrint('✅ [Media] Video loaded from API: $videoUrl');
      }
    } catch (e) {
      debugPrint('❌ [Media] Video API fetch failed: $e');
    }

    if (mounted && imageUrl == null && !isVideoInitialized) {
      setState(() => isLoadingMedia = false);
    }
  }

  /// Track which exercise indices have already shown a tip
  final Set<int> _tippedExerciseIndices = {};

  /// Lookahead: pre-fetch tips for the next few exercises so they're
  /// cached by the time the user gets there. Only fetches 2 ahead
  /// to avoid saturating the network at workout start.
  void _prefetchUpcomingTips() {
    final tipService = ref.read(exerciseTipServiceProvider);
    final aiSettings = ref.read(aiSettingsProvider);
    final userGoal = ref.read(authStateProvider).user?.primaryGoal;

    // Pre-fetch next 2 exercises (current + 1 and + 2)
    for (int offset = 1; offset <= 2; offset++) {
      final i = currentExerciseIndex + offset;
      if (i >= exercises.length) break;

      final exercise = exercises[i];

      // Skip if already cached
      if (tipService.getCachedTip(exercise.name) != null) continue;

      final pattern = exerciseProgressionPattern[i]
          ?? SetProgressionPattern.pyramidUp;
      final prevSets = previousSets[i];
      final prWeight = exerciseMaxWeights[exercise.name];

      tipService.getExerciseTip(
        exerciseName: exercise.name,
        aiSettings: aiSettings,
        bodyPart: exercise.bodyPart,
        equipment: exercise.equipment,
        sets: exercise.sets ?? 3,
        reps: exercise.reps,
        targetWeight: exercise.weight,
        useKg: useKg,
        userGoal: userGoal,
        progressionPattern: pattern.displayName,
        previousSets: prevSets,
        prWeight: prWeight,
      ).catchError((e) {
        debugPrint('⚠️ [AIFeatures] Pre-fetch failed for ${exercise.name}: $e');
        return ''; // Return empty to satisfy Future<String> type
      });
    }
  }

  /// Show coach tip bubble — fires for EACH new exercise.
  /// Also pre-fetches the next 2 exercises' tips in the background.
  void showCoachTipIfNeeded() {
    if (!mounted) return;

    // Skip if this exercise already showed a tip
    if (_tippedExerciseIndices.contains(currentExerciseIndex)) return;
    _tippedExerciseIndices.add(currentExerciseIndex);

    // Dismiss any previous tip
    if (showCoachTip) {
      setState(() => showCoachTip = false);
    }

    // Fetch current exercise tip (instant if cached)
    _showCachedOrFetchTip();

    // Pre-fetch next 2 exercises in background
    _prefetchUpcomingTips();
  }

  Future<void> _showCachedOrFetchTip() async {
    final exercise = exercises[currentExerciseIndex];
    final aiSettings = ref.read(aiSettingsProvider);
    final userGoal = ref.read(authStateProvider).user?.primaryGoal;
    final pattern = exerciseProgressionPattern[currentExerciseIndex]
        ?? SetProgressionPattern.pyramidUp;
    final prevSets = previousSets[currentExerciseIndex];
    final prWeight = exerciseMaxWeights[exercise.name];
    final targetWeight = double.tryParse(weightController.text);

    try {
      final tipService = ref.read(exerciseTipServiceProvider);

      // This returns instantly if pre-fetched, or fetches on cache miss
      final tip = await tipService.getExerciseTip(
        exerciseName: exercise.name,
        aiSettings: aiSettings,
        bodyPart: exercise.bodyPart,
        equipment: exercise.equipment,
        sets: exercise.sets ?? 3,
        reps: exercise.reps,
        targetWeight: targetWeight,
        useKg: useKg,
        userGoal: userGoal,
        progressionPattern: pattern.displayName,
        previousSets: prevSets,
        prWeight: prWeight,
      );

      if (!mounted) return;

      setState(() {
        coachTipMessage = tip;
        showCoachTip = true;
      });

      // Auto-dismiss after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => showCoachTip = false);
        }
      });
    } catch (e) {
      debugPrint('❌ [AIFeatures] Coach tip fetch failed: $e');
    }
  }

  /// Load coach persona from AI settings
  void loadCoachPersona() {
    // Coach persona is loaded for AI settings context;
    // the actual persona is referenced via aiSettingsProvider when needed.
  }
}
