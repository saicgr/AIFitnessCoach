// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neat_reminder_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeatReminderPreferences _$NeatReminderPreferencesFromJson(
  Map<String, dynamic> json,
) => NeatReminderPreferences(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  remindersEnabled: json['reminders_enabled'] as bool? ?? true,
  reminderIntervalMinutes:
      (json['reminder_interval_minutes'] as num?)?.toInt() ?? 60,
  stepsThreshold: (json['steps_threshold'] as num?)?.toInt() ?? 250,
  quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? true,
  quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
  quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00',
  workHoursOnly: json['work_hours_only'] as bool? ?? false,
  workHoursStart: json['work_hours_start'] as String? ?? '09:00',
  workHoursEnd: json['work_hours_end'] as String? ?? '17:00',
  vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
  soundEnabled: json['sound_enabled'] as bool? ?? false,
  smartReminders: json['smart_reminders'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NeatReminderPreferencesToJson(
  NeatReminderPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'reminders_enabled': instance.remindersEnabled,
  'reminder_interval_minutes': instance.reminderIntervalMinutes,
  'steps_threshold': instance.stepsThreshold,
  'quiet_hours_enabled': instance.quietHoursEnabled,
  'quiet_hours_start': instance.quietHoursStart,
  'quiet_hours_end': instance.quietHoursEnd,
  'work_hours_only': instance.workHoursOnly,
  'work_hours_start': instance.workHoursStart,
  'work_hours_end': instance.workHoursEnd,
  'vibration_enabled': instance.vibrationEnabled,
  'sound_enabled': instance.soundEnabled,
  'smart_reminders': instance.smartReminders,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

NeatReminderUpdateResponse _$NeatReminderUpdateResponseFromJson(
  Map<String, dynamic> json,
) => NeatReminderUpdateResponse(
  success: json['success'] as bool? ?? false,
  preferences: json['preferences'] == null
      ? null
      : NeatReminderPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>,
        ),
  message: json['message'] as String?,
);

Map<String, dynamic> _$NeatReminderUpdateResponseToJson(
  NeatReminderUpdateResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'preferences': instance.preferences,
  'message': instance.message,
};
