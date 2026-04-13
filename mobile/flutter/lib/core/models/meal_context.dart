/// Lightweight day-context summary for the AI-Coach popup on the meal-log sheet.
///
/// Returned by `GET /api/v1/chat/meal-context`. Powers the conditional pill
/// selection (over-budget → low-cal pill, workout → pre/post pill, favorites →
/// favorite pill) and the "partial context" banner when a backend fetch failed.
library;

class MealContextMacrosRemaining {
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  const MealContextMacrosRemaining({this.proteinG, this.carbsG, this.fatG});

  factory MealContextMacrosRemaining.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return MealContextMacrosRemaining(
      proteinG: toDouble(json['protein_g']),
      carbsG: toDouble(json['carbs_g']),
      fatG: toDouble(json['fat_g']),
    );
  }
}

class TodayWorkoutSummary {
  final String? id;
  final String? name;
  final String? type;
  final bool isCompleted;
  final int? durationMinutes;
  final String? scheduledTimeLocal;
  final List<String> primaryMuscles;
  final int exerciseCount;

  const TodayWorkoutSummary({
    this.id,
    this.name,
    this.type,
    this.isCompleted = false,
    this.durationMinutes,
    this.scheduledTimeLocal,
    this.primaryMuscles = const [],
    this.exerciseCount = 0,
  });

  factory TodayWorkoutSummary.fromJson(Map<String, dynamic> json) {
    return TodayWorkoutSummary(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      scheduledTimeLocal: json['scheduled_time_local'] as String?,
      primaryMuscles: ((json['primary_muscles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FavoritePreview {
  final String? id;
  final String name;
  final int? totalCalories;
  final int? lastLoggedDaysAgo;

  const FavoritePreview({
    this.id,
    required this.name,
    this.totalCalories,
    this.lastLoggedDaysAgo,
  });

  factory FavoritePreview.fromJson(Map<String, dynamic> json) {
    return FavoritePreview(
      id: json['id']?.toString(),
      name: (json['name'] as String?) ?? '',
      totalCalories: (json['total_calories'] as num?)?.toInt(),
      lastLoggedDaysAgo: (json['last_logged_days_ago'] as num?)?.toInt(),
    );
  }
}

class MealContext {
  final int? calorieRemainder;
  final int totalCalories;
  final int? targetCalories;
  final MealContextMacrosRemaining macrosRemaining;
  final bool overBudget;

  final List<String> mealTypesLogged;
  final int mealCount;
  final int ultraProcessedCountToday;

  final TodayWorkoutSummary? todayWorkout;

  final bool hasFavorites;
  final List<FavoritePreview> favoritesPreview;

  final String? mealType;
  final String timezone;
  final bool contextPartial;
  final int computedAtMs;

  const MealContext({
    this.calorieRemainder,
    this.totalCalories = 0,
    this.targetCalories,
    this.macrosRemaining = const MealContextMacrosRemaining(),
    this.overBudget = false,
    this.mealTypesLogged = const [],
    this.mealCount = 0,
    this.ultraProcessedCountToday = 0,
    this.todayWorkout,
    this.hasFavorites = false,
    this.favoritesPreview = const [],
    this.mealType,
    this.timezone = 'UTC',
    this.contextPartial = false,
    this.computedAtMs = 0,
  });

  factory MealContext.fromJson(Map<String, dynamic> json) {
    final workoutJson = json['today_workout'];
    return MealContext(
      calorieRemainder: (json['calorie_remainder'] as num?)?.toInt(),
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      targetCalories: (json['target_calories'] as num?)?.toInt(),
      macrosRemaining: MealContextMacrosRemaining.fromJson(
        (json['macros_remaining'] as Map<String, dynamic>?) ?? const {},
      ),
      overBudget: (json['over_budget'] as bool?) ?? false,
      mealTypesLogged: ((json['meal_types_logged'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      mealCount: (json['meal_count'] as num?)?.toInt() ?? 0,
      ultraProcessedCountToday:
          (json['ultra_processed_count_today'] as num?)?.toInt() ?? 0,
      todayWorkout: workoutJson is Map<String, dynamic>
          ? TodayWorkoutSummary.fromJson(workoutJson)
          : null,
      hasFavorites: (json['has_favorites'] as bool?) ?? false,
      favoritesPreview: ((json['favorites_preview'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FavoritePreview.fromJson)
          .toList(),
      mealType: json['meal_type'] as String?,
      timezone: (json['timezone'] as String?) ?? 'UTC',
      contextPartial: (json['context_partial'] as bool?) ?? false,
      computedAtMs: (json['computed_at_ms'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convenience: one of the key UX discriminators.
  bool get hasWorkoutToday => todayWorkout != null;

  /// For display in "partial context" banner.
  bool get canShowRemainderPill => calorieRemainder != null;
}
