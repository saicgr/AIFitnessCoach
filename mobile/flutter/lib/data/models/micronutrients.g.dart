// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'micronutrients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MicronutrientData _$MicronutrientDataFromJson(Map<String, dynamic> json) =>
    MicronutrientData(
      vitaminAUg: (json['vitamin_a_ug'] as num?)?.toDouble(),
      vitaminCMg: (json['vitamin_c_mg'] as num?)?.toDouble(),
      vitaminDIu: (json['vitamin_d_iu'] as num?)?.toDouble(),
      vitaminEMg: (json['vitamin_e_mg'] as num?)?.toDouble(),
      vitaminKUg: (json['vitamin_k_ug'] as num?)?.toDouble(),
      vitaminB1Mg: (json['vitamin_b1_mg'] as num?)?.toDouble(),
      vitaminB2Mg: (json['vitamin_b2_mg'] as num?)?.toDouble(),
      vitaminB3Mg: (json['vitamin_b3_mg'] as num?)?.toDouble(),
      vitaminB5Mg: (json['vitamin_b5_mg'] as num?)?.toDouble(),
      vitaminB6Mg: (json['vitamin_b6_mg'] as num?)?.toDouble(),
      vitaminB7Ug: (json['vitamin_b7_ug'] as num?)?.toDouble(),
      vitaminB9Ug: (json['vitamin_b9_ug'] as num?)?.toDouble(),
      vitaminB12Ug: (json['vitamin_b12_ug'] as num?)?.toDouble(),
      cholineMg: (json['choline_mg'] as num?)?.toDouble(),
      calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
      ironMg: (json['iron_mg'] as num?)?.toDouble(),
      magnesiumMg: (json['magnesium_mg'] as num?)?.toDouble(),
      zincMg: (json['zinc_mg'] as num?)?.toDouble(),
      seleniumUg: (json['selenium_ug'] as num?)?.toDouble(),
      potassiumMg: (json['potassium_mg'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      phosphorusMg: (json['phosphorus_mg'] as num?)?.toDouble(),
      copperMg: (json['copper_mg'] as num?)?.toDouble(),
      manganeseMg: (json['manganese_mg'] as num?)?.toDouble(),
      iodineUg: (json['iodine_ug'] as num?)?.toDouble(),
      chromiumUg: (json['chromium_ug'] as num?)?.toDouble(),
      molybdenumUg: (json['molybdenum_ug'] as num?)?.toDouble(),
      omega3G: (json['omega3_g'] as num?)?.toDouble(),
      omega6G: (json['omega6_g'] as num?)?.toDouble(),
      saturatedFatG: (json['saturated_fat_g'] as num?)?.toDouble(),
      transFatG: (json['trans_fat_g'] as num?)?.toDouble(),
      monounsaturatedFatG: (json['monounsaturated_fat_g'] as num?)?.toDouble(),
      polyunsaturatedFatG: (json['polyunsaturated_fat_g'] as num?)?.toDouble(),
      cholesterolMg: (json['cholesterol_mg'] as num?)?.toDouble(),
      sugarG: (json['sugar_g'] as num?)?.toDouble(),
      addedSugarG: (json['added_sugar_g'] as num?)?.toDouble(),
      waterMl: (json['water_ml'] as num?)?.toDouble(),
      caffeineMg: (json['caffeine_mg'] as num?)?.toDouble(),
      alcoholG: (json['alcohol_g'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MicronutrientDataToJson(MicronutrientData instance) =>
    <String, dynamic>{
      'vitamin_a_ug': instance.vitaminAUg,
      'vitamin_c_mg': instance.vitaminCMg,
      'vitamin_d_iu': instance.vitaminDIu,
      'vitamin_e_mg': instance.vitaminEMg,
      'vitamin_k_ug': instance.vitaminKUg,
      'vitamin_b1_mg': instance.vitaminB1Mg,
      'vitamin_b2_mg': instance.vitaminB2Mg,
      'vitamin_b3_mg': instance.vitaminB3Mg,
      'vitamin_b5_mg': instance.vitaminB5Mg,
      'vitamin_b6_mg': instance.vitaminB6Mg,
      'vitamin_b7_ug': instance.vitaminB7Ug,
      'vitamin_b9_ug': instance.vitaminB9Ug,
      'vitamin_b12_ug': instance.vitaminB12Ug,
      'choline_mg': instance.cholineMg,
      'calcium_mg': instance.calciumMg,
      'iron_mg': instance.ironMg,
      'magnesium_mg': instance.magnesiumMg,
      'zinc_mg': instance.zincMg,
      'selenium_ug': instance.seleniumUg,
      'potassium_mg': instance.potassiumMg,
      'sodium_mg': instance.sodiumMg,
      'phosphorus_mg': instance.phosphorusMg,
      'copper_mg': instance.copperMg,
      'manganese_mg': instance.manganeseMg,
      'iodine_ug': instance.iodineUg,
      'chromium_ug': instance.chromiumUg,
      'molybdenum_ug': instance.molybdenumUg,
      'omega3_g': instance.omega3G,
      'omega6_g': instance.omega6G,
      'saturated_fat_g': instance.saturatedFatG,
      'trans_fat_g': instance.transFatG,
      'monounsaturated_fat_g': instance.monounsaturatedFatG,
      'polyunsaturated_fat_g': instance.polyunsaturatedFatG,
      'cholesterol_mg': instance.cholesterolMg,
      'sugar_g': instance.sugarG,
      'added_sugar_g': instance.addedSugarG,
      'water_ml': instance.waterMl,
      'caffeine_mg': instance.caffeineMg,
      'alcohol_g': instance.alcoholG,
    };

NutrientRDA _$NutrientRDAFromJson(Map<String, dynamic> json) => NutrientRDA(
  nutrientName: json['nutrient_name'] as String,
  nutrientKey: json['nutrient_key'] as String,
  unit: json['unit'] as String,
  category: json['category'] as String,
  rdaFloor: (json['rda_floor'] as num?)?.toDouble(),
  rdaTarget: (json['rda_target'] as num?)?.toDouble(),
  rdaCeiling: (json['rda_ceiling'] as num?)?.toDouble(),
  rdaTargetMale: (json['rda_target_male'] as num?)?.toDouble(),
  rdaTargetFemale: (json['rda_target_female'] as num?)?.toDouble(),
  displayName: json['display_name'] as String,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  colorHex: json['color_hex'] as String?,
);

Map<String, dynamic> _$NutrientRDAToJson(NutrientRDA instance) =>
    <String, dynamic>{
      'nutrient_name': instance.nutrientName,
      'nutrient_key': instance.nutrientKey,
      'unit': instance.unit,
      'category': instance.category,
      'rda_floor': instance.rdaFloor,
      'rda_target': instance.rdaTarget,
      'rda_ceiling': instance.rdaCeiling,
      'rda_target_male': instance.rdaTargetMale,
      'rda_target_female': instance.rdaTargetFemale,
      'display_name': instance.displayName,
      'display_order': instance.displayOrder,
      'color_hex': instance.colorHex,
    };

NutrientContributor _$NutrientContributorFromJson(Map<String, dynamic> json) =>
    NutrientContributor(
      foodLogId: json['food_log_id'] as String,
      foodName: json['food_name'] as String,
      mealType: json['meal_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );

Map<String, dynamic> _$NutrientContributorToJson(
  NutrientContributor instance,
) => <String, dynamic>{
  'food_log_id': instance.foodLogId,
  'food_name': instance.foodName,
  'meal_type': instance.mealType,
  'amount': instance.amount,
  'unit': instance.unit,
  'logged_at': instance.loggedAt.toIso8601String(),
};

NutrientProgress _$NutrientProgressFromJson(Map<String, dynamic> json) =>
    NutrientProgress(
      nutrientKey: json['nutrient_key'] as String,
      displayName: json['display_name'] as String,
      unit: json['unit'] as String,
      category: json['category'] as String,
      currentValue: (json['current_value'] as num).toDouble(),
      targetValue: (json['target_value'] as num).toDouble(),
      floorValue: (json['floor_value'] as num?)?.toDouble(),
      ceilingValue: (json['ceiling_value'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      status: json['status'] as String,
      colorHex: json['color_hex'] as String?,
      topContributors: (json['top_contributors'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$NutrientProgressToJson(NutrientProgress instance) =>
    <String, dynamic>{
      'nutrient_key': instance.nutrientKey,
      'display_name': instance.displayName,
      'unit': instance.unit,
      'category': instance.category,
      'current_value': instance.currentValue,
      'target_value': instance.targetValue,
      'floor_value': instance.floorValue,
      'ceiling_value': instance.ceilingValue,
      'percentage': instance.percentage,
      'status': instance.status,
      'color_hex': instance.colorHex,
      'top_contributors': instance.topContributors,
    };

DailyMicronutrientSummary _$DailyMicronutrientSummaryFromJson(
  Map<String, dynamic> json,
) => DailyMicronutrientSummary(
  date: json['date'] as String,
  userId: json['user_id'] as String,
  vitamins:
      (json['vitamins'] as List<dynamic>?)
          ?.map((e) => NutrientProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minerals:
      (json['minerals'] as List<dynamic>?)
          ?.map((e) => NutrientProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  fattyAcids:
      (json['fatty_acids'] as List<dynamic>?)
          ?.map((e) => NutrientProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  other:
      (json['other'] as List<dynamic>?)
          ?.map((e) => NutrientProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pinned:
      (json['pinned'] as List<dynamic>?)
          ?.map((e) => NutrientProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DailyMicronutrientSummaryToJson(
  DailyMicronutrientSummary instance,
) => <String, dynamic>{
  'date': instance.date,
  'user_id': instance.userId,
  'vitamins': instance.vitamins,
  'minerals': instance.minerals,
  'fatty_acids': instance.fattyAcids,
  'other': instance.other,
  'pinned': instance.pinned,
};

NutrientContributorsResponse _$NutrientContributorsResponseFromJson(
  Map<String, dynamic> json,
) => NutrientContributorsResponse(
  nutrientKey: json['nutrient_key'] as String,
  displayName: json['display_name'] as String,
  unit: json['unit'] as String,
  totalIntake: (json['total_intake'] as num).toDouble(),
  target: (json['target'] as num).toDouble(),
  contributors:
      (json['contributors'] as List<dynamic>?)
          ?.map((e) => NutrientContributor.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$NutrientContributorsResponseToJson(
  NutrientContributorsResponse instance,
) => <String, dynamic>{
  'nutrient_key': instance.nutrientKey,
  'display_name': instance.displayName,
  'unit': instance.unit,
  'total_intake': instance.totalIntake,
  'target': instance.target,
  'contributors': instance.contributors,
};

PinnedNutrientsUpdate _$PinnedNutrientsUpdateFromJson(
  Map<String, dynamic> json,
) => PinnedNutrientsUpdate(
  pinnedNutrients: (json['pinned_nutrients'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PinnedNutrientsUpdateToJson(
  PinnedNutrientsUpdate instance,
) => <String, dynamic>{'pinned_nutrients': instance.pinnedNutrients};
