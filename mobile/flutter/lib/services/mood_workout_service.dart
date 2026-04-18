import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/providers/user_provider.dart';
import '../data/local/database.dart';
import '../data/local/database_provider.dart';
import '../data/models/mood.dart';
import '../data/models/workout.dart';
import '../data/models/workout_style.dart';
import '../data/repositories/offline_workout_repository.dart';
import '../data/services/exercise_library_loader.dart';
import 'hrv_recovery_service.dart';
import 'mood_workout_adaptation.dart';
import 'mood_workout_context.dart';
import 'mood_workout_presets.dart';
import 'mood_workout_wrapper.dart';
import 'muscle_recovery_tracker.dart';
import 'offline_workout_generator.dart';
import 'quick_workout_engine.dart';

/// Local-first mood workout generator.
///
/// Reuses [QuickWorkoutEngine] with a [MoodPreset]-derived parameter set so
/// the workout is produced in <500 ms without a network round-trip. The UI
/// calls [generateLocally], checks [existingWorkoutsForToday] to decide
/// Replace-vs-Add, then commits via [persist].
class MoodWorkoutService {
  final AppDatabase _db;
  final OfflineWorkoutRepository _offlineRepo;
  final Ref _ref;

  static const _uuid = Uuid();

  MoodWorkoutService(this._db, this._offlineRepo, this._ref);

  /// Generate a mood-tuned workout locally. The returned workout is NOT yet
  /// saved — the caller is expected to show Replace/Add UI first and then
  /// persist via [persist].
  Future<Workout> generateLocally({
    required Mood mood,
    required String userId,
    WorkoutStyle? style,
    String? difficulty,
    int? duration,
  }) async {
    final stopwatch = Stopwatch()..start();
    final preset = MoodPreset.forMood(mood);

    // If the user hasn't explicitly overridden style, check the personal
    // adaptation layer to see if they historically complete a different
    // style more often for this mood. Research default still ships as a
    // fallback via preset.recommendedStyle.
    final personalizedStyle = style != null
        ? null
        : await MoodWorkoutAdaptation.personalizedStyleFor(mood);

    var effectiveStyle = style ?? personalizedStyle ?? preset.recommendedStyle;
    var effectiveDifficulty = difficulty ?? preset.recommendedDifficulty;
    var effectiveDuration = duration ?? preset.recommendedDuration;

    // Safety gate: Tired + low recovery readiness → 10 min stretching.
    // (HRV/sleep-driven downgrade so users don't grind while fried.)
    if (mood == Mood.tired) {
      final hrv = await HrvRecoveryService.getModifiers();
      if (hrv.hasData && hrv.readinessLevel == ReadinessLevel.low) {
        effectiveStyle = WorkoutStyle.yogaStretch;
        effectiveDuration = effectiveDuration > 10 ? 10 : effectiveDuration;
        debugPrint(
          '🛡 [MoodWorkout] Tired + low readiness → capping to 10min stretch',
        );
      }
    }

    // Contextual intelligence: time-of-day, comeback streak, mood repeats,
    // general HRV downgrade. Only applies modifications the user didn't
    // explicitly override (we never undo a deliberate style pick, but we
    // may soft-cap difficulty / duration when context warrants it).
    final ctxAdjustment = await MoodWorkoutContext.evaluate(
      mood: mood,
      currentStyle: effectiveStyle,
      currentDifficulty: effectiveDifficulty,
      currentDuration: effectiveDuration,
    );
    if (ctxAdjustment.overrideStyle != null && style == null) {
      effectiveStyle = ctxAdjustment.overrideStyle!;
    }
    if (ctxAdjustment.overrideDifficulty != null && difficulty == null) {
      effectiveDifficulty = ctxAdjustment.overrideDifficulty!;
    }
    if (ctxAdjustment.durationCapMinutes != null) {
      effectiveDuration = effectiveDuration > ctxAdjustment.durationCapMinutes!
          ? ctxAdjustment.durationCapMinutes!
          : effectiveDuration;
    }
    // Record the mood pick AFTER context evaluation so the current session
    // doesn't inflate its own repeat count.
    await MoodWorkoutContext.recordMoodPick(mood);

    // User context.
    final userAsync = _ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    final fitnessLevel = user?.fitnessLevel ?? 'intermediate';
    final userEquipment = user?.equipmentList ?? const <String>[];
    final userInjuries = user?.injuriesList ?? const <String>[];

    // If the user has no saved equipment and picked Weights, downgrade to
    // Bodyweight rather than producing an all-barbell workout that can't be
    // done.
    if (effectiveStyle == WorkoutStyle.weights && userEquipment.isEmpty) {
      effectiveStyle = WorkoutStyle.bodyweight;
      debugPrint('🔁 [MoodWorkout] No equipment saved → downgrading Weights → Bodyweight');
    }

    final availableEquipment = _availableEquipmentFor(effectiveStyle, userEquipment);

    // Load library (Drift first, bundled asset as fallback).
    final library = await _loadExerciseLibrary();

    // Recent exercise names for variety.
    final prefs = await SharedPreferences.getInstance();
    final recentRaw = prefs.getStringList('mood_workout_recent') ?? [];
    final recentExercises =
        recentRaw.expand((s) => s.split(',')).where((s) => s.isNotEmpty).toSet();

    final recoveryScores = await MuscleRecoveryTracker.getAllRecoveryScores();

    // Resolve focus. For strength-style moods the focus rotates by weekday
    // so a user tapping Motivated every day across the week naturally hits
    // the full push/pull/legs split.
    final focus = _resolveFocus(effectiveStyle, mood);

    final engine = QuickWorkoutEngine();
    var workout = engine.generate(
      userId: userId,
      durationMinutes: effectiveDuration,
      focus: focus,
      difficulty: effectiveDifficulty,
      mood: preset.engineMoodKey,
      useSupersets: preset.useSupersets,
      equipment: availableEquipment,
      injuries: userInjuries,
      exerciseLibrary: library,
      fitnessLevel: fitnessLevel,
      oneRepMaxes: const {},
      stapleExercises: const [],
      avoidedExercises: const [],
      recentlyUsedExercises: recentExercises,
      goal: preset.goal,
      muscleRecoveryScores: recoveryScores,
    );

    // Decorate with mood metadata + fresh ID + today's scheduled date so it
    // always lands in the today carousel.
    final todayStr = _todayIsoDate();
    workout = workout.copyWith(
      id: workout.id ?? _uuid.v4(),
      scheduledDate: todayStr,
      generationMethod: 'mood_rule_based',
      generationMetadata: {
        ...?workout.generationMetadata,
        'generator': 'mood_rule_based',
        'mood': mood.value,
        'mood_emoji': mood.emoji,
        'mood_color': _colorHex(mood.colorValue),
        'style': effectiveStyle.value,
        'style_was_overridden': style != null,
        'difficulty': effectiveDifficulty,
        'difficulty_was_overridden': difficulty != null,
        'duration': effectiveDuration,
        'duration_was_overridden': duration != null,
        'recommended_style': preset.recommendedStyle.value,
        'recommended_difficulty': preset.recommendedDifficulty,
        'evidence_grade': preset.evidenceGrade,
        'latency_ms': stopwatch.elapsedMilliseconds,
        if (ctxAdjustment.caption != null)
          'context_caption': ctxAdjustment.caption,
      },
    );

    // Decorate with mood-specific name / quote / music / breath / finishers.
    workout = MoodWorkoutWrapper.decorate(
      workout,
      mood: mood,
      style: effectiveStyle,
      difficulty: effectiveDifficulty,
    );

    // Record recent-exercise trail for variety on the next generation.
    final newNames = workout.exercises.map((e) => e.name).join(',');
    final updated = [...recentRaw, newNames];
    if (updated.length > 5) updated.removeRange(0, updated.length - 5);
    await prefs.setStringList('mood_workout_recent', updated);

    // Record for personal adaptation (per-mood style propensity).
    await MoodWorkoutAdaptation.recordGeneration(mood, effectiveStyle);

    stopwatch.stop();
    debugPrint(
      '🎯 [MoodWorkout] Generated "${workout.name}" '
      '(mood=${mood.value}, style=${effectiveStyle.value}, '
      'difficulty=$effectiveDifficulty, duration=${effectiveDuration}m, '
      '${workout.exercises.length} exercises) in ${stopwatch.elapsedMilliseconds}ms',
    );
    return workout;
  }

  /// Persist the workout to Drift + enqueue sync. Call after the Replace/Add
  /// decision has been made.
  Future<void> persist(Workout workout, String userId) async {
    await _offlineRepo.saveLocalWorkout(workout, userId);
  }

  /// Returns workouts scheduled for today (used by the sheet to decide
  /// whether to show Replace/Add).
  Future<List<Workout>> existingWorkoutsForToday(String userId) async {
    final today = _todayIsoDate();
    final cached =
        await _db.workoutDao.getWorkoutsForDateRange(userId, today, today);
    return cached.map(_cachedToWorkout).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<List<OfflineExercise>> _loadExerciseLibrary() async {
    var cached = await _db.exerciseLibraryDao.getAllCachedExercises();
    if (cached.length < 50) {
      // Seed from the bundled JSON asset so first-run users still get a
      // workout even before exercise sync finishes.
      await ExerciseLibraryLoader.seedDatabaseIfNeeded(_db);
      cached = await _db.exerciseLibraryDao.getAllCachedExercises();
    }
    return cached.map(_cachedToOffline).toList();
  }

  OfflineExercise _cachedToOffline(dynamic c) {
    // `c` is a Drift `CachedExercise` row. We use `dynamic` here to avoid
    // importing the generated companion/table type directly; the field names
    // are stable across the schema.
    List<String>? secondary;
    final raw = c.secondaryMuscles as String?;
    if (raw != null && raw.isNotEmpty) {
      // Accept both JSON arrays and comma-separated legacy rows.
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          secondary = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        secondary = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return OfflineExercise(
      id: c.id as String,
      name: c.name as String,
      bodyPart: c.bodyPart as String?,
      equipment: c.equipment as String?,
      targetMuscle: c.targetMuscle as String?,
      primaryMuscle: c.primaryMuscle as String?,
      secondaryMuscles: secondary,
      difficulty: c.difficulty as String?,
      difficultyNum: c.difficultyNum as int?,
      videoUrl: c.videoUrl as String?,
      imageS3Path: c.imageS3Path as String?,
    );
  }

  Workout _cachedToWorkout(dynamic c) {
    dynamic exercisesJson;
    try {
      exercisesJson = jsonDecode(c.exercisesJson as String);
    } catch (_) {
      exercisesJson = c.exercisesJson;
    }
    Map<String, dynamic>? meta;
    final rawMeta = c.generationMetadata as String?;
    if (rawMeta != null) {
      try {
        meta = jsonDecode(rawMeta) as Map<String, dynamic>;
      } catch (_) {}
    }
    return Workout(
      id: c.id as String?,
      userId: c.userId as String?,
      name: c.name as String?,
      type: c.type as String?,
      difficulty: c.difficulty as String?,
      scheduledDate: c.scheduledDate as String?,
      isCompleted: c.isCompleted as bool?,
      exercisesJson: exercisesJson,
      durationMinutes: c.durationMinutes as int?,
      generationMethod: c.generationMethod as String?,
      generationMetadata: meta,
      createdAt: (c.createdAt as DateTime?)?.toIso8601String(),
    );
  }

  List<String> _availableEquipmentFor(
    WorkoutStyle style,
    List<String> userEquipment,
  ) {
    switch (style) {
      case WorkoutStyle.bodyweight:
      case WorkoutStyle.yogaStretch:
        return const ['bodyweight'];
      case WorkoutStyle.cardio:
        // Cardio tolerates any equipment but defaults to bodyweight cardio
        // if none saved (jumping jacks, burpees, etc.).
        return userEquipment.isNotEmpty ? userEquipment : const ['bodyweight'];
      case WorkoutStyle.weights:
      case WorkoutStyle.mixed:
        return userEquipment.isNotEmpty ? userEquipment : const ['bodyweight'];
    }
  }

  String _resolveFocus(WorkoutStyle style, Mood mood) {
    if (style == WorkoutStyle.cardio) return 'cardio';
    if (style == WorkoutStyle.yogaStretch) return 'stretch';

    // For strength-style picks: rotate push/pull/legs by weekday so a user
    // tapping Motivated every day across the week hits the full split.
    if (mood == Mood.motivated || mood == Mood.focused) {
      final wd = DateTime.now().weekday; // 1..7
      if (wd == DateTime.monday || wd == DateTime.thursday) return 'push';
      if (wd == DateTime.tuesday || wd == DateTime.friday) return 'pull';
      if (wd == DateTime.wednesday || wd == DateTime.saturday) return 'legs';
      return 'full_body';
    }

    return 'full_body';
  }

  String _todayIsoDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _colorHex(int argb) {
    final hex = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
    // Drop alpha for a 6-digit web-style hex.
    return '#${hex.substring(2)}';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final moodWorkoutServiceProvider = Provider<MoodWorkoutService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ref.watch(offlineWorkoutRepositoryProvider);
  return MoodWorkoutService(db, repo, ref);
});
