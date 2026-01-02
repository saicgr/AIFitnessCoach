import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill_progression.dart';
import '../repositories/skill_progression_repository.dart';

// ============================================
// State Classes
// ============================================

/// State for skill progressions
class SkillProgressionState {
  final bool isLoading;
  final String? error;
  final List<ProgressionChain> chains;
  final List<UserSkillProgress> userProgress;
  final ProgressionChain? selectedChain;
  final UserSkillProgress? selectedChainProgress;
  final List<ProgressionAttempt> attemptHistory;
  final SkillProgressionSummary? summary;
  final String? selectedCategory;

  const SkillProgressionState({
    this.isLoading = false,
    this.error,
    this.chains = const [],
    this.userProgress = const [],
    this.selectedChain,
    this.selectedChainProgress,
    this.attemptHistory = const [],
    this.summary,
    this.selectedCategory,
  });

  SkillProgressionState copyWith({
    bool? isLoading,
    String? error,
    List<ProgressionChain>? chains,
    List<UserSkillProgress>? userProgress,
    ProgressionChain? selectedChain,
    UserSkillProgress? selectedChainProgress,
    List<ProgressionAttempt>? attemptHistory,
    SkillProgressionSummary? summary,
    String? selectedCategory,
    bool clearError = false,
    bool clearSelectedChain = false,
    bool clearSelectedProgress = false,
  }) {
    return SkillProgressionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      chains: chains ?? this.chains,
      userProgress: userProgress ?? this.userProgress,
      selectedChain: clearSelectedChain ? null : (selectedChain ?? this.selectedChain),
      selectedChainProgress: clearSelectedProgress
          ? null
          : (selectedChainProgress ?? this.selectedChainProgress),
      attemptHistory: attemptHistory ?? this.attemptHistory,
      summary: summary ?? this.summary,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  /// Get chains filtered by selected category
  List<ProgressionChain> get filteredChains {
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      return chains;
    }
    return chains.where((c) => c.category == selectedCategory).toList();
  }

  /// Get user progress for a specific chain
  UserSkillProgress? getProgressForChain(String chainId) {
    try {
      return userProgress.firstWhere((p) => p.chainId == chainId);
    } catch (_) {
      return null;
    }
  }

  /// Get chains user has started
  List<ProgressionChain> get startedChains {
    final startedIds = userProgress.map((p) => p.chainId).toSet();
    return chains.where((c) => startedIds.contains(c.id)).toList();
  }

  /// Get chains user hasn't started yet
  List<ProgressionChain> get availableChains {
    final startedIds = userProgress.map((p) => p.chainId).toSet();
    return chains.where((c) => !startedIds.contains(c.id)).toList();
  }
}

// ============================================
// State Notifier
// ============================================

class SkillProgressionNotifier extends StateNotifier<SkillProgressionState> {
  final SkillProgressionRepository _repository;
  String? _currentUserId;

  SkillProgressionNotifier(this._repository) : super(const SkillProgressionState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all progression chains
  Future<void> loadChains({String? category}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final chains = await _repository.getProgressionChains(category: category);
      state = state.copyWith(
        isLoading: false,
        chains: chains,
        selectedCategory: category,
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

  /// Load user's progress for all chains
  Future<void> loadUserProgress({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('No user ID, skipping load user progress');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final progress = await _repository.getUserProgress(uid);
      state = state.copyWith(
        isLoading: false,
        userProgress: progress,
      );
      debugPrint('Loaded ${progress.length} user progressions');
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load progress: $e',
      );
    }
  }

  /// Load user's summary
  Future<void> loadSummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final summary = await _repository.getUserSummary(uid);
      state = state.copyWith(summary: summary);
      debugPrint('Loaded user progression summary');
    } catch (e) {
      debugPrint('Error loading summary: $e');
    }
  }

  /// Load a specific chain with its steps
  Future<void> loadChainDetail(String chainId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final chain = await _repository.getChainWithSteps(chainId);
      state = state.copyWith(
        isLoading: false,
        selectedChain: chain,
      );

      // Also load user's progress for this chain if we have a user ID
      if (uid != null) {
        final progress = await _repository.getUserChainProgress(uid, chainId);
        state = state.copyWith(selectedChainProgress: progress);
      }

      debugPrint('Loaded chain detail: ${chain.name}');
    } catch (e) {
      debugPrint('Error loading chain detail: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chain: $e',
      );
    }
  }

  /// Start a new progression chain
  Future<UserSkillProgress?> startChain(String chainId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final progress = await _repository.startChain(uid, chainId);

      // Add to user progress list
      final updatedProgress = [...state.userProgress, progress];
      state = state.copyWith(
        isLoading: false,
        userProgress: updatedProgress,
        selectedChainProgress: progress,
      );

      debugPrint('Started chain: $chainId');
      return progress;
    } catch (e) {
      debugPrint('Error starting chain: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start chain: $e',
      );
      return null;
    }
  }

  /// Log an attempt at the current step
  Future<ProgressionAttempt?> logAttempt({
    required String chainId,
    required String stepId,
    required int stepOrder,
    int? repsCompleted,
    int? setsCompleted,
    int? holdSeconds,
    String? notes,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    try {
      final attempt = await _repository.logAttempt(
        userId: uid,
        chainId: chainId,
        stepId: stepId,
        stepOrder: stepOrder,
        repsCompleted: repsCompleted,
        setsCompleted: setsCompleted,
        holdSeconds: holdSeconds,
        notes: notes,
      );

      // Add to attempt history
      final updatedHistory = [attempt, ...state.attemptHistory];
      state = state.copyWith(attemptHistory: updatedHistory);

      // Reload progress if attempt unlocked next step
      if (attempt.unlockedNext) {
        await loadUserProgress(userId: uid);
        if (state.selectedChain != null) {
          await loadChainDetail(chainId, userId: uid);
        }
      }

      debugPrint('Logged attempt: ${attempt.wasSuccessful ? "Success" : "Try again"}');
      return attempt;
    } catch (e) {
      debugPrint('Error logging attempt: $e');
      state = state.copyWith(error: 'Failed to log attempt: $e');
      return null;
    }
  }

  /// Manually unlock the next step
  Future<bool> unlockNextStep(String chainId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      final progress = await _repository.unlockNextStep(uid, chainId);

      // Update progress in list
      final updatedProgress = state.userProgress.map((p) {
        if (p.chainId == chainId) return progress;
        return p;
      }).toList();

      state = state.copyWith(
        userProgress: updatedProgress,
        selectedChainProgress: progress,
      );

      debugPrint('Unlocked next step in chain: $chainId');
      return true;
    } catch (e) {
      debugPrint('Error unlocking next step: $e');
      state = state.copyWith(error: 'Failed to unlock step: $e');
      return false;
    }
  }

  /// Load attempt history for a chain
  Future<void> loadAttemptHistory({
    required String chainId,
    int? stepOrder,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final history = await _repository.getAttemptHistory(
        userId: uid,
        chainId: chainId,
        stepOrder: stepOrder,
      );
      state = state.copyWith(attemptHistory: history);
      debugPrint('Loaded ${history.length} attempts');
    } catch (e) {
      debugPrint('Error loading attempt history: $e');
    }
  }

  /// Set selected category filter
  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Clear selected chain
  void clearSelectedChain() {
    state = state.copyWith(
      clearSelectedChain: true,
      clearSelectedProgress: true,
      attemptHistory: [],
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await Future.wait([
      loadChains(category: state.selectedCategory),
      loadUserProgress(userId: userId),
    ]);
  }
}

// ============================================
// Providers
// ============================================

/// Main skill progression provider
final skillProgressionProvider =
    StateNotifierProvider<SkillProgressionNotifier, SkillProgressionState>((ref) {
  final repository = ref.watch(skillProgressionRepositoryProvider);
  return SkillProgressionNotifier(repository);
});

/// All progression chains (convenience provider)
final progressionChainsProvider = Provider<List<ProgressionChain>>((ref) {
  return ref.watch(skillProgressionProvider).chains;
});

/// Filtered progression chains based on selected category (convenience provider)
final filteredProgressionChainsProvider = Provider<List<ProgressionChain>>((ref) {
  return ref.watch(skillProgressionProvider).filteredChains;
});

/// User's skill progress list (convenience provider)
final userSkillProgressProvider = Provider<List<UserSkillProgress>>((ref) {
  return ref.watch(skillProgressionProvider).userProgress;
});

/// Currently selected chain (convenience provider)
final currentChainProvider = Provider<ProgressionChain?>((ref) {
  return ref.watch(skillProgressionProvider).selectedChain;
});

/// Progress for currently selected chain (convenience provider)
final currentChainProgressProvider = Provider<UserSkillProgress?>((ref) {
  return ref.watch(skillProgressionProvider).selectedChainProgress;
});

/// Chains user has started (convenience provider)
final startedChainsProvider = Provider<List<ProgressionChain>>((ref) {
  return ref.watch(skillProgressionProvider).startedChains;
});

/// Chains user hasn't started (convenience provider)
final availableChainsProvider = Provider<List<ProgressionChain>>((ref) {
  return ref.watch(skillProgressionProvider).availableChains;
});

/// Skill progression loading state (convenience provider)
final skillProgressionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(skillProgressionProvider).isLoading;
});

/// Skill progression error (convenience provider)
final skillProgressionErrorProvider = Provider<String?>((ref) {
  return ref.watch(skillProgressionProvider).error;
});

/// Selected category filter (convenience provider)
final selectedCategoryProvider = Provider<String?>((ref) {
  return ref.watch(skillProgressionProvider).selectedCategory;
});

/// User progress for a specific chain (family provider)
final chainProgressProvider = Provider.family<UserSkillProgress?, String>((ref, chainId) {
  return ref.watch(skillProgressionProvider).getProgressForChain(chainId);
});
