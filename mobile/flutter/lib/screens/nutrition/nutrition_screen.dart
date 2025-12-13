import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
// Log Meal Sheet (Simple placeholder - would need AI integration)
// ─────────────────────────────────────────────────────────────────

class _LogMealSheet extends StatefulWidget {
  final String userId;
  final bool isDark;

  const _LogMealSheet({required this.userId, required this.isDark});

  @override
  State<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<_LogMealSheet> {
  MealType _selectedType = MealType.lunch;

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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Log a Meal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MEAL TYPE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: MealType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? teal.withOpacity(0.2) : elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? teal : cardBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            type.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cyan.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take a Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'AI will analyze your meal automatically',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: Take a photo of your meal and our AI will estimate calories and macros',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
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
