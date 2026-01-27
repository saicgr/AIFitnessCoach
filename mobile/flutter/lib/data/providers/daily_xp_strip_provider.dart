import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences
const String _kDailyXPStripEnabled = 'daily_xp_strip_enabled';
const String _kDailyXPStripDismissedDate = 'daily_xp_strip_dismissed_date';

/// Provider for whether the daily XP strip is permanently enabled in settings
/// Default is true (enabled)
final dailyXPStripEnabledProvider =
    StateNotifierProvider<DailyXPStripEnabledNotifier, bool>((ref) {
  return DailyXPStripEnabledNotifier();
});

/// Provider for whether the strip is dismissed for today
/// Resets at midnight
final dailyXPStripDismissedTodayProvider =
    StateNotifierProvider<DailyXPStripDismissedNotifier, bool>((ref) {
  return DailyXPStripDismissedNotifier();
});

/// Combined provider that determines if the strip should be visible
/// Returns true only if enabled in settings AND not dismissed for today
final dailyXPStripVisibleProvider = Provider<bool>((ref) {
  final enabled = ref.watch(dailyXPStripEnabledProvider);
  final dismissedToday = ref.watch(dailyXPStripDismissedTodayProvider);
  return enabled && !dismissedToday;
});

/// Notifier for the permanent enable/disable setting
class DailyXPStripEnabledNotifier extends StateNotifier<bool> {
  DailyXPStripEnabledNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kDailyXPStripEnabled) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyXPStripEnabled, enabled);
    state = enabled;
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

/// Notifier for the daily dismiss state
class DailyXPStripDismissedNotifier extends StateNotifier<bool> {
  DailyXPStripDismissedNotifier() : super(false) {
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDateStr = prefs.getString(_kDailyXPStripDismissedDate);

    if (dismissedDateStr != null) {
      final today = _getTodayKey();
      // Only keep dismissed if it was dismissed today
      state = dismissedDateStr == today;
    } else {
      state = false;
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Dismiss the strip for the rest of today
  Future<void> dismissForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    await prefs.setString(_kDailyXPStripDismissedDate, today);
    state = true;
  }

  /// Reset dismissed state (called when opening the app on a new day)
  Future<void> resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDateStr = prefs.getString(_kDailyXPStripDismissedDate);

    if (dismissedDateStr != null) {
      final today = _getTodayKey();
      if (dismissedDateStr != today) {
        // New day - reset the dismissed state
        await prefs.remove(_kDailyXPStripDismissedDate);
        state = false;
      }
    }
  }
}
