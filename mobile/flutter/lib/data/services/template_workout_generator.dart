import '../models/exercise.dart';
import '../models/workout.dart';
import '../../screens/onboarding/pre_auth_quiz_screen.dart';

/// Generates template-based workout previews using user's quiz selections
///
/// This provides instant workout previews without waiting for AI generation.
/// Templates are designed based on primary goal, fitness level, and equipment available.
class TemplateWorkoutGenerator {
  /// Generate a sample workout based on quiz data
  static Workout generateTemplateWorkout(PreAuthQuizData quizData) {
    final primaryGoal = quizData.primaryGoal ?? 'hypertrophy';
    final fitnessLevel = quizData.fitnessLevel ?? 'beginner';
    final equipment = quizData.equipment ?? [];
    final duration = quizData.workoutDuration ?? 45;

    // Determine workout name based on primary goal and day pattern
    final workoutName = _getWorkoutName(primaryGoal, quizData.daysPerWeek ?? 3);

    // Generate exercises based on selections
    final exercises = _generateExercises(
      primaryGoal: primaryGoal,
      fitnessLevel: fitnessLevel,
      equipment: equipment,
      duration: duration,
    );

    // Calculate estimated duration based on exercises
    final estimatedDuration = _calculateDuration(exercises);

    // Convert exercises to JSON format expected by Workout model
    final exercisesJson = exercises.map((e) => e.toJson()).toList();

    return Workout(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      name: workoutName,
      type: _getWorkoutType(primaryGoal),
      exercisesJson: exercisesJson,
      estimatedDurationMinutes: estimatedDuration,
      scheduledDate: DateTime.now().toIso8601String(),
      isCompleted: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  static String _getWorkoutName(String primaryGoal, int daysPerWeek) {
    if (daysPerWeek <= 2) {
      return 'Full Body Workout';
    } else if (daysPerWeek == 3) {
      switch (primaryGoal) {
        case 'strength':
          return 'Day 1: Lower Body Strength';
        case 'hypertrophy':
          return 'Day 1: Push (Chest, Shoulders, Triceps)';
        case 'balanced':
          return 'Day 1: Upper Body Power';
        case 'endurance':
          return 'Day 1: Circuit Training';
        default:
          return 'Day 1: Push (Chest, Shoulders, Triceps)';
      }
    } else if (daysPerWeek == 4) {
      return 'Day 1: Upper Body Push';
    } else {
      return 'Day 1: Push (Chest, Shoulders, Triceps)';
    }
  }

  static String _getWorkoutType(String primaryGoal) {
    switch (primaryGoal) {
      case 'strength':
        return 'strength';
      case 'hypertrophy':
        return 'hypertrophy';
      case 'balanced':
        return 'strength_hypertrophy';
      case 'endurance':
        return 'endurance';
      default:
        return 'hypertrophy';
    }
  }

  static List<WorkoutExercise> _generateExercises({
    required String primaryGoal,
    required String fitnessLevel,
    required List<String> equipment,
    required int duration,
  }) {
    // Equipment detection - comprehensive list
    final hasBarbell = equipment.contains('barbell');
    final hasDumbbells = equipment.contains('dumbbells');
    final hasKettlebells = equipment.contains('kettlebells');
    final hasCables = equipment.contains('cable_machine');
    final hasPullUpBar = equipment.contains('pull_up_bar');
    final hasResistanceBands = equipment.contains('resistance_bands');
    final hasBench = equipment.contains('adjustable_bench') || equipment.contains('bench_press');
    final hasSquatRack = equipment.contains('squat_rack') || equipment.contains('power_rack');
    final hasDipStation = equipment.contains('dip_station');
    final hasEZBar = equipment.contains('ez_curl_bar');
    final hasLegPress = equipment.contains('leg_press');
    final hasLegCurl = equipment.contains('leg_curl_machine');
    final hasLegExtension = equipment.contains('leg_extension_machine');
    final hasLatPulldown = equipment.contains('lat_pulldown');
    final hasSeatedRow = equipment.contains('seated_row_machine');
    final hasSmithMachine = equipment.contains('smith_machine');

    // Gym tier classification
    final hasFullGym = (hasBarbell && hasCables && hasLegPress) || equipment.contains('commercial_gym');
    final hasHomeGym = hasBarbell && hasDumbbells && (hasSquatRack || hasBench);

    // Determine rep ranges based on primary goal
    final (sets, reps) = _getSetRepScheme(primaryGoal, fitnessLevel);

    // Generate exercise list based on equipment and goal
    final exercises = <WorkoutExercise>[];

    // HYPERTROPHY - Push day (Chest, Shoulders, Triceps)
    if (primaryGoal == 'hypertrophy') {
      // Main chest movement
      if (hasBarbell && hasBench) {
        exercises.add(_createExercise('Barbell Bench Press', sets, reps, 90));
      } else if (hasSmithMachine) {
        exercises.add(_createExercise('Smith Machine Bench Press', sets, reps, 90));
      } else if (hasDumbbells && hasBench) {
        exercises.add(_createExercise('Dumbbell Bench Press', sets, reps, 90));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Floor Press', sets, reps, 90));
      } else {
        exercises.add(_createExercise('Push-ups', sets, reps + 2, 60));
      }

      // Shoulder movement
      if (hasBarbell) {
        exercises.add(_createExercise('Barbell Overhead Press', sets, reps, 75));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Shoulder Press', sets, reps, 75));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Press', sets, reps, 75));
      } else {
        exercises.add(_createExercise('Pike Push-ups', sets, reps - 2, 60));
      }

      // Lateral delts
      if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Lateral Raises', 3, 12, 45));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Lateral Raises', 3, 12, 45));
      } else if (hasCables) {
        exercises.add(_createExercise('Cable Lateral Raises', 3, 12, 45));
      } else if (hasResistanceBands) {
        exercises.add(_createExercise('Band Lateral Raises', 3, 15, 30));
      } else {
        exercises.add(_createExercise('Arm Circles', 3, 15, 30));
      }

      // Triceps
      if (hasCables) {
        exercises.add(_createExercise('Cable Tricep Pushdowns', 3, 12, 45));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Tricep Extensions', 3, 12, 45));
      } else if (hasEZBar) {
        exercises.add(_createExercise('EZ Bar Skull Crushers', 3, 12, 60));
      } else if (hasDipStation || hasPullUpBar) {
        exercises.add(_createExercise('Tricep Dips', 3, 10, 60));
      } else {
        exercises.add(_createExercise('Diamond Push-ups', 3, 10, 60));
      }

      // Chest volume (if have dumbbells or cables)
      if (hasDumbbells && hasBench) {
        exercises.add(_createExercise('Dumbbell Chest Flyes', 3, 12, 60));
      } else if (hasCables) {
        exercises.add(_createExercise('Cable Chest Flyes', 3, 12, 60));
      }
    }
    // STRENGTH - Lower body (Quads, Hamstrings, Glutes)
    else if (primaryGoal == 'strength') {
      // Main squat movement
      if (hasBarbell && hasSquatRack) {
        exercises.add(_createExercise('Barbell Back Squat', sets, reps, 120));
      } else if (hasLegPress) {
        exercises.add(_createExercise('Leg Press', sets, reps, 90));
      } else if (hasSmithMachine) {
        exercises.add(_createExercise('Smith Machine Squat', sets, reps, 90));
      } else if (hasDumbbells || hasKettlebells) {
        exercises.add(_createExercise('Goblet Squat', sets, reps, 90));
      } else {
        exercises.add(_createExercise('Bodyweight Squats', sets, reps + 5, 60));
      }

      // Hip hinge / Hamstrings
      if (hasBarbell) {
        exercises.add(_createExercise('Romanian Deadlift', sets, reps, 90));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Romanian Deadlift', sets, reps, 75));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Deadlift', sets, reps, 75));
      } else {
        exercises.add(_createExercise('Single-Leg Deadlifts', sets, reps, 60));
      }

      // Unilateral / Lunge movement
      if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Walking Lunges', 3, 10, 60));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Lunges', 3, 10, 60));
      } else if (hasBarbell) {
        exercises.add(_createExercise('Barbell Lunges', 3, 10, 75));
      } else {
        exercises.add(_createExercise('Walking Lunges', 3, 10, 60));
      }

      // Hamstring isolation
      if (hasLegCurl) {
        exercises.add(_createExercise('Leg Curls', 3, 10, 45));
      } else if (hasCables) {
        exercises.add(_createExercise('Cable Pull-Throughs', 3, 12, 60));
      } else {
        exercises.add(_createExercise('Nordic Hamstring Curls', 3, 6, 90));
      }

      // Quad isolation (optional)
      if (hasLegExtension) {
        exercises.add(_createExercise('Leg Extensions', 3, 12, 45));
      }
    }
    // BALANCED - Upper body (Push + Pull)
    else if (primaryGoal == 'balanced') {
      // Push movement (Chest)
      if (hasBarbell && hasBench) {
        exercises.add(_createExercise('Barbell Bench Press', sets, reps, 90));
      } else if (hasDumbbells && hasBench) {
        exercises.add(_createExercise('Dumbbell Bench Press', sets, reps, 90));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Floor Press', sets, reps, 90));
      } else {
        exercises.add(_createExercise('Push-ups', sets, reps + 2, 60));
      }

      // Pull movement (Back)
      if (hasBarbell) {
        exercises.add(_createExercise('Barbell Bent-Over Rows', sets, reps, 90));
      } else if (hasCables) {
        exercises.add(_createExercise('Cable Seated Rows', sets, reps, 75));
      } else if (hasSeatedRow) {
        exercises.add(_createExercise('Machine Rows', sets, reps, 75));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Rows', sets, reps, 75));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Rows', sets, reps, 75));
      } else if (hasResistanceBands) {
        exercises.add(_createExercise('Band Rows', sets, reps + 3, 60));
      } else {
        exercises.add(_createExercise('Inverted Rows', sets, reps, 75));
      }

      // Vertical pull (Lats)
      if (hasLatPulldown) {
        exercises.add(_createExercise('Lat Pulldowns', 3, 10, 60));
      } else if (hasPullUpBar) {
        exercises.add(_createExercise('Pull-ups', 3, 8, 90));
      } else if (hasCables) {
        exercises.add(_createExercise('Cable Lat Pulldowns', 3, 10, 60));
      }

      // Vertical push (Shoulders)
      if (hasBarbell) {
        exercises.add(_createExercise('Barbell Overhead Press', 3, 10, 75));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Shoulder Press', 3, 10, 75));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Press', 3, 10, 75));
      } else {
        exercises.add(_createExercise('Pike Push-ups', 3, 10, 60));
      }

      // Biceps
      if (hasEZBar) {
        exercises.add(_createExercise('EZ Bar Bicep Curls', 3, 10, 45));
      } else if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Bicep Curls', 3, 10, 45));
      } else if (hasBarbell) {
        exercises.add(_createExercise('Barbell Bicep Curls', 3, 10, 45));
      } else if (hasResistanceBands) {
        exercises.add(_createExercise('Band Bicep Curls', 3, 15, 30));
      } else if (hasPullUpBar) {
        exercises.add(_createExercise('Chin-ups', 3, 8, 60));
      }
    }
    // For endurance - Circuit training
    else if (primaryGoal == 'endurance') {
      exercises.add(_createExercise('Jumping Jacks', 3, 20, 30));
      exercises.add(_createExercise('Bodyweight Squats', 3, 15, 30));
      exercises.add(_createExercise('Push-ups', 3, 12, 30));
      exercises.add(_createExercise('Mountain Climbers', 3, 20, 30));
      exercises.add(_createExercise('Plank', 3, 30, 30)); // 30 seconds
      exercises.add(_createExercise('Burpees', 3, 10, 30));
    }

    // If we have too many exercises for the duration, trim them
    final maxExercises = _getMaxExercisesForDuration(duration);
    if (exercises.length > maxExercises) {
      return exercises.take(maxExercises).toList();
    }

    return exercises;
  }

  static WorkoutExercise _createExercise(
    String name,
    int sets,
    int reps,
    int restSeconds,
  ) {
    return WorkoutExercise(
      id: 'template_${name.toLowerCase().replaceAll(' ', '_')}',
      nameValue: name,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
    );
  }

  static (int sets, int reps) _getSetRepScheme(String primaryGoal, String fitnessLevel) {
    switch (primaryGoal) {
      case 'strength':
        // Heavy weights, low reps
        return fitnessLevel == 'beginner' ? (3, 6) : (4, 5);
      case 'hypertrophy':
        // Moderate weights, moderate reps
        return fitnessLevel == 'beginner' ? (3, 10) : (4, 10);
      case 'balanced':
        // Mix of strength and hypertrophy
        return fitnessLevel == 'beginner' ? (3, 8) : (4, 8);
      case 'endurance':
        // Light weights, high reps
        return (3, 15);
      default:
        return (3, 10);
    }
  }

  static int _getMaxExercisesForDuration(int duration) {
    if (duration <= 30) return 4;
    if (duration <= 45) return 5;
    if (duration <= 60) return 6;
    if (duration <= 75) return 7;
    return 8;
  }

  static int _calculateDuration(List<WorkoutExercise> exercises) {
    // Estimate: 1 min per set + rest time
    int totalSeconds = 0;

    for (final exercise in exercises) {
      final sets = exercise.sets ?? 3;
      final restSeconds = exercise.restSeconds ?? 60;

      // Assume 45 seconds per working set + rest time
      totalSeconds += (sets * (45 + restSeconds));
    }

    // Add 5 min warmup
    totalSeconds += 300;

    return (totalSeconds / 60).ceil();
  }
}
