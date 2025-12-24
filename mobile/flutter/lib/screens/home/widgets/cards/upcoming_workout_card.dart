import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/services/haptic_service.dart';

/// A compact card for displaying upcoming workouts in a list
class UpcomingWorkoutCard extends StatelessWidget {
  /// The workout to display
  final Workout workout;

  /// Callback when the card is tapped
  final VoidCallback onTap;

  const UpcomingWorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final typeColor =
        AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.selection();
            debugPrint('Target: [UpcomingCard] Tapped: ${workout.name}');
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDay(workout.scheduledDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        _getMonth(workout.scheduledDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name ?? 'Workout',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${workout.durationMinutes ?? 45}m - ${workout.exerciseCount} exercises',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDay(String? date) {
    if (date == null) return '--';
    try {
      final d = DateTime.parse(date);
      return d.day.toString();
    } catch (_) {
      return '--';
    }
  }

  String _getMonth(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return months[d.month - 1];
    } catch (_) {
      return '';
    }
  }
}
