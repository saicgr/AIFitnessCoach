import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/nutrition.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Health score template - Average health score with best/worst meals
class NutritionHealthScoreTemplate extends StatelessWidget {
  final List<FoodLog> meals;
  final int totalCalories;
  final int calorieTarget;
  final String dateLabel;
  final bool showWatermark;

  const NutritionHealthScoreTemplate({
    super.key,
    required this.meals,
    required this.totalCalories,
    required this.calorieTarget,
    required this.dateLabel,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate average health score
    final scoredMeals = meals.where((m) => m.healthScore != null).toList();
    final avgScore = scoredMeals.isNotEmpty
        ? (scoredMeals.fold<int>(0, (s, m) => s + m.healthScore!) / scoredMeals.length).round()
        : 0;

    // Best meal
    FoodLog? bestMeal;
    if (scoredMeals.isNotEmpty) {
      bestMeal = scoredMeals.reduce((a, b) => (a.healthScore ?? 0) >= (b.healthScore ?? 0) ? a : b);
    }

    final remaining = calorieTarget - totalCalories;
    final isOver = remaining < 0;

    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2027),
            avgScore >= 7 ? const Color(0xFF0D3320) : avgScore >= 4 ? const Color(0xFF332B00) : const Color(0xFF330D0D),
            const Color(0xFF0F2027),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'NUTRITION SCORE',
              style: TextStyle(
                color: _scoreColor(avgScore),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),

            const SizedBox(height: 28),

            // Big score
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _scoreColor(avgScore).withValues(alpha: 0.3),
                          _scoreColor(avgScore).withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(color: _scoreColor(avgScore).withValues(alpha: 0.5), width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      scoredMeals.isNotEmpty ? '$avgScore' : '-',
                      style: TextStyle(
                        color: _scoreColor(avgScore),
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scoredMeals.isNotEmpty ? _scoreLabel(avgScore) : 'No scores yet',
                    style: TextStyle(
                      color: _scoreColor(avgScore),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'avg across ${scoredMeals.length} meals',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Calories',
                  value: '$totalCalories',
                  subtitle: 'of $calorieTarget',
                  color: AppColors.teal,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: isOver ? 'Over' : 'Remaining',
                  value: '${remaining.abs()}',
                  subtitle: 'kcal',
                  color: isOver ? AppColors.error : AppColors.teal,
                )),
              ],
            ),

            if (bestMeal != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('\u{1F31F}', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best meal',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                          ),
                          Text(
                            bestMeal.foodItems.isNotEmpty ? bestMeal.foodItems.first.name : 'Meal',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${bestMeal.healthScore}/10',
                      style: TextStyle(color: _scoreColor(bestMeal.healthScore!), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 8) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Average';
    if (score >= 3) return 'Needs Work';
    return 'Poor';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
