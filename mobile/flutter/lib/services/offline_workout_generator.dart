import 'package:uuid/uuid.dart';

import '../data/models/exercise.dart';
import '../data/models/workout.dart';
import 'exercise_selector.dart' as selector;
import 'injury_muscle_mapping.dart';
import 'progressive_overload.dart' as overload;
import 'workout_templates.dart';

/// Lightweight exercise data class for offline generation.
///
/// Mirrors the fields needed from the cached exercise library
/// without depending on drift-generated code.
class OfflineExercise {
  final String? id;
  final String? name;
  final String? bodyPart;
  final String? equipment;
  final String? targetMuscle;
  final String? primaryMuscle;
  final List<String>? secondaryMuscles;
  final String? difficulty;
  final int? difficultyNum;
  final String? videoUrl;
  final String? imageS3Path;
  final bool? isUnilateral;

  const OfflineExercise({
    this.id,
    this.name,
    this.bodyPart,
    this.equipment,
    this.targetMuscle,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.difficulty,
    this.difficultyNum,
    this.videoUrl,
    this.imageS3Path,
    this.isUnilateral,
  });

  /// Create from a JSON map (matching the bundled exercise_library.json format).
  factory OfflineExercise.fromJson(Map<String, dynamic> json) {
    List<String>? secondaryMuscles;
    final sm = json['secondary_muscles'];
    if (sm is List) {
      secondaryMuscles = sm.map((e) => e.toString()).toList();
    } else if (sm is String && sm.isNotEmpty) {
      secondaryMuscles =
          sm.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    int? difficultyNum;
    final dl = json['difficulty_level'] ?? json['difficulty_num'];
    if (dl is int) {
      difficultyNum = dl;
    } else if (dl is String) {
      difficultyNum = int.tryParse(dl);
    }

    return OfflineExercise(
      id: json['id'] as String?,
      name: json['name'] as String?,
      bodyPart: json['body_part'] as String?,
      equipment: json['equipment'] as String?,
      targetMuscle: json['target_muscle'] as String?,
      primaryMuscle: (json['primary_muscle'] ?? json['target_muscle']) as String?,
      secondaryMuscles: secondaryMuscles,
      difficulty: dl?.toString(),
      difficultyNum: difficultyNum,
      videoUrl: json['video_url'] as String?,
      imageS3Path: (json['image_s3_path'] ?? json['image_url']) as String?,
    );
  }
}

const _uuid = Uuid();

/// Rule-based offline workout generator.
///
/// Generates complete workouts algorithmically without any network
/// connection. Uses workout templates, exercise filtering, progressive
/// overload, and injury-aware muscle avoidance.
///
/// Designed to execute in <50ms synchronously.
class OfflineWorkoutGenerator {
  /// Generate a workout using the rule-based algorithm.
  ///
  /// Returns a [Workout] object fully compatible with the server format,
  /// including proper [SetTarget] objects for each exercise.
  Workout generate({
    required String userId,
    required String splitType,
    required String scheduledDate,
    required List<OfflineExercise> exerciseLibrary,
    String fitnessLevel = 'intermediate',
    String goal = 'muscle_hypertrophy',
    List<String> availableEquipment = const [],
    List<String> avoidedExercises = const [],
    List<String> avoidedMuscles = const [],
    List<String> injuries = const [],
    List<String> stapleExercises = const [],
    Map<String, double> oneRepMaxes = const {},
  }) {
    // 1. Expand injuries into avoided muscles
    final injuryMuscles = expandInjuriesToMuscles(injuries);
    final allAvoidedMuscles = <String>{
      ...avoidedMuscles.map((m) => m.toLowerCase()),
      ...injuryMuscles,
    };

    // 2. Get the workout template
    final template = getTemplate(splitType);

    // 3. Build set of previously performed exercise names (have 1RM data)
    final previouslyPerformed =
        oneRepMaxes.keys.map((k) => k.toLowerCase()).toSet();

    // 4. Select exercises for each muscle slot
    final selectedExercises = <WorkoutExercise>[];
    final alreadySelected = <String>{};
    int estimatedMinutes = 0;

    for (final slot in template.slots) {
      for (int i = 0; i < slot.count; i++) {
        // Filter library for this slot
        final candidates = selector.filterExercises(
          exerciseLibrary,
          targetMuscle: slot.muscle,
          equipment: availableEquipment,
          avoidedExercises: avoidedExercises,
          avoidedMuscles: allAvoidedMuscles,
          fitnessLevel: fitnessLevel,
        );

        // Select one exercise
        final selected = selector.selectForSlot(
          candidates,
          stapleExercises: stapleExercises,
          previouslyPerformed: previouslyPerformed,
          preferCompound: slot.compoundFirst && i == 0,
          alreadySelected: alreadySelected,
        );

        if (selected == null) continue;

        final exName = (selected.name ?? '').toLowerCase();
        alreadySelected.add(exName);

        // Check if compound
        final isCompound = slot.compoundFirst && i == 0;

        // Get 1RM if available
        final orm = oneRepMaxes[exName];

        // Generate set targets
        final setTargets = overload.generateSetTargets(
          exerciseName: selected.name ?? '',
          oneRepMax: orm,
          fitnessLevel: fitnessLevel,
          goal: goal,
          isCompound: isCompound,
          equipment: selected.equipment,
        );

        // Calculate rest and reps for display
        final restSecs = overload.getRestSeconds(
          goal: goal,
          isCompound: isCompound,
        );
        final displayReps = overload.getDefaultReps(goal: goal);
        final totalSets = setTargets.length;

        // Calculate working weight for the exercise-level weight field
        double? workingWeight;
        if (orm != null && orm > 0) {
          final intensity = overload.getIntensityPercent(
            goal: goal,
            fitnessLevel: fitnessLevel,
          );
          workingWeight = overload.calculateWorkingWeight(
            orm,
            intensity,
            equipmentType: overload.detectEquipmentType(selected.equipment),
          );
        }

        // Estimate time for this exercise: sets * (set_time + rest)
        // Average set ~45s, plus rest between sets
        estimatedMinutes +=
            ((totalSets * (45 + restSecs)) / 60).ceil();

        selectedExercises.add(WorkoutExercise(
          id: _uuid.v4(),
          exerciseId: selected.id,
          nameValue: selected.name,
          sets: totalSets,
          reps: displayReps,
          restSeconds: restSecs,
          weight: workingWeight,
          bodyPart: selected.bodyPart,
          equipment: selected.equipment,
          muscleGroup: slot.muscle,
          primaryMuscle: selected.primaryMuscle ?? selected.targetMuscle,
          secondaryMuscles: selected.secondaryMuscles,
          difficulty: selected.difficulty,
          difficultyNum: selected.difficultyNum,
          weightSource: orm != null ? '1rm_calculated' : null,
          setTargets: setTargets,
          isCompleted: false,
        ));
      }
    }

    // Clamp estimated duration to reasonable range
    estimatedMinutes = estimatedMinutes.clamp(25, 90);

    // 5. Build the workout name
    final workoutName = workoutNameFromSplit(splitType, scheduledDate);

    // 6. Serialize exercises to JSON list (matches server format)
    final exercisesJsonList =
        selectedExercises.map((e) => e.toJson()).toList();

    return Workout(
      id: _uuid.v4(),
      userId: userId,
      name: workoutName,
      type: splitType,
      difficulty: fitnessLevel,
      scheduledDate: scheduledDate,
      isCompleted: false,
      exercisesJson: exercisesJsonList,
      durationMinutes: estimatedMinutes,
      estimatedDurationMinutes: estimatedMinutes,
      generationMethod: 'rule_based_offline',
      generationMetadata: {
        'generator': 'offline_rule_based',
        'goal': goal,
        'fitness_level': fitnessLevel,
        'split_type': splitType,
        'exercise_count': selectedExercises.length,
        'had_1rm_data': oneRepMaxes.isNotEmpty,
      },
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
