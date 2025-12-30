import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_suggestion.dart';
import '../repositories/recipe_suggestion_repository.dart';

/// State for recipe suggestions
class RecipeSuggestionState {
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final List<RecipeSuggestion> currentSuggestions;
  final List<RecipeSuggestion> savedRecipes;
  final List<CuisineInfo> availableCuisines;
  final List<BodyTypeInfo> availableBodyTypes;
  final String? lastSessionId;

  const RecipeSuggestionState({
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.currentSuggestions = const [],
    this.savedRecipes = const [],
    this.availableCuisines = const [],
    this.availableBodyTypes = const [],
    this.lastSessionId,
  });

  RecipeSuggestionState copyWith({
    bool? isLoading,
    bool? isGenerating,
    String? error,
    List<RecipeSuggestion>? currentSuggestions,
    List<RecipeSuggestion>? savedRecipes,
    List<CuisineInfo>? availableCuisines,
    List<BodyTypeInfo>? availableBodyTypes,
    String? lastSessionId,
  }) {
    return RecipeSuggestionState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentSuggestions: currentSuggestions ?? this.currentSuggestions,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      availableCuisines: availableCuisines ?? this.availableCuisines,
      availableBodyTypes: availableBodyTypes ?? this.availableBodyTypes,
      lastSessionId: lastSessionId ?? this.lastSessionId,
    );
  }
}

/// Provider for recipe suggestion state
final recipeSuggestionProvider =
    StateNotifierProvider<RecipeSuggestionNotifier, RecipeSuggestionState>((ref) {
  return RecipeSuggestionNotifier(ref.watch(recipeSuggestionRepositoryProvider));
});

/// Notifier for recipe suggestion state management
class RecipeSuggestionNotifier extends StateNotifier<RecipeSuggestionState> {
  final RecipeSuggestionRepository _repository;

  RecipeSuggestionNotifier(this._repository)
      : super(const RecipeSuggestionState());

  /// Initialize data (cuisines, body types)
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cuisines = await _repository.getCuisines();
      final bodyTypes = await _repository.getBodyTypes();
      state = state.copyWith(
        isLoading: false,
        availableCuisines: cuisines,
        availableBodyTypes: bodyTypes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Generate new recipe suggestions
  Future<void> generateSuggestions({
    required String userId,
    String mealType = 'any',
    int count = 3,
    String? additionalRequirements,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final response = await _repository.suggestRecipes(
        userId: userId,
        mealType: mealType,
        count: count,
        additionalRequirements: additionalRequirements,
      );

      if (response.success) {
        state = state.copyWith(
          isGenerating: false,
          currentSuggestions: response.recipes,
          lastSessionId: response.sessionId,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: response.error ?? 'Failed to generate suggestions',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Load saved recipes
  Future<void> loadSavedRecipes(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final saved = await _repository.getSuggestions(
        userId: userId,
        savedOnly: true,
      );
      state = state.copyWith(
        isLoading: false,
        savedRecipes: saved,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Rate a recipe
  Future<bool> rateRecipe({
    required String userId,
    required String suggestionId,
    required int rating,
  }) async {
    final success = await _repository.rateRecipe(
      userId: userId,
      suggestionId: suggestionId,
      rating: rating,
    );

    if (success) {
      // Update local state
      state = state.copyWith(
        currentSuggestions: state.currentSuggestions.map((r) {
          if (r.id == suggestionId) {
            return r.copyWith(userRating: rating);
          }
          return r;
        }).toList(),
        savedRecipes: state.savedRecipes.map((r) {
          if (r.id == suggestionId) {
            return r.copyWith(userRating: rating);
          }
          return r;
        }).toList(),
      );
    }

    return success;
  }

  /// Save or unsave a recipe
  Future<bool> toggleSaveRecipe({
    required String userId,
    required String suggestionId,
    required bool save,
  }) async {
    final success = await _repository.saveRecipe(
      userId: userId,
      suggestionId: suggestionId,
      save: save,
    );

    if (success) {
      // Update local state
      state = state.copyWith(
        currentSuggestions: state.currentSuggestions.map((r) {
          if (r.id == suggestionId) {
            return r.copyWith(userSaved: save);
          }
          return r;
        }).toList(),
      );

      // Refresh saved recipes list
      if (save) {
        final recipe = state.currentSuggestions.firstWhere(
          (r) => r.id == suggestionId,
          orElse: () => state.savedRecipes.firstWhere((r) => r.id == suggestionId),
        );
        if (!state.savedRecipes.any((r) => r.id == suggestionId)) {
          state = state.copyWith(
            savedRecipes: [...state.savedRecipes, recipe.copyWith(userSaved: true)],
          );
        }
      } else {
        state = state.copyWith(
          savedRecipes: state.savedRecipes.where((r) => r.id != suggestionId).toList(),
        );
      }
    }

    return success;
  }

  /// Mark recipe as cooked
  Future<bool> markAsCooked({
    required String userId,
    required String suggestionId,
  }) async {
    final success = await _repository.markAsCooked(
      userId: userId,
      suggestionId: suggestionId,
    );

    if (success) {
      // Update times_cooked in local state
      state = state.copyWith(
        currentSuggestions: state.currentSuggestions.map((r) {
          if (r.id == suggestionId) {
            return r.copyWith(timesCooked: r.timesCooked + 1);
          }
          return r;
        }).toList(),
        savedRecipes: state.savedRecipes.map((r) {
          if (r.id == suggestionId) {
            return r.copyWith(timesCooked: r.timesCooked + 1);
          }
          return r;
        }).toList(),
      );
    }

    return success;
  }

  /// Update recipe preferences
  Future<bool> updatePreferences({
    required String userId,
    String? bodyType,
    List<String>? favoriteCuisines,
    String? culturalBackground,
    String? spiceTolerance,
  }) async {
    return await _repository.updateRecipePreferences(
      userId: userId,
      bodyType: bodyType,
      favoriteCuisines: favoriteCuisines,
      culturalBackground: culturalBackground,
      spiceTolerance: spiceTolerance,
    );
  }

  /// Clear current suggestions
  void clearSuggestions() {
    state = state.copyWith(currentSuggestions: [], lastSessionId: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for available cuisines (cached)
final availableCuisinesProvider = FutureProvider<List<CuisineInfo>>((ref) async {
  final repository = ref.watch(recipeSuggestionRepositoryProvider);
  return await repository.getCuisines();
});

/// Provider for available body types (cached)
final availableBodyTypesProvider = FutureProvider<List<BodyTypeInfo>>((ref) async {
  final repository = ref.watch(recipeSuggestionRepositoryProvider);
  return await repository.getBodyTypes();
});
