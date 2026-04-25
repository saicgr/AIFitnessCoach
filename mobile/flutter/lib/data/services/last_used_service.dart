import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/accessibility/accessibility_provider.dart' show sharedPreferencesProvider;

/// Persists the user's most recent choice across small-set picker UIs (share
/// period, meal type, food browser tab, fasting protocol, RPE chip per
/// exercise, food input method, regen sheet sub-pickers).
///
/// Reads/writes are synchronous-ish (set returns Future; gets are sync against
/// the in-memory cache that SharedPreferences keeps after first load).
class LastUsedService {
  static const _prefix = 'lastUsed::';
  final SharedPreferences _prefs;

  const LastUsedService(this._prefs);

  String? get(String feature) => _prefs.getString('$_prefix$feature');

  Future<void> set(String feature, String value) =>
      _prefs.setString('$_prefix$feature', value);

  Future<void> clear(String feature) => _prefs.remove('$_prefix$feature');
}

final lastUsedServiceProvider = Provider<LastUsedService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LastUsedService(prefs);
});
