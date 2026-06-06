import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../services/meal_suggestion_widget_service.dart';
import '../log_meal_sheet.dart';

/// F3 — a compact "Coach recommends" card on the Nutrition Daily tab, backed by
/// the existing `/nutrition/quick-suggestion` endpoint (via
/// [MealSuggestionWidgetService], which already caches + refreshes the same
/// suggestion shown in the home-screen widget).
///
/// Body tap → opens the full log-meal sheet (where the AI coach lives) so the
/// user can refine. "Log this" → logs the suggestion's `food_items` directly to
/// its `meal_slot` for today (double-tap guarded). Renders nothing while there
/// is no cached/loaded suggestion (no empty shell on the tab).
class CoachRecommendsCard extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const CoachRecommendsCard({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<CoachRecommendsCard> createState() =>
      _CoachRecommendsCardState();
}

enum _LogState { idle, logging, logged, error }

class _CoachRecommendsCardState extends ConsumerState<CoachRecommendsCard> {
  QuickSuggestion? _suggestion;
  bool _loaded = false;
  _LogState _logState = _LogState.idle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Prefer the cached suggestion for an instant first paint; kick a
      // freshness refresh in the background (the service no-ops if fresh).
      final cached = await MealSuggestionWidgetService.instance.readCached();
      if (mounted && cached != null) {
        setState(() {
          _suggestion = cached;
          _loaded = true;
        });
      }
      final fresh = await MealSuggestionWidgetService.instance.refreshNow();
      if (mounted) {
        setState(() {
          _suggestion = fresh ?? _suggestion;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _logSuggestion() async {
    final s = _suggestion;
    if (s == null || s.foodItems.isEmpty) return;
    if (_logState == _LogState.logging || _logState == _LogState.logged) return;
    HapticService.medium();
    setState(() => _logState = _LogState.logging);
    try {
      final rankings = s.foodItems
          .map((it) => FoodItemRanking(
                name: it.name,
                calories: it.calories,
                proteinG: it.proteinG,
                carbsG: it.carbsG,
                fatG: it.fatG,
              ))
          .toList();
      final analyzed = LogFoodResponse(
        success: true,
        foodItems: rankings,
        totalCalories: s.calories,
        proteinG: s.proteinG,
        carbsG: s.carbsG,
        fatG: s.fatG,
        sourceType: 'ai_suggestion',
      );
      final slot = s.mealSlot == 'fasting' ? 'snack' : s.mealSlot;
      await ref.read(nutritionRepositoryProvider).logFoodDirect(
            userId: widget.userId,
            mealType: slot,
            analyzedFood: analyzed,
            sourceType: 'ai_suggestion',
            inputType: 'ai_suggestion',
            idempotencyKey: NutritionRepository.newMealIdempotencyKey(),
          );
      if (!mounted) return;
      HapticService.success();
      setState(() => _logState = _LogState.logged);
      ref
          .read(dailyNutritionProvider(todayNutritionKey()).notifier)
          .load(widget.userId, forceRefresh: true);
      ref
          .read(dailyNutritionProvider(todayNutritionKey()).notifier)
          .refreshTimeline();
    } catch (_) {
      if (!mounted) return;
      HapticService.error();
      setState(() => _logState = _LogState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _suggestion;
    // No empty shell: render nothing until a suggestion is available.
    if (!_loaded || s == null || s.title.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final proteinColor =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final hasItems = s.foodItems.isNotEmpty;
    final logged = _logState == _LogState.logged;
    final logging = _logState == _LogState.logging;

    Widget macroPill(String label, double grams, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text('$label ${grams.round()}g',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticService.light();
              // Open the full log-meal sheet (the AI coach lives there) so the
              // user can refine the suggestion before logging.
              showLogMealSheet(context, ref);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'COACH RECOMMENDS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary),
                            ),
                            if (s.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(s.subtitle,
                                  style: TextStyle(
                                      fontSize: 12, color: textSecondary)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${s.calories} kcal',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: accent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      macroPill('P', s.proteinG, proteinColor),
                      macroPill('C', s.carbsG, carbsColor),
                      macroPill('F', s.fatG, fatColor),
                    ],
                  ),
                  if (hasItems) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (logging || logged) ? null : _logSuggestion,
                        icon: Icon(
                            logged
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            size: 18),
                        label: Text(logged ? 'Logged' : 'Log this'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logged
                              ? AppColors.green.withValues(alpha: 0.2)
                              : accent,
                          foregroundColor: logged ? AppColors.green : Colors.white,
                          disabledBackgroundColor: logged
                              ? AppColors.green.withValues(alpha: 0.2)
                              : accent.withValues(alpha: 0.5),
                          disabledForegroundColor:
                              logged ? AppColors.green : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (_logState == _LogState.error)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text("Couldn't log that — tap to try again.",
                            style: TextStyle(
                                fontSize: 11, color: AppColors.error)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
