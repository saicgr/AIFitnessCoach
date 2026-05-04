import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether Health-Connect / Apple-Health-synced workouts surface in the home
/// carousel. Defaults to `false` — synced workouts always live in the
/// "Synced Workouts" history tab, the carousel is intentionally noise-free
/// unless the user opts in via the home overflow menu.
const String _showSyncedInCarouselKey = 'home_carousel_show_synced';

final showSyncedInCarouselProvider =
    StateNotifierProvider<ShowSyncedInCarouselNotifier, bool>((ref) {
  return ShowSyncedInCarouselNotifier();
});

class ShowSyncedInCarouselNotifier extends StateNotifier<bool> {
  ShowSyncedInCarouselNotifier() : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_showSyncedInCarouselKey) ?? false;
    } catch (e) {
      debugPrint('❌ [SyncedVisibility] Failed to load preference: $e');
    }
  }

  Future<void> setVisible(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showSyncedInCarouselKey, value);
    } catch (e) {
      debugPrint('❌ [SyncedVisibility] Failed to save preference: $e');
    }
  }

  Future<void> toggle() async {
    await setVisible(!state);
  }
}
