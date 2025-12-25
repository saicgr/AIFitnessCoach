import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null) {
      setState(() => _userId = userId);
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      ref.read(nutritionProvider.notifier).loadTargets(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        title: Text('Nutrition', style: TextStyle(color: textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: () => _showTargetsSettings(context, isDark),
          ),
        ],
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(color: teal),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Calorie ring
                    _CalorieRing(
                      consumed: state.todaySummary?.totalCalories ?? 0,
                      target: state.targets?.dailyCalorieTarget ?? 2000,
                      isDark: isDark,
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 24),

                    // Macros
                    _MacrosSection(
                      summary: state.todaySummary,
                      targets: state.targets,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // Today's meals
                    if (state.todaySummary?.meals.isNotEmpty == true) ...[
                      _SectionHeader(title: 'TODAY\'S MEALS', isDark: isDark),
                      const SizedBox(height: 12),
                      ...state.todaySummary!.meals.asMap().entries.map((e) {
                        return _MealCard(
                          meal: e.value,
                          onDelete: () => _deleteMeal(e.value.id),
                          isDark: isDark,
                        ).animate().fadeIn(delay: (50 * e.key).ms);
                      }),
                    ] else
                      _EmptyMealsState(isDark: isDark)
                          .animate()
                          .fadeIn(delay: 150.ms),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogMealSheet(isDark),
        backgroundColor: teal,
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  void _showLogMealSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LogMealSheet(userId: _userId ?? '', isDark: isDark),
    );
  }

  Future<void> _deleteMeal(String mealId) async {
    if (_userId == null) return;
    await ref.read(nutritionProvider.notifier).deleteLog(_userId!, mealId);
  }

  void _showTargetsSettings(BuildContext context, bool isDark) {
    final state = ref.read(nutritionProvider);
    final caloriesController = TextEditingController(
      text: (state.targets?.dailyCalorieTarget ?? 2000).toString(),
    );
    final proteinController = TextEditingController(
      text: (state.targets?.dailyProteinTargetG ?? 150).toString(),
    );
    final carbsController = TextEditingController(
      text: (state.targets?.dailyCarbsTargetG ?? 250).toString(),
    );
    final fatController = TextEditingController(
      text: (state.targets?.dailyFatTargetG ?? 70).toString(),
    );

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: nearBlack,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Targets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Calories', 'kcal', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Protein', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Carbs', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration: _inputDecoration('Fat', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_userId != null) {
                      ref.read(nutritionProvider.notifier).updateTargets(
                            _userId!,
                            calorieTarget: int.tryParse(caloriesController.text),
                            proteinTarget:
                                double.tryParse(proteinController.text),
                            carbsTarget: double.tryParse(carbsController.text),
                            fatTarget: double.tryParse(fatController.text),
                          );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Update Targets'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, String suffix, Color fillColor, Color labelColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      suffixText: suffix,
      suffixStyle: TextStyle(color: labelColor),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Calorie Ring
// ─────────────────────────────────────────────────────────────────

class _CalorieRing extends StatelessWidget {
  final int consumed;
  final int target;
  final bool isDark;

  const _CalorieRing({
    required this.consumed,
    required this.target,
    required this.isDark,
  });

  double get percentage => (consumed / target).clamp(0.0, 1.0);
  int get remaining => (target - consumed).clamp(0, target);

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final warning = isDark ? AppColors.warning : AppColorsLight.warning;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            teal.withOpacity(0.2),
            success.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 12,
                    backgroundColor: glassSurface,
                    color: glassSurface,
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    color: consumed > target ? warning : teal,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$consumed',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'calories',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalorieStat(label: 'Target', value: target, isDark: isDark),
              Container(
                height: 24,
                width: 1,
                color: cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _CalorieStat(label: 'Remaining', value: remaining, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final int value;
  final bool isDark;

  const _CalorieStat(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
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
}

// ─────────────────────────────────────────────────────────────────
// Macros Section
// ─────────────────────────────────────────────────────────────────

class _MacrosSection extends StatelessWidget {
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final bool isDark;

  const _MacrosSection({this.summary, this.targets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            label: 'Protein',
            current: summary?.totalProteinG ?? 0,
            target: targets?.dailyProteinTargetG ?? 150,
            color: purple,
            unit: 'g',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroCard(
            label: 'Carbs',
            current: summary?.totalCarbsG ?? 0,
            target: targets?.dailyCarbsTargetG ?? 250,
            color: orange,
            unit: 'g',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroCard(
            label: 'Fat',
            current: summary?.totalFatG ?? 0,
            target: targets?.dailyFatTargetG ?? 70,
            color: coral,
            unit: 'g',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final bool isDark;

  const _MacroCard({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    required this.isDark,
  });

  double get percentage => (current / target).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 4,
                  backgroundColor: glassSurface,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${current.toInt()}/$target$unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Meal Card
// ─────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final FoodLog meal;
  final VoidCallback onDelete;
  final bool isDark;

  const _MealCard({
    required this.meal,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final type = MealType.fromValue(meal.mealType);
    final time =
        '${meal.loggedAt.hour.toString().padLeft(2, '0')}:${meal.loggedAt.minute.toString().padLeft(2, '0')}';

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${meal.totalCalories} kcal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: textMuted,
                onPressed: onDelete,
              ),
            ],
          ),
          if (meal.foodItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meal.foodItems.take(4).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroChip(
                label: 'P',
                value: meal.proteinG,
                color: purple,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'C',
                value: meal.carbsG,
                color: orange,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: 'F',
                value: meal.fatG,
                color: coral,
              ),
              if (meal.healthScore != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getHealthScoreColor(meal.healthScore!, isDark)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 12,
                        color: _getHealthScoreColor(meal.healthScore!, isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.healthScore}/10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              _getHealthScoreColor(meal.healthScore!, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (meal.aiFeedback != null && meal.aiFeedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyan.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: cyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.aiFeedback!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score, bool isDark) {
    if (score >= 8) return isDark ? AppColors.success : AppColorsLight.success;
    if (score >= 5) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.toInt()}g',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty Meals State
// ─────────────────────────────────────────────────────────────────

class _EmptyMealsState extends StatelessWidget {
  final bool isDark;

  const _EmptyMealsState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 64,
            color: textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your first meal',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Log Meal Sheet - 5 Tab Implementation
// ─────────────────────────────────────────────────────────────────

class _LogMealSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const _LogMealSheet({required this.userId, required this.isDark});

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealType _selectedMealType = MealType.lunch;
  bool _isLoading = false;
  String? _error;

  // Text input controller for Describe tab
  final _descriptionController = TextEditingController();

  // Barcode scanner controller
  MobileScannerController? _scannerController;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromImage(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFile: File(image.path),
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar(response.totalCalories);
        ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logFromText() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromText(
        userId: widget.userId,
        description: description,
        mealType: _selectedMealType.value,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar(response.totalCalories);
        ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (_hasScanned) return;
    _hasScanned = true;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // First lookup the product
      final product = await repository.lookupBarcode(barcode);

      if (mounted) {
        // Show product confirmation dialog
        final confirmed = await _showProductConfirmation(product);
        if (confirmed == true) {
          final response = await repository.logFoodFromBarcode(
            userId: widget.userId,
            barcode: barcode,
            mealType: _selectedMealType.value,
          );

          if (mounted) {
            Navigator.pop(context);
            _showSuccessSnackbar(response.totalCalories);
            ref
                .read(nutritionProvider.notifier)
                .loadTodaySummary(widget.userId);
          }
        } else {
          setState(() {
            _isLoading = false;
            _hasScanned = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasScanned = false;
        _error = e.toString();
      });
    }
  }

  Future<bool?> _showProductConfirmation(BarcodeProduct product) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Found Product',
          style: TextStyle(color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (product.brand != null) ...[
              const SizedBox(height: 4),
              Text(
                product.brand!,
                style: TextStyle(color: textMuted),
              ),
            ],
            const SizedBox(height: 16),
            _NutritionInfoRow(
              label: 'Calories',
              value: '${product.caloriesPer100g.toInt()} kcal/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Protein',
              value: '${product.proteinPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Carbs',
              value: '${product.carbsPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
            _NutritionInfoRow(
              label: 'Fat',
              value: '${product.fatPer100g.toStringAsFixed(1)}g/100g',
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: teal),
            child: const Text('Log This'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(int calories) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $calories kcal'),
        backgroundColor:
            widget.isDark ? AppColors.success : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Text(
                  'Log a Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Meal type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? teal.withOpacity(0.2) : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? teal : cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(type.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? teal : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt, size: 18), text: 'Photo'),
                Tab(icon: Icon(Icons.mic, size: 18), text: 'Voice'),
                Tab(icon: Icon(Icons.edit, size: 18), text: 'Describe'),
                Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scan'),
                Tab(icon: Icon(Icons.flash_on, size: 18), text: 'Quick'),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
            ),

          // Loading indicator
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: teal),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing your food...',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PhotoTab(
                    onPickImage: _pickImage,
                    isDark: isDark,
                  ),
                  _VoiceTab(
                    onSubmit: (text) {
                      _descriptionController.text = text;
                      _logFromText();
                    },
                    isDark: isDark,
                  ),
                  _DescribeTab(
                    controller: _descriptionController,
                    onSubmit: _logFromText,
                    isDark: isDark,
                  ),
                  _ScanTab(
                    onBarcodeDetected: _handleBarcodeScan,
                    isDark: isDark,
                  ),
                  _QuickTab(
                    userId: widget.userId,
                    mealType: _selectedMealType,
                    onLogged: () {
                      Navigator.pop(context);
                      ref
                          .read(nutritionProvider.notifier)
                          .loadTodaySummary(widget.userId);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Photo Tab
// ─────────────────────────────────────────────────────────────────

class _PhotoTab extends StatelessWidget {
  final void Function(ImageSource) onPickImage;
  final bool isDark;

  const _PhotoTab({required this.onPickImage, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onPickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: teal.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, size: 48, color: teal),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Take a Photo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI will identify and estimate nutrition',
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onPickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library, color: cyan),
              label: Text(
                'Choose from Gallery',
                style: TextStyle(color: cyan),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: cyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Voice Tab
// ─────────────────────────────────────────────────────────────────

class _VoiceTab extends StatefulWidget {
  final void Function(String) onSubmit;
  final bool isDark;

  const _VoiceTab({required this.onSubmit, required this.isDark});

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  bool _isListening = false;
  String _transcribedText = '';

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (!_isListening && _transcribedText.isNotEmpty) {
        // In a real implementation, this would use speech_to_text package
        // For now, show a message that voice is not yet implemented
        _transcribedText = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(_isListening ? 40 : 32),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? coral.withOpacity(0.2)
                          : teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: coral.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      size: 48,
                      color: _isListening ? coral : teal,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isListening ? 'Listening...' : 'Tap to Speak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe what you ate',
                  style: TextStyle(fontSize: 14, color: textMuted),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"I had two scrambled eggs with toast and a glass of orange juice"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.warning : AppColorsLight.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark ? AppColors.warning : AppColorsLight.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Voice input coming soon! Use the Describe tab for now.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
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

// ─────────────────────────────────────────────────────────────────
// Describe Tab
// ─────────────────────────────────────────────────────────────────

class _DescribeTab extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isDark;

  const _DescribeTab({
    required this.controller,
    required this.onSubmit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What did you eat?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText:
                    'e.g., 2 eggs, toast with butter, and a glass of orange juice',
                hintStyle: TextStyle(color: textMuted),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickSuggestion(
                label: 'Coffee',
                onTap: () => _appendText(controller, 'coffee'),
                isDark: isDark,
              ),
              _QuickSuggestion(
                label: 'Eggs',
                onTap: () => _appendText(controller, '2 eggs'),
                isDark: isDark,
              ),
              _QuickSuggestion(
                label: 'Toast',
                onTap: () => _appendText(controller, 'toast'),
                isDark: isDark,
              ),
              _QuickSuggestion(
                label: 'Salad',
                onTap: () => _appendText(controller, 'salad'),
                isDark: isDark,
              ),
              _QuickSuggestion(
                label: 'Chicken',
                onTap: () => _appendText(controller, 'chicken breast'),
                isDark: isDark,
              ),
              _QuickSuggestion(
                label: 'Rice',
                onTap: () => _appendText(controller, '1 cup rice'),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log This Meal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _appendText(TextEditingController controller, String text) {
    if (controller.text.isNotEmpty && !controller.text.endsWith(', ')) {
      controller.text += ', ';
    }
    controller.text += text;
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickSuggestion({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          '+ $label',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Scan Tab (Barcode Scanner)
// ─────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  final void Function(String) onBarcodeDetected;
  final bool isDark;

  const _ScanTab({required this.onBarcodeDetected, required this.isDark});

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  MobileScannerController? _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_hasDetected) return;
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _hasDetected = true;
                        widget.onBarcodeDetected(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              ),
              // Scan overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: teal, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Scan a Barcode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a product barcode',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Tab (Recent/Favorites)
// ─────────────────────────────────────────────────────────────────

class _QuickTab extends ConsumerWidget {
  final String userId;
  final MealType mealType;
  final VoidCallback onLogged;
  final bool isDark;

  const _QuickTab({
    required this.userId,
    required this.mealType,
    required this.onLogged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // Get recent unique food items
    final recentItems = <String, Map<String, dynamic>>{};
    for (final log in state.recentLogs.take(20)) {
      for (final item in log.foodItems) {
        if (!recentItems.containsKey(item.name)) {
          recentItems[item.name] = {
            'name': item.name,
            'calories': item.calories ?? 0,
            'protein': item.proteinG ?? 0,
            'carbs': item.carbsG ?? 0,
            'fat': item.fatG ?? 0,
          };
        }
      }
    }

    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No recent items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log some meals to see them here',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'RECENT ITEMS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...recentItems.values.take(10).map((item) => _QuickFoodItem(
              name: item['name'] as String,
              calories: item['calories'] as int,
              onTap: () async {
                // Log using text description
                final repository = ref.read(nutritionRepositoryProvider);
                try {
                  await repository.logFoodFromText(
                    userId: userId,
                    description: item['name'] as String,
                    mealType: mealType.value,
                  );
                  onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: isDark,
            )),
      ],
    );
  }
}

class _QuickFoodItem extends StatelessWidget {
  final String name;
  final int calories;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickFoodItem({
    required this.name,
    required this.calories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$calories kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: teal,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_circle, color: teal, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────

class _NutritionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _NutritionInfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted)),
          Text(value, style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
