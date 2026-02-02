/// Holds all onboarding form data.
class OnboardingData {
  // Step 1: Personal Info
  String? name;
  String? gender;
  int? age;

  // Step 2: Body Metrics
  double? heightCm;
  double? weightKg;
  double? targetWeightKg;
  // Advanced measurements
  double? waistCm;
  double? hipCm;
  double? neckCm;
  double? bodyFatPercent;
  int? restingHeartRate;
  int? bloodPressureSystolic;
  int? bloodPressureDiastolic;

  // Step 3: Fitness Background
  String? fitnessLevel;
  List<String> goals = [];
  List<String> previousExperience = [];

  // Step 4: Schedule
  List<int> workoutDays = []; // 0=Mon, 6=Sun
  String? preferredTime;
  int workoutDuration = 45;

  // Step 5: Preferences
  String? trainingSplit;
  String? intensityLevel;
  List<String> equipment = [];
  String? workoutVariety;
  int dumbbellCount = 2; // 1 or 2 dumbbells
  int kettlebellCount = 1; // 1 or 2 kettlebells
  // New: Progression pace control (slow, medium, fast)
  String progressionPace = 'medium';
  // New: Workout type preference (strength, cardio, mixed)
  String workoutTypePreference = 'strength';
  // New: Gym location context
  String? workoutEnvironment; // 'home_gym', 'commercial_gym', 'both', 'other'
  String? gymName; // User-provided name for their gym

  // Step 6: Health & Limitations
  List<String> injuries = [];
  List<String> healthConditions = [];
  String? activityLevel;

  OnboardingData();

  /// Returns the default gym name based on workout environment
  String get effectiveGymName {
    if (gymName != null && gymName!.isNotEmpty) {
      return gymName!;
    }
    switch (workoutEnvironment) {
      case 'home_gym':
        return 'Home Gym';
      case 'commercial_gym':
        return 'My Gym';
      case 'both':
        return 'Home Gym';
      case 'other':
        return 'My Gym';
      default:
        return 'My Gym';
    }
  }

  /// Validates if all required fields for a step are filled.
  bool isStepValid(int step) {
    switch (step) {
      case 0: // Personal Info
        return name != null && name!.isNotEmpty && gender != null;
      case 1: // Body Metrics
        return heightCm != null && weightKg != null;
      case 2: // Fitness Background
        return fitnessLevel != null && goals.isNotEmpty;
      case 3: // Schedule
        return workoutDays.isNotEmpty && preferredTime != null;
      case 4: // Preferences
        return trainingSplit != null &&
               equipment.isNotEmpty &&
               workoutEnvironment != null;
      case 5: // Health
        return activityLevel != null &&
            (injuries.isNotEmpty || healthConditions.isNotEmpty ||
             injuries.contains('none') || healthConditions.contains('none'));
      default:
        return false;
    }
  }

  /// Converts to JSON for API submission.
  Map<String, dynamic> toJson() {
    return {
      // Personal
      'name': name,
      'gender': gender,
      'age': age,

      // Body metrics
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_weight_kg': targetWeightKg,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
      'neck_cm': neckCm,
      'body_fat_percent': bodyFatPercent,
      'resting_heart_rate': restingHeartRate,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,

      // Fitness
      'fitness_level': fitnessLevel,
      'goals': goals,
      'previous_experience': previousExperience,

      // Schedule
      'workout_days': workoutDays,
      'preferred_time': preferredTime,
      'workout_duration': workoutDuration,
      'days_per_week': workoutDays.length,

      // Preferences
      'training_split': trainingSplit,
      'intensity_preference': intensityLevel,
      'equipment': equipment,
      'workout_environment': workoutEnvironment,
      'gym_name': effectiveGymName,
      'workout_variety': workoutVariety,
      'dumbbell_count': dumbbellCount,
      'kettlebell_count': kettlebellCount,
      'progression_pace': progressionPace,
      'workout_type_preference': workoutTypePreference,
      'preferences': {
        'training_split': trainingSplit,
        'intensity_preference': intensityLevel,
        'workout_variety': workoutVariety,
        'days_per_week': workoutDays.length,
        'workout_duration': workoutDuration,
        'preferred_time': preferredTime,
        'dumbbell_count': dumbbellCount,
        'kettlebell_count': kettlebellCount,
        'progression_pace': progressionPace,
        'workout_type_preference': workoutTypePreference,
        'workout_environment': workoutEnvironment,
        'gym_name': effectiveGymName,
      },

      // Health
      'active_injuries': injuries.where((i) => i != 'none').toList(),
      'health_conditions': healthConditions.where((c) => c != 'none').toList(),
      'activity_level': activityLevel,

      // Completion flag - NOTE: set to false here, will be set to true
      // by the onboarding screen AFTER all data is saved and workouts generated
      'onboarding_completed': false,
    };
  }
}

/// Options for fitness goals
class GoalOptions {
  static const List<Map<String, String>> all = [
    {'label': 'Build Muscle', 'value': 'build_muscle'},
    {'label': 'Lose Weight', 'value': 'lose_weight'},
    {'label': 'Increase Strength', 'value': 'increase_strength'},
    {'label': 'Improve Endurance', 'value': 'improve_endurance'},
    {'label': 'Stay Active', 'value': 'stay_active'},
    {'label': 'Flexibility', 'value': 'flexibility'},
    {'label': 'Athletic Performance', 'value': 'athletic_performance'},
    {'label': 'General Health', 'value': 'general_health'},
  ];
}

/// Options for previous experience
class ExperienceOptions {
  static const List<Map<String, String>> all = [
    {'label': 'Weight Training', 'value': 'weight_training'},
    {'label': 'Cardio', 'value': 'cardio'},
    {'label': 'HIIT', 'value': 'hiit'},
    {'label': 'Yoga/Pilates', 'value': 'yoga_pilates'},
    {'label': 'CrossFit', 'value': 'crossfit'},
    {'label': 'Calisthenics', 'value': 'calisthenics'},
    {'label': 'Sports', 'value': 'sports'},
    {'label': 'None', 'value': 'none'},
  ];
}

/// Options for equipment
class EquipmentOptions {
  static const List<Map<String, String>> all = [
    {'label': 'Full Gym', 'value': 'full_gym'},
    {'label': 'Bodyweight Only', 'value': 'bodyweight'},
    {'label': 'Dumbbells', 'value': 'dumbbells'},
    {'label': 'Barbell', 'value': 'barbell'},
    {'label': 'Resistance Bands', 'value': 'resistance_bands'},
    {'label': 'Pull-up Bar', 'value': 'pull_up_bar'},
    {'label': 'Kettlebell', 'value': 'kettlebell'},
    {'label': 'Cable Machine', 'value': 'cable_machine'},
  ];
}

/// Options for injuries
class InjuryOptions {
  static const List<Map<String, String>> all = [
    {'label': 'None', 'value': 'none'},
    {'label': 'Lower Back', 'value': 'lower_back'},
    {'label': 'Shoulder', 'value': 'shoulder'},
    {'label': 'Knee', 'value': 'knee'},
    {'label': 'Wrist/Elbow', 'value': 'wrist_elbow'},
    {'label': 'Neck', 'value': 'neck'},
    {'label': 'Hip', 'value': 'hip'},
    {'label': 'Leg', 'value': 'leg'},
    {'label': 'Ankle', 'value': 'ankle'},
    {'label': 'Other', 'value': 'other'},
  ];
}

/// Options for health conditions
class HealthConditionOptions {
  static const List<Map<String, String>> all = [
    {'label': 'None', 'value': 'none'},
    {'label': 'High Blood Pressure', 'value': 'high_blood_pressure'},
    {'label': 'Heart Condition', 'value': 'heart_condition'},
    {'label': 'Diabetes', 'value': 'diabetes'},
    {'label': 'Asthma', 'value': 'asthma'},
    {'label': 'Arthritis', 'value': 'arthritis'},
    {'label': 'Pregnancy', 'value': 'pregnancy'},
    {'label': 'Recent Surgery', 'value': 'recent_surgery'},
    {'label': 'Other', 'value': 'other'},
  ];
}
