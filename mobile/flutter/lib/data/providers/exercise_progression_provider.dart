import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_progression.dart';
import '../repositories/exercise_progression_repository.dart';

// ============================================================================
// State Classes
// ============================================================================

/// State for exercise progression management
class ExerciseProgressionState {
  final bool isLoading;
  final String? error;
  final List<ExerciseVariantChain> chains;
  final List<UserExerciseMastery> userMastery;
  final List<ProgressionSuggestion> suggestions;
  final UserRepPreferences? repPreferences;
  final ExerciseVariantChain? selectedChain;
  final String? selectedMuscleGroup;

  const ExerciseProgressionState({
    this.isLoading = false,
    this.error,
    this.chains = const [],
    this.userMastery = const [],
    this.suggestions = const [],
    this.repPreferences,
    this.selectedChain,
    this.selectedMuscleGroup,
  });

  ExerciseProgressionState copyWith({
    bool? isLoading,
    String? error,
    List<ExerciseVariantChain>? chains,
    List<UserExerciseMastery>? userMastery,
    List<ProgressionSuggestion>? suggestions,
    UserRepPreferences? repPreferences,
    ExerciseVariantChain? selectedChain,
    String? selectedMuscleGroup,
    bool clearError = false,
    bool clearSelectedChain = false,
  }) {
    return ExerciseProgressionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      chains: chains ?? this.chains,
      userMastery: userMastery ?? this.userMastery,
      suggestions: suggestions ?? this.suggestions,
      repPreferences: repPreferences ?? this.repPreferences,
      selectedChain: clearSelectedChain ? null : (selectedChain ?? this.selectedChain),
      selectedMuscleGroup: selectedMuscleGroup ?? this.selectedMuscleGroup,
    );
  }

  /// Get pending suggestions only
  List<ProgressionSuggestion> get pendingSuggestions =>
      suggestions.where((s) => s.isPending).toList();

  /// Get mastery for a specific exercise
  UserExerciseMastery? getMasteryFor(String exerciseName) {
    try {
      return userMastery.firstWhere(
        (m) => m.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get exercises ready for progression
  List<UserExerciseMastery> get readyForProgression =>
      userMastery.where((m) => m.readyForProgression).toList();

  /// Get chains filtered by selected muscle group
  List<ExerciseVariantChain> get filteredChains {
    if (selectedMuscleGroup == null || selectedMuscleGroup!.isEmpty) {
      return chains;
    }
    return chains
        .where((c) =>
            c.muscleGroup.toLowerCase() == selectedMuscleGroup!.toLowerCase())
        .toList();
  }
}

// ============================================================================
// State Notifier
// ============================================================================

/// Manages exercise progression state and operations
class ExerciseProgressionNotifier extends StateNotifier<ExerciseProgressionState> {
  final ExerciseProgressionRepository _repository;
  String? _currentUserId;

  ExerciseProgressionNotifier(this._repository)
      : super(const ExerciseProgressionState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading Data
  // ─────────────────────────────────────────────────────────────────────────

  /// Load all progression chains
  Future<void> loadChains({String? muscleGroup, ChainType? chainType}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final chains = await _repository.getProgressionChains(
        muscleGroup: muscleGroup,
        chainType: chainType,
      );

      state = state.copyWith(
        isLoading: false,
        chains: chains,
        selectedMuscleGroup: muscleGroup,
      );
      debugPrint('Loaded ${chains.length} progression chains');
    } catch (e) {
      debugPrint('Error loading chains: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load progression chains: $e',
      );
    }
  }

  /// Load user's mastery data for all exercises
  Future<void> loadUserMastery({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('No user ID, skipping load user mastery');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final mastery = await _repository.getUserMastery(uid);
      state = state.copyWith(
        isLoading: false,
        userMastery: mastery,
      );
      debugPrint('Loaded ${mastery.length} exercise mastery records');
    } catch (e) {
      debugPrint('Error loading user mastery: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load mastery data: $e',
      );
    }
  }

  /// Load progression suggestions for the user
  Future<void> loadSuggestions({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final suggestions = await _repository.getProgressionSuggestions(uid);
      state = state.copyWith(suggestions: suggestions);
      debugPrint('Loaded ${suggestions.length} progression suggestions');
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  /// Load user's rep preferences
  Future<void> loadRepPreferences({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final prefs = await _repository.getRepPreferences(uid);
      state = state.copyWith(repPreferences: prefs);
      debugPrint('Loaded rep preferences: ${prefs.trainingFocus.name}');
    } catch (e) {
      debugPrint('Error loading rep preferences: $e');
    }
  }

  /// Load a specific chain with its variants
  Future<void> loadChainDetail(String chainId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final chain = await _repository.getChainWithVariants(chainId);
      state = state.copyWith(
        isLoading: false,
        selectedChain: chain,
      );
      debugPrint('Loaded chain detail: ${chain.baseExerciseName}');
    } catch (e) {
      debugPrint('Error loading chain detail: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chain: $e',
      );
    }
  }

  /// Load all data for the user
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.wait([
        loadChains(),
        loadUserMastery(userId: uid),
        loadSuggestions(userId: uid),
        loadRepPreferences(userId: uid),
      ]);
    } catch (e) {
      debugPrint('Error loading all progression data: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mastery Updates
  // ─────────────────────────────────────────────────────────────────────────

  /// Update mastery for a single exercise after performance
  Future<UserExerciseMastery?> updateMastery({
    required String exerciseName,
    required int reps,
    double? weight,
    required String difficultyFelt,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    try {
      final mastery = await _repository.updateExerciseMastery(
        userId: uid,
        exerciseName: exerciseName,
        reps: reps,
        weight: weight,
        difficultyFelt: difficultyFelt,
      );

      // Update mastery in state
      final updatedMastery = state.userMastery.map((m) {
        if (m.exerciseName.toLowerCase() == exerciseName.toLowerCase()) {
          return mastery;
        }
        return m;
      }).toList();

      // Add if not found
      if (!updatedMastery.any(
          (m) => m.exerciseName.toLowerCase() == exerciseName.toLowerCase())) {
        updatedMastery.add(mastery);
      }

      state = state.copyWith(userMastery: updatedMastery);
      debugPrint('Updated mastery for $exerciseName');
      return mastery;
    } catch (e) {
      debugPrint('Error updating mastery: $e');
      state = state.copyWith(error: 'Failed to update mastery: $e');
      return null;
    }
  }

  /// Batch update mastery after workout completion
  Future<void> batchUpdateMastery({
    required List<Map<String, dynamic>> exercisePerformance,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final masteryList = await _repository.batchUpdateMastery(
        userId: uid,
        exercisePerformance: exercisePerformance,
      );

      state = state.copyWith(userMastery: masteryList);
      debugPrint('Batch updated mastery for ${masteryList.length} exercises');

      // Also refresh suggestions after batch update
      await loadSuggestions(userId: uid);
    } catch (e) {
      debugPrint('Error batch updating mastery: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Progression Suggestions
  // ─────────────────────────────────────────────────────────────────────────

  /// Accept a progression suggestion
  Future<bool> acceptProgression(String suggestionId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      final accepted = await _repository.acceptProgression(
        userId: uid,
        suggestionId: suggestionId,
      );

      // Update suggestion in state
      final updatedSuggestions = state.suggestions.map((s) {
        if (s.id == suggestionId) return accepted;
        return s;
      }).toList();

      state = state.copyWith(suggestions: updatedSuggestions);
      debugPrint('Accepted progression: ${accepted.suggestedExercise}');
      return true;
    } catch (e) {
      debugPrint('Error accepting progression: $e');
      state = state.copyWith(error: 'Failed to accept progression: $e');
      return false;
    }
  }

  /// Accept progression by exercise names
  Future<bool> acceptProgressionByExercise({
    required String currentExercise,
    required String newExercise,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      await _repository.acceptProgressionByExercise(
        userId: uid,
        currentExercise: currentExercise,
        newExercise: newExercise,
      );

      // Refresh suggestions
      await loadSuggestions(userId: uid);
      debugPrint('Accepted progression: $currentExercise -> $newExercise');
      return true;
    } catch (e) {
      debugPrint('Error accepting progression: $e');
      state = state.copyWith(error: 'Failed to accept progression: $e');
      return false;
    }
  }

  /// Dismiss a progression suggestion
  Future<bool> dismissProgression(String suggestionId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      await _repository.dismissProgression(
        userId: uid,
        suggestionId: suggestionId,
      );

      // Remove suggestion from state
      final updatedSuggestions =
          state.suggestions.where((s) => s.id != suggestionId).toList();

      state = state.copyWith(suggestions: updatedSuggestions);
      debugPrint('Dismissed progression suggestion');
      return true;
    } catch (e) {
      debugPrint('Error dismissing progression: $e');
      state = state.copyWith(error: 'Failed to dismiss progression: $e');
      return false;
    }
  }

  /// Generate new suggestions after a workout
  Future<List<ProgressionSuggestion>> generateSuggestions({
    required String workoutLogId,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return [];
    _currentUserId = uid;

    try {
      final newSuggestions = await _repository.generateSuggestions(
        userId: uid,
        workoutLogId: workoutLogId,
      );

      // Add to existing suggestions
      final allSuggestions = [...state.suggestions, ...newSuggestions];
      state = state.copyWith(suggestions: allSuggestions);

      debugPrint('Generated ${newSuggestions.length} new suggestions');
      return newSuggestions;
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rep Preferences
  // ─────────────────────────────────────────────────────────────────────────

  /// Update rep preferences
  Future<bool> updateRepPreferences(
    UserRepPreferences preferences, {
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      final updated = await _repository.updateRepPreferences(
        userId: uid,
        preferences: preferences,
      );

      state = state.copyWith(repPreferences: updated);
      debugPrint('Updated rep preferences');
      return true;
    } catch (e) {
      debugPrint('Error updating rep preferences: $e');
      state = state.copyWith(error: 'Failed to update preferences: $e');
      return false;
    }
  }

  /// Update training focus
  Future<void> setTrainingFocus(TrainingFocus focus, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        trainingFocus: focus,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting training focus: $e');
    }
  }

  /// Update rep range
  Future<void> setRepRange(int minReps, int maxReps, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        preferredMinReps: minReps,
        preferredMaxReps: maxReps,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting rep range: $e');
    }
  }

  /// Toggle avoid high reps preference
  Future<void> setAvoidHighReps(bool avoid, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        avoidHighReps: avoid,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting avoid high reps: $e');
    }
  }

  /// Set progression style
  Future<void> setProgressionStyle(
    ProgressionStyle style, {
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        progressionStyle: style,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting progression style: $e');
    }
  }

  /// Set max sets per exercise
  Future<void> setMaxSetsPerExercise(int maxSets, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        maxSetsPerExercise: maxSets,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting max sets per exercise: $e');
    }
  }

  /// Set min sets per exercise
  Future<void> setMinSetsPerExercise(int minSets, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        minSetsPerExercise: minSets,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting min sets per exercise: $e');
    }
  }

  /// Set sets range (both min and max)
  Future<void> setSetsRange(int minSets, int maxSets, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        minSetsPerExercise: minSets,
        maxSetsPerExercise: maxSets,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting sets range: $e');
    }
  }

  /// Toggle enforce rep ceiling preference
  Future<void> setEnforceRepCeiling(bool enforce, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final updated = await _repository.patchRepPreferences(
        userId: uid,
        enforceRepCeiling: enforce,
      );
      state = state.copyWith(repPreferences: updated);
    } catch (e) {
      debugPrint('Error setting enforce rep ceiling: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Set muscle group filter
  void setMuscleGroupFilter(String? muscleGroup) {
    state = state.copyWith(selectedMuscleGroup: muscleGroup);
  }

  /// Clear selected chain
  void clearSelectedChain() {
    state = state.copyWith(clearSelectedChain: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main exercise progression provider
final exerciseProgressionProvider =
    StateNotifierProvider<ExerciseProgressionNotifier, ExerciseProgressionState>(
        (ref) {
  final repository = ref.watch(exerciseProgressionRepositoryProvider);
  return ExerciseProgressionNotifier(repository);
});

/// All progression chains (convenience provider)
final progressionChainsProvider = Provider<List<ExerciseVariantChain>>((ref) {
  return ref.watch(exerciseProgressionProvider).chains;
});

/// Filtered progression chains based on selected muscle group
final filteredProgressionChainsProvider =
    Provider<List<ExerciseVariantChain>>((ref) {
  return ref.watch(exerciseProgressionProvider).filteredChains;
});

/// User's exercise mastery list
final userMasteryProvider = Provider<List<UserExerciseMastery>>((ref) {
  return ref.watch(exerciseProgressionProvider).userMastery;
});

/// Exercises ready for progression
final readyForProgressionProvider = Provider<List<UserExerciseMastery>>((ref) {
  return ref.watch(exerciseProgressionProvider).readyForProgression;
});

/// Pending progression suggestions
final pendingSuggestionsProvider = Provider<List<ProgressionSuggestion>>((ref) {
  return ref.watch(exerciseProgressionProvider).pendingSuggestions;
});

/// All progression suggestions
final allSuggestionsProvider = Provider<List<ProgressionSuggestion>>((ref) {
  return ref.watch(exerciseProgressionProvider).suggestions;
});

/// User's rep preferences
final repPreferencesProvider = Provider<UserRepPreferences?>((ref) {
  return ref.watch(exerciseProgressionProvider).repPreferences;
});

/// Currently selected chain
final selectedChainProvider = Provider<ExerciseVariantChain?>((ref) {
  return ref.watch(exerciseProgressionProvider).selectedChain;
});

/// Exercise progression loading state
final exerciseProgressionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(exerciseProgressionProvider).isLoading;
});

/// Exercise progression error
final exerciseProgressionErrorProvider = Provider<String?>((ref) {
  return ref.watch(exerciseProgressionProvider).error;
});

/// Mastery for a specific exercise (family provider)
final exerciseMasteryProvider =
    Provider.family<UserExerciseMastery?, String>((ref, exerciseName) {
  return ref.watch(exerciseProgressionProvider).getMasteryFor(exerciseName);
});

/// Check if user has any pending suggestions
final hasPendingSuggestionsProvider = Provider<bool>((ref) {
  return ref.watch(exerciseProgressionProvider).pendingSuggestions.isNotEmpty;
});
