import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers/generation_mode_provider.dart';
import '../data/local/database.dart';
import '../data/local/database_provider.dart';
import '../data/models/workout.dart';
import '../data/repositories/offline_workout_repository.dart';
import '../data/services/connectivity_service.dart';
import 'offline_workout_generator.dart';
import 'on_device_gemma_service.dart';

/// Orchestrates workout generation using the user's selected mode.
///
/// Flow:
///   1. Check pre-cached workouts → Hit? Return cached
///   2. Use user's selected mode (strict, NO fallback between modes):
///      - Cloud AI → call backend /generate-stream
///      - On-Device AI → Gemma via flutter_gemma
///      - Rule-Based → algorithmic generation (always succeeds)
///
/// If a mode fails, we show an error — NOT silently fall back.
class WorkoutGenerationOrchestrator {
  final AppDatabase _db;
  final OfflineWorkoutRepository _offlineRepo;
  final Ref _ref;

  WorkoutGenerationOrchestrator(this._db, this._offlineRepo, this._ref);

  /// Generate or retrieve a workout for the given date.
  ///
  /// Returns a [Workout] if successful, or throws an exception with
  /// a user-friendly message if generation fails.
  Future<Workout> getOrGenerateWorkout({
    required String userId,
    required String splitType,
    String? scheduledDate,
    String fitnessLevel = 'intermediate',
    String goal = 'muscle_hypertrophy',
    List<String> availableEquipment = const [],
    List<String> avoidedExercises = const [],
    List<String> avoidedMuscles = const [],
    List<String> injuries = const [],
    List<String> stapleExercises = const [],
    Map<String, double> oneRepMaxes = const {},
  }) async {
    final dateStr = scheduledDate ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Step 1: Check pre-cached workouts
    final cached = await _checkPreCached(userId, dateStr);
    if (cached != null) {
      debugPrint('✅ [Orchestrator] Using pre-cached workout for $dateStr');
      return cached;
    }

    // Step 2: Use user's selected generation mode (strict)
    final mode = _ref.read(generationModeProvider);
    debugPrint('🔄 [Orchestrator] Generating workout via mode: $mode');

    switch (mode) {
      case WorkoutGenerationMode.cloudAI:
        return _generateCloudAI(userId, dateStr);

      case WorkoutGenerationMode.onDeviceAI:
        return _generateOnDeviceAI(
          userId: userId,
          splitType: splitType,
          scheduledDate: dateStr,
          fitnessLevel: fitnessLevel,
          goal: goal,
          availableEquipment: availableEquipment,
          avoidedExercises: avoidedExercises,
          injuries: injuries,
        );

      case WorkoutGenerationMode.ruleBased:
        return _generateRuleBased(
          userId: userId,
          splitType: splitType,
          scheduledDate: dateStr,
          fitnessLevel: fitnessLevel,
          goal: goal,
          availableEquipment: availableEquipment,
          avoidedExercises: avoidedExercises,
          avoidedMuscles: avoidedMuscles,
          injuries: injuries,
          stapleExercises: stapleExercises,
          oneRepMaxes: oneRepMaxes,
        );
    }
  }

  /// Check if a workout is pre-cached for this date.
  Future<Workout?> _checkPreCached(String userId, String dateStr) async {
    final workouts =
        await _db.workoutDao.getWorkoutsForDateRange(userId, dateStr, dateStr);
    if (workouts.isNotEmpty) {
      final cached = workouts.first;
      dynamic exercisesJson;
      try {
        exercisesJson = jsonDecode(cached.exercisesJson);
      } catch (_) {
        exercisesJson = cached.exercisesJson;
      }

      Map<String, dynamic>? genMeta;
      if (cached.generationMetadata != null) {
        try {
          genMeta =
              jsonDecode(cached.generationMetadata!) as Map<String, dynamic>;
        } catch (_) {}
      }

      return Workout(
        id: cached.id,
        userId: cached.userId,
        name: cached.name,
        type: cached.type,
        difficulty: cached.difficulty,
        scheduledDate: cached.scheduledDate,
        isCompleted: cached.isCompleted,
        exercisesJson: exercisesJson,
        durationMinutes: cached.durationMinutes,
        generationMethod: cached.generationMethod,
        generationMetadata: genMeta,
      );
    }
    return null;
  }

  /// Generate via Cloud AI (existing server-side flow).
  /// Requires internet — throws if offline.
  Future<Workout> _generateCloudAI(String userId, String dateStr) async {
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      throw Exception(
          'Cloud AI requires an internet connection. '
          'Connect to the internet or switch to Rule-Based mode in Settings.');
    }

    // Delegate to existing server-side generation
    // The existing today_workout_provider handles this flow
    throw Exception(
        'Cloud AI generation should be handled by the existing '
        'TodayWorkoutNotifier polling flow. This path indicates a '
        'routing error in the orchestrator.');
  }

  /// Generate via on-device Gemma AI.
  Future<Workout> _generateOnDeviceAI({
    required String userId,
    required String splitType,
    required String scheduledDate,
    required String fitnessLevel,
    required String goal,
    required List<String> availableEquipment,
    required List<String> avoidedExercises,
    required List<String> injuries,
  }) async {
    try {
      final gemmaService = _ref.read(onDeviceGemmaServiceProvider);

      if (!gemmaService.isModelLoaded) {
        throw Exception(
            'AI model not loaded. Please download the AI model in Settings → Offline Mode.');
      }

      final workout = await gemmaService.generateWorkout(
        splitType: splitType,
        fitnessLevel: fitnessLevel,
        availableEquipment: availableEquipment,
        goal: goal,
        avoidedExercises: avoidedExercises,
        injuries: injuries,
        userId: userId,
        scheduledDate: scheduledDate,
      );

      // Save to local DB
      await _offlineRepo.saveLocalWorkout(workout, userId);
      debugPrint('✅ [Orchestrator] On-device AI workout generated and saved');
      return workout;
    } catch (e) {
      debugPrint('❌ [Orchestrator] On-device AI failed: $e');
      // NO FALLBACK — rethrow for UI to handle
      rethrow;
    }
  }

  /// Generate via rule-based algorithm (always succeeds, all devices).
  Future<Workout> _generateRuleBased({
    required String userId,
    required String splitType,
    required String scheduledDate,
    required String fitnessLevel,
    required String goal,
    required List<String> availableEquipment,
    required List<String> avoidedExercises,
    required List<String> avoidedMuscles,
    required List<String> injuries,
    required List<String> stapleExercises,
    required Map<String, double> oneRepMaxes,
  }) async {
    // Get cached exercise library
    final cachedExercises = await _db.exerciseLibraryDao.getAllCachedExercises();

    // Convert CachedExercise to OfflineExercise
    final offlineExercises = cachedExercises.map((ce) {
      List<String>? secondaryMuscles;
      if (ce.secondaryMuscles != null) {
        try {
          secondaryMuscles =
              (jsonDecode(ce.secondaryMuscles!) as List).cast<String>();
        } catch (_) {}
      }

      return OfflineExercise(
        id: ce.id,
        name: ce.name,
        bodyPart: ce.bodyPart,
        equipment: ce.equipment,
        targetMuscle: ce.targetMuscle,
        primaryMuscle: ce.primaryMuscle,
        secondaryMuscles: secondaryMuscles,
        difficulty: ce.difficulty,
        difficultyNum: ce.difficultyNum,
      );
    }).toList();

    final generator = OfflineWorkoutGenerator();
    final workout = generator.generate(
      userId: userId,
      splitType: splitType,
      scheduledDate: scheduledDate,
      exerciseLibrary: offlineExercises,
      fitnessLevel: fitnessLevel,
      goal: goal,
      availableEquipment: availableEquipment,
      avoidedExercises: avoidedExercises,
      avoidedMuscles: avoidedMuscles,
      injuries: injuries,
      stapleExercises: stapleExercises,
      oneRepMaxes: oneRepMaxes,
    );

    // Save to local DB
    await _offlineRepo.saveLocalWorkout(workout, userId);
    debugPrint('✅ [Orchestrator] Rule-based workout generated and saved');
    return workout;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Workout generation orchestrator provider.
final workoutGenerationOrchestratorProvider =
    Provider<WorkoutGenerationOrchestrator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final offlineRepo = ref.watch(offlineWorkoutRepositoryProvider);
  return WorkoutGenerationOrchestrator(db, offlineRepo, ref);
});
