import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/week_comparison_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../utils/tz.dart';
import '../../../widgets/glass_sheet.dart';
import '../components/exercise_detail_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card widget displaying exercise info in a list format
class ExerciseCard extends ConsumerWidget {
  final LibraryExercise exercise;

  const ExerciseCard({
    super.key,
    required this.exercise,
  });

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      case 'neck':
        return Icons.face;
      default:
        return Icons.fitness_center;
    }
  }

  void _showExerciseDetail(BuildContext context) {
    showGlassSheet(
      context: context,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = tc.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    // Compact metadata line — MUSCLE · DIFFICULTY · EQUIPMENT (signature-v2
    // `.nl-exrow .bx`). Only non-empty parts are joined so a sparse exercise
    // never shows dangling separators.
    final metaParts = <String>[
      if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty)
        exercise.muscleGroup!,
      if (exercise.difficulty != null && exercise.difficulty!.isNotEmpty)
        DifficultyUtils.getDisplayName(exercise.difficulty!),
      if (exercise.equipment.isNotEmpty) exercise.equipment.first,
    ];

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        // Dense list spacing with a hairline divider — reads as a compact row,
        // not a tall card. Inline favorite/add actions moved to the detail
        // sheet (its floating action bar) on tap.
        padding: const EdgeInsets.only(bottom: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail with image or icon fallback — 56×56, all corners rounded.
            Hero(
              tag: 'exercise-image-${exercise.name}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      purple.withOpacity(0.3),
                      cyan.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Exercise image or body part icon fallback
                    if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: exercise.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            _getBodyPartIcon(exercise.bodyPart),
                            size: 24,
                            color: purple.withOpacity(0.8),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            _getBodyPartIcon(exercise.bodyPart),
                            size: 24,
                            color: purple.withOpacity(0.8),
                          ),
                        ),
                      )
                    else
                      Icon(
                        _getBodyPartIcon(exercise.bodyPart),
                        size: 24,
                        color: purple.withOpacity(0.8),
                      ),
                    // Video play indicator
                    if (hasVideo)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: cyan,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 10,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info — title (+ NEW chip) over the muted metadata line.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // NEW badge for exercises new this week
                      Builder(
                        builder: (context) {
                          final isNew = ref.watch(isExerciseNewThisWeekProvider(exercise.name));
                          if (!isNew) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Tiny difficulty dot prefix (matches the v2 spec's
                        // colored `.dif` marker) when a difficulty is present.
                        if (exercise.difficulty != null &&
                            exercise.difficulty!.isNotEmpty) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DifficultyUtils.getColor(
                                  exercise.difficulty!),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            metaParts.join(' · ').toUpperCase(),
                            style: ZType.lbl(
                              10,
                              color: textMuted,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing chevron — full actions live in the detail sheet on tap.
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to select which workout to add the exercise to
class _AddToWorkoutSheet extends ConsumerStatefulWidget {
  final String exerciseName;

  const _AddToWorkoutSheet({
    required this.exerciseName,
  });

  @override
  ConsumerState<_AddToWorkoutSheet> createState() => _AddToWorkoutSheetState();
}

class _AddToWorkoutSheetState extends ConsumerState<_AddToWorkoutSheet> {
  bool _isAdding = false;
  String? _selectedWorkoutId;

  void _addToQueue() {
    HapticService.light();
    ref.read(exerciseQueueProvider.notifier).addToQueue(widget.exerciseName);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.playlist_add_check, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Added "${widget.exerciseName}" to queue'),
            ),
          ],
        ),
        backgroundColor: AppColors.cyan,
      ),
    );
  }

  Widget _buildQueueOption(
    BuildContext context, {
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(widget.exerciseName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isQueued ? null : _addToQueue,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQueued ? AppLocalizations.of(context).exerciseCardAlreadyInQueue : AppLocalizations.of(context).exerciseQueueAddToQueue,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isQueued
                            ? AppLocalizations.of(context).exerciseCardWillBeIncludedIn
                            : 'AI will include in your next generated workout',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isQueued)
                  Icon(Icons.check_circle, color: AppColors.cyan)
                else
                  Icon(Icons.chevron_right, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToWorkout(Workout workout) async {
    setState(() {
      _isAdding = true;
      _selectedWorkoutId = workout.id;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await workoutRepo.addExercise(
        workoutId: workout.id!,
        exerciseName: widget.exerciseName,
      );

      if (mounted) {
        Navigator.pop(context);
        if (updatedWorkout != null) {
          // Refresh workout list silently (no loading flash)
          await ref.read(workoutsProvider.notifier).silentRefresh();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${widget.exerciseName}" to ${workout.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).exerciseCardFailedToAddExercise),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final workoutsAsync = ref.watch(workoutsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.add_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).exerciseCardAddToWorkout,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exerciseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Add to Queue option
          _buildQueueOption(
            context,
            elevated: elevated,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Divider with label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: textMuted.withOpacity(0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    AppLocalizations.of(context).exerciseCardOrAddToWorkout,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: textMuted.withOpacity(0.2))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Workout list
          Flexible(
            child: workoutsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.success),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    AppLocalizations.of(context).exerciseCardFailedToLoadWorkouts,
                    style: TextStyle(color: textMuted),
                  ),
                ),
              ),
              data: (workouts) {
                // Filter to upcoming/today's incomplete workouts
                final today = Tz.localDate();
                final upcomingWorkouts = workouts.where((w) {
                  final date = w.scheduledDate?.split('T')[0] ?? '';
                  return !(w.isCompleted ?? false) && date.compareTo(today) >= 0;
                }).take(5).toList();

                if (upcomingWorkouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).exerciseCardNoUpcomingWorkouts,
                            style: TextStyle(color: textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).exerciseCardGenerateAWorkoutPlan,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: upcomingWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = upcomingWorkouts[index];
                    final isFirst = index == 0;
                    final isLoading = _isAdding && _selectedWorkoutId == workout.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _isAdding ? null : () => _addToWorkout(workout),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Workout icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isFirst ? AppColors.success : AppColors.cyan)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: isFirst ? AppColors.success : AppColors.cyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Workout info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              workout.name ?? AppLocalizations.of(context).navWorkout,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isFirst)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'NEXT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(workout.scheduledDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Loading or add icon
                                if (isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.success,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.add_circle,
                                    color: isFirst ? AppColors.success : AppColors.cyan,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No date';
    try {
      final date = DateTime.parse(dateStr);
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
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
