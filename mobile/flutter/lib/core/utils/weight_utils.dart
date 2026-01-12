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
