import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// Shows a polished confirmation bottom sheet after a food report is
/// submitted. Surfaces the report_id (so the user has a receipt) and the
/// 48h review SLA. Per feedback_design_preferences.md — rich visuals,
/// not a minimal snackbar. ✅
void _showReportConfirmation(BuildContext context, String? reportId) {
  if (!context.mounted) return;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
  final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Success icon with green halo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Report submitted',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (reportId != null && reportId.isNotEmpty && reportId != 'unknown') ...[
              const SizedBox(height: 6),
              Text(
                '#$reportId',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              "We'll review and update within 48h.\nThanks for helping improve our data!",
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
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
      final userId = Supabase.instance.client.auth.currentSession?.user.id ?? '';
      if (userId.isEmpty) {
        throw Exception('Not authenticated. Please log in and try again.');
      }
      final data = <String, dynamic>{
        'user_id': userId,
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

      final response = await widget.apiClient.post('/nutrition/food-report', data: data);

      // Pull report_id from the API response so we can display it in the
      // confirmation sheet — gives the user a tangible receipt that the
      // report was saved. ✅
      String? reportId;
      try {
        final raw = response.data;
        if (raw is Map) {
          final id = raw['report_id'];
          if (id != null) reportId = id.toString();
        }
      } catch (e) {
        debugPrint('⚠️ Could not parse report_id from response: $e');
      }

      if (!mounted) return;
      // Capture the root navigator BEFORE popping so we can show the
      // confirmation sheet on top of the underlying screen, not the
      // dialog that's about to close.
      final navigator = Navigator.of(context, rootNavigator: true);
      final rootContext = navigator.context;
      Navigator.of(context).pop(true); // Return true to indicate success
      // Replace the previous snackbar with a richer confirmation sheet
      // showing the report ID + SLA so the user trusts the submission. ✅
      _showReportConfirmation(rootContext, reportId);
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Colorful accents for the report sheet
    const wrongNutritionColor = AppColors.orange;
    const wrongFoodColor = AppColors.coral;
    final activeChipColor = _reportType == 'wrong_nutrition'
        ? wrongNutritionColor
        : wrongFoodColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeChipColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: activeChipColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Issue',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.foodName,
                        style: TextStyle(color: textMuted, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Report type toggle
            Row(
              children: [
                _ReportTypeChip(
                  label: 'Wrong nutrition',
                  isSelected: _reportType == 'wrong_nutrition',
                  onTap: () => setState(() => _reportType = 'wrong_nutrition'),
                  activeColor: wrongNutritionColor,
                  textMuted: textMuted,
                  surfaceColor: surfaceColor,
                ),
                const SizedBox(width: 8),
                _ReportTypeChip(
                  label: 'Wrong food',
                  isSelected: _reportType == 'wrong_food',
                  onTap: () => setState(() => _reportType = 'wrong_food'),
                  activeColor: wrongFoodColor,
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
                      accentColor: activeChipColor,
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
                      accentColor: AppColors.macroProtein,
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
                      accentColor: AppColors.macroCarbs,
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
                      accentColor: AppColors.macroFat,
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
                  borderSide: BorderSide(color: cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activeChipColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button - colorful with gradient
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isSubmitting
                      ? null
                      : LinearGradient(
                          colors: [
                            activeChipColor,
                            activeChipColor.withOpacity(0.8),
                          ],
                        ),
                  color: _isSubmitting ? activeChipColor.withOpacity(0.4) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
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
  final Color accentColor;
  final bool isInteger;

  const _NutrientField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.isDark,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textMuted,
    required this.accentColor,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
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
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor),
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
  final Color activeColor;
  final Color textMuted;
  final Color surfaceColor;

  const _ReportTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
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
          color: isSelected ? activeColor.withOpacity(0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : textMuted.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
