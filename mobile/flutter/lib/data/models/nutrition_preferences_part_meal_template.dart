part of 'nutrition_preferences.dart';

@JsonSerializable()
class MealTemplate {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String name;
  @JsonKey(name: 'meal_type')
  final String mealType;
  @JsonKey(name: 'food_items')
  final List<TemplateFoodItem> foodItems;
  @JsonKey(name: 'total_calories')
  final int? totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double? totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double? totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double? totalFatG;
  @JsonKey(name: 'is_system_template')
  final bool isSystemTemplate;
  @JsonKey(name: 'use_count')
  final int useCount;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  final String? description;
  final List<String>? tags;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  const MealTemplate({
    this.id,
    this.userId,
    required this.name,
    required this.mealType,
    this.foodItems = const [],
    this.totalCalories,
    this.totalProteinG,
    this.totalCarbsG,
    this.totalFatG,
    this.isSystemTemplate = false,
    this.useCount = 0,
    this.lastUsedAt,
    this.createdAt,
    this.description,
    this.tags,
    this.imageUrl,
  });

  factory MealTemplate.fromJson(Map<String, dynamic> json) =>
      _$MealTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$MealTemplateToJson(this);

  MealTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? mealType,
    List<TemplateFoodItem>? foodItems,
    int? totalCalories,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    bool? isSystemTemplate,
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    String? description,
    List<String>? tags,
    String? imageUrl,
  }) {
    return MealTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      foodItems: foodItems ?? this.foodItems,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Calculate total calories from food items if not set
  int get calculatedCalories =>
      totalCalories ??
      foodItems.fold(0, (sum, item) => sum + item.calories);

  /// Calculate total protein from food items if not set
  double get calculatedProtein =>
      totalProteinG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.proteinG ?? 0));

  /// Calculate total carbs from food items if not set
  double get calculatedCarbs =>
      totalCarbsG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.carbsG ?? 0));

  /// Calculate total fat from food items if not set
  double get calculatedFat =>
      totalFatG ??
      foodItems.fold(0.0, (sum, item) => sum + (item.fatG ?? 0));

  /// Check if this is a user-created template
  bool get isUserTemplate => !isSystemTemplate;

  /// Get display name with meal type emoji
  String get displayName {
    final emoji = _mealTypeEmoji;
    return '$emoji $name';
  }

  String get _mealTypeEmoji {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}

@JsonSerializable()
class QuickSuggestion {
  @JsonKey(name: 'food_name')
  final String foodName;
  @JsonKey(name: 'meal_type')
  final String mealType;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'log_count')
  final int logCount;
  @JsonKey(name: 'time_of_day_bucket')
  final String? timeOfDayBucket;
  @JsonKey(name: 'saved_food_id')
  final String? savedFoodId;
  @JsonKey(name: 'template_id')
  final String? templateId;
  @JsonKey(name: 'last_logged_at')
  final DateTime? lastLoggedAt;
  @JsonKey(name: 'avg_servings')
  final double? avgServings;
  final String? description;

  const QuickSuggestion({
    required this.foodName,
    required this.mealType,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.logCount = 0,
    this.timeOfDayBucket,
    this.savedFoodId,
    this.templateId,
    this.lastLoggedAt,
    this.avgServings,
    this.description,
  });

  factory QuickSuggestion.fromJson(Map<String, dynamic> json) =>
      _$QuickSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuickSuggestionToJson(this);

  /// Check if this is a frequently logged item
  bool get isFrequent => logCount >= 3;

  /// Check if this is a recent item
  bool get isRecent {
    if (lastLoggedAt == null) return false;
    final daysSinceLog = DateTime.now().difference(lastLoggedAt!).inDays;
    return daysSinceLog <= 7;
  }

  /// Get relevance score for sorting (higher = more relevant)
  double get relevanceScore {
    double score = 0;

    // Frequency bonus
    score += logCount.clamp(0, 10) * 2;

    // Recency bonus
    if (lastLoggedAt != null) {
      final daysSinceLog = DateTime.now().difference(lastLoggedAt!).inDays;
      if (daysSinceLog <= 1) {
        score += 20;
      } else if (daysSinceLog <= 3) {
        score += 15;
      } else if (daysSinceLog <= 7) {
        score += 10;
      } else if (daysSinceLog <= 14) {
        score += 5;
      }
    }

    // Time of day match bonus
    final currentBucket = _getCurrentTimeOfDayBucket();
    if (timeOfDayBucket == currentBucket) {
      score += 15;
    }

    return score;
  }

  static String _getCurrentTimeOfDayBucket() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 15) return 'midday';
    if (hour >= 15 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  /// Get display subtitle
  String get subtitle {
    final parts = <String>[];
    parts.add('$calories cal');
    if (proteinG != null) parts.add('${proteinG!.round()}g protein');
    return parts.join(' | ');
  }

  /// Check if this suggestion is from a template
  bool get isFromTemplate => templateId != null;

  /// Check if this suggestion is from a saved food
  bool get isFromSavedFood => savedFoodId != null;
}

@JsonSerializable()
class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  @JsonKey(name: 'serving_size')
  final String? servingSize;
  @JsonKey(name: 'serving_unit')
  final String? servingUnit;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double? proteinG;
  @JsonKey(name: 'carbs_g')
  final double? carbsG;
  @JsonKey(name: 'fat_g')
  final double? fatG;
  @JsonKey(name: 'fiber_g')
  final double? fiberG;
  final String? barcode;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'source_type')
  final String? sourceType;
  @JsonKey(name: 'is_verified')
  final bool isVerified;

  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.servingSize,
    this.servingUnit,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.barcode,
    this.imageUrl,
    this.sourceType,
    this.isVerified = false,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) =>
      _$FoodSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$FoodSearchResultToJson(this);

  /// Get display name with brand if available
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$name ($brand)';
    }
    return name;
  }

  /// Get serving info string
  String get servingInfo {
    if (servingSize != null && servingUnit != null) {
      return '$servingSize $servingUnit';
    }
    if (servingSize != null) return servingSize!;
    return '1 serving';
  }

  /// Get macro summary string
  String get macroSummary {
    final parts = <String>[];
    if (proteinG != null) parts.add('P: ${proteinG!.round()}g');
    if (carbsG != null) parts.add('C: ${carbsG!.round()}g');
    if (fatG != null) parts.add('F: ${fatG!.round()}g');
    return parts.join(' | ');
  }
}


// ============================================
// MacroFactor-Style Adaptive TDEE Models
// ============================================

/// Detailed TDEE calculation with confidence intervals
/// Based on EMA-smoothed weight trends and energy balance
class DetailedTDEE {
  final int tdee;
  final int confidenceLow;
  final int confidenceHigh;
  final int uncertaintyCalories;
  final double dataQualityScore;
  final String confidenceLevel;
  final WeightTrendInfo weightTrend;
  final MetabolicAdaptationInfo? metabolicAdaptation;

  const DetailedTDEE({
    required this.tdee,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.uncertaintyCalories,
    required this.dataQualityScore,
    required this.confidenceLevel,
    required this.weightTrend,
    this.metabolicAdaptation,
  });

  /// Get uncertainty display string (e.g., "±120 cal")
  String get uncertaintyDisplay => '±$uncertaintyCalories cal';

  /// Get TDEE range display (e.g., "2,030 - 2,270")
  String get rangeDisplay =>
      '${_formatNumber(confidenceLow)} - ${_formatNumber(confidenceHigh)}';

  /// Check if we have enough data for reliable estimates
  bool get hasReliableData => dataQualityScore >= 0.6;

  /// Check if metabolic adaptation was detected
  bool get hasAdaptation => metabolicAdaptation != null;

  static String _formatNumber(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  factory DetailedTDEE.fromJson(Map<String, dynamic> json) {
    return DetailedTDEE(
      tdee: json['tdee'] as int? ?? 0,
      confidenceLow: json['confidence_low'] as int? ?? 0,
      confidenceHigh: json['confidence_high'] as int? ?? 0,
      uncertaintyCalories: json['uncertainty_calories'] as int? ?? 0,
      dataQualityScore: (json['data_quality_score'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidence_level'] as String? ?? 'low',
      weightTrend: WeightTrendInfo.fromJson(
          json['weight_trend'] as Map<String, dynamic>? ?? {}),
      metabolicAdaptation: json['metabolic_adaptation'] != null
          ? MetabolicAdaptationInfo.fromJson(
              json['metabolic_adaptation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tdee': tdee,
        'confidence_low': confidenceLow,
        'confidence_high': confidenceHigh,
        'uncertainty_calories': uncertaintyCalories,
        'data_quality_score': dataQualityScore,
        'confidence_level': confidenceLevel,
        'weight_trend': weightTrend.toJson(),
        if (metabolicAdaptation != null)
          'metabolic_adaptation': metabolicAdaptation!.toJson(),
      };
}


/// Weight trend information from EMA smoothing
class WeightTrendInfo {
  final double changeKg;
  final double weeklyRate;
  final String direction;
  final double? startWeight;
  final double? endWeight;

  const WeightTrendInfo({
    required this.changeKg,
    required this.weeklyRate,
    required this.direction,
    this.startWeight,
    this.endWeight,
  });

  /// Get formatted weekly rate (e.g., "-0.45 kg/week")
  String get formattedWeeklyRate {
    if (weeklyRate.abs() < 0.05) return 'Stable';
    final sign = weeklyRate > 0 ? '+' : '';
    return '$sign${weeklyRate.toStringAsFixed(2)} kg/week';
  }

  /// Get direction emoji
  String get directionEmoji {
    switch (direction) {
      case 'losing':
        return '📉';
      case 'gaining':
        return '📈';
      default:
        return '➡️';
    }
  }

  factory WeightTrendInfo.fromJson(Map<String, dynamic> json) {
    return WeightTrendInfo(
      changeKg: (json['change_kg'] as num?)?.toDouble() ?? 0.0,
      weeklyRate: (json['weekly_rate_kg'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] as String? ?? 'stable',
      startWeight: (json['start_weight'] as num?)?.toDouble(),
      endWeight: (json['end_weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'change_kg': changeKg,
        'weekly_rate': weeklyRate,
        'direction': direction,
        if (startWeight != null) 'start_weight': startWeight,
        if (endWeight != null) 'end_weight': endWeight,
      };
}


/// Metabolic adaptation event information
class MetabolicAdaptationInfo {
  final String eventType;
  final String severity;
  final int? plateauWeeks;
  final double? expectedWeightChangeKg;
  final double? actualWeightChangeKg;
  final int? previousTdee;
  final int? currentTdee;
  final double? tdeeDropPercent;
  final int? tdeeDropCalories;
  final String suggestedAction;
  final String actionDescription;

  const MetabolicAdaptationInfo({
    required this.eventType,
    required this.severity,
    this.plateauWeeks,
    this.expectedWeightChangeKg,
    this.actualWeightChangeKg,
    this.previousTdee,
    this.currentTdee,
    this.tdeeDropPercent,
    this.tdeeDropCalories,
    required this.suggestedAction,
    required this.actionDescription,
  });

  /// Check if this is a plateau event
  bool get isPlateau => eventType == 'plateau';

  /// Check if this is a metabolic adaptation event
  bool get isAdaptation => eventType == 'adaptation';

  /// Get severity color
  String get severityColor {
    switch (severity) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      default:
        return 'yellow';
    }
  }

  /// Get action display name
  String get actionDisplayName {
    switch (suggestedAction) {
      case 'diet_break':
        return 'Diet Break';
      case 'refeed':
        return 'Refeed Days';
      case 'increase_activity':
        return 'Increase Activity';
      case 'reduce_deficit':
        return 'Reduce Deficit';
      default:
        return 'Be Patient';
    }
  }

  factory MetabolicAdaptationInfo.fromJson(Map<String, dynamic> json) {
    return MetabolicAdaptationInfo(
      eventType: json['event_type'] as String? ?? 'unknown',
      severity: json['severity'] as String? ?? 'low',
      plateauWeeks: json['plateau_weeks'] as int?,
      expectedWeightChangeKg:
          (json['expected_weight_change_kg'] as num?)?.toDouble(),
      actualWeightChangeKg:
          (json['actual_weight_change_kg'] as num?)?.toDouble(),
      previousTdee: json['previous_tdee'] as int?,
      currentTdee: json['current_tdee'] as int?,
      tdeeDropPercent: (json['tdee_drop_percent'] as num?)?.toDouble(),
      tdeeDropCalories: json['tdee_drop_calories'] as int?,
      suggestedAction: json['suggested_action'] as String? ?? 'patience',
      actionDescription: json['action_description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'event_type': eventType,
        'severity': severity,
        if (plateauWeeks != null) 'plateau_weeks': plateauWeeks,
        if (expectedWeightChangeKg != null)
          'expected_weight_change_kg': expectedWeightChangeKg,
        if (actualWeightChangeKg != null)
          'actual_weight_change_kg': actualWeightChangeKg,
        if (previousTdee != null) 'previous_tdee': previousTdee,
        if (currentTdee != null) 'current_tdee': currentTdee,
        if (tdeeDropPercent != null) 'tdee_drop_percent': tdeeDropPercent,
        if (tdeeDropCalories != null) 'tdee_drop_calories': tdeeDropCalories,
        'suggested_action': suggestedAction,
        'action_description': actionDescription,
      };
}


// ============================================
// Adherence Tracking Models
// ============================================

/// Daily adherence metrics
class DailyAdherence {
  final DateTime date;
  final double calorieAdherencePct;
  final double proteinAdherencePct;
  final double carbsAdherencePct;
  final double fatAdherencePct;
  final double overallAdherencePct;
  final bool caloriesOver;
  final bool proteinOver;

  const DailyAdherence({
    required this.date,
    required this.calorieAdherencePct,
    required this.proteinAdherencePct,
    required this.carbsAdherencePct,
    required this.fatAdherencePct,
    required this.overallAdherencePct,
    this.caloriesOver = false,
    this.proteinOver = false,
  });

  /// Check if meeting calorie target (>95%)
  bool get onTargetCalories => calorieAdherencePct >= 95;

  /// Check if meeting protein target (>95%)
  bool get onTargetProtein => proteinAdherencePct >= 95;

  factory DailyAdherence.fromJson(Map<String, dynamic> json) {
    return DailyAdherence(
      date: DateTime.parse(json['date'] as String),
      calorieAdherencePct:
          (json['calorie_adherence_pct'] as num?)?.toDouble() ?? 0.0,
      proteinAdherencePct:
          (json['protein_adherence_pct'] as num?)?.toDouble() ?? 0.0,
      carbsAdherencePct:
          (json['carbs_adherence_pct'] as num?)?.toDouble() ?? 0.0,
      fatAdherencePct: (json['fat_adherence_pct'] as num?)?.toDouble() ?? 0.0,
      overallAdherencePct:
          (json['overall_adherence_pct'] as num?)?.toDouble() ?? 0.0,
      caloriesOver: json['calories_over'] as bool? ?? false,
      proteinOver: json['protein_over'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'calorie_adherence_pct': calorieAdherencePct,
        'protein_adherence_pct': proteinAdherencePct,
        'carbs_adherence_pct': carbsAdherencePct,
        'fat_adherence_pct': fatAdherencePct,
        'overall_adherence_pct': overallAdherencePct,
        'calories_over': caloriesOver,
        'protein_over': proteinOver,
      };
}


/// Adherence summary with sustainability score
class AdherenceSummary {
  final List<WeeklyAdherenceData> weeklyAdherence;
  final double averageAdherence;
  final double sustainabilityScore;
  final String sustainabilityRating;
  final String recommendation;
  final int weeksAnalyzed;
  final double consistencyScore;
  final double loggingScore;

  const AdherenceSummary({
    required this.weeklyAdherence,
    required this.averageAdherence,
    required this.sustainabilityScore,
    required this.sustainabilityRating,
    required this.recommendation,
    required this.weeksAnalyzed,
    required this.consistencyScore,
    required this.loggingScore,
  });

  /// Check if sustainability is high
  bool get isHighSustainability => sustainabilityRating == 'high';

  /// Check if sustainability is low
  bool get isLowSustainability => sustainabilityRating == 'low';

  /// Get rating color
  String get ratingColor {
    switch (sustainabilityRating) {
      case 'high':
        return 'green';
      case 'medium':
        return 'orange';
      default:
        return 'red';
    }
  }

  /// Get rating emoji
  String get ratingEmoji {
    switch (sustainabilityRating) {
      case 'high':
        return '🟢';
      case 'medium':
        return '🟡';
      default:
        return '🔴';
    }
  }

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    final weeklyList = (json['weekly_adherence'] as List?)
            ?.map((w) => WeeklyAdherenceData.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [];

    return AdherenceSummary(
      weeklyAdherence: weeklyList,
      averageAdherence: (json['average_adherence'] as num?)?.toDouble() ?? 0.0,
      sustainabilityScore:
          (json['sustainability_score'] as num?)?.toDouble() ?? 0.0,
      sustainabilityRating:
          json['sustainability_rating'] as String? ?? 'medium',
      recommendation: json['recommendation'] as String? ?? '',
      weeksAnalyzed: json['weeks_analyzed'] as int? ?? 0,
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0.0,
      loggingScore: (json['logging_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekly_adherence': weeklyAdherence.map((w) => w.toJson()).toList(),
        'average_adherence': averageAdherence,
        'sustainability_score': sustainabilityScore,
        'sustainability_rating': sustainabilityRating,
        'recommendation': recommendation,
        'weeks_analyzed': weeksAnalyzed,
        'consistency_score': consistencyScore,
        'logging_score': loggingScore,
      };
}


/// Weekly adherence data
class WeeklyAdherenceData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int daysLogged;
  final int daysInWeek;
  final double avgCalorieAdherence;
  final double avgProteinAdherence;
  final double avgCarbsAdherence;
  final double avgFatAdherence;
  final double avgOverallAdherence;
  final double adherenceVariance;
  final int daysOnTargetCalories;
  final int daysOnTargetProtein;

  const WeeklyAdherenceData({
    required this.weekStart,
    required this.weekEnd,
    required this.daysLogged,
    this.daysInWeek = 7,
    required this.avgCalorieAdherence,
    required this.avgProteinAdherence,
    required this.avgCarbsAdherence,
    required this.avgFatAdherence,
    required this.avgOverallAdherence,
    required this.adherenceVariance,
    required this.daysOnTargetCalories,
    required this.daysOnTargetProtein,
  });

  /// Get logging rate as percentage
  double get loggingRatePct => (daysLogged / daysInWeek) * 100;

  factory WeeklyAdherenceData.fromJson(Map<String, dynamic> json) {
    return WeeklyAdherenceData(
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      daysLogged: json['days_logged'] as int? ?? 0,
      daysInWeek: json['days_in_week'] as int? ?? 7,
      avgCalorieAdherence:
          (json['avg_calorie_adherence'] as num?)?.toDouble() ?? 0.0,
      avgProteinAdherence:
          (json['avg_protein_adherence'] as num?)?.toDouble() ?? 0.0,
      avgCarbsAdherence:
          (json['avg_carbs_adherence'] as num?)?.toDouble() ?? 0.0,
      avgFatAdherence: (json['avg_fat_adherence'] as num?)?.toDouble() ?? 0.0,
      avgOverallAdherence:
          (json['avg_overall_adherence'] as num?)?.toDouble() ?? 0.0,
      adherenceVariance:
          (json['adherence_variance'] as num?)?.toDouble() ?? 0.0,
      daysOnTargetCalories: json['days_on_target_calories'] as int? ?? 0,
      daysOnTargetProtein: json['days_on_target_protein'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'week_start': weekStart.toIso8601String().split('T').first,
        'week_end': weekEnd.toIso8601String().split('T').first,
        'days_logged': daysLogged,
        'days_in_week': daysInWeek,
        'avg_calorie_adherence': avgCalorieAdherence,
        'avg_protein_adherence': avgProteinAdherence,
        'avg_carbs_adherence': avgCarbsAdherence,
        'avg_fat_adherence': avgFatAdherence,
        'avg_overall_adherence': avgOverallAdherence,
        'adherence_variance': adherenceVariance,
        'days_on_target_calories': daysOnTargetCalories,
        'days_on_target_protein': daysOnTargetProtein,
      };
}


// ============================================
// Multi-Option Recommendation Models
// ============================================

/// A single recommendation option (aggressive, moderate, conservative)
class RecommendationOption {
  final String optionType;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final double expectedWeeklyChangeKg;
  final String sustainabilityRating;
  final String description;

  const RecommendationOption({
    required this.optionType,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.expectedWeeklyChangeKg,
    required this.sustainabilityRating,
    required this.description,
  });

  /// Get option display name
  String get displayName {
    switch (optionType) {
      case 'aggressive':
        return 'Aggressive';
      case 'moderate':
        return 'Moderate';
      case 'conservative':
        return 'Conservative';
      case 'maintenance':
        return 'Maintenance';
      default:
        return optionType;
    }
  }

  /// Get option emoji
  String get emoji {
    switch (optionType) {
      case 'aggressive':
        return '🔥';
      case 'moderate':
        return '⚖️';
      case 'conservative':
        return '🐢';
      case 'maintenance':
        return '➡️';
      default:
        return '📊';
    }
  }

  /// Get formatted expected change
  String get formattedWeeklyChange {
    if (expectedWeeklyChangeKg.abs() < 0.05) return 'Maintain';
    final sign = expectedWeeklyChangeKg > 0 ? '+' : '';
    return '$sign${expectedWeeklyChangeKg.toStringAsFixed(2)} kg/week';
  }

  /// Get sustainability color
  String get sustainabilityColor {
    switch (sustainabilityRating) {
      case 'high':
        return 'green';
      case 'medium':
        return 'orange';
      default:
        return 'red';
    }
  }

  factory RecommendationOption.fromJson(Map<String, dynamic> json) {
    return RecommendationOption(
      optionType: json['option_type'] as String? ?? 'moderate',
      calories: json['calories'] as int? ?? 0,
      proteinG: json['protein_g'] as int? ?? 0,
      carbsG: json['carbs_g'] as int? ?? 0,
      fatG: json['fat_g'] as int? ?? 0,
      expectedWeeklyChangeKg:
          (json['expected_weekly_change_kg'] as num?)?.toDouble() ?? 0.0,
      sustainabilityRating:
          json['sustainability_rating'] as String? ?? 'medium',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'option_type': optionType,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'expected_weekly_change_kg': expectedWeeklyChangeKg,
        'sustainability_rating': sustainabilityRating,
        'description': description,
      };
}


/// Multi-option recommendation response
class RecommendationOptions {
  final int currentTdee;
  final String currentGoal;
  final double adherenceScore;
  final bool hasAdaptation;
  final List<RecommendationOption> options;
  final String? recommendedOption;

  const RecommendationOptions({
    required this.currentTdee,
    required this.currentGoal,
    required this.adherenceScore,
    required this.hasAdaptation,
    required this.options,
    this.recommendedOption,
  });

  /// Get the recommended option if available
  RecommendationOption? get recommended {
    if (options.isEmpty) return null;
    if (recommendedOption == null) return options.first;
    final match = options.where((o) => o.optionType == recommendedOption);
    return match.isNotEmpty ? match.first : options.first;
  }

  /// Check if aggressive option is available
  bool get hasAggressiveOption =>
      options.any((o) => o.optionType == 'aggressive');

  /// Check if conservative option is available
  bool get hasConservativeOption =>
      options.any((o) => o.optionType == 'conservative');

  factory RecommendationOptions.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List?)
            ?.map((o) => RecommendationOption.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [];

    return RecommendationOptions(
      currentTdee: json['current_tdee'] as int? ?? 0,
      currentGoal: json['current_goal'] as String? ?? 'maintain',
      adherenceScore: (json['adherence_score'] as num?)?.toDouble() ?? 0.0,
      hasAdaptation: json['has_adaptation'] as bool? ?? false,
      options: optionsList,
      recommendedOption: json['recommended_option'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_tdee': currentTdee,
        'current_goal': currentGoal,
        'adherence_score': adherenceScore,
        'has_adaptation': hasAdaptation,
        'options': options.map((o) => o.toJson()).toList(),
        if (recommendedOption != null) 'recommended_option': recommendedOption,
      };
}

