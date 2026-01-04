import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/haptic_service.dart';

/// Compact workout row - minimal workout display with quick start
/// Used below nutrition/fasting hero cards when workout isn't primary focus
class CompactWorkoutRow extends ConsumerWidget {
  final Workout workout;

  const CompactWorkoutRow({
    super.key,
    required this.workout,
  });

  String _getDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return '';
    try {
      final date = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final workoutDate = DateTime(date.year, date.month, date.day);

      if (workoutDate == today) {
        return 'Today';
      } else if (workoutDate == tomorrow) {
        return 'Tomorrow';
      } else {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[date.weekday - 1];
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final dateLabel = _getDateLabel(workout.scheduledDate);
    final isToday = dateLabel == 'Today';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticService.light();
              context.push('/workout/${workout.id}');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Workout icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.cyan.withValues(alpha: 0.15)
                          : AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: isToday ? AppColors.cyan : AppColors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Workout info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (dateLabel.isNotEmpty) ...[
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? AppColors.cyan : AppColors.purple,
                                ),
                              ),
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                workout.name ?? 'Workout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${workout.durationMinutes ?? 45}min • ${workout.exerciseCount} exercises',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Start button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.cyan : AppColors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticService.medium();
                        context.push('/active-workout', extra: workout);
                      },
                      icon: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
