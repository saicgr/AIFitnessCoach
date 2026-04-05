import 'dart:math';

import 'package:uuid/uuid.dart';

import '../data/models/exercise.dart';
import '../data/models/workout.dart';
import 'equipment_context.dart';
import 'equipment_context_resolver.dart';
import 'exercise_selector.dart' as selector;
import 'injury_muscle_mapping.dart';
import 'mesocycle_planner.dart';
import 'offline_workout_generator.dart';
import 'progressive_overload.dart' as overload;
import 'quick_workout_constants.dart';
import 'quick_workout_templates.dart';
import 'advanced_techniques.dart';
import 'movement_patterns.dart';
import 'quick_workout_rest.dart';
import 'hrv_recovery_service.dart';
import 'rpe_feedback_service.dart';
import 'volume_landmark_service.dart';
import 'workout_templates.dart' show muscleAliases;

part 'quick_workout_engine_part_selected_exercise.dart';

part 'quick_workout_engine_ui.dart';


const _uuid = Uuid();
final _random = Random();

/// Pure-Dart, rule-based quick workout generator.
///
/// Produces workouts in <100ms using research-backed constants,
/// a strategy pattern for each focus mode, and existing exercise
/// selection / progressive overload infrastructure.
///
/// See `QUICK_WORKOUT_ENGINE.md` for the full algorithm documentation.
class QuickWorkoutEngine {

  // =====================================================================
  // Private helpers
  // =====================================================================

  /// Round weight to nearest 0.5kg for display.
  static double _roundWeight(double weight) {
    return (weight * 2).round() / 2;
  }

  /// Select an exercise for a muscle slot, using the existing ExerciseSelector
  /// infrastructure with additional variety and mood bias handling.
  /// Get equipment-specific weight increment for progressive overload.
  static double _getEquipmentIncrement(String? equipment) {
    if (equipment == null) return 2.5;
    final lower = equipment.toLowerCase();
    if (lower.contains('dumbbell')) return 2.0;
    if (lower.contains('kettlebell')) return 4.0;
    if (lower.contains('machine')) return 5.0;
    if (lower.contains('cable')) return 2.5;
    return 2.5; // barbell default
  }

  OfflineExercise? _selectExerciseForSlot({
    required QuickMuscleSlot slot,
    required List<OfflineExercise> library,
    required List<String> effectiveEquipment,
    required List<String> avoidedExercises,
    required Set<String> avoidedMuscles,
    required String effectiveFitnessLevel,
    required List<String> stapleExercises,
    required Set<String> previouslyPerformed,
    required Set<String> alreadySelectedNames,
    required Set<String> recentlyUsedExercises,
    String? exerciseBias,
    required String focus,
    EquipmentContext? equipmentContext,
    bool preferUnilateral = false,
    Map<String, int> sessionsSinceLastUse = const {},
    Map<String, double> collaborativeScores = const {},
    Map<String, double> sfrScores = const {},
  }) {
    // For cardio focus, use cardio-specific selection
    if (focus == 'cardio') {
      return _selectCardioExercise(
        library: library,
        alreadySelectedNames: alreadySelectedNames,
        recentlyUsedExercises: recentlyUsedExercises,
        effectiveFitnessLevel: effectiveFitnessLevel,
      );
    }

    // For stretch focus, use stretch-specific selection
    if (focus == 'stretch') {
      return _selectStretchExercise(
        slot: slot,
        library: library,
        alreadySelectedNames: alreadySelectedNames,
        recentlyUsedExercises: recentlyUsedExercises,
      );
    }

    // Standard muscle-targeted selection using existing infrastructure
    final candidates = selector.filterExercises(
      library,
      targetMuscle: slot.muscle,
      equipment: effectiveEquipment,
      avoidedExercises: avoidedExercises,
      avoidedMuscles: avoidedMuscles,
      fitnessLevel: effectiveFitnessLevel,
      equipmentContext: equipmentContext,
    );

    if (candidates.isEmpty) return null;

    // Apply variety: penalize recently used exercises
    final freshCandidates = candidates
        .where((ex) => !recentlyUsedExercises.contains((ex.name ?? '').toLowerCase()))
        .toList();

    // Use fresh candidates if available, otherwise use all
    final pool = freshCandidates.isNotEmpty ? freshCandidates : candidates;

    // Apply mood exercise bias
    var preferCompound = slot.preferCompound;
    if (exerciseBias == 'compound') {
      preferCompound = true;
    } else if (exerciseBias == 'isolation') {
      preferCompound = false;
    }

    if (sessionsSinceLastUse.isNotEmpty || collaborativeScores.isNotEmpty || sfrScores.isNotEmpty) {
      return selector.selectForSlotWeighted(
        pool,
        stapleExercises: stapleExercises,
        previouslyPerformed: previouslyPerformed,
        preferCompound: preferCompound,
        preferUnilateral: preferUnilateral,
        alreadySelected: alreadySelectedNames,
        sessionsSinceLastUse: sessionsSinceLastUse,
        collaborativeScores: collaborativeScores,
        sfrScores: sfrScores,
      );
    }

    return selector.selectForSlot(
      pool,
      stapleExercises: stapleExercises,
      previouslyPerformed: previouslyPerformed,
      preferCompound: preferCompound,
      preferUnilateral: preferUnilateral,
      alreadySelected: alreadySelectedNames,
    );
  }

  /// Select a cardio exercise from the library or fallback pool.
  OfflineExercise? _selectCardioExercise({
    required List<OfflineExercise> library,
    required Set<String> alreadySelectedNames,
    required Set<String> recentlyUsedExercises,
    required String effectiveFitnessLevel,
  }) {
    // Search patterns for cardio exercises in the library
    const cardioPatterns = [
      'jump', 'burpee', 'mountain climber', 'high knee', 'sprint',
      'run', 'jog', 'skip', 'hop', 'lunge jump', 'squat jump',
      'cardio', 'hiit', 'plyo', 'box jump', 'shuttle',
    ];

    // Filter library for cardio-ish exercises
    final libraryCardio = library.where((ex) {
      final name = (ex.name ?? '').toLowerCase();
      final already = alreadySelectedNames.contains(name);
      if (already) return false;
      return cardioPatterns.any((p) => name.contains(p));
    }).toList();

    // Merge with fallback pool
    final pool = <OfflineExercise>[
      ...libraryCardio,
      ...QuickWorkoutConstants.cardioFallbackExercises
          .where((ex) => !alreadySelectedNames.contains((ex.name ?? '').toLowerCase())),
    ];

    if (pool.isEmpty) return null;

    // Prefer fresh (not recently used) exercises
    final fresh = pool
        .where((ex) => !recentlyUsedExercises.contains((ex.name ?? '').toLowerCase()))
        .toList();

    final candidates = fresh.isNotEmpty ? fresh : pool;

    // Filter by difficulty for beginners
    if (effectiveFitnessLevel == 'beginner') {
      final easy = candidates.where((ex) => (ex.difficultyNum ?? 5) <= 5).toList();
      if (easy.isNotEmpty) return easy[_random.nextInt(easy.length)];
    }

    return candidates[_random.nextInt(candidates.length)];
  }

  /// Select a stretch exercise from the library or fallback pool.
  OfflineExercise? _selectStretchExercise({
    required QuickMuscleSlot slot,
    required List<OfflineExercise> library,
    required Set<String> alreadySelectedNames,
    required Set<String> recentlyUsedExercises,
  }) {
    const stretchPatterns = [
      'stretch', 'mobility', 'yoga', 'flexibility', 'hold',
      'pose', 'flow', 'foam roll', 'release', 'open',
    ];

    // Get aliases for target muscle
    final aliases = muscleAliases[slot.muscle.toLowerCase()] ?? [slot.muscle.toLowerCase()];

    // Filter library for stretches targeting the right muscle
    final libraryStretches = library.where((ex) {
      final name = (ex.name ?? '').toLowerCase();
      final target = (ex.targetMuscle ?? '').toLowerCase();
      final bodyPart = (ex.bodyPart ?? '').toLowerCase();
      if (alreadySelectedNames.contains(name)) return false;

      final isStretchExercise = stretchPatterns.any((p) => name.contains(p));
      final matchesMuscle = aliases.any((a) =>
          target.contains(a) || bodyPart.contains(a) || name.contains(a));

      return isStretchExercise && matchesMuscle;
    }).toList();

    // Merge with relevant fallback stretches
    final fallbacks = QuickWorkoutConstants.stretchFallbackExercises.where((ex) {
      final name = (ex.name ?? '').toLowerCase();
      if (alreadySelectedNames.contains(name)) return false;
      final target = (ex.targetMuscle ?? '').toLowerCase();
      return aliases.any((a) => target.contains(a));
    }).toList();

    final pool = [...libraryStretches, ...fallbacks];

    if (pool.isEmpty) {
      // Fall back to any stretch not already selected
      final anyStretch = QuickWorkoutConstants.stretchFallbackExercises
          .where((ex) => !alreadySelectedNames.contains((ex.name ?? '').toLowerCase()))
          .toList();
      if (anyStretch.isEmpty) return null;
      return anyStretch[_random.nextInt(anyStretch.length)];
    }

    // Prefer fresh exercises
    final fresh = pool
        .where((ex) => !recentlyUsedExercises.contains((ex.name ?? '').toLowerCase()))
        .toList();
    final candidates = fresh.isNotEmpty ? fresh : pool;
    return candidates[_random.nextInt(candidates.length)];
  }

  /// Find the index of a superset partner exercise in the selected list.
  int? _findPartnerIndex(
    List<_SelectedExercise> selected,
    int currentIndex,
    String partnerMuscle,
    Set<int> alreadyPaired,
  ) {
    for (int j = currentIndex + 1; j < selected.length; j++) {
      if (alreadyPaired.contains(j)) continue;
      if (selected[j].slot.muscle.toLowerCase() == partnerMuscle.toLowerCase()) {
        return j;
      }
    }
    return null;
  }

  /// Add fallback exercises when too few were found (severe injury scenario).
  void _addFallbackExercises(
    List<_SelectedExercise> selected,
    String focus,
    Set<String> alreadySelectedNames,
    Set<String> avoidedMuscles,
    String difficulty,
  ) {
    final fallbacks = focus == 'cardio'
        ? QuickWorkoutConstants.cardioFallbackExercises
        : focus == 'stretch'
            ? QuickWorkoutConstants.stretchFallbackExercises
            : QuickWorkoutConstants.cardioFallbackExercises; // generic bodyweight

    for (final fb in fallbacks) {
      if (selected.length >= 3) break;
      final name = (fb.name ?? '').toLowerCase();
      if (alreadySelectedNames.contains(name)) continue;

      // Check muscle isn't avoided
      final target = (fb.targetMuscle ?? '').toLowerCase();
      if (avoidedMuscles.contains(target)) continue;

      alreadySelectedNames.add(name);
      selected.add(_SelectedExercise(
        exercise: fb,
        slot: const QuickMuscleSlot('full_body'),
        timeCost: QuickWorkoutConstants.circuitTimeCost,
      ));
    }
  }
}
