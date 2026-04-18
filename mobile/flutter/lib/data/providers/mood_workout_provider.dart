import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/mood_workout_service.dart';
import '../models/mood.dart';
import '../models/workout.dart';
import '../models/workout_style.dart';
import '../services/api_client.dart';

// ============================================
// Mood Workout State
// ============================================

/// State for mood-based workout generation
class MoodWorkoutState {
  /// Currently selected mood (null if none selected)
  final Mood? selectedMood;

  /// Whether generation is in progress
  final bool isGenerating;

  /// Current generation progress (0.0 to 1.0)
  final double progress;

  /// Current step in the generation process (1-4)
  final int currentStep;

  /// Total steps in the generation process
  final int totalSteps;

  /// Human-readable status message
  final String? statusMessage;

  /// Additional detail about current step
  final String? detail;

  /// Generated workout (null until complete)
  final Workout? generatedWorkout;

  /// Error message if generation failed
  final String? error;

  /// Mood emoji for UI display
  final String? moodEmoji;

  /// Mood color hex for UI display
  final String? moodColor;

  /// Total time taken for generation (ms)
  final int? totalTimeMs;

  const MoodWorkoutState({
    this.selectedMood,
    this.isGenerating = false,
    this.progress = 0.0,
    this.currentStep = 0,
    this.totalSteps = 4,
    this.statusMessage,
    this.detail,
    this.generatedWorkout,
    this.error,
    this.moodEmoji,
    this.moodColor,
    this.totalTimeMs,
  });

  MoodWorkoutState copyWith({
    Mood? selectedMood,
    bool? isGenerating,
    double? progress,
    int? currentStep,
    int? totalSteps,
    String? statusMessage,
    String? detail,
    Workout? generatedWorkout,
    String? error,
    String? moodEmoji,
    String? moodColor,
    int? totalTimeMs,
    bool clearError = false,
    bool clearMood = false,
    bool clearWorkout = false,
    bool clearStatus = false,
  }) {
    return MoodWorkoutState(
      selectedMood: clearMood ? null : (selectedMood ?? this.selectedMood),
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      detail: clearStatus ? null : (detail ?? this.detail),
      generatedWorkout: clearWorkout ? null : (generatedWorkout ?? this.generatedWorkout),
      error: clearError ? null : (error ?? this.error),
      moodEmoji: moodEmoji ?? this.moodEmoji,
      moodColor: moodColor ?? this.moodColor,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
    );
  }

  /// Whether generation completed successfully
  bool get isCompleted => generatedWorkout != null && !isGenerating;

  /// Whether generation failed
  bool get hasFailed => error != null && !isGenerating;

  /// Whether ready to start generation (mood selected, not generating)
  bool get canGenerate => selectedMood != null && !isGenerating;
}

// ============================================
// Mood Workout Notifier
// ============================================

class MoodWorkoutNotifier extends StateNotifier<MoodWorkoutState> {
  final MoodWorkoutService _service;
  final ApiClient _apiClient;

  MoodWorkoutNotifier(this._service, this._apiClient)
      : super(const MoodWorkoutState());

  /// Select a mood for workout generation
  void selectMood(Mood mood) {
    debugPrint('🎯 [MoodWorkout] Selected mood: ${mood.value}');
    state = state.copyWith(
      selectedMood: mood,
      moodEmoji: mood.emoji,
      clearError: true,
      clearWorkout: true,
      clearStatus: true,
    );
  }

  /// Clear selected mood
  void clearMood() {
    state = state.copyWith(clearMood: true, clearError: true);
  }

  /// Generate a workout locally using [MoodWorkoutService]. Returns the
  /// workout without persisting it — the UI layer inspects
  /// [MoodWorkoutService.existingWorkoutsForToday] and decides whether to
  /// Replace or Add before committing via [persistWorkout].
  ///
  /// [style], [difficulty], [duration] are user overrides from the mood
  /// sheet's Advanced Options panel. When `null`, preset defaults apply.
  Future<Workout?> generateMoodWorkout({
    WorkoutStyle? style,
    String? difficulty,
    int? duration,
  }) async {
    final mood = state.selectedMood;
    if (mood == null) {
      debugPrint('⚠️ [MoodWorkout] No mood selected, cannot generate');
      state = state.copyWith(error: 'Please select a mood first');
      return null;
    }

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('⚠️ [MoodWorkout] No user ID, cannot generate');
      state = state.copyWith(error: 'User not logged in');
      return null;
    }

    debugPrint('🚀 [MoodWorkout] Starting local generation for mood: '
        '${mood.value}, style=${style?.value}, difficulty=$difficulty, '
        'duration=$duration');
    state = state.copyWith(
      isGenerating: true,
      progress: 0.0,
      currentStep: 1,
      totalSteps: 1,
      statusMessage: 'Generating your ${mood.label.toLowerCase()} workout...',
      clearError: true,
      clearWorkout: true,
    );

    final sw = Stopwatch()..start();
    try {
      final workout = await _service
          .generateLocally(
            mood: mood,
            userId: userId,
            style: style,
            difficulty: difficulty,
            duration: duration,
          )
          .timeout(const Duration(seconds: 5));

      sw.stop();
      state = state.copyWith(
        isGenerating: false,
        generatedWorkout: workout,
        totalTimeMs: sw.elapsedMilliseconds,
        statusMessage: 'Workout ready!',
        progress: 1.0,
      );
      debugPrint('✅ [MoodWorkout] Local generation complete in '
          '${sw.elapsedMilliseconds}ms');
      return workout;
    } catch (e, stack) {
      debugPrint('❌ [MoodWorkout] Local generation failed: $e\n$stack');
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate workout: $e',
      );
      return null;
    }
  }

  /// Persist a previously-generated workout. Called after the Replace/Add
  /// decision.
  Future<void> persistWorkout(Workout workout) async {
    final userId = await _apiClient.getUserId();
    if (userId == null) return;
    await _service.persist(workout, userId);
  }

  /// Fetch today's existing workouts so the UI can ask Replace vs Add.
  Future<List<Workout>> existingTodayWorkouts() async {
    final userId = await _apiClient.getUserId();
    if (userId == null) return const [];
    return _service.existingWorkoutsForToday(userId);
  }

  /// Reset state for a new generation
  void reset() {
    state = const MoodWorkoutState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear the generated workout (after navigation)
  void clearGeneratedWorkout() {
    state = state.copyWith(clearWorkout: true);
  }
}

// ============================================
// Providers
// ============================================

/// Main mood workout provider
final moodWorkoutProvider =
    StateNotifierProvider<MoodWorkoutNotifier, MoodWorkoutState>((ref) {
  final service = ref.watch(moodWorkoutServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return MoodWorkoutNotifier(service, apiClient);
});

/// Currently selected mood (convenience provider)
final selectedMoodProvider = Provider<Mood?>((ref) {
  return ref.watch(moodWorkoutProvider).selectedMood;
});

/// Whether mood workout is generating (convenience provider)
final isMoodWorkoutGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(moodWorkoutProvider).isGenerating;
});

/// Mood workout generation progress (convenience provider)
final moodWorkoutProgressProvider = Provider<double>((ref) {
  return ref.watch(moodWorkoutProvider).progress;
});

/// Generated mood workout (convenience provider)
final generatedMoodWorkoutProvider = Provider<Workout?>((ref) {
  return ref.watch(moodWorkoutProvider).generatedWorkout;
});

/// Mood workout error (convenience provider)
final moodWorkoutErrorProvider = Provider<String?>((ref) {
  return ref.watch(moodWorkoutProvider).error;
});

/// Mood workout status message (convenience provider)
final moodWorkoutStatusProvider = Provider<String?>((ref) {
  return ref.watch(moodWorkoutProvider).statusMessage;
});
