import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/micronutrients.dart';

class PinnedNutrientsCard extends StatelessWidget {
  final List<NutrientProgress> pinned;
  final bool isDark;
  final VoidCallback? onEdit;

  const PinnedNutrientsCard({
    super.key,
    required this.pinned,
    required this.isDark,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'PINNED NUTRIENTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pinned.length}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: teal,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit, size: 13, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Horizontal scrollable nutrient chips — always visible
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pinned.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => _CompactNutrientChip(
                nutrient: pinned[i],
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ultra-compact horizontal chip: [color dot] Name  value/target unit  [thin bar]
class _CompactNutrientChip extends StatelessWidget {
  final NutrientProgress nutrient;
  final bool isDark;

  const _CompactNutrientChip({
    required this.nutrient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final color = Color(
        int.parse(nutrient.progressColor.replaceFirst('#', '0xFF')));
    final percentage = nutrient.percentage.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          // Name + value stacked
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nutrient.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${nutrient.formattedCurrent}/${nutrient.formattedTarget} ${nutrient.unit}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          // Tiny vertical progress bar
          SizedBox(
            width: 3,
            height: 20,
            child: RotatedBox(
              quarterTurns: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: elevated,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
