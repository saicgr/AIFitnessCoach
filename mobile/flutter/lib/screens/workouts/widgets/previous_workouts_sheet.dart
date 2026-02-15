import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';

/// Shows the previous workouts bottom sheet
Future<void> showPreviousWorkoutsSheet(
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
      child: const _PreviousWorkoutsSheet(),
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _PreviousWorkoutsSheet extends ConsumerWidget {
  const _PreviousWorkoutsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;

    // Load workouts on-demand from the provider and filter for completed
    final workoutsState = ref.watch(workoutsProvider);
    final allWorkouts = workoutsState.valueOrNull ?? [];
    final completedWorkouts = allWorkouts.where((w) => w.isCompleted == true).toList();

    // Sort by scheduled date (most recent first)
    final sortedWorkouts = List<Workout>.from(completedWorkouts)
      ..sort((a, b) {
        final aDate = a.scheduledDate ?? '';
        final bDate = b.scheduledDate ?? '';
        return bDate.compareTo(aDate);
      });

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
                  Icons.history_rounded,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous Workouts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sortedWorkouts.length} completed workout${sortedWorkouts.length == 1 ? '' : 's'}',
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
            child: sortedWorkouts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No completed workouts yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete your first workout to see it here',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: sortedWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = sortedWorkouts[index];
                      return _buildWorkoutCard(
                        context,
                        workout,
                        isDark,
                        accentColor,
                        textPrimary,
                        textSecondary,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    Workout workout,
    bool isDark,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark
        ? AppColors.background.withValues(alpha: 0.5)
        : AppColorsLight.background;

    // Parse date
    final dateStr = workout.scheduledDate ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final dayName = date != null ? DateFormat('EEE').format(date) : '?';
    final dayNum = date != null ? DateFormat('d').format(date) : '?';

    // Calculate duration or use stored value
    final duration = workout.durationMinutes ?? 45;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.light();
            Navigator.of(context).pop();
            context.push('/workout/${workout.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date badge with checkmark
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Workout info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout.name ?? 'Workout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$duration min • ${workout.type?.toUpperCase() ?? 'STRENGTH'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right,
                  color: textSecondary.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
