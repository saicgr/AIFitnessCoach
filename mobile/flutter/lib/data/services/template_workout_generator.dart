import '../../utils/tz.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../../screens/onboarding/pre_auth_quiz_screen.dart';

/// Generates template-based workout previews using user's quiz selections
///
/// This provides instant workout previews without waiting for AI generation.
/// Templates are designed based on primary goal, fitness level, equipment,
/// and — critically — the user's declared injuries/limitations.
class TemplateWorkoutGenerator {
  /// Generate a sample workout based on quiz data
  static Workout generateTemplateWorkout(PreAuthQuizData quizData) {
    final primaryGoal = quizData.primaryGoal ?? 'hypertrophy';
    final fitnessLevel = quizData.fitnessLevel ?? 'beginner';
    final equipment = quizData.equipment ?? [];
    final duration = quizData.workoutDuration ?? 45;

    // "['none']" means the user explicitly declared no injuries. Filter it out
    // so downstream logic treats the list as empty. An actually empty list also
    // means no injuries. Either way, the avoid-list is empty → no filtering.
    final limitations = (quizData.limitations ?? const <String>[])
        .where((l) => l.isNotEmpty && l != 'none' && l != 'other')
        .toList();

    // Generate raw exercise candidates based on goal + equipment.
    final rawExercises = _generateExercises(
      primaryGoal: primaryGoal,
      fitnessLevel: fitnessLevel,
      equipment: equipment,
      duration: duration,
    );

    // Filter out anything stressing a declared injury, then top up with
    // safe substitutes if filtering left us below the per-duration target.
    final filtered = _applyInjuryFilter(
      rawExercises,
      limitations: limitations,
      fitnessLevel: fitnessLevel,
      duration: duration,
      primaryGoal: primaryGoal,
    );

    // If injuries caused significant swaps, reflect it in the workout name
    // so the preview visibly honors what the user just told us.
    final removedCount = rawExercises.length - rawExercises
        .where((e) => filtered.any((f) => f.nameValue == e.nameValue))
        .length;
    final heavilyModified =
        limitations.isNotEmpty && removedCount >= (rawExercises.length / 2).ceil();

    final workoutName = _getWorkoutName(
      primaryGoal,
      quizData.daysPerWeek ?? 3,
      modifiedForInjury: heavilyModified ? limitations.first : null,
    );

    final estimatedDuration = _calculateDuration(filtered);
    final exercisesJson = filtered.map((e) => e.toJson()).toList();

    return Workout(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      name: workoutName,
      type: _getWorkoutType(primaryGoal),
      exercisesJson: exercisesJson,
      estimatedDurationMinutes: estimatedDuration,
      scheduledDate: Tz.timestamp(),
      isCompleted: false,
      createdAt: Tz.timestamp(),
      updatedAt: Tz.timestamp(),
    );
  }

  static String _getWorkoutName(
    String primaryGoal,
    int daysPerWeek, {
    String? modifiedForInjury,
  }) {
    final base = _baseWorkoutName(primaryGoal, daysPerWeek);
    if (modifiedForInjury == null) return base;
    final humanized = _humanizeInjury(modifiedForInjury);
    // Prefix to make the modification visible without clobbering the original
    // split label. Example: "Day 1: Modified Push — Lower-Back-Safe".
    return 'Day 1: Modified ${_goalLabel(primaryGoal)} — $humanized-Safe';
  }

  static String _baseWorkoutName(String primaryGoal, int daysPerWeek) {
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

  static String _goalLabel(String primaryGoal) {
    switch (primaryGoal) {
      case 'strength':
        return 'Strength';
      case 'hypertrophy':
        return 'Push';
      case 'balanced':
        return 'Upper Body';
      case 'endurance':
        return 'Circuit';
      default:
        return 'Workout';
    }
  }

  static String _humanizeInjury(String id) {
    switch (id) {
      case 'lower_back':
        return 'Lower-Back';
      case 'knees':
        return 'Knee';
      case 'shoulders':
        return 'Shoulder';
      case 'wrists':
        return 'Wrist';
      case 'elbows':
        return 'Elbow';
      case 'hips':
        return 'Hip';
      case 'ankles':
        return 'Ankle';
      case 'neck':
        return 'Neck';
      default:
        return id[0].toUpperCase() + id.substring(1);
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

  /// Exercise-name → injuries-it-stresses map. Listed per exercise (not per
  /// injury) because it's easier to audit when adding a new movement. Derived
  /// from general coaching heuristics (axial-loaded → lower back/hips/neck,
  /// weight-bearing knee flexion → knees, overhead pressing → shoulders,
  /// loaded wrist extension → wrists, deep elbow flexion under load →
  /// elbows, impact plyometrics → ankles).
  static const Map<String, Set<String>> _exerciseInjuryMap = {
    // Lower-body compound / loaded
    'Barbell Back Squat': {'lower_back', 'knees', 'hips', 'neck'},
    'Goblet Squat': {'lower_back', 'knees'},
    'Bodyweight Squats': {'knees'},
    'Smith Machine Squat': {'lower_back', 'knees'},
    'Leg Press': {'knees', 'lower_back'},
    'Leg Extensions': {'knees'},
    'Leg Curls': {},
    // Hip hinge
    'Romanian Deadlift': {'lower_back', 'hips'},
    'Dumbbell Romanian Deadlift': {'lower_back', 'hips'},
    'Kettlebell Deadlift': {'lower_back', 'hips'},
    'Single-Leg Deadlifts': {'lower_back', 'hips', 'ankles'},
    // Unilateral / impact
    'Dumbbell Walking Lunges': {'knees', 'ankles'},
    'Walking Lunges': {'knees', 'ankles'},
    'Kettlebell Lunges': {'knees', 'ankles'},
    'Barbell Lunges': {'knees', 'lower_back', 'hips'},
    // Upper push
    'Barbell Bench Press': {'shoulders', 'wrists'},
    'Smith Machine Bench Press': {'shoulders', 'wrists'},
    'Dumbbell Bench Press': {'shoulders'},
    'Dumbbell Floor Press': {},
    'Push-ups': {'wrists', 'shoulders'},
    'Diamond Push-ups': {'wrists', 'elbows'},
    'Pike Push-ups': {'shoulders', 'wrists'},
    'Banded Push-ups': {'wrists', 'shoulders'},
    // Overhead
    'Barbell Overhead Press': {'shoulders', 'lower_back', 'neck'},
    'Dumbbell Shoulder Press': {'shoulders'},
    'Kettlebell Press': {'shoulders'},
    'Dumbbell Thrusters': {'shoulders', 'knees'},
    'Kettlebell Clean & Press': {'shoulders', 'lower_back'},
    // Lateral / isolation
    'Dumbbell Lateral Raises': {'shoulders'},
    'Kettlebell Lateral Raises': {'shoulders'},
    'Cable Lateral Raises': {'shoulders'},
    'Band Lateral Raises': {'shoulders'},
    'Arm Circles': {'shoulders'},
    // Arms
    'Barbell Bicep Curls': {'elbows', 'wrists'},
    'EZ Bar Bicep Curls': {'elbows'},
    'Dumbbell Bicep Curls': {},
    'Band Bicep Curls': {},
    'EZ Bar Skull Crushers': {'elbows'},
    'Tricep Dips': {'shoulders', 'elbows', 'wrists'},
    'Cable Tricep Pushdowns': {'elbows'},
    'Dumbbell Tricep Extensions': {'elbows'},
    // Pull
    'Barbell Bent-Over Rows': {'lower_back'},
    'Dumbbell Rows': {},
    'Kettlebell Rows': {},
    'Cable Seated Rows': {},
    'Machine Rows': {},
    'Inverted Rows': {},
    'Band Rows': {},
    'Lat Pulldowns': {'shoulders'},
    'Cable Lat Pulldowns': {'shoulders'},
    'Pull-ups': {'shoulders', 'elbows'},
    'Chin-ups': {'shoulders', 'elbows'},
    // Chest accessory
    'Dumbbell Chest Flyes': {'shoulders'},
    'Cable Chest Flyes': {'shoulders'},
    // Conditioning / plyo
    'Jumping Jacks': {'ankles', 'knees'},
    'Mountain Climbers': {'wrists', 'knees'},
    'Burpees': {'wrists', 'knees', 'ankles', 'lower_back'},
    'Kettlebell Swings': {'lower_back', 'hips'},
    'Kettlebell Snatches': {'lower_back', 'shoulders'},
    'Plank': {'wrists'},
    'Banded Squats': {'knees'},
    'Dumbbell Squats': {'knees'},
  };

  /// Injury-safe substitutes grouped by what they target and which
  /// injuries they tolerate. Used when filtering removes too many.
  /// Each tuple: (name, sets, reps, restSec, safeFor).
  static const List<(String, int, int, int, Set<String>)> _safeSubstitutes = [
    // Core / posterior chain safe for almost everything
    ('Glute Bridges', 3, 15, 45, {'lower_back', 'knees', 'hips', 'ankles', 'wrists', 'elbows'}),
    ('Hip Thrusts (Bodyweight)', 3, 15, 45, {'knees', 'ankles', 'wrists', 'elbows'}),
    ('Bird Dog', 3, 10, 30, {'lower_back', 'knees', 'hips', 'ankles', 'shoulders'}),
    ('Dead Bug', 3, 10, 30, {'lower_back', 'knees', 'hips', 'ankles', 'wrists'}),
    ('Side Plank', 3, 30, 30, {'lower_back', 'knees', 'ankles', 'wrists'}),
    ('Seated Dumbbell Curls', 3, 12, 45, {'lower_back', 'knees', 'ankles', 'hips', 'shoulders'}),
    ('Seated Dumbbell Shoulder Press', 3, 10, 60, {'lower_back', 'knees', 'ankles', 'hips'}),
    ('Seated Cable Rows', 3, 12, 45, {'knees', 'ankles', 'hips', 'wrists'}),
    ('Standing Calf Raises', 3, 15, 30, {'lower_back', 'knees', 'wrists', 'elbows', 'shoulders'}),
    ('Wall Sits', 3, 30, 30, {'lower_back', 'wrists', 'elbows', 'shoulders', 'ankles'}),
    ('Banded Pull-Aparts', 3, 15, 30, {'lower_back', 'knees', 'ankles', 'hips', 'wrists', 'elbows'}),
    ('Farmer\'s Carry', 3, 30, 45, {'knees', 'shoulders', 'elbows'}),
  ];

  /// Drop anything in `rawExercises` that stresses a declared injury, then
  /// top up with safe substitutes if the filtered list is too short.
  /// Uses a hash of (primaryGoal + first limitation + rawExercises.length)
  /// to stably-randomize which substitutes get picked — avoids the same
  /// 3 substitutes appearing for every user with the same injury.
  static List<WorkoutExercise> _applyInjuryFilter(
    List<WorkoutExercise> rawExercises, {
    required List<String> limitations,
    required String fitnessLevel,
    required int duration,
    required String primaryGoal,
  }) {
    if (limitations.isEmpty) {
      // Still apply duration cap.
      final max = _getMaxExercisesForDuration(duration);
      return rawExercises.take(max).toList();
    }

    final avoidSet = limitations.toSet();
    final kept = <WorkoutExercise>[];
    for (final ex in rawExercises) {
      final stresses = _exerciseInjuryMap[ex.nameValue ?? ''] ?? const <String>{};
      final conflict = stresses.intersection(avoidSet).isNotEmpty;
      if (!conflict) kept.add(ex);
    }

    // Minimum acceptable size — match original generator's duration cap or 3.
    final maxAllowed = _getMaxExercisesForDuration(duration);
    final minTarget = primaryGoal == 'endurance' ? 4 : 4;

    if (kept.length < minTarget) {
      // Pick substitutes that are safe for ALL selected injuries, using a
      // deterministic hash so two different users with the same setup get
      // slightly different workouts.
      final safePool = _safeSubstitutes.where((sub) {
        final blockedBy = avoidSet.difference(sub.$5);
        return blockedBy.isEmpty;
      }).toList();

      // Rotate pool by a cheap hash of the goal + first injury so users don't
      // all see the same top-3 substitutes.
      final seed =
          (primaryGoal.hashCode ^ limitations.first.hashCode ^ rawExercises.length) &
              0x7fffffff;
      final rotated = [
        ...safePool.skip(seed % (safePool.isEmpty ? 1 : safePool.length)),
        ...safePool.take(seed % (safePool.isEmpty ? 1 : safePool.length)),
      ];

      for (final sub in rotated) {
        if (kept.length >= minTarget) break;
        // De-dupe by name so we don't append something already present.
        if (kept.any((e) => e.nameValue == sub.$1)) continue;
        kept.add(_createExercise(sub.$1, sub.$2, sub.$3, sub.$4));
      }
    }

    if (kept.length > maxAllowed) {
      return kept.take(maxAllowed).toList();
    }
    return kept;
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
    // For endurance - Circuit training (use equipment when available)
    else if (primaryGoal == 'endurance') {
      // Explosive movement
      if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Swings', 3, 15, 30));
      } else {
        exercises.add(_createExercise('Jumping Jacks', 3, 20, 30));
      }
      // Lower body
      if (hasDumbbells || hasKettlebells) {
        exercises.add(_createExercise(hasKettlebells ? 'Goblet Squat' : 'Dumbbell Squats', 3, 15, 30));
      } else if (hasResistanceBands) {
        exercises.add(_createExercise('Banded Squats', 3, 15, 30));
      } else {
        exercises.add(_createExercise('Bodyweight Squats', 3, 15, 30));
      }
      // Upper push
      if (hasDumbbells) {
        exercises.add(_createExercise('Dumbbell Thrusters', 3, 12, 30));
      } else if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Clean & Press', 3, 10, 30));
      } else if (hasResistanceBands) {
        exercises.add(_createExercise('Banded Push-ups', 3, 12, 30));
      } else {
        exercises.add(_createExercise('Push-ups', 3, 12, 30));
      }
      // Cardio / full body
      if (hasKettlebells) {
        exercises.add(_createExercise('Kettlebell Snatches', 3, 10, 30));
      } else {
        exercises.add(_createExercise('Mountain Climbers', 3, 20, 30));
      }
      exercises.add(_createExercise('Plank', 3, 30, 30));
      exercises.add(_createExercise('Burpees', 3, 10, 30));
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
