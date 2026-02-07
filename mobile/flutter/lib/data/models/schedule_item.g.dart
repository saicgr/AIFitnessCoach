// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleItem _$ScheduleItemFromJson(Map<String, dynamic> json) => ScheduleItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: $enumDecode(_$ScheduleItemTypeEnumMap, json['item_type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      status: $enumDecodeNullable(_$ScheduleItemStatusEnumMap, json['status']) ??
          ScheduleItemStatus.scheduled,
      workoutId: json['workout_id'] as String?,
      habitId: json['habit_id'] as String?,
      fastingRecordId: json['fasting_record_id'] as String?,
      activityType: json['activity_type'] as String?,
      activityTarget: json['activity_target'] as String?,
      activityIcon: json['activity_icon'] as String?,
      activityColor: json['activity_color'] as String?,
      mealType: $enumDecodeNullable(_$MealTypeEnumMap, json['meal_type']),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
      notifyBeforeMinutes:
          (json['notify_before_minutes'] as num?)?.toInt() ?? 15,
      googleCalendarEventId:
          json['google_calendar_event_id'] as String?,
      googleCalendarSyncedAt: json['google_calendar_synced_at'] == null
          ? null
          : DateTime.parse(json['google_calendar_synced_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ScheduleItemToJson(ScheduleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'item_type': _$ScheduleItemTypeEnumMap[instance.itemType]!,
      'title': instance.title,
      'description': instance.description,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'duration_minutes': instance.durationMinutes,
      'status': _$ScheduleItemStatusEnumMap[instance.status]!,
      'workout_id': instance.workoutId,
      'habit_id': instance.habitId,
      'fasting_record_id': instance.fastingRecordId,
      'activity_type': instance.activityType,
      'activity_target': instance.activityTarget,
      'activity_icon': instance.activityIcon,
      'activity_color': instance.activityColor,
      'meal_type': _$MealTypeEnumMap[instance.mealType],
      'is_recurring': instance.isRecurring,
      'recurrence_rule': instance.recurrenceRule,
      'notify_before_minutes': instance.notifyBeforeMinutes,
      'google_calendar_event_id': instance.googleCalendarEventId,
      'google_calendar_synced_at':
          instance.googleCalendarSyncedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ScheduleItemTypeEnumMap = {
  ScheduleItemType.workout: 'workout',
  ScheduleItemType.activity: 'activity',
  ScheduleItemType.meal: 'meal',
  ScheduleItemType.fasting: 'fasting',
  ScheduleItemType.habit: 'habit',
};

const _$ScheduleItemStatusEnumMap = {
  ScheduleItemStatus.scheduled: 'scheduled',
  ScheduleItemStatus.inProgress: 'in_progress',
  ScheduleItemStatus.completed: 'completed',
  ScheduleItemStatus.skipped: 'skipped',
  ScheduleItemStatus.missed: 'missed',
};

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};

DailyScheduleResponse _$DailyScheduleResponseFromJson(
        Map<String, dynamic> json) =>
    DailyScheduleResponse(
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      summary: json['summary'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$DailyScheduleResponseToJson(
        DailyScheduleResponse instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'summary': instance.summary,
    };

UpNextResponse _$UpNextResponseFromJson(Map<String, dynamic> json) =>
    UpNextResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      asOf: DateTime.parse(json['as_of'] as String),
    );

Map<String, dynamic> _$UpNextResponseToJson(UpNextResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'as_of': instance.asOf.toIso8601String(),
    };
