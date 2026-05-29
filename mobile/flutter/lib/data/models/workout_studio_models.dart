import 'package:flutter/foundation.dart';

/// Customization Studio param set — mirrors backend `WorkoutBuildParams`.
/// Manual JSON (no codegen; build_runner is banned in this repo).
@immutable
class WorkoutBuildParams {
  final List<String> focusAreas;
  final List<String>? equipment; // null => use profile equipment
  final String intensity; // light | moderate | intense
  final int durationMinutes;
  final String trainingStyle; // strength | hypertrophy | endurance | circuit
  final int warmupMinutes;
  final int cooldownMinutes;
  final List<String> soreAreas; // transient; never persisted to profile
  final String impactLevel; // low | normal | high
  final bool? supersets; // null => auto
  final bool? amrap; // null => auto
  final bool prioritizeStaples;
  final int? exerciseCount;
  final List<String> avoidExercises;
  final List<String> excludeCurrent;
  final bool activeRecovery;
  final int? seed;

  const WorkoutBuildParams({
    this.focusAreas = const ['full_body'],
    this.equipment,
    this.intensity = 'moderate',
    this.durationMinutes = 20,
    this.trainingStyle = 'hypertrophy',
    this.warmupMinutes = 5,
    this.cooldownMinutes = 5,
    this.soreAreas = const [],
    this.impactLevel = 'normal',
    this.supersets,
    this.amrap,
    this.prioritizeStaples = false,
    this.exerciseCount,
    this.avoidExercises = const [],
    this.excludeCurrent = const [],
    this.activeRecovery = false,
    this.seed,
  });

  WorkoutBuildParams copyWith({
    List<String>? focusAreas,
    List<String>? equipment,
    bool clearEquipment = false,
    String? intensity,
    int? durationMinutes,
    String? trainingStyle,
    int? warmupMinutes,
    int? cooldownMinutes,
    List<String>? soreAreas,
    String? impactLevel,
    bool? supersets,
    bool clearSupersets = false,
    bool? amrap,
    bool clearAmrap = false,
    bool? prioritizeStaples,
    int? exerciseCount,
    bool clearExerciseCount = false,
    List<String>? avoidExercises,
    List<String>? excludeCurrent,
    bool? activeRecovery,
  }) {
    return WorkoutBuildParams(
      focusAreas: focusAreas ?? this.focusAreas,
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      intensity: intensity ?? this.intensity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      trainingStyle: trainingStyle ?? this.trainingStyle,
      warmupMinutes: warmupMinutes ?? this.warmupMinutes,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      soreAreas: soreAreas ?? this.soreAreas,
      impactLevel: impactLevel ?? this.impactLevel,
      supersets: clearSupersets ? null : (supersets ?? this.supersets),
      amrap: clearAmrap ? null : (amrap ?? this.amrap),
      prioritizeStaples: prioritizeStaples ?? this.prioritizeStaples,
      exerciseCount:
          clearExerciseCount ? null : (exerciseCount ?? this.exerciseCount),
      avoidExercises: avoidExercises ?? this.avoidExercises,
      excludeCurrent: excludeCurrent ?? this.excludeCurrent,
      activeRecovery: activeRecovery ?? this.activeRecovery,
      seed: seed,
    );
  }

  Map<String, dynamic> toJson() => {
        'focus_areas': focusAreas,
        if (equipment != null) 'equipment': equipment,
        'intensity': intensity,
        'duration_minutes': durationMinutes,
        'training_style': trainingStyle,
        'warmup_minutes': warmupMinutes,
        'cooldown_minutes': cooldownMinutes,
        'sore_areas': soreAreas,
        'impact_level': impactLevel,
        if (supersets != null) 'supersets': supersets,
        if (amrap != null) 'amrap': amrap,
        'prioritize_staples': prioritizeStaples,
        if (exerciseCount != null) 'exercise_count': exerciseCount,
        'avoid_exercises': avoidExercises,
        'exclude_current': excludeCurrent,
        'active_recovery': activeRecovery,
        if (seed != null) 'seed': seed,
      };

  factory WorkoutBuildParams.fromJson(Map<String, dynamic> j) {
    List<String> ls(dynamic v) =>
        (v is List) ? v.map((e) => e.toString()).toList() : <String>[];
    return WorkoutBuildParams(
      focusAreas: j['focus_areas'] != null ? ls(j['focus_areas']) : const ['full_body'],
      equipment: j['equipment'] != null ? ls(j['equipment']) : null,
      intensity: j['intensity'] as String? ?? 'moderate',
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 20,
      trainingStyle: j['training_style'] as String? ?? 'hypertrophy',
      warmupMinutes: (j['warmup_minutes'] as num?)?.toInt() ?? 5,
      cooldownMinutes: (j['cooldown_minutes'] as num?)?.toInt() ?? 5,
      soreAreas: ls(j['sore_areas']),
      impactLevel: j['impact_level'] as String? ?? 'normal',
      supersets: j['supersets'] as bool?,
      amrap: j['amrap'] as bool?,
      prioritizeStaples: j['prioritize_staples'] as bool? ?? false,
      exerciseCount: (j['exercise_count'] as num?)?.toInt(),
      avoidExercises: ls(j['avoid_exercises']),
      excludeCurrent: ls(j['exclude_current']),
      activeRecovery: j['active_recovery'] as bool? ?? false,
      seed: (j['seed'] as num?)?.toInt(),
    );
  }
}

/// Engine output — mirrors backend `BuiltWorkout`. Exercises stay as raw maps
/// so they round-trip into the existing workout/exercise rendering.
@immutable
class BuiltWorkout {
  final String name;
  final String type;
  final String difficulty;
  final int durationMinutes;
  final List<String> targetMuscles;
  final List<Map<String, dynamic>> warmup;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> cooldown;
  final List<String> relaxedConstraints;
  final String? notes;
  final String? workoutId;

  const BuiltWorkout({
    required this.name,
    required this.type,
    required this.difficulty,
    required this.durationMinutes,
    this.targetMuscles = const [],
    this.warmup = const [],
    this.exercises = const [],
    this.cooldown = const [],
    this.relaxedConstraints = const [],
    this.notes,
    this.workoutId,
  });

  int get totalExercises => exercises.length;

  static List<Map<String, dynamic>> _maps(dynamic v) => (v is List)
      ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'target_muscles': targetMuscles,
        'warmup': warmup,
        'exercises': exercises,
        'cooldown': cooldown,
        'relaxed_constraints': relaxedConstraints,
        if (notes != null) 'notes': notes,
        if (workoutId != null) 'workout_id': workoutId,
      };

  factory BuiltWorkout.fromJson(Map<String, dynamic> j) => BuiltWorkout(
        name: j['name'] as String? ?? 'Workout',
        type: j['type'] as String? ?? 'full_body',
        difficulty: j['difficulty'] as String? ?? 'moderate',
        durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 20,
        targetMuscles: (j['target_muscles'] is List)
            ? (j['target_muscles'] as List).map((e) => e.toString()).toList()
            : const [],
        warmup: _maps(j['warmup']),
        exercises: _maps(j['exercises']),
        cooldown: _maps(j['cooldown']),
        relaxedConstraints: (j['relaxed_constraints'] is List)
            ? (j['relaxed_constraints'] as List).map((e) => e.toString()).toList()
            : const [],
        notes: j['notes'] as String?,
        workoutId: j['workout_id'] as String?,
      );
}

/// A saved Customization Studio preset.
@immutable
class WorkoutPreset {
  final String id;
  final String name;
  final WorkoutBuildParams params;

  const WorkoutPreset({required this.id, required this.name, required this.params});

  factory WorkoutPreset.fromJson(Map<String, dynamic> j) => WorkoutPreset(
        id: j['id'].toString(),
        name: j['name'] as String? ?? 'Preset',
        params: WorkoutBuildParams.fromJson(
            Map<String, dynamic>.from(j['params'] as Map? ?? const {})),
      );
}
