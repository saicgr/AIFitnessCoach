import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood.dart';

/// Card displaying a single mood check-in in the history
class MoodHistoryItemCard extends StatelessWidget {
  final MoodHistoryItem item;
  final VoidCallback? onWorkoutTap;

  const MoodHistoryItemCard({
    super.key,
    required this.item,
    this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Mood emoji circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.moodEmoji,
              style: const TextStyle(fontSize: 24),
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
                    Text(
                      'Feeling ${item.mood}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    if (item.workoutGenerated) ...[
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        item.workoutCompleted ? 'Completed' : 'Generated',
                        item.workoutCompleted ? Colors.green : item.color,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item.checkInTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    if (item.context != null) ...[
                      const SizedBox(width: 12),
                      if (item.context!['time_of_day'] != null)
                        _buildContextChip(
                          _capitalizeFirst(item.context!['time_of_day'] as String),
                          textSecondary,
                        ),
                    ],
                  ],
                ),
                // Workout info
                if (item.workout != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onWorkoutTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: item.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.workout!.name ?? 'Mood Workout',
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onWorkoutTap != null)
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContextChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('h:mm a').format(dateTime);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
