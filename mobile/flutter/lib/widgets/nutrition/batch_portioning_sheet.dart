import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';

/// Result from the batch portioning calculator
class BatchPortioningResult {
  final String recipeName;
  final int totalServings;
  final double portionEaten;
  final int caloriesPerServing;
  final int caloriesConsumed;
  final double proteinPerServing;
  final double proteinConsumed;
  final double carbsPerServing;
  final double carbsConsumed;
  final double fatPerServing;
  final double fatConsumed;

  BatchPortioningResult({
    required this.recipeName,
    required this.totalServings,
    required this.portionEaten,
    required this.caloriesPerServing,
    required this.caloriesConsumed,
    required this.proteinPerServing,
    required this.proteinConsumed,
    required this.carbsPerServing,
    required this.carbsConsumed,
    required this.fatPerServing,
    required this.fatConsumed,
  });
}

/// Batch Cooking/Portioning Calculator Sheet
/// Helps users calculate nutrition for partial servings of batch-cooked meals
class BatchPortioningSheet extends StatefulWidget {
  final bool isDark;
  final String? recipeName;
  final int? totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final int? defaultServings;

  const BatchPortioningSheet({
    super.key,
    required this.isDark,
    this.recipeName,
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.defaultServings,
  });

  @override
  State<BatchPortioningSheet> createState() => _BatchPortioningSheetState();
}

class _BatchPortioningSheetState extends State<BatchPortioningSheet> {
  final _nameController = TextEditingController();
  final _totalCaloriesController = TextEditingController();
  final _totalProteinController = TextEditingController();
  final _totalCarbsController = TextEditingController();
  final _totalFatController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');

  double _portionEaten = 1.0;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from provided values
    if (widget.recipeName != null) {
      _nameController.text = widget.recipeName!;
    }
    if (widget.totalCalories != null) {
      _totalCaloriesController.text = widget.totalCalories.toString();
    }
    if (widget.totalProtein != null) {
      _totalProteinController.text = widget.totalProtein!.toStringAsFixed(1);
    }
    if (widget.totalCarbs != null) {
      _totalCarbsController.text = widget.totalCarbs!.toStringAsFixed(1);
    }
    if (widget.totalFat != null) {
      _totalFatController.text = widget.totalFat!.toStringAsFixed(1);
    }
    if (widget.defaultServings != null) {
      _servingsController.text = widget.defaultServings.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalCaloriesController.dispose();
    _totalProteinController.dispose();
    _totalCarbsController.dispose();
    _totalFatController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  int get _totalServings => int.tryParse(_servingsController.text) ?? 1;
  int get _totalCalories => int.tryParse(_totalCaloriesController.text) ?? 0;
  double get _totalProtein =>
      double.tryParse(_totalProteinController.text) ?? 0;
  double get _totalCarbs => double.tryParse(_totalCarbsController.text) ?? 0;
  double get _totalFat => double.tryParse(_totalFatController.text) ?? 0;

  int get _caloriesPerServing =>
      _totalServings > 0 ? (_totalCalories / _totalServings).round() : 0;
  double get _proteinPerServing =>
      _totalServings > 0 ? _totalProtein / _totalServings : 0;
  double get _carbsPerServing =>
      _totalServings > 0 ? _totalCarbs / _totalServings : 0;
  double get _fatPerServing =>
      _totalServings > 0 ? _totalFat / _totalServings : 0;

  int get _caloriesConsumed => (_caloriesPerServing * _portionEaten).round();
  double get _proteinConsumed => _proteinPerServing * _portionEaten;
  double get _carbsConsumed => _carbsPerServing * _portionEaten;
  double get _fatConsumed => _fatPerServing * _portionEaten;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final green = isDark ? AppColors.green : AppColorsLight.success;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Portioning',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Calculate nutrition per portion',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Name
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Recipe/Meal Name',
                      labelStyle: TextStyle(color: textMuted),
                      hintText: 'e.g., Chicken Stir Fry',
                      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(Icons.restaurant, color: textMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total Nutrition Section
                  Text(
                    'TOTAL BATCH NUTRITION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nutrition inputs row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMacroInput(
                                controller: _totalCaloriesController,
                                label: 'Calories',
                                color: teal,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                isInteger: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMacroInput(
                                controller: _totalProteinController,
                                label: 'Protein (g)',
                                color: Colors.blue,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMacroInput(
                                controller: _totalCarbsController,
                                label: 'Carbs (g)',
                                color: Colors.orange,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMacroInput(
                                controller: _totalFatController,
                                label: 'Fat (g)',
                                color: Colors.purple,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Number of Servings
                  Text(
                    'HOW MANY SERVINGS?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'This makes',
                          style: TextStyle(fontSize: 16, color: textPrimary),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: teal,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: teal.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'servings',
                          style: TextStyle(fontSize: 16, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Per Serving Breakdown
                  if (_totalCalories > 0 && _totalServings > 0) ...[
                    Text(
                      'PER SERVING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: teal.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroDisplay(
                            value: _caloriesPerServing.toString(),
                            label: 'kcal',
                            color: teal,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _buildMacroDisplay(
                            value: _proteinPerServing.toStringAsFixed(1),
                            label: 'protein',
                            color: Colors.blue,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _buildMacroDisplay(
                            value: _carbsPerServing.toStringAsFixed(1),
                            label: 'carbs',
                            color: Colors.orange,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _buildMacroDisplay(
                            value: _fatPerServing.toStringAsFixed(1),
                            label: 'fat',
                            color: Colors.purple,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // How much did you eat?
                    Text(
                      'HOW MUCH DID YOU EAT?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick portion buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPortionButton(0.5, '½', textPrimary, textMuted,
                            cardColor, green),
                        _buildPortionButton(1.0, '1', textPrimary, textMuted,
                            cardColor, green),
                        _buildPortionButton(1.5, '1½', textPrimary, textMuted,
                            cardColor, green),
                        _buildPortionButton(2.0, '2', textPrimary, textMuted,
                            cardColor, green),
                        _buildPortionButton(2.5, '2½', textPrimary, textMuted,
                            cardColor, green),
                        _buildPortionButton(3.0, '3', textPrimary, textMuted,
                            cardColor, green),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Manual input toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _showManualInput = !_showManualInput);
                      },
                      child: Row(
                        children: [
                          Icon(
                            _showManualInput
                                ? Icons.keyboard_hide
                                : Icons.keyboard,
                            color: textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showManualInput
                                ? 'Hide custom input'
                                : 'Enter custom amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showManualInput) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: '1.0',
                                hintStyle: TextStyle(
                                    color: textMuted.withValues(alpha: 0.5)),
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null && parsed > 0) {
                                  setState(() => _portionEaten = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'servings',
                            style: TextStyle(fontSize: 16, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Final calculation result
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            green.withValues(alpha: 0.15),
                            green.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: green.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: green, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'You ate $_portionEaten serving${_portionEaten != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFinalMacro(
                                value: _caloriesConsumed.toString(),
                                label: 'kcal',
                                color: teal,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              _buildFinalMacro(
                                value: _proteinConsumed.toStringAsFixed(1),
                                label: 'P',
                                color: Colors.blue,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              _buildFinalMacro(
                                value: _carbsConsumed.toStringAsFixed(1),
                                label: 'C',
                                color: Colors.orange,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                              _buildFinalMacro(
                                value: _fatConsumed.toStringAsFixed(1),
                                label: 'F',
                                color: Colors.purple,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          if (_totalCalories > 0 && _totalServings > 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      HapticService.medium();
                      Navigator.pop(
                        context,
                        BatchPortioningResult(
                          recipeName: _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Batch Meal',
                          totalServings: _totalServings,
                          portionEaten: _portionEaten,
                          caloriesPerServing: _caloriesPerServing,
                          caloriesConsumed: _caloriesConsumed,
                          proteinPerServing: _proteinPerServing,
                          proteinConsumed: _proteinConsumed,
                          carbsPerServing: _carbsPerServing,
                          carbsConsumed: _carbsConsumed,
                          fatPerServing: _fatPerServing,
                          fatConsumed: _fatConsumed,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log This Portion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInput({
    required TextEditingController controller,
    required String label,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: InputDecoration(
            filled: true,
            fillColor: color.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildMacroDisplay({
    required String value,
    required String label,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPortionButton(
    double portion,
    String label,
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color selectedColor,
  ) {
    final isSelected = _portionEaten == portion;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _portionEaten = portion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : textMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFinalMacro({
    required String value,
    required String label,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
