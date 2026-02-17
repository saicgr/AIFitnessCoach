import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

// ============================================
// Quick Workout State
// ============================================

/// State for quick workout generation
class QuickWorkoutState {
  /// Whether generation is in progress
  final bool isGenerating;

  /// Current status message
  final String? statusMessage;

  /// Generated workout (null until complete)
  final Workout? generatedWorkout;

  /// Error message if generation failed
  final String? error;

  /// Last used duration preference
  final int? lastDuration;

  /// Last used focus preference
  final String? lastFocus;

  const QuickWorkoutState({
    this.isGenerating = false,
    this.statusMessage,
    this.generatedWorkout,
    this.error,
    this.lastDuration,
    this.lastFocus,
  });

  QuickWorkoutState copyWith({
    bool? isGenerating,
    String? statusMessage,
    Workout? generatedWorkout,
    String? error,
    int? lastDuration,
    String? lastFocus,
    bool clearError = false,
    bool clearWorkout = false,
    bool clearStatus = false,
  }) {
    return QuickWorkoutState(
      isGenerating: isGenerating ?? this.isGenerating,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      generatedWorkout: clearWorkout ? null : (generatedWorkout ?? this.generatedWorkout),
      error: clearError ? null : (error ?? this.error),
      lastDuration: lastDuration ?? this.lastDuration,
      lastFocus: lastFocus ?? this.lastFocus,
    );
  }

  /// Whether generation completed successfully
  bool get isCompleted => generatedWorkout != null && !isGenerating;

  /// Whether generation failed
  bool get hasFailed => error != null && !isGenerating;
}

// ============================================
// Quick Workout Notifier
// ============================================

class QuickWorkoutNotifier extends StateNotifier<QuickWorkoutState> {
  final ApiClient _apiClient;

  QuickWorkoutNotifier(this._apiClient) : super(const QuickWorkoutState());

  /// Generate a quick workout
  Future<Workout?> generateQuickWorkout({
    required int duration,
    String? focus,
    String? difficulty,
    List<String>? equipment,
    List<String>? injuries,
  }) async {
    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('[QuickWorkout] No user ID, cannot generate');
      state = state.copyWith(error: 'User not logged in');
      return null;
    }

    debugPrint('[QuickWorkout] Starting generation: ${duration}min, focus=$focus, difficulty=$difficulty');
    state = state.copyWith(
      isGenerating: true,
      statusMessage: 'Generating workout...',
      clearError: true,
      clearWorkout: true,
    );

    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'duration': duration,
        'focus': focus,
      };
      if (difficulty != null) data['difficulty'] = difficulty;
      if (equipment != null && equipment.isNotEmpty) data['equipment'] = equipment;
      if (injuries != null && injuries.isNotEmpty) data['injuries'] = injuries;

      final response = await _apiClient.post(
        '${ApiConstants.workouts}/quick',
        data: data,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final workoutData = data['workout'] as Map<String, dynamic>;
        final workout = Workout.fromJson(workoutData);

        debugPrint('[QuickWorkout] Generated successfully: ${workout.name}');
        state = state.copyWith(
          isGenerating: false,
          generatedWorkout: workout,
          lastDuration: duration,
          lastFocus: focus,
          statusMessage: 'Workout ready!',
        );

        return workout;
      } else {
        throw Exception('Failed to generate workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[QuickWorkout] Error: $e');
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate workout. Please try again.',
      );
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear generated workout
  void clearGeneratedWorkout() {
    state = state.copyWith(clearWorkout: true);
  }

  /// Reset state
  void reset() {
    state = const QuickWorkoutState();
  }
}

// ============================================
// Providers
// ============================================

/// Main quick workout provider
final quickWorkoutProvider =
    StateNotifierProvider<QuickWorkoutNotifier, QuickWorkoutState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuickWorkoutNotifier(apiClient);
});

/// Whether quick workout is generating (convenience provider)
final isQuickWorkoutGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(quickWorkoutProvider).isGenerating;
});

/// Generated quick workout (convenience provider)
final generatedQuickWorkoutProvider = Provider<Workout?>((ref) {
  return ref.watch(quickWorkoutProvider).generatedWorkout;
});

/// Quick workout error (convenience provider)
final quickWorkoutErrorProvider = Provider<String?>((ref) {
  return ref.watch(quickWorkoutProvider).error;
});

// ============================================
// Quick Workout Preferences
// ============================================

/// Fetches and caches user's quick workout preferences
final quickWorkoutPreferencesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();

  if (userId == null) {
    return {
      'preferred_duration': 10,
      'preferred_focus': null,
      'quick_workout_count': 0,
    };
  }

  try {
    final response = await apiClient.get(
      '${ApiConstants.workouts}/quick/preferences/$userId',
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('[QuickWorkout] Failed to fetch preferences: $e');
  }

  return {
    'preferred_duration': 10,
    'preferred_focus': null,
    'quick_workout_count': 0,
  };
});
