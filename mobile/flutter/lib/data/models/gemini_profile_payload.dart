import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../screens/onboarding/pre_auth_quiz_screen.dart';

/// Builder for creating Gemini-ready profile payloads with conditional fields.
///
/// This class constructs payloads based on the progressive profiling onboarding flow:
/// - Phase 1 (Required): Core workout parameters
/// - Phase 2 (Optional): Personalization fields
/// - Phase 3 (Optional): Nutrition fields
///
/// Fields are conditionally included based on whether they were provided by the user.
class GeminiProfilePayloadBuilder {
  /// Builds a payload from PreAuthQuizData with conditional field inclusion.
  ///
  /// Returns a Map suitable for sending to the Gemini API or backend workout generation.
  static Map<String, dynamic> buildPayload(PreAuthQuizData profile) {
    final payload = <String, dynamic>{};

    // ===== PHASE 1: REQUIRED FIELDS (Always Include) =====

    if (profile.goals != null && profile.goals!.isNotEmpty) {
      payload['goals'] = profile.goals;
    }

    if (profile.fitnessLevel != null) {
      payload['fitness_level'] = profile.fitnessLevel;
    }

    if (profile.daysPerWeek != null) {
      payload['workouts_per_week'] = profile.daysPerWeek;
      payload['days_per_week'] = profile.daysPerWeek;  // Backend expects this field name
    }

    // Duration range - send both min and max for Gemini to generate varied workouts
    if (profile.workoutDurationMin != null) {
      payload['workout_duration_min'] = profile.workoutDurationMin;
    }
    if (profile.workoutDurationMax != null) {
      payload['workout_duration_max'] = profile.workoutDurationMax;
    }
    // Keep workout_duration for backwards compatibility (use max as single value)
    if (profile.workoutDurationMax != null) {
      payload['workout_duration'] = profile.workoutDurationMax;
    } else if (profile.workoutDuration != null) {
      payload['workout_duration'] = profile.workoutDuration;
    }

    if (profile.workoutEnvironment != null) {
      payload['workout_environment'] = profile.workoutEnvironment;
    }

    if (profile.equipment != null && profile.equipment!.isNotEmpty) {
      payload['equipment'] = profile.equipment;
    }

    if (profile.primaryGoal != null) {
      payload['primary_goal'] = profile.primaryGoal;
    }

    // ===== CONDITIONAL BASIC FIELDS (Only if Present) =====

    if (profile.trainingExperience != null) {
      payload['training_experience'] = profile.trainingExperience;
    }

    if (profile.workoutDays != null && profile.workoutDays!.isNotEmpty) {
      payload['workout_days'] = profile.workoutDays;
      payload['selected_days'] = profile.workoutDays;  // Backend expects this field name
    }

    // ===== PHASE 2: PERSONALIZATION (Only if Provided) =====

    // Muscle focus points - only include if user allocated points
    if (profile.muscleFocusPoints != null && profile.muscleFocusPoints!.isNotEmpty) {
      final totalPoints = profile.muscleFocusPoints!.values.fold(0, (sum, val) => sum + val);
      if (totalPoints > 0) {
        payload['muscle_focus_points'] = profile.muscleFocusPoints;
      }
    }

    // Training split - only include if user selected something other than "ai_decide"
    if (profile.trainingSplit != null && profile.trainingSplit != 'ai_decide') {
      payload['training_split'] = profile.trainingSplit;
    }

    if (profile.progressionPace != null) {
      payload['progression_pace'] = profile.progressionPace;
    }

    if (profile.workoutVariety != null) {
      payload['workout_variety'] = profile.workoutVariety;
    }

    if (profile.limitations != null && profile.limitations!.isNotEmpty) {
      payload['limitations'] = profile.limitations;
    }

    // ===== FITNESS ASSESSMENT (For AI workout personalization) =====
    // These fields help Gemini create workouts matched to user's actual capabilities

    if (profile.pushupCapacity != null) {
      payload['pushup_capacity'] = profile.pushupCapacity;
    }

    if (profile.pullupCapacity != null) {
      payload['pullup_capacity'] = profile.pullupCapacity;
    }

    if (profile.plankCapacity != null) {
      payload['plank_capacity'] = profile.plankCapacity;
    }

    if (profile.squatCapacity != null) {
      payload['squat_capacity'] = profile.squatCapacity;
    }

    if (profile.cardioCapacity != null) {
      payload['cardio_capacity'] = profile.cardioCapacity;
    }

    // ===== PHASE 3: NUTRITION (Only if Opted In) =====

    if (profile.nutritionEnabled == true) {
      final nutritionBlock = <String, dynamic>{};

      if (profile.nutritionGoals != null) {
        nutritionBlock['nutrition_goals'] = profile.nutritionGoals;
      }

      if (profile.dietaryRestrictions != null) {
        // Always use empty array, never ["none"] sentinel value
        nutritionBlock['dietary_restrictions'] = profile.dietaryRestrictions!.isEmpty
            ? []
            : profile.dietaryRestrictions;
      }

      if (profile.mealsPerDay != null) {
        nutritionBlock['meals_per_day'] = profile.mealsPerDay;
      }

      // Only add nutrition block if it has content
      if (nutritionBlock.isNotEmpty) {
        payload['nutrition'] = nutritionBlock;
      }

      // Fasting sub-block (only if interested in fasting)
      if (profile.interestedInFasting == true) {
        final fastingBlock = <String, dynamic>{};

        if (profile.fastingProtocol != null) {
          fastingBlock['protocol'] = profile.fastingProtocol;
        }

        if (profile.wakeTime != null) {
          fastingBlock['wake_time'] = profile.wakeTime;
        }

        if (profile.sleepTime != null) {
          fastingBlock['sleep_time'] = profile.sleepTime;
        }

        // Only add fasting block if it has content
        if (fastingBlock.isNotEmpty) {
          payload['fasting'] = fastingBlock;
        }
      }
    }

    return payload;
  }

  /// Converts payload to a readable string for logging and debugging.
  ///
  /// Use this in development to verify payload content before sending to API.
  /// Remove debug prints in production builds.
  static String toReadableString(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    buffer.writeln('=== Gemini Profile Payload ===');

    // Core Profile (Phase 1)
    buffer.writeln('\n[Core Profile]');
    buffer.writeln('Goals: ${payload['goals'] ?? 'N/A'}');
    buffer.writeln('Fitness Level: ${payload['fitness_level'] ?? 'N/A'}');
    buffer.writeln('Workouts/Week: ${payload['workouts_per_week'] ?? 'N/A'}');
    // Show duration range if available
    final durationMin = payload['workout_duration_min'];
    final durationMax = payload['workout_duration_max'];
    if (durationMin != null && durationMax != null) {
      buffer.writeln('Duration Range: $durationMin-$durationMax min');
    } else {
      buffer.writeln('Duration: ${payload['workout_duration'] ?? 'N/A'} min');
    }
    buffer.writeln('Environment: ${payload['workout_environment'] ?? 'N/A'}');
    buffer.writeln('Equipment: ${payload['equipment'] ?? 'N/A'}');
    buffer.writeln('Primary Goal: ${payload['primary_goal'] ?? 'N/A'}');

    // Optional Basic Fields
    if (payload.containsKey('training_experience')) {
      buffer.writeln('\n[Experience]');
      buffer.writeln('Training Experience: ${payload['training_experience']}');
    }

    if (payload.containsKey('workout_days')) {
      buffer.writeln('Workout Days: ${payload['workout_days']}');
    }

    // Personalization (Phase 2)
    if (payload.containsKey('muscle_focus_points') ||
        payload.containsKey('training_split') ||
        payload.containsKey('progression_pace') ||
        payload.containsKey('limitations')) {
      buffer.writeln('\n[Personalization]');

      if (payload.containsKey('muscle_focus_points')) {
        buffer.writeln('Muscle Focus: ${payload['muscle_focus_points']}');
      }

      if (payload.containsKey('training_split')) {
        buffer.writeln('Training Split: ${payload['training_split']}');
      }

      if (payload.containsKey('progression_pace')) {
        buffer.writeln('Progression Pace: ${payload['progression_pace']}');
      }

      if (payload.containsKey('limitations')) {
        buffer.writeln('Limitations: ${payload['limitations']}');
      }
    }

    // Fitness Assessment
    if (payload.containsKey('pushup_capacity') ||
        payload.containsKey('pullup_capacity') ||
        payload.containsKey('plank_capacity') ||
        payload.containsKey('squat_capacity') ||
        payload.containsKey('cardio_capacity')) {
      buffer.writeln('\n[Fitness Assessment]');

      if (payload.containsKey('pushup_capacity')) {
        buffer.writeln('Push-ups: ${payload['pushup_capacity']}');
      }

      if (payload.containsKey('pullup_capacity')) {
        buffer.writeln('Pull-ups: ${payload['pullup_capacity']}');
      }

      if (payload.containsKey('plank_capacity')) {
        buffer.writeln('Plank: ${payload['plank_capacity']}');
      }

      if (payload.containsKey('squat_capacity')) {
        buffer.writeln('Squats: ${payload['squat_capacity']}');
      }

      if (payload.containsKey('cardio_capacity')) {
        buffer.writeln('Cardio: ${payload['cardio_capacity']}');
      }
    }

    // Nutrition (Phase 3)
    if (payload.containsKey('nutrition')) {
      buffer.writeln('\n[Nutrition]');
      final nutrition = payload['nutrition'] as Map<String, dynamic>;
      buffer.writeln('Goals: ${nutrition['nutrition_goals'] ?? 'N/A'}');
      buffer.writeln('Dietary Restrictions: ${nutrition['dietary_restrictions'] ?? 'N/A'}');
      buffer.writeln('Meals/Day: ${nutrition['meals_per_day'] ?? 'N/A'}');
    }

    if (payload.containsKey('fasting')) {
      buffer.writeln('\n[Fasting]');
      final fasting = payload['fasting'] as Map<String, dynamic>;
      buffer.writeln('Protocol: ${fasting['protocol'] ?? 'N/A'}');
      buffer.writeln('Wake Time: ${fasting['wake_time'] ?? 'N/A'}');
      buffer.writeln('Sleep Time: ${fasting['sleep_time'] ?? 'N/A'}');
    }

    buffer.writeln('\n=============================');
    return buffer.toString();
  }

  /// Validates that required Phase 1 fields are present.
  ///
  /// Returns true if all required fields for workout generation are included.
  static bool validateRequiredFields(Map<String, dynamic> payload) {
    final requiredFields = [
      'goals',
      'fitness_level',
      'workouts_per_week',
      'workout_duration',
      'workout_environment',
      'equipment',
      'primary_goal',
    ];

    for (final field in requiredFields) {
      if (!payload.containsKey(field) || payload[field] == null) {
        if (kDebugMode) {
          print('❌ [Payload] Missing required field: $field');
        }
        return false;
      }

      // Check for empty lists
      if (payload[field] is List && (payload[field] as List).isEmpty) {
        if (kDebugMode) {
          print('❌ [Payload] Empty list for required field: $field');
        }
        return false;
      }
    }

    return true;
  }

  /// Converts payload to JSON string for API transmission.
  static String toJsonString(Map<String, dynamic> payload) {
    return jsonEncode(payload);
  }
}
