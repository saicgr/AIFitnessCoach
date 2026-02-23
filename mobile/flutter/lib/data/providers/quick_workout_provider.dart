import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/collaborative_score_service.dart';
import '../../services/hrv_recovery_service.dart';
import '../../services/mesocycle_planner.dart';
import '../../services/mrv_learning_service.dart';
import '../../services/muscle_recovery_tracker.dart';
import '../../services/dup_rotation.dart';
import '../../services/progressive_overload_tracker.dart';
import '../../services/rpe_feedback_service.dart';
import '../../services/sfr_score_service.dart';
import '../../services/volume_landmark_service.dart';
import '../../services/weekly_volume_tracker.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../models/workout.dart';
import '../services/api_client.dart';
import '../services/exercise_library_loader.dart';
import '../../core/constants/api_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../models/equipment_item.dart';
import '../../services/equipment_context_resolver.dart';
import '../../services/offline_workout_generator.dart';
import '../../services/quick_workout_engine.dart';

// ============================================
// Quick Workout State
// ============================================

/// State for quick workout generation
class QuickWorkoutState {
  /// Whether generation is in progress
  final bool isGenerating;

  /// Current status message
  final String? statusMessage;

  /// Generated workout (null until complete)
  final Workout? generatedWorkout;

  /// Error message if generation failed
  final String? error;

  /// Last used duration preference
  final int? lastDuration;

  /// Last used focus preference
  final String? lastFocus;

  const QuickWorkoutState({
    this.isGenerating = false,
    this.statusMessage,
    this.generatedWorkout,
    this.error,
    this.lastDuration,
    this.lastFocus,
  });

  QuickWorkoutState copyWith({
    bool? isGenerating,
    String? statusMessage,
    Workout? generatedWorkout,
    String? error,
    int? lastDuration,
    String? lastFocus,
    bool clearError = false,
    bool clearWorkout = false,
    bool clearStatus = false,
  }) {
    return QuickWorkoutState(
      isGenerating: isGenerating ?? this.isGenerating,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      generatedWorkout: clearWorkout ? null : (generatedWorkout ?? this.generatedWorkout),
      error: clearError ? null : (error ?? this.error),
      lastDuration: lastDuration ?? this.lastDuration,
      lastFocus: lastFocus ?? this.lastFocus,
    );
  }

  /// Whether generation completed successfully
  bool get isCompleted => generatedWorkout != null && !isGenerating;

  /// Whether generation failed
  bool get hasFailed => error != null && !isGenerating;
}

// ============================================
// Quick Workout Notifier
// ============================================

class QuickWorkoutNotifier extends StateNotifier<QuickWorkoutState> {
  final ApiClient _apiClient;
  final AppDatabase _db;
  final Ref _ref;

  QuickWorkoutNotifier(this._apiClient, this._db, this._ref)
      : super(const QuickWorkoutState());

  /// Generate a quick workout — local engine first, API fallback if cache is small.
  /// If [scheduledDate] is provided, the generated workout's scheduled date
  /// will be overridden (used when user picks "Change Date" in conflict dialog).
  Future<Workout?> generateQuickWorkout({
    required int duration,
    String? focus,
    String? difficulty,
    String? mood,
    String? goal,
    bool useSupersets = true,
    List<String>? equipment,
    List<String>? injuries,
    Map<String, EquipmentItem>? equipmentDetails,
    DateTime? scheduledDate,
  }) async {
    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('[QuickWorkout] No user ID, cannot generate');
      state = state.copyWith(error: 'User not logged in');
      return null;
    }

    debugPrint('[QuickWorkout] Starting generation: ${duration}min, focus=$focus, '
        'difficulty=$difficulty, mood=$mood, supersets=$useSupersets');
    state = state.copyWith(
      isGenerating: true,
      statusMessage: 'Generating workout...',
      clearError: true,
      clearWorkout: true,
    );

    try {
      // 1. Get cached exercises from Drift
      final cachedExercises = await _db.exerciseLibraryDao.getAllCachedExercises();

      // 2. Convert to OfflineExercise
      var offlineExercises = cachedExercises.map((c) => OfflineExercise(
        id: c.id,
        name: c.name,
        bodyPart: c.bodyPart,
        equipment: c.equipment,
        targetMuscle: c.targetMuscle,
        primaryMuscle: c.primaryMuscle,
        secondaryMuscles: c.secondaryMuscles?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        difficulty: c.difficulty,
        difficultyNum: c.difficultyNum,
        videoUrl: c.videoUrl,
        imageS3Path: c.imageS3Path,
      )).toList();

      // 3. If cache is too small, try seeding from bundled asset first
      if (offlineExercises.length < 50) {
        debugPrint('[QuickWorkout] Cache too small (${offlineExercises.length}), seeding from bundled asset...');
        await ExerciseLibraryLoader.seedDatabaseIfNeeded(_db);

        // Re-read after seed
        final reloaded = await _db.exerciseLibraryDao.getAllCachedExercises();
        final reloadedOffline = reloaded.map((c) => OfflineExercise(
          id: c.id,
          name: c.name,
          bodyPart: c.bodyPart,
          equipment: c.equipment,
          targetMuscle: c.targetMuscle,
          primaryMuscle: c.primaryMuscle,
          secondaryMuscles: c.secondaryMuscles?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          difficulty: c.difficulty,
          difficultyNum: c.difficultyNum,
          videoUrl: c.videoUrl,
          imageS3Path: c.imageS3Path,
        )).toList();

        if (reloadedOffline.length >= 50) {
          debugPrint('[QuickWorkout] Seed successful (${reloadedOffline.length} exercises), proceeding locally');
          offlineExercises = reloadedOffline;
        } else {
          debugPrint('[QuickWorkout] Seed still insufficient (${reloadedOffline.length}), falling back to API');
          return _generateViaApi(
            userId: userId,
            duration: duration,
            focus: focus,
            difficulty: difficulty,
            goal: goal,
            equipment: equipment,
            injuries: injuries,
          );
        }
      }

      // 4. Load variety data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('quick_workout_recent_exercises') ?? [];
      final recentExercises = recentJson.expand((s) => s.split(',')).toSet();

      // 5. Get user profile data
      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;

      // 5b. Load muscle recovery scores
      var recoveryScores = await MuscleRecoveryTracker.getAllRecoveryScores();

      // 5b2. Load HRV/sleep recovery modifiers
      final hrvModifiers = await HrvRecoveryService.getModifiers();
      if (hrvModifiers.hasData) {
        recoveryScores = MuscleRecoveryTracker.adjustRecoveryScoresWithHrv(
          recoveryScores, hrvModifiers.volumeMultiplier,
        );
      }

      // 5c. Load exercise session tracking
      final sessionTrackingJson = prefs.getString('quick_workout_exercise_sessions');
      Map<String, int> sessionsSinceLastUse = {};
      if (sessionTrackingJson != null) {
        try {
          final decoded = jsonDecode(sessionTrackingJson) as Map<String, dynamic>;
          sessionsSinceLastUse = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
        } catch (_) {}
      }

      // 5d. Load RPE feedback summaries and derived 1RMs
      final rpeFeedbackService = RpeFeedbackService(_db);
      final rpeSummaries = await rpeFeedbackService.computeSummaries(userId);
      final rpeDerived1rms = RpeFeedbackService.extract1rmEstimates(rpeSummaries);

      // 5e. Load persistent 1RMs merged with RPE-derived ones
      final overloadTracker = ProgressiveOverloadTracker(_db);
      final merged1rms = await overloadTracker.getMerged1rms(userId, rpeDerived1rms);

      // 5f. Load weekly volume tracking
      final weeklyVolume = await WeeklyVolumeTracker.getCurrentWeekVolume();

      // 5g. Load volume landmarks for user's fitness level
      final fitnessLevel = user?.fitnessLevel ?? 'intermediate';
      final volumeLandmarks = await VolumeLandmarkService.getLandmarks(fitnessLevel);

      // 5h. Personalize volume landmarks with recovery + RPE data
      final globalAvgRpe = RpeFeedbackService.computeGlobalAvgRpe(rpeSummaries);
      final rpeLowCount = rpeSummaries.values
          .where((s) => s.avgRpe < 6.5 && s.sessionCount >= 3)
          .length;
      final personalizedLandmarks = VolumeLandmarkService.personalize(
        volumeLandmarks,
        recoveryScores: recoveryScores,
        globalAvgRpe: globalAvgRpe,
        rpeLowSessionCount: rpeLowCount,
      );

      // 5h2. Apply individual MRV learning (Feature 3)
      final mrvService = MrvLearningService(_db);
      final learnedLandmarks = await mrvService.getPersonalizedLandmarks(
        userId, personalizedLandmarks,
      );
      // Use learned landmarks if MRV data is available
      final effectiveLandmarks = learnedLandmarks.isNotEmpty
          ? learnedLandmarks
          : personalizedLandmarks;

      // 5i. Load mesocycle context
      final mesocycleContext = await MesocyclePlanner.getCurrentContext(
        volumeLandmarks: effectiveLandmarks,
      );

      // 5j. Check auto-deload triggers
      if (mesocycleContext != null && !mesocycleContext.isDeload) {
        final shouldDeload = await MesocyclePlanner.shouldAutoDeload(
          rpeSummaries: rpeSummaries,
          recoveryScores: recoveryScores,
        );
        if (shouldDeload) {
          await MesocyclePlanner.forceDeload();
        }
      }

      // 5k. Load collaborative filtering scores for the target focus/goal
      final effectiveGoal = goal ?? 'hypertrophy';
      final effectiveFocus = focus ?? 'full_body';
      Map<String, double> collaborativeScores = {};
      try {
        // Load scores for the primary muscle groups based on focus
        final muscles = _focusToMuscles(effectiveFocus);
        for (final muscle in muscles) {
          final scores = await CollaborativeScoreService.getScores(
            muscle, effectiveGoal,
          );
          collaborativeScores.addAll(scores);
        }
      } catch (_) {
        // Non-critical: continue without collaborative scores
      }

      // 6. Build equipment context from details (if available)
      final eqContext = EquipmentContextResolver.fromMixed(
        equipment ?? [],
        equipmentDetails,
      );

      // 6b. Load SFR scores for exercise selection (Feature 1)
      final exerciseNames = offlineExercises.map((e) => e.name ?? '').toList();
      final sfrScores = await SfrScoreService.batchGetSfrScores(exerciseNames);

      // 7. Generate locally (<100ms)
      final engine = QuickWorkoutEngine();
      var workout = engine.generate(
        userId: userId,
        durationMinutes: duration,
        focus: focus,
        difficulty: difficulty ?? 'medium',
        mood: mood,
        useSupersets: useSupersets,
        equipment: equipment ?? [],
        injuries: injuries ?? [],
        exerciseLibrary: offlineExercises,
        fitnessLevel: fitnessLevel,
        oneRepMaxes: merged1rms,
        stapleExercises: const [],
        avoidedExercises: const [],
        recentlyUsedExercises: recentExercises,
        goal: goal,
        muscleRecoveryScores: recoveryScores,
        sessionsSinceLastUse: sessionsSinceLastUse,
        equipmentContext: eqContext,
        rpeFeedback: rpeSummaries,
        weeklyVolume: weeklyVolume,
        volumeLandmarks: effectiveLandmarks,
        mesocycleContext: mesocycleContext,
        collaborativeScores: collaborativeScores,
        sfrScores: sfrScores,
        hrvModifiers: hrvModifiers,
      );

      debugPrint('[QuickWorkout] Generated locally: ${workout.name} '
          '(${workout.exercises.length} exercises, ~${workout.estimatedDurationMinutes}min)');

      // 7b. Apply scheduled date override if user chose "Change Date"
      if (scheduledDate != null) {
        final dateStr = '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
        workout = workout.copyWith(scheduledDate: dateStr);
        debugPrint('[QuickWorkout] Overriding scheduled date to $dateStr');
      }

      // 8. Save variety data
      final newExerciseNames = workout.exercises.map((e) => e.name).join(',');
      final updatedRecent = [...recentJson, newExerciseNames];
      if (updatedRecent.length > 5) {
        updatedRecent.removeRange(0, updatedRecent.length - 5);
      }
      await prefs.setStringList('quick_workout_recent_exercises', updatedRecent);

      // 8b. Record weekly volume tracking
      final workoutMuscleSetCounts = <String, int>{};
      for (final ex in workout.exercises) {
        final muscle = (ex.muscleGroup ?? ex.primaryMuscle ?? '').toLowerCase();
        if (muscle.isNotEmpty) {
          workoutMuscleSetCounts[muscle] =
              (workoutMuscleSetCounts[muscle] ?? 0) + (ex.sets ?? 1);
        }
      }
      if (workoutMuscleSetCounts.isNotEmpty) {
        await WeeklyVolumeTracker.recordWorkoutVolume(workoutMuscleSetCounts);
      }

      // 8b2. Record SFR-adjusted fatigue volume (Feature 1)
      final fatigueSets = <String, double>{};
      for (final ex in workout.exercises) {
        final muscle = (ex.muscleGroup ?? ex.primaryMuscle ?? '').toLowerCase();
        if (muscle.isNotEmpty) {
          final exName = ex.name.toLowerCase();
          final sfrData = await SfrScoreService.getSfr(exName);
          final rawSets = ex.sets ?? 1;
          fatigueSets[muscle] =
              (fatigueSets[muscle] ?? 0.0) + (rawSets * sfrData.systemicFatigue);
        }
      }
      if (fatigueSets.isNotEmpty) {
        await WeeklyVolumeTracker.recordWorkoutVolumeSfr(fatigueSets);
      }

      // 8c. Record muscle recovery data from this workout
      final muscleSetCounts = <String, (int, double)>{};
      for (final ex in workout.exercises) {
        final muscle = (ex.muscleGroup ?? ex.primaryMuscle ?? '').toLowerCase();
        if (muscle.isNotEmpty) {
          final existing = muscleSetCounts[muscle];
          final sets = ex.sets ?? 1;
          final intensity = 0.8; // Default moderate intensity
          if (existing != null) {
            muscleSetCounts[muscle] = (existing.$1 + sets, (existing.$2 + intensity) / 2);
          } else {
            muscleSetCounts[muscle] = (sets, intensity);
          }
        }
      }
      if (muscleSetCounts.isNotEmpty) {
        await MuscleRecoveryTracker.recordWorkout(muscleSetCounts);
      }

      // 8c. Update exercise session tracking
      final updatedSessions = Map<String, int>.from(sessionsSinceLastUse);
      // Increment all existing by 1 (one more session has passed)
      for (final key in updatedSessions.keys.toList()) {
        updatedSessions[key] = updatedSessions[key]! + 1;
      }
      // Reset exercises used in this workout to 0
      for (final ex in workout.exercises) {
        final name = ex.name.toLowerCase();
        if (name.isNotEmpty) updatedSessions[name] = 0;
      }
      await prefs.setString('quick_workout_exercise_sessions', jsonEncode(updatedSessions));

      // 8d. Record DUP session goal
      await DupRotation.recordSession(effectiveGoal);

      // 9. Update state immediately (instant UX)
      state = state.copyWith(
        isGenerating: false,
        generatedWorkout: workout,
        lastDuration: duration,
        lastFocus: focus,
        statusMessage: 'Workout ready!',
      );

      // 10. Persist to backend async (fire-and-forget)
      _persistToBackend(workout);

      return workout;
    } catch (e) {
      debugPrint('[QuickWorkout] Local generation error: $e');
      // Try API fallback
      try {
        return _generateViaApi(
          userId: userId,
          duration: duration,
          focus: focus,
          difficulty: difficulty,
          goal: goal,
          equipment: equipment,
          injuries: injuries,
        );
      } catch (apiError) {
        debugPrint('[QuickWorkout] API fallback also failed: $apiError');
        state = state.copyWith(
          isGenerating: false,
          error: 'Failed to generate workout. Please try again.',
        );
        return null;
      }
    }
  }

  /// Original API-based generation (fallback when cache is small).
  Future<Workout?> _generateViaApi({
    required String userId,
    required int duration,
    String? focus,
    String? difficulty,
    String? goal,
    List<String>? equipment,
    List<String>? injuries,
  }) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'duration': duration,
      'focus': focus,
    };
    if (difficulty != null) data['difficulty'] = difficulty;
    if (goal != null) data['goal'] = goal;
    if (equipment != null && equipment.isNotEmpty) data['equipment'] = equipment;
    if (injuries != null && injuries.isNotEmpty) data['injuries'] = injuries;

    final response = await _apiClient.post(
      '${ApiConstants.workouts}/quick',
      data: data,
    );

    if (response.statusCode == 200) {
      final respData = response.data as Map<String, dynamic>;
      final workoutData = respData['workout'] as Map<String, dynamic>;
      final workout = Workout.fromJson(workoutData);

      debugPrint('[QuickWorkout] Generated via API: ${workout.name}');
      state = state.copyWith(
        isGenerating: false,
        generatedWorkout: workout,
        lastDuration: duration,
        lastFocus: focus,
        statusMessage: 'Workout ready!',
      );

      return workout;
    } else {
      throw Exception('Failed to generate workout: ${response.statusCode}');
    }
  }

  /// Fire-and-forget persistence to backend for history + analytics.
  void _persistToBackend(Workout workout) {
    _apiClient.post(
      '${ApiConstants.workouts}/quick/save',
      data: {
        'workout': workout.toJson(),
        'source': 'quick_button',
        'generation_method': 'quick_rule_based',
        'generation_source': 'quick_workout',
        'generation_metadata': workout.generationMetadata,
      },
    ).then((_) {
      debugPrint('[QuickWorkout] Backend save successful');
    }).catchError((e) {
      debugPrint('[QuickWorkout] Backend save failed (will retry on sync): $e');
    });
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear generated workout
  void clearGeneratedWorkout() {
    state = state.copyWith(clearWorkout: true);
  }

  /// Reset state
  void reset() {
    state = const QuickWorkoutState();
  }

  /// Map focus area to primary muscle groups for collaborative scoring.
  static List<String> _focusToMuscles(String focus) {
    switch (focus.toLowerCase()) {
      case 'upper_body':
        return ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
      case 'lower_body':
        return ['quads', 'hamstrings', 'glutes', 'calves'];
      case 'core':
        return ['abs'];
      case 'chest':
        return ['chest'];
      case 'back':
        return ['back'];
      case 'strength':
        return ['chest', 'back', 'quads', 'shoulders'];
      case 'full_body':
      default:
        return ['chest', 'back', 'quads', 'shoulders', 'biceps', 'triceps',
                'hamstrings', 'glutes'];
    }
  }
}

// ============================================
// Providers
// ============================================

/// Main quick workout provider
final quickWorkoutProvider =
    StateNotifierProvider<QuickWorkoutNotifier, QuickWorkoutState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return QuickWorkoutNotifier(apiClient, db, ref);
});

/// Whether quick workout is generating (convenience provider)
final isQuickWorkoutGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(quickWorkoutProvider).isGenerating;
});

/// Generated quick workout (convenience provider)
final generatedQuickWorkoutProvider = Provider<Workout?>((ref) {
  return ref.watch(quickWorkoutProvider).generatedWorkout;
});

/// Quick workout error (convenience provider)
final quickWorkoutErrorProvider = Provider<String?>((ref) {
  return ref.watch(quickWorkoutProvider).error;
});

// ============================================
// Quick Workout Preferences
// ============================================

/// Fetches and caches user's quick workout preferences
final quickWorkoutPreferencesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();

  if (userId == null) {
    return {
      'preferred_duration': 10,
      'preferred_focus': null,
      'quick_workout_count': 0,
    };
  }

  try {
    final response = await apiClient.get(
      '${ApiConstants.workouts}/quick/preferences/$userId',
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('[QuickWorkout] Failed to fetch preferences: $e');
  }

  return {
    'preferred_duration': 10,
    'preferred_focus': null,
    'quick_workout_count': 0,
  };
});
