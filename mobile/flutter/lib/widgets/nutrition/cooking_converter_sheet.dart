import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';

/// Shows the cooking weight converter sheet
Future<CookingConversionResult?> showCookingConverterSheet(
  BuildContext context, {
  required bool isDark,
}) {
  return showModalBottomSheet<CookingConversionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CookingConverterSheet(isDark: isDark),
  );
}

/// Direction of conversion
enum ConversionDirection {
  rawToCooked,
  cookedToRaw,
}

/// Result from the cooking converter
class CookingConversionResult {
  final String foodName;
  final double rawWeight;
  final double cookedWeight;
  final String unit;
  final ConversionDirection direction;
  final double inputGrams;
  final double outputGrams;

  const CookingConversionResult({
    required this.foodName,
    required this.rawWeight,
    required this.cookedWeight,
    required this.unit,
    required this.direction,
    required this.inputGrams,
    required this.outputGrams,
  });
}

/// Cooking weight conversion data
class CookingConversionData {
  final String name;
  final String category;
  final double rawToCookedMultiplier; // Raw weight * multiplier = Cooked weight
  final String notes;

  const CookingConversionData({
    required this.name,
    required this.category,
    required this.rawToCookedMultiplier,
    this.notes = '',
  });

  /// Convert raw to cooked
  double rawToCooked(double rawGrams) => rawGrams * rawToCookedMultiplier;

  /// Convert cooked to raw
  double cookedToRaw(double cookedGrams) => cookedGrams / rawToCookedMultiplier;
}

/// Common foods with their cooking conversion multipliers
const List<CookingConversionData> commonFoodConversions = [
  // Proteins (shrink when cooked - lose water)
  CookingConversionData(
    name: 'Chicken Breast',
    category: 'Protein',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked',
  ),
  CookingConversionData(
    name: 'Chicken Thigh',
    category: 'Protein',
    rawToCookedMultiplier: 0.70,
    notes: 'Loses ~30% weight when cooked (more fat)',
  ),
  CookingConversionData(
    name: 'Ground Beef (80/20)',
    category: 'Protein',
    rawToCookedMultiplier: 0.70,
    notes: 'Loses ~30% weight when cooked',
  ),
  CookingConversionData(
    name: 'Ground Beef (90/10)',
    category: 'Protein',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked (less fat)',
  ),
  CookingConversionData(
    name: 'Ground Turkey',
    category: 'Protein',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked',
  ),
  CookingConversionData(
    name: 'Steak (Beef)',
    category: 'Protein',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked',
  ),
  CookingConversionData(
    name: 'Pork Chop',
    category: 'Protein',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked',
  ),
  CookingConversionData(
    name: 'Salmon',
    category: 'Protein',
    rawToCookedMultiplier: 0.80,
    notes: 'Loses ~20% weight when cooked',
  ),
  CookingConversionData(
    name: 'Shrimp',
    category: 'Protein',
    rawToCookedMultiplier: 0.85,
    notes: 'Loses ~15% weight when cooked',
  ),
  CookingConversionData(
    name: 'Eggs (scrambled)',
    category: 'Protein',
    rawToCookedMultiplier: 0.90,
    notes: 'Loses ~10% weight when cooked',
  ),

  // Grains (expand when cooked - absorb water)
  CookingConversionData(
    name: 'White Rice',
    category: 'Grains',
    rawToCookedMultiplier: 3.0,
    notes: 'Triples in weight when cooked',
  ),
  CookingConversionData(
    name: 'Brown Rice',
    category: 'Grains',
    rawToCookedMultiplier: 2.75,
    notes: 'Nearly triples when cooked',
  ),
  CookingConversionData(
    name: 'Pasta (dried)',
    category: 'Grains',
    rawToCookedMultiplier: 2.25,
    notes: 'More than doubles when cooked',
  ),
  CookingConversionData(
    name: 'Quinoa',
    category: 'Grains',
    rawToCookedMultiplier: 2.75,
    notes: 'Nearly triples when cooked',
  ),
  CookingConversionData(
    name: 'Oatmeal',
    category: 'Grains',
    rawToCookedMultiplier: 2.5,
    notes: '2.5x weight when cooked',
  ),
  CookingConversionData(
    name: 'Couscous',
    category: 'Grains',
    rawToCookedMultiplier: 2.5,
    notes: '2.5x weight when cooked',
  ),
  CookingConversionData(
    name: 'Barley',
    category: 'Grains',
    rawToCookedMultiplier: 3.5,
    notes: '3.5x weight when cooked',
  ),

  // Legumes (expand when cooked)
  CookingConversionData(
    name: 'Lentils (dried)',
    category: 'Legumes',
    rawToCookedMultiplier: 2.5,
    notes: '2.5x weight when cooked',
  ),
  CookingConversionData(
    name: 'Chickpeas (dried)',
    category: 'Legumes',
    rawToCookedMultiplier: 2.5,
    notes: '2.5x weight when cooked',
  ),
  CookingConversionData(
    name: 'Black Beans (dried)',
    category: 'Legumes',
    rawToCookedMultiplier: 2.5,
    notes: '2.5x weight when cooked',
  ),

  // Vegetables (shrink when cooked)
  CookingConversionData(
    name: 'Spinach',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.10,
    notes: 'Loses ~90% volume when cooked!',
  ),
  CookingConversionData(
    name: 'Kale',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.30,
    notes: 'Loses ~70% volume when cooked',
  ),
  CookingConversionData(
    name: 'Mushrooms',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.50,
    notes: 'Loses ~50% weight when cooked',
  ),
  CookingConversionData(
    name: 'Broccoli',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.85,
    notes: 'Loses ~15% weight when cooked',
  ),
  CookingConversionData(
    name: 'Onions',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.60,
    notes: 'Loses ~40% weight when caramelized',
  ),
  CookingConversionData(
    name: 'Zucchini',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.75,
    notes: 'Loses ~25% weight when cooked',
  ),
  CookingConversionData(
    name: 'Bell Peppers',
    category: 'Vegetables',
    rawToCookedMultiplier: 0.85,
    notes: 'Loses ~15% weight when cooked',
  ),
];

/// Cooking Weight Converter Sheet
class CookingConverterSheet extends StatefulWidget {
  final bool isDark;

  const CookingConverterSheet({super.key, required this.isDark});

  @override
  State<CookingConverterSheet> createState() => _CookingConverterSheetState();
}

class _CookingConverterSheetState extends State<CookingConverterSheet> {
  final _amountController = TextEditingController();
  CookingConversionData? _selectedFood;
  bool _isRawToCooked = true; // Direction of conversion
  String _searchQuery = '';

  List<CookingConversionData> get _filteredFoods {
    if (_searchQuery.isEmpty) return commonFoodConversions;
    final query = _searchQuery.toLowerCase();
    return commonFoodConversions
        .where((f) =>
            f.name.toLowerCase().contains(query) ||
            f.category.toLowerCase().contains(query))
        .toList();
  }

  double? get _convertedAmount {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedFood == null) return null;

    if (_isRawToCooked) {
      return _selectedFood!.rawToCooked(amount);
    } else {
      return _selectedFood!.cookedToRaw(amount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.swap_vert, color: teal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooking Converter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Convert between raw and cooked weights',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DirectionButton(
                            label: 'Raw → Cooked',
                            isSelected: _isRawToCooked,
                            onTap: () {
                              HapticService.light();
                              setState(() => _isRawToCooked = true);
                            },
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _DirectionButton(
                            label: 'Cooked → Raw',
                            isSelected: !_isRawToCooked,
                            onTap: () {
                              HapticService.light();
                              setState(() => _isRawToCooked = false);
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Food selector
                  Text(
                    'Select Food',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search field
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      hintStyle: TextStyle(color: textMuted),
                      prefixIcon: Icon(Icons.search, color: textMuted),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Food list (grouped by category)
                  _buildFoodList(elevated, textPrimary, textMuted, teal, cardBorder),

                  const SizedBox(height: 20),

                  // Amount input
                  if (_selectedFood != null) ...[
                    Text(
                      'Enter ${_isRawToCooked ? 'Raw' : 'Cooked'} Weight',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: textPrimary, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: textMuted),
                        suffixText: 'g',
                        suffixStyle: TextStyle(color: textMuted, fontSize: 16),
                        filled: true,
                        fillColor: elevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Result card
                    if (_convertedAmount != null)
                      _buildResultCard(
                        elevated,
                        textPrimary,
                        textMuted,
                        teal,
                        cardBorder,
                      ),

                    const SizedBox(height: 20),

                    // Use this value button
                    if (_convertedAmount != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final amount = double.tryParse(_amountController.text);
                            if (amount != null && _selectedFood != null) {
                              Navigator.pop(
                                context,
                                CookingConversionResult(
                                  foodName: _selectedFood!.name,
                                  rawWeight: _isRawToCooked ? amount : _convertedAmount!,
                                  cookedWeight: _isRawToCooked ? _convertedAmount! : amount,
                                  unit: 'g',
                                  direction: _isRawToCooked
                                      ? ConversionDirection.rawToCooked
                                      : ConversionDirection.cookedToRaw,
                                  inputGrams: amount,
                                  outputGrams: _convertedAmount!,
                                ),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Use This Value',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color teal,
    Color cardBorder,
  ) {
    // Group foods by category
    final groupedFoods = <String, List<CookingConversionData>>{};
    for (final food in _filteredFoods) {
      groupedFoods.putIfAbsent(food.category, () => []).add(food);
    }

    if (groupedFoods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No foods found',
            style: TextStyle(color: textMuted),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: groupedFoods.entries.length,
        itemBuilder: (context, categoryIndex) {
          final entry = groupedFoods.entries.elementAt(categoryIndex);
          final category = entry.key;
          final foods = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Food items
              ...foods.map((food) => _FoodTile(
                    food: food,
                    isSelected: _selectedFood?.name == food.name,
                    onTap: () {
                      HapticService.light();
                      setState(() => _selectedFood = food);
                    },
                    isDark: widget.isDark,
                  )),
              if (categoryIndex < groupedFoods.entries.length - 1)
                Divider(height: 1, color: cardBorder),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultCard(
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color teal,
    Color cardBorder,
  ) {
    final inputAmount = double.tryParse(_amountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Conversion visualization
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      _isRawToCooked ? Icons.egg_outlined : Icons.restaurant,
                      color: teal,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRawToCooked ? 'Raw' : 'Cooked',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                    Text(
                      '${inputAmount.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: teal,
                size: 24,
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      _isRawToCooked ? Icons.restaurant : Icons.egg_outlined,
                      color: teal,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRawToCooked ? 'Cooked' : 'Raw',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                    Text(
                      '${_convertedAmount!.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFood!.notes,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _DirectionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? teal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final CookingConversionData food;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FoodTile({
    required this.food,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Determine if food expands or shrinks
    final expands = food.rawToCookedMultiplier > 1;
    final multiplierText = expands
        ? '${food.rawToCookedMultiplier.toStringAsFixed(1)}x'
        : '${(food.rawToCookedMultiplier * 100).toStringAsFixed(0)}%';

    return Material(
      color: isSelected ? teal.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? teal : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? teal : textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // Food name
              Expanded(
                child: Text(
                  food.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
              // Multiplier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: expands
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      expands ? Icons.expand : Icons.compress,
                      size: 12,
                      color: expands ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      multiplierText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: expands ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
