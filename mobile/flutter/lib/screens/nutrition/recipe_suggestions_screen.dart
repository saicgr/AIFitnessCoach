import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/recipe_suggestion.dart';
import '../../data/providers/recipe_suggestion_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/xp_provider.dart';
import 'widgets/recipe_suggestion_card.dart';
import 'widgets/recipe_preferences_sheet.dart';

/// Screen for AI-powered recipe suggestions based on body type, culture, and diet
class RecipeSuggestionsScreen extends ConsumerStatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  ConsumerState<RecipeSuggestionsScreen> createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends ConsumerState<RecipeSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealType _selectedMealType = MealType.any;
  final TextEditingController _requirementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipeSuggestionProvider.notifier).initialize();
      _loadSavedRecipes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRecipes() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null) {
      ref.read(recipeSuggestionProvider.notifier).loadSavedRecipes(user.id);
    }
  }

  Future<void> _generateSuggestions() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null) {
      ref.read(recipeSuggestionProvider.notifier).generateSuggestions(
        userId: user.id,
        mealType: _selectedMealType.value,
        count: 3,
        additionalRequirements: _requirementsController.text.isNotEmpty
            ? _requirementsController.text
            : null,
      );
    }
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecipePreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(recipeSuggestionProvider);
    final background = isDark ? AppColors.background : AppColorsLight.background;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Recipe Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showPreferencesSheet,
            tooltip: 'Recipe Preferences',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Suggestions'),
            Tab(text: 'Saved'),
          ],
          labelColor: accent,
          unselectedLabelColor: textSecondary,
          indicatorColor: accent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Suggestions Tab
          _buildSuggestionsTab(
            isDark: isDark,
            state: state,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accent: accent,
          ),
          // Saved Tab
          _buildSavedTab(
            isDark: isDark,
            state: state,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab({
    required bool isDark,
    required RecipeSuggestionState state,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    return CustomScrollView(
      slivers: [
        // Meal type selector and generate button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What meal are you planning?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Meal type chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MealType.values.map((type) {
                      final isSelected = type == _selectedMealType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedMealType = type);
                            }
                          },
                          selectedColor: accent.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? accent : textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Additional requirements
                TextField(
                  controller: _requirementsController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Any specific requirements? (e.g., under 400 cal, high fiber)',
                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
                const SizedBox(height: 16),
                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isGenerating ? null : _generateSuggestions,
                    icon: state.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      state.isGenerating ? 'Generating...' : 'Generate Suggestions',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (state.error != null)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      ref.read(recipeSuggestionProvider.notifier).clearError();
                    },
                  ),
                ],
              ),
            ),
          ),

        // Suggestions list
        if (state.currentSuggestions.isEmpty && !state.isGenerating)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No suggestions yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Generate Suggestions" to get AI-powered recipe ideas based on your preferences',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = state.currentSuggestions[index];
                return RecipeSuggestionCard(
                  recipe: recipe,
                  onSave: () => _toggleSave(recipe),
                  onRate: (rating) => _rateRecipe(recipe, rating),
                  onCook: () => _markAsCooked(recipe),
                );
              },
              childCount: state.currentSuggestions.length,
            ),
          ),
      ],
    );
  }

  Widget _buildSavedTab({
    required bool isDark,
    required RecipeSuggestionState state,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.savedRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 64,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No saved recipes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save recipes you like to find them here later',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.savedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = state.savedRecipes[index];
        return RecipeSuggestionCard(
          recipe: recipe,
          onSave: () => _toggleSave(recipe),
          onRate: (rating) => _rateRecipe(recipe, rating),
          onCook: () => _markAsCooked(recipe),
        );
      },
    );
  }

  Future<void> _toggleSave(RecipeSuggestion recipe) async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null && recipe.id != null) {
      final wasSaved = recipe.userSaved;

      ref.read(recipeSuggestionProvider.notifier).toggleSaveRecipe(
        userId: user.id,
        suggestionId: recipe.id!,
        save: !wasSaved,
      );

      // Check for first recipe XP bonus when SAVING (not unsaving)
      if (!wasSaved) {
        final xpAwarded = await ref.read(xpProvider.notifier).checkFirstRecipeBonus();
        if (xpAwarded > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipe saved! +$xpAwarded XP first recipe bonus!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _rateRecipe(RecipeSuggestion recipe, int rating) async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null && recipe.id != null) {
      ref.read(recipeSuggestionProvider.notifier).rateRecipe(
        userId: user.id,
        suggestionId: recipe.id!,
        rating: rating,
      );
    }
  }

  Future<void> _markAsCooked(RecipeSuggestion recipe) async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null && recipe.id != null) {
      ref.read(recipeSuggestionProvider.notifier).markAsCooked(
        userId: user.id,
        suggestionId: recipe.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as cooked!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
