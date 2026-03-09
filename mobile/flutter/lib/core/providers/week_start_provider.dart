import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the week display starts on Sunday (true) or Monday (false).
const String _weekStartsSundayKey = 'week_starts_sunday';

/// Provider for the week-start preference.
final weekStartsSundayProvider =
    StateNotifierProvider<WeekStartNotifier, bool>((ref) {
  return WeekStartNotifier();
});

class WeekStartNotifier extends StateNotifier<bool> {
  WeekStartNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_weekStartsSundayKey) ?? false;
    } catch (e) {
      debugPrint('❌ [WeekStart] Failed to load preference: $e');
    }
  }

  Future<void> setStartsSunday(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_weekStartsSundayKey, value);
    } catch (e) {
      debugPrint('❌ [WeekStart] Failed to save preference: $e');
    }
  }

  Future<void> toggle() async {
    await setStartsSunday(!state);
  }
}

/// Helper that returns display-order constants based on the preference.
///
/// When Sunday-first: display order [6,0,1,2,3,4,5], labels S M T W T F S
/// When Monday-first: display order [0,1,2,3,4,5,6], labels M T W T F S S
class WeekDisplayConfig {
  final List<int> displayOrder;
  final List<String> dayLabels;
  final bool startsSunday;

  const WeekDisplayConfig._({
    required this.displayOrder,
    required this.dayLabels,
    required this.startsSunday,
  });

  factory WeekDisplayConfig.from(bool startsSunday) {
    if (startsSunday) {
      return const WeekDisplayConfig._(
        displayOrder: [6, 0, 1, 2, 3, 4, 5],
        dayLabels: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        startsSunday: true,
      );
    }
    return const WeekDisplayConfig._(
      displayOrder: [0, 1, 2, 3, 4, 5, 6],
      dayLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      startsSunday: false,
    );
  }

  /// The first day of the current week as a DateTime.
  DateTime weekStart(DateTime today) {
    if (startsSunday) {
      return today.subtract(Duration(days: today.weekday % 7));
    }
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Convert a data index (0=Mon..6=Sun) to a date within the current
  /// display-week anchored at [weekStartDate].
  DateTime dateForDataIndex(DateTime weekStartDate, int dataIndex) {
    if (startsSunday) {
      // Sunday is offset 0, Monday is offset 1, … Saturday is offset 6
      return weekStartDate.add(Duration(days: (dataIndex + 1) % 7));
    }
    // Monday-first: Monday is offset 0, … Sunday is offset 6
    return weekStartDate.add(Duration(days: dataIndex));
  }
}

/// Derived provider for the display config.
final weekDisplayConfigProvider = Provider<WeekDisplayConfig>((ref) {
  final startsSunday = ref.watch(weekStartsSundayProvider);
  return WeekDisplayConfig.from(startsSunday);
});
