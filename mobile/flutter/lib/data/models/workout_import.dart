/// Models for the AI "Import workout" flow (photo / screenshot / text / video →
/// structured workout the user reviews, then saves into their Custom workouts).
///
/// Mirrors the backend contract in `backend/api/v1/saved_workouts.py`:
///   POST /saved-workouts/import-ai        → { workout?, job_id?, status }
///   POST /saved-workouts/import-ai/save   → { workout_id, name, generation_source }
///   GET  /media-jobs/{id}  (video)        → result_json: `{ workout: ExtractedWorkout }`
library;

class ImportedWorkoutExercise {
  final String name;
  final int sets;
  final int? reps;
  final int? restSeconds;
  final int? durationSeconds;
  final double? weightKg;
  final String? muscleGroup;
  final String? notes;

  ImportedWorkoutExercise({
    required this.name,
    this.sets = 3,
    this.reps,
    this.restSeconds = 60,
    this.durationSeconds,
    this.weightKg,
    this.muscleGroup,
    this.notes,
  });

  factory ImportedWorkoutExercise.fromJson(Map<String, dynamic> j) {
    int? asInt(dynamic v) => v == null ? null : (v as num).toInt();
    double? asDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return ImportedWorkoutExercise(
      name: (j['name'] ?? '').toString(),
      sets: asInt(j['sets']) ?? 3,
      reps: asInt(j['reps']),
      restSeconds: asInt(j['rest_seconds']) ?? 60,
      durationSeconds: asInt(j['duration_seconds']),
      weightKg: asDouble(j['weight_kg']),
      muscleGroup: j['muscle_group']?.toString(),
      notes: j['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (restSeconds != null) 'rest_seconds': restSeconds,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (weightKg != null) 'weight_kg': weightKg,
        if (muscleGroup != null) 'muscle_group': muscleGroup,
        if (notes != null) 'notes': notes,
      };

  ImportedWorkoutExercise copyWith({String? name, int? sets, int? reps}) =>
      ImportedWorkoutExercise(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        restSeconds: restSeconds,
        durationSeconds: durationSeconds,
        weightKg: weightKg,
        muscleGroup: muscleGroup,
        notes: notes,
      );
}

class ImportedWorkout {
  final String name;
  final String workoutType;
  final String difficulty;
  final int estimatedDurationMinutes;
  final List<ImportedWorkoutExercise> exercises;
  final double? confidence;

  ImportedWorkout({
    required this.name,
    this.workoutType = 'strength',
    this.difficulty = 'medium',
    this.estimatedDurationMinutes = 45,
    required this.exercises,
    this.confidence,
  });

  factory ImportedWorkout.fromJson(Map<String, dynamic> j) => ImportedWorkout(
        name: (j['name'] ?? 'Imported workout').toString(),
        workoutType: (j['workout_type'] ?? 'strength').toString(),
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        estimatedDurationMinutes:
            (j['estimated_duration_minutes'] as num?)?.toInt() ?? 45,
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) => ImportedWorkoutExercise.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        confidence: (j['confidence'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toSavePayload({
    required String userId,
    String? sourceUrl,
  }) =>
      {
        'user_id': userId,
        'name': name,
        'workout_type': workoutType,
        'difficulty': difficulty,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        if (sourceUrl != null) 'source_url': sourceUrl,
      };

  ImportedWorkout copyWith({
    String? name,
    List<ImportedWorkoutExercise>? exercises,
  }) =>
      ImportedWorkout(
        name: name ?? this.name,
        workoutType: workoutType,
        difficulty: difficulty,
        estimatedDurationMinutes: estimatedDurationMinutes,
        exercises: exercises ?? this.exercises,
        confidence: confidence,
      );
}
