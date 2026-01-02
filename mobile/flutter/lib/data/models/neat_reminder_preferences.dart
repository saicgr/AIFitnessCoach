/// NEAT reminder preferences models.
///
/// These models support:
/// - Movement reminder configuration
/// - Quiet hours and work hours settings
/// - Reminder interval customization
/// - Step threshold triggers
library;

import 'package:json_annotation/json_annotation.dart';

part 'neat_reminder_preferences.g.dart';

/// User's NEAT reminder preferences
@JsonSerializable()
class NeatReminderPreferences {
  final String? id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'reminders_enabled')
  final bool remindersEnabled;

  @JsonKey(name: 'reminder_interval_minutes')
  final int reminderIntervalMinutes;

  @JsonKey(name: 'steps_threshold')
  final int stepsThreshold;

  @JsonKey(name: 'quiet_hours_enabled')
  final bool quietHoursEnabled;

  @JsonKey(name: 'quiet_hours_start')
  final String quietHoursStart;

  @JsonKey(name: 'quiet_hours_end')
  final String quietHoursEnd;

  @JsonKey(name: 'work_hours_only')
  final bool workHoursOnly;

  @JsonKey(name: 'work_hours_start')
  final String workHoursStart;

  @JsonKey(name: 'work_hours_end')
  final String workHoursEnd;

  @JsonKey(name: 'vibration_enabled')
  final bool vibrationEnabled;

  @JsonKey(name: 'sound_enabled')
  final bool soundEnabled;

  @JsonKey(name: 'smart_reminders')
  final bool smartReminders;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const NeatReminderPreferences({
    this.id,
    required this.userId,
    this.remindersEnabled = true,
    this.reminderIntervalMinutes = 60,
    this.stepsThreshold = 250,
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.workHoursOnly = false,
    this.workHoursStart = '09:00',
    this.workHoursEnd = '17:00',
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.smartReminders = true,
    this.createdAt,
    this.updatedAt,
  });

  factory NeatReminderPreferences.fromJson(Map<String, dynamic> json) =>
      _$NeatReminderPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NeatReminderPreferencesToJson(this);

  /// Parse time string to TimeOfDay-like values
  static ({int hour, int minute}) _parseTime(String time) {
    final parts = time.split(':');
    return (
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  /// Get quiet hours start as hour and minute
  ({int hour, int minute}) get quietStart => _parseTime(quietHoursStart);

  /// Get quiet hours end as hour and minute
  ({int hour, int minute}) get quietEnd => _parseTime(quietHoursEnd);

  /// Get work hours start as hour and minute
  ({int hour, int minute}) get workStart => _parseTime(workHoursStart);

  /// Get work hours end as hour and minute
  ({int hour, int minute}) get workEnd => _parseTime(workHoursEnd);

  /// Check if a given time is within quiet hours
  bool isQuietTime(DateTime time) {
    if (!quietHoursEnabled) return false;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = quietStart.hour * 60 + quietStart.minute;
    final endMinutes = quietEnd.hour * 60 + quietEnd.minute;

    // Handle overnight quiet hours (e.g., 22:00 to 07:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Check if a given time is within work hours
  bool isWorkTime(DateTime time) {
    if (!workHoursOnly) return true;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = workStart.hour * 60 + workStart.minute;
    final endMinutes = workEnd.hour * 60 + workEnd.minute;

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  /// Check if reminders should be active at a given time
  bool shouldRemindAt(DateTime time) {
    if (!remindersEnabled) return false;
    if (isQuietTime(time)) return false;
    if (workHoursOnly && !isWorkTime(time)) return false;
    return true;
  }

  /// Get formatted quiet hours display
  String get quietHoursDisplay => '$quietHoursStart - $quietHoursEnd';

  /// Get formatted work hours display
  String get workHoursDisplay => '$workHoursStart - $workHoursEnd';

  /// Get reminder interval in hours for display
  String get intervalDisplay {
    if (reminderIntervalMinutes >= 60) {
      final hours = reminderIntervalMinutes / 60;
      return hours == 1 ? 'Every hour' : 'Every ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} hours';
    }
    return 'Every $reminderIntervalMinutes minutes';
  }

  /// Create a copy with updated values
  NeatReminderPreferences copyWith({
    String? id,
    String? userId,
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    int? stepsThreshold,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? workHoursOnly,
    String? workHoursStart,
    String? workHoursEnd,
    bool? vibrationEnabled,
    bool? soundEnabled,
    bool? smartReminders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeatReminderPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      stepsThreshold: stepsThreshold ?? this.stepsThreshold,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      workHoursOnly: workHoursOnly ?? this.workHoursOnly,
      workHoursStart: workHoursStart ?? this.workHoursStart,
      workHoursEnd: workHoursEnd ?? this.workHoursEnd,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      smartReminders: smartReminders ?? this.smartReminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Predefined reminder interval options
enum ReminderIntervalOption {
  thirtyMinutes(30, '30 minutes'),
  fortyFiveMinutes(45, '45 minutes'),
  oneHour(60, '1 hour'),
  ninetyMinutes(90, '1.5 hours'),
  twoHours(120, '2 hours');

  final int minutes;
  final String displayName;

  const ReminderIntervalOption(this.minutes, this.displayName);
}

/// Predefined step threshold options
enum StepThresholdOption {
  low(100, '100 steps', 'Very sensitive'),
  medium(250, '250 steps', 'Recommended'),
  high(500, '500 steps', 'Less frequent'),
  veryHigh(750, '750 steps', 'Minimal');

  final int steps;
  final String displayName;
  final String description;

  const StepThresholdOption(this.steps, this.displayName, this.description);
}

/// Reminder settings update response
@JsonSerializable()
class NeatReminderUpdateResponse {
  final bool success;
  final NeatReminderPreferences? preferences;
  final String? message;

  const NeatReminderUpdateResponse({
    this.success = false,
    this.preferences,
    this.message,
  });

  factory NeatReminderUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$NeatReminderUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NeatReminderUpdateResponseToJson(this);
}
