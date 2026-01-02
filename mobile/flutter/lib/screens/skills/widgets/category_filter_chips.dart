import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Horizontal scrolling category filter chips
class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
            selectedColor: cyan,
            backgroundColor: elevated,
            textColor: textMuted,
            borderColor: cardBorder,
          ),
          const SizedBox(width: 8),
          // Category chips
          ...categories.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _formatCategory(category),
                isSelected: isSelected,
                onTap: () => onCategorySelected(isSelected ? null : category),
                selectedColor: cyan,
                backgroundColor: elevated,
                textColor: textMuted,
                borderColor: cardBorder,
                icon: _getCategoryIcon(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    // Capitalize first letter
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  IconData? _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'push':
      case 'pushing':
        return Icons.fitness_center_rounded;
      case 'pull':
      case 'pulling':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'legs':
      case 'squat':
        return Icons.directions_walk_rounded;
      case 'core':
      case 'abs':
        return Icons.accessibility_new_rounded;
      case 'balance':
      case 'handstand':
        return Icons.pan_tool_rounded;
      case 'flexibility':
      case 'mobility':
        return Icons.self_improvement_rounded;
      default:
        return null;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.15) : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? selectedColor : textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
