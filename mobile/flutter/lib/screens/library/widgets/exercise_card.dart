import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/avoided_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/week_comparison_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'info_badge.dart';
import '../components/exercise_detail_sheet.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  void _showAddToWorkoutSheet(BuildContext context, WidgetRef ref) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => _AddToWorkoutSheet(
        exerciseName: exercise.name,
      ),
    );
  }

  void _toggleFavorite(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(favoritesProvider.notifier).toggleFavorite(exercise.name);
  }

  void _toggleQueue(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(exerciseQueueProvider.notifier).toggleQueue(
      exercise.name,
      targetMuscleGroup: exercise.muscleGroup,
    );
  }

  void _toggleAvoided(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(avoidedProvider.notifier).toggleAvoided(exercise.name);
  }

  void _toggleStaple(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(staplesProvider.notifier).toggleStaple(
      exercise.name,
      muscleGroup: exercise.muscleGroup,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    // Watch favorites, queue, avoided, and staples state
    final favoritesState = ref.watch(favoritesProvider);
    final queueState = ref.watch(exerciseQueueProvider);
    final avoidedState = ref.watch(avoidedProvider);
    final staplesState = ref.watch(staplesProvider);
    final isFavorite = favoritesState.isFavorite(exercise.name);
    final isQueued = queueState.isQueued(exercise.name);
    final isAvoided = avoidedState.isAvoided(exercise.name);
    final isStaple = staplesState.isStaple(exercise.name);

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail with image or icon fallback
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    purple.withOpacity(0.3),
                    cyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Exercise image or body part icon fallback
                  if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: exercise.imageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          _getBodyPartIcon(exercise.bodyPart),
                          size: 36,
                          color: purple.withOpacity(0.8),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          _getBodyPartIcon(exercise.bodyPart),
                          size: 36,
                          color: purple.withOpacity(0.8),
                        ),
                      ),
                    )
                  else
                    Icon(
                      _getBodyPartIcon(exercise.bodyPart),
                      size: 36,
                      color: purple.withOpacity(0.8),
                    ),
                  // Video play indicator
                  if (hasVideo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          InfoBadge(
                            icon: Icons.accessibility_new,
                            text: exercise.muscleGroup!,
                            color: purple,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.difficulty != null)
                          InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: DifficultyUtils.getDisplayName(exercise.difficulty!),
                            color: DifficultyUtils.getColor(exercise.difficulty!),
                          ),
                      ],
                    ),
                    if (exercise.equipment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.equipment.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite button
                GestureDetector(
                  onTap: () => _toggleFavorite(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? AppColors.error.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : textMuted,
                      size: 18,
                    ),
                  ),
                ),
                // Queue button
                GestureDetector(
                  onTap: () => _toggleQueue(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isQueued
                          ? AppColors.cyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                      color: isQueued ? AppColors.cyan : textMuted,
                      size: 18,
                    ),
                  ),
                ),
                // Avoid button
                GestureDetector(
                  onTap: () => _toggleAvoided(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isAvoided
                          ? AppColors.orange.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAvoided ? Icons.block : Icons.block_outlined,
                      color: isAvoided ? AppColors.orange : textMuted,
                      size: 18,
                    ),
                  ),
                ),
                // Staple/Pin button
                GestureDetector(
                  onTap: () => _toggleStaple(ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isStaple
                          ? purple.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isStaple ? purple : textMuted,
                      size: 18,
                    ),
                  ),
                ),
                // Add to workout button
                GestureDetector(
                  onTap: () => _showAddToWorkoutSheet(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(width: 8),
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
                        isQueued ? 'Already in Queue' : 'Add to Queue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isQueued
                            ? 'Will be included in next workout'
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
          // Refresh workout list and invalidate to force UI rebuild
          await ref.read(workoutsProvider.notifier).refresh();
          ref.invalidate(workoutsProvider);

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
            const SnackBar(
              content: Text('Failed to add exercise'),
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
                        'Add to Workout',
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
                    'OR ADD TO WORKOUT',
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
                    'Failed to load workouts',
                    style: TextStyle(color: textMuted),
                  ),
                ),
              ),
              data: (workouts) {
                // Filter to upcoming/today's incomplete workouts
                final today = DateTime.now().toIso8601String().split('T')[0];
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
                            'No upcoming workouts',
                            style: TextStyle(color: textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate a workout plan first',
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
                                              workout.name ?? 'Workout',
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
