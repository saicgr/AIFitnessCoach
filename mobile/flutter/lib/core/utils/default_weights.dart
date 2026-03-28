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
}) {
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();
  final isMale = gender?.toLowerCase() != 'female';
  final isAdvanced = fitnessLevel?.toLowerCase() == 'intermediate' ||
      fitnessLevel?.toLowerCase() == 'advanced';

  if (useKg) {
    return _getDefaultKg(eq, name, isMale, isAdvanced);
  } else {
    return _getDefaultLbs(eq, name, isMale, isAdvanced);
  }
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
  final plateIncrement = kg ? 2.0 : 5.0; // 1kg/side = 2kg total, 2.5lb/side = 5lb total
  if (raw <= barWeight) return barWeight;
  final plates = ((raw - barWeight) / plateIncrement).round() * plateIncrement;
  return barWeight + plates;
}

/// Snap dumbbell weight to real increments.
double _snapDumbbell(double raw, {required bool kg}) {
  final step = kg ? 2.0 : 5.0;
  final min = kg ? 2.0 : 5.0;
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
double snapToRealIncrement(double weight, String? equipment, {String? exerciseName, required bool useKg}) {
  if (weight <= 0) return 0;
  final eq = (equipment ?? '').toLowerCase();
  final name = (exerciseName ?? '').toLowerCase();

  // Kettlebells have fixed non-linear weights
  if (eq.contains('kettlebell') || name.contains('kettlebell')) {
    return useKg ? _snapKettlebellKg(weight) : _snapKettlebellLbs(weight);
  }

  // Barbell: total must be bar + plate pairs
  if (_isBarbell(eq, name)) {
    final barWeight = useKg ? 20.0 : 45.0;
    if (weight <= barWeight) return barWeight;
    final plateStep = useKg ? 2.0 : 5.0; // 1kg/side = 2kg total, 2.5lb/side = 5lb total
    final plates = ((weight - barWeight) / plateStep).round() * plateStep;
    return barWeight + plates;
  }

  // Dumbbells: 2 kg or 5 lb steps
  if (_isDumbbell(eq, name)) {
    final step = useKg ? 2.0 : 5.0;
    return (weight / step).round() * step;
  }

  // Cable/machine: 5 kg or 10 lb steps
  if (eq.contains('cable') || name.contains('cable') || eq.contains('machine') || name.contains('machine')) {
    final step = useKg ? 5.0 : 10.0;
    return (weight / step).round() * step;
  }

  // Default: round to nearest 2.5 kg or 5 lb
  final step = useKg ? 2.5 : 5.0;
  return (weight / step).round() * step;
}

/// Returns true if the exercise weight is NOT from actual user workout history.
/// Only 'historical' weights are reliable — everything else (null, 'generic',
/// 'gemini', any AI source) should be replaced with equipment-based defaults.
bool isGenericWeight(double? weight, String? weightSource) {
  return weightSource != 'historical';
}
