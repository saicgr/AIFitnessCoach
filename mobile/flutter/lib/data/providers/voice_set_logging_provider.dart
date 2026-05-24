import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User toggle for the active-workout voice mic FAB (Phase J).
///
/// Default OFF — voice logging is opt-in because gym ambient noise can
/// reduce accuracy. The settings tile explains "Best with headphones."
///
/// SharedPreferences key: `voice_set_logging_enabled`.
class VoiceSetLoggingEnabledNotifier extends StateNotifier<bool> {
  static const _prefsKey = 'voice_set_logging_enabled';

  VoiceSetLoggingEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> toggle() => setEnabled(!state);
}

final voiceSetLoggingEnabledProvider =
    StateNotifierProvider<VoiceSetLoggingEnabledNotifier, bool>((ref) {
  return VoiceSetLoggingEnabledNotifier();
});
