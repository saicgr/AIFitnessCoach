import 'dart:math';

import 'offline_workout_generator.dart';

// ---------------------------------------------------------------------------
// C3. Difficulty multiplier
// ---------------------------------------------------------------------------
class DifficultyMultiplier {
  final double volume;
  final double rest;
  final int rpeMin;
  final int rpeMax;

  const DifficultyMultiplier({
    required this.volume,
    required this.rest,
    required this.rpeMin,
    required this.rpeMax,
  });
}

// ---------------------------------------------------------------------------
// C3b. Mood multiplier
// ---------------------------------------------------------------------------
class MoodMultiplier {
  /// Applied to weight / intensity.
  final double intensity;

  /// Applied to sets / exercise count.
  final double volume;

  /// Applied to rest periods.
  final double rest;

  /// Bias for exercise selection: 'compound', 'isolation', 'balanced', 'mobility'.
  final String exerciseBias;

  const MoodMultiplier(this.intensity, this.volume, this.rest, this.exerciseBias);
}

// ---------------------------------------------------------------------------
// C5. Exercise count target range
// ---------------------------------------------------------------------------
class _ExerciseCountRange {
  final int min;
  final int max;
  const _ExerciseCountRange(this.min, this.max);
}

// ---------------------------------------------------------------------------
// QuickWorkoutConstants
// ---------------------------------------------------------------------------
class QuickWorkoutConstants {
  QuickWorkoutConstants._();

  static final _rng = Random();

  // -----------------------------------------------------------------------
  // C1. Time estimates (seconds per exercise, all sets included)
  // -----------------------------------------------------------------------
  static const int compoundSupersetSeconds = 150;
  static const int isolationStraightSetSeconds = 180;
  static const int circuitExerciseSeconds = 75;
  static const int hiitIntervalSeconds = 55;
  static const int stretchHoldSeconds = 80;
  static const int warmupMovementSeconds = 30;
  static const int tabataBlockSeconds = 240;

  // Time cost aliases used by templates for budget calculation
  static const int supersetPairTimeCost = compoundSupersetSeconds;
  static const int straightSetTimeCost = isolationStraightSetSeconds;
  static const int hiitIntervalTimeCost = hiitIntervalSeconds;
  static const int stretchHoldTimeCost = stretchHoldSeconds;
  static const int circuitTimeCost = circuitExerciseSeconds;
  static const int emomTimeCost = 60;   // 60s per exercise (fills one minute)
  static const int amrapTimeCost = 50;  // 50s per exercise cycle

  // -----------------------------------------------------------------------
  // C2. Warm-up budgets (seconds)
  // -----------------------------------------------------------------------
  static const Map<int, int> warmupBudgets = {
    5: 0,
    10: 60,
    15: 120,
    20: 150,
    25: 180,
    30: 240,
  };

  /// Returns the warm-up budget for the given [duration] in minutes.
  /// Falls back to the nearest lower key when the exact duration is absent.
  static int getWarmupSeconds(int duration) {
    if (warmupBudgets.containsKey(duration)) return warmupBudgets[duration]!;
    // Find the nearest lower key
    final keys = warmupBudgets.keys.toList()..sort();
    int result = 0;
    for (final k in keys) {
      if (k <= duration) {
        result = warmupBudgets[k]!;
      } else {
        break;
      }
    }
    return result;
  }

  // -----------------------------------------------------------------------
  // C3. Difficulty multipliers
  // -----------------------------------------------------------------------
  static const Map<String, DifficultyMultiplier> difficultyMultipliers = {
    'easy': DifficultyMultiplier(
      volume: 0.7,
      rest: 1.3,
      rpeMin: 5,
      rpeMax: 6,
    ),
    'medium': DifficultyMultiplier(
      volume: 1.0,
      rest: 1.0,
      rpeMin: 7,
      rpeMax: 8,
    ),
    'hard': DifficultyMultiplier(
      volume: 1.15,
      rest: 0.8,
      rpeMin: 8,
      rpeMax: 9,
    ),
    'hell': DifficultyMultiplier(
      volume: 1.3,
      rest: 0.6,
      rpeMin: 9,
      rpeMax: 10,
    ),
  };

  // -----------------------------------------------------------------------
  // C3b. Mood multipliers
  // -----------------------------------------------------------------------
  static const Map<String, MoodMultiplier> moodMultipliers = {
    'energized': MoodMultiplier(1.1, 1.1, 0.85, 'compound'),
    'tired': MoodMultiplier(0.8, 0.8, 1.3, 'isolation'),
    'stressed': MoodMultiplier(1.05, 1.0, 0.9, 'compound'),
    'chill': MoodMultiplier(0.9, 0.95, 1.15, 'balanced'),
    'motivated': MoodMultiplier(1.15, 1.2, 0.8, 'compound'),
    'low_energy': MoodMultiplier(0.7, 0.75, 1.4, 'mobility'),
  };

  // -----------------------------------------------------------------------
  // C4. Sets by duration (base sets, and per-difficulty overrides)
  //     Index order: [easy, medium, hard, hell]
  // -----------------------------------------------------------------------
  static const Map<int, int> _baseSets = {
    5: 1,
    10: 2,
    15: 2,
    20: 3,
    25: 3,
    30: 3,
  };

  static const Map<int, List<int>> _setsByDifficulty = {
    5: [1, 1, 1, 1],
    10: [1, 2, 2, 2],
    15: [2, 2, 3, 3],
    20: [2, 3, 3, 3],
    25: [2, 3, 3, 4],
    30: [3, 3, 4, 4],
  };

  static const List<String> _difficultyOrder = ['easy', 'medium', 'hard', 'hell'];

  /// Returns the number of sets for the given [duration] (minutes) and
  /// [difficulty] level. Falls back to the base set count when the exact
  /// combination is not found.
  static int getBaseSets(int duration, String difficulty) {
    final idx = _difficultyOrder.indexOf(difficulty);
    if (idx != -1 && _setsByDifficulty.containsKey(duration)) {
      return _setsByDifficulty[duration]![idx];
    }
    // Fallback to base sets
    if (_baseSets.containsKey(duration)) return _baseSets[duration]!;
    // Nearest lower key
    final keys = _baseSets.keys.toList()..sort();
    int result = 2;
    for (final k in keys) {
      if (k <= duration) {
        result = _baseSets[k]!;
      } else {
        break;
      }
    }
    return result;
  }

  // -----------------------------------------------------------------------
  // C5. Exercise count targets (min, max)
  // -----------------------------------------------------------------------
  static const Map<int, _ExerciseCountRange> _supersetsOnCounts = {
    5: _ExerciseCountRange(4, 4),
    10: _ExerciseCountRange(6, 6),
    15: _ExerciseCountRange(6, 8),
    20: _ExerciseCountRange(8, 8),
    25: _ExerciseCountRange(8, 10),
    30: _ExerciseCountRange(10, 12),
  };

  static const Map<int, _ExerciseCountRange> _supersetsOffCounts = {
    5: _ExerciseCountRange(2, 3),
    10: _ExerciseCountRange(4, 5),
    15: _ExerciseCountRange(4, 6),
    20: _ExerciseCountRange(5, 7),
    25: _ExerciseCountRange(6, 8),
    30: _ExerciseCountRange(7, 9),
  };

  static const Map<int, _ExerciseCountRange> _cardioHiitCounts = {
    5: _ExerciseCountRange(3, 4),
    10: _ExerciseCountRange(5, 6),
    15: _ExerciseCountRange(6, 7),
    20: _ExerciseCountRange(7, 8),
    25: _ExerciseCountRange(8, 9),
    30: _ExerciseCountRange(8, 10),
  };

  static const Map<int, _ExerciseCountRange> _stretchCounts = {
    5: _ExerciseCountRange(4, 5),
    10: _ExerciseCountRange(6, 7),
    15: _ExerciseCountRange(7, 8),
    20: _ExerciseCountRange(8, 9),
    25: _ExerciseCountRange(9, 10),
    30: _ExerciseCountRange(10, 12),
  };

  /// Returns (min, max) exercise count for the given parameters.
  static (int, int) getExerciseCountRange(int duration, {bool supersets = false, bool isCardio = false, bool isStretch = false}) {
    final Map<int, _ExerciseCountRange> table;
    if (isStretch) {
      table = _stretchCounts;
    } else if (isCardio) {
      table = _cardioHiitCounts;
    } else if (supersets) {
      table = _supersetsOnCounts;
    } else {
      table = _supersetsOffCounts;
    }

    if (table.containsKey(duration)) {
      final r = table[duration]!;
      return (r.min, r.max);
    }
    // Nearest lower key
    final keys = table.keys.toList()..sort();
    _ExerciseCountRange fallback = const _ExerciseCountRange(3, 5);
    for (final k in keys) {
      if (k <= duration) {
        fallback = table[k]!;
      } else {
        break;
      }
    }
    return (fallback.min, fallback.max);
  }

  // -----------------------------------------------------------------------
  // C6. Antagonist superset pairings
  // -----------------------------------------------------------------------
  static const List<(String, String)> antagonistPairs = [
    ('chest', 'back'),
    ('shoulders', 'back'),
    ('quads', 'hamstrings'),
    ('biceps', 'triceps'),
    ('abs', 'lower_back'),
    ('glutes', 'quads'),
    ('chest', 'shoulders'),
  ];

  /// Finds the antagonist for a given [muscle]. Returns `null` if no
  /// antagonist is mapped.
  static String? getAntagonist(String muscle) {
    final m = muscle.toLowerCase();
    for (final pair in antagonistPairs) {
      if (pair.$1 == m) return pair.$2;
      if (pair.$2 == m) return pair.$1;
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // C7. Cardio fallback exercises (15 bodyweight)
  // -----------------------------------------------------------------------
  static const List<OfflineExercise> cardioFallbackExercises = [
    OfflineExercise(id: 'qw_cardio_01', name: 'Jumping Jacks', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'full_body', difficultyNum: 2),
    OfflineExercise(id: 'qw_cardio_02', name: 'Burpees', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'full_body', difficultyNum: 8),
    OfflineExercise(id: 'qw_cardio_03', name: 'Mountain Climbers', bodyPart: 'core', equipment: 'bodyweight', targetMuscle: 'core', difficultyNum: 5),
    OfflineExercise(id: 'qw_cardio_04', name: 'High Knees', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 3),
    OfflineExercise(id: 'qw_cardio_05', name: 'Jump Squats', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 6),
    OfflineExercise(id: 'qw_cardio_06', name: 'Speed Skaters', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'glutes', difficultyNum: 5),
    OfflineExercise(id: 'qw_cardio_07', name: 'Plank Jacks', bodyPart: 'core', equipment: 'bodyweight', targetMuscle: 'core', difficultyNum: 4),
    OfflineExercise(id: 'qw_cardio_08', name: 'Tuck Jumps', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 7),
    OfflineExercise(id: 'qw_cardio_09', name: 'Jump Lunges', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 7),
    OfflineExercise(id: 'qw_cardio_10', name: 'Bear Crawls', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'full_body', difficultyNum: 6),
    OfflineExercise(id: 'qw_cardio_11', name: 'Lateral Shuffles', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 3),
    OfflineExercise(id: 'qw_cardio_12', name: 'Star Jumps', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'full_body', difficultyNum: 5),
    OfflineExercise(id: 'qw_cardio_13', name: 'Skater Hops', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'glutes', difficultyNum: 4),
    OfflineExercise(id: 'qw_cardio_14', name: 'Sprint in Place', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'full_body', difficultyNum: 4),
    OfflineExercise(id: 'qw_cardio_15', name: 'Inchworms', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'hamstrings', difficultyNum: 5),
  ];

  // -----------------------------------------------------------------------
  // C8. Stretch fallback exercises (15 bodyweight)
  // -----------------------------------------------------------------------
  static const List<OfflineExercise> stretchFallbackExercises = [
    OfflineExercise(id: 'qw_stretch_01', name: 'Standing Hamstring Stretch', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'hamstrings', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_02', name: 'Hip Flexor Stretch', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'hip_flexors', difficultyNum: 2),
    OfflineExercise(id: 'qw_stretch_03', name: 'Pigeon Pose', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'glutes', difficultyNum: 3),
    OfflineExercise(id: 'qw_stretch_04', name: 'Cat-Cow', bodyPart: 'back', equipment: 'bodyweight', targetMuscle: 'lower_back', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_05', name: "Child's Pose", bodyPart: 'back', equipment: 'bodyweight', targetMuscle: 'lower_back', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_06', name: "World's Greatest Stretch", bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'hip_flexors', difficultyNum: 3),
    OfflineExercise(id: 'qw_stretch_07', name: 'Standing Quad Stretch', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'quads', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_08', name: 'Chest Doorway Stretch', bodyPart: 'chest', equipment: 'bodyweight', targetMuscle: 'chest', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_09', name: 'Shoulder Cross-Body Stretch', bodyPart: 'shoulders', equipment: 'bodyweight', targetMuscle: 'shoulders', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_10', name: 'Spinal Twist', bodyPart: 'back', equipment: 'bodyweight', targetMuscle: 'lower_back', difficultyNum: 2),
    OfflineExercise(id: 'qw_stretch_11', name: 'Downward Dog', bodyPart: 'full_body', equipment: 'bodyweight', targetMuscle: 'hamstrings', difficultyNum: 2),
    OfflineExercise(id: 'qw_stretch_12', name: 'Cobra Stretch', bodyPart: 'back', equipment: 'bodyweight', targetMuscle: 'abs', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_13', name: 'Seated Forward Fold', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'hamstrings', difficultyNum: 2),
    OfflineExercise(id: 'qw_stretch_14', name: 'Calf Stretch', bodyPart: 'legs', equipment: 'bodyweight', targetMuscle: 'calves', difficultyNum: 1),
    OfflineExercise(id: 'qw_stretch_15', name: 'Neck Circles', bodyPart: 'neck', equipment: 'bodyweight', targetMuscle: 'neck', difficultyNum: 1),
  ];

  // -----------------------------------------------------------------------
  // C9. Workout name pools (random selection for variety)
  // -----------------------------------------------------------------------
  static const Map<String, List<String>> workoutNamePools = {
    'strength': [
      'Quick Strength Blast',
      'Express Power Session',
      'Rapid Strength Hit',
      'Speed Strength',
      'Power Express',
    ],
    'cardio': [
      'HIIT Express',
      'Quick Cardio Blast',
      'Rapid Fire Cardio',
      'Cardio Surge',
      'Burn Express',
    ],
    'stretch': [
      'Quick Flexibility Flow',
      'Express Mobility',
      'Rapid Recovery',
      'Flex Express',
      'Stretch & Release',
    ],
    'full_body': [
      'Total Body Express',
      'Full Body Blitz',
      'Complete Quick Hit',
      'Total Burn Express',
    ],
    'upper_body': [
      'Upper Body Express',
      'Arms & Shoulders Blast',
      'Push-Pull Express',
      'Upper Pump',
    ],
    'lower_body': [
      'Leg Day Express',
      'Lower Body Blast',
      'Quick Leg Burn',
      'Glutes & Legs Express',
    ],
    'core': [
      'Core Crusher Express',
      'Ab Blast',
      'Core Strength Quick',
      'Midsection Express',
    ],
    'emom': [
      'EMOM Express',
      'Every Minute Power',
      'EMOM Challenge',
      'Minute-by-Minute',
    ],
    'amrap': [
      'AMRAP Assault',
      'Max Rounds Express',
      'AMRAP Challenge',
      'Race the Clock',
    ],
  };

  /// Returns a random workout name for the given [focus] category.
  /// Falls back to 'full_body' names when the focus is not found.
  static String getRandomWorkoutName(String focus) {
    final pool = workoutNamePools[focus] ?? workoutNamePools['full_body']!;
    return pool[_rng.nextInt(pool.length)];
  }
}
