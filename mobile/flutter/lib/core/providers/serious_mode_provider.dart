/// Serious Mode provider.
///
/// When enabled:
///   - You Hub defaults to the Profile tab (not Overview) so the first
///     thing a serious lifter sees is their profile, not gamification.
///   - Home streak strip is suppressed.
///   - Celebration animations (level-up confetti, trophy pop-ins) are muted.
///   - Overview tab still renders, just with subdued styling (accent tone
///     dialed down — future hook).
///
/// Stored in SharedPreferences under `serious_mode_v1`. Persists across
/// launches. Default: off — the gamified experience is FitWiz's retention
/// engine and should be the default per project_gamification_role.md.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final seriousModeProvider =
    StateNotifierProvider<SeriousModeNotifier, bool>((ref) {
  return SeriousModeNotifier();
});

class SeriousModeNotifier extends StateNotifier<bool> {
  static const _key = 'serious_mode_v1';

  SeriousModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('❌ [SeriousMode] load failed: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (e) {
      debugPrint('❌ [SeriousMode] save failed: $e');
    }
  }

  Future<void> toggle() => setEnabled(!state);
}
