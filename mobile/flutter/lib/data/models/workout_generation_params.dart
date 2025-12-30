/// Model for workout generation parameters and AI reasoning
class WorkoutGenerationParams {
  final String workoutId;
  final String? workoutName;
  final String? workoutType;
  final String? difficulty;
  final int? durationMinutes;
  final String? generationMethod;
  final UserProfile userProfile;
  final ProgramPrefs programPreferences;
  final String workoutReasoning;
  final List<ExerciseReasoning> exerciseReasoning;
  final List<String> targetMuscles;

  WorkoutGenerationParams({
    required this.workoutId,
    this.workoutName,
    this.workoutType,
    this.difficulty,
    this.durationMinutes,
    this.generationMethod,
    required this.userProfile,
    required this.programPreferences,
    required this.workoutReasoning,
    required this.exerciseReasoning,
    required this.targetMuscles,
  });

  factory WorkoutGenerationParams.fromJson(Map<String, dynamic> json) {
    return WorkoutGenerationParams(
      workoutId: json['workout_id'] as String? ?? '',
      workoutName: json['workout_name'] as String?,
      workoutType: json['workout_type'] as String?,
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      generationMethod: json['generation_method'] as String?,
      userProfile: UserProfile.fromJson(
        json['user_profile'] as Map<String, dynamic>? ?? {},
      ),
      programPreferences: ProgramPrefs.fromJson(
        json['program_preferences'] as Map<String, dynamic>? ?? {},
      ),
      workoutReasoning: json['workout_reasoning'] as String? ?? '',
      exerciseReasoning: (json['exercise_reasoning'] as List<dynamic>?)
              ?.map((e) => ExerciseReasoning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      targetMuscles: (json['target_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_id': workoutId,
        'workout_name': workoutName,
        'workout_type': workoutType,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'generation_method': generationMethod,
        'user_profile': userProfile.toJson(),
        'program_preferences': programPreferences.toJson(),
        'workout_reasoning': workoutReasoning,
        'exercise_reasoning': exerciseReasoning.map((e) => e.toJson()).toList(),
        'target_muscles': targetMuscles,
      };
}

/// User profile data used for workout generation
class UserProfile {
  final String? fitnessLevel;
  final List<String> goals;
  final List<String> equipment;
  final List<String> injuries;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender;

  UserProfile({
    this.fitnessLevel,
    this.goals = const [],
    this.equipment = const [],
    this.injuries = const [],
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fitnessLevel: json['fitness_level'] as String?,
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      injuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      age: json['age'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fitness_level': fitnessLevel,
        'goals': goals,
        'equipment': equipment,
        'injuries': injuries,
        'age': age,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'gender': gender,
      };

  /// Check if user has provided sufficient profile data
  bool get hasProfileData =>
      fitnessLevel != null || goals.isNotEmpty || equipment.isNotEmpty;
}

/// Program preferences used for workout generation
class ProgramPrefs {
  final String? difficulty;
  final int? durationMinutes;
  final String? workoutType;
  final String? trainingSplit;
  final List<String> workoutDays;
  final List<String> focusAreas;
  final String? customProgramDescription;

  ProgramPrefs({
    this.difficulty,
    this.durationMinutes,
    this.workoutType,
    this.trainingSplit,
    this.workoutDays = const [],
    this.focusAreas = const [],
    this.customProgramDescription,
  });

  factory ProgramPrefs.fromJson(Map<String, dynamic> json) {
    return ProgramPrefs(
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      workoutType: json['workout_type'] as String?,
      trainingSplit: json['training_split'] as String?,
      workoutDays: (json['workout_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      customProgramDescription: json['custom_program_description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'workout_type': workoutType,
        'training_split': trainingSplit,
        'workout_days': workoutDays,
        'focus_areas': focusAreas,
        'custom_program_description': customProgramDescription,
      };
}

/// Reasoning for why a specific exercise was selected
class ExerciseReasoning {
  final String exerciseName;
  final String reasoning;
  final String? muscleGroup;
  final String? equipment;

  ExerciseReasoning({
    required this.exerciseName,
    required this.reasoning,
    this.muscleGroup,
    this.equipment,
  });

  factory ExerciseReasoning.fromJson(Map<String, dynamic> json) {
    return ExerciseReasoning(
      exerciseName: json['exercise_name'] as String? ?? 'Unknown',
      reasoning: json['reasoning'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String?,
      equipment: json['equipment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'reasoning': reasoning,
        'muscle_group': muscleGroup,
        'equipment': equipment,
      };
}
