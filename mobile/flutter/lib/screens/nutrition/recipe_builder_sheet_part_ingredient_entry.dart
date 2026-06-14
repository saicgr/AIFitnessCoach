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
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final errorColor = tc.error;

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
              color: textMuted,
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
                style: ZType.data(14, color: textPrimary),
              ),
              Text(
                'KCAL',
                style: ZType.lbl(9, color: textMuted, letterSpacing: 1.5),
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
        // Analysis-only hack (the log is deleted below) — never persist a
        // stray hydration entry for a water-based ingredient (Gap 1).
        skipHydration: true,
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
    final accent = tc.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

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
                  AppLocalizations.of(context).recipeBuilderSheetAddIngredient,
                  style: ZType.disp(22, color: textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: textMuted)),
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
                    decoration: _hairlineDecoration(
                      labelText: AppLocalizations.of(context).recipeBuilderSheetIngredientName,
                      hintText: 'e.g., Chicken breast, Oats, Banana',
                      textMuted: textMuted,
                      surface: surface,
                      cardBorder: cardBorder,
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
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).recipeBuilderSheetAmount,
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              dropdownColor: surface,
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

                  // Analyze Button — ghost secondary (accent reserved for Add CTA)
                  _isAnalyzing
                      ? SizedBox(
                          height: 46,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context).recipeBuilderSheetAnalyzing,
                                  style: ZType.lbl(14, color: textMuted, letterSpacing: 2.5),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ZealovaButton(
                          label: 'Estimate Nutrition with AI',
                          onTap: _analyzeIngredient,
                          variant: ZealovaButtonVariant.ghost,
                          trailingIcon: Icons.auto_awesome,
                          height: 46,
                        ),
                  const SizedBox(height: 24),

                  // Nutrition Fields
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).recipeBuilderSheetNutritionPerAmountAbove,
                  ),
                  const SizedBox(height: 12),

                  // Calories
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary),
                    decoration: _hairlineDecoration(
                      labelText: AppLocalizations.of(context).workoutSummaryGeneralCalories,
                      suffixText: 'kcal',
                      textMuted: textMuted,
                      surface: surface,
                      cardBorder: cardBorder,
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
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                            suffixText: 'g',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                            suffixText: 'g',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
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
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).weeklyCheckinSheetFat,
                            suffixText: 'g',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _fiberController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textPrimary),
                          decoration: _hairlineDecoration(
                            labelText: AppLocalizations.of(context).recipeBuilderSheetFiber,
                            suffixText: 'g',
                            textMuted: textMuted,
                            surface: surface,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add Button — the one primary CTA for this sheet
                  ZealovaButton(
                    label: AppLocalizations.of(context).recipeBuilderSheetAddIngredient,
                    onTap: _addIngredient,
                    trailingIcon: Icons.add,
                    height: 52,
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
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final accent = tc.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Semantic macro colors
    final proteinColor = AppColors.macroProtein;
    final carbsColor = AppColors.macroCarbs;
    final fatColor = AppColors.macroFat;
    final fiberColor = tc.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Calories Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tc.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(Icons.local_fire_department, size: 20, color: textPrimary),
              ),
              const SizedBox(width: 12),
              Text(
                '$calories',
                style: ZType.disp(30, color: textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                'KCAL',
                style: ZType.lbl(12, color: textMuted, letterSpacing: 1.5),
              ),
              const Spacer(),
              if (servings > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tc.elevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Text(
                    '${calories * servings} total',
                    style: ZType.lbl(11, color: accent, letterSpacing: 1.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Macros Row
          Row(
            children: [
              _MacroChip(
                label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                value: protein,
                color: proteinColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                value: carbs,
                color: carbsColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: AppLocalizations.of(context).weeklyCheckinSheetFat,
                value: fat,
                color: fatColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: AppLocalizations.of(context).recipeBuilderSheetFiber,
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
    final tc = ThemeColors.of(context);
    final textMuted = tc.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: ZType.lbl(9, color: textMuted, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: ZType.data(14, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

