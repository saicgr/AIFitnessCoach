import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Compact week progress strip showing day circles and completion count
/// Displays M T W T F S S with visual states for completed/today/upcoming
class WeekProgressStrip extends ConsumerWidget {
  const WeekProgressStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Watch the workouts provider to get this week's data
    final workoutsAsync = ref.watch(workoutsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          context.go('/workouts');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: workoutsAsync.when(
            data: (workouts) {
              // Calculate week data
              final now = DateTime.now();
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              final todayIndex = now.weekday - 1; // 0 = Monday

              // Get this week's workouts
              final thisWeekWorkouts = workouts.where((w) {
                final date = w.scheduledLocalDate;
                if (date == null) return false;
                final workoutWeekStart = date.subtract(Duration(days: date.weekday - 1));
                return workoutWeekStart.year == weekStart.year &&
                    workoutWeekStart.month == weekStart.month &&
                    workoutWeekStart.day == weekStart.day;
              }).toList();

              // Create day states
              final dayStates = List<_DayState>.generate(7, (index) {
                final dayDate = weekStart.add(Duration(days: index));
                final dayWorkouts = thisWeekWorkouts.where((w) {
                  final date = w.scheduledLocalDate;
                  if (date == null) return false;
                  return date.year == dayDate.year &&
                      date.month == dayDate.month &&
                      date.day == dayDate.day;
                }).toList();

                final hasWorkout = dayWorkouts.isNotEmpty;
                final isCompleted = dayWorkouts.any((w) => w.isCompleted == true);
                final isToday = index == todayIndex;
                final isPast = index < todayIndex;

                return _DayState(
                  hasWorkout: hasWorkout,
                  isCompleted: isCompleted,
                  isToday: isToday,
                  isPast: isPast,
                );
              });

              // Count completed
              final completedCount = dayStates.where((d) => d.isCompleted).length;
              final totalScheduled = dayStates.where((d) => d.hasWorkout).length;

              return Column(
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Day circles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      return _DayCircle(
                        dayLabel: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                        state: dayStates[index],
                        isDark: isDark,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Progress text
                  Text(
                    totalScheduled > 0
                        ? '$completedCount of $totalScheduled workouts completed'
                        : 'No workouts scheduled this week',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            },
            loading: () => _buildLoading(textSecondary),
            error: (_, __) => _buildError(textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading...',
          style: TextStyle(fontSize: 13, color: textColor),
        ),
      ],
    );
  }

  Widget _buildError(Color textColor) {
    return Text(
      'Could not load progress',
      style: TextStyle(fontSize: 13, color: textColor),
    );
  }
}

/// State for each day in the week
class _DayState {
  final bool hasWorkout;
  final bool isCompleted;
  final bool isToday;
  final bool isPast;

  const _DayState({
    required this.hasWorkout,
    required this.isCompleted,
    required this.isToday,
    required this.isPast,
  });
}

/// Individual day circle widget
class _DayCircle extends StatelessWidget {
  final String dayLabel;
  final _DayState state;
  final bool isDark;

  const _DayCircle({
    required this.dayLabel,
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Monochrome accent - white in dark mode, black in light mode
    final accentColor = textPrimary;

    // Determine appearance based on state
    Color bgColor;
    Color borderColor;
    Widget? centerWidget;

    if (state.isCompleted) {
      // Completed - filled green with checkmark
      bgColor = AppColors.success;
      borderColor = AppColors.success;
      centerWidget = Icon(Icons.check, size: 16, color: Colors.white);
    } else if (state.isToday) {
      // Today - monochrome accent ring
      bgColor = accentColor.withValues(alpha: 0.15);
      borderColor = accentColor;
      centerWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accentColor,
        ),
      );
    } else if (state.hasWorkout && state.isPast) {
      // Missed workout - red outline
      bgColor = AppColors.error.withValues(alpha: 0.1);
      borderColor = AppColors.error.withValues(alpha: 0.5);
      centerWidget = null;
    } else if (state.hasWorkout) {
      // Future scheduled - outlined
      bgColor = Colors.transparent;
      borderColor = textMuted.withValues(alpha: 0.5);
      centerWidget = null;
    } else {
      // No workout - very faint
      bgColor = Colors.transparent;
      borderColor = textMuted.withValues(alpha: 0.2);
      centerWidget = null;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: state.isToday ? 2 : 1),
          ),
          child: Center(child: centerWidget),
        ),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: state.isToday ? FontWeight.bold : FontWeight.normal,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
