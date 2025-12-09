import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import 'widgets/exercise_set_tracker.dart';

/// List-based workout screen similar to Strong app
class ListWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const ListWorkoutScreen({super.key, required this.workout});

  @override
  ConsumerState<ListWorkoutScreen> createState() => _ListWorkoutScreenState();
}

class _ListWorkoutScreenState extends ConsumerState<ListWorkoutScreen> {
  // Timer
  Timer? _workoutTimer;
  int _workoutSeconds = 0;

  // Unit preference
  bool _useKg = true;

  // Sets data for all exercises
  late Map<int, List<SetData>> _exerciseSets;

  // Previous session data (from API)
  Map<int, List<PreviousSetData>> _previousSets = {};

  // Loading state
  bool _isLoadingPrevious = true;

  @override
  void initState() {
    super.initState();
    _initializeExerciseSets();
    _startWorkoutTimer();
    _fetchPreviousSessionData();
  }

  void _initializeExerciseSets() {
    _exerciseSets = {};
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      final numSets = exercise.sets ?? 3;
      _exerciseSets[i] = List.generate(numSets, (setIndex) {
        return SetData(
          setNumber: setIndex + 1,
          weight: exercise.weight ?? 0,
          reps: exercise.reps ?? 10,
          isWarmup: false,
          isCompleted: false,
        );
      });
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _workoutSeconds++);
      }
    });
  }

  Future<void> _fetchPreviousSessionData() async {
    // TODO: Implement fetching from /api/v1/performance-db/logs
    // For now, simulate some previous data
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock previous data for demonstration
    final mockPrevious = <int, List<PreviousSetData>>{};
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      mockPrevious[i] = [
        PreviousSetData(setNumber: 1, weight: (exercise.weight ?? 20) * 0.5, reps: 15, isWarmup: true),
        PreviousSetData(setNumber: 2, weight: (exercise.weight ?? 20) * 0.75, reps: 10, isWarmup: true),
        PreviousSetData(setNumber: 1, weight: exercise.weight ?? 20, reps: 10),
        PreviousSetData(setNumber: 2, weight: (exercise.weight ?? 20) * 1.2, reps: 10),
        PreviousSetData(setNumber: 3, weight: (exercise.weight ?? 20) * 1.4, reps: 8),
      ];
    }

    if (mounted) {
      setState(() {
        _previousSets = mockPrevious;
        _isLoadingPrevious = false;
      });
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  void _toggleUnit() {
    setState(() {
      _useKg = !_useKg;
      // Convert all weights when toggling
      for (final exerciseSets in _exerciseSets.values) {
        for (final set in exerciseSets) {
          if (_useKg) {
            // Convert from lbs to kg
            set.weight = set.weight * 0.453592;
          } else {
            // Convert from kg to lbs
            set.weight = set.weight * 2.20462;
          }
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  void _onSetUpdated(int exerciseIndex, int setIndex, SetData updatedSet) {
    setState(() {
      _exerciseSets[exerciseIndex]![setIndex] = updatedSet;
    });
  }

  void _onSetCompleted(int exerciseIndex, int setIndex) {
    setState(() {
      final set = _exerciseSets[exerciseIndex]![setIndex];
      _exerciseSets[exerciseIndex]![setIndex] = set.copyWith(
        isCompleted: !set.isCompleted,
        completedAt: set.isCompleted ? null : DateTime.now(),
      );
    });
  }

  void _onAddSet(int exerciseIndex) {
    setState(() {
      final sets = _exerciseSets[exerciseIndex]!;
      final lastSet = sets.isNotEmpty ? sets.last : null;
      sets.add(SetData(
        setNumber: sets.where((s) => !s.isWarmup).length + 1,
        weight: lastSet?.weight ?? 0,
        reps: lastSet?.reps ?? 10,
        isWarmup: false,
        isCompleted: false,
      ));
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _finishWorkout() async {
    // Check if any sets are completed
    int totalCompletedSets = 0;
    int totalReps = 0;
    double totalVolumeKg = 0.0;
    for (final sets in _exerciseSets.values) {
      for (final set in sets.where((s) => s.isCompleted)) {
        totalCompletedSets++;
        totalReps += set.reps;
        final weightKg = _useKg ? set.weight : set.weight * 0.453592;
        totalVolumeKg += set.reps * weightKg;
      }
    }

    if (totalCompletedSets == 0) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.glassSurface,
          title: const Text('No Sets Completed', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'You haven\'t completed any sets. Are you sure you want to finish?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finish Anyway', style: TextStyle(color: AppColors.orange)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Save workout data and get workoutLogId for AI Coach feedback
    final workoutLogId = await _saveWorkoutData();

    // Build exercises performance data for AI Coach feedback
    final exercisesPerformance = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      final sets = _exerciseSets[i] ?? [];
      final completedSets = sets.where((s) => s.isCompleted).toList();
      if (completedSets.isNotEmpty) {
        final avgWeight = completedSets.fold<double>(
          0, (sum, s) => sum + (_useKg ? s.weight : s.weight * 0.453592),
        ) / completedSets.length;
        final exTotalReps = completedSets.fold<int>(0, (sum, s) => sum + s.reps);
        exercisesPerformance.add({
          'name': exercise.name,
          'sets': completedSets.length,
          'reps': exTotalReps,
          'weight_kg': avgWeight,
        });
      }
    }

    // Navigate to completion screen
    if (mounted) {
      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _workoutSeconds,
        'calories': 0, // List workout screen doesn't track calories
        // AI Coach feedback data
        'workoutLogId': workoutLogId,
        'exercisesPerformance': exercisesPerformance,
        'totalRestSeconds': 0, // List workout screen doesn't track rest
        'avgRestSeconds': 0.0,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
      });
    }
  }

  Future<String?> _saveWorkoutData() async {
    String? resultWorkoutLogId;
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (widget.workout.id != null && userId != null) {
        // Build sets JSON
        final allSets = <Map<String, dynamic>>[];
        for (int i = 0; i < widget.workout.exercises.length; i++) {
          final exercise = widget.workout.exercises[i];
          final sets = _exerciseSets[i] ?? [];
          for (final set in sets.where((s) => s.isCompleted)) {
            allSets.add({
              'exercise_index': i,
              'exercise_name': exercise.name,
              'set_number': set.setNumber,
              'reps': set.reps,
              'weight_kg': _useKg ? set.weight : set.weight * 0.453592,
              'is_warmup': set.isWarmup,
              'completed_at': set.completedAt?.toIso8601String(),
            });
          }
        }

        // Create workout log
        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: widget.workout.id!,
          userId: userId,
          setsJson: jsonEncode(allSets),
          totalTimeSeconds: _workoutSeconds,
        );

        // Log individual sets
        if (workoutLog != null) {
          resultWorkoutLogId = workoutLog['id'] as String;
          for (int i = 0; i < widget.workout.exercises.length; i++) {
            final exercise = widget.workout.exercises[i];
            final sets = _exerciseSets[i] ?? [];
            for (final set in sets.where((s) => s.isCompleted)) {
              await workoutRepo.logSetPerformance(
                workoutLogId: resultWorkoutLogId,
                userId: userId,
                exerciseId: exercise.exerciseId ?? exercise.libraryId ?? 'unknown',
                exerciseName: exercise.name,
                setNumber: set.setNumber,
                repsCompleted: set.reps,
                weightKg: _useKg ? set.weight : set.weight * 0.453592,
              );
            }
          }
        }

        // Mark workout complete
        await workoutRepo.completeWorkout(widget.workout.id!);
      }
    } catch (e) {
      debugPrint('Error saving workout: $e');
    }
    return resultWorkoutLogId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Top header with timer and controls
            _buildHeader(),

            // Scrollable exercise list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: widget.workout.exercises.length + 1, // +1 for add exercise button
                itemBuilder: (context, index) {
                  if (index == widget.workout.exercises.length) {
                    return _buildAddExerciseButton();
                  }
                  final exercise = widget.workout.exercises[index];
                  return ExerciseSetTracker(
                    exercise: exercise,
                    exerciseIndex: index,
                    sets: _exerciseSets[index] ?? [],
                    previousSets: _previousSets[index],
                    useKg: _useKg,
                    onToggleUnit: _toggleUnit,
                    onSetUpdated: (setIdx, updated) => _onSetUpdated(index, setIdx, updated),
                    onSetCompleted: (setIdx) => _onSetCompleted(index, setIdx),
                    onAddSet: () => _onAddSet(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          // Collapse/Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.expand_more, color: AppColors.textPrimary, size: 24),
            ),
          ),

          const SizedBox(width: 12),

          // Timer
          Text(
            _formatDuration(_workoutSeconds),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),

          const Spacer(),

          // History button
          GestureDetector(
            onTap: () {
              // TODO: Show workout history
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: AppColors.textSecondary, size: 24),
            ),
          ),

          const SizedBox(width: 12),

          // Finish button
          ElevatedButton(
            onPressed: _finishWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Finish',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Show exercise picker
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.cyan, size: 24),
            SizedBox(width: 8),
            Text(
              'Add Exercise',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
