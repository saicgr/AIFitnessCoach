import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Button widget that shows filter icon with active filter count badge
class FilterButton extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.activeFilterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final hasActiveFilters = activeFilterCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasActiveFilters ? cyan.withOpacity(0.2) : elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActiveFilters
                ? cyan
                : (isDark ? Colors.transparent : AppColorsLight.cardBorder),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune,
              color: hasActiveFilters ? cyan : textMuted,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cyan,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
