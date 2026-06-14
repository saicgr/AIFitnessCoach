import 'package:flutter/material.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          ZealovaChip(
            label: AppLocalizations.of(context).syncedWorkoutsHistoryAll,
            selected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          // Category chips
          ...categories.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ZealovaChip(
                label: _formatCategory(category),
                selected: isSelected,
                onTap: () => onCategorySelected(isSelected ? null : category),
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
