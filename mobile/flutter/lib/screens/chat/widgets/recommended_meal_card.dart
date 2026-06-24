import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';

/// F3 — renders the backend `meal_recommended` chat action as a rich meal card
/// with a one-tap "Log this" button.
///
/// Contract (`action_data`):
/// ```
/// {
///   "action": "meal_recommended",
///   "meal": {
///     "emoji": str, "title": str, "subtitle": str,
///     "calories": int, "protein_g": num, "carbs_g": num, "fat_g": num,
///     "food_items": [{"name": str, "calories": int,
///                     "protein_g": num, "carbs_g": num, "fat_g": num}]
///   },
///   "macros_fit": {...},   // optional — how it fits remaining budget
///   "meal_slot": str,      // breakfast | lunch | dinner | snack
///   "log_cta": true
/// }
/// ```
///
/// "Log this" writes `meal.food_items` to `meal_slot` for today via the
/// existing food-log path ([NutritionRepository.logFoodDirect]). Double-tap
/// guarded: the button disables after the first tap.
class RecommendedMealCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> actionData;

  const RecommendedMealCard({
    super.key,
    required this.actionData,
  });

  @override
  ConsumerState<RecommendedMealCard> createState() =>
      _RecommendedMealCardState();
}

enum _LogState { idle, logging, logged, error }

class _RecommendedMealCardState extends ConsumerState<RecommendedMealCard> {
  _LogState _state = _LogState.idle;

  Map<String, dynamic>? get _meal {
    final m = widget.actionData['meal'];
    return m is Map ? Map<String, dynamic>.from(m) : null;
  }

  String get _mealSlot {
    final slot = widget.actionData['meal_slot'];
    if (slot is String && slot.trim().isNotEmpty) return slot.trim();
    return 'snack';
  }

  List<Map<String, dynamic>> get _foodItems {
    final raw = _meal?['food_items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  num _num(Object? v) => v is num ? v : 0;

  Future<void> _logMeal() async {
    if (_state == _LogState.logging || _state == _LogState.logged) return;
    final items = _foodItems;
    if (items.isEmpty) return;
    HapticService.medium();
    setState(() => _state = _LogState.logging);

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() => _state = _LogState.error);
        return;
      }
      final meal = _meal!;
      // Build a LogFoodResponse from the recommended meal so we reuse the
      // canonical confirmed-log path (logFoodDirect → logAdjustedFood).
      final rankings = items
          .map((it) => FoodItemRanking(
                name: (it['name'] ?? 'Food').toString(),
                calories: _num(it['calories']).round(),
                proteinG: _num(it['protein_g']).toDouble(),
                carbsG: _num(it['carbs_g']).toDouble(),
                fatG: _num(it['fat_g']).toDouble(),
              ))
          .toList();

      final analyzed = LogFoodResponse(
        success: true,
        foodItems: rankings,
        totalCalories: _num(meal['calories']).round(),
        proteinG: _num(meal['protein_g']).toDouble(),
        carbsG: _num(meal['carbs_g']).toDouble(),
        fatG: _num(meal['fat_g']).toDouble(),
        sourceType: 'chat',
      );

      await ref.read(nutritionRepositoryProvider).logFoodDirect(
            userId: userId,
            mealType: _mealSlot,
            analyzedFood: analyzed,
            sourceType: 'chat',
            inputType: 'ai_suggestion',
            idempotencyKey: NutritionRepository.newMealIdempotencyKey(),
          );

      if (!mounted) return;
      HapticService.success();
      setState(() => _state = _LogState.logged);
      // Refresh today's summary so the meal appears on the Nutrition tab.
      ref.read(dailyNutritionProvider(todayNutritionKey()).notifier).load(
            userId,
            forceRefresh: true,
          );
      ref.read(dailyNutritionProvider(todayNutritionKey()).notifier).refreshTimeline();
    } catch (e) {
      if (!mounted) return;
      HapticService.error();
      setState(() => _state = _LogState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    if (meal == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final proteinColor =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final emoji = (meal['emoji'] ?? '🍽️').toString();
    final title = (meal['title'] ?? 'Suggested meal').toString();
    final subtitle = (meal['subtitle'] ?? '').toString();
    final calories = _num(meal['calories']).round();
    final hasFoodItems = _foodItems.isNotEmpty;
    final showLogCta = widget.actionData['log_cta'] != false && hasFoodItems;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: emoji + title/subtitle + calories
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZType.sans(
                          15,
                          weight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: ZType.ser(
                            12.5,
                            color: textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$calories',
                      style: ZType.data(18, color: accent),
                    ),
                    Text(
                      'KCAL',
                      style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Macro pills — AccentColorScope macro-specific colors.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroPill(
                  label: 'P',
                  grams: _num(meal['protein_g']),
                  color: proteinColor,
                ),
                _MacroPill(
                  label: 'C',
                  grams: _num(meal['carbs_g']),
                  color: carbsColor,
                ),
                _MacroPill(
                  label: 'F',
                  grams: _num(meal['fat_g']),
                  color: fatColor,
                ),
              ],
            ),
            if (showLogCta) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _LogButton(
                  state: _state,
                  accent: accent,
                  mealSlot: _mealSlot,
                  onTap: _logMeal,
                ),
              ),
              if (_state == _LogState.error)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Couldn't log that — tap to try again.",
                    style: ZType.sans(
                      11,
                      weight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final num grams;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$label ${grams.round()} grams',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: ZType.lbl(11, color: color, letterSpacing: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              '${grams.round()}g',
              style: ZType.data(12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final _LogState state;
  final Color accent;
  final String mealSlot;
  final VoidCallback onTap;

  const _LogButton({
    required this.state,
    required this.accent,
    required this.mealSlot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logged = state == _LogState.logged;
    final logging = state == _LogState.logging;
    final slotLabel = mealSlot.isEmpty
        ? ''
        : ' to ${mealSlot[0].toUpperCase()}${mealSlot.substring(1)}';
    final label = logged ? 'Logged' : 'Log this$slotLabel';

    return Semantics(
      button: true,
      enabled: !logged && !logging,
      label: label,
      child: ElevatedButton(
        onPressed: (logging || logged) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: logged
              ? AppColors.green.withValues(alpha: 0.2)
              : accent,
          foregroundColor: logged ? AppColors.green : Colors.white,
          disabledBackgroundColor: logged
              ? AppColors.green.withValues(alpha: 0.2)
              : accent.withValues(alpha: 0.5),
          disabledForegroundColor: logged ? AppColors.green : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logging)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(logged ? Icons.check_rounded : Icons.add_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: ZType.lbl(
                14,
                color: logged ? AppColors.green : Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
