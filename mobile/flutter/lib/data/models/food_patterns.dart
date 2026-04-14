import 'package:json_annotation/json_annotation.dart';

part 'food_patterns.g.dart';

/// One aggregated row from the mood/energy patterns RPC.
@JsonSerializable()
class FoodPatternEntry {
  @JsonKey(name: 'food_name')
  final String foodName;
  final int logs;
  @JsonKey(name: 'confirmed_count')
  final int confirmedCount;
  @JsonKey(name: 'inferred_count')
  final int inferredCount;
  @JsonKey(name: 'negative_mood_count')
  final int negativeMoodCount;
  @JsonKey(name: 'positive_mood_count')
  final int positiveMoodCount;
  @JsonKey(name: 'avg_energy')
  final double? avgEnergy;
  @JsonKey(name: 'low_energy_count', defaultValue: 0)
  final int lowEnergyCount;
  @JsonKey(name: 'high_energy_count', defaultValue: 0)
  final int highEnergyCount;
  @JsonKey(name: 'dominant_symptom')
  final String? dominantSymptom;
  @JsonKey(name: 'last_logged_at')
  final String? lastLoggedAt;
  @JsonKey(name: 'negative_score')
  final double negativeScore;
  @JsonKey(name: 'positive_score')
  final double positiveScore;

  const FoodPatternEntry({
    required this.foodName,
    required this.logs,
    required this.confirmedCount,
    required this.inferredCount,
    required this.negativeMoodCount,
    required this.positiveMoodCount,
    this.avgEnergy,
    this.lowEnergyCount = 0,
    this.highEnergyCount = 0,
    this.dominantSymptom,
    this.lastLoggedAt,
    required this.negativeScore,
    required this.positiveScore,
  });

  factory FoodPatternEntry.fromJson(Map<String, dynamic> json) =>
      _$FoodPatternEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FoodPatternEntryToJson(this);

  /// True when the row came mostly from passive inference and the user hasn't
  /// confirmed it — UI should show an "AI guess" pill.
  bool get isMostlyInferred => confirmedCount == 0 && inferredCount > 0;
}

@JsonSerializable()
class FoodPatternsMoodResponse {
  @JsonKey(name: 'energizing_foods', defaultValue: [])
  final List<FoodPatternEntry> energizingFoods;
  @JsonKey(name: 'draining_foods', defaultValue: [])
  final List<FoodPatternEntry> drainingFoods;
  @JsonKey(name: 'total_logs_analyzed', defaultValue: 0)
  final int totalLogsAnalyzed;
  @JsonKey(name: 'days_window', defaultValue: 90)
  final int daysWindow;
  @JsonKey(name: 'oldest_log_date')
  final String? oldestLogDate;
  @JsonKey(name: 'checkin_disabled', defaultValue: false)
  final bool checkinDisabled;
  @JsonKey(name: 'inference_enabled', defaultValue: true)
  final bool inferenceEnabled;

  const FoodPatternsMoodResponse({
    this.energizingFoods = const [],
    this.drainingFoods = const [],
    this.totalLogsAnalyzed = 0,
    this.daysWindow = 90,
    this.oldestLogDate,
    this.checkinDisabled = false,
    this.inferenceEnabled = true,
  });

  factory FoodPatternsMoodResponse.fromJson(Map<String, dynamic> json) =>
      _$FoodPatternsMoodResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FoodPatternsMoodResponseToJson(this);

  bool get isEmpty => energizingFoods.isEmpty && drainingFoods.isEmpty;
}

@JsonSerializable()
class TopFoodEntry {
  @JsonKey(name: 'food_name')
  final String foodName;
  @JsonKey(name: 'total_value')
  final double totalValue;
  final String unit;
  final int occurrences;
  @JsonKey(name: 'last_image_url')
  final String? lastImageUrl;
  @JsonKey(name: 'last_food_score')
  final int? lastFoodScore;
  @JsonKey(name: 'last_logged_at')
  final String? lastLoggedAt;

  const TopFoodEntry({
    required this.foodName,
    required this.totalValue,
    required this.unit,
    required this.occurrences,
    this.lastImageUrl,
    this.lastFoodScore,
    this.lastLoggedAt,
  });

  factory TopFoodEntry.fromJson(Map<String, dynamic> json) =>
      _$TopFoodEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TopFoodEntryToJson(this);
}

@JsonSerializable()
class TopFoodsResponse {
  final String metric;
  final String range;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(defaultValue: [])
  final List<TopFoodEntry> items;

  const TopFoodsResponse({
    required this.metric,
    required this.range,
    required this.startDate,
    required this.endDate,
    this.items = const [],
  });

  factory TopFoodsResponse.fromJson(Map<String, dynamic> json) =>
      _$TopFoodsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TopFoodsResponseToJson(this);
}

@JsonSerializable()
class DailyMacroPoint {
  final String date;
  @JsonKey(defaultValue: 0)
  final int calories;
  @JsonKey(name: 'protein_g', defaultValue: 0.0)
  final double proteinG;
  @JsonKey(name: 'carbs_g', defaultValue: 0.0)
  final double carbsG;
  @JsonKey(name: 'fat_g', defaultValue: 0.0)
  final double fatG;
  @JsonKey(name: 'fiber_g', defaultValue: 0.0)
  final double fiberG;

  const DailyMacroPoint({
    required this.date,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  factory DailyMacroPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyMacroPointFromJson(json);
  Map<String, dynamic> toJson() => _$DailyMacroPointToJson(this);
}

@JsonSerializable()
class MacrosSummaryResponse {
  final String range;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'days_counted', defaultValue: 0)
  final int daysCounted;
  @JsonKey(name: 'avg_calories', defaultValue: 0)
  final int avgCalories;
  @JsonKey(name: 'avg_protein_g', defaultValue: 0.0)
  final double avgProteinG;
  @JsonKey(name: 'avg_carbs_g', defaultValue: 0.0)
  final double avgCarbsG;
  @JsonKey(name: 'avg_fat_g', defaultValue: 0.0)
  final double avgFatG;
  @JsonKey(name: 'avg_fiber_g', defaultValue: 0.0)
  final double avgFiberG;
  @JsonKey(name: 'calorie_goal')
  final int? calorieGoal;
  @JsonKey(name: 'protein_goal')
  final int? proteinGoal;
  @JsonKey(name: 'carbs_goal')
  final int? carbsGoal;
  @JsonKey(name: 'fat_goal')
  final int? fatGoal;
  @JsonKey(name: 'fiber_goal')
  final int? fiberGoal;
  @JsonKey(name: 'daily_series', defaultValue: [])
  final List<DailyMacroPoint> dailySeries;

  const MacrosSummaryResponse({
    required this.range,
    required this.startDate,
    required this.endDate,
    this.daysCounted = 0,
    this.avgCalories = 0,
    this.avgProteinG = 0,
    this.avgCarbsG = 0,
    this.avgFatG = 0,
    this.avgFiberG = 0,
    this.calorieGoal,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
    this.fiberGoal,
    this.dailySeries = const [],
  });

  factory MacrosSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$MacrosSummaryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MacrosSummaryResponseToJson(this);
}

@JsonSerializable()
class PatternsSettings {
  @JsonKey(name: 'post_meal_checkin_disabled', defaultValue: false)
  final bool postMealCheckinDisabled;
  @JsonKey(name: 'post_meal_reminder_enabled', defaultValue: true)
  final bool postMealReminderEnabled;
  @JsonKey(name: 'passive_inference_enabled', defaultValue: true)
  final bool passiveInferenceEnabled;

  const PatternsSettings({
    this.postMealCheckinDisabled = false,
    this.postMealReminderEnabled = true,
    this.passiveInferenceEnabled = true,
  });

  factory PatternsSettings.fromJson(Map<String, dynamic> json) =>
      _$PatternsSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PatternsSettingsToJson(this);

  PatternsSettings copyWith({
    bool? postMealCheckinDisabled,
    bool? postMealReminderEnabled,
    bool? passiveInferenceEnabled,
  }) =>
      PatternsSettings(
        postMealCheckinDisabled:
            postMealCheckinDisabled ?? this.postMealCheckinDisabled,
        postMealReminderEnabled:
            postMealReminderEnabled ?? this.postMealReminderEnabled,
        passiveInferenceEnabled:
            passiveInferenceEnabled ?? this.passiveInferenceEnabled,
      );
}
