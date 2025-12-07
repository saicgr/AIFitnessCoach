import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  Workout? _workout;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.getWorkout(widget.workoutId);
      setState(() {
        _workout = workout;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_error != null || _workout == null) {
      return Scaffold(
        backgroundColor: AppColors.pureBlack,
        appBar: AppBar(
          backgroundColor: AppColors.pureBlack,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadWorkout,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final workout = _workout!;
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');
    final exercises = workout.exercises;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.pureBlack,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, size: 20),
                ),
                onPressed: () => _showWorkoutActions(context, ref, workout),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      typeColor.withOpacity(0.3),
                      AppColors.pureBlack,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                workout.type?.toUpperCase() ?? 'STRENGTH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.glassSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (workout.difficulty ?? 'Medium').capitalize(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getDifficultyColor(
                                    workout.difficulty ?? 'medium',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          workout.name ?? 'Workout',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    value: '${workout.durationMinutes ?? 45}',
                    label: 'min',
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.fitness_center,
                    value: '${exercises.length}',
                    label: 'exercises',
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${workout.estimatedCalories}',
                    label: 'cal',
                    color: AppColors.orange,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          ),

          // Equipment Section
          if (workout.equipmentNeeded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EQUIPMENT NEEDED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: workout.equipmentNeeded.map((equipment) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.elevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                equipment,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),
            ),
          ],

          // Exercises Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'EXERCISES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Exercise List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = exercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  index: index,
                  workoutId: widget.workoutId,
                  onSwap: (updatedWorkout) {
                    setState(() => _workout = updatedWorkout);
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 50));
              },
              childCount: exercises.length,
            ),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Start Workout FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to active workout with workout data
          context.push('/active-workout', extra: workout);
        },
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.pureBlack,
        icon: const Icon(Icons.play_arrow),
        label: const Text(
          'Start Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _showWorkoutActions(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await showWorkoutActionsSheet(
      context,
      ref,
      workout,
      onRefresh: () {
        _loadWorkout();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
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

// ─────────────────────────────────────────────────────────────────
// Exercise Card
// ─────────────────────────────────────────────────────────────────

class _ExerciseCard extends ConsumerWidget {
  final WorkoutExercise exercise;
  final int index;
  final String workoutId;
  final Function(Workout) onSwap;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.workoutId,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // GIF/Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: exercise.gifUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cyan,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.fitness_center,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ExerciseInfoChip(
                              text: '${exercise.sets} sets',
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 8),
                            _ExerciseInfoChip(
                              text: exercise.reps != null
                                  ? '${exercise.reps} reps'
                                  : '${exercise.durationSeconds}s',
                              color: AppColors.purple,
                            ),
                            if (exercise.weight != null) ...[
                              const SizedBox(width: 8),
                              _ExerciseInfoChip(
                                text: '${exercise.weight} kg',
                                color: AppColors.orange,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Swap button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: AppColors.cyan,
                      ),
                    ),
                    onPressed: () async {
                      final updatedWorkout = await showExerciseSwapSheet(
                        context,
                        ref,
                        workoutId: workoutId,
                        exercise: exercise,
                      );
                      if (updatedWorkout != null) {
                        onSwap(updatedWorkout);
                      }
                    },
                    tooltip: 'Swap exercise',
                  ),

                  // Index badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rest time
            if (exercise.restSeconds != null && exercise.restSeconds! > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise.restSeconds}s rest between sets',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
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

class _ExerciseInfoChip extends StatelessWidget {
  final String text;
  final Color color;

  const _ExerciseInfoChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// String Extension
// ─────────────────────────────────────────────────────────────────

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
