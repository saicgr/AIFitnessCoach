import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/recipe_suggestion.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRecipeDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with match score
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.recipeName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(recipe.cuisine.toUpperCase(), textSecondary),
                            const SizedBox(width: 8),
                            _buildChip(recipe.category.toUpperCase(), textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Match score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(recipe.overallMatchScore).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          size: 16,
                          color: _getScoreColor(recipe.overallMatchScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.overallMatchScore}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                style: TextStyle(color: textSecondary, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Why this recipe
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
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
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Nutrition info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNutrientInfo(
                    'Calories',
                    '${recipe.caloriesPerServing}',
                    textPrimary,
                    textSecondary,
                  ),
                  _buildNutrientInfo(
                    'Protein',
                    '${recipe.proteinPerServingG.round()}g',
                    textPrimary,
                    textSecondary,
                  ),
                  _buildNutrientInfo(
                    'Carbs',
                    '${recipe.carbsPerServingG.round()}g',
                    textPrimary,
                    textSecondary,
                  ),
                  _buildNutrientInfo(
                    'Fat',
                    '${recipe.fatPerServingG.round()}g',
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time and servings
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    recipe.formattedTotalTime,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.servings} servings',
                    style: TextStyle(color: textSecondary, fontSize: 13),
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
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSave,
                      icon: Icon(
                        recipe.userSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(recipe.userSaved ? 'Saved' : 'Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: recipe.userSaved ? accent : textSecondary,
                        side: BorderSide(
                          color: recipe.userSaved ? accent : textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCook,
                      icon: const Icon(Icons.restaurant),
                      label: Text(
                        recipe.timesCooked > 0 ? 'Cook Again' : 'I Made This',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.background : AppColorsLight.background;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  Text(
                    recipe.recipeName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.recipeDescription,
                    style: TextStyle(color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  // Match scores
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match Analysis',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
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
                  Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
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
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
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
                  Text(
                    'Rate This Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
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
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onSave();
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            recipe.userSaved ? Icons.bookmark : Icons.bookmark_border,
                          ),
                          label: Text(recipe.userSaved ? 'Saved' : 'Save Recipe'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onCook();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.restaurant),
                          label: const Text('I Made This'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
