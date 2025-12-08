import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/expanded_exercise_card.dart';

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

          // Exercise List with inline set tables
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = exercises[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    print('🎯 [WorkoutDetail] Exercise tapped at index $index: ${exercise.name}');
                    context.push('/exercise-detail', extra: exercise);
                  },
                  child: ExpandedExerciseCard(
                    key: ValueKey(exercise.id ?? index),
                    exercise: exercise,
                    index: index,
                    workoutId: widget.workoutId,
                    onTap: () {
                      // Navigation is handled by parent GestureDetector
                      print('🎯 [Card] onTap called for: ${exercise.name}');
                      context.push('/exercise-detail', extra: exercise);
                    },
                    onSwap: () async {
                      final updatedWorkout = await showExerciseSwapSheet(
                        context,
                        ref,
                        workoutId: widget.workoutId,
                        exercise: exercise,
                      );
                      if (updatedWorkout != null) {
                        setState(() => _workout = updatedWorkout);
                      }
                    },
                  ),
                );
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

      // Action FABs: AI Chat + Play
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Chat button
          FloatingActionButton(
            heroTag: 'ai_chat',
            onPressed: () => context.push('/chat'),
            backgroundColor: AppColors.purple.withOpacity(0.9),
            foregroundColor: Colors.white,
            child: const Icon(Icons.auto_awesome, size: 24),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),
          const SizedBox(width: 16),
          // Play button
          FloatingActionButton(
            heroTag: 'start_workout',
            onPressed: () => context.push('/active-workout', extra: workout),
            backgroundColor: AppColors.cyan,
            foregroundColor: AppColors.pureBlack,
            child: const Icon(Icons.play_arrow_rounded, size: 32),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
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
// String Extension
// ─────────────────────────────────────────────────────────────────

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
