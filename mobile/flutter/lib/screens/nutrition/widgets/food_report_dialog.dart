import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/food_search_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Shows the food report bottom sheet for correcting nutrition data.
///
/// Pass either [food] (a FoodSearchResult) or raw values ([foodName], etc.)
/// for sources like NL analysis results or food history logs.
Future<void> showFoodReportDialog(
  BuildContext context, {
  required ApiClient apiClient,
  // Option A: pass a FoodSearchResult (existing search result)
  FoodSearchResult? food,
  // Option B: pass raw values (for NL items, food history, etc.)
  String? foodName,
  int? originalCalories,
  double? originalProtein,
  double? originalCarbs,
  double? originalFat,
  // Extra context fields
  String? dataSource,
  String? foodLogId,
  // Traceability fields
  String? originalQuery,
  List<Map<String, dynamic>>? allFoodItems,
}) {
  assert(food != null || foodName != null, 'Either food or foodName must be provided');
  return showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      child: _FoodReportSheet(
        food: food,
        foodName: food?.name ?? foodName!,
        initialCalories: food?.calories ?? originalCalories ?? 0,
        initialProtein: food?.protein ?? originalProtein,
        initialCarbs: food?.carbs ?? originalCarbs,
        initialFat: food?.fat ?? originalFat,
        dataSource: dataSource,
        foodLogId: foodLogId,
        apiClient: apiClient,
        originalQuery: originalQuery,
        allFoodItems: allFoodItems,
      ),
    ),
  );
}

class _FoodReportSheet extends StatefulWidget {
  final FoodSearchResult? food;
  final String foodName;
  final int initialCalories;
  final double? initialProtein;
  final double? initialCarbs;
  final double? initialFat;
  final String? dataSource;
  final String? foodLogId;
  final ApiClient apiClient;
  final String? originalQuery;
  final List<Map<String, dynamic>>? allFoodItems;

  const _FoodReportSheet({
    this.food,
    required this.foodName,
    required this.initialCalories,
    this.initialProtein,
    this.initialCarbs,
    this.initialFat,
    this.dataSource,
    this.foodLogId,
    required this.apiClient,
    this.originalQuery,
    this.allFoodItems,
  });

  @override
  State<_FoodReportSheet> createState() => _FoodReportSheetState();
}

class _FoodReportSheetState extends State<_FoodReportSheet> {
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;
  String _reportType = 'wrong_nutrition'; // 'wrong_nutrition' | 'wrong_food'

  @override
  void initState() {
    super.initState();
    _caloriesController =
        TextEditingController(text: widget.initialCalories.toString());
    _proteinController = TextEditingController(
        text: widget.initialProtein?.toStringAsFixed(1) ?? '');
    _carbsController = TextEditingController(
        text: widget.initialCarbs?.toStringAsFixed(1) ?? '');
    _fatController = TextEditingController(
        text: widget.initialFat?.toStringAsFixed(1) ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'user_id': '', // Will be set from auth context
        'food_name': widget.foodName,
        'reported_issue': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'original_calories': widget.initialCalories.toDouble(),
        'original_protein': widget.initialProtein,
        'original_carbs': widget.initialCarbs,
        'original_fat': widget.initialFat,
        'report_type': _reportType,
      };

      // Only include corrected macros for nutrition reports
      if (_reportType == 'wrong_nutrition') {
        data['corrected_calories'] = double.tryParse(_caloriesController.text);
        data['corrected_protein'] = double.tryParse(_proteinController.text);
        data['corrected_carbs'] = double.tryParse(_carbsController.text);
        data['corrected_fat'] = double.tryParse(_fatController.text);
      }

      // Include food_database_id if from a FoodSearchResult
      if (widget.food != null) {
        data['food_database_id'] = int.tryParse(widget.food!.id);
      }

      // Include extra context fields
      if (widget.dataSource != null) {
        data['data_source'] = widget.dataSource;
      }
      if (widget.foodLogId != null) {
        data['food_log_id'] = widget.foodLogId;
      }

      // Traceability fields
      if (widget.originalQuery != null) {
        data['original_query'] = widget.originalQuery;
      }
      if (widget.allFoodItems != null) {
        data['all_food_items'] = widget.allFoodItems;
      }

      await widget.apiClient.post('/nutrition/food-report', data: data);

      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Report Issue',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.foodName,
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Report type toggle
            Row(
              children: [
                _ReportTypeChip(
                  label: 'Wrong nutrition',
                  isSelected: _reportType == 'wrong_nutrition',
                  onTap: () => setState(() => _reportType = 'wrong_nutrition'),
                  accent: accent,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  surfaceColor: surfaceColor,
                ),
                const SizedBox(width: 8),
                _ReportTypeChip(
                  label: 'Wrong food',
                  isSelected: _reportType == 'wrong_food',
                  onTap: () => setState(() => _reportType = 'wrong_food'),
                  accent: accent,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  surfaceColor: surfaceColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Corrected values (only for wrong nutrition)
            if (_reportType == 'wrong_nutrition') ...[
              Text(
                'Corrected Values',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Nutrient fields in a 2x2 grid
              Row(
                children: [
                  Expanded(
                    child: _NutrientField(
                      label: 'Calories',
                      controller: _caloriesController,
                      suffix: 'kcal',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      isInteger: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NutrientField(
                      label: 'Protein',
                      controller: _proteinController,
                      suffix: 'g',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
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
                    child: _NutrientField(
                      label: 'Carbs',
                      controller: _carbsController,
                      suffix: 'g',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NutrientField(
                      label: 'Fat',
                      controller: _fatController,
                      suffix: 'g',
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes field
            Text(
              _reportType == 'wrong_food'
                  ? 'What food did you actually mean?'
                  : 'Additional Notes (optional)',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: _reportType == 'wrong_food' ? 3 : 2,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: _reportType == 'wrong_food'
                    ? 'e.g. I searched for mexican coke, not a burrito bowl'
                    : 'e.g. Serving size seems off...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: accentContrast,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: accent.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentContrast,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final bool isDark;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textMuted;
  final bool isInteger;

  const _NutrientField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.isDark,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textMuted,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
            ),
          ],
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: TextStyle(color: textMuted, fontSize: 13),
            filled: true,
            fillColor: surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.accent : AppColorsLight.accent,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _ReportTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color surfaceColor;

  const _ReportTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : textMuted.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accent : textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
