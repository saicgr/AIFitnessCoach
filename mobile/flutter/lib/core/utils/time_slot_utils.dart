import 'package:flutter/material.dart';

/// Time slots for workout preferences
enum TimeSlot {
  earlyMorning,
  morning,
  afternoon,
  evening,
  night,
}

/// Extension methods for TimeSlot enum
extension TimeSlotExtension on TimeSlot {
  /// Database value for this time slot
  String get value => switch (this) {
        TimeSlot.earlyMorning => 'early_morning',
        TimeSlot.morning => 'morning',
        TimeSlot.afternoon => 'afternoon',
        TimeSlot.evening => 'evening',
        TimeSlot.night => 'night',
      };

  /// User-friendly label
  String get label => switch (this) {
        TimeSlot.earlyMorning => 'Early Morning',
        TimeSlot.morning => 'Morning',
        TimeSlot.afternoon => 'Afternoon',
        TimeSlot.evening => 'Evening',
        TimeSlot.night => 'Night',
      };

  /// Short label for compact display
  String get shortLabel => switch (this) {
        TimeSlot.earlyMorning => 'Early AM',
        TimeSlot.morning => 'Morning',
        TimeSlot.afternoon => 'Afternoon',
        TimeSlot.evening => 'Evening',
        TimeSlot.night => 'Night',
      };

  /// Time range description
  String get timeRange => switch (this) {
        TimeSlot.earlyMorning => '5 AM - 7 AM',
        TimeSlot.morning => '7 AM - 11 AM',
        TimeSlot.afternoon => '11 AM - 4 PM',
        TimeSlot.evening => '4 PM - 8 PM',
        TimeSlot.night => '8 PM - 12 AM',
      };

  /// Material icon for this time slot
  IconData get icon => switch (this) {
        TimeSlot.earlyMorning => Icons.wb_twilight_rounded,
        TimeSlot.morning => Icons.wb_sunny_rounded,
        TimeSlot.afternoon => Icons.wb_cloudy_rounded,
        TimeSlot.evening => Icons.nightlight_round,
        TimeSlot.night => Icons.dark_mode_rounded,
      };

  /// Color associated with this time slot
  Color get color => switch (this) {
        TimeSlot.earlyMorning => const Color(0xFFFF9800), // Orange
        TimeSlot.morning => const Color(0xFFFFEB3B), // Yellow
        TimeSlot.afternoon => const Color(0xFF03A9F4), // Light Blue
        TimeSlot.evening => const Color(0xFF673AB7), // Deep Purple
        TimeSlot.night => const Color(0xFF1A237E), // Indigo
      };

  /// Start hour for this time slot (24-hour format)
  int get startHour => switch (this) {
        TimeSlot.earlyMorning => 5,
        TimeSlot.morning => 7,
        TimeSlot.afternoon => 11,
        TimeSlot.evening => 16,
        TimeSlot.night => 20,
      };

  /// End hour for this time slot (24-hour format)
  int get endHour => switch (this) {
        TimeSlot.earlyMorning => 7,
        TimeSlot.morning => 11,
        TimeSlot.afternoon => 16,
        TimeSlot.evening => 20,
        TimeSlot.night => 24,
      };
}

/// Utility class for time slot operations
class TimeSlotUtils {
  TimeSlotUtils._();

  /// Get the current time slot based on device time
  static TimeSlot getCurrentTimeSlot() {
    final hour = DateTime.now().hour;
    return getTimeSlotForHour(hour);
  }

  /// Get time slot for a specific hour (0-23)
  static TimeSlot getTimeSlotForHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeSlot.earlyMorning;
    if (hour >= 7 && hour < 11) return TimeSlot.morning;
    if (hour >= 11 && hour < 16) return TimeSlot.afternoon;
    if (hour >= 16 && hour < 20) return TimeSlot.evening;
    // Night: 8 PM - 12 AM and 12 AM - 5 AM (wraps around midnight)
    return TimeSlot.night;
  }

  /// Parse time slot from database value string
  static TimeSlot? fromValue(String? value) {
    if (value == null) return null;
    return switch (value) {
      'early_morning' => TimeSlot.earlyMorning,
      'morning' => TimeSlot.morning,
      'afternoon' => TimeSlot.afternoon,
      'evening' => TimeSlot.evening,
      'night' => TimeSlot.night,
      _ => null,
    };
  }

  /// Get label for a database value string
  static String? getLabelForValue(String? value) {
    return fromValue(value)?.label;
  }

  /// Get icon for a database value string
  static IconData? getIconForValue(String? value) {
    return fromValue(value)?.icon;
  }

  /// Get all time slots in order
  static List<TimeSlot> get allSlots => TimeSlot.values;

  /// Check if a given hour falls within a time slot
  static bool isHourInSlot(int hour, TimeSlot slot) {
    if (slot == TimeSlot.night) {
      // Night wraps around midnight
      return hour >= 20 || hour < 5;
    }
    return hour >= slot.startHour && hour < slot.endHour;
  }

  /// Check if current time matches the given time slot
  static bool isCurrentTimeInSlot(TimeSlot slot) {
    return getCurrentTimeSlot() == slot;
  }

  /// Check if current time matches the given database value
  static bool isCurrentTimeInSlotValue(String? value) {
    if (value == null) return false;
    final slot = fromValue(value);
    return slot != null && isCurrentTimeInSlot(slot);
  }
}
