import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How workouts are generated
enum WorkoutGenerationMode {
  /// Cloud AI (Gemini) - requires internet
  cloudAI,

  /// On-device AI (Gemma) - works offline, requires downloaded model
  onDeviceAI,

  /// Rule-based algorithm - works offline, no model needed
  ruleBased,
}

extension WorkoutGenerationModeExtension on WorkoutGenerationMode {
  String get displayName {
    switch (this) {
      case WorkoutGenerationMode.cloudAI:
        return 'Cloud AI';
      case WorkoutGenerationMode.onDeviceAI:
        return 'On-Device AI';
      case WorkoutGenerationMode.ruleBased:
        return 'Offline Rules';
    }
  }

  String get description {
    switch (this) {
      case WorkoutGenerationMode.cloudAI:
        return 'Best quality. Uses cloud AI for personalized workouts. Requires internet.';
      case WorkoutGenerationMode.onDeviceAI:
        return 'AI-powered workouts that work offline. Requires a downloaded model.';
      case WorkoutGenerationMode.ruleBased:
        return 'Algorithm-based workouts. Always available, no downloads needed.';
    }
  }

  bool get requiresInternet => this == WorkoutGenerationMode.cloudAI;

  bool get requiresModel => this == WorkoutGenerationMode.onDeviceAI;
}

/// Persists and manages the workout generation mode preference.
class GenerationModeNotifier extends StateNotifier<WorkoutGenerationMode> {
  static const String _prefsKey = 'workout_generation_mode';

  GenerationModeNotifier() : super(WorkoutGenerationMode.cloudAI) {
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getString(_prefsKey);
      if (savedValue != null) {
        final mode = WorkoutGenerationMode.values.firstWhere(
          (m) => m.name == savedValue,
          orElse: () => WorkoutGenerationMode.cloudAI,
        );
        state = mode;
        debugPrint('🔍 [GenerationMode] Loaded saved mode: ${mode.name}');
      }
    } catch (e) {
      debugPrint('❌ [GenerationMode] Error loading saved mode: $e');
    }
  }

  /// Set the generation mode and persist it.
  Future<void> setMode(WorkoutGenerationMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
      debugPrint('✅ [GenerationMode] Saved mode: ${mode.name}');
    } catch (e) {
      debugPrint('❌ [GenerationMode] Error saving mode: $e');
    }
  }
}

/// Provider for the current workout generation mode.
/// Persisted to SharedPreferences.
final generationModeProvider =
    StateNotifierProvider<GenerationModeNotifier, WorkoutGenerationMode>((ref) {
  return GenerationModeNotifier();
});
