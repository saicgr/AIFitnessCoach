import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/nutrition/cooking_converter_sheet.dart';
import '../../widgets/nutrition/batch_portioning_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
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
                      ? 'Edit Recipe'
                      : 'Create Recipe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textMuted)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    disabledBackgroundColor: teal.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
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
                color: (isDark ? AppColors.error : AppColorsLight.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.error : AppColorsLight.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? AppColors.error : AppColorsLight.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: isDark ? AppColors.error : AppColorsLight.error,
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
                    decoration: InputDecoration(
                      labelText: 'Recipe Name *',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Oatmeal with Berries',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                            color: elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<RecipeCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: elevated,
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
                          decoration: InputDecoration(
                            labelText: 'Servings',
                            labelStyle: TextStyle(color: textMuted),
                            filled: true,
                            fillColor: elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Prep Time',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'min',
                            suffixStyle: TextStyle(color: textMuted),
                            filled: true,
                            fillColor: elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cookTimeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Cook Time',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'min',
                            suffixStyle: TextStyle(color: textMuted),
                            filled: true,
                            fillColor: elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingredients Section
                  Row(
                    children: [
                      Text(
                        'INGREDIENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_ingredients.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ingredients List
                  Container(
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
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
                                  'No ingredients yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textMuted,
                                  ),
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
                              // Add Ingredient Button
                              Expanded(
                                child: InkWell(
                                  onTap: _addIngredient,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: teal, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add Ingredient',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Cooking Converter Button
                              InkWell(
                                onTap: () => _openCookingConverter(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.scale, color: Colors.orange, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Converter',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                    Text(
                      'NUTRITION PER SERVING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
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
                    // Batch Portioning Button
                    InkWell(
                      onTap: () => _openBatchPortioning(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pie_chart, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Calculate Portion to Log',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description (Optional)
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'A brief description of the recipe',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions (Optional)
                  TextField(
                    controller: _instructionsController,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Instructions (Optional)',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: '1. First step...\n2. Second step...',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recipe Sharing Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Recipe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
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
                          activeThumbColor: teal,
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
