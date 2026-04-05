part of 'recipe_builder_sheet.dart';


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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
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

    // Monochrome macro colors
    final caloriesColor = AppColors.textPrimary;
    final proteinColor = AppColors.textSecondary;
    final carbsColor = AppColors.textMuted;
    final fatColor = AppColors.textSecondary;
    final fiberColor = AppColors.textMuted;

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

