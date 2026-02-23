import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for Beast Mode unlock state.
///
/// Persisted via SharedPreferences under key 'beast_mode_unlocked'.
/// Unlocked by tapping the version label 7 times in settings.
final beastModeProvider =
    StateNotifierProvider<BeastModeNotifier, bool>((ref) {
  return BeastModeNotifier();
});

class BeastModeNotifier extends StateNotifier<bool> {
  static const String _prefsKey = 'beast_mode_unlocked';

  BeastModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    state = true;
  }

  Future<void> lock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
    state = false;
  }
}
