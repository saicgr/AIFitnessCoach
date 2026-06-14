import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/recipe_suggestion.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card widget for displaying a recipe suggestion
class RecipeSuggestionCard extends StatelessWidget {
  final RecipeSuggestion recipe;
  final VoidCallback onSave;
  final Function(int) onRate;
  final VoidCallback onCook;

  const RecipeSuggestionCard({
    super.key,
    required this.recipe,
    required this.onSave,
    required this.onRate,
    required this.onCook,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final accent = tc.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        padding: const EdgeInsets.all(16),
        onTap: () => _showRecipeDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with match score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.recipeName,
                        style: ZType.disp(20, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChip(recipe.cuisine.toUpperCase(), textMuted),
                          _buildChip(recipe.category.toUpperCase(), textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Match score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _getScoreColor(recipe.overallMatchScore).withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: _getScoreColor(recipe.overallMatchScore),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.overallMatchScore}%',
                        style: ZType.data(
                          13,
                          color: _getScoreColor(recipe.overallMatchScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              recipe.recipeDescription,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Why this recipe
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tc.surface,
                border: const Border(
                  left: BorderSide(color: AppColors.cardBorder, width: 3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recipe.suggestionReason,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Nutrition info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutrientInfo(
                  'Calories',
                  '${recipe.caloriesPerServing}',
                  textPrimary,
                  textMuted,
                ),
                _buildNutrientInfo(
                  'Protein',
                  '${recipe.proteinPerServingG.round()}g',
                  AppColors.macroProtein,
                  textMuted,
                ),
                _buildNutrientInfo(
                  'Carbs',
                  '${recipe.carbsPerServingG.round()}g',
                  AppColors.macroCarbs,
                  textMuted,
                ),
                _buildNutrientInfo(
                  'Fat',
                  '${recipe.fatPerServingG.round()}g',
                  AppColors.macroFat,
                  textMuted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const ZealovaRule(),
            const SizedBox(height: 12),
            // Time and servings
            Row(
              children: [
                Icon(Icons.access_time, size: 15, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  recipe.formattedTotalTime.toUpperCase(),
                  style: ZType.lbl(11, color: textMuted, letterSpacing: 1.0),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people_outline, size: 15, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  '${recipe.servings} SERVINGS',
                  style: ZType.lbl(11, color: textMuted, letterSpacing: 1.0),
                ),
                const Spacer(),
                // Rating
                if (recipe.userRating != null)
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < recipe.userRating! ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ZealovaButton(
                    label: recipe.userSaved
                        ? AppLocalizations.of(context).savedHubSaved
                        : AppLocalizations.of(context).buttonSave,
                    onTap: onSave,
                    variant: ZealovaButtonVariant.ghost,
                    trailingIcon: recipe.userSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ZealovaButton(
                    label: recipe.timesCooked > 0
                        ? AppLocalizations.of(context).recipeSuggestionCardCookAgain
                        : AppLocalizations.of(context).recipeSuggestionCardIMadeThis,
                    onTap: onCook,
                    variant: ZealovaButtonVariant.primary,
                    trailingIcon: Icons.restaurant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ZType.lbl(9, color: color, letterSpacing: 1.3),
      ),
    );
  }

  Widget _buildNutrientInfo(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: ZType.disp(18, color: valueColor),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: labelColor, letterSpacing: 1.3),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }

  void _showRecipeDetails(BuildContext context) {
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final accent = tc.accent;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        maxHeightFraction: 0.95,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  Text(
                    recipe.recipeName,
                    style: ZType.disp(26, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.recipeDescription,
                    style: TextStyle(color: textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // Match scores
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZealovaSectionKicker(
                          AppLocalizations.of(context).recipeSuggestionCardMatchAnalysis,
                        ),
                        const SizedBox(height: 12),
                        _buildScoreRow('Goal Alignment', recipe.goalAlignmentScore, textPrimary),
                        _buildScoreRow('Cuisine Match', recipe.cuisineMatchScore, textPrimary),
                        _buildScoreRow('Diet Compliance', recipe.dietComplianceScore, textPrimary),
                        const Divider(height: 24),
                        _buildScoreRow('Overall Match', recipe.overallMatchScore, textPrimary, isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ingredients
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).recipeSuggestionCardIngredients,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${ing.amount} ${ing.unit} ${ing.name}',
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                        if (ing.calories != null)
                          Text(
                            '${ing.calories} cal',
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  // Instructions
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).workoutShowcaseInstructions,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 12),
                  ...recipe.instructions.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  // Rate this recipe
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).recipeSuggestionCardRateThisRecipe,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return IconButton(
                        icon: Icon(
                          (recipe.userRating ?? 0) >= rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 36,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          onRate(rating);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ZealovaButton(
                          label: recipe.userSaved
                              ? AppLocalizations.of(context).savedHubSaved
                              : AppLocalizations.of(context).recipeSuggestionCardSaveRecipe,
                          onTap: () {
                            onSave();
                            Navigator.pop(context);
                          },
                          variant: ZealovaButtonVariant.ghost,
                          trailingIcon:
                              recipe.userSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZealovaButton(
                          label: AppLocalizations.of(context).recipeSuggestionCardIMadeThis,
                          onTap: () {
                            onCook();
                            Navigator.pop(context);
                          },
                          variant: ZealovaButtonVariant.primary,
                          trailingIcon: Icons.restaurant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color textPrimary, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getScoreColor(score),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$score%',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: _getScoreColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
