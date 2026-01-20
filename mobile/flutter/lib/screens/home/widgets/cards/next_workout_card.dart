import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/difficulty_utils.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../components/stat_badge.dart';
import '../regenerate_workout_sheet.dart';
import 'exercise_image_thumbnail.dart';

/// The main workout card showing the next scheduled workout
/// Displays workout details with start, customize, and skip actions
class NextWorkoutCard extends ConsumerStatefulWidget {
  /// The workout to display
  final Workout workout;

  /// Callback when start button is pressed
  final VoidCallback onStart;

  /// Whether to show the "Upcoming" link (hide on Workouts screen)
  final bool showUpcomingLink;

  const NextWorkoutCard({
    super.key,
    required this.workout,
    required this.onStart,
    this.showUpcomingLink = true,
  });

  @override
  ConsumerState<NextWorkoutCard> createState() => _NextWorkoutCardState();
}

class _NextWorkoutCardState extends ConsumerState<NextWorkoutCard> {
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
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      }
    } catch (_) {
      return 'Scheduled';
    }
  }

  Future<void> _regenerateWorkout() async {
    // Show the regenerate customization sheet
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    // If a new workout was returned, refresh the list
    if (newWorkout != null && mounted) {
      await ref.read(workoutsProvider.notifier).refresh();
      // Invalidate provider to force UI rebuild with fresh data
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Skip Workout?'),
        content: const Text(
          'This workout will be marked as skipped and won\'t count towards your weekly goal.',
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
      // Reschedule to mark as skipped - move to yesterday so it's "past"
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        await ref.read(workoutsProvider.notifier).refresh();
        // Invalidate provider to force UI rebuild with fresh data
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
            content: Text('Could not skip workout. Please try again.'),
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
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final workout = widget.workout;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final exercises = workout.exercises;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              elevatedColor,
              elevatedColor.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badges row with View Upcoming link
                  Row(
                    children: [
                      // Badges - tappable to view workout detail
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            context.push('/workout/${workout.id}');
                          },
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Scheduled date badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getScheduledDateLabel(workout.scheduledDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Workout type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  workout.type?.toUpperCase() ?? 'STRENGTH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DifficultyUtils.getDisplayName(workout.difficulty ?? 'medium'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // View Upcoming link (hidden on Workouts screen)
                      if (widget.showUpcomingLink)
                        GestureDetector(
                          onTap: () {
                            HapticService.light();
                            // Navigate to Workouts tab and scroll to upcoming section
                            context.go('/workouts?scrollTo=upcoming');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Upcoming',
                                style: TextStyle(
                                  color: ref.colors(context).accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: ref.colors(context).accent,
                                size: 16,
                              ),
                            ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title - tappable to view workout detail
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}');
                    },
                    child: Text(
                      workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row - tappable to view workout detail
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}');
                    },
                    child: Row(
                      children: [
                        StatPill(
                          icon: Icons.timer_outlined,
                          value: workout.formattedDurationShort,
                        ),
                        const SizedBox(width: 12),
                        StatPill(
                          icon: Icons.fitness_center,
                          value: '${workout.exerciseCount} exercises',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons row - Start and quick actions
                  Row(
                    children: [
                      // Main Start button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticService.medium();
                            context.push('/active-workout', extra: workout);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Regenerate icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticService.light();
                            _regenerateWorkout();
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          color: accentColor,
                          tooltip: 'Regenerate',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isSkipping
                              ? null
                              : () {
                                  HapticService.light();
                                  _skipWorkout();
                                },
                          icon: _isSkipping
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.skip_next, size: 20),
                          color: AppColors.textMuted,
                          tooltip: 'Skip',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exercise preview strip at bottom - tappable to view workout detail
            if (exercises.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticService.selection();
                  context.push('/workout/${workout.id}');
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ExerciseImageThumbnail(
                          exercise: exercise,
                          size: 44,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
    );
  }
}
