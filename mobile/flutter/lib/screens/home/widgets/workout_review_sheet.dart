import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/main_shell.dart';
import '../../workout/widgets/exercise_swap_sheet.dart';
import '../../workout/widgets/exercise_add_sheet.dart';
import 'components/components.dart';

/// Shows workout review sheet after regeneration
/// Returns the approved Workout or null if user goes back
Future<Workout?> showWorkoutReviewSheet(
  BuildContext context,
  WidgetRef ref,
  Workout generatedWorkout,
) async {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return await showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => _WorkoutReviewSheet(workout: generatedWorkout),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

class _WorkoutReviewSheet extends ConsumerStatefulWidget {
  final Workout workout;

  const _WorkoutReviewSheet({required this.workout});

  @override
  ConsumerState<_WorkoutReviewSheet> createState() =>
      _WorkoutReviewSheetState();
}

class _WorkoutReviewSheetState extends ConsumerState<_WorkoutReviewSheet> {
  late Workout _currentWorkout;
  bool _isSwapping = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  Future<void> _swapExercise(WorkoutExercise exercise) async {
    if (_currentWorkout.id == null) return;

    setState(() => _isSwapping = true);

    final updatedWorkout = await showExerciseSwapSheet(
      context,
      ref,
      workoutId: _currentWorkout.id!,
      exercise: exercise,
    );

    if (mounted) {
      setState(() => _isSwapping = false);
      if (updatedWorkout != null) {
        setState(() => _currentWorkout = updatedWorkout);
      }
    }
  }

  Future<void> _addExercise() async {
    if (_currentWorkout.id == null) return;

    setState(() => _isAdding = true);

    final updatedWorkout = await showExerciseAddSheet(
      context,
      ref,
      workoutId: _currentWorkout.id!,
      workoutType: _currentWorkout.type ?? 'strength',
      currentExerciseNames:
          _currentWorkout.exercises.map((e) => e.name).toList(),
    );

    if (mounted) {
      setState(() => _isAdding = false);
      if (updatedWorkout != null) {
        setState(() => _currentWorkout = updatedWorkout);
      }
    }
  }

  void _goBack() {
    Navigator.pop(context, null);
  }

  void _approvePlan() {
    Navigator.pop(context, _currentWorkout);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sheetColors;
    final exercises = _currentWorkout.exercises;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? colors.elevated.withOpacity(0.85)
                : colors.elevated.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colors),
                Divider(height: 1, color: colors.cardBorder),
                _buildWorkoutSummary(colors),
                Divider(height: 1, color: colors.cardBorder),
                Expanded(
                  child: _buildExerciseList(colors, exercises),
                ),
                _buildAddExerciseButton(colors),
                _buildBottomActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: colors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review Your Workout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _goBack,
                icon: Icon(Icons.close, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummary(SheetColors colors) {
    final typeColor = getWorkoutTypeColor(_currentWorkout.type ?? 'strength');
    final difficultyColor =
        getDifficultyColor(_currentWorkout.difficulty ?? 'medium');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout name
          Text(
            _currentWorkout.name ?? 'Your Workout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Badges and stats row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_currentWorkout.type ?? 'strength').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_currentWorkout.difficulty ?? 'medium').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: difficultyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Duration
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentWorkout.durationMinutes ?? 45}m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Exercise count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentWorkout.exerciseCount} exercises',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(SheetColors colors, List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No exercises yet',
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ReviewExerciseCard(
          exercise: exercise,
          index: index,
          colors: colors,
          isSwapping: _isSwapping,
          onSwap: () => _swapExercise(exercise),
        );
      },
    );
  }

  Widget _buildAddExerciseButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _isAdding ? null : _addExercise,
        icon: _isAdding
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.success,
                ),
              )
            : Icon(Icons.add, color: colors.success),
        label: Text(
          _isAdding ? 'Adding...' : 'Add Exercise',
          style: TextStyle(color: colors.success),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.success.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(SheetColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Approve Plan button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _approvePlan,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual exercise card for review
class _ReviewExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final SheetColors colors;
  final bool isSwapping;
  final VoidCallback onSwap;

  const _ReviewExerciseCard({
    required this.exercise,
    required this.index,
    required this.colors,
    required this.isSwapping,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final gifUrl = exercise.gifUrl ?? exercise.videoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          // Exercise thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: colors.textMuted.withOpacity(0.1),
              child: gifUrl != null && gifUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: gifUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: colors.textMuted,
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: colors.textMuted,
                          size: 24,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.fitness_center,
                        color: colors.textMuted,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Muscle group and equipment
                Row(
                  children: [
                    if (exercise.muscleGroup != null) ...[
                      Text(
                        exercise.muscleGroup!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (exercise.muscleGroup != null &&
                        exercise.equipment != null)
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    if (exercise.equipment != null)
                      Flexible(
                        child: Text(
                          exercise.equipment!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Sets, reps, rest
                Row(
                  children: [
                    _buildStatChip(
                      '${exercise.sets ?? 3} sets',
                      colors,
                    ),
                    const SizedBox(width: 6),
                    _buildStatChip(
                      '${exercise.reps ?? '10-12'} reps',
                      colors,
                    ),
                    const SizedBox(width: 6),
                    _buildStatChip(
                      '${exercise.restSeconds ?? 60}s',
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Swap button
          IconButton(
            onPressed: isSwapping ? null : onSwap,
            icon: isSwapping
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.cyan,
                    ),
                  )
                : Icon(
                    Icons.swap_horiz,
                    color: colors.cyan,
                    size: 24,
                  ),
            tooltip: 'Swap exercise',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, SheetColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.textMuted,
        ),
      ),
    );
  }
}
