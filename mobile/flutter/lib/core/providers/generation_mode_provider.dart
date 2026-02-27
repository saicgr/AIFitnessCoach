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
///
/// Offline Mode is Coming Soon — on-device AI and rule-based modes are
/// disabled. [setMode] silently ignores non-cloud modes until Offline Mode
/// launches.
class GenerationModeNotifier extends StateNotifier<WorkoutGenerationMode> {
  static const String _prefsKey = 'workout_generation_mode';

  GenerationModeNotifier() : super(WorkoutGenerationMode.cloudAI) {
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    // Offline Mode is Coming Soon — always use cloudAI regardless of
    // any previously-saved preference.
    state = WorkoutGenerationMode.cloudAI;
  }

  /// Set the generation mode and persist it.
  ///
  /// While Offline Mode is Coming Soon, only [WorkoutGenerationMode.cloudAI]
  /// is accepted. Other modes are silently ignored.
  Future<void> setMode(WorkoutGenerationMode mode) async {
    // Offline Mode is Coming Soon — only cloud AI is available.
    if (mode != WorkoutGenerationMode.cloudAI) {
      debugPrint('⚠️ [GenerationMode] Offline modes are Coming Soon — staying on cloudAI');
      return;
    }
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
