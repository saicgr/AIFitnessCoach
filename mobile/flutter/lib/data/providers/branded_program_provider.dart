import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branded_program.dart';
import '../repositories/branded_program_repository.dart';

// ============================================================================
// STATE CLASSES
// ============================================================================

/// State for branded programs list
class BrandedProgramsState {
  final List<BrandedProgram> programs;
  final List<BrandedProgram> featuredPrograms;
  final List<String> categories;
  final String? selectedCategory;
  final String? selectedDifficulty;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const BrandedProgramsState({
    this.programs = const [],
    this.featuredPrograms = const [],
    this.categories = const [],
    this.selectedCategory,
    this.selectedDifficulty,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  BrandedProgramsState copyWith({
    List<BrandedProgram>? programs,
    List<BrandedProgram>? featuredPrograms,
    List<String>? categories,
    String? selectedCategory,
    String? selectedDifficulty,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
    bool clearDifficulty = false,
    bool clearError = false,
  }) {
    return BrandedProgramsState(
      programs: programs ?? this.programs,
      featuredPrograms: featuredPrograms ?? this.featuredPrograms,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedDifficulty: clearDifficulty
          ? null
          : (selectedDifficulty ?? this.selectedDifficulty),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get filtered programs based on current filters
  List<BrandedProgram> get filteredPrograms {
    var result = programs;

    // Filter by category
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      result = result
          .where((p) =>
              p.category?.toLowerCase() == selectedCategory!.toLowerCase())
          .toList();
    }

    // Filter by difficulty
    if (selectedDifficulty != null && selectedDifficulty!.isNotEmpty) {
      result = result
          .where((p) =>
              p.difficultyLevel?.toLowerCase() ==
              selectedDifficulty!.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.category?.toLowerCase().contains(query) ?? false) ||
            (p.description?.toLowerCase().contains(query) ?? false) ||
            (p.celebrityName?.toLowerCase().contains(query) ?? false) ||
            (p.tags?.any((t) => t.toLowerCase().contains(query)) ?? false) ||
            (p.goals?.any((g) => g.toLowerCase().contains(query)) ?? false);
      }).toList();
    }

    return result;
  }
}

/// State for user's current program
class CurrentProgramState {
  final UserProgram? currentProgram;
  final bool isLoading;
  final bool isAssigning;
  final String? error;

  const CurrentProgramState({
    this.currentProgram,
    this.isLoading = false,
    this.isAssigning = false,
    this.error,
  });

  CurrentProgramState copyWith({
    UserProgram? currentProgram,
    bool? isLoading,
    bool? isAssigning,
    String? error,
    bool clearProgram = false,
    bool clearError = false,
  }) {
    return CurrentProgramState(
      currentProgram:
          clearProgram ? null : (currentProgram ?? this.currentProgram),
      isLoading: isLoading ?? this.isLoading,
      isAssigning: isAssigning ?? this.isAssigning,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasActiveProgram => currentProgram?.isActive == true;
}

// ============================================================================
// NOTIFIERS
// ============================================================================

/// Notifier for branded programs list
class BrandedProgramsNotifier extends StateNotifier<BrandedProgramsState> {
  final BrandedProgramRepository _repository;

  BrandedProgramsNotifier(this._repository)
      : super(const BrandedProgramsState()) {
    loadPrograms();
  }

  /// Load all branded programs
  Future<void> loadPrograms() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load programs, featured, and categories in parallel
      final results = await Future.wait([
        _repository.getBrandedPrograms(),
        _repository.getFeaturedPrograms(),
        _repository.getCategories(),
      ]);

      state = state.copyWith(
        programs: results[0] as List<BrandedProgram>,
        featuredPrograms: results[1] as List<BrandedProgram>,
        categories: results[2] as List<String>,
        isLoading: false,
      );
      debugPrint('✅ [BrandedProgramsProvider] Loaded programs');
    } catch (e) {
      debugPrint('❌ [BrandedProgramsProvider] Error loading programs: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load programs: $e',
      );
    }
  }

  /// Set category filter
  void setCategory(String? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Set difficulty filter
  void setDifficulty(String? difficulty) {
    if (difficulty == state.selectedDifficulty) {
      state = state.copyWith(clearDifficulty: true);
    } else {
      state = state.copyWith(selectedDifficulty: difficulty);
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearDifficulty: true,
    );
  }

  /// Refresh programs
  Future<void> refresh() async {
    await loadPrograms();
  }
}

/// Notifier for user's current program
class CurrentProgramNotifier extends StateNotifier<CurrentProgramState> {
  final BrandedProgramRepository _repository;
  String? _currentUserId;

  CurrentProgramNotifier(this._repository)
      : super(const CurrentProgramState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
    loadCurrentProgram(userId: userId);
  }

  /// Load user's current program
  Future<void> loadCurrentProgram({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [CurrentProgramProvider] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final program = await _repository.getCurrentProgram(userId: uid);
      state = state.copyWith(
        currentProgram: program,
        isLoading: false,
      );
      debugPrint('✅ [CurrentProgramProvider] Loaded current program');
    } catch (e) {
      debugPrint('❌ [CurrentProgramProvider] Error loading program: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load current program: $e',
      );
    }
  }

  /// Assign a new program
  Future<bool> assignProgram({
    required String programId,
    String? customName,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [CurrentProgramProvider] No user ID for assign');
      return false;
    }

    state = state.copyWith(isAssigning: true, clearError: true);

    try {
      final userProgram = await _repository.assignProgram(
        userId: uid,
        programId: programId,
        customName: customName,
      );

      if (userProgram != null) {
        state = state.copyWith(
          currentProgram: userProgram,
          isAssigning: false,
        );
        debugPrint('✅ [CurrentProgramProvider] Program assigned');
        return true;
      }

      state = state.copyWith(
        isAssigning: false,
        error: 'Failed to assign program',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [CurrentProgramProvider] Error assigning program: $e');
      state = state.copyWith(
        isAssigning: false,
        error: 'Failed to assign program: $e',
      );
      return false;
    }
  }

  /// Rename current program
  Future<bool> renameProgram(String newName, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;

    try {
      final updated = await _repository.renameProgram(
        userId: uid,
        newName: newName,
      );

      if (updated != null) {
        state = state.copyWith(currentProgram: updated);
        debugPrint('✅ [CurrentProgramProvider] Program renamed');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [CurrentProgramProvider] Error renaming program: $e');
      state = state.copyWith(error: 'Failed to rename program: $e');
      return false;
    }
  }

  /// End current program
  Future<bool> endProgram({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;

    try {
      final success = await _repository.endProgram(userId: uid);
      if (success) {
        state = state.copyWith(clearProgram: true);
        debugPrint('✅ [CurrentProgramProvider] Program ended');
      }
      return success;
    } catch (e) {
      debugPrint('❌ [CurrentProgramProvider] Error ending program: $e');
      state = state.copyWith(error: 'Failed to end program: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh
  Future<void> refresh({String? userId}) async {
    await loadCurrentProgram(userId: userId);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main branded programs provider
final brandedProgramsProvider =
    StateNotifierProvider<BrandedProgramsNotifier, BrandedProgramsState>((ref) {
  final repository = ref.watch(brandedProgramRepositoryProvider);
  return BrandedProgramsNotifier(repository);
});

/// Current user program provider
final currentProgramProvider =
    StateNotifierProvider<CurrentProgramNotifier, CurrentProgramState>((ref) {
  final repository = ref.watch(brandedProgramRepositoryProvider);
  return CurrentProgramNotifier(repository);
});

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

/// All branded programs list
final allBrandedProgramsProvider = Provider<List<BrandedProgram>>((ref) {
  return ref.watch(brandedProgramsProvider).programs;
});

/// Featured programs list
final featuredProgramsProvider = Provider<List<BrandedProgram>>((ref) {
  return ref.watch(brandedProgramsProvider).featuredPrograms;
});

/// Filtered programs (with applied filters)
final filteredBrandedProgramsProvider = Provider<List<BrandedProgram>>((ref) {
  return ref.watch(brandedProgramsProvider).filteredPrograms;
});

/// Program categories list
final programCategoriesListProvider = Provider<List<String>>((ref) {
  return ref.watch(brandedProgramsProvider).categories;
});

/// Selected category filter
final selectedBrandedCategoryProvider = Provider<String?>((ref) {
  return ref.watch(brandedProgramsProvider).selectedCategory;
});

/// Programs loading state
final brandedProgramsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(brandedProgramsProvider).isLoading;
});

/// User's active program
final activeUserProgramProvider = Provider<UserProgram?>((ref) {
  return ref.watch(currentProgramProvider).currentProgram;
});

/// Whether user has an active program
final hasActiveProgramProvider = Provider<bool>((ref) {
  return ref.watch(currentProgramProvider).hasActiveProgram;
});

/// Current program name (for display)
final currentProgramNameProvider = Provider<String?>((ref) {
  final userProgram = ref.watch(activeUserProgramProvider);
  return userProgram?.displayName;
});

/// Program assign loading state
final isProgramAssigningProvider = Provider<bool>((ref) {
  return ref.watch(currentProgramProvider).isAssigning;
});

// ============================================================================
// FUTURE PROVIDERS
// ============================================================================

/// Single program by ID
final brandedProgramByIdProvider =
    FutureProvider.family<BrandedProgram?, String>((ref, programId) async {
  final repository = ref.watch(brandedProgramRepositoryProvider);
  return repository.getProgram(programId);
});

/// Program history for current user
final programHistoryProvider =
    FutureProvider.family<List<UserProgram>, String>((ref, userId) async {
  final repository = ref.watch(brandedProgramRepositoryProvider);
  return repository.getProgramHistory(userId: userId);
});
