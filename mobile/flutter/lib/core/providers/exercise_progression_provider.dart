import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/set_progression.dart';

/// Provider for per-exercise progression model preferences.
///
/// Persists the user's chosen progression pattern (pyramid up, drop sets, etc.)
/// for each exercise to SharedPreferences. When the same exercise appears in
/// a future workout, the saved pattern is automatically loaded.
final exerciseProgressionProvider = StateNotifierProvider<
    ExerciseProgressionNotifier, Map<String, SetProgressionPattern>>((ref) {
  return ExerciseProgressionNotifier();
});

class ExerciseProgressionNotifier
    extends StateNotifier<Map<String, SetProgressionPattern>> {
  static const String _keyPrefix = 'progression_model_';

  ExerciseProgressionNotifier() : super({});

  /// Normalize exercise name for consistent key lookup.
  static String _normalize(String exerciseName) {
    return exerciseName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get the progression pattern for an exercise, loading from disk if needed.
  ///
  /// Returns [SetProgressionPattern.pyramidUp] if no preference is saved.
  Future<SetProgressionPattern> getPattern(String exerciseName) async {
    final key = _normalize(exerciseName);

    // Check in-memory cache first
    if (state.containsKey(key)) {
      return state[key]!;
    }

    // Load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_keyPrefix$key');
      if (stored != null) {
        final pattern = SetProgressionPatternX.fromStorageKey(stored);
        state = {...state, key: pattern};
        return pattern;
      }
    } catch (e) {
      debugPrint('❌ [ExerciseProgression] Error loading pattern for $exerciseName: $e');
    }

    return SetProgressionPattern.pyramidUp; // Default
  }

  /// Set the progression pattern for an exercise and persist to disk.
  Future<void> setPattern(String exerciseName, SetProgressionPattern pattern) async {
    final key = _normalize(exerciseName);
    state = {...state, key: pattern};

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$key', pattern.storageKey);
      debugPrint('✅ [ExerciseProgression] Saved $pattern for $exerciseName');
    } catch (e) {
      debugPrint('❌ [ExerciseProgression] Error saving pattern: $e');
    }
  }

  /// Get the cached pattern synchronously (returns default if not loaded yet).
  SetProgressionPattern getPatternSync(String exerciseName) {
    final key = _normalize(exerciseName);
    return state[key] ?? SetProgressionPattern.pyramidUp;
  }

  /// Preload patterns for a list of exercise names (call at workout start).
  Future<void> preloadPatterns(List<String> exerciseNames) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updates = <String, SetProgressionPattern>{};

      for (final name in exerciseNames) {
        final key = _normalize(name);
        if (!state.containsKey(key)) {
          final stored = prefs.getString('$_keyPrefix$key');
          if (stored != null) {
            updates[key] = SetProgressionPatternX.fromStorageKey(stored);
          }
        }
      }

      if (updates.isNotEmpty) {
        state = {...state, ...updates};
        debugPrint('✅ [ExerciseProgression] Preloaded ${updates.length} patterns');
      }
    } catch (e) {
      debugPrint('❌ [ExerciseProgression] Error preloading: $e');
    }
  }
}
