import 'package:json_annotation/json_annotation.dart';

part 'habit.g.dart';

/// Habit category enumeration
enum HabitCategory {
  @JsonValue('nutrition')
  nutrition('nutrition', 'Nutrition', 'apple.alt'),
  @JsonValue('activity')
  activity('activity', 'Activity', 'running'),
  @JsonValue('health')
  health('health', 'Health', 'heart'),
  @JsonValue('lifestyle')
  lifestyle('lifestyle', 'Lifestyle', 'star');

  final String value;
  final String label;
  final String iconName;

  const HabitCategory(this.value, this.label, this.iconName);

  static HabitCategory fromValue(String value) {
    return HabitCategory.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => HabitCategory.lifestyle,
    );
  }
}

/// Habit type: positive (build) or negative (break)
enum HabitType {
  @JsonValue('positive')
  positive('positive', 'Build'),
  @JsonValue('negative')
  negative('negative', 'Break');

  final String value;
  final String label;

  const HabitType(this.value, this.label);

  static HabitType fromValue(String value) {
    return HabitType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => HabitType.positive,
    );
  }
}

/// Habit frequency enumeration
enum HabitFrequency {
  @JsonValue('daily')
  daily('daily', 'Daily'),
  @JsonValue('weekly')
  weekly('weekly', 'Weekly'),
  @JsonValue('specific_days')
  specificDays('specific_days', 'Specific Days');

  final String value;
  final String label;

  const HabitFrequency(this.value, this.label);

  static HabitFrequency fromValue(String value) {
    return HabitFrequency.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => HabitFrequency.daily,
    );
  }
}

/// Main habit model
@JsonSerializable()
class Habit {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final HabitCategory category;
  @JsonKey(name: 'habit_type')
  final HabitType habitType;
  final HabitFrequency frequency;
  @JsonKey(name: 'specific_days')
  final List<int>? specificDays; // 0 = Sunday, 6 = Saturday
  @JsonKey(name: 'target_count')
  final int? targetCount; // For quantitative habits
  final String? unit; // e.g., "glasses", "minutes", "steps"
  final String icon;
  final String color;
  @JsonKey(name: 'reminder_time')
  final String? reminderTime; // HH:mm format
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Computed/joined fields
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'best_streak')
  final int bestStreak;
  @JsonKey(name: 'completion_rate_7d')
  final double completionRate7d;
  @JsonKey(name: 'is_completed_today')
  final bool isCompletedToday;
  @JsonKey(name: 'today_progress')
  final int todayProgress;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category = HabitCategory.lifestyle,
    this.habitType = HabitType.positive,
    this.frequency = HabitFrequency.daily,
    this.specificDays,
    this.targetCount,
    this.unit,
    this.icon = 'check_circle',
    this.color = '#06B6D4',
    this.reminderTime,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completionRate7d = 0.0,
    this.isCompletedToday = false,
    this.todayProgress = 0,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
  Map<String, dynamic> toJson() => _$HabitToJson(this);

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    HabitCategory? category,
    HabitType? habitType,
    HabitFrequency? frequency,
    List<int>? specificDays,
    int? targetCount,
    String? unit,
    String? icon,
    String? color,
    String? reminderTime,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? bestStreak,
    double? completionRate7d,
    bool? isCompletedToday,
    int? todayProgress,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      habitType: habitType ?? this.habitType,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      reminderTime: reminderTime ?? this.reminderTime,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      completionRate7d: completionRate7d ?? this.completionRate7d,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      todayProgress: todayProgress ?? this.todayProgress,
    );
  }

  /// Check if habit is due today based on frequency
  bool get isDueToday {
    if (frequency == HabitFrequency.daily) return true;
    if (frequency == HabitFrequency.specificDays && specificDays != null) {
      final today = DateTime.now().weekday % 7; // Convert to 0-6 (Sun-Sat)
      return specificDays!.contains(today);
    }
    return true;
  }

  /// Get progress percentage for quantitative habits
  double get progressPercentage {
    if (targetCount == null || targetCount == 0) {
      return isCompletedToday ? 1.0 : 0.0;
    }
    return (todayProgress / targetCount!).clamp(0.0, 1.0);
  }
}

/// Habit completion log entry
@JsonSerializable()
class HabitLog {
  final String id;
  @JsonKey(name: 'habit_id')
  final String habitId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String date; // YYYY-MM-DD
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'is_skipped')
  final bool isSkipped;
  final int? value; // For quantitative habits
  final String? notes;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    this.isCompleted = false,
    this.isSkipped = false,
    this.value,
    this.notes,
    this.completedAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) => _$HabitLogFromJson(json);
  Map<String, dynamic> toJson() => _$HabitLogToJson(this);
}

/// Daily habits summary
@JsonSerializable()
class DailyHabitSummary {
  final String date;
  @JsonKey(name: 'total_habits')
  final int totalHabits;
  @JsonKey(name: 'completed_count')
  final int completedCount;
  @JsonKey(name: 'skipped_count')
  final int skippedCount;
  @JsonKey(name: 'completion_percentage')
  final double completionPercentage;
  final List<Habit> habits;

  const DailyHabitSummary({
    required this.date,
    this.totalHabits = 0,
    this.completedCount = 0,
    this.skippedCount = 0,
    this.completionPercentage = 0.0,
    this.habits = const [],
  });

  factory DailyHabitSummary.fromJson(Map<String, dynamic> json) =>
      _$DailyHabitSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DailyHabitSummaryToJson(this);
}

/// Weekly habit statistics
@JsonSerializable()
class WeeklyHabitStats {
  @JsonKey(name: 'week_start')
  final String weekStart;
  @JsonKey(name: 'week_end')
  final String weekEnd;
  @JsonKey(name: 'total_completions')
  final int totalCompletions;
  @JsonKey(name: 'total_possible')
  final int totalPossible;
  @JsonKey(name: 'completion_rate')
  final double completionRate;
  @JsonKey(name: 'best_day')
  final String? bestDay;
  @JsonKey(name: 'improvement_trend')
  final String improvementTrend; // 'improving', 'stable', 'declining'
  @JsonKey(name: 'daily_breakdown')
  final Map<String, int> dailyBreakdown;

  const WeeklyHabitStats({
    required this.weekStart,
    required this.weekEnd,
    this.totalCompletions = 0,
    this.totalPossible = 0,
    this.completionRate = 0.0,
    this.bestDay,
    this.improvementTrend = 'stable',
    this.dailyBreakdown = const {},
  });

  factory WeeklyHabitStats.fromJson(Map<String, dynamic> json) =>
      _$WeeklyHabitStatsFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyHabitStatsToJson(this);
}

/// Habit template for quick creation
@JsonSerializable()
class HabitTemplate {
  final String id;
  final String name;
  final String description;
  final HabitCategory category;
  @JsonKey(name: 'habit_type')
  final HabitType habitType;
  final String icon;
  final String color;
  @JsonKey(name: 'suggested_target_count')
  final int? suggestedTargetCount;
  final String? unit;

  const HabitTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.habitType = HabitType.positive,
    required this.icon,
    required this.color,
    this.suggestedTargetCount,
    this.unit,
  });

  factory HabitTemplate.fromJson(Map<String, dynamic> json) =>
      _$HabitTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$HabitTemplateToJson(this);

  static const List<HabitTemplate> defaults = [
    // Nutrition
    HabitTemplate(
      id: 'drink_water',
      name: 'Drink Water',
      description: 'Stay hydrated throughout the day',
      category: HabitCategory.nutrition,
      icon: 'water_drop',
      color: '#3B82F6',
      suggestedTargetCount: 8,
      unit: 'glasses',
    ),
    HabitTemplate(
      id: 'eat_vegetables',
      name: 'Eat Vegetables',
      description: 'Include veggies in your meals',
      category: HabitCategory.nutrition,
      icon: 'eco',
      color: '#22C55E',
      suggestedTargetCount: 3,
      unit: 'servings',
    ),
    HabitTemplate(
      id: 'no_sugar',
      name: 'Avoid Added Sugar',
      description: 'Skip sugary drinks and snacks',
      category: HabitCategory.nutrition,
      habitType: HabitType.negative,
      icon: 'do_not_disturb',
      color: '#EF4444',
    ),
    HabitTemplate(
      id: 'take_vitamins',
      name: 'Take Vitamins',
      description: 'Remember your daily supplements',
      category: HabitCategory.nutrition,
      icon: 'medication',
      color: '#F97316',
    ),
    // Activity
    HabitTemplate(
      id: 'daily_walk',
      name: 'Daily Walk',
      description: 'Take a walk every day',
      category: HabitCategory.activity,
      icon: 'directions_walk',
      color: '#06B6D4',
      suggestedTargetCount: 30,
      unit: 'minutes',
    ),
    HabitTemplate(
      id: 'stretch',
      name: 'Morning Stretch',
      description: 'Start your day with stretching',
      category: HabitCategory.activity,
      icon: 'self_improvement',
      color: '#14B8A6',
    ),
    HabitTemplate(
      id: 'steps',
      name: '10K Steps',
      description: 'Reach 10,000 steps daily',
      category: HabitCategory.activity,
      icon: 'directions_run',
      color: '#8B5CF6',
      suggestedTargetCount: 10000,
      unit: 'steps',
    ),
    HabitTemplate(
      id: 'workout',
      name: 'Workout',
      description: 'Complete a workout session',
      category: HabitCategory.activity,
      icon: 'fitness_center',
      color: '#EC4899',
    ),
    // Health
    HabitTemplate(
      id: 'sleep_early',
      name: 'Sleep Early',
      description: 'Get to bed by a healthy time',
      category: HabitCategory.health,
      icon: 'bedtime',
      color: '#6366F1',
    ),
    HabitTemplate(
      id: 'meditate',
      name: 'Meditate',
      description: 'Practice mindfulness daily',
      category: HabitCategory.health,
      icon: 'spa',
      color: '#14B8A6',
      suggestedTargetCount: 10,
      unit: 'minutes',
    ),
    HabitTemplate(
      id: 'no_alcohol',
      name: 'No Alcohol',
      description: 'Stay alcohol-free',
      category: HabitCategory.health,
      habitType: HabitType.negative,
      icon: 'no_drinks',
      color: '#F43F5E',
    ),
    HabitTemplate(
      id: 'sunlight',
      name: 'Morning Sunlight',
      description: 'Get natural light in the morning',
      category: HabitCategory.health,
      icon: 'wb_sunny',
      color: '#FBBF24',
    ),
    // Lifestyle
    HabitTemplate(
      id: 'read',
      name: 'Read',
      description: 'Read for personal growth',
      category: HabitCategory.lifestyle,
      icon: 'menu_book',
      color: '#F97316',
      suggestedTargetCount: 20,
      unit: 'minutes',
    ),
    HabitTemplate(
      id: 'journal',
      name: 'Journal',
      description: 'Write in your journal',
      category: HabitCategory.lifestyle,
      icon: 'edit_note',
      color: '#8B5CF6',
    ),
    HabitTemplate(
      id: 'no_phone_bed',
      name: 'No Phone Before Bed',
      description: 'Avoid screens before sleep',
      category: HabitCategory.lifestyle,
      habitType: HabitType.negative,
      icon: 'phone_disabled',
      color: '#64748B',
    ),
    HabitTemplate(
      id: 'gratitude',
      name: 'Practice Gratitude',
      description: 'Note things you are grateful for',
      category: HabitCategory.lifestyle,
      icon: 'favorite',
      color: '#EC4899',
    ),
  ];

  static List<HabitTemplate> getByCategory(HabitCategory category) {
    return defaults.where((t) => t.category == category).toList();
  }
}

/// AI-generated habit insights
@JsonSerializable()
class HabitInsights {
  final String summary;
  @JsonKey(name: 'best_performing')
  final List<String> bestPerforming;
  @JsonKey(name: 'needs_improvement')
  final List<String> needsImprovement;
  final List<String> suggestions;
  @JsonKey(name: 'generated_at')
  final DateTime? generatedAt;

  const HabitInsights({
    required this.summary,
    this.bestPerforming = const [],
    this.needsImprovement = const [],
    this.suggestions = const [],
    this.generatedAt,
  });

  factory HabitInsights.fromJson(Map<String, dynamic> json) =>
      _$HabitInsightsFromJson(json);
  Map<String, dynamic> toJson() => _$HabitInsightsToJson(this);
}

/// Habit with today's status for provider state
@JsonSerializable()
class HabitWithStatus {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  final String? description;
  final HabitCategory category;
  @JsonKey(name: 'habit_type')
  final HabitType habitType;
  final HabitFrequency frequency;
  @JsonKey(name: 'specific_days')
  final List<int>? specificDays;
  @JsonKey(name: 'target_count')
  final int? targetCount;
  final String? unit;
  final String icon;
  final String color;
  @JsonKey(name: 'reminder_time')
  final String? reminderTime;
  @JsonKey(name: 'is_archived')
  final bool isArchived;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'best_streak')
  final int bestStreak;
  @JsonKey(name: 'completion_rate_7d')
  final double completionRate7d;
  @JsonKey(name: 'today_completed')
  final bool todayCompleted;
  @JsonKey(name: 'today_value')
  final double? todayValue;
  final int? order;

  const HabitWithStatus({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category = HabitCategory.lifestyle,
    this.habitType = HabitType.positive,
    this.frequency = HabitFrequency.daily,
    this.specificDays,
    this.targetCount,
    this.unit,
    this.icon = 'check_circle',
    this.color = '#06B6D4',
    this.reminderTime,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completionRate7d = 0.0,
    this.todayCompleted = false,
    this.todayValue,
    this.order,
  });

  factory HabitWithStatus.fromJson(Map<String, dynamic> json) =>
      _$HabitWithStatusFromJson(json);
  Map<String, dynamic> toJson() => _$HabitWithStatusToJson(this);

  HabitWithStatus copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    HabitCategory? category,
    HabitType? habitType,
    HabitFrequency? frequency,
    List<int>? specificDays,
    int? targetCount,
    String? unit,
    String? icon,
    String? color,
    String? reminderTime,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? bestStreak,
    double? completionRate7d,
    bool? todayCompleted,
    double? todayValue,
    int? order,
  }) {
    return HabitWithStatus(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      habitType: habitType ?? this.habitType,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      reminderTime: reminderTime ?? this.reminderTime,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      completionRate7d: completionRate7d ?? this.completionRate7d,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      todayValue: todayValue ?? this.todayValue,
      order: order ?? this.order,
    );
  }
}

/// Today's habits response from API
@JsonSerializable()
class TodayHabitsResponse {
  final List<HabitWithStatus> habits;
  @JsonKey(name: 'total_habits')
  final int totalHabits;
  @JsonKey(name: 'completed_today')
  final int completedToday;
  @JsonKey(name: 'completion_percentage')
  final double completionPercentage;

  const TodayHabitsResponse({
    this.habits = const [],
    this.totalHabits = 0,
    this.completedToday = 0,
    this.completionPercentage = 0.0,
  });

  factory TodayHabitsResponse.fromJson(Map<String, dynamic> json) =>
      _$TodayHabitsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TodayHabitsResponseToJson(this);
}

/// Habits summary for dashboard
@JsonSerializable()
class HabitsSummary {
  @JsonKey(name: 'total_active_habits')
  final int totalActiveHabits;
  @JsonKey(name: 'completed_today')
  final int completedToday;
  @JsonKey(name: 'completion_rate_today')
  final double completionRateToday;
  @JsonKey(name: 'average_streak')
  final double averageStreak;
  @JsonKey(name: 'longest_current_streak')
  final int longestCurrentStreak;
  @JsonKey(name: 'best_habit_name')
  final String? bestHabitName;
  @JsonKey(name: 'needs_attention')
  final List<String> needsAttention;

  const HabitsSummary({
    this.totalActiveHabits = 0,
    this.completedToday = 0,
    this.completionRateToday = 0.0,
    this.averageStreak = 0.0,
    this.longestCurrentStreak = 0,
    this.bestHabitName,
    this.needsAttention = const [],
  });

  factory HabitsSummary.fromJson(Map<String, dynamic> json) =>
      _$HabitsSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$HabitsSummaryToJson(this);
}

/// Weekly summary for a habit
@JsonSerializable()
class HabitWeeklySummary {
  @JsonKey(name: 'habit_id')
  final String habitId;
  @JsonKey(name: 'habit_name')
  final String habitName;
  @JsonKey(name: 'week_start')
  final DateTime weekStart;
  @JsonKey(name: 'days_completed')
  final int daysCompleted;
  @JsonKey(name: 'days_scheduled')
  final int daysScheduled;
  @JsonKey(name: 'completion_rate')
  final double completionRate;
  @JsonKey(name: 'current_streak')
  final int currentStreak;

  const HabitWeeklySummary({
    required this.habitId,
    required this.habitName,
    required this.weekStart,
    this.daysCompleted = 0,
    this.daysScheduled = 7,
    this.completionRate = 0.0,
    this.currentStreak = 0,
  });

  factory HabitWeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$HabitWeeklySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$HabitWeeklySummaryToJson(this);
}

/// Habit streak data
@JsonSerializable()
class HabitStreak {
  final String id;
  @JsonKey(name: 'habit_id')
  final String habitId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'last_completed_date')
  final DateTime? lastCompletedDate;
  @JsonKey(name: 'streak_start_date')
  final DateTime? streakStartDate;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const HabitStreak({
    required this.id,
    required this.habitId,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.streakStartDate,
    required this.updatedAt,
  });

  factory HabitStreak.fromJson(Map<String, dynamic> json) =>
      _$HabitStreakFromJson(json);
  Map<String, dynamic> toJson() => _$HabitStreakToJson(this);
}

/// Habit suggestion response from AI
@JsonSerializable()
class HabitSuggestionResponse {
  @JsonKey(name: 'suggested_habits')
  final List<HabitTemplate> suggestedHabits;
  final String reasoning;

  const HabitSuggestionResponse({
    this.suggestedHabits = const [],
    this.reasoning = '',
  });

  factory HabitSuggestionResponse.fromJson(Map<String, dynamic> json) =>
      _$HabitSuggestionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HabitSuggestionResponseToJson(this);
}

/// Calendar data for visualization
@JsonSerializable()
class HabitCalendarData {
  final DateTime date;
  final String status; // completed, missed, skipped, not_scheduled, future
  final double? value;

  const HabitCalendarData({
    required this.date,
    required this.status,
    this.value,
  });

  factory HabitCalendarData.fromJson(Map<String, dynamic> json) =>
      _$HabitCalendarDataFromJson(json);
  Map<String, dynamic> toJson() => _$HabitCalendarDataToJson(this);
}

/// Request to create a new habit
class HabitCreate {
  final String name;
  final String? description;
  final HabitCategory category;
  final HabitType habitType;
  final HabitFrequency frequency;
  final List<int>? specificDays;
  final int? targetCount;
  final String? unit;
  final String icon;
  final String color;
  final String? reminderTime;

  const HabitCreate({
    required this.name,
    this.description,
    this.category = HabitCategory.lifestyle,
    this.habitType = HabitType.positive,
    this.frequency = HabitFrequency.daily,
    this.specificDays,
    this.targetCount,
    this.unit,
    this.icon = 'check_circle',
    this.color = '#06B6D4',
    this.reminderTime,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'category': category.value,
        'habit_type': habitType.value,
        'frequency': frequency.value,
        if (specificDays != null) 'specific_days': specificDays,
        if (targetCount != null) 'target_count': targetCount,
        if (unit != null) 'unit': unit,
        'icon': icon,
        'color': color,
        if (reminderTime != null) 'reminder_time': reminderTime,
      };
}

/// Request to update a habit
class HabitUpdate {
  final String? name;
  final String? description;
  final HabitCategory? category;
  final HabitType? habitType;
  final HabitFrequency? frequency;
  final List<int>? specificDays;
  final int? targetCount;
  final String? unit;
  final String? icon;
  final String? color;
  final String? reminderTime;
  final bool? isArchived;

  const HabitUpdate({
    this.name,
    this.description,
    this.category,
    this.habitType,
    this.frequency,
    this.specificDays,
    this.targetCount,
    this.unit,
    this.icon,
    this.color,
    this.reminderTime,
    this.isArchived,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (category != null) map['category'] = category!.value;
    if (habitType != null) map['habit_type'] = habitType!.value;
    if (frequency != null) map['frequency'] = frequency!.value;
    if (specificDays != null) map['specific_days'] = specificDays;
    if (targetCount != null) map['target_count'] = targetCount;
    if (unit != null) map['unit'] = unit;
    if (icon != null) map['icon'] = icon;
    if (color != null) map['color'] = color;
    if (reminderTime != null) map['reminder_time'] = reminderTime;
    if (isArchived != null) map['is_archived'] = isArchived;
    return map;
  }
}

/// Request to log a habit
class HabitLogCreate {
  final String habitId;
  final DateTime logDate;
  final bool completed;
  final double? value;
  final String? notes;
  final bool skipped;
  final String? skipReason;

  const HabitLogCreate({
    required this.habitId,
    required this.logDate,
    this.completed = false,
    this.value,
    this.notes,
    this.skipped = false,
    this.skipReason,
  });

  Map<String, dynamic> toJson() => {
        'habit_id': habitId,
        'log_date': logDate.toIso8601String().split('T')[0],
        'completed': completed,
        if (value != null) 'value': value,
        if (notes != null) 'notes': notes,
        'skipped': skipped,
        if (skipReason != null) 'skip_reason': skipReason,
      };
}

/// Request to update a habit log
class HabitLogUpdate {
  final bool? completed;
  final double? value;
  final String? notes;
  final bool? skipped;
  final String? skipReason;

  const HabitLogUpdate({
    this.completed,
    this.value,
    this.notes,
    this.skipped,
    this.skipReason,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (completed != null) map['completed'] = completed;
    if (value != null) map['value'] = value;
    if (notes != null) map['notes'] = notes;
    if (skipped != null) map['skipped'] = skipped;
    if (skipReason != null) map['skip_reason'] = skipReason;
    return map;
  }
}
