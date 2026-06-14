import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/nutrition/cooking_converter_sheet.dart';
import '../../widgets/nutrition/batch_portioning_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
part 'recipe_builder_sheet_part_ingredient_entry.dart';


/// Recipe Builder Sheet - Create custom recipes with multiple ingredients
class RecipeBuilderSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final Recipe? existingRecipe; // For editing

  const RecipeBuilderSheet({
    super.key,
    required this.userId,
    required this.isDark,
    this.existingRecipe,
  });

  @override
  ConsumerState<RecipeBuilderSheet> createState() => _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends ConsumerState<RecipeBuilderSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();

  RecipeCategory _selectedCategory = RecipeCategory.other;
  final List<_IngredientEntry> _ingredients = [];
  bool _isSaving = false;
  bool _isPublic = false; // Recipe sharing toggle
  String? _error;

  // Calculated totals
  int get _totalCalories =>
      _ingredients.fold(0, (sum, i) => sum + (i.calories ?? 0));
  double get _totalProtein =>
      _ingredients.fold(0.0, (sum, i) => sum + (i.proteinG ?? 0));
  double get _totalCarbs =>
      _ingredients.fold(0.0, (sum, i) => sum + (i.carbsG ?? 0));
  double get _totalFat =>
      _ingredients.fold(0.0, (sum, i) => sum + (i.fatG ?? 0));
  double get _totalFiber =>
      _ingredients.fold(0.0, (sum, i) => sum + (i.fiberG ?? 0));

  int get _servings => int.tryParse(_servingsController.text) ?? 1;

  int get _caloriesPerServing =>
      _servings > 0 ? (_totalCalories / _servings).round() : _totalCalories;
  double get _proteinPerServing =>
      _servings > 0 ? _totalProtein / _servings : _totalProtein;
  double get _carbsPerServing =>
      _servings > 0 ? _totalCarbs / _servings : _totalCarbs;
  double get _fatPerServing =>
      _servings > 0 ? _totalFat / _servings : _totalFat;
  double get _fiberPerServing =>
      _servings > 0 ? _totalFiber / _servings : _totalFiber;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecipe != null) {
      _loadExistingRecipe(widget.existingRecipe!);
    }
  }

  void _loadExistingRecipe(Recipe recipe) {
    _nameController.text = recipe.name;
    _descriptionController.text = recipe.description ?? '';
    _instructionsController.text = recipe.instructions ?? '';
    _servingsController.text = recipe.servings.toString();
    _prepTimeController.text = recipe.prepTimeMinutes?.toString() ?? '';
    _cookTimeController.text = recipe.cookTimeMinutes?.toString() ?? '';
    _selectedCategory = recipe.categoryEnum;
    _isPublic = recipe.isPublic;

    // Load ingredients
    for (final ingredient in recipe.ingredients) {
      _ingredients.add(_IngredientEntry(
        name: ingredient.foodName,
        amount: ingredient.amount,
        unit: ingredient.unit,
        calories: ingredient.caloriesInt,
        proteinG: ingredient.proteinG,
        carbsG: ingredient.carbsG,
        fatG: ingredient.fatG,
        fiberG: ingredient.fiberG,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final result = await showGlassSheet<_IngredientEntry>(
      context: context,
      builder: (context) => GlassSheet(
        child: _AddIngredientSheet(
          userId: widget.userId,
          isDark: widget.isDark,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients.add(result);
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a recipe name');
      return;
    }

    if (_ingredients.isEmpty) {
      setState(() => _error = 'Please add at least one ingredient');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      final recipeCreate = RecipeCreate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        servings: _servings,
        prepTimeMinutes: int.tryParse(_prepTimeController.text),
        cookTimeMinutes: int.tryParse(_cookTimeController.text),
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        category: _selectedCategory.value,
        sourceType: 'manual',
        isPublic: _isPublic,
        ingredients: _ingredients.map((i) => RecipeIngredientCreate(
          foodName: i.name,
          amount: i.amount,
          unit: i.unit,
          calories: i.calories?.toDouble(),
          proteinG: i.proteinG,
          carbsG: i.carbsG,
          fatG: i.fatG,
          fiberG: i.fiberG,
          ingredientOrder: _ingredients.indexOf(i),
        )).toList(),
      );

      await repository.createRecipe(
        userId: widget.userId,
        request: recipeCreate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${_nameController.text}" created!'),
            backgroundColor:
                widget.isDark ? AppColors.success : AppColorsLight.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Failed to save recipe: $e';
      });
    }
  }

  void _openCookingConverter(BuildContext context) async {
    final result = await showGlassSheet<CookingConversionResult>(
      context: context,
      builder: (context) => GlassSheet(
        child: CookingConverterSheet(
          isDark: widget.isDark,
        ),
      ),
    );

    if (result != null && mounted) {
      // Show the conversion result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.inputGrams.toStringAsFixed(0)}g ${result.direction == ConversionDirection.rawToCooked ? "raw" : "cooked"} '
            '${result.foodName} = ${result.outputGrams.toStringAsFixed(0)}g '
            '${result.direction == ConversionDirection.rawToCooked ? "cooked" : "raw"}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _openBatchPortioning(BuildContext context) async {
    final result = await showGlassSheet<BatchPortioningResult>(
      context: context,
      builder: (context) => GlassSheet(
        child: BatchPortioningSheet(
          isDark: widget.isDark,
          recipeName: _nameController.text.isNotEmpty ? _nameController.text : null,
          totalCalories: _totalCalories,
          totalProtein: _totalProtein,
          totalCarbs: _totalCarbs,
          totalFat: _totalFat,
          defaultServings: _servings,
        ),
      ),
    );

    if (result != null && mounted) {
      // Show the portioning result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${result.portionEaten} serving(s) of "${result.recipeName}": '
            '${result.caloriesConsumed} kcal',
          ),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Hairline-led input decoration for the Signature dark sheet.
  InputDecoration _hairlineDecoration({
    required String labelText,
    String? hintText,
    String? suffixText,
    required Color textMuted,
    required Color surface,
    required Color cardBorder,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: labelText,
      labelStyle: ZType.lbl(12, color: textMuted, letterSpacing: 1.3),
      hintText: hintText,
      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
      suffixText: suffixText,
      suffixStyle: ZType.lbl(12, color: textMuted, letterSpacing: 1.3),
      filled: true,
      fillColor: surface,
      border: border(cardBorder),
      enabledBorder: border(cardBorder),
      focusedBorder: border(ThemeColors.of(context).accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final textSecondary = tc.textSecondary;
    final accent = tc.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                Text(
                  widget.existingRecipe != null
                      ? AppLocalizations.of(context).recipeBuilderEditRecipe
                      : 'Create Recipe',
                  style: ZType.disp(26, color: textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: textMuted)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: ZealovaButton(
                    label: AppLocalizations.of(context).buttonSave,
                    onTap: _isSaving ? null : _saveRecipe,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tc.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tc.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: tc.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: tc.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Name
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textPrimary, fontSize: 18),
                    decoration: _hairlineDecoration(
                      labelText: 'Recipe Name *',
                      hintText: 'e.g., Oatmeal with Berries',
                      textMuted: textMuted,
                      surface: surface,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category and Servings Row
                  Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<RecipeCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: surface,
                              style: TextStyle(color: textPrimary),
                              items: RecipeCategory.values.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Text(cat.emoji),
                                      const SizedBox(width: 8),
                                      Text(cat.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Servings
                      Expanded(
                        child: TextField(
                          controller: _servingsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).recipeBuilderServings,
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prep and Cook Time
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prepTimeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).recipeBuilderPrepTime,
                            suffixText: 'min',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cookTimeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).recipeBuilderCookTime,
                            suffixText: 'min',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingredients Section
                  Row(
                    children: [
                      ZealovaSectionKicker(
                        AppLocalizations.of(context).recipeBuilderIngredients,
                      ),
                      const Spacer(),
                      Text(
                        '${_ingredients.length} items',
                        style: ZType.lbl(11, color: textSecondary, letterSpacing: 1.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ingredients List
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        if (_ingredients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 40,
                                  color: textMuted.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context).recipeBuilderNoIngredientsYet,
                                  style: ZType.lbl(13, color: textMuted, letterSpacing: 1.3),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._ingredients.asMap().entries.map((entry) {
                            final index = entry.key;
                            final ingredient = entry.value;
                            return _IngredientRow(
                              ingredient: ingredient,
                              onRemove: () => _removeIngredient(index),
                              isDark: isDark,
                              isLast: index == _ingredients.length - 1,
                            );
                          }),

                        // Add Ingredient Button Row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: _ingredients.isNotEmpty
                                ? Border(top: BorderSide(color: cardBorder))
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Add Ingredient Button — primary CTA (the one accent)
                              Expanded(
                                child: ZealovaButton(
                                  label: AppLocalizations.of(context).recipeBuilderSheetAddIngredient,
                                  onTap: _addIngredient,
                                  height: 46,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Cooking Converter Button — ghost / hairline secondary
                              ZealovaButton(
                                label: AppLocalizations.of(context).recipeBuilderConverter,
                                onTap: () => _openCookingConverter(context),
                                variant: ZealovaButtonVariant.ghost,
                                expand: false,
                                height: 46,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Summary
                  if (_ingredients.isNotEmpty) ...[
                    ZealovaSectionKicker(
                      AppLocalizations.of(context).recipeBuilderNutritionPerServing,
                    ),
                    const SizedBox(height: 12),
                    _NutritionSummaryCard(
                      calories: _caloriesPerServing,
                      protein: _proteinPerServing,
                      carbs: _carbsPerServing,
                      fat: _fatPerServing,
                      fiber: _fiberPerServing,
                      servings: _servings,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    // Batch Portioning Button — ghost secondary
                    ZealovaButton(
                      label: AppLocalizations.of(context).recipeBuilderCalculatePortionToLog,
                      onTap: () => _openBatchPortioning(context),
                      variant: ZealovaButtonVariant.ghost,
                      trailingIcon: Icons.pie_chart,
                      height: 46,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description (Optional)
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(color: textPrimary),
                    decoration: _hairlineDecoration(
                      labelText: AppLocalizations.of(context).recipeBuilderDescriptionOptional,
                      hintText: 'A brief description of the recipe',
                      textMuted: textMuted,
                      surface: surface,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions (Optional)
                  TextField(
                    controller: _instructionsController,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: _hairlineDecoration(
                      labelText: AppLocalizations.of(context).recipeBuilderInstructionsOptional,
                      hintText: '1. First step...\n2. Second step...',
                      textMuted: textMuted,
                      surface: surface,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recipe Sharing Toggle
                  ZealovaCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).recipeBuilderShareRecipe,
                                style: ZType.lbl(15, color: textPrimary, letterSpacing: 1.3),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPublic
                                    ? 'Others can discover this recipe'
                                    : 'Only you can see this recipe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) => setState(() => _isPublic = value),
                          activeThumbColor: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
