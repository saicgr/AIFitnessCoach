import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for per-exercise bar type preferences.
///
/// Persists the user's chosen bar type (standard, women's, EZ curl, etc.)
/// for each exercise to SharedPreferences. When the same exercise appears
/// in a future workout, the saved bar type is automatically loaded.
final exerciseBarTypeProvider = StateNotifierProvider<
    ExerciseBarTypeNotifier, Map<String, String>>((ref) {
  return ExerciseBarTypeNotifier();
});

class ExerciseBarTypeNotifier extends StateNotifier<Map<String, String>> {
  static const String _keyPrefix = 'bar_type_';

  ExerciseBarTypeNotifier() : super({});

  static String _normalize(String exerciseName) {
    return exerciseName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get the bar type for an exercise, loading from disk if needed.
  /// Returns null if no preference is saved (auto-detect from equipment).
  Future<String?> getBarType(String exerciseName) async {
    final key = _normalize(exerciseName);

    if (state.containsKey(key)) {
      return state[key];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_keyPrefix$key');
      if (stored != null) {
        state = {...state, key: stored};
        return stored;
      }
    } catch (e) {
      debugPrint('❌ [ExerciseBarType] Error loading bar type for $exerciseName: $e');
    }

    return null;
  }

  /// Set the bar type for an exercise and persist to disk.
  Future<void> setBarType(String exerciseName, String barType) async {
    final key = _normalize(exerciseName);
    state = {...state, key: barType};

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$key', barType);
      debugPrint('✅ [ExerciseBarType] Saved $barType for $exerciseName');
    } catch (e) {
      debugPrint('❌ [ExerciseBarType] Error saving bar type: $e');
    }
  }

  /// Get the cached bar type synchronously (returns null if not loaded).
  String? getBarTypeSync(String exerciseName) {
    final key = _normalize(exerciseName);
    return state[key];
  }

  /// Preload bar types for a list of exercise names (call at workout start).
  Future<void> preloadBarTypes(List<String> exerciseNames) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updates = <String, String>{};

      for (final name in exerciseNames) {
        final key = _normalize(name);
        if (!state.containsKey(key)) {
          final stored = prefs.getString('$_keyPrefix$key');
          if (stored != null) {
            updates[key] = stored;
          }
        }
      }

      if (updates.isNotEmpty) {
        state = {...state, ...updates};
        debugPrint('✅ [ExerciseBarType] Preloaded ${updates.length} bar types');
      }
    } catch (e) {
      debugPrint('❌ [ExerciseBarType] Error preloading: $e');
    }
  }
}
