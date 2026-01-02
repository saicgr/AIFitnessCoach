import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weekly_plan.g.dart';

/// Day type for planning
enum DayType {
  training,
  rest,
  @JsonValue('active_recovery')
  activeRecovery;

  String get displayName {
    switch (this) {
      case DayType.training:
        return 'Training Day';
      case DayType.rest:
        return 'Rest Day';
      case DayType.activeRecovery:
        return 'Active Recovery';
    }
  }

  IconData get icon {
    switch (this) {
      case DayType.training:
        return Icons.fitness_center;
      case DayType.rest:
        return Icons.self_improvement;
      case DayType.activeRecovery:
        return Icons.directions_walk;
    }
  }

  Color get color {
    switch (this) {
      case DayType.training:
        return const Color(0xFF4CAF50);
      case DayType.rest:
        return const Color(0xFF9E9E9E);
      case DayType.activeRecovery:
        return const Color(0xFF2196F3);
    }
  }
}

/// Nutrition strategy for the week
enum NutritionStrategy {
  @JsonValue('workout_aware')
  workoutAware,
  static,
  cutting,
  bulking,
  maintenance;

  String get displayName {
    switch (this) {
      case NutritionStrategy.workoutAware:
        return 'Workout Aware';
      case NutritionStrategy.static:
        return 'Static';
      case NutritionStrategy.cutting:
        return 'Cutting';
      case NutritionStrategy.bulking:
        return 'Bulking';
      case NutritionStrategy.maintenance:
        return 'Maintenance';
    }
  }

  String get description {
    switch (this) {
      case NutritionStrategy.workoutAware:
        return 'Higher calories and carbs on training days';
      case NutritionStrategy.static:
        return 'Same targets every day';
      case NutritionStrategy.cutting:
        return 'Calorie deficit for fat loss';
      case NutritionStrategy.bulking:
        return 'Calorie surplus for muscle gain';
      case NutritionStrategy.maintenance:
        return 'Maintain current weight';
    }
  }
}

/// A food item in a meal suggestion
@JsonSerializable()
class FoodItem {
  final String name;
  final String amount;
  final int calories;
  @JsonKey(name: 'protein_g')
  final double proteinG;
  @JsonKey(name: 'carbs_g')
  final double carbsG;
  @JsonKey(name: 'fat_g')
  final double fatG;

  FoodItem({
    required this.name,
    required this.amount,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);

  Map<String, dynamic> toJson() => _$FoodItemToJson(this);
}

/// A meal suggestion within a daily plan
@JsonSerializable()
class MealSuggestion {
  @JsonKey(name: 'meal_type')
  final String mealType;
  @JsonKey(name: 'suggested_time')
  final String suggestedTime;
  final List<FoodItem> foods;
  @JsonKey(name: 'total_calories')
  final int? totalCalories;
  @JsonKey(name: 'total_protein_g')
  final double? totalProteinG;
  @JsonKey(name: 'total_carbs_g')
  final double? totalCarbsG;
  @JsonKey(name: 'total_fat_g')
  final double? totalFatG;
  @JsonKey(name: 'prep_time_minutes')
  final int? prepTimeMinutes;
  final String? notes;

  MealSuggestion({
    required this.mealType,
    required this.suggestedTime,
    required this.foods,
    this.totalCalories,
    this.totalProteinG,
    this.totalCarbsG,
    this.totalFatG,
    this.prepTimeMinutes,
    this.notes,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) =>
      _$MealSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$MealSuggestionToJson(this);

  /// Get display name for meal type
  String get mealTypeDisplay {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      case 'pre_workout':
        return 'Pre-Workout';
      case 'post_workout':
        return 'Post-Workout';
      default:
        return mealType;
    }
  }

  /// Get icon for meal type
  IconData get mealTypeIcon {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.restaurant;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      case 'pre_workout':
        return Icons.bolt;
      case 'post_workout':
        return Icons.fitness_center;
      default:
        return Icons.restaurant_menu;
    }
  }

  /// Parse time string to TimeOfDay
  TimeOfDay? get suggestedTimeOfDay {
    try {
      final parts = suggestedTime.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }
}

/// A coordination note/warning for the daily plan
@JsonSerializable()
class CoordinationNote {
  final String type;
  final String message;
  final String? severity; // info, warning, error
  final String? suggestion;

  CoordinationNote({
    required this.type,
    required this.message,
    this.severity,
    this.suggestion,
  });

  factory CoordinationNote.fromJson(Map<String, dynamic> json) =>
      _$CoordinationNoteFromJson(json);

  Map<String, dynamic> toJson() => _$CoordinationNoteToJson(this);

  Color get severityColor {
    switch (severity?.toLowerCase()) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData get severityIcon {
    switch (severity?.toLowerCase()) {
      case 'warning':
        return Icons.warning_amber;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}

/// A single day's plan entry
@JsonSerializable()
class DailyPlanEntry {
  final String id;
  @JsonKey(name: 'weekly_plan_id')
  final String weeklyPlanId;
  @JsonKey(name: 'plan_date')
  final DateTime planDate;
  @JsonKey(name: 'day_type')
  final DayType dayType;

  // Workout info (null for rest days)
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'workout_time')
  final String? workoutTime;
  @JsonKey(name: 'workout_focus')
  final String? workoutFocus;
  @JsonKey(name: 'workout_duration_minutes')
  final int? workoutDurationMinutes;

  // Nutrition targets for this specific day
  @JsonKey(name: 'calorie_target')
  final int calorieTarget;
  @JsonKey(name: 'protein_target_g')
  final double proteinTargetG;
  @JsonKey(name: 'carbs_target_g')
  final double carbsTargetG;
  @JsonKey(name: 'fat_target_g')
  final double fatTargetG;
  @JsonKey(name: 'fiber_target_g')
  final double? fiberTargetG;

  // Fasting window
  @JsonKey(name: 'fasting_start_time')
  final String? fastingStartTime;
  @JsonKey(name: 'eating_window_start')
  final String? eatingWindowStart;
  @JsonKey(name: 'eating_window_end')
  final String? eatingWindowEnd;
  @JsonKey(name: 'fasting_protocol')
  final String? fastingProtocol;
  @JsonKey(name: 'fasting_duration_hours')
  final int? fastingDurationHours;

  // AI meal suggestions
  @JsonKey(name: 'meal_suggestions')
  final List<MealSuggestion> mealSuggestions;

  // Coordination warnings/notes
  @JsonKey(name: 'coordination_notes')
  final List<CoordinationNote> coordinationNotes;

  // Tracking
  @JsonKey(name: 'nutrition_logged')
  final bool nutritionLogged;
  @JsonKey(name: 'workout_completed')
  final bool workoutCompleted;
  @JsonKey(name: 'fasting_completed')
  final bool fastingCompleted;

  DailyPlanEntry({
    required this.id,
    required this.weeklyPlanId,
    required this.planDate,
    required this.dayType,
    this.workoutId,
    this.workoutTime,
    this.workoutFocus,
    this.workoutDurationMinutes,
    required this.calorieTarget,
    required this.proteinTargetG,
    required this.carbsTargetG,
    required this.fatTargetG,
    this.fiberTargetG,
    this.fastingStartTime,
    this.eatingWindowStart,
    this.eatingWindowEnd,
    this.fastingProtocol,
    this.fastingDurationHours,
    this.mealSuggestions = const [],
    this.coordinationNotes = const [],
    this.nutritionLogged = false,
    this.workoutCompleted = false,
    this.fastingCompleted = false,
  });

  factory DailyPlanEntry.fromJson(Map<String, dynamic> json) =>
      _$DailyPlanEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DailyPlanEntryToJson(this);

  /// Check if this is today
  bool get isToday {
    final now = DateTime.now();
    return planDate.year == now.year &&
        planDate.month == now.month &&
        planDate.day == now.day;
  }

  /// Get day name (Monday, Tuesday, etc.)
  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[planDate.weekday - 1];
  }

  /// Get short day name (Mon, Tue, etc.)
  String get shortDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[planDate.weekday - 1];
  }

  /// Parse workout time to TimeOfDay
  TimeOfDay? get workoutTimeOfDay {
    if (workoutTime == null) return null;
    try {
      final parts = workoutTime!.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Get eating window display string
  String? get eatingWindowDisplay {
    if (eatingWindowStart == null || eatingWindowEnd == null) return null;
    return '$eatingWindowStart - $eatingWindowEnd';
  }

  /// Check if there are warnings
  bool get hasWarnings =>
      coordinationNotes.any((n) => n.severity == 'warning' || n.severity == 'error');
}

/// A complete weekly plan
@JsonSerializable()
class WeeklyPlan {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'week_start_date')
  final DateTime weekStartDate;
  final String status;

  // Plan settings
  @JsonKey(name: 'workout_days')
  final List<int> workoutDays;
  @JsonKey(name: 'fasting_protocol')
  final String? fastingProtocol;
  @JsonKey(name: 'nutrition_strategy')
  final String nutritionStrategy;

  // Base nutrition targets
  @JsonKey(name: 'base_calorie_target')
  final int? baseCalorieTarget;
  @JsonKey(name: 'base_protein_target_g')
  final double? baseProteinTargetG;
  @JsonKey(name: 'base_carbs_target_g')
  final double? baseCarbsTargetG;
  @JsonKey(name: 'base_fat_target_g')
  final double? baseFatTargetG;

  // AI generation metadata
  @JsonKey(name: 'generated_at')
  final DateTime? generatedAt;
  @JsonKey(name: 'ai_model_used')
  final String? aiModelUsed;

  // Daily entries
  @JsonKey(name: 'daily_entries')
  final List<DailyPlanEntry> dailyEntries;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  WeeklyPlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.status,
    required this.workoutDays,
    this.fastingProtocol,
    required this.nutritionStrategy,
    this.baseCalorieTarget,
    this.baseProteinTargetG,
    this.baseCarbsTargetG,
    this.baseFatTargetG,
    this.generatedAt,
    this.aiModelUsed,
    this.dailyEntries = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPlanFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyPlanToJson(this);

  /// Get today's entry if it exists in this plan
  DailyPlanEntry? get todayEntry {
    try {
      return dailyEntries.firstWhere((e) => e.isToday);
    } catch (_) {
      return null;
    }
  }

  /// Get training day count
  int get trainingDayCount =>
      dailyEntries.where((e) => e.dayType == DayType.training).length;

  /// Get rest day count
  int get restDayCount =>
      dailyEntries.where((e) => e.dayType == DayType.rest).length;

  /// Get average daily calories
  int get avgDailyCalories {
    if (dailyEntries.isEmpty) return 0;
    final total = dailyEntries.fold<int>(0, (sum, e) => sum + e.calorieTarget);
    return total ~/ dailyEntries.length;
  }

  /// Get week end date
  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  /// Get display date range
  String get dateRangeDisplay {
    final startMonth = _monthName(weekStartDate.month);
    final endMonth = _monthName(weekEndDate.month);

    if (startMonth == endMonth) {
      return '$startMonth ${weekStartDate.day} - ${weekEndDate.day}';
    }
    return '$startMonth ${weekStartDate.day} - $endMonth ${weekEndDate.day}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  /// Check if this plan is for the current week
  bool get isCurrentWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStartDate.year == weekStart.year &&
        weekStartDate.month == weekStart.month &&
        weekStartDate.day == weekStart.day;
  }

  /// Get parsed nutrition strategy
  NutritionStrategy get parsedNutritionStrategy {
    switch (nutritionStrategy.toLowerCase()) {
      case 'workout_aware':
        return NutritionStrategy.workoutAware;
      case 'static':
        return NutritionStrategy.static;
      case 'cutting':
        return NutritionStrategy.cutting;
      case 'bulking':
        return NutritionStrategy.bulking;
      case 'maintenance':
        return NutritionStrategy.maintenance;
      default:
        return NutritionStrategy.workoutAware;
    }
  }

  /// Get workout days as day names
  List<String> get workoutDayNames {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return workoutDays.map((i) => days[i]).toList();
  }
}

/// Request model for generating a weekly plan
@JsonSerializable()
class GenerateWeeklyPlanRequest {
  @JsonKey(name: 'workout_days')
  final List<int> workoutDays;
  @JsonKey(name: 'fasting_protocol')
  final String? fastingProtocol;
  @JsonKey(name: 'nutrition_strategy')
  final String nutritionStrategy;
  @JsonKey(name: 'preferred_workout_time')
  final String? preferredWorkoutTime;
  final List<String>? goals;

  GenerateWeeklyPlanRequest({
    required this.workoutDays,
    this.fastingProtocol,
    required this.nutritionStrategy,
    this.preferredWorkoutTime,
    this.goals,
  });

  factory GenerateWeeklyPlanRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateWeeklyPlanRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateWeeklyPlanRequestToJson(this);
}

/// Request model for generating meal suggestions
@JsonSerializable()
class GenerateMealSuggestionsRequest {
  @JsonKey(name: 'plan_date')
  final String planDate;
  @JsonKey(name: 'day_type')
  final String dayType;
  @JsonKey(name: 'calorie_target')
  final int calorieTarget;
  @JsonKey(name: 'protein_target_g')
  final double proteinTargetG;
  @JsonKey(name: 'eating_window_start')
  final String? eatingWindowStart;
  @JsonKey(name: 'eating_window_end')
  final String? eatingWindowEnd;
  @JsonKey(name: 'workout_time')
  final String? workoutTime;

  GenerateMealSuggestionsRequest({
    required this.planDate,
    required this.dayType,
    required this.calorieTarget,
    required this.proteinTargetG,
    this.eatingWindowStart,
    this.eatingWindowEnd,
    this.workoutTime,
  });

  factory GenerateMealSuggestionsRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateMealSuggestionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateMealSuggestionsRequestToJson(this);
}
