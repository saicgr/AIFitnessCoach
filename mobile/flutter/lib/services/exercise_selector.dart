import 'dart:math';

import 'offline_workout_generator.dart';
import 'workout_templates.dart';

/// Exercise selection algorithm for offline workout generation.
///
/// Filters the cached exercise library by muscle group, equipment,
/// and user preferences, then selects exercises using a priority system:
/// staples > compounds > previously performed > random.

final _random = Random();

/// Filter exercises from the library matching the given criteria.
///
/// Returns exercises that match [targetMuscle], are available with
/// the user's [equipment], and are not in the avoided lists.
List<OfflineExercise> filterExercises(
  List<OfflineExercise> library, {
  required String targetMuscle,
  List<String> equipment = const [],
  List<String> avoidedExercises = const [],
  Set<String> avoidedMuscles = const {},
  String fitnessLevel = 'intermediate',
}) {
  final targetLower = targetMuscle.toLowerCase();

  // Get all valid names for this muscle group
  final aliases = muscleAliases[targetLower] ?? [targetLower];

  // Build set of avoided exercise names (lowercase)
  final avoidedSet = avoidedExercises.map((e) => e.toLowerCase()).toSet();

  // Build set of available equipment (lowercase), empty means "all allowed"
  final equipmentSet = equipment.map((e) => e.toLowerCase()).toSet();

  return library.where((ex) {
    // Check if exercise targets the right muscle
    final exTarget = (ex.targetMuscle ?? '').toLowerCase();
    final exPrimary = (ex.primaryMuscle ?? '').toLowerCase();
    final exBodyPart = (ex.bodyPart ?? '').toLowerCase();

    final matchesMuscle = aliases.any((alias) =>
        exTarget.contains(alias) ||
        exPrimary.contains(alias) ||
        exBodyPart.contains(alias));

    if (!matchesMuscle) return false;

    // Check not in avoided exercises
    final exName = (ex.name ?? '').toLowerCase();
    if (avoidedSet.contains(exName)) return false;

    // Check exercise's target muscle isn't in avoided muscles
    if (avoidedMuscles.contains(exTarget) ||
        avoidedMuscles.contains(exPrimary)) {
      return false;
    }

    // Check secondary muscles don't overlap with avoided
    if (ex.secondaryMuscles != null && avoidedMuscles.isNotEmpty) {
      final secondaries = ex.secondaryMuscles!
          .map((m) => m.toLowerCase())
          .toSet();
      if (secondaries.intersection(avoidedMuscles).isNotEmpty) {
        return false;
      }
    }

    // Check equipment availability (empty = all allowed)
    if (equipmentSet.isNotEmpty) {
      final exEquip = (ex.equipment ?? '').toLowerCase();
      // Bodyweight exercises are always available
      if (exEquip.contains('bodyweight') ||
          exEquip.contains('body weight') ||
          exEquip.contains('none') ||
          exEquip.isEmpty) {
        // Always allowed
      } else if (!equipmentSet.any((eq) => exEquip.contains(eq))) {
        return false;
      }
    }

    // Check difficulty level compatibility
    if (fitnessLevel == 'beginner') {
      final diff = ex.difficultyNum ?? 5;
      if (diff > 6) return false; // Skip hard exercises for beginners
    }

    return true;
  }).toList();
}

/// Select a single exercise from [filtered] candidates for one slot.
///
/// Priority order:
/// 1. Staple exercises (user's preferred exercises)
/// 2. Compound exercises (if [preferCompound] is true)
/// 3. Previously performed exercises (have known weights)
/// 4. Random selection for variety
///
/// [alreadySelected] prevents duplicate exercises in the same workout.
OfflineExercise? selectForSlot(
  List<OfflineExercise> filtered, {
  List<String> stapleExercises = const [],
  Set<String> previouslyPerformed = const {},
  bool preferCompound = false,
  Set<String> alreadySelected = const {},
}) {
  if (filtered.isEmpty) return null;

  // Remove already-selected exercises
  final available = filtered
      .where((ex) => !alreadySelected.contains((ex.name ?? '').toLowerCase()))
      .toList();

  if (available.isEmpty) return null;

  // Build lowercase staples set
  final staplesLower = stapleExercises.map((s) => s.toLowerCase()).toSet();

  // 1. Try staple exercises first
  final staples = available
      .where((ex) => staplesLower.contains((ex.name ?? '').toLowerCase()))
      .toList();
  if (staples.isNotEmpty) {
    return staples[_random.nextInt(staples.length)];
  }

  // 2. Prefer compound exercises if requested
  if (preferCompound) {
    final compounds = available
        .where((ex) =>
            (ex.difficulty ?? '').toLowerCase() != 'isolation' &&
            _isLikelyCompound(ex))
        .toList();
    if (compounds.isNotEmpty) {
      // Among compounds, prefer previously performed
      final knownCompounds = compounds
          .where(
              (ex) => previouslyPerformed.contains((ex.name ?? '').toLowerCase()))
          .toList();
      if (knownCompounds.isNotEmpty) {
        return knownCompounds[_random.nextInt(knownCompounds.length)];
      }
      return compounds[_random.nextInt(compounds.length)];
    }
  }

  // 3. Prefer previously performed (have known weights)
  final known = available
      .where(
          (ex) => previouslyPerformed.contains((ex.name ?? '').toLowerCase()))
      .toList();
  if (known.isNotEmpty) {
    return known[_random.nextInt(known.length)];
  }

  // 4. Random selection
  return available[_random.nextInt(available.length)];
}

/// Heuristic to detect compound exercises by name patterns.
bool _isLikelyCompound(OfflineExercise ex) {
  final name = (ex.name ?? '').toLowerCase();
  const compoundPatterns = [
    'bench press',
    'squat',
    'deadlift',
    'overhead press',
    'military press',
    'barbell row',
    'bent over row',
    'pull up',
    'pull-up',
    'chin up',
    'chin-up',
    'dip',
    'lunge',
    'hip thrust',
    'clean',
    'snatch',
    'push press',
    'front squat',
    'romanian deadlift',
    'rdl',
    'pendlay row',
    't-bar row',
    'incline press',
    'decline press',
    'leg press',
    'hack squat',
  ];
  return compoundPatterns.any((p) => name.contains(p));
}
