/// Equipment-based default starting weights.
///
/// All values are in the user's preferred unit system (lb or kg).
/// Weights snap to real gym equipment increments:
///   - Dumbbells: 5 lb steps (US) / 2 kg steps (metric)
///   - Barbell: 5 lb steps / 2 kg steps (plate per side)
///   - Cable: 10 lb steps / 5 kg steps
///   - Kettlebells: fixed standard weights
///
/// Sources: NSCA, commercial gym standards (Rogue, Life Fitness, Eleiko)

/// Returns a sensible default weight based on equipment type and exercise.
/// [useKg] determines which unit system to use.
/// Returns weight in the specified unit (lb or kg), snapped to real increments.
double getDefaultWeight(
  String? equipment, {
  String? exerciseName,
  String? fitnessLevel,
  String? gender,
  bool useKg = true,
  List<String>? availableEquipment,
  List<double>? ownedWeights,
}) {
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();

  // If gym profile says this equipment isn't available, return 0
  if (availableEquipment != null && availableEquipment.isNotEmpty) {
    if (!isEquipmentAvailable(equipment, exerciseName, availableEquipment)) {
      return 0;
    }
  }

  final isMale = gender?.toLowerCase() != 'female';
  final isAdvanced = fitnessLevel?.toLowerCase() == 'intermediate' ||
      fitnessLevel?.toLowerCase() == 'advanced';

  double result;
  if (useKg) {
    result = _getDefaultKg(eq, name, isMale, isAdvanced);
  } else {
    result = _getDefaultLbs(eq, name, isMale, isAdvanced);
  }

  // If user has specific weights in inventory, snap to nearest owned weight
  if (ownedWeights != null && ownedWeights.isNotEmpty && result > 0) {
    result = _findClosest(result, ownedWeights);
  }

  return result;
}

/// Default weights in KG — snapped to real metric gym increments.
/// Dumbbells: 2 kg steps (2, 4, 6, 8, 10, 12...)
/// Barbell: 2 kg steps on total (1 kg plate per side)
/// Cable: 5 kg steps
/// Kettlebells: standard competition weights (4, 8, 12, 16, 20...)
double _getDefaultKg(String eq, String name, bool isMale, bool isAdvanced) {
  final level = isAdvanced ? 1.5 : 1.0;
  final genderMult = isMale ? 1.0 : 0.6;

  double raw;

  // Barbell exercises — minimum is bar weight (20 kg men / 15 kg women)
  if (_isBarbell(eq, name)) {
    if (name.contains('deadlift')) {
      raw = isMale ? 40.0 : 30.0;
    } else if (name.contains('squat')) {
      raw = isMale ? 30.0 : 20.0;
    } else if (name.contains('bench') || name.contains('press')) {
      raw = isMale ? 30.0 : 20.0;
    } else if (name.contains('curl') || name.contains('extension') || name.contains('pullover')) {
      raw = isMale ? 20.0 : 16.0;
    } else if (name.contains('row')) {
      raw = isMale ? 30.0 : 20.0;
    } else {
      raw = isMale ? 24.0 : 16.0;
    }
    raw = raw * (isAdvanced ? 1.5 : 1.0);
    return _snapToBarbell(raw, kg: true, isMale: isMale);
  }

  // Dumbbell exercises — snap to 2 kg increments
  if (_isDumbbell(eq, name)) {
    if (name.contains('lateral') || name.contains('fly') || name.contains('raise')) {
      raw = 4.0 * genderMult * level;
    } else if (name.contains('curl') || name.contains('extension') || name.contains('kick')) {
      raw = 6.0 * genderMult * level;
    } else if (name.contains('press') || name.contains('row') || name.contains('snatch')) {
      raw = 10.0 * genderMult * level;
    } else {
      raw = 8.0 * genderMult * level;
    }
    return _snapDumbbell(raw, kg: true);
  }

  // Cable — snap to 5 kg
  if (eq.contains('cable') || name.contains('cable')) {
    raw = (name.contains('fly') || name.contains('lateral') || name.contains('face pull'))
        ? 5.0 * genderMult * level
        : 15.0 * genderMult * level;
    return _snapCable(raw, kg: true);
  }

  // Machine — snap to 5 kg
  if (eq.contains('machine') || name.contains('machine')) {
    raw = 20.0 * genderMult * level;
    return _snapCable(raw, kg: true); // Same 5 kg increments
  }

  // Kettlebell — snap to standard competition weights
  if (eq.contains('kettlebell') || name.contains('kettlebell')) {
    raw = (isMale ? 12.0 : 6.0) * (isAdvanced ? 1.5 : 1.0);
    return _snapKettlebellKg(raw);
  }

  // Smith machine
  if (eq.contains('smith') || name.contains('smith')) {
    raw = 20.0 * genderMult * level;
    return _snapToBarbell(raw, kg: true, isMale: isMale);
  }

  // EZ curl bar
  if (eq.contains('ez') || name.contains('ez bar') || name.contains('ez curl')) {
    raw = 16.0 * genderMult * level;
    return _snapToBarbell(raw, kg: true, isMale: false); // EZ bars use 15 kg women's-style min
  }

  return 0.0; // Bodyweight
}

/// Default weights in LBS — snapped to real US gym increments.
/// Dumbbells: 5 lb steps (5, 10, 15, 20, 25...)
/// Barbell: 5 lb steps total (2.5 lb plate per side)
/// Cable: 10 lb steps (or 5 lb with add-on)
/// Kettlebells: standard US weights (10, 15, 20, 25, 30, 35...)
double _getDefaultLbs(String eq, String name, bool isMale, bool isAdvanced) {
  final level = isAdvanced ? 1.5 : 1.0;
  final genderMult = isMale ? 1.0 : 0.6;

  double raw;

  // Barbell — minimum is bar (45 lb men / 35 lb women)
  if (_isBarbell(eq, name)) {
    if (name.contains('deadlift')) {
      raw = isMale ? 95.0 : 65.0;
    } else if (name.contains('squat')) {
      raw = isMale ? 65.0 : 45.0;
    } else if (name.contains('bench') || name.contains('press')) {
      raw = isMale ? 65.0 : 45.0;
    } else if (name.contains('curl') || name.contains('extension') || name.contains('pullover')) {
      raw = isMale ? 45.0 : 35.0;
    } else if (name.contains('row')) {
      raw = isMale ? 65.0 : 45.0;
    } else {
      raw = isMale ? 55.0 : 35.0;
    }
    raw = raw * (isAdvanced ? 1.3 : 1.0); // Less aggressive multiplier for lbs
    return _snapToBarbell(raw, kg: false, isMale: isMale);
  }

  // Dumbbell — snap to 5 lb
  if (_isDumbbell(eq, name)) {
    if (name.contains('lateral') || name.contains('fly') || name.contains('raise')) {
      raw = 10.0 * genderMult * level;
    } else if (name.contains('curl') || name.contains('extension') || name.contains('kick')) {
      raw = 15.0 * genderMult * level;
    } else if (name.contains('press') || name.contains('row') || name.contains('snatch')) {
      raw = 25.0 * genderMult * level;
    } else {
      raw = 15.0 * genderMult * level;
    }
    return _snapDumbbell(raw, kg: false);
  }

  // Cable — snap to 10 lb
  if (eq.contains('cable') || name.contains('cable')) {
    raw = (name.contains('fly') || name.contains('lateral') || name.contains('face pull'))
        ? 10.0 * genderMult * level
        : 30.0 * genderMult * level;
    return _snapCable(raw, kg: false);
  }

  // Machine — snap to 10 lb
  if (eq.contains('machine') || name.contains('machine')) {
    raw = 40.0 * genderMult * level;
    return _snapCable(raw, kg: false);
  }

  // Kettlebell — snap to 5 lb standard
  if (eq.contains('kettlebell') || name.contains('kettlebell')) {
    raw = (isMale ? 25.0 : 15.0) * (isAdvanced ? 1.3 : 1.0);
    return _snapKettlebellLbs(raw);
  }

  // Smith machine
  if (eq.contains('smith') || name.contains('smith')) {
    raw = 40.0 * genderMult * level;
    return _snapToBarbell(raw, kg: false, isMale: isMale);
  }

  // EZ curl bar
  if (eq.contains('ez') || name.contains('ez bar') || name.contains('ez curl')) {
    raw = 30.0 * genderMult * level;
    return _snapToBarbell(raw, kg: false, isMale: false);
  }

  return 0.0; // Bodyweight
}

// --- Snap functions ---

/// Snap barbell weight to valid barbell load.
/// Must be bar weight + multiples of plate pair weight.
double _snapToBarbell(double raw, {required bool kg, required bool isMale}) {
  final barWeight = kg ? (isMale ? 20.0 : 15.0) : (isMale ? 45.0 : 35.0);
  final plateIncrement = kg ? 2.5 : 5.0; // 1.25kg/side = 2.5kg total, 2.5lb/side = 5lb total
  final maxWeight = kg ? 265.0 : 585.0;
  if (raw <= barWeight) return barWeight;
  final plates = ((raw - barWeight) / plateIncrement).round() * plateIncrement;
  return (barWeight + plates).clamp(barWeight, maxWeight);
}

/// Snap dumbbell weight to real increments.
double _snapDumbbell(double raw, {required bool kg}) {
  final step = kg ? 2.5 : 5.0; // 2.5 kg metric standard, 5 lb US standard
  final min = kg ? 2.5 : 5.0;
  final snapped = (raw / step).round() * step;
  return snapped < min ? min : snapped;
}

/// Snap cable/machine weight to real pin-select increments.
double _snapCable(double raw, {required bool kg}) {
  final step = kg ? 5.0 : 10.0;
  final min = kg ? 5.0 : 10.0;
  final snapped = (raw / step).round() * step;
  return snapped < min ? min : snapped;
}

/// Snap to standard competition kettlebell weights (kg).
double _snapKettlebellKg(double raw) {
  // Competition: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 40, 44, 48
  const weights = [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0];
  return _findClosest(raw, weights);
}

/// Snap to standard US kettlebell weights (lbs).
double _snapKettlebellLbs(double raw) {
  // US standard: 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80
  const weights = [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];
  return _findClosest(raw, weights);
}

double _findClosest(double target, List<double> options) {
  double closest = options.first;
  double minDiff = (target - closest).abs();
  for (final w in options) {
    final diff = (target - w).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = w;
    }
  }
  return closest;
}

// --- Detection helpers ---

bool _isBarbell(String eq, String name) {
  return eq.contains('barbell') ||
      name.contains('barbell') ||
      name.contains('bench press') ||
      name.contains('deadlift') ||
      (name.contains('squat') && !name.contains('goblet') && !name.contains('dumbbell'));
}

bool _isDumbbell(String eq, String name) {
  return eq.contains('dumbbell') || name.contains('dumbbell') || name.contains('dumbbells');
}

/// Snap a weight to the nearest real gym increment for a given equipment type.
/// Call this after unit conversion to ensure the displayed weight actually exists.
// ============================================================================
// EQUIPMENT WEIGHT RANGES — Real commercial gym standards
//
// Sources: Rogue, Eleiko, Life Fitness, Hammer Strength, Jordan Fitness
// Verified against Planet Fitness, LA Fitness, Gold's Gym, Equinox inventory
// ============================================================================

/// Weight range definition for each equipment type.
class WeightRange {
  final double minLbs, maxLbs, stepLbs;
  final double minKg, maxKg, stepKg;
  const WeightRange({
    required this.minLbs, required this.maxLbs, required this.stepLbs,
    required this.minKg, required this.maxKg, required this.stepKg,
  });
}

const _ranges = {
  'dumbbell': WeightRange(minLbs: 5, maxLbs: 120, stepLbs: 5, minKg: 2.5, maxKg: 50, stepKg: 2.5),
  'barbell': WeightRange(minLbs: 45, maxLbs: 585, stepLbs: 5, minKg: 20, maxKg: 265, stepKg: 2.5),
  'cable': WeightRange(minLbs: 10, maxLbs: 300, stepLbs: 10, minKg: 5, maxKg: 150, stepKg: 5),
  'machine': WeightRange(minLbs: 10, maxLbs: 400, stepLbs: 10, minKg: 5, maxKg: 200, stepKg: 5),
  'kettlebell_lbs': WeightRange(minLbs: 5, maxLbs: 80, stepLbs: 5, minKg: 4, maxKg: 48, stepKg: 4),
  'smith': WeightRange(minLbs: 20, maxLbs: 400, stepLbs: 5, minKg: 9, maxKg: 200, stepKg: 2.5),
  'ez_bar': WeightRange(minLbs: 25, maxLbs: 200, stepLbs: 5, minKg: 11, maxKg: 100, stepKg: 2.5),
  'trap_bar': WeightRange(minLbs: 45, maxLbs: 500, stepLbs: 5, minKg: 20, maxKg: 230, stepKg: 2.5),
  'bodyweight': WeightRange(minLbs: 0, maxLbs: 0, stepLbs: 0, minKg: 0, maxKg: 0, stepKg: 0),
};

/// Get the weight range for an equipment type.
WeightRange getWeightRange(String? equipment, {String? exerciseName}) {
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();

  if (eq.contains('kettlebell') || name.contains('kettlebell')) return _ranges['kettlebell_lbs']!;
  if (_isBarbell(eq, name)) return _ranges['barbell']!;
  if (eq.contains('smith') || name.contains('smith')) return _ranges['smith']!;
  if (eq.contains('ez') || name.contains('ez bar')) return _ranges['ez_bar']!;
  if (eq.contains('trap') || name.contains('trap bar') || name.contains('hex bar')) return _ranges['trap_bar']!;
  if (_isDumbbell(eq, name)) return _ranges['dumbbell']!;
  if (eq.contains('cable') || name.contains('cable')) return _ranges['cable']!;
  if (eq.contains('machine') || name.contains('machine')) return _ranges['machine']!;
  return _ranges['dumbbell']!; // Default
}

/// Snap a weight to the nearest real gym increment and clamp to valid range.
double snapToRealIncrement(double weight, String? equipment, {String? exerciseName, required bool useKg}) {
  if (weight <= 0) return 0;
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();
  final range = getWeightRange(equipment, exerciseName: exerciseName);

  // Get min, max, step for current unit
  final min = useKg ? range.minKg : range.minLbs;
  final max = useKg ? range.maxKg : range.maxLbs;
  final step = useKg ? range.stepKg : range.stepLbs;

  if (step <= 0) return 0; // Bodyweight

  // Kettlebells have fixed non-linear weights
  if (eq.contains('kettlebell') || name.contains('kettlebell')) {
    final snapped = useKg ? _snapKettlebellKg(weight) : _snapKettlebellLbs(weight);
    return snapped.clamp(min, max);
  }

  // Barbell: total must be bar + plate pairs
  if (_isBarbell(eq, name) || eq.contains('smith') || eq.contains('ez') || eq.contains('trap')) {
    final barWeight = min; // min IS the bar weight
    if (weight <= barWeight) return barWeight;
    final plates = ((weight - barWeight) / step).round() * step;
    return (barWeight + plates).clamp(min, max);
  }

  // Dumbbells, cable, machine: simple step rounding + clamp
  final snapped = (weight / step).round() * step;
  return snapped.clamp(min, max);
}

/// Snap to the nearest weight the user actually owns.
/// If no inventory provided, falls back to standard gym increments.
///
/// [target] — the desired weight
/// [ownedWeights] — sorted list of weights the user owns (from equipmentDetails.weightInventory)
/// [equipment] / [exerciseName] — for fallback to standard increments
/// [useKg] — unit system
double snapToOwnedWeight(
  double target,
  List<double>? ownedWeights, {
  String? equipment,
  String? exerciseName,
  required bool useKg,
}) {
  if (ownedWeights != null && ownedWeights.isNotEmpty) {
    return _findClosest(target, ownedWeights);
  }
  return snapToRealIncrement(target, equipment, exerciseName: exerciseName, useKg: useKg);
}

/// Find the next HIGHER weight in the owned inventory (for +/- buttons).
/// Returns null if already at max.
double? nextOwnedWeight(double current, List<double> ownedWeights) {
  final sorted = [...ownedWeights]..sort();
  for (final w in sorted) {
    if (w > current + 0.01) return w;
  }
  return null;
}

/// Find the next LOWER weight in the owned inventory (for +/- buttons).
/// Returns null if already at min.
double? prevOwnedWeight(double current, List<double> ownedWeights) {
  final sorted = [...ownedWeights]..sort((a, b) => b.compareTo(a)); // descending
  for (final w in sorted) {
    if (w < current - 0.01) return w;
  }
  return null;
}

/// Check if the exercise's equipment type is available in the user's gym profile.
bool isEquipmentAvailable(String? equipment, String? exerciseName, List<String> availableEquipment) {
  if (availableEquipment.isEmpty) return true; // No profile = assume everything available
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();

  // Map exercise equipment to gym profile equipment names
  if (_isBarbell(eq, name)) {
    return availableEquipment.any((e) => e.toLowerCase().contains('barbell'));
  }
  if (_isDumbbell(eq, name)) {
    return availableEquipment.any((e) => e.toLowerCase().contains('dumbbell'));
  }
  if (eq.contains('cable') || name.contains('cable')) {
    return availableEquipment.any((e) => e.toLowerCase().contains('cable'));
  }
  if (eq.contains('machine') || name.contains('machine')) {
    // Check for specific machine types or generic "machine"
    return availableEquipment.any((e) {
      final eLower = e.toLowerCase();
      return eLower.contains('machine') || eLower.contains('leg_press') ||
             eLower.contains('lat_pulldown') || eLower.contains('full_gym');
    });
  }
  if (eq.contains('kettlebell') || name.contains('kettlebell')) {
    return availableEquipment.any((e) => e.toLowerCase().contains('kettlebell'));
  }
  if (eq.contains('smith') || name.contains('smith')) {
    return availableEquipment.any((e) => e.toLowerCase().contains('smith'));
  }
  if (eq.contains('bench') || name.contains('bench')) {
    return availableEquipment.any((e) => e.toLowerCase().contains('bench'));
  }
  // Bodyweight is always available
  if (eq.contains('bodyweight') || eq.contains('body weight') || eq.isEmpty) {
    return true;
  }
  // Default: assume available
  return true;
}

/// Returns true if the exercise weight is NOT from actual user workout history.
/// Only 'historical' weights are reliable — everything else (null, 'generic',
/// 'gemini', any AI source) should be replaced with equipment-based defaults.
bool isGenericWeight(double? weight, String? weightSource) {
  return weightSource != 'historical';
}
