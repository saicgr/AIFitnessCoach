/// Bottom-sheet recipe detail for a From-Your-Fridge suggestion: title, match
/// badge, macro strip, the have/need ingredient checklist, and Save / Log meal
/// / Cook mode actions. Wires to real persistence (createRecipe / logAdjustedFood).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/nutrition_repository.dart';
import 'fridge_cook_mode.dart';
import 'fridge_dish_card.dart';

class FridgeRecipeDetailSheet extends ConsumerStatefulWidget {
  final PantrySuggestion suggestion;
  final String userId;
  const FridgeRecipeDetailSheet({
    super.key,
    required this.suggestion,
    required this.userId,
  });

  @override
  ConsumerState<FridgeRecipeDetailSheet> createState() =>
      _FridgeRecipeDetailSheetState();
}

class _FridgeRecipeDetailSheetState extends ConsumerState<FridgeRecipeDetailSheet> {
  bool _saving = false;
  bool _logging = false;

  PantrySuggestion get s => widget.suggestion;

  /// Infer a meal type from the current hour so the log lands sensibly without
  /// forcing the user to pick.
  String _inferMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return 'breakfast';
    if (h < 16) return 'lunch';
    if (h < 21) return 'dinner';
    return 'snack';
  }

  Future<void> _logMeal() async {
    final cals = s.caloriesPerServing ?? 0;
    final protein = (s.proteinPerServingG ?? 0).round();
    final carbs = (s.carbsPerServingG ?? 0).round();
    final fat = (s.fatPerServingG ?? 0).round();
    await ref.read(nutritionRepositoryProvider).logAdjustedFood(
          userId: widget.userId,
          mealType: _inferMealType(),
          foodItems: [
            {
              'name': s.name,
              'calories': cals,
              'protein_g': protein,
              'carbs_g': carbs,
              'fat_g': fat,
            }
          ],
          totalCalories: cals,
          totalProtein: protein,
          totalCarbs: carbs,
          totalFat: fat,
          totalFiber: s.fiberPerServingG?.round(),
          sourceType: 'manual',
          inputType: 'ai_suggestion',
        );
  }

  Future<void> _onLogPressed() async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      await _logMeal();
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack('Logged ${s.name} ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _logging = false);
      _snack('Could not log meal: ${_clean(e)}');
    }
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ingredients = <RecipeIngredientCreate>[
        for (final n in s.matchedPantryItems)
          RecipeIngredientCreate(foodName: n, amount: 1, unit: 'serving'),
        for (final n in s.missingIngredients)
          RecipeIngredientCreate(
              foodName: n, amount: 1, unit: 'serving', isOptional: true),
      ];
      await ref.read(nutritionRepositoryProvider).createRecipe(
            userId: widget.userId,
            request: RecipeCreate(
              name: s.name,
              description: s.description,
              servings: s.servings,
              prepTimeMinutes: s.prepTimeMinutes,
              cookTimeMinutes: s.cookTimeMinutes,
              instructions: s.instructions.isEmpty ? null : s.instructions.join('\n'),
              imageUrl: s.imageUrl,
              category: s.category,
              cuisine: s.cuisine,
              ingredients: ingredients,
            ),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Saved to your recipes ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save: ${_clean(e)}');
    }
  }

  void _startCook() {
    // Push Cook Mode ON TOP of this sheet (do NOT pop first): the "DONE — log
    // it" callback is `_logMeal`, which reads this widget's `ref`, so the sheet
    // must stay mounted underneath while Cook Mode runs.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FridgeCookMode(suggestion: s, onDone: _logMeal),
    ));
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final amber = tc.warning;
    final hasSteps = s.instructions.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: tc.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(s.name.toUpperCase(),
                            style: ZType.disp(23, color: tc.textPrimary)
                                .copyWith(height: 1.12)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: accent.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${s.overallMatchScore.clamp(0, 100)}% MATCH',
                            style: ZType.lbl(10, color: accent, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  if (s.suggestionReason != null) ...[
                    const SizedBox(height: 6),
                    Text(s.suggestionReason!,
                        style: TextStyle(color: tc.textMuted, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 14),
                  FridgeStatStrip(s: s, onDark: false),
                  const SizedBox(height: 20),
                  Text('INGREDIENTS · ✓ IN YOUR FRIDGE',
                      style: ZType.lbl(12, color: tc.textSecondary, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  for (final n in s.matchedPantryItems)
                    _ingRow(n, matched: true, accent: accent, amber: amber, tc: tc),
                  for (final n in s.missingIngredients)
                    _ingRow(n, matched: false, accent: accent, amber: amber, tc: tc),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _btn(
                          label: _saving ? 'SAVING…' : 'SAVE',
                          primary: false,
                          tc: tc,
                          onTap: _saving ? null : _onSavePressed,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _btn(
                          label: _logging ? 'LOGGING…' : 'LOG MEAL',
                          primary: false,
                          tc: tc,
                          onTap: _logging ? null : _onLogPressed,
                        ),
                      ),
                    ],
                  ),
                  if (hasSteps) ...[
                    const SizedBox(height: 9),
                    _btn(
                      label: '▶ COOK MODE',
                      primary: true,
                      tc: tc,
                      onTap: _startCook,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingRow(String name,
      {required bool matched,
      required Color accent,
      required Color amber,
      required ThemeColors tc}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Icon(matched ? Icons.check : Icons.add,
                size: 15, color: matched ? accent : amber),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: matched ? tc.textPrimary : amber, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String label,
    required bool primary,
    required ThemeColors tc,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? tc.accent : Colors.transparent,
            border: primary ? null : Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: ZType.lbl(14,
                color: primary ? tc.accentContrast : tc.textPrimary,
                letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}
