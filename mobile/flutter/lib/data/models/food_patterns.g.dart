// GENERATED CODE - hand-written to match project convention (build_runner disabled).

part of 'food_patterns.dart';

// ────────────── FoodPatternEntry ──────────────
FoodPatternEntry _$FoodPatternEntryFromJson(Map<String, dynamic> json) =>
    FoodPatternEntry(
      foodName: json['food_name'] as String? ?? '',
      logs: (json['logs'] as num?)?.toInt() ??
          (json['logs_with_checkin'] as num?)?.toInt() ??
          0,
      confirmedCount: (json['confirmed_count'] as num?)?.toInt() ?? 0,
      inferredCount: (json['inferred_count'] as num?)?.toInt() ?? 0,
      negativeMoodCount: (json['negative_mood_count'] as num?)?.toInt() ?? 0,
      positiveMoodCount: (json['positive_mood_count'] as num?)?.toInt() ?? 0,
      avgEnergy: (json['avg_energy'] as num?)?.toDouble(),
      lowEnergyCount: (json['low_energy_count'] as num?)?.toInt() ?? 0,
      highEnergyCount: (json['high_energy_count'] as num?)?.toInt() ?? 0,
      dominantSymptom: json['dominant_symptom'] as String?,
      lastLoggedAt: json['last_logged_at'] as String?,
      negativeScore: (json['negative_score'] as num?)?.toDouble() ?? 0,
      positiveScore: (json['positive_score'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$FoodPatternEntryToJson(FoodPatternEntry instance) =>
    <String, dynamic>{
      'food_name': instance.foodName,
      'logs': instance.logs,
      'confirmed_count': instance.confirmedCount,
      'inferred_count': instance.inferredCount,
      'negative_mood_count': instance.negativeMoodCount,
      'positive_mood_count': instance.positiveMoodCount,
      'avg_energy': instance.avgEnergy,
      'low_energy_count': instance.lowEnergyCount,
      'high_energy_count': instance.highEnergyCount,
      'dominant_symptom': instance.dominantSymptom,
      'last_logged_at': instance.lastLoggedAt,
      'negative_score': instance.negativeScore,
      'positive_score': instance.positiveScore,
    };

// ────────────── FoodPatternsMoodResponse ──────────────
FoodPatternsMoodResponse _$FoodPatternsMoodResponseFromJson(
  Map<String, dynamic> json,
) => FoodPatternsMoodResponse(
  energizingFoods: (json['energizing_foods'] as List<dynamic>?)
          ?.map((e) => FoodPatternEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  drainingFoods: (json['draining_foods'] as List<dynamic>?)
          ?.map((e) => FoodPatternEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalLogsAnalyzed: (json['total_logs_analyzed'] as num?)?.toInt() ?? 0,
  daysWindow: (json['days_window'] as num?)?.toInt() ?? 90,
  oldestLogDate: json['oldest_log_date'] as String?,
  checkinDisabled: json['checkin_disabled'] as bool? ?? false,
  inferenceEnabled: json['inference_enabled'] as bool? ?? true,
);

Map<String, dynamic> _$FoodPatternsMoodResponseToJson(
  FoodPatternsMoodResponse instance,
) => <String, dynamic>{
  'energizing_foods': instance.energizingFoods.map((e) => e.toJson()).toList(),
  'draining_foods': instance.drainingFoods.map((e) => e.toJson()).toList(),
  'total_logs_analyzed': instance.totalLogsAnalyzed,
  'days_window': instance.daysWindow,
  'oldest_log_date': instance.oldestLogDate,
  'checkin_disabled': instance.checkinDisabled,
  'inference_enabled': instance.inferenceEnabled,
};

// ────────────── TopFoodEntry ──────────────
TopFoodEntry _$TopFoodEntryFromJson(Map<String, dynamic> json) => TopFoodEntry(
      foodName: json['food_name'] as String? ?? '',
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      occurrences: (json['occurrences'] as num?)?.toInt() ?? 0,
      lastImageUrl: json['last_image_url'] as String?,
      lastFoodScore: (json['last_food_score'] as num?)?.toInt(),
      lastLoggedAt: json['last_logged_at'] as String?,
    );

Map<String, dynamic> _$TopFoodEntryToJson(TopFoodEntry instance) =>
    <String, dynamic>{
      'food_name': instance.foodName,
      'total_value': instance.totalValue,
      'unit': instance.unit,
      'occurrences': instance.occurrences,
      'last_image_url': instance.lastImageUrl,
      'last_food_score': instance.lastFoodScore,
      'last_logged_at': instance.lastLoggedAt,
    };

// ────────────── TopFoodsResponse ──────────────
TopFoodsResponse _$TopFoodsResponseFromJson(Map<String, dynamic> json) =>
    TopFoodsResponse(
      metric: json['metric'] as String? ?? 'calories',
      range: json['range'] as String? ?? 'week',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TopFoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TopFoodsResponseToJson(TopFoodsResponse instance) =>
    <String, dynamic>{
      'metric': instance.metric,
      'range': instance.range,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

// ────────────── DailyMacroPoint ──────────────
DailyMacroPoint _$DailyMacroPointFromJson(Map<String, dynamic> json) =>
    DailyMacroPoint(
      date: json['date'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$DailyMacroPointToJson(DailyMacroPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'calories': instance.calories,
      'protein_g': instance.proteinG,
      'carbs_g': instance.carbsG,
      'fat_g': instance.fatG,
      'fiber_g': instance.fiberG,
    };

// ────────────── MacrosSummaryResponse ──────────────
MacrosSummaryResponse _$MacrosSummaryResponseFromJson(
  Map<String, dynamic> json,
) => MacrosSummaryResponse(
  range: json['range'] as String? ?? 'week',
  startDate: json['start_date'] as String? ?? '',
  endDate: json['end_date'] as String? ?? '',
  daysCounted: (json['days_counted'] as num?)?.toInt() ?? 0,
  avgCalories: (json['avg_calories'] as num?)?.toInt() ?? 0,
  avgProteinG: (json['avg_protein_g'] as num?)?.toDouble() ?? 0,
  avgCarbsG: (json['avg_carbs_g'] as num?)?.toDouble() ?? 0,
  avgFatG: (json['avg_fat_g'] as num?)?.toDouble() ?? 0,
  avgFiberG: (json['avg_fiber_g'] as num?)?.toDouble() ?? 0,
  calorieGoal: (json['calorie_goal'] as num?)?.toInt(),
  proteinGoal: (json['protein_goal'] as num?)?.toInt(),
  carbsGoal: (json['carbs_goal'] as num?)?.toInt(),
  fatGoal: (json['fat_goal'] as num?)?.toInt(),
  fiberGoal: (json['fiber_goal'] as num?)?.toInt(),
  dailySeries: (json['daily_series'] as List<dynamic>?)
          ?.map((e) => DailyMacroPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MacrosSummaryResponseToJson(
  MacrosSummaryResponse instance,
) => <String, dynamic>{
  'range': instance.range,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'days_counted': instance.daysCounted,
  'avg_calories': instance.avgCalories,
  'avg_protein_g': instance.avgProteinG,
  'avg_carbs_g': instance.avgCarbsG,
  'avg_fat_g': instance.avgFatG,
  'avg_fiber_g': instance.avgFiberG,
  'calorie_goal': instance.calorieGoal,
  'protein_goal': instance.proteinGoal,
  'carbs_goal': instance.carbsGoal,
  'fat_goal': instance.fatGoal,
  'fiber_goal': instance.fiberGoal,
  'daily_series': instance.dailySeries.map((e) => e.toJson()).toList(),
};

// ────────────── PatternsSettings ──────────────
PatternsSettings _$PatternsSettingsFromJson(Map<String, dynamic> json) =>
    PatternsSettings(
      postMealCheckinDisabled:
          json['post_meal_checkin_disabled'] as bool? ?? false,
      postMealReminderEnabled:
          json['post_meal_reminder_enabled'] as bool? ?? true,
      passiveInferenceEnabled:
          json['passive_inference_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$PatternsSettingsToJson(PatternsSettings instance) =>
    <String, dynamic>{
      'post_meal_checkin_disabled': instance.postMealCheckinDisabled,
      'post_meal_reminder_enabled': instance.postMealReminderEnabled,
      'passive_inference_enabled': instance.passiveInferenceEnabled,
    };
