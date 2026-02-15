import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';

/// Shows the upcoming workouts bottom sheet
Future<void> showUpcomingWorkoutsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final parentTheme = Theme.of(context);

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return showGlassSheet<void>(
    context: context,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: const _UpcomingWorkoutsSheet(),
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _UpcomingWorkoutsSheet extends ConsumerStatefulWidget {
  const _UpcomingWorkoutsSheet();

  @override
  ConsumerState<_UpcomingWorkoutsSheet> createState() => _UpcomingWorkoutsSheetState();
}

class _UpcomingWorkoutsSheetState extends ConsumerState<_UpcomingWorkoutsSheet> {
  /// Track which dates are currently generating
  final Set<String> _generatingDates = {};

  @override
  Widget build(BuildContext context) {
    // Load workouts on-demand from the provider
    final workoutsState = ref.watch(workoutsProvider);
    final workouts = workoutsState.valueOrNull ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;

    // Get user's workout days
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final workoutDays = user?.workoutDays ?? [0, 2, 4]; // Default Mon, Wed, Fri

    // Calculate upcoming dates for this week and next week
    final upcomingDates = _calculateUpcomingDates(workoutDays);

    // Group by week
    final thisWeekDates = <DateTime>[];
    final nextWeekDates = <DateTime>[];
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));

    for (final date in upcomingDates) {
      if (date.isBefore(startOfNextWeek)) {
        thisWeekDates.add(date);
      } else {
        nextWeekDates.add(date);
      }
    }

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Workouts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap a date to generate your workout',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This week
                  if (thisWeekDates.isNotEmpty) ...[
                    _buildWeekHeader('This Week', textSecondary),
                    const SizedBox(height: 8),
                    ...thisWeekDates.map((date) => _buildDateRow(
                      context,
                      date,
                      isDark,
                      accentColor,
                      textPrimary,
                      textSecondary,
                      workouts,
                    )),
                  ],

                  // Next week
                  if (nextWeekDates.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildWeekHeader('Next Week', textSecondary),
                    const SizedBox(height: 8),
                    ...nextWeekDates.map((date) => _buildDateRow(
                      context,
                      date,
                      isDark,
                      accentColor,
                      textPrimary,
                      textSecondary,
                      workouts,
                    )),
                  ],

                  if (upcomingDates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No workout days scheduled',
                              style: TextStyle(
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Update your workout schedule in Settings',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Calculate upcoming workout dates based on user's selected days
  List<DateTime> _calculateUpcomingDates(List<int> workoutDays) {
    final dates = <DateTime>[];
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    // Look ahead 14 days (this week + next week)
    for (int i = 0; i < 14; i++) {
      final date = todayDateOnly.add(Duration(days: i));
      // weekday: 1=Mon, 7=Sun, but our workoutDays uses 0=Mon, 6=Sun
      final adjustedWeekday = date.weekday - 1; // Convert to 0-indexed

      if (workoutDays.contains(adjustedWeekday)) {
        dates.add(date);
      }
    }

    return dates;
  }

  /// Check if a workout exists for the given date
  Workout? _getWorkoutForDate(DateTime date, List<Workout> workouts) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    for (final workout in workouts) {
      if (workout.scheduledDate != null) {
        final workoutDate = workout.scheduledDate!.split('T')[0];
        if (workoutDate == dateStr && workout.isCompleted != true) {
          return workout;
        }
      }
    }
    return null;
  }

  Widget _buildDateRow(
    BuildContext context,
    DateTime date,
    bool isDark,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
    List<Workout> workouts,
  ) {
    final cardColor = isDark
        ? AppColors.background.withValues(alpha: 0.5)
        : AppColorsLight.background;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final existingWorkout = _getWorkoutForDate(date, workouts);
    final isGenerating = _generatingDates.contains(dateStr);

    // Format date display
    final dayName = DateFormat('EEE').format(date); // Mon, Tue, etc
    final dayNum = DateFormat('d').format(date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.light();
            if (existingWorkout != null) {
              // Close sheet and navigate to workout detail
              Navigator.of(context).pop();
              context.push('/workout/${existingWorkout.id}');
            } else if (!isGenerating) {
              // Generate workout for this date
              _generateWorkoutForDate(dateStr);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? accentColor.withValues(alpha: 0.2)
                        : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: existingWorkout != null
                      ? _buildWorkoutInfo(existingWorkout, textPrimary, textSecondary)
                      : _buildGeneratePrompt(isGenerating, textPrimary, textSecondary, accentColor),
                ),

                // Arrow or loading indicator
                if (isGenerating)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  )
                else
                  Icon(
                    existingWorkout != null ? Icons.chevron_right : Icons.add_circle_outline,
                    color: existingWorkout != null
                        ? textSecondary.withValues(alpha: 0.5)
                        : accentColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutInfo(Workout workout, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workout.name ?? 'Workout',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '${workout.durationMinutes ?? 45} min • ${workout.type?.toUpperCase() ?? 'STRENGTH'}',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratePrompt(bool isGenerating, Color textPrimary, Color textSecondary, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isGenerating ? 'Generating...' : 'Tap to Generate',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isGenerating ? textSecondary : accentColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isGenerating ? 'Creating your personalized workout' : 'AI will create your workout',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _generateWorkoutForDate(String scheduledDate) async {
    setState(() {
      _generatingDates.add(scheduledDate);
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final userId = await repository.getCurrentUserId();

      if (userId == null) {
        debugPrint('❌ [Upcoming] No user ID for generation');
        return;
      }

      debugPrint('🚀 [Upcoming] Generating workout for $scheduledDate');

      await for (final progress in repository.generateWorkoutStreaming(
        userId: userId,
        scheduledDate: scheduledDate,
      )) {
        debugPrint('🔄 [Upcoming] Progress: ${progress.status} - ${progress.message}');

        if (progress.status == WorkoutGenerationStatus.completed) {
          debugPrint('✅ [Upcoming] Workout generated for $scheduledDate');
          // Refresh workouts list
          ref.invalidate(workoutsProvider);
          ref.invalidate(todayWorkoutProvider);
          break;
        }

        if (progress.status == WorkoutGenerationStatus.error) {
          debugPrint('❌ [Upcoming] Generation failed: ${progress.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to generate workout: ${progress.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('❌ [Upcoming] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generatingDates.remove(scheduledDate);
        });
      }
    }
  }
}
