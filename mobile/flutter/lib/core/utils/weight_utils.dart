/// Utility class for weight unit conversions and formatting.
///
/// Provides centralized weight conversion between metric (kg) and imperial (lbs)
/// units, ensuring consistent handling throughout the app.
class WeightUtils {
  WeightUtils._(); // Private constructor - use static methods only

  /// Conversion factor: 1 kg = 2.20462 lbs
  static const double kgToLbsFactor = 2.20462;

  /// Conversion factor: 1 lb = 0.453592 kg
  static const double lbsToKgFactor = 0.453592;

  // ============================================================
  // CONVERSION METHODS
  // ============================================================

  /// Convert kilograms to pounds
  static double kgToLbs(double kg) => kg * kgToLbsFactor;

  /// Convert pounds to kilograms
  static double lbsToKg(double lbs) => lbs * lbsToKgFactor;

  /// Convert weight to kg if needed (for storage/API calls)
  /// All backend storage is in kg
  static double toKg(double weight, {required bool isCurrentlyLbs}) {
    return isCurrentlyLbs ? lbsToKg(weight) : weight;
  }

  /// Convert weight from kg to display unit
  static double fromKg(double weightKg, {required bool displayInLbs}) {
    return displayInLbs ? kgToLbs(weightKg) : weightKg;
  }

  // ============================================================
  // FORMATTING METHODS
  // ============================================================

  /// Format weight for display with unit suffix
  ///
  /// [weight] - The weight value (already in display units)
  /// [useKg] - Whether to display as kg (true) or lbs (false)
  /// [showDecimal] - Whether to show decimal places for whole numbers
  static String formatWeight(
    double weight, {
    required bool useKg,
    bool showDecimal = false,
  }) {
    final unit = useKg ? 'kg' : 'lbs';
    if (!showDecimal && weight == weight.roundToDouble()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(1)} $unit';
  }

  /// Format weight for display without unit suffix
  ///
  /// Useful for input fields where unit is shown separately
  static String formatWeightValue(double weight, {bool showDecimal = false}) {
    if (!showDecimal && weight == weight.roundToDouble()) {
      return '${weight.toInt()}';
    }
    return weight.toStringAsFixed(1);
  }

  /// Format weight from kg with automatic conversion for display
  ///
  /// [weightKg] - Weight in kilograms (from database)
  /// [useKg] - User's preferred unit setting
  static String formatWeightFromKg(double weightKg, {required bool useKg}) {
    final displayWeight = fromKg(weightKg, displayInLbs: !useKg);
    return formatWeight(displayWeight, useKg: useKg);
  }

  /// Get the unit label ('kg' or 'lbs')
  static String getUnitLabel(bool useKg) => useKg ? 'kg' : 'lbs';

  // ============================================================
  // ROUNDING METHODS
  // ============================================================

  /// Round weight to nearest 0.5 (common for gym weights)
  static double roundToHalf(double weight) {
    return (weight * 2).round() / 2;
  }

  /// Round weight to nearest 2.5 (common for plates in kg)
  static double roundToQuarter(double weight) {
    return (weight / 2.5).round() * 2.5;
  }

  /// Round weight to nearest 5 (common for plates in lbs)
  static double roundToFive(double weight) {
    return (weight / 5).round() * 5;
  }

  /// Smart rounding based on unit (2.5 for kg, 5 for lbs)
  static double smartRound(double weight, {required bool useKg}) {
    return useKg ? roundToQuarter(weight) : roundToFive(weight);
  }

  /// Whether a kg value is a "clean" gym weight (multiple of 2.5 kg).
  ///
  /// Clean values come from AI/backend (e.g., 25.0, 60.0, 100.0 kg).
  /// Non-clean values are round-tripped user entries (e.g., 62.14 kg from 137 lbs).
  /// We only apply gym-standard snapping to clean values; user entries are preserved.
  static bool isCleanKg(double weightKg) {
    return (weightKg % 2.5).abs() < 0.01 || ((weightKg % 2.5) - 2.5).abs() < 0.01;
  }

  /// Convert from kg to display unit, preserving user-entered values.
  ///
  /// For AI-generated clean kg values (multiples of 2.5): uses gym-standard lookup.
  /// For user-entered round-tripped values: rounds to nearest 0.5 to preserve original.
  static double fromKgSnapped(double weightKg,
      {required bool displayInLbs, double? increment}) {
    if (weightKg <= 0) return 0;
    if (!displayInLbs) {
      return isCleanKg(weightKg) ? roundToQuarter(weightKg) : weightKg;
    }
    final rawLbs = kgToLbs(weightKg);
    if (!isCleanKg(weightKg)) {
      // User-entered round-trip: preserve their value (round to nearest 0.5)
      return (rawLbs * 2).round() / 2;
    }
    // AI-generated clean kg: use gym-standard lookup
    if (increment == null) {
      return kgToLbsGym(weightKg);
    }
    if (increment <= 0) return rawLbs;
    return (rawLbs / increment).round() * increment;
  }

  // ============================================================
  // GYM-STANDARD LOOKUP (kg → lbs)
  // ============================================================

  /// Gym-standard kg→lbs lookup. Unlike raw math (×2.205), returns the lbs
  /// value gym-goers recognize: 60 kg → 135 lbs, 100 kg → 225 lbs.
  /// Sources: Rogue, Eleiko, Rep Fitness plate catalogs.
  static final Map<double, double> _kgToLbsGym = {
    // Micro plates / fractional
    0.5: 1,    1.0: 2.5,  1.25: 2.5, 1.5: 3,
    2.0: 5,    2.5: 5,    3.0: 5,    3.5: 8,
    4.0: 10,   4.5: 10,   5.0: 10,   5.5: 12,
    6.0: 15,   6.5: 15,   7.0: 15,   7.5: 15,
    8.0: 20,   8.5: 20,   9.0: 20,   9.5: 20,
    // Dumbbell / plate range
    10.0: 20,  10.5: 25,  11.0: 25,  11.5: 25,
    12.0: 25,  12.5: 25,  13.0: 30,  13.5: 30,
    14.0: 30,  14.5: 30,  15.0: 35,  15.5: 35,
    16.0: 35,  16.5: 35,  17.0: 35,  17.5: 40,
    18.0: 40,  18.5: 40,  19.0: 40,  19.5: 45,
    20.0: 45,  20.5: 45,  21.0: 45,  21.5: 45,
    22.0: 50,  22.5: 50,  23.0: 50,  23.5: 50,
    24.0: 55,  24.5: 55,  25.0: 55,  25.5: 55,
    26.0: 55,  26.5: 60,  27.0: 60,  27.5: 60,
    28.0: 60,  28.5: 65,  29.0: 65,  29.5: 65,
    30.0: 65,  30.5: 65,  31.0: 70,  31.5: 70,
    32.0: 70,  32.5: 70,  33.0: 75,  33.5: 75,
    34.0: 75,  34.5: 75,  35.0: 75,  35.5: 80,
    36.0: 80,  36.5: 80,  37.0: 80,  37.5: 85,
    38.0: 85,  38.5: 85,  39.0: 85,  39.5: 90,
    40.0: 90,  40.5: 90,  41.0: 90,  41.5: 90,
    42.0: 95,  42.5: 95,  43.0: 95,  43.5: 95,
    44.0: 95,  44.5: 100, 45.0: 100, 45.5: 100,
    46.0: 100, 46.5: 105, 47.0: 105, 47.5: 105,
    48.0: 105, 48.5: 110, 49.0: 110, 49.5: 110,
    50.0: 110,
    // Barbell landmark totals
    55.0: 120, 60.0: 135, 65.0: 145, 70.0: 155,
    75.0: 165, 80.0: 175, 85.0: 185, 90.0: 200,
    95.0: 210, 100.0: 225, 105.0: 230, 110.0: 245,
    115.0: 255, 120.0: 265, 125.0: 275, 130.0: 285,
    135.0: 295, 140.0: 315, 145.0: 315, 150.0: 335,
    155.0: 340, 160.0: 355, 165.0: 365, 170.0: 375,
    175.0: 385, 180.0: 405, 185.0: 405, 190.0: 420,
    195.0: 430, 200.0: 445, 210.0: 465, 220.0: 495,
    230.0: 515, 240.0: 530, 250.0: 555, 260.0: 585,
  };

  /// Convert kg to gym-standard lbs using the researched lookup.
  static double kgToLbsGym(double weightKg) {
    if (weightKg <= 0) return 0;
    // Round to nearest 0.5 kg for lookup
    final key = (weightKg * 2).round() / 2;
    if (_kgToLbsGym.containsKey(key)) return _kgToLbsGym[key]!;
    // Find nearest key
    final keys = _kgToLbsGym.keys.toList()..sort();
    if (key <= keys.first) return _kgToLbsGym[keys.first]!;
    if (key >= keys.last) return roundToFive(kgToLbs(weightKg));
    // Binary search for nearest
    int lo = 0, hi = keys.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (keys[mid] <= key) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (key - keys[lo]).abs() <= (key - keys[hi]).abs()
        ? _kgToLbsGym[keys[lo]]!
        : _kgToLbsGym[keys[hi]]!;
  }

  // ============================================================
  // VALIDATION METHODS
  // ============================================================

  /// Check if weight is valid (positive and within reasonable range)
  static bool isValidWeight(double? weight) {
    if (weight == null) return false;
    return weight > 0 && weight <= 1000; // Max 1000kg or ~2200lbs
  }

  /// Get minimum weight increment based on unit
  static double getMinIncrement(bool useKg) => useKg ? 0.5 : 1.0;

  /// Get recommended weight increment for progression
  static double getProgressionIncrement(bool useKg) => useKg ? 2.5 : 5.0;

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  /// Common gym weights in kg
  static const List<double> commonWeightsKg = [
    1.25, 2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20,
    22.5, 25, 27.5, 30, 32.5, 35, 37.5, 40,
    42.5, 45, 47.5, 50, 55, 60, 70, 80, 90, 100,
  ];

  /// Common gym weights in lbs
  static const List<double> commonWeightsLbs = [
    2.5, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50,
    55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
    105, 110, 115, 120, 135, 155, 175, 185, 225,
  ];

  /// Get list of common weights based on unit preference
  static List<double> getCommonWeights(bool useKg) {
    return useKg ? commonWeightsKg : commonWeightsLbs;
  }
}
