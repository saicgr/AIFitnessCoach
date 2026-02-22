import 'dart:math';

import 'equipment_context.dart';
import 'offline_workout_generator.dart';
import 'workout_templates.dart';

/// Exercise selection algorithm for offline workout generation.
///
/// Filters the cached exercise library by muscle group, equipment,
/// and user preferences, then selects exercises using a priority system:
/// staples > compounds > previously performed > random.

final _random = Random();

/// Heuristic to detect unilateral exercises by name patterns.
///
/// Returns [ex.isUnilateral] if explicitly set, otherwise checks name patterns.
bool isLikelyUnilateral(OfflineExercise ex) {
  if (ex.isUnilateral != null) return ex.isUnilateral!;
  final name = (ex.name ?? '').toLowerCase();
  const unilateralPatterns = [
    'single arm',
    'single-arm',
    'single leg',
    'single-leg',
    'one arm',
    'one-arm',
    'alternating',
    'split squat',
    'bulgarian',
    'pistol',
    'step up',
    'step-up',
    'lunge',
    'goblet',
  ];
  return unilateralPatterns.any((p) => name.contains(p));
}

/// Heuristic to detect bilateral exercises that require paired equipment.
///
/// Returns false if the exercise is already identified as unilateral.
bool isLikelyBilateral(OfflineExercise ex) {
  if (isLikelyUnilateral(ex)) return false;
  final name = (ex.name ?? '').toLowerCase();
  const bilateralDumbbellPatterns = [
    'dumbbell bench press',
    'dumbbell shoulder press',
    'dumbbell fly',
    'dumbbell curl',
    'dumbbell lateral raise',
    'farmer walk',
    'farmer\'s walk',
    'dumbbell shrug',
    'dumbbell row', // bent-over dumbbell row (both arms)
    'dumbbell front raise',
    'dumbbell hammer curl',
  ];
  return bilateralDumbbellPatterns.any((p) => name.contains(p));
}

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
  EquipmentContext? equipmentContext,
}) {
  final targetLower = targetMuscle.toLowerCase();

  // Get all valid names for this muscle group
  final aliases = muscleAliases[targetLower] ?? [targetLower];

  // Build set of avoided exercise names (lowercase)
  final avoidedSet = avoidedExercises.map((e) => e.toLowerCase()).toSet();

  // Build set of available equipment (lowercase), empty means "all allowed"
  final equipmentSet = equipment.map((e) => e.toLowerCase()).toSet();

  final result = library.where((ex) {
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

  // Post-filter: remove bilateral dumbbell/kettlebell exercises when
  // the inventory only has quantity 1 for those types.
  if (equipmentContext != null && equipmentContext.hasDetailedInventory) {
    return result.where((ex) {
      if (!isLikelyBilateral(ex)) return true;

      final exEquip = (ex.equipment ?? '').toLowerCase();
      String? typeKey;
      if (exEquip.contains('dumbbell')) {
        typeKey = 'dumbbell';
      } else if (exEquip.contains('kettlebell')) {
        typeKey = 'kettlebell';
      }
      if (typeKey == null) return true;

      final inv = equipmentContext.getInventory(typeKey);
      if (inv == null || !inv.isPairType) return true;

      // Check if ANY weight has quantity >= 2
      return inv.weightToQuantity.values.any((qty) => qty >= 2);
    }).toList();
  }

  return result;
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
  bool preferUnilateral = false,
  Set<String> alreadySelected = const {},
}) {
  if (filtered.isEmpty) return null;

  // Remove already-selected exercises
  final available = filtered
      .where((ex) => !alreadySelected.contains((ex.name ?? '').toLowerCase()))
      .toList();

  if (available.isEmpty) return null;

  // 0. If preferUnilateral, try to select from unilateral pool first
  if (preferUnilateral) {
    final unilateral = available.where((ex) => isLikelyUnilateral(ex)).toList();
    if (unilateral.isNotEmpty) {
      // Among unilateral, still prefer staples > compounds > known > random
      final staplesLower = stapleExercises.map((s) => s.toLowerCase()).toSet();
      final uniStaples = unilateral
          .where((ex) => staplesLower.contains((ex.name ?? '').toLowerCase()))
          .toList();
      if (uniStaples.isNotEmpty) {
        return uniStaples[_random.nextInt(uniStaples.length)];
      }
      final uniKnown = unilateral
          .where((ex) => previouslyPerformed.contains((ex.name ?? '').toLowerCase()))
          .toList();
      if (uniKnown.isNotEmpty) {
        return uniKnown[_random.nextInt(uniKnown.length)];
      }
      return unilateral[_random.nextInt(unilateral.length)];
    }
    // Fall through to normal selection if no unilateral found
  }

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

/// Select an exercise using weighted scoring for better variety.
///
/// Score = 0.25*freshness + 0.18*staple + 0.12*knownData + 0.12*collaborative + 0.10*sfr + 0.10*random + bonuses
///
/// [freshness] uses exponential decay: e^(-0.3 * sessionsSinceLastUse)
/// [sessionsSinceLastUse] maps exercise name (lowercase) to session count
/// [collaborativeScores] maps exercise name (lowercase) to population score (0-1)
/// [sfrScores] maps exercise name (lowercase) to SFR score (0-1, higher = more efficient)
///
/// Falls back to [selectForSlot] if scoring produces no viable candidates.
OfflineExercise? selectForSlotWeighted(
  List<OfflineExercise> filtered, {
  List<String> stapleExercises = const [],
  Set<String> previouslyPerformed = const {},
  bool preferCompound = false,
  bool preferUnilateral = false,
  Set<String> alreadySelected = const {},
  Map<String, int> sessionsSinceLastUse = const {},
  Map<String, double> collaborativeScores = const {},
  Map<String, double> sfrScores = const {},
}) {
  if (filtered.isEmpty) return null;

  // Remove already-selected exercises
  final available = filtered
      .where((ex) => !alreadySelected.contains((ex.name ?? '').toLowerCase()))
      .toList();

  if (available.isEmpty) return null;
  if (available.length == 1) return available.first;

  final staplesLower = stapleExercises.map((s) => s.toLowerCase()).toSet();

  // Score each candidate
  final scores = <double>[];
  for (final ex in available) {
    final name = (ex.name ?? '').toLowerCase();

    // Freshness: e^(-0.3 * sessions_since_last_use), default to 10 if never used
    final sessionsSince = sessionsSinceLastUse[name] ?? 10; // 10 = very fresh
    final freshness = exp(-0.3 * sessionsSince.clamp(0, 20));
    // Invert: higher freshness score = MORE sessions since last use = FRESHER
    final freshnessScore = 1.0 - freshness;

    // Staple bonus
    final stapleScore = staplesLower.contains(name) ? 1.0 : 0.0;

    // Known data bonus (has 1RM / previous performance)
    final knownScore = previouslyPerformed.contains(name) ? 1.0 : 0.0;

    // Collaborative filtering score (population-level signal)
    final collabScore = collaborativeScores[name] ?? 0.0;

    // Compound preference
    double compoundBonus = 0;
    if (preferCompound && _isLikelyCompound(ex)) compoundBonus = 0.3;

    // Unilateral preference
    double unilateralBonus = 0;
    if (preferUnilateral && isLikelyUnilateral(ex)) unilateralBonus = 0.2;

    // Random component
    final randomScore = _random.nextDouble();

    // SFR score (higher = more efficient exercise)
    final sfrScore = sfrScores[name] ?? 0.5; // neutral default

    // Weighted score (updated with collaborative filtering + SFR)
    final score = 0.25 * freshnessScore +
        0.18 * stapleScore +
        0.12 * knownScore +
        0.12 * collabScore +
        0.10 * sfrScore +
        0.10 * randomScore +
        compoundBonus +
        unilateralBonus;

    scores.add(score);
  }

  // Weighted random selection using scores as probabilities
  final totalScore = scores.reduce((a, b) => a + b);
  if (totalScore <= 0) return available[_random.nextInt(available.length)];

  var threshold = _random.nextDouble() * totalScore;
  for (int i = 0; i < available.length; i++) {
    threshold -= scores[i];
    if (threshold <= 0) return available[i];
  }

  return available.last;
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
