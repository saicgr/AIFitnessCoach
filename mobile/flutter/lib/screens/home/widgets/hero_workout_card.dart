import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'regenerate_workout_sheet.dart';

/// Hero workout card - prominent action-focused workout display
/// Features a big START button as the primary action
class HeroWorkoutCard extends ConsumerStatefulWidget {
  final Workout workout;

  const HeroWorkoutCard({
    super.key,
    required this.workout,
  });

  @override
  ConsumerState<HeroWorkoutCard> createState() => _HeroWorkoutCardState();
}

class _HeroWorkoutCardState extends ConsumerState<HeroWorkoutCard> {
  bool _isSkipping = false;

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'Scheduled';
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
      return 'Scheduled';
    }
  }

  Future<void> _regenerateWorkout() async {
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    if (newWorkout != null && mounted) {
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout regenerated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _skipWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Skip Workout?'),
        content: const Text(
          'This workout will be marked as skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout skipped'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not skip workout'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSkipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final workout = widget.workout;
    final dateLabel = _getScheduledDateLabel(workout.scheduledDate);
    final isToday = dateLabel == 'Today';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday
                ? AppColors.cyan.withValues(alpha: 0.4)
                : AppColors.purple.withValues(alpha: 0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isToday ? AppColors.cyan : AppColors.purple).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.cyan.withValues(alpha: 0.15)
                          : AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.cyan : AppColors.purple,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workout name - tappable
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}');
                    },
                    child: Text(
                      workout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${workout.durationMinutes ?? 45} min',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${workout.exerciseCount} exercises',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Big START button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        context.push('/active-workout', extra: workout);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isToday ? AppColors.cyan : AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'START',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Regenerate button
                      TextButton.icon(
                        onPressed: () {
                          HapticService.light();
                          _regenerateWorkout();
                        },
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        label: Text(
                          'Regenerate',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: textSecondary.withValues(alpha: 0.3),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // Skip button
                      TextButton.icon(
                        onPressed: _isSkipping ? null : () {
                          HapticService.light();
                          _skipWorkout();
                        },
                        icon: _isSkipping
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: textSecondary,
                                ),
                              )
                            : Icon(
                                Icons.skip_next_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                        label: Text(
                          'Skip',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stat chip showing icon + label
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Card shown when generating workouts
class GeneratingHeroCard extends StatelessWidget {
  final String? message;

  const GeneratingHeroCard({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'Generating your workout...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
