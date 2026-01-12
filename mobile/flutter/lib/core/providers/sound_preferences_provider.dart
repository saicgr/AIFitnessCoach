import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/api_client.dart';

/// Provider for the SoundService singleton.
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Sound preferences state
class SoundPreferencesState {
  // Countdown sounds (3, 2, 1)
  final bool countdownSoundEnabled;
  final String countdownSoundType;

  // Rest timer end sounds
  final bool restTimerSoundEnabled;
  final String restTimerSoundType;

  // Exercise completion sounds (when all sets done)
  final bool exerciseCompletionSoundEnabled;
  final String exerciseCompletionSoundType;

  // Workout completion sounds (entire workout done)
  final bool workoutCompletionSoundEnabled;
  final String workoutCompletionSoundType;

  // Master volume
  final double soundEffectsVolume;

  // Loading state
  final bool isLoading;
  final String? error;

  const SoundPreferencesState({
    this.countdownSoundEnabled = true,
    this.countdownSoundType = 'beep',
    this.restTimerSoundEnabled = true,
    this.restTimerSoundType = 'beep',
    this.exerciseCompletionSoundEnabled = true,
    this.exerciseCompletionSoundType = 'chime',
    this.workoutCompletionSoundEnabled = true,
    this.workoutCompletionSoundType = 'chime',
    this.soundEffectsVolume = 0.8,
    this.isLoading = false,
    this.error,
  });

  SoundPreferencesState copyWith({
    bool? countdownSoundEnabled,
    String? countdownSoundType,
    bool? restTimerSoundEnabled,
    String? restTimerSoundType,
    bool? exerciseCompletionSoundEnabled,
    String? exerciseCompletionSoundType,
    bool? workoutCompletionSoundEnabled,
    String? workoutCompletionSoundType,
    double? soundEffectsVolume,
    bool? isLoading,
    String? error,
  }) {
    return SoundPreferencesState(
      countdownSoundEnabled:
          countdownSoundEnabled ?? this.countdownSoundEnabled,
      countdownSoundType: countdownSoundType ?? this.countdownSoundType,
      restTimerSoundEnabled:
          restTimerSoundEnabled ?? this.restTimerSoundEnabled,
      restTimerSoundType: restTimerSoundType ?? this.restTimerSoundType,
      exerciseCompletionSoundEnabled:
          exerciseCompletionSoundEnabled ?? this.exerciseCompletionSoundEnabled,
      exerciseCompletionSoundType:
          exerciseCompletionSoundType ?? this.exerciseCompletionSoundType,
      workoutCompletionSoundEnabled:
          workoutCompletionSoundEnabled ?? this.workoutCompletionSoundEnabled,
      workoutCompletionSoundType:
          workoutCompletionSoundType ?? this.workoutCompletionSoundType,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for sound preferences state.
///
/// This persists settings locally and syncs to backend.
final soundPreferencesProvider =
    StateNotifierProvider<SoundPreferencesNotifier, SoundPreferencesState>(
        (ref) {
  return SoundPreferencesNotifier(ref);
});

/// Notifier for managing sound preferences state.
class SoundPreferencesNotifier extends StateNotifier<SoundPreferencesState> {
  final Ref _ref;

  // SharedPreferences keys
  static const String _countdownEnabledKey = 'sound_countdown_enabled';
  static const String _countdownTypeKey = 'sound_countdown_type';
  static const String _restTimerEnabledKey = 'sound_rest_timer_enabled';
  static const String _restTimerTypeKey = 'sound_rest_timer_type';
  static const String _exerciseCompleteEnabledKey =
      'sound_exercise_complete_enabled';
  static const String _exerciseCompleteTypeKey = 'sound_exercise_complete_type';
  static const String _workoutCompleteEnabledKey =
      'sound_workout_complete_enabled';
  static const String _workoutCompleteTypeKey = 'sound_workout_complete_type';
  static const String _volumeKey = 'sound_effects_volume';

  SoundPreferencesNotifier(this._ref)
      : super(const SoundPreferencesState()) {
    _init();
  }

  /// Initialize from local storage and backend.
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      // Initialize the sound service
      await _ref.read(soundServiceProvider).initialize();

      // Load from local storage first for instant feedback
      final prefs = await SharedPreferences.getInstance();
      state = SoundPreferencesState(
        countdownSoundEnabled: prefs.getBool(_countdownEnabledKey) ?? true,
        countdownSoundType: prefs.getString(_countdownTypeKey) ?? 'beep',
        restTimerSoundEnabled: prefs.getBool(_restTimerEnabledKey) ?? true,
        restTimerSoundType: prefs.getString(_restTimerTypeKey) ?? 'beep',
        exerciseCompletionSoundEnabled:
            prefs.getBool(_exerciseCompleteEnabledKey) ?? true,
        exerciseCompletionSoundType:
            prefs.getString(_exerciseCompleteTypeKey) ?? 'chime',
        workoutCompletionSoundEnabled:
            prefs.getBool(_workoutCompleteEnabledKey) ?? true,
        workoutCompletionSoundType:
            prefs.getString(_workoutCompleteTypeKey) ?? 'chime',
        soundEffectsVolume: prefs.getDouble(_volumeKey) ?? 0.8,
        isLoading: false,
      );

      // Sync sound service with preferences
      _syncSoundService();

      debugPrint('✅ [SoundPreferences] Loaded from local storage');

      // Try to fetch from backend
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('❌ [SoundPreferences] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetch preferences from backend and update state.
  Future<void> _fetchFromBackend() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/sound-preferences');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Update state with backend data
        state = state.copyWith(
          countdownSoundEnabled: data['countdown_sound_enabled'] ?? true,
          countdownSoundType: data['countdown_sound_type'] ?? 'beep',
          restTimerSoundEnabled: data['rest_timer_sound_enabled'] ?? true,
          restTimerSoundType: data['rest_timer_sound_type'] ?? 'beep',
          exerciseCompletionSoundEnabled:
              data['exercise_completion_sound_enabled'] ?? true,
          exerciseCompletionSoundType:
              data['exercise_completion_sound_type'] ?? 'chime',
          workoutCompletionSoundEnabled:
              data['completion_sound_enabled'] ?? true,
          workoutCompletionSoundType: data['completion_sound_type'] ?? 'chime',
          soundEffectsVolume:
              (data['sound_effects_volume'] as num?)?.toDouble() ?? 0.8,
          isLoading: false,
        );

        // Save to local storage
        await _saveToLocalStorage();

        // Sync sound service
        _syncSoundService();

        debugPrint('✅ [SoundPreferences] Synced from backend');
      }
    } catch (e) {
      // Don't fail if backend fetch fails - local storage is the fallback
      debugPrint('⚠️ [SoundPreferences] Backend fetch failed: $e');
    }
  }

  /// Save current state to local storage.
  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_countdownEnabledKey, state.countdownSoundEnabled);
    await prefs.setString(_countdownTypeKey, state.countdownSoundType);
    await prefs.setBool(_restTimerEnabledKey, state.restTimerSoundEnabled);
    await prefs.setString(_restTimerTypeKey, state.restTimerSoundType);
    await prefs.setBool(
        _exerciseCompleteEnabledKey, state.exerciseCompletionSoundEnabled);
    await prefs.setString(
        _exerciseCompleteTypeKey, state.exerciseCompletionSoundType);
    await prefs.setBool(
        _workoutCompleteEnabledKey, state.workoutCompletionSoundEnabled);
    await prefs.setString(
        _workoutCompleteTypeKey, state.workoutCompletionSoundType);
    await prefs.setDouble(_volumeKey, state.soundEffectsVolume);
  }

  /// Sync SoundService with current preferences.
  void _syncSoundService() {
    _ref.read(soundServiceProvider).updatePreferences(
          countdownEnabled: state.countdownSoundEnabled,
          countdownType: state.countdownSoundType,
          restTimerEnabled: state.restTimerSoundEnabled,
          restTimerType: state.restTimerSoundType,
          exerciseCompletionEnabled: state.exerciseCompletionSoundEnabled,
          exerciseCompletionType: state.exerciseCompletionSoundType,
          completionEnabled: state.workoutCompletionSoundEnabled,
          completionType: state.workoutCompletionSoundType,
          volume: state.soundEffectsVolume,
        );
  }

  /// Sync current state to backend.
  Future<void> _syncToBackend() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        '/sound-preferences',
        data: {
          'countdown_sound_enabled': state.countdownSoundEnabled,
          'countdown_sound_type': state.countdownSoundType,
          'rest_timer_sound_enabled': state.restTimerSoundEnabled,
          'rest_timer_sound_type': state.restTimerSoundType,
          'exercise_completion_sound_enabled':
              state.exerciseCompletionSoundEnabled,
          'exercise_completion_sound_type': state.exerciseCompletionSoundType,
          'completion_sound_enabled': state.workoutCompletionSoundEnabled,
          'completion_sound_type': state.workoutCompletionSoundType,
          'sound_effects_volume': state.soundEffectsVolume,
        },
      );
      debugPrint('✅ [SoundPreferences] Synced to backend');
    } catch (e) {
      debugPrint('⚠️ [SoundPreferences] Backend sync failed: $e');
    }
  }

  // ============ Countdown Sound Settings ============

  /// Set countdown sound enabled.
  Future<void> setCountdownEnabled(bool enabled) async {
    if (enabled == state.countdownSoundEnabled) return;

    state = state.copyWith(countdownSoundEnabled: enabled);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  /// Set countdown sound type.
  Future<void> setCountdownType(String type) async {
    if (type == state.countdownSoundType) return;

    state = state.copyWith(countdownSoundType: type);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  // ============ Rest Timer Sound Settings ============

  /// Set rest timer sound enabled.
  Future<void> setRestTimerEnabled(bool enabled) async {
    if (enabled == state.restTimerSoundEnabled) return;

    state = state.copyWith(restTimerSoundEnabled: enabled);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  /// Set rest timer sound type.
  Future<void> setRestTimerType(String type) async {
    if (type == state.restTimerSoundType) return;

    state = state.copyWith(restTimerSoundType: type);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  // ============ Exercise Completion Sound Settings ============

  /// Set exercise completion sound enabled.
  Future<void> setExerciseCompletionEnabled(bool enabled) async {
    if (enabled == state.exerciseCompletionSoundEnabled) return;

    state = state.copyWith(exerciseCompletionSoundEnabled: enabled);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  /// Set exercise completion sound type.
  Future<void> setExerciseCompletionType(String type) async {
    if (type == state.exerciseCompletionSoundType) return;

    state = state.copyWith(exerciseCompletionSoundType: type);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  // ============ Workout Completion Sound Settings ============

  /// Set workout completion sound enabled.
  Future<void> setWorkoutCompletionEnabled(bool enabled) async {
    if (enabled == state.workoutCompletionSoundEnabled) return;

    state = state.copyWith(workoutCompletionSoundEnabled: enabled);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  /// Set workout completion sound type.
  Future<void> setWorkoutCompletionType(String type) async {
    if (type == state.workoutCompletionSoundType) return;

    state = state.copyWith(workoutCompletionSoundType: type);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  // ============ Volume Settings ============

  /// Set sound effects volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (clamped == state.soundEffectsVolume) return;

    state = state.copyWith(soundEffectsVolume: clamped);
    _syncSoundService();
    await _saveToLocalStorage();
    await _syncToBackend();
  }

  // ============ Sound Playback Methods ============

  /// Play countdown sound (3, 2, 1).
  Future<void> playCountdown(int count) async {
    await _ref.read(soundServiceProvider).playCountdownBeep(count);
  }

  /// Play rest timer end sound.
  Future<void> playRestTimerEnd() async {
    await _ref.read(soundServiceProvider).playRestTimerSound();
  }

  /// Play exercise completion sound.
  Future<void> playExerciseCompletion() async {
    await _ref.read(soundServiceProvider).playExerciseCompletionSound();
  }

  /// Play workout completion sound.
  Future<void> playWorkoutCompletion() async {
    await _ref.read(soundServiceProvider).playWorkoutCompletionSound();
  }

  /// Play preview sound for settings.
  Future<void> playPreview(String category, String soundType) async {
    await _ref.read(soundServiceProvider).playPreviewSound(category, soundType);
  }

  /// Stop all sounds.
  Future<void> stop() async {
    await _ref.read(soundServiceProvider).stop();
  }
}
