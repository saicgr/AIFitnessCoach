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

/// Shows the favorite workouts bottom sheet
Future<void> showFavoriteWorkoutsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final parentTheme = Theme.of(context);

  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return showGlassSheet<void>(
    context: context,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: const _FavoriteWorkoutsSheet(),
    ),
  ).whenComplete(() {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _FavoriteWorkoutsSheet extends ConsumerWidget {
  const _FavoriteWorkoutsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;

    final workoutsState = ref.watch(workoutsProvider);
    final allWorkouts = workoutsState.valueOrNull ?? [];
    final favorites = allWorkouts.where((w) => w.isFavorite == true).toList()
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.favorite, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorite Workouts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${favorites.length} saved workout${favorites.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: favorites.isEmpty
                ? _buildEmptyState(textSecondary)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      return _buildWorkoutCard(
                        context,
                        ref,
                        favorites[index],
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

  Widget _buildEmptyState(Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No favorite workouts yet',
              style: TextStyle(fontSize: 16, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the heart on any workout to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
    bool isDark,
    Color accentColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark
        ? AppColors.background.withValues(alpha: 0.5)
        : AppColorsLight.background;

    final dateStr = workout.scheduledDate ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final dayName = date != null ? DateFormat('EEE').format(date) : '—';
    final dayNum = date != null ? DateFormat('d').format(date) : '—';
    final duration = workout.durationMinutes ?? 45;
    final exerciseCount = workout.exercises.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticService.light();
            Navigator.of(context).pop();
            context.push('/workout/${workout.id}', extra: workout);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

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
                            Icons.favorite,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$duration min • $exerciseCount exercise${exerciseCount == 1 ? '' : 's'} • ${workout.type?.toUpperCase() ?? 'STRENGTH'}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
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
