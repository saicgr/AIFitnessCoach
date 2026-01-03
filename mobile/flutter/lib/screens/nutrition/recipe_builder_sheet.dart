import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../widgets/nutrition/cooking_converter_sheet.dart';
import '../../widgets/nutrition/batch_portioning_sheet.dart';

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
    final result = await showModalBottomSheet<_IngredientEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddIngredientSheet(
        userId: widget.userId,
        isDark: widget.isDark,
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
    final result = await showModalBottomSheet<CookingConversionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CookingConverterSheet(
        isDark: widget.isDark,
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
    final result = await showModalBottomSheet<BatchPortioningResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BatchPortioningSheet(
        isDark: widget.isDark,
        recipeName: _nameController.text.isNotEmpty ? _nameController.text : null,
        totalCalories: _totalCalories,
        totalProtein: _totalProtein,
        totalCarbs: _totalCarbs,
        totalFat: _totalFat,
        defaultServings: _servings,
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
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

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

// ─────────────────────────────────────────────────────────────────
// Ingredient Entry Model
// ─────────────────────────────────────────────────────────────────

class _IngredientEntry {
  final String name;
  final double amount;
  final String unit;
  final int? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;

  const _IngredientEntry({
    required this.name,
    required this.amount,
    required this.unit,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
  });
}

// ─────────────────────────────────────────────────────────────────
// Ingredient Row Widget
// ─────────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final _IngredientEntry ingredient;
  final VoidCallback onRemove;
  final bool isDark;
  final bool isLast;

  const _IngredientRow({
    required this.ingredient,
    required this.onRemove,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          // Bullet
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name and amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${ingredient.amount} ${ingredient.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ingredient.calories ?? 0}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: teal,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close, size: 16, color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Ingredient Sheet
// ─────────────────────────────────────────────────────────────────

class _AddIngredientSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const _AddIngredientSheet({
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends ConsumerState<_AddIngredientSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  String _selectedUnit = 'g';
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  final List<String> _units = ['g', 'ml', 'oz', 'cup', 'tbsp', 'tsp', 'piece', 'serving'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _analyzeIngredient() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final amount = double.tryParse(_amountController.text) ?? 100;
      final description = '$amount $_selectedUnit ${_nameController.text}';

      // For now, we just analyze but note that this creates a log entry
      // In a future version, we could add a dryRun parameter to the API
      final response = await repository.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: 'snack',
      );

      // Delete the log entry we just created since we only wanted the analysis
      try {
        if (response.foodLogId != null) {
          await repository.deleteFoodLog(response.foodLogId!);
        }
      } catch (_) {
        // Ignore delete errors
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasAnalyzed = true;
          _caloriesController.text = response.totalCalories.toString();
          _proteinController.text = response.proteinG.toStringAsFixed(1);
          _carbsController.text = response.carbsG.toStringAsFixed(1);
          _fatController.text = response.fatG.toStringAsFixed(1);
          _fiberController.text = (response.fiberG ?? 0).toStringAsFixed(1);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze: $e')),
        );
      }
    }
  }

  void _addIngredient() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final ingredient = _IngredientEntry(
      name: name,
      amount: double.tryParse(_amountController.text) ?? 100,
      unit: _selectedUnit,
      calories: int.tryParse(_caloriesController.text),
      proteinG: double.tryParse(_proteinController.text),
      carbsG: double.tryParse(_carbsController.text),
      fatG: double.tryParse(_fatController.text),
      fiberG: double.tryParse(_fiberController.text),
    );

    Navigator.pop(context, ingredient);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                Text(
                  'Add Ingredient',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textMuted)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredient Name
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Ingredient Name',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Chicken breast, Oats, Banana',
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

                  // Amount and Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Amount',
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              dropdownColor: elevated,
                              style: TextStyle(color: textPrimary),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedUnit = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Analyze Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeIngredient,
                      icon: _isAnalyzing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: teal,
                              ),
                            )
                          : Icon(Icons.auto_awesome, color: teal),
                      label: Text(
                        _isAnalyzing
                            ? 'Analyzing...'
                            : 'Estimate Nutrition with AI',
                        style: TextStyle(color: teal),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Fields
                  Text(
                    'NUTRITION (per amount above)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calories
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      labelStyle: TextStyle(color: textMuted),
                      suffixText: 'kcal',
                      suffixStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Macros Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Protein',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'g',
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Carbs',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'g',
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
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fatController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Fat',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'g',
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _fiberController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Fiber',
                            labelStyle: TextStyle(color: textMuted),
                            suffixText: 'g',
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

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add Ingredient',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrition Summary Card
// ─────────────────────────────────────────────────────────────────

class _NutritionSummaryCard extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int servings;
  final bool isDark;

  const _NutritionSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // Rainbow colors
    const caloriesColor = Color(0xFFFF6B6B);
    const proteinColor = Color(0xFFFFD93D);
    const carbsColor = Color(0xFF6BCB77);
    const fatColor = Color(0xFF4D96FF);
    const fiberColor = Color(0xFF9B59B6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Calories Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: caloriesColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_fire_department, size: 20, color: caloriesColor),
              ),
              const SizedBox(width: 12),
              Text(
                '$calories',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kcal',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              if (servings > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${calories * servings} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Macros Row
          Row(
            children: [
              _MacroChip(
                label: 'Protein',
                value: protein,
                color: proteinColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Carbs',
                value: carbs,
                color: carbsColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Fat',
                value: fat,
                color: fatColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'Fiber',
                value: fiber,
                color: fiberColor,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
