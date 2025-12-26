import 'package:json_annotation/json_annotation.dart';

part 'micronutrients.g.dart';

/// Category of nutrient
enum NutrientCategory {
  vitamin('vitamin'),
  mineral('mineral'),
  fattyAcid('fatty_acid'),
  other('other');

  final String value;
  const NutrientCategory(this.value);

  static NutrientCategory fromValue(String value) {
    return NutrientCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NutrientCategory.other,
    );
  }
}

/// Status of nutrient intake relative to targets
enum NutrientStatus {
  low('low'),
  optimal('optimal'),
  high('high'),
  overCeiling('over_ceiling');

  final String value;
  const NutrientStatus(this.value);

  static NutrientStatus fromValue(String value) {
    return NutrientStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NutrientStatus.optimal,
    );
  }

  /// Get color for status
  String get colorHex {
    switch (this) {
      case NutrientStatus.low:
        return '#FFC107'; // Yellow
      case NutrientStatus.optimal:
        return '#4CAF50'; // Green
      case NutrientStatus.high:
        return '#FF9800'; // Orange
      case NutrientStatus.overCeiling:
        return '#F44336'; // Red
    }
  }
}

/// Comprehensive micronutrient data for a food/meal
@JsonSerializable()
class MicronutrientData {
  // Vitamins
  @JsonKey(name: 'vitamin_a_ug')
  final double? vitaminAUg;
  @JsonKey(name: 'vitamin_c_mg')
  final double? vitaminCMg;
  @JsonKey(name: 'vitamin_d_iu')
  final double? vitaminDIu;
  @JsonKey(name: 'vitamin_e_mg')
  final double? vitaminEMg;
  @JsonKey(name: 'vitamin_k_ug')
  final double? vitaminKUg;
  @JsonKey(name: 'vitamin_b1_mg')
  final double? vitaminB1Mg; // Thiamine
  @JsonKey(name: 'vitamin_b2_mg')
  final double? vitaminB2Mg; // Riboflavin
  @JsonKey(name: 'vitamin_b3_mg')
  final double? vitaminB3Mg; // Niacin
  @JsonKey(name: 'vitamin_b5_mg')
  final double? vitaminB5Mg; // Pantothenic Acid
  @JsonKey(name: 'vitamin_b6_mg')
  final double? vitaminB6Mg;
  @JsonKey(name: 'vitamin_b7_ug')
  final double? vitaminB7Ug; // Biotin
  @JsonKey(name: 'vitamin_b9_ug')
  final double? vitaminB9Ug; // Folate
  @JsonKey(name: 'vitamin_b12_ug')
  final double? vitaminB12Ug;
  @JsonKey(name: 'choline_mg')
  final double? cholineMg;

  // Minerals
  @JsonKey(name: 'calcium_mg')
  final double? calciumMg;
  @JsonKey(name: 'iron_mg')
  final double? ironMg;
  @JsonKey(name: 'magnesium_mg')
  final double? magnesiumMg;
  @JsonKey(name: 'zinc_mg')
  final double? zincMg;
  @JsonKey(name: 'selenium_ug')
  final double? seleniumUg;
  @JsonKey(name: 'potassium_mg')
  final double? potassiumMg;
  @JsonKey(name: 'sodium_mg')
  final double? sodiumMg;
  @JsonKey(name: 'phosphorus_mg')
  final double? phosphorusMg;
  @JsonKey(name: 'copper_mg')
  final double? copperMg;
  @JsonKey(name: 'manganese_mg')
  final double? manganeseMg;
  @JsonKey(name: 'iodine_ug')
  final double? iodineUg;
  @JsonKey(name: 'chromium_ug')
  final double? chromiumUg;
  @JsonKey(name: 'molybdenum_ug')
  final double? molybdenumUg;

  // Fatty Acids
  @JsonKey(name: 'omega3_g')
  final double? omega3G;
  @JsonKey(name: 'omega6_g')
  final double? omega6G;
  @JsonKey(name: 'saturated_fat_g')
  final double? saturatedFatG;
  @JsonKey(name: 'trans_fat_g')
  final double? transFatG;
  @JsonKey(name: 'monounsaturated_fat_g')
  final double? monounsaturatedFatG;
  @JsonKey(name: 'polyunsaturated_fat_g')
  final double? polyunsaturatedFatG;

  // Other
  @JsonKey(name: 'cholesterol_mg')
  final double? cholesterolMg;
  @JsonKey(name: 'sugar_g')
  final double? sugarG;
  @JsonKey(name: 'added_sugar_g')
  final double? addedSugarG;
  @JsonKey(name: 'water_ml')
  final double? waterMl;
  @JsonKey(name: 'caffeine_mg')
  final double? caffeineMg;
  @JsonKey(name: 'alcohol_g')
  final double? alcoholG;

  const MicronutrientData({
    this.vitaminAUg,
    this.vitaminCMg,
    this.vitaminDIu,
    this.vitaminEMg,
    this.vitaminKUg,
    this.vitaminB1Mg,
    this.vitaminB2Mg,
    this.vitaminB3Mg,
    this.vitaminB5Mg,
    this.vitaminB6Mg,
    this.vitaminB7Ug,
    this.vitaminB9Ug,
    this.vitaminB12Ug,
    this.cholineMg,
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.zincMg,
    this.seleniumUg,
    this.potassiumMg,
    this.sodiumMg,
    this.phosphorusMg,
    this.copperMg,
    this.manganeseMg,
    this.iodineUg,
    this.chromiumUg,
    this.molybdenumUg,
    this.omega3G,
    this.omega6G,
    this.saturatedFatG,
    this.transFatG,
    this.monounsaturatedFatG,
    this.polyunsaturatedFatG,
    this.cholesterolMg,
    this.sugarG,
    this.addedSugarG,
    this.waterMl,
    this.caffeineMg,
    this.alcoholG,
  });

  factory MicronutrientData.fromJson(Map<String, dynamic> json) =>
      _$MicronutrientDataFromJson(json);
  Map<String, dynamic> toJson() => _$MicronutrientDataToJson(this);

  /// Create empty micronutrient data
  factory MicronutrientData.empty() => const MicronutrientData();

  /// Add two micronutrient data sets together
  MicronutrientData operator +(MicronutrientData other) {
    return MicronutrientData(
      vitaminAUg: _addNullable(vitaminAUg, other.vitaminAUg),
      vitaminCMg: _addNullable(vitaminCMg, other.vitaminCMg),
      vitaminDIu: _addNullable(vitaminDIu, other.vitaminDIu),
      vitaminEMg: _addNullable(vitaminEMg, other.vitaminEMg),
      vitaminKUg: _addNullable(vitaminKUg, other.vitaminKUg),
      vitaminB1Mg: _addNullable(vitaminB1Mg, other.vitaminB1Mg),
      vitaminB2Mg: _addNullable(vitaminB2Mg, other.vitaminB2Mg),
      vitaminB3Mg: _addNullable(vitaminB3Mg, other.vitaminB3Mg),
      vitaminB5Mg: _addNullable(vitaminB5Mg, other.vitaminB5Mg),
      vitaminB6Mg: _addNullable(vitaminB6Mg, other.vitaminB6Mg),
      vitaminB7Ug: _addNullable(vitaminB7Ug, other.vitaminB7Ug),
      vitaminB9Ug: _addNullable(vitaminB9Ug, other.vitaminB9Ug),
      vitaminB12Ug: _addNullable(vitaminB12Ug, other.vitaminB12Ug),
      cholineMg: _addNullable(cholineMg, other.cholineMg),
      calciumMg: _addNullable(calciumMg, other.calciumMg),
      ironMg: _addNullable(ironMg, other.ironMg),
      magnesiumMg: _addNullable(magnesiumMg, other.magnesiumMg),
      zincMg: _addNullable(zincMg, other.zincMg),
      seleniumUg: _addNullable(seleniumUg, other.seleniumUg),
      potassiumMg: _addNullable(potassiumMg, other.potassiumMg),
      sodiumMg: _addNullable(sodiumMg, other.sodiumMg),
      phosphorusMg: _addNullable(phosphorusMg, other.phosphorusMg),
      copperMg: _addNullable(copperMg, other.copperMg),
      manganeseMg: _addNullable(manganeseMg, other.manganeseMg),
      iodineUg: _addNullable(iodineUg, other.iodineUg),
      chromiumUg: _addNullable(chromiumUg, other.chromiumUg),
      molybdenumUg: _addNullable(molybdenumUg, other.molybdenumUg),
      omega3G: _addNullable(omega3G, other.omega3G),
      omega6G: _addNullable(omega6G, other.omega6G),
      saturatedFatG: _addNullable(saturatedFatG, other.saturatedFatG),
      transFatG: _addNullable(transFatG, other.transFatG),
      monounsaturatedFatG:
          _addNullable(monounsaturatedFatG, other.monounsaturatedFatG),
      polyunsaturatedFatG:
          _addNullable(polyunsaturatedFatG, other.polyunsaturatedFatG),
      cholesterolMg: _addNullable(cholesterolMg, other.cholesterolMg),
      sugarG: _addNullable(sugarG, other.sugarG),
      addedSugarG: _addNullable(addedSugarG, other.addedSugarG),
      waterMl: _addNullable(waterMl, other.waterMl),
      caffeineMg: _addNullable(caffeineMg, other.caffeineMg),
      alcoholG: _addNullable(alcoholG, other.alcoholG),
    );
  }

  static double? _addNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }
}

/// Reference Daily Allowance for a nutrient
@JsonSerializable()
class NutrientRDA {
  @JsonKey(name: 'nutrient_name')
  final String nutrientName;
  @JsonKey(name: 'nutrient_key')
  final String nutrientKey;
  final String unit;
  final String category;
  @JsonKey(name: 'rda_floor')
  final double? rdaFloor;
  @JsonKey(name: 'rda_target')
  final double? rdaTarget;
  @JsonKey(name: 'rda_ceiling')
  final double? rdaCeiling;
  @JsonKey(name: 'rda_target_male')
  final double? rdaTargetMale;
  @JsonKey(name: 'rda_target_female')
  final double? rdaTargetFemale;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'color_hex')
  final String? colorHex;

  const NutrientRDA({
    required this.nutrientName,
    required this.nutrientKey,
    required this.unit,
    required this.category,
    this.rdaFloor,
    this.rdaTarget,
    this.rdaCeiling,
    this.rdaTargetMale,
    this.rdaTargetFemale,
    required this.displayName,
    this.displayOrder = 0,
    this.colorHex,
  });

  factory NutrientRDA.fromJson(Map<String, dynamic> json) =>
      _$NutrientRDAFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientRDAToJson(this);

  /// Get category as enum
  NutrientCategory get categoryEnum => NutrientCategory.fromValue(category);

  /// Get default color based on category
  String get defaultColor {
    switch (categoryEnum) {
      case NutrientCategory.vitamin:
        return '#FF9F43'; // Orange
      case NutrientCategory.mineral:
        return '#00D9C0'; // Teal
      case NutrientCategory.fattyAcid:
        return '#4D96FF'; // Blue
      case NutrientCategory.other:
        return '#9B59B6'; // Purple
    }
  }
}

/// Contributor to a nutrient (food that provided the nutrient)
@JsonSerializable()
class NutrientContributor {
  @JsonKey(name: 'food_log_id')
  final String foodLogId;
  @JsonKey(name: 'food_name')
  final String foodName;
  @JsonKey(name: 'meal_type')
  final String mealType;
  final double amount;
  final String unit;
  @JsonKey(name: 'logged_at')
  final DateTime loggedAt;

  const NutrientContributor({
    required this.foodLogId,
    required this.foodName,
    required this.mealType,
    required this.amount,
    required this.unit,
    required this.loggedAt,
  });

  factory NutrientContributor.fromJson(Map<String, dynamic> json) =>
      _$NutrientContributorFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientContributorToJson(this);
}

/// Progress towards a nutrient target
@JsonSerializable()
class NutrientProgress {
  @JsonKey(name: 'nutrient_key')
  final String nutrientKey;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String unit;
  final String category;
  @JsonKey(name: 'current_value')
  final double currentValue;
  @JsonKey(name: 'target_value')
  final double targetValue;
  @JsonKey(name: 'floor_value')
  final double? floorValue;
  @JsonKey(name: 'ceiling_value')
  final double? ceilingValue;
  final double percentage;
  final String status;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'top_contributors')
  final List<Map<String, dynamic>>? topContributors;

  const NutrientProgress({
    required this.nutrientKey,
    required this.displayName,
    required this.unit,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    this.floorValue,
    this.ceilingValue,
    required this.percentage,
    required this.status,
    this.colorHex,
    this.topContributors,
  });

  factory NutrientProgress.fromJson(Map<String, dynamic> json) =>
      _$NutrientProgressFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientProgressToJson(this);

  /// Get status as enum
  NutrientStatus get statusEnum => NutrientStatus.fromValue(status);

  /// Get category as enum
  NutrientCategory get categoryEnum => NutrientCategory.fromValue(category);

  /// Get color for the progress bar
  String get progressColor => colorHex ?? statusEnum.colorHex;

  /// Whether this is at floor level
  bool get isAtFloor =>
      floorValue != null && currentValue >= floorValue! && currentValue < targetValue;

  /// Whether this is at target level (optimal)
  bool get isAtTarget {
    if (ceilingValue != null) {
      return currentValue >= targetValue && currentValue <= ceilingValue!;
    }
    return currentValue >= targetValue;
  }

  /// Whether this is over ceiling
  bool get isOverCeiling =>
      ceilingValue != null && currentValue > ceilingValue!;

  /// Get formatted current value
  String get formattedCurrent {
    if (currentValue >= 1000) {
      return '${(currentValue / 1000).toStringAsFixed(1)}k';
    }
    if (currentValue < 1) {
      return currentValue.toStringAsFixed(2);
    }
    return currentValue.toStringAsFixed(1);
  }

  /// Get formatted target value
  String get formattedTarget {
    if (targetValue >= 1000) {
      return '${(targetValue / 1000).toStringAsFixed(1)}k';
    }
    return targetValue.toStringAsFixed(0);
  }
}

/// Daily summary of all micronutrients
@JsonSerializable()
class DailyMicronutrientSummary {
  final String date;
  @JsonKey(name: 'user_id')
  final String userId;
  final List<NutrientProgress> vitamins;
  final List<NutrientProgress> minerals;
  @JsonKey(name: 'fatty_acids')
  final List<NutrientProgress> fattyAcids;
  final List<NutrientProgress> other;
  final List<NutrientProgress> pinned;

  const DailyMicronutrientSummary({
    required this.date,
    required this.userId,
    this.vitamins = const [],
    this.minerals = const [],
    this.fattyAcids = const [],
    this.other = const [],
    this.pinned = const [],
  });

  factory DailyMicronutrientSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyMicronutrientSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMicronutrientSummaryToJson(this);

  /// Get all nutrients combined
  List<NutrientProgress> get allNutrients =>
      [...vitamins, ...minerals, ...fattyAcids, ...other];

  /// Get nutrients below floor
  List<NutrientProgress> get lowNutrients =>
      allNutrients.where((n) => n.statusEnum == NutrientStatus.low).toList();

  /// Get nutrients at optimal level
  List<NutrientProgress> get optimalNutrients =>
      allNutrients.where((n) => n.statusEnum == NutrientStatus.optimal).toList();

  /// Get nutrients over ceiling
  List<NutrientProgress> get overNutrients => allNutrients
      .where((n) =>
          n.statusEnum == NutrientStatus.high ||
          n.statusEnum == NutrientStatus.overCeiling)
      .toList();

  /// Get overall micronutrient score (percentage of nutrients at optimal)
  double get overallScore {
    if (allNutrients.isEmpty) return 0;
    final optimal = optimalNutrients.length;
    return (optimal / allNutrients.length) * 100;
  }
}

/// Response for nutrient contributors
@JsonSerializable()
class NutrientContributorsResponse {
  @JsonKey(name: 'nutrient_key')
  final String nutrientKey;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String unit;
  @JsonKey(name: 'total_intake')
  final double totalIntake;
  final double target;
  final List<NutrientContributor> contributors;

  const NutrientContributorsResponse({
    required this.nutrientKey,
    required this.displayName,
    required this.unit,
    required this.totalIntake,
    required this.target,
    this.contributors = const [],
  });

  factory NutrientContributorsResponse.fromJson(Map<String, dynamic> json) =>
      _$NutrientContributorsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientContributorsResponseToJson(this);

  /// Get percentage of target achieved
  double get percentage => target > 0 ? (totalIntake / target) * 100 : 0;
}

/// Request to update pinned nutrients
@JsonSerializable()
class PinnedNutrientsUpdate {
  @JsonKey(name: 'pinned_nutrients')
  final List<String> pinnedNutrients;

  const PinnedNutrientsUpdate({
    required this.pinnedNutrients,
  });

  factory PinnedNutrientsUpdate.fromJson(Map<String, dynamic> json) =>
      _$PinnedNutrientsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$PinnedNutrientsUpdateToJson(this);
}

/// Default pinned nutrients for new users
const List<String> defaultPinnedNutrients = [
  'vitamin_d_iu',
  'calcium_mg',
  'iron_mg',
  'omega3_g',
];

/// All available nutrient keys for pinning
const Map<String, String> allNutrientKeys = {
  // Vitamins
  'vitamin_a_ug': 'Vitamin A',
  'vitamin_c_mg': 'Vitamin C',
  'vitamin_d_iu': 'Vitamin D',
  'vitamin_e_mg': 'Vitamin E',
  'vitamin_k_ug': 'Vitamin K',
  'vitamin_b1_mg': 'Thiamine (B1)',
  'vitamin_b2_mg': 'Riboflavin (B2)',
  'vitamin_b3_mg': 'Niacin (B3)',
  'vitamin_b6_mg': 'Vitamin B6',
  'vitamin_b9_ug': 'Folate (B9)',
  'vitamin_b12_ug': 'Vitamin B12',
  'choline_mg': 'Choline',
  // Minerals
  'calcium_mg': 'Calcium',
  'iron_mg': 'Iron',
  'magnesium_mg': 'Magnesium',
  'zinc_mg': 'Zinc',
  'selenium_ug': 'Selenium',
  'potassium_mg': 'Potassium',
  'sodium_mg': 'Sodium',
  'phosphorus_mg': 'Phosphorus',
  'copper_mg': 'Copper',
  'manganese_mg': 'Manganese',
  'iodine_ug': 'Iodine',
  // Fatty Acids & Other
  'omega3_g': 'Omega-3',
  'omega6_g': 'Omega-6',
  'fiber_g': 'Fiber',
  'cholesterol_mg': 'Cholesterol',
  'water_ml': 'Water',
  'sugar_g': 'Sugar',
  'caffeine_mg': 'Caffeine',
};
