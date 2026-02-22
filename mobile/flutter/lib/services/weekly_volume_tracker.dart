import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks weekly training volume (sets per muscle group) using
/// SharedPreferences with ISO week-based keys that auto-reset.
///
/// Key format: `weekly_volume_YYYY_WW` (e.g., `weekly_volume_2026_08`)
class WeeklyVolumeTracker {
  /// Get current week's volume for all tracked muscles.
  ///
  /// Returns a map of muscle name -> sets completed this week.
  static Future<Map<String, int>> getCurrentWeekVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentWeekKey();
    final raw = prefs.getString(key);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// Record volume from a completed workout.
  ///
  /// [muscleSetCounts] maps muscle name (lowercase) to sets performed.
  static Future<void> recordWorkoutVolume(
    Map<String, int> muscleSetCounts,
  ) async {
    if (muscleSetCounts.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _currentWeekKey();
    final current = await getCurrentWeekVolume();

    for (final entry in muscleSetCounts.entries) {
      final muscle = entry.key.toLowerCase();
      current[muscle] = (current[muscle] ?? 0) + entry.value;
    }

    await prefs.setString(key, jsonEncode(current));

    // Clean up old week keys (keep only current + previous week)
    await _cleanupOldKeys(prefs);
  }

  /// Get volume for a specific muscle this week.
  static Future<int> getMuscleVolume(String muscle) async {
    final volume = await getCurrentWeekVolume();
    return volume[muscle.toLowerCase()] ?? 0;
  }

  /// Generate the SharedPreferences key for the current ISO week.
  static String _currentWeekKey() {
    final now = DateTime.now();
    final isoWeek = _isoWeekNumber(now);
    return 'weekly_volume_${now.year}_${isoWeek.toString().padLeft(2, '0')}';
  }

  /// Calculate ISO week number for a date.
  static int _isoWeekNumber(DateTime date) {
    // ISO 8601: week starts Monday, first week contains January 4
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final dayOfWeek = date.weekday; // 1=Mon, 7=Sun
    final weekNumber = ((dayOfYear - dayOfWeek + 10) / 7).floor();

    if (weekNumber < 1) {
      // Last week of previous year
      return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    }
    if (weekNumber > 52) {
      // Check if it's actually week 1 of next year
      final dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday < 4) return 1;
    }
    return weekNumber;
  }

  /// Record SFR-adjusted fatigue volume from a workout.
  /// [muscleFatigueSets] maps muscle (lowercase) to fatigue-adjusted set count.
  static Future<void> recordWorkoutVolumeSfr(
    Map<String, double> muscleFatigueSets,
  ) async {
    if (muscleFatigueSets.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '${_currentWeekKey()}_sfr';
    final current = await getCurrentWeekFatigueSets();

    for (final entry in muscleFatigueSets.entries) {
      final muscle = entry.key.toLowerCase();
      current[muscle] = (current[muscle] ?? 0.0) + entry.value;
    }

    await prefs.setString(key, jsonEncode(current));
  }

  /// Get current week's fatigue-adjusted volume for all muscles.
  static Future<Map<String, double>> getCurrentWeekFatigueSets() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_currentWeekKey()}_sfr';
    final raw = prefs.getString(key);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// Clean up SharedPreferences keys from weeks older than 2 weeks ago.
  static Future<void> _cleanupOldKeys(SharedPreferences prefs) async {
    final currentKey = _currentWeekKey();
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final lastWeekKey =
        'weekly_volume_${lastWeek.year}_${_isoWeekNumber(lastWeek).toString().padLeft(2, '0')}';

    final keepKeys = {
      currentKey, lastWeekKey,
      '${currentKey}_sfr', '${lastWeekKey}_sfr',
    };

    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('weekly_volume_') && !keepKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}
