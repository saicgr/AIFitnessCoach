import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A card showing weekly workout progress with a progress bar and day indicators
class WeeklyProgressCard extends StatelessWidget {
  /// Number of completed workouts this week
  final int completed;

  /// Total number of workouts planned for this week
  final int total;

  /// Whether to use dark theme
  final bool isDark;

  const WeeklyProgressCard({
    super.key,
    required this.completed,
    required this.total,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0-indexed
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed of $total workouts',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: glassSurface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isToday = index == today;
                final isPast = index < today;

                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.cyan.withOpacity(0.2)
                            : isPast
                                ? AppColors.success.withOpacity(0.2)
                                : glassSurface,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: AppColors.cyan, width: 2)
                            : null,
                      ),
                      child: isPast
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.success,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? AppColors.cyan : textMuted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
