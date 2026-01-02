import 'models/exercise.dart';
import 'models/workout.dart';

/// Static demo workouts for preview before sign-up
/// These workouts are hardcoded and do not require API calls
class DemoWorkouts {
  DemoWorkouts._();

  /// Available demo workout types
  static const List<String> availableTypes = [
    'beginner_full_body',
    'quick_hiit',
    'upper_body_strength',
  ];

  /// Get a demo workout by type
  static DemoWorkout getWorkout(String type) {
    switch (type) {
      case 'beginner_full_body':
        return beginnerFullBody;
      case 'quick_hiit':
        return quickHiit;
      case 'upper_body_strength':
        return upperBodyStrength;
      default:
        return beginnerFullBody;
    }
  }

  /// Get a random demo workout
  static DemoWorkout getRandomWorkout({String? excludeType}) {
    final types = availableTypes.where((t) => t != excludeType).toList();
    types.shuffle();
    return getWorkout(types.first);
  }

  /// Get all demo workouts
  static List<DemoWorkout> get all => [
        beginnerFullBody,
        quickHiit,
        upperBodyStrength,
      ];

  // ─────────────────────────────────────────────────────────────────
  // Demo Workout: Beginner Full Body
  // ─────────────────────────────────────────────────────────────────
  static final DemoWorkout beginnerFullBody = DemoWorkout(
    id: 'demo_beginner_full_body',
    type: 'beginner_full_body',
    name: 'Beginner Full Body',
    description:
        'A perfect starter workout targeting all major muscle groups. Great for building a foundation of strength and movement patterns.',
    difficulty: 'Beginner',
    workoutType: 'strength',
    durationMinutes: 30,
    estimatedCalories: 180,
    targetMuscles: ['Chest', 'Back', 'Legs', 'Core', 'Shoulders'],
    equipment: ['Bodyweight', 'Dumbbells'],
    exercises: [
      DemoExercise(
        name: 'Bodyweight Squats',
        sets: 3,
        reps: 12,
        restSeconds: 60,
        muscleGroup: 'Quadriceps',
        equipment: 'Bodyweight',
        instructions:
            'Stand with feet shoulder-width apart. Lower your body as if sitting back into a chair, keeping your chest up and knees tracking over toes. Push through your heels to return to standing.',
        gifUrl: null, // Will use placeholder
      ),
      DemoExercise(
        name: 'Push-ups',
        sets: 3,
        reps: 10,
        restSeconds: 60,
        muscleGroup: 'Chest',
        equipment: 'Bodyweight',
        instructions:
            'Start in a plank position with hands slightly wider than shoulder-width. Lower your chest toward the floor, keeping your body in a straight line. Push back up to the starting position.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Dumbbell Rows',
        sets: 3,
        reps: 10,
        restSeconds: 60,
        muscleGroup: 'Back',
        equipment: 'Dumbbells',
        weight: 10,
        instructions:
            'Hinge at the hips with a dumbbell in each hand. Pull the weights toward your hips, squeezing your shoulder blades together. Lower with control.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Lunges',
        sets: 3,
        reps: 10,
        restSeconds: 60,
        muscleGroup: 'Quadriceps',
        equipment: 'Bodyweight',
        instructions:
            'Step forward with one leg, lowering your hips until both knees are bent at 90 degrees. Push back to the starting position and alternate legs.',
        isUnilateral: true,
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Plank',
        sets: 3,
        holdSeconds: 30,
        restSeconds: 45,
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        instructions:
            'Hold a straight-arm or forearm plank position, keeping your body in a straight line from head to heels. Engage your core and avoid letting your hips sag.',
        gifUrl: null,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────
  // Demo Workout: Quick HIIT
  // ─────────────────────────────────────────────────────────────────
  static final DemoWorkout quickHiit = DemoWorkout(
    id: 'demo_quick_hiit',
    type: 'quick_hiit',
    name: 'Quick HIIT',
    description:
        'High-intensity interval training to maximize calorie burn in minimal time. Short bursts of effort followed by brief rest periods.',
    difficulty: 'Intermediate',
    workoutType: 'hiit',
    durationMinutes: 20,
    estimatedCalories: 250,
    targetMuscles: ['Full Body', 'Cardio'],
    equipment: ['Bodyweight'],
    exercises: [
      DemoExercise(
        name: 'Burpees',
        sets: 3,
        reps: 10,
        restSeconds: 30,
        muscleGroup: 'Full Body',
        equipment: 'Bodyweight',
        instructions:
            'From standing, drop into a squat and place hands on the floor. Jump feet back to plank, perform a push-up, jump feet forward, then explosively jump up with arms overhead.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Mountain Climbers',
        sets: 3,
        durationSeconds: 30,
        restSeconds: 20,
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        instructions:
            'Start in a plank position. Drive one knee toward your chest, then quickly switch legs in a running motion while maintaining plank form.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Jump Squats',
        sets: 3,
        reps: 15,
        restSeconds: 30,
        muscleGroup: 'Quadriceps',
        equipment: 'Bodyweight',
        instructions:
            'Perform a squat, then explosively jump as high as possible. Land softly and immediately lower into the next squat.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'High Knees',
        sets: 3,
        durationSeconds: 30,
        restSeconds: 20,
        muscleGroup: 'Cardio',
        equipment: 'Bodyweight',
        instructions:
            'Run in place, driving your knees up toward your chest as high as possible. Pump your arms and maintain a fast pace.',
        gifUrl: null,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────
  // Demo Workout: Upper Body Strength
  // ─────────────────────────────────────────────────────────────────
  static final DemoWorkout upperBodyStrength = DemoWorkout(
    id: 'demo_upper_body_strength',
    type: 'upper_body_strength',
    name: 'Upper Body Strength',
    description:
        'Build a strong upper body with this focused strength session. Targets chest, back, shoulders, and arms with compound and isolation movements.',
    difficulty: 'Intermediate',
    workoutType: 'strength',
    durationMinutes: 40,
    estimatedCalories: 220,
    targetMuscles: ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'],
    equipment: ['Dumbbells', 'Bench'],
    exercises: [
      DemoExercise(
        name: 'Dumbbell Bench Press',
        sets: 4,
        reps: 10,
        restSeconds: 90,
        muscleGroup: 'Chest',
        equipment: 'Dumbbells',
        weight: 20,
        instructions:
            'Lie on a bench with a dumbbell in each hand at chest level. Press the weights up until arms are extended, then lower with control.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Bent-Over Rows',
        sets: 4,
        reps: 10,
        restSeconds: 90,
        muscleGroup: 'Back',
        equipment: 'Dumbbells',
        weight: 15,
        instructions:
            'Hinge forward at the hips with a flat back. Pull the dumbbells toward your lower chest, squeezing your back muscles. Lower with control.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Shoulder Press',
        sets: 3,
        reps: 12,
        restSeconds: 60,
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbells',
        weight: 12,
        instructions:
            'Sit or stand with dumbbells at shoulder height, palms facing forward. Press the weights overhead until arms are fully extended. Lower with control.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Bicep Curls',
        sets: 3,
        reps: 12,
        restSeconds: 45,
        muscleGroup: 'Biceps',
        equipment: 'Dumbbells',
        weight: 10,
        instructions:
            'Stand with dumbbells at your sides, palms facing forward. Curl the weights toward your shoulders while keeping elbows stationary. Lower with control.',
        gifUrl: null,
      ),
      DemoExercise(
        name: 'Tricep Dips',
        sets: 3,
        reps: 12,
        restSeconds: 45,
        muscleGroup: 'Triceps',
        equipment: 'Bench',
        instructions:
            'Place hands on a bench behind you, legs extended. Lower your body by bending elbows to 90 degrees, then push back up.',
        gifUrl: null,
      ),
    ],
  );
}

/// Represents a demo workout for preview
class DemoWorkout {
  final String id;
  final String type;
  final String name;
  final String description;
  final String difficulty;
  final String workoutType;
  final int durationMinutes;
  final int estimatedCalories;
  final List<String> targetMuscles;
  final List<String> equipment;
  final List<DemoExercise> exercises;

  const DemoWorkout({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.workoutType,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.targetMuscles,
    required this.equipment,
    required this.exercises,
  });

  /// Convert to WorkoutExercise list for compatibility with existing widgets
  List<WorkoutExercise> toWorkoutExercises() {
    return exercises.map((e) => e.toWorkoutExercise()).toList();
  }

  /// Create a Workout-like object for preview purposes
  /// Note: This is a demo workout and should NOT be saved to the database
  Workout toWorkout() {
    return Workout(
      id: id,
      name: name,
      type: workoutType,
      difficulty: difficulty,
      durationMinutes: durationMinutes,
      exercisesJson: exercises.map((e) => e.toJson()).toList(),
    );
  }
}

/// Represents a demo exercise within a demo workout
class DemoExercise {
  final String name;
  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int? holdSeconds;
  final int restSeconds;
  final String muscleGroup;
  final String equipment;
  final String instructions;
  final double? weight;
  final bool isUnilateral;
  final String? gifUrl;

  const DemoExercise({
    required this.name,
    required this.sets,
    this.reps,
    this.durationSeconds,
    this.holdSeconds,
    required this.restSeconds,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
    this.weight,
    this.isUnilateral = false,
    this.gifUrl,
  });

  /// Convert to WorkoutExercise for compatibility with existing widgets
  WorkoutExercise toWorkoutExercise() {
    return WorkoutExercise(
      id: 'demo_${name.toLowerCase().replaceAll(' ', '_')}',
      nameValue: name,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      holdSeconds: holdSeconds,
      restSeconds: restSeconds,
      muscleGroup: muscleGroup,
      primaryMuscle: muscleGroup,
      equipment: equipment,
      instructions: instructions,
      weight: weight,
      isUnilateral: isUnilateral,
      gifUrl: gifUrl,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': 'demo_${name.toLowerCase().replaceAll(' ', '_')}',
      'name': name,
      'sets': sets,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'hold_seconds': holdSeconds,
      'rest_seconds': restSeconds,
      'muscle_group': muscleGroup,
      'primary_muscle': muscleGroup,
      'equipment': equipment,
      'instructions': instructions,
      'weight': weight,
      'is_unilateral': isUnilateral,
      'gif_url': gifUrl,
    };
  }
}
