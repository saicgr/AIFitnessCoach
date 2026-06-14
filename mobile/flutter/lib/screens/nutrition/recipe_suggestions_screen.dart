import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../core/services/posthog_service.dart';
import '../../data/models/recipe_suggestion.dart';
import '../../data/providers/recipe_suggestion_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/recipe_suggestion_card.dart';
import 'widgets/recipe_preferences_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen for AI-powered recipe suggestions based on body type, culture, and diet
class RecipeSuggestionsScreen extends ConsumerStatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  ConsumerState<RecipeSuggestionsScreen> createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends ConsumerState<RecipeSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  MealType _selectedMealType = MealType.any;
  final TextEditingController _requirementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && _tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
      }
    });

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
      ref.read(posthogServiceProvider).capture(
        eventName: 'recipe_generated',
        properties: <String, Object>{
          'meal_type': _selectedMealType.value,
          'has_requirements': _requirementsController.text.isNotEmpty,
        },
      );
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
    showGlassSheet(
      context: context,
      builder: (context) => const GlassSheet(
        child: RecipePreferencesSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;
    final state = ref.watch(recipeSuggestionProvider);
    final background = tc.background;
    final surface = tc.surface;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final accent = tc.accent;

    return Scaffold(
      backgroundColor: background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).recipeSuggestionsRecipeSuggestions,
        titleSize: 26,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: textSecondary),
            onPressed: _showPreferencesSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ZealovaTextTabs(
                tabs: [
                  AppLocalizations.of(context).unresolvedExercisesSuggestions,
                  AppLocalizations.of(context).savedHubSaved,
                ],
                activeIndex: _tabIndex,
                onChanged: (i) {
                  setState(() => _tabIndex = i);
                  _tabController.animateTo(i);
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
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
                ZealovaSectionKicker(
                  AppLocalizations.of(context).recipeSuggestionsWhatMealAreYou,
                  fontSize: 12,
                ),
                const SizedBox(height: 12),
                // Meal type chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MealType.values.map((type) {
                    final isSelected = type == _selectedMealType;
                    return ZealovaChip(
                      label: type.displayName,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedMealType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Additional requirements
                TextField(
                  controller: _requirementsController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).recipeSuggestionsAnySpecificRequirementsE,
                    hintStyle: ZType.lbl(13, color: textSecondary, letterSpacing: 1.0),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent),
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
                ZealovaButton(
                  label: state.isGenerating
                      ? AppLocalizations.of(context).upcomingWorkoutsGenerating
                      : AppLocalizations.of(context).recipeSuggestionsGenerateSuggestions,
                  onTap: state.isGenerating ? null : _generateSuggestions,
                  variant: ZealovaButtonVariant.primary,
                  trailingIcon: state.isGenerating ? null : Icons.auto_awesome,
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
                color: surface,
                border: Border.all(
                    color: ThemeColors.of(context).error.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: ThemeColors.of(context).error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: ThemeColors.of(context).error),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: ThemeColors.of(context).error),
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
                      AppLocalizations.of(context).regenerateWorkoutSheetNoSuggestionsYet,
                      textAlign: TextAlign.center,
                      style: ZType.disp(22, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).recipeSuggestionsTapGenerateSuggestionsTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, height: 1.4),
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
      // Layout-matched skeleton rows instead of a blocking centered spinner —
      // mirrors the saved-recipe card list below.
      return const SkeletonList(
        scrollable: true,
        itemCount: 6,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemBuilder: _suggestionSkeletonRow,
      );
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
                AppLocalizations.of(context).recipeSuggestionsNoSavedRecipes,
                textAlign: TextAlign.center,
                style: ZType.disp(22, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).recipeSuggestionsSaveRecipesYouLike,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, height: 1.4),
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
          SnackBar(
            content: Text(AppLocalizations.of(context).recipeSuggestionsMarkedAsCooked),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Skeleton row for the Saved tab loading state — a thumbnail + 2 text lines,
/// roughly matching a [RecipeSuggestionCard]'s shape so the skeleton→content
/// swap is reflow-free. Top-level so it can be a `const` tear-off.
Widget _suggestionSkeletonRow(BuildContext context, int index) =>
    const SkeletonCard(
      showLeading: true,
      leadingSize: 64,
      lines: 3,
    );
