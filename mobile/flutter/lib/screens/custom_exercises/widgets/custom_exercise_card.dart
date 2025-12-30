import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget for displaying a custom exercise
class CustomExerciseCard extends StatelessWidget {
  final CustomExercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: exercise.isComposite
                          ? cyan.withOpacity(0.2)
                          : (isDark ? AppColors.surface : AppColorsLight.surface),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        exercise.isComposite
                            ? Icons.layers
                            : Icons.fitness_center,
                        color: exercise.isComposite
                            ? cyan
                            : textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(
                              context,
                              exercise.typeLabel,
                              exercise.isComposite ? cyan : textSecondary,
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              context,
                              exercise.primaryMuscle,
                              textSecondary,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      onPressed: () {
                        HapticService.light();
                        onDelete?.call();
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ),

              // Component exercises preview (for composites)
              if (exercise.isComposite && exercise.componentExercises != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surface.withOpacity(0.5)
                        : AppColorsLight.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list,
                            size: 14,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${exercise.componentCount} exercises',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise.componentExercises!
                            .map((c) => c.name)
                            .join(' → '),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Details row
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailChip(
                    context,
                    Icons.repeat,
                    '${exercise.defaultSets} sets',
                    isDark,
                  ),
                  if (exercise.defaultReps != null) ...[
                    const SizedBox(width: 12),
                    _buildDetailChip(
                      context,
                      Icons.fitness_center,
                      '${exercise.defaultReps} reps',
                      isDark,
                    ),
                  ],
                  const Spacer(),
                  // Equipment
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface.withOpacity(0.5)
                          : AppColorsLight.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEquipmentIcon(exercise.equipment),
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEquipment(exercise.equipment),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Usage stats (if used)
              if (exercise.hasBeenUsed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Used ${exercise.usageCount} times',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    if (exercise.lastUsedFormatted != null) ...[
                      const Text(' • '),
                      Text(
                        exercise.lastUsedFormatted!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark,
  ) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return Icons.sports_gymnastics;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'cable':
        return Icons.swap_vert;
      case 'machine':
        return Icons.settings;
      case 'bodyweight':
        return Icons.accessibility_new;
      case 'kettlebell':
        return Icons.fitness_center;
      case 'resistance band':
      case 'band':
        return Icons.linear_scale;
      default:
        return Icons.sports;
    }
  }

  String _formatEquipment(String equipment) {
    // Capitalize first letter
    if (equipment.isEmpty) return 'Bodyweight';
    return equipment[0].toUpperCase() + equipment.substring(1);
  }
}
