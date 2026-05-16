import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/accessibility/accessibility_provider.dart'
    show sharedPreferencesProvider;

/// Persists whether the hidden mini-games surface has been unlocked.
///
/// The mini-game (`NutrientRushGame`) is normally only reachable from one-shot
/// celebrations (level-up, trophy ceremony, weekly recap). A hidden easter-egg
/// — tapping the You-hub profile avatar 7 times rapidly — flips this flag,
/// after which a permanent "Mini-games" entry point appears in the You hub.
///
/// State is a single bool stored in SharedPreferences under
/// [_kUnlockedKey]. Once unlocked it never reverts.
class MinigameUnlockService {
  MinigameUnlockService(this._prefs);

  final SharedPreferences _prefs;

  /// SharedPreferences key for the unlock flag.
  static const String _kUnlockedKey = 'minigames_unlocked';

  /// Number of consecutive rapid taps required to trigger the unlock.
  static const int tapsToUnlock = 7;

  /// Whether the mini-games surface has been unlocked.
  bool get isUnlocked => _prefs.getBool(_kUnlockedKey) ?? false;

  /// Persists the unlock. Idempotent — safe to call when already unlocked.
  Future<void> unlock() async {
    if (isUnlocked) return;
    await _prefs.setBool(_kUnlockedKey, true);
    debugPrint('🎮 [MinigameUnlock] Mini-games unlocked');
  }
}

/// Provider for [MinigameUnlockService].
///
/// Depends on [sharedPreferencesProvider] which must be overridden at app
/// startup (it is — see main.dart's ProviderScope overrides).
final minigameUnlockServiceProvider = Provider<MinigameUnlockService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MinigameUnlockService(prefs);
});

/// Reactive unlock-state notifier so UI (You hub, settings) can rebuild the
/// instant the easter-egg fires without needing a manual provider refresh.
class MinigameUnlockNotifier extends StateNotifier<bool> {
  MinigameUnlockNotifier(this._service) : super(_service.isUnlocked);

  final MinigameUnlockService _service;

  /// Persist + broadcast the unlock. No-op if already unlocked.
  Future<void> unlock() async {
    if (state) return;
    await _service.unlock();
    state = true;
  }
}

/// Reactive `bool` — `true` once the mini-games surface is unlocked.
final minigameUnlockedProvider =
    StateNotifierProvider<MinigameUnlockNotifier, bool>((ref) {
  return MinigameUnlockNotifier(ref.watch(minigameUnlockServiceProvider));
});
