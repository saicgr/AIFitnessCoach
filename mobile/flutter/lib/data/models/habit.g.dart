// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  category:
      $enumDecodeNullable(_$HabitCategoryEnumMap, json['category']) ??
      HabitCategory.lifestyle,
  habitType:
      $enumDecodeNullable(_$HabitTypeEnumMap, json['habit_type']) ??
      HabitType.positive,
  frequency:
      $enumDecodeNullable(_$HabitFrequencyEnumMap, json['frequency']) ??
      HabitFrequency.daily,
  specificDays: (json['specific_days'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  targetCount: (json['target_count'] as num?)?.toInt(),
  unit: json['unit'] as String?,
  icon: json['icon'] as String? ?? 'check_circle',
  color: json['color'] as String? ?? '#06B6D4',
  reminderTime: json['reminder_time'] as String?,
  isArchived: json['is_archived'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
  completionRate7d: (json['completion_rate_7d'] as num?)?.toDouble() ?? 0.0,
  isCompletedToday: json['is_completed_today'] as bool? ?? false,
  todayProgress: (json['today_progress'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'category': _$HabitCategoryEnumMap[instance.category]!,
  'habit_type': _$HabitTypeEnumMap[instance.habitType]!,
  'frequency': _$HabitFrequencyEnumMap[instance.frequency]!,
  'specific_days': instance.specificDays,
  'target_count': instance.targetCount,
  'unit': instance.unit,
  'icon': instance.icon,
  'color': instance.color,
  'reminder_time': instance.reminderTime,
  'is_archived': instance.isArchived,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'current_streak': instance.currentStreak,
  'best_streak': instance.bestStreak,
  'completion_rate_7d': instance.completionRate7d,
  'is_completed_today': instance.isCompletedToday,
  'today_progress': instance.todayProgress,
};

const _$HabitCategoryEnumMap = {
  HabitCategory.nutrition: 'nutrition',
  HabitCategory.activity: 'activity',
  HabitCategory.health: 'health',
  HabitCategory.lifestyle: 'lifestyle',
};

const _$HabitTypeEnumMap = {
  HabitType.positive: 'positive',
  HabitType.negative: 'negative',
};

const _$HabitFrequencyEnumMap = {
  HabitFrequency.daily: 'daily',
  HabitFrequency.weekly: 'weekly',
  HabitFrequency.specificDays: 'specific_days',
};

HabitLog _$HabitLogFromJson(Map<String, dynamic> json) => HabitLog(
  id: json['id'] as String,
  habitId: json['habit_id'] as String,
  userId: json['user_id'] as String,
  date: json['date'] as String,
  isCompleted: json['is_completed'] as bool? ?? false,
  isSkipped: json['is_skipped'] as bool? ?? false,
  value: (json['value'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
);

Map<String, dynamic> _$HabitLogToJson(HabitLog instance) => <String, dynamic>{
  'id': instance.id,
  'habit_id': instance.habitId,
  'user_id': instance.userId,
  'date': instance.date,
  'is_completed': instance.isCompleted,
  'is_skipped': instance.isSkipped,
  'value': instance.value,
  'notes': instance.notes,
  'completed_at': instance.completedAt?.toIso8601String(),
};

DailyHabitSummary _$DailyHabitSummaryFromJson(Map<String, dynamic> json) =>
    DailyHabitSummary(
      date: json['date'] as String,
      totalHabits: (json['total_habits'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skipped_count'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      habits:
          (json['habits'] as List<dynamic>?)
              ?.map((e) => Habit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyHabitSummaryToJson(DailyHabitSummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_habits': instance.totalHabits,
      'completed_count': instance.completedCount,
      'skipped_count': instance.skippedCount,
      'completion_percentage': instance.completionPercentage,
      'habits': instance.habits,
    };

WeeklyHabitStats _$WeeklyHabitStatsFromJson(Map<String, dynamic> json) =>
    WeeklyHabitStats(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalCompletions: (json['total_completions'] as num?)?.toInt() ?? 0,
      totalPossible: (json['total_possible'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      bestDay: json['best_day'] as String?,
      improvementTrend: json['improvement_trend'] as String? ?? 'stable',
      dailyBreakdown:
          (json['daily_breakdown'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$WeeklyHabitStatsToJson(WeeklyHabitStats instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'total_completions': instance.totalCompletions,
      'total_possible': instance.totalPossible,
      'completion_rate': instance.completionRate,
      'best_day': instance.bestDay,
      'improvement_trend': instance.improvementTrend,
      'daily_breakdown': instance.dailyBreakdown,
    };

HabitTemplate _$HabitTemplateFromJson(Map<String, dynamic> json) =>
    HabitTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$HabitCategoryEnumMap, json['category']),
      habitType:
          $enumDecodeNullable(_$HabitTypeEnumMap, json['habit_type']) ??
          HabitType.positive,
      icon: json['icon'] as String,
      color: json['color'] as String,
      suggestedTargetCount: (json['suggested_target_count'] as num?)?.toInt(),
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$HabitTemplateToJson(HabitTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': _$HabitCategoryEnumMap[instance.category]!,
      'habit_type': _$HabitTypeEnumMap[instance.habitType]!,
      'icon': instance.icon,
      'color': instance.color,
      'suggested_target_count': instance.suggestedTargetCount,
      'unit': instance.unit,
    };

HabitInsights _$HabitInsightsFromJson(Map<String, dynamic> json) =>
    HabitInsights(
      summary: json['summary'] as String,
      bestPerforming:
          (json['best_performing'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      needsImprovement:
          (json['needs_improvement'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.parse(json['generated_at'] as String),
    );

Map<String, dynamic> _$HabitInsightsToJson(HabitInsights instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'best_performing': instance.bestPerforming,
      'needs_improvement': instance.needsImprovement,
      'suggestions': instance.suggestions,
      'generated_at': instance.generatedAt?.toIso8601String(),
    };

HabitWithStatus _$HabitWithStatusFromJson(Map<String, dynamic> json) =>
    HabitWithStatus(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category:
          $enumDecodeNullable(_$HabitCategoryEnumMap, json['category']) ??
          HabitCategory.lifestyle,
      habitType:
          $enumDecodeNullable(_$HabitTypeEnumMap, json['habit_type']) ??
          HabitType.positive,
      frequency:
          $enumDecodeNullable(_$HabitFrequencyEnumMap, json['frequency']) ??
          HabitFrequency.daily,
      specificDays: (json['specific_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      targetCount: (json['target_count'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      icon: json['icon'] as String? ?? 'check_circle',
      color: json['color'] as String? ?? '#06B6D4',
      reminderTime: json['reminder_time'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      completionRate7d: (json['completion_rate_7d'] as num?)?.toDouble() ?? 0.0,
      todayCompleted: json['today_completed'] as bool? ?? false,
      todayValue: (json['today_value'] as num?)?.toDouble(),
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HabitWithStatusToJson(HabitWithStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'category': _$HabitCategoryEnumMap[instance.category]!,
      'habit_type': _$HabitTypeEnumMap[instance.habitType]!,
      'frequency': _$HabitFrequencyEnumMap[instance.frequency]!,
      'specific_days': instance.specificDays,
      'target_count': instance.targetCount,
      'unit': instance.unit,
      'icon': instance.icon,
      'color': instance.color,
      'reminder_time': instance.reminderTime,
      'is_archived': instance.isArchived,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'current_streak': instance.currentStreak,
      'best_streak': instance.bestStreak,
      'completion_rate_7d': instance.completionRate7d,
      'today_completed': instance.todayCompleted,
      'today_value': instance.todayValue,
      'order': instance.order,
    };

TodayHabitsResponse _$TodayHabitsResponseFromJson(Map<String, dynamic> json) =>
    TodayHabitsResponse(
      habits:
          (json['habits'] as List<dynamic>?)
              ?.map((e) => HabitWithStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalHabits: (json['total_habits'] as num?)?.toInt() ?? 0,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TodayHabitsResponseToJson(
  TodayHabitsResponse instance,
) => <String, dynamic>{
  'habits': instance.habits,
  'total_habits': instance.totalHabits,
  'completed_today': instance.completedToday,
  'completion_percentage': instance.completionPercentage,
};

HabitsSummary _$HabitsSummaryFromJson(Map<String, dynamic> json) =>
    HabitsSummary(
      totalActiveHabits: (json['total_active_habits'] as num?)?.toInt() ?? 0,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      completionRateToday:
          (json['completion_rate_today'] as num?)?.toDouble() ?? 0.0,
      averageStreak: (json['average_streak'] as num?)?.toDouble() ?? 0.0,
      longestCurrentStreak:
          (json['longest_current_streak'] as num?)?.toInt() ?? 0,
      bestHabitName: json['best_habit_name'] as String?,
      needsAttention:
          (json['needs_attention'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HabitsSummaryToJson(HabitsSummary instance) =>
    <String, dynamic>{
      'total_active_habits': instance.totalActiveHabits,
      'completed_today': instance.completedToday,
      'completion_rate_today': instance.completionRateToday,
      'average_streak': instance.averageStreak,
      'longest_current_streak': instance.longestCurrentStreak,
      'best_habit_name': instance.bestHabitName,
      'needs_attention': instance.needsAttention,
    };

HabitWeeklySummary _$HabitWeeklySummaryFromJson(Map<String, dynamic> json) =>
    HabitWeeklySummary(
      habitId: json['habit_id'] as String,
      habitName: json['habit_name'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      daysCompleted: (json['days_completed'] as num?)?.toInt() ?? 0,
      daysScheduled: (json['days_scheduled'] as num?)?.toInt() ?? 7,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$HabitWeeklySummaryToJson(HabitWeeklySummary instance) =>
    <String, dynamic>{
      'habit_id': instance.habitId,
      'habit_name': instance.habitName,
      'week_start': instance.weekStart.toIso8601String(),
      'days_completed': instance.daysCompleted,
      'days_scheduled': instance.daysScheduled,
      'completion_rate': instance.completionRate,
      'current_streak': instance.currentStreak,
    };

HabitStreak _$HabitStreakFromJson(Map<String, dynamic> json) => HabitStreak(
  id: json['id'] as String,
  habitId: json['habit_id'] as String,
  userId: json['user_id'] as String,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  lastCompletedDate: json['last_completed_date'] == null
      ? null
      : DateTime.parse(json['last_completed_date'] as String),
  streakStartDate: json['streak_start_date'] == null
      ? null
      : DateTime.parse(json['streak_start_date'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$HabitStreakToJson(HabitStreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habit_id': instance.habitId,
      'user_id': instance.userId,
      'current_streak': instance.currentStreak,
      'longest_streak': instance.longestStreak,
      'last_completed_date': instance.lastCompletedDate?.toIso8601String(),
      'streak_start_date': instance.streakStartDate?.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

HabitSuggestionResponse _$HabitSuggestionResponseFromJson(
  Map<String, dynamic> json,
) => HabitSuggestionResponse(
  suggestedHabits:
      (json['suggested_habits'] as List<dynamic>?)
          ?.map((e) => HabitTemplate.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  reasoning: json['reasoning'] as String? ?? '',
);

Map<String, dynamic> _$HabitSuggestionResponseToJson(
  HabitSuggestionResponse instance,
) => <String, dynamic>{
  'suggested_habits': instance.suggestedHabits,
  'reasoning': instance.reasoning,
};

HabitCalendarData _$HabitCalendarDataFromJson(Map<String, dynamic> json) =>
    HabitCalendarData(
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$HabitCalendarDataToJson(HabitCalendarData instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'status': instance.status,
      'value': instance.value,
    };
