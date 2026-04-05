part of 'xp_provider.dart';


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

