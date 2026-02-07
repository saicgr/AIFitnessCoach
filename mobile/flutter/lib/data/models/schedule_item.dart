import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_item.g.dart';

/// Type of schedule item
enum ScheduleItemType {
  @JsonValue('workout')
  workout,
  @JsonValue('activity')
  activity,
  @JsonValue('meal')
  meal,
  @JsonValue('fasting')
  fasting,
  @JsonValue('habit')
  habit,
}

/// Status of a schedule item
enum ScheduleItemStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('skipped')
  skipped,
  @JsonValue('missed')
  missed,
}

/// Meal type for meal schedule items
enum MealType {
  @JsonValue('breakfast')
  breakfast,
  @JsonValue('lunch')
  lunch,
  @JsonValue('dinner')
  dinner,
  @JsonValue('snack')
  snack,
}

/// Main schedule item model
@JsonSerializable()
class ScheduleItem {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'item_type')
  final ScheduleItemType itemType;
  final String title;
  final String? description;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'start_time')
  final String startTime; // "HH:MM"
  @JsonKey(name: 'end_time')
  final String? endTime;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  final ScheduleItemStatus status;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'habit_id')
  final String? habitId;
  @JsonKey(name: 'fasting_record_id')
  final String? fastingRecordId;
  @JsonKey(name: 'activity_type')
  final String? activityType;
  @JsonKey(name: 'activity_target')
  final String? activityTarget;
  @JsonKey(name: 'activity_icon')
  final String? activityIcon;
  @JsonKey(name: 'activity_color')
  final String? activityColor;
  @JsonKey(name: 'meal_type')
  final MealType? mealType;
  @JsonKey(name: 'is_recurring')
  final bool isRecurring;
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @JsonKey(name: 'notify_before_minutes')
  final int notifyBeforeMinutes;
  @JsonKey(name: 'google_calendar_event_id')
  final String? googleCalendarEventId;
  @JsonKey(name: 'google_calendar_synced_at')
  final DateTime? googleCalendarSyncedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const ScheduleItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.title,
    this.description,
    required this.scheduledDate,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.status = ScheduleItemStatus.scheduled,
    this.workoutId,
    this.habitId,
    this.fastingRecordId,
    this.activityType,
    this.activityTarget,
    this.activityIcon,
    this.activityColor,
    this.mealType,
    this.isRecurring = false,
    this.recurrenceRule,
    this.notifyBeforeMinutes = 15,
    this.googleCalendarEventId,
    this.googleCalendarSyncedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) =>
      _$ScheduleItemFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleItemToJson(this);

  ScheduleItem copyWith({
    String? id,
    String? userId,
    ScheduleItemType? itemType,
    String? title,
    String? description,
    DateTime? scheduledDate,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    ScheduleItemStatus? status,
    String? workoutId,
    String? habitId,
    String? fastingRecordId,
    String? activityType,
    String? activityTarget,
    String? activityIcon,
    String? activityColor,
    MealType? mealType,
    bool? isRecurring,
    String? recurrenceRule,
    int? notifyBeforeMinutes,
    String? googleCalendarEventId,
    DateTime? googleCalendarSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      workoutId: workoutId ?? this.workoutId,
      habitId: habitId ?? this.habitId,
      fastingRecordId: fastingRecordId ?? this.fastingRecordId,
      activityType: activityType ?? this.activityType,
      activityTarget: activityTarget ?? this.activityTarget,
      activityIcon: activityIcon ?? this.activityIcon,
      activityColor: activityColor ?? this.activityColor,
      mealType: mealType ?? this.mealType,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
      googleCalendarEventId:
          googleCalendarEventId ?? this.googleCalendarEventId,
      googleCalendarSyncedAt:
          googleCalendarSyncedAt ?? this.googleCalendarSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Color associated with the item type
  Color get typeColor {
    switch (itemType) {
      case ScheduleItemType.workout:
        return const Color(0xFF06B6D4);
      case ScheduleItemType.activity:
        return const Color(0xFF3B82F6);
      case ScheduleItemType.meal:
        return const Color(0xFF22C55E);
      case ScheduleItemType.fasting:
        return const Color(0xFFF97316);
      case ScheduleItemType.habit:
        return const Color(0xFFA855F7);
    }
  }

  /// Icon associated with the item type
  IconData get typeIcon {
    switch (itemType) {
      case ScheduleItemType.workout:
        return Icons.fitness_center;
      case ScheduleItemType.activity:
        return Icons.directions_run;
      case ScheduleItemType.meal:
        return Icons.restaurant;
      case ScheduleItemType.fasting:
        return Icons.timer;
      case ScheduleItemType.habit:
        return Icons.check_circle_outline;
    }
  }
}

/// Request model for creating a schedule item
class ScheduleItemCreate {
  final String title;
  final ScheduleItemType itemType;
  final DateTime scheduledDate;
  final String startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? description;
  final String? workoutId;
  final String? habitId;
  final String? fastingRecordId;
  final String? activityType;
  final String? activityTarget;
  final String? activityIcon;
  final String? activityColor;
  final MealType? mealType;
  final bool isRecurring;
  final String? recurrenceRule;
  final int notifyBeforeMinutes;
  final bool syncToGoogleCalendar;

  const ScheduleItemCreate({
    required this.title,
    required this.itemType,
    required this.scheduledDate,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.description,
    this.workoutId,
    this.habitId,
    this.fastingRecordId,
    this.activityType,
    this.activityTarget,
    this.activityIcon,
    this.activityColor,
    this.mealType,
    this.isRecurring = false,
    this.recurrenceRule,
    this.notifyBeforeMinutes = 15,
    this.syncToGoogleCalendar = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'item_type': itemType.name,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (description != null) 'description': description,
        if (workoutId != null) 'workout_id': workoutId,
        if (habitId != null) 'habit_id': habitId,
        if (fastingRecordId != null) 'fasting_record_id': fastingRecordId,
        if (activityType != null) 'activity_type': activityType,
        if (activityTarget != null) 'activity_target': activityTarget,
        if (activityIcon != null) 'activity_icon': activityIcon,
        if (activityColor != null) 'activity_color': activityColor,
        if (mealType != null) 'meal_type': mealType!.name,
        'is_recurring': isRecurring,
        if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
        'notify_before_minutes': notifyBeforeMinutes,
        'sync_to_google_calendar': syncToGoogleCalendar,
      };
}

/// Response model for daily schedule
@JsonSerializable()
class DailyScheduleResponse {
  final DateTime date;
  final List<ScheduleItem> items;
  final Map<String, dynamic> summary;

  const DailyScheduleResponse({
    required this.date,
    this.items = const [],
    this.summary = const {},
  });

  factory DailyScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyScheduleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DailyScheduleResponseToJson(this);

  int get totalItems => summary['total_items'] as int? ?? items.length;
  int get completed => summary['completed'] as int? ?? 0;
  int get upcoming => summary['upcoming'] as int? ?? 0;
}

/// Response model for up-next items
@JsonSerializable()
class UpNextResponse {
  final List<ScheduleItem> items;
  @JsonKey(name: 'as_of')
  final DateTime asOf;

  const UpNextResponse({
    this.items = const [],
    required this.asOf,
  });

  factory UpNextResponse.fromJson(Map<String, dynamic> json) =>
      _$UpNextResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UpNextResponseToJson(this);
}
