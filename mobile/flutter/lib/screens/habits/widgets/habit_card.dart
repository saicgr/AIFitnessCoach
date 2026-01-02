import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit.dart';

/// Individual habit card with toggle, streak, and actions
class HabitCard extends StatelessWidget {
  final HabitWithStatus habit;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = _parseColor(habit.color);
    final isNegative = habit.habitType == HabitType.negative;

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        if (onDelete != null) {
          onDelete!();
        }
        return false; // Don't dismiss, let the dialog handle it
      },
      child: Card(
        elevation: habit.todayCompleted ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: habit.todayCompleted
              ? BorderSide(color: habitColor.withValues(alpha: 0.5), width: 2)
              : BorderSide.none,
        ),
        color: habit.todayCompleted
            ? habitColor.withValues(alpha: 0.1)
            : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox / Toggle
                _buildToggle(habitColor),
                const SizedBox(width: 16),

                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: habit.todayCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: habit.todayCompleted
                                    ? Colors.grey
                                    : null,
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: habitColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              habit.category.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: habitColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Streak badge
                          if (habit.currentStreak > 0) ...[
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${habit.currentStreak}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // 7-day completion rate
                          if (habit.completionRate7d > 0) ...[
                            Icon(
                              Icons.show_chart,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${habit.completionRate7d.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Target progress for quantitative habits
                      if (habit.targetCount != null && habit.targetCount! > 1) ...[
                        const SizedBox(height: 8),
                        _buildProgressBar(habitColor),
                      ],
                    ],
                  ),
                ),

                // Menu button
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(Color color) {
    return GestureDetector(
      onTap: () => onToggle(!habit.todayCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: habit.todayCompleted ? color : Colors.transparent,
          border: Border.all(
            color: habit.todayCompleted ? color : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: habit.todayCompleted
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildProgressBar(Color color) {
    final progress = habit.todayValue != null && habit.targetCount != null
        ? (habit.todayValue! / habit.targetCount!).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${habit.todayValue?.round() ?? 0} / ${habit.targetCount} ${habit.unit ?? ''}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
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
