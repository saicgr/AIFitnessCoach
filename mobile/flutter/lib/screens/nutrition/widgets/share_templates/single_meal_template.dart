import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/nutrition.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Single-meal share card — what the user just ate, ready to drop into IG
/// Stories or send to a friend. Compact: photo (when present), meal name,
/// macros, health score. Sized to Instagram Stories (1080x1920) by the
/// caller's RepaintBoundary.
class SingleMealShareTemplate extends StatelessWidget {
  final FoodLog meal;
  final bool showWatermark;

  const SingleMealShareTemplate({
    super.key,
    required this.meal,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mealLabel = meal.mealType.isEmpty
        ? 'Meal'
        : '${meal.mealType[0].toUpperCase()}${meal.mealType.substring(1)}';
    final title = (meal.userQuery?.trim().isNotEmpty == true)
        ? meal.userQuery!
        : meal.foodItems.map((f) => f.name).take(3).join(' + ');
    final score = meal.healthScore;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1B2D), Color(0xFF1A2942)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mealLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 22,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
                height: 1.05,
              )),
          const SizedBox(height: 32),
          if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                meal.imageUrl!,
                width: double.infinity,
                height: 600,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const Spacer(),
          // Macro pills + cal headline
          Text('${meal.totalCalories} cal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MacroPill(label: 'P', grams: meal.proteinG, color: AppColors.macroProtein),
              _MacroPill(label: 'C', grams: meal.carbsG, color: AppColors.macroCarbs),
              _MacroPill(label: 'F', grams: meal.fatG, color: AppColors.macroFat),
              if (score != null)
                _ScoreBadge(score: score),
            ],
          ),
          if (showWatermark) ...[
            const SizedBox(height: 30),
            const AppWatermark(),
          ],
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  const _MacroPill({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '$label ${grams.round()}g',
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 8
        ? AppColors.success
        : (score >= 5 ? AppColors.warning : AppColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        'Score $score/10',
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
