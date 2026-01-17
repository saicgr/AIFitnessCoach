import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit.dart';

/// Bottom sheet showing habit templates grouped by category
class HabitTemplatesSheet extends StatelessWidget {
  final ScrollController? scrollController;
  final ValueChanged<HabitTemplate> onTemplateSelected;

  const HabitTemplatesSheet({
    super.key,
    this.scrollController,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Group templates by category
    final groupedTemplates = <HabitCategory, List<HabitTemplate>>{};
    for (final template in HabitTemplate.defaults) {
      groupedTemplates.putIfAbsent(template.category, () => []).add(template);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Choose a Template',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          // Templates list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: groupedTemplates.length,
              itemBuilder: (context, index) {
                final category = groupedTemplates.keys.elementAt(index);
                final templates = groupedTemplates[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 20,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Template cards
                    ...templates.map((template) => _buildTemplateCard(
                          context,
                          template,
                        )),

                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, HabitTemplate template) {
    final templateColor = _parseColor(template.color);
    final isNegative = template.habitType == HabitType.negative;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onTemplateSelected(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: templateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(template.icon),
                  color: templateColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (isNegative)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AVOID',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (template.suggestedTargetCount != null &&
                        template.unit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${template.suggestedTargetCount} ${template.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: templateColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Add icon
              Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.nutrition:
        return Icons.restaurant;
      case HabitCategory.activity:
        return Icons.directions_run;
      case HabitCategory.health:
        return Icons.favorite;
      case HabitCategory.lifestyle:
        return Icons.self_improvement;
      default:
        return Icons.check_circle;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_run':
        return Icons.directions_run;
      case 'water_drop':
        return Icons.water_drop;
      case 'restaurant':
        return Icons.restaurant;
      case 'bedtime':
        return Icons.bedtime;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'menu_book':
        return Icons.menu_book;
      case 'medication':
        return Icons.medication;
      case 'no_drinks':
        return Icons.no_drinks;
      case 'eco':
        return Icons.eco;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'spa':
        return Icons.spa;
      case 'edit_note':
        return Icons.edit_note;
      case 'do_not_disturb':
        return Icons.do_not_disturb;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'phone_disabled':
        return Icons.phone_disabled;
      default:
        return Icons.check_circle;
    }
  }

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.teal;
    }
  }
}
