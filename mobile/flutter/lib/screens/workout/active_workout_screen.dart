import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';

/// Log for a single set
class SetLog {
  final int reps;
  final double weight;
  final DateTime completedAt;

  SetLog({required this.reps, required this.weight, DateTime? completedAt})
      : completedAt = completedAt ?? DateTime.now();
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isPaused = false;
  bool _isComplete = false;
  bool _showInstructions = false;
  bool _showExerciseList = false;

  // Video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = true;
  String? _imageUrl;
  String? _videoUrl;
  bool _isLoadingMedia = true;

  // Timers
  Timer? _workoutTimer;
  Timer? _restTimer;
  int _workoutSeconds = 0;
  int _restSecondsRemaining = 0;

  // Tracking - now stores weight/reps per set
  final Map<int, List<SetLog>> _completedSets = {};
  int _totalCaloriesBurned = 0;

  // Inline input controllers for real-time weight/reps entry
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _useKg = true; // true = kg, false = lbs

  // Set tracking overlay
  bool _showSetOverlay = true; // Show by default

  // Mock previous session data (will be fetched from API)
  Map<int, List<Map<String, dynamic>>> _previousSets = {};

  // Dynamic sets count per exercise (can add more sets)
  final Map<int, int> _totalSetsPerExercise = {};

  // Exercise navigation in Set Tracker (independent of video/main view)
  int _viewingExerciseIndex = 0;

  // Mutable exercise list for reordering
  late List<WorkoutExercise> _exercises;

  // Drink intake tracking (in ml)
  int _totalDrinkIntakeMl = 0;

  // Rest interval tracking
  final List<Map<String, dynamic>> _restIntervals = [];
  DateTime? _lastSetCompletedAt;
  DateTime? _lastExerciseStartedAt;

  // Time tracking per exercise (start time -> total seconds)
  final Map<int, int> _exerciseTimeSeconds = {};
  DateTime? _currentExerciseStartTime;

  @override
  void initState() {
    super.initState();
    // Initialize mutable exercises list (for reordering)
    _exercises = List.from(widget.workout.exercises);
    // Initialize input controllers with default values from first exercise
    final firstExercise = _exercises[0];
    _repsController = TextEditingController(text: (firstExercise.reps ?? 10).toString());
    _weightController = TextEditingController(text: (firstExercise.weight ?? 0).toString());
    _startWorkoutTimer();
    // Initialize completed sets tracking and mock previous data
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      _totalSetsPerExercise[i] = exercise.sets ?? 3;
      // Mock previous session data - would come from API in real implementation
      final defaultWeight = exercise.weight ?? 20.0;
      _previousSets[i] = [
        {'set': 1, 'weight': defaultWeight * 0.9, 'reps': exercise.reps ?? 10},
        {'set': 2, 'weight': defaultWeight, 'reps': exercise.reps ?? 10},
        {'set': 3, 'weight': defaultWeight * 1.1, 'reps': (exercise.reps ?? 10) - 2},
      ];
    }
    // Fetch media for first exercise
    _fetchMediaForExercise(_exercises[0]);
    // Start exercise time tracking for first exercise
    _currentExerciseStartTime = DateTime.now();
    _lastExerciseStartedAt = DateTime.now();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _videoController?.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetchMediaForExercise(WorkoutExercise exercise) async {
    setState(() {
      _isLoadingMedia = true;
      _imageUrl = null;
      _videoUrl = null;
    });

    // Dispose previous video
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final exerciseName = exercise.name;
      debugPrint('🎥 Fetching media for: $exerciseName');

      // Fetch image first (faster)
      try {
        final imageResponse = await dio.get(
          '/exercise-images/${Uri.encodeComponent(exerciseName)}',
        );
        if (imageResponse.data?['url'] != null) {
          if (mounted) {
            setState(() {
              _imageUrl = imageResponse.data['url'];
              _isLoadingMedia = false;
            });
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch image: $e');
      }

      // Fetch video
      try {
        final videoResponse = await dio.get(
          '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
        );
        if (videoResponse.data?['url'] != null) {
          _videoUrl = videoResponse.data['url'];
          await _initializeVideo();
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch video: $e');
      }

      if (_imageUrl == null && _videoUrl == null && mounted) {
        setState(() => _isLoadingMedia = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching media: $e');
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _initializeVideo() async {
    if (_videoUrl == null) return;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));

    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);
      if (_isVideoPlaying) _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Video init error: $e');
    }
  }

  void _toggleVideoPlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      _isVideoPlaying = !_isVideoPlaying;
      if (_isVideoPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
    HapticFeedback.lightImpact();
  }

  /// Handle tap on video/screen background
  /// - If overlay is showing: hide it to show full video
  /// - If overlay is hidden: toggle video pause/play
  void _handleScreenTap() {
    if (_showSetOverlay) {
      // First tap: hide overlay to show full video
      setState(() => _showSetOverlay = false);
      HapticFeedback.lightImpact();
    } else {
      // Overlay is hidden, toggle video pause/play
      _toggleVideoPlayPause();
    }
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _workoutSeconds++;
          _totalCaloriesBurned = (_workoutSeconds / 60 * 6).round();
        });
      }
    });
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
        if (_restSecondsRemaining == 0) _endRest();
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _completeSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    final totalSets = exercise.sets ?? 3;

    // Get values from inline controllers
    final reps = int.tryParse(_repsController.text) ?? (exercise.reps ?? 10);
    var weight = double.tryParse(_weightController.text) ?? (exercise.weight ?? 0);

    // Convert lbs to kg for storage if using lbs
    if (!_useKg) {
      weight = weight * 0.453592; // lbs to kg
    }

    // Track rest interval since last set
    if (_lastSetCompletedAt != null) {
      final restSeconds = DateTime.now().difference(_lastSetCompletedAt!).inSeconds;
      _restIntervals.add({
        'exercise_id': exercise.exerciseId ?? exercise.libraryId,
        'exercise_name': exercise.name,
        'set_number': _currentSet,
        'rest_seconds': restSeconds,
        'rest_type': 'between_sets',
        'recorded_at': DateTime.now().toIso8601String(),
      });
    }

    // Log the set (always stored in kg)
    setState(() {
      _completedSets[_currentExerciseIndex]!.add(SetLog(reps: reps, weight: weight));
    });

    // Update last set completed time
    _lastSetCompletedAt = DateTime.now();

    HapticFeedback.mediumImpact();

    if (_currentSet < totalSets) {
      // Move to next set, keep the same weight/reps for convenience
      setState(() => _currentSet++);
      final restTime = exercise.restSeconds ?? 90;
      _startRestTimer(restTime);
    } else {
      // Exercise complete, move to next
      _moveToNextExercise();
    }
  }

  /// Update controllers when switching exercises
  void _updateControllersForExercise(WorkoutExercise exercise) {
    // Get last logged values or default from exercise
    final previousLogs = _completedSets[_currentExerciseIndex] ?? [];
    final defaultReps = exercise.reps ?? 10;
    final defaultWeight = exercise.weight ?? 0;

    final newReps = previousLogs.isNotEmpty ? previousLogs.last.reps : defaultReps;
    final newWeight = previousLogs.isNotEmpty ? previousLogs.last.weight : defaultWeight;

    _repsController.text = newReps.toString();
    _weightController.text = newWeight.toString();
  }

  void _moveToNextExercise() {
    // Track time spent on current exercise
    if (_currentExerciseStartTime != null) {
      final elapsed = DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
      _exerciseTimeSeconds[_currentExerciseIndex] =
          (_exerciseTimeSeconds[_currentExerciseIndex] ?? 0) + elapsed;
    }

    // Track rest interval between exercises
    if (_lastExerciseStartedAt != null) {
      final currentExercise = _exercises[_currentExerciseIndex];
      final restSeconds = DateTime.now().difference(_lastSetCompletedAt ?? _lastExerciseStartedAt!).inSeconds;
      _restIntervals.add({
        'exercise_id': currentExercise.exerciseId ?? currentExercise.libraryId,
        'exercise_name': currentExercise.name,
        'rest_seconds': restSeconds,
        'rest_type': 'between_exercises',
        'recorded_at': DateTime.now().toIso8601String(),
      });
    }

    if (_currentExerciseIndex < _exercises.length - 1) {
      final nextIndex = _currentExerciseIndex + 1;
      final nextExercise = _exercises[nextIndex];
      setState(() {
        _currentExerciseIndex = nextIndex;
        _viewingExerciseIndex = nextIndex; // Sync Set Tracker view
        _currentSet = 1;
        _isResting = false;
        _showInstructions = false;
      });
      // Update controllers with next exercise defaults
      _repsController.text = (nextExercise.reps ?? 10).toString();
      _weightController.text = (nextExercise.weight ?? 0).toString();
      _fetchMediaForExercise(nextExercise);

      // Reset exercise time tracking for next exercise
      _currentExerciseStartTime = DateTime.now();
      _lastExerciseStartedAt = DateTime.now();
      _lastSetCompletedAt = null; // Reset for new exercise

      HapticFeedback.heavyImpact();
    } else {
      _completeWorkout();
    }
  }

  void _skipExercise() => _moveToNextExercise();

  /// Skip a specific exercise (mark as skipped, remove from list)
  void _skipSpecificExercise(int index) {
    if (_exercises.length <= 1) return; // Can't skip the only exercise

    setState(() {
      // Adjust current exercise index if needed
      if (index < _currentExerciseIndex) {
        _currentExerciseIndex--;
      } else if (index == _currentExerciseIndex) {
        // If skipping current exercise, stay at same index (next one slides in)
        // Or move to previous if we're at the end
        if (_currentExerciseIndex >= _exercises.length - 1) {
          _currentExerciseIndex = _exercises.length - 2;
        }
      }

      // Update viewing index
      if (index <= _viewingExerciseIndex && _viewingExerciseIndex > 0) {
        _viewingExerciseIndex--;
      }

      _exercises.removeAt(index);
    });

    // Update media if we skipped current exercise
    if (_currentExerciseIndex >= 0 && _currentExerciseIndex < _exercises.length) {
      _fetchMediaForExercise(_exercises[_currentExerciseIndex]);
    }

    HapticFeedback.mediumImpact();
  }

  /// Reorder exercises in the list
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);

      // Reorder the completed sets tracking to match
      final tempCompletedSets = Map<int, List<SetLog>>.from(_completedSets);
      final tempTotalSets = Map<int, int>.from(_totalSetsPerExercise);
      final tempPreviousSets = Map<int, List<Map<String, dynamic>>>.from(_previousSets);

      _completedSets.clear();
      _totalSetsPerExercise.clear();
      _previousSets.clear();

      for (int i = 0; i < _exercises.length; i++) {
        // Find original index
        int originalIndex = i;
        if (i == newIndex) {
          originalIndex = oldIndex;
        } else if (oldIndex < newIndex && i >= oldIndex && i < newIndex) {
          originalIndex = i + 1;
        } else if (oldIndex > newIndex && i > newIndex && i <= oldIndex) {
          originalIndex = i - 1;
        }

        _completedSets[i] = tempCompletedSets[originalIndex] ?? [];
        _totalSetsPerExercise[i] = tempTotalSets[originalIndex] ?? 3;
        _previousSets[i] = tempPreviousSets[originalIndex] ?? [];
      }

      // Adjust current exercise index
      if (_currentExerciseIndex == oldIndex) {
        _currentExerciseIndex = newIndex;
      } else if (oldIndex < _currentExerciseIndex && newIndex >= _currentExerciseIndex) {
        _currentExerciseIndex--;
      } else if (oldIndex > _currentExerciseIndex && newIndex <= _currentExerciseIndex) {
        _currentExerciseIndex++;
      }

      // Adjust viewing index similarly
      if (_viewingExerciseIndex == oldIndex) {
        _viewingExerciseIndex = newIndex;
      } else if (oldIndex < _viewingExerciseIndex && newIndex >= _viewingExerciseIndex) {
        _viewingExerciseIndex--;
      } else if (oldIndex > _viewingExerciseIndex && newIndex <= _viewingExerciseIndex) {
        _viewingExerciseIndex++;
      }
    });

    HapticFeedback.mediumImpact();
  }

  /// Make a specific exercise active (allow out-of-order completion)
  void _makeExerciseActive(int index) {
    if (index == _currentExerciseIndex) return;

    final exercise = _exercises[index];
    final completedSetsCount = _completedSets[index]?.length ?? 0;

    setState(() {
      _currentExerciseIndex = index;
      _viewingExerciseIndex = index;
      _currentSet = completedSetsCount + 1;
      _isResting = false;
      _showInstructions = false;
    });

    // Update controllers with exercise defaults
    _repsController.text = (exercise.reps ?? 10).toString();
    _weightController.text = (exercise.weight ?? 0).toString();

    _fetchMediaForExercise(exercise);
    HapticFeedback.mediumImpact();
  }

  /// Show exercise options menu (replace/skip)
  void _showExerciseOptionsMenu(BuildContext ctx, int index) {
    final exercise = _exercises[index];

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Exercise name
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Start this exercise (make active)
            _ExerciseOptionTile(
              icon: Icons.play_circle_outline,
              title: 'Start This Exercise',
              subtitle: 'Make this the active exercise',
              color: AppColors.cyan,
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(ctx); // Close the exercise list too
                _makeExerciseActive(index);
              },
            ),

            const SizedBox(height: 12),

            // Replace with similar
            _ExerciseOptionTile(
              icon: Icons.swap_horiz,
              title: 'Replace Exercise',
              subtitle: 'Choose a similar exercise',
              color: AppColors.purple,
              onTap: () {
                Navigator.pop(context);
                _showReplaceExerciseDialog(ctx, index);
              },
            ),

            const SizedBox(height: 12),

            // Skip this exercise
            _ExerciseOptionTile(
              icon: Icons.skip_next,
              title: 'Skip Exercise',
              subtitle: 'Remove from this workout',
              color: AppColors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(ctx); // Close the exercise list too
                _skipSpecificExercise(index);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Show dialog to replace exercise with similar one
  void _showReplaceExerciseDialog(BuildContext ctx, int index) {
    final exercise = _exercises[index];
    final muscleGroup = exercise.muscleGroup ?? exercise.bodyPart ?? 'Unknown';

    // Mock similar exercises - in real implementation, would fetch from API
    final similarExercises = [
      '${muscleGroup} Alternative 1',
      '${muscleGroup} Alternative 2',
      '${muscleGroup} Alternative 3',
      'Dumbbell ${exercise.name}',
      'Cable ${exercise.name}',
    ];

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text(
          'Replace Exercise',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Similar exercises for ${exercise.name}:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...similarExercises.map((name) => ListTile(
                    dense: true,
                    title: Text(
                      name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.cyan),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(ctx); // Close the exercise list
                      _replaceExercise(index, name);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Replace exercise at index with a new exercise
  void _replaceExercise(int index, String newExerciseName) {
    final oldExercise = _exercises[index];

    setState(() {
      // Create new exercise with same structure but different name
      _exercises[index] = oldExercise.copyWith(nameValue: newExerciseName);

      // Reset completed sets for this exercise
      _completedSets[index] = [];
    });

    // If this was the current exercise, reload media
    if (index == _currentExerciseIndex) {
      _fetchMediaForExercise(_exercises[index]);
    }

    HapticFeedback.mediumImpact();
  }

  Future<void> _completeWorkout() async {
    _workoutTimer?.cancel();
    _restTimer?.cancel();

    // Record final exercise time
    if (_currentExerciseStartTime != null) {
      final elapsed = DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
      _exerciseTimeSeconds[_currentExerciseIndex] =
          (_exerciseTimeSeconds[_currentExerciseIndex] ?? 0) + elapsed;
    }

    setState(() => _isComplete = true);

    // Variables to pass to workout complete screen for AI Coach feedback
    String? workoutLogId;
    int totalCompletedSets = 0;
    int totalReps = 0;
    double totalVolumeKg = 0.0;
    int totalRestSeconds = 0;
    double avgRestSeconds = 0.0;

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (widget.workout.id != null && userId != null) {
        // 1. Create workout log with all sets and comprehensive metadata
        debugPrint('🏋️ Saving workout log to backend...');
        final setsJson = _buildSetsJson();
        final metadata = _buildWorkoutMetadata();

        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: widget.workout.id!,
          userId: userId,
          setsJson: setsJson,
          totalTimeSeconds: _workoutSeconds,
          metadata: jsonEncode(metadata),
        );

        // 2. Log individual set performances
        if (workoutLog != null) {
          debugPrint('✅ Workout log created: ${workoutLog['id']}');
          workoutLogId = workoutLog['id'] as String;
          await _logAllSetPerformances(workoutLogId, userId);

          // 3. Log rest intervals to backend
          await _logAllRestIntervals(workoutLogId, userId);
        } else {
          debugPrint('⚠️ Failed to create workout log, skipping performance logs');
        }

        // 4. Log drink intake if any
        if (_totalDrinkIntakeMl > 0) {
          await workoutRepo.logDrinkIntake(
            workoutId: widget.workout.id!,
            userId: userId,
            amountMl: _totalDrinkIntakeMl,
            drinkType: 'water',
          );
          debugPrint('💧 Logged drink intake: ${_totalDrinkIntakeMl}ml');
        }

        // 5. Log workout exit as "completed"
        totalCompletedSets = _completedSets.values.fold<int>(
          0, (sum, list) => sum + list.length,
        );
        final exercisesWithSets = _completedSets.values.where((l) => l.isNotEmpty).length;

        // Calculate total reps and volume for AI Coach feedback
        for (final sets in _completedSets.values) {
          for (final setLog in sets) {
            totalReps += setLog.reps;
            totalVolumeKg += setLog.reps * setLog.weight;
          }
        }

        // Calculate rest time stats
        if (_restIntervals.isNotEmpty) {
          for (final interval in _restIntervals) {
            totalRestSeconds += (interval['rest_seconds'] as int?) ?? 0;
          }
          avgRestSeconds = totalRestSeconds / _restIntervals.length;
        }

        await workoutRepo.logWorkoutExit(
          workoutId: widget.workout.id!,
          userId: userId,
          exitReason: 'completed',
          exercisesCompleted: exercisesWithSets,
          totalExercises: _exercises.length,
          setsCompleted: totalCompletedSets,
          timeSpentSeconds: _workoutSeconds,
          progressPercentage: _exercises.isNotEmpty
              ? (exercisesWithSets / _exercises.length * 100)
              : 100.0,
        );
        debugPrint('✅ Workout exit logged as completed');

        // 6. Mark workout as complete in workouts table
        await workoutRepo.completeWorkout(widget.workout.id!);
        debugPrint('✅ Workout marked as complete');
      }
    } catch (e) {
      debugPrint('❌ Failed to complete workout: $e');
    }

    // Build exercises performance data for AI Coach feedback
    final exercisesPerformance = <Map<String, dynamic>>[];
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final sets = _completedSets[i] ?? [];
      if (sets.isNotEmpty) {
        // Calculate average weight for this exercise
        final avgWeight = sets.fold<double>(0, (sum, s) => sum + s.weight) / sets.length;
        final totalExReps = sets.fold<int>(0, (sum, s) => sum + s.reps);
        exercisesPerformance.add({
          'name': exercise.name,
          'sets': sets.length,
          'reps': totalExReps,
          'weight_kg': avgWeight,
        });
      }
    }

    if (mounted) {
      // Log what we're passing to workout complete screen
      debugPrint('🏋️ [Complete] Navigating to workout-complete with:');
      debugPrint('🏋️ [Complete] workoutLogId: $workoutLogId');
      debugPrint('🏋️ [Complete] workoutId: ${widget.workout.id}');
      debugPrint('🏋️ [Complete] exercisesPerformance: ${exercisesPerformance.length} exercises');
      debugPrint('🏋️ [Complete] totalSets: $totalCompletedSets, totalReps: $totalReps, totalVolumeKg: $totalVolumeKg');

      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _workoutSeconds,
        'calories': _totalCaloriesBurned,
        'drinkIntakeMl': _totalDrinkIntakeMl,
        'restIntervals': _restIntervals.length,
        // AI Coach feedback data
        'workoutLogId': workoutLogId,
        'exercisesPerformance': exercisesPerformance,
        'totalRestSeconds': totalRestSeconds,
        'avgRestSeconds': avgRestSeconds,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
      });
    }
  }

  /// Log all rest intervals to backend
  Future<void> _logAllRestIntervals(String workoutLogId, String userId) async {
    if (_restIntervals.isEmpty) return;

    final workoutRepo = ref.read(workoutRepositoryProvider);

    for (final interval in _restIntervals) {
      try {
        await workoutRepo.logRestInterval(
          workoutLogId: workoutLogId,
          userId: userId,
          restSeconds: interval['rest_seconds'] as int? ?? 0,
          exerciseId: interval['exercise_id'] as String?,
          setNumber: interval['set_number'] as int?,
          restType: interval['rest_type'] as String? ?? 'between_sets',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to log rest interval: $e');
      }
    }

    debugPrint('⏱️ Logged ${_restIntervals.length} rest intervals');
  }

  /// Build comprehensive JSON string with all workout data
  String _buildSetsJson() {
    final List<Map<String, dynamic>> allSets = [];

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final sets = _completedSets[i] ?? [];

      for (int j = 0; j < sets.length; j++) {
        allSets.add({
          'exercise_index': i,
          'exercise_id': exercise.exerciseId ?? exercise.libraryId,
          'exercise_name': exercise.name,
          'set_number': j + 1,
          'reps': sets[j].reps,
          'weight_kg': sets[j].weight,
          'completed_at': sets[j].completedAt.toIso8601String(),
        });
      }
    }

    return jsonEncode(allSets);
  }

  /// Build comprehensive workout metadata JSON
  Map<String, dynamic> _buildWorkoutMetadata() {
    // Calculate exercise order (may have been reordered)
    final exerciseOrder = _exercises.asMap().entries.map((e) => {
      'index': e.key,
      'exercise_id': e.value.exerciseId ?? e.value.libraryId,
      'exercise_name': e.value.name,
      'time_spent_seconds': _exerciseTimeSeconds[e.key] ?? 0,
    }).toList();

    return {
      'exercise_order': exerciseOrder,
      'rest_intervals': _restIntervals,
      'drink_intake_ml': _totalDrinkIntakeMl,
      'exercise_time_tracking': _exerciseTimeSeconds.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'total_sets_per_exercise': _totalSetsPerExercise.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  /// Log all individual set performances to backend
  Future<void> _logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final sets = _completedSets[i] ?? [];

      for (int j = 0; j < sets.length; j++) {
        await workoutRepo.logSetPerformance(
          workoutLogId: workoutLogId,
          userId: userId,
          exerciseId: exercise.exerciseId ?? exercise.libraryId ?? 'unknown',
          exerciseName: exercise.name,
          setNumber: j + 1,
          repsCompleted: sets[j].reps,
          weightKg: sets[j].weight,
        );
      }
    }

    debugPrint('✅ Logged ${_completedSets.values.fold<int>(0, (sum, list) => sum + list.length)} sets to backend');
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    HapticFeedback.selectionClick();
  }

  void _showQuitDialog() {
    // Calculate progress stats
    int totalCompletedSets = 0;
    int exercisesWithCompletedSets = 0;
    for (int i = 0; i < _exercises.length; i++) {
      final sets = _completedSets[i] ?? [];
      if (sets.isNotEmpty) {
        totalCompletedSets += sets.length;
        exercisesWithCompletedSets++;
      }
    }
    final progressPercent = _exercises.isNotEmpty
        ? (exercisesWithCompletedSets / _exercises.length * 100).round()
        : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          String? selectedReason;
          final TextEditingController notesController = TextEditingController();

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title with progress
                Row(
                  children: [
                    const Icon(Icons.exit_to_app, color: AppColors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Workout Early?',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$progressPercent% complete • $totalCompletedSets sets done',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressPercent >= 50 ? AppColors.cyan : AppColors.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Question
                const Text(
                  'Why are you ending early?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Quick reply reasons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReasonChip('too_tired', 'Too tired', Icons.battery_1_bar, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('out_of_time', 'Out of time', Icons.timer_off, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('not_feeling_well', 'Not feeling well', Icons.sick, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('equipment_unavailable', 'Equipment busy', Icons.fitness_center, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('injury', 'Pain/Injury', Icons.healing, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('other', 'Other reason', Icons.more_horiz, selectedReason, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Optional notes
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)...',
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
                    filled: true,
                    fillColor: AppColors.elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Keep Going',
                          style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedReason == null ? null : () async {
                          Navigator.pop(ctx);
                          await _logWorkoutExitAndQuit(
                            selectedReason!,
                            notesController.text.isEmpty ? null : notesController.text,
                            exercisesWithCompletedSets,
                            totalCompletedSets,
                            progressPercent.toDouble(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedReason == null
                              ? AppColors.elevated
                              : AppColors.orange,
                          foregroundColor: selectedReason == null
                              ? AppColors.textMuted
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'End Workout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReasonChip(
    String value,
    String label,
    IconData icon,
    String? selectedReason,
    Function(String) onSelected,
  ) {
    final isSelected = selectedReason == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange.withOpacity(0.2) : AppColors.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.orange : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.orange : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logWorkoutExitAndQuit(
    String exitReason,
    String? exitNotes,
    int exercisesCompleted,
    int setsCompleted,
    double progressPercentage,
  ) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (widget.workout.id != null && userId != null) {
        // Log the workout exit
        await workoutRepo.logWorkoutExit(
          workoutId: widget.workout.id!,
          userId: userId,
          exitReason: exitReason,
          exitNotes: exitNotes,
          exercisesCompleted: exercisesCompleted,
          totalExercises: _exercises.length,
          setsCompleted: setsCompleted,
          timeSpentSeconds: _workoutSeconds,
          progressPercentage: progressPercentage,
        );

        // Also save any completed sets before quitting
        if (setsCompleted > 0) {
          await _savePartialWorkoutData(userId);
        }

        debugPrint('✅ [Workout] Exit logged: $exitReason ($progressPercentage%)');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to log workout exit: $e');
    }

    // Cancel timers and navigate home
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    if (mounted) {
      context.go('/home');
    }
  }

  void _showDrinkIntakeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          int selectedAmount = 250; // Default 250ml
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Water Intake',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${(_totalDrinkIntakeMl / 1000).toStringAsFixed(2)}L',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick amount buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildDrinkAmountChip(100, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                    _buildDrinkAmountChip(150, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                    _buildDrinkAmountChip(200, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                    _buildDrinkAmountChip(250, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                    _buildDrinkAmountChip(300, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                    _buildDrinkAmountChip(500, selectedAmount, (amount) {
                      setModalState(() => selectedAmount = amount);
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // Log button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logDrinkIntake(selectedAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log ${selectedAmount}ml',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrinkAmountChip(int amount, int selected, Function(int) onTap) {
    final isSelected = amount == selected;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(amount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          '${amount}ml',
          style: TextStyle(
            color: isSelected ? Colors.blue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _logDrinkIntake(int amountMl) {
    setState(() {
      _totalDrinkIntakeMl += amountMl;
    });
    HapticFeedback.mediumImpact();

    // Show brief confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('+${amountMl}ml logged'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _savePartialWorkoutData(String userId) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);

      // Build sets JSON for partial workout
      final List<Map<String, dynamic>> allSets = [];
      for (int i = 0; i < _exercises.length; i++) {
        final exercise = _exercises[i];
        final sets = _completedSets[i] ?? [];
        for (int j = 0; j < sets.length; j++) {
          allSets.add({
            'exercise_index': i,
            'exercise_name': exercise.name,
            'set_number': j + 1,
            'reps': sets[j].reps,
            'weight_kg': _useKg ? sets[j].weight : sets[j].weight * 0.453592,
            'completed_at': sets[j].completedAt.toIso8601String(),
          });
        }
      }

      if (allSets.isNotEmpty && widget.workout.id != null) {
        // Create partial workout log
        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: widget.workout.id!,
          userId: userId,
          setsJson: jsonEncode(allSets),
          totalTimeSeconds: _workoutSeconds,
        );

        // Log individual set performances
        if (workoutLog != null) {
          final workoutLogId = workoutLog['id'] as String;
          for (int i = 0; i < _exercises.length; i++) {
            final exercise = _exercises[i];
            final sets = _completedSets[i] ?? [];
            for (int j = 0; j < sets.length; j++) {
              await workoutRepo.logSetPerformance(
                workoutLogId: workoutLogId,
                userId: userId,
                exerciseId: exercise.exerciseId ?? exercise.libraryId ?? 'unknown',
                exerciseName: exercise.name,
                setNumber: j + 1,
                repsCompleted: sets[j].reps,
                weightKg: _useKg ? sets[j].weight : sets[j].weight * 0.453592,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to save partial workout data: $e');
    }
  }

  void _showExerciseListDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title with instructions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: AppColors.cyan),
                      const SizedBox(width: 12),
                      Text(
                        'All Exercises (${_exercises.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.textMuted.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to start • Long press to reorder • ⋮ for options',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: AppColors.cardBorder.withOpacity(0.3), height: 1),
                // Reorderable exercise list
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      _reorderExercises(oldIndex, newIndex);
                      setModalState(() {}); // Update the modal UI
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      final hasCompletedSets = (_completedSets[index]?.length ?? 0) > 0;
                      final isCurrent = index == _currentExerciseIndex;
                      final completedSetsCount = _completedSets[index]?.length ?? 0;
                      final totalSets = _totalSetsPerExercise[index] ?? exercise.sets ?? 3;

                      return Container(
                        key: ValueKey('exercise_$index'),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _makeExerciseActive(index);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.cyan.withOpacity(0.1)
                                    : AppColors.elevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.cyan.withOpacity(0.5)
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Drag handle
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: AppColors.textMuted.withOpacity(0.5),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Index/status circle
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: hasCompletedSets
                                          ? AppColors.success
                                          : isCurrent
                                              ? AppColors.cyan
                                              : AppColors.glassSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: hasCompletedSets
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrent
                                                    ? AppColors.pureBlack
                                                    : AppColors.textMuted,
                                              ),
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$totalSets sets × ${exercise.reps ?? 10} reps',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Progress badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.cyan.withOpacity(0.2)
                                          : hasCompletedSets
                                              ? AppColors.success.withOpacity(0.2)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isCurrent
                                          ? 'Active'
                                          : hasCompletedSets
                                              ? '$completedSetsCount/$totalSets'
                                              : '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? AppColors.cyan
                                            : AppColors.success,
                                      ),
                                    ),
                                  ),
                                  // Options button
                                  IconButton(
                                    onPressed: () => _showExerciseOptionsMenu(ctx, index),
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = _exercises[_currentExerciseIndex];
    final nextExercise = _currentExerciseIndex < _exercises.length - 1
        ? _exercises[_currentExerciseIndex + 1]
        : null;
    final progress = (_currentExerciseIndex + 1) / _exercises.length;

    return WillPopScope(
      onWillPop: () async {
        _showQuitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: Stack(
          children: [
            // Full-screen video/image background - tap to hide overlay or pause video
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleScreenTap,
                child: _buildMediaBackground(),
              ),
            ),

            // Gradient overlay for readability
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.pureBlack.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        AppColors.pureBlack.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.25, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Video pause indicator
            if (!_isVideoPlaying && _isVideoInitialized)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 64,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
              ),

            // Top stats overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildTopOverlay(currentExercise, progress),
              ),
            ),

            // Rest timer overlay
            if (_isResting)
              Positioned.fill(
                child: _buildRestOverlay(),
              ),

            // Set tracking table overlay (in middle of screen)
            if (_showSetOverlay && !_isResting)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 150, // Below top overlay
                child: _buildSetTrackingOverlay(),
              ),

            // Bottom section: next exercise + collapsible instructions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSection(currentExercise, nextExercise),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBackground() {
    // Video if available - use LayoutBuilder for proper cover scaling
    if (_isVideoInitialized && _videoController != null) {
      final videoSize = _videoController!.value.size;
      if (videoSize.width > 0 && videoSize.height > 0) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final screenAspect = screenWidth / screenHeight;
            final videoAspect = videoSize.width / videoSize.height;

            // Calculate scale to cover the screen
            final scale = videoAspect > screenAspect
                ? screenHeight / videoSize.height
                : screenWidth / videoSize.width;

            return ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: videoSize.width,
                    height: videoSize.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            );
          },
        );
      }
    }

    // Image fallback
    if (_imageUrl != null) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => Container(color: AppColors.elevated),
          errorWidget: (_, __, ___) => _buildPlaceholderBackground(),
        ),
      );
    }

    // Loading or error
    if (_isLoadingMedia) {
      return Container(
        color: AppColors.elevated,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    return _buildPlaceholderBackground();
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: AppColors.elevated,
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          size: 80,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildTopOverlay(WorkoutExercise exercise, double progress) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row: Close, title, pause
          Row(
            children: [
              _GlassButton(
                icon: Icons.close,
                onTap: _showQuitDialog,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _GlassButton(
                icon: Icons.list_alt,
                onTap: _showExerciseListDrawer,
              ),
              const SizedBox(width: 8),
              _GlassButton(
                icon: _showSetOverlay ? Icons.table_chart : Icons.table_chart_outlined,
                onTap: () => setState(() => _showSetOverlay = !_showSetOverlay),
                isHighlighted: _showSetOverlay,
              ),
              const SizedBox(width: 8),
              _GlassButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                onTap: _togglePause,
                isHighlighted: _isPaused,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
              minHeight: 4,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.012),

          // Stats row: Timer | Calories | Set | Water (responsive sizing)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Scale factor: 1.0 for 400px width, scales proportionally
              final scaleFactor = (screenWidth / 400).clamp(0.75, 1.3);
              final spacing = (6 * scaleFactor).clamp(4.0, 10.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: _StatChip(
                      icon: Icons.timer_outlined,
                      value: _formatTime(_workoutSeconds),
                      color: _isPaused ? AppColors.textMuted : AppColors.cyan,
                      label: _isPaused ? 'PAUSED' : null,
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Flexible(
                    child: _StatChip(
                      icon: Icons.local_fire_department,
                      value: '$_totalCaloriesBurned',
                      suffix: 'cal',
                      color: AppColors.orange,
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Flexible(
                    child: _StatChip(
                      icon: Icons.repeat,
                      value: '$_currentSet/${exercise.sets ?? 3}',
                      suffix: 'set',
                      color: AppColors.purple,
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Flexible(
                    child: GestureDetector(
                      onTap: _showDrinkIntakeDialog,
                      child: _StatChip(
                        icon: Icons.water_drop_outlined,
                        value: '${(_totalDrinkIntakeMl / 1000).toStringAsFixed(1)}',
                        suffix: 'L',
                        color: Colors.blue,
                        scaleFactor: scaleFactor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRestOverlay() {
    return Container(
      color: AppColors.pureBlack.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'REST',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_restSecondsRemaining}s',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _endRest,
              icon: const Icon(Icons.skip_next, color: AppColors.purple),
              label: const Text('Skip Rest', style: TextStyle(color: AppColors.purple)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  /// Build the set tracking table overlay (Strong app style on top of video)
  Widget _buildSetTrackingOverlay() {
    final viewingExercise = _exercises[_viewingExerciseIndex];
    final totalSets = _totalSetsPerExercise[_viewingExerciseIndex] ?? viewingExercise.sets ?? 3;
    final completedSetsForExercise = _completedSets[_viewingExerciseIndex] ?? [];
    final previousSetsForExercise = _previousSets[_viewingExerciseIndex] ?? [];
    final isViewingCurrent = _viewingExerciseIndex == _currentExerciseIndex;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with exercise navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.elevated.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Previous exercise button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _viewingExerciseIndex > 0
                      ? () {
                          setState(() => _viewingExerciseIndex--);
                          HapticFeedback.selectionClick();
                        }
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _viewingExerciseIndex > 0
                          ? AppColors.cyan.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: _viewingExerciseIndex > 0
                          ? AppColors.cyan
                          : AppColors.textMuted.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Exercise name and position
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        viewingExercise.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isViewingCurrent ? AppColors.cyan : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_viewingExerciseIndex + 1}/${_exercises.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (!isViewingCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _viewingExerciseIndex < _currentExerciseIndex ? 'PAST' : 'UPCOMING',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Next exercise button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _viewingExerciseIndex < _exercises.length - 1
                      ? () {
                          setState(() => _viewingExerciseIndex++);
                          HapticFeedback.selectionClick();
                        }
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _viewingExerciseIndex < _exercises.length - 1
                          ? AppColors.cyan.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: _viewingExerciseIndex < _exercises.length - 1
                          ? AppColors.cyan
                          : AppColors.textMuted.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Unit toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final currentVal = double.tryParse(_weightController.text) ?? 0;
                      if (_useKg) {
                        final lbsVal = currentVal * 2.20462;
                        _weightController.text = lbsVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                      } else {
                        final kgVal = currentVal * 0.453592;
                        _weightController.text = kgVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                      }
                      _useKg = !_useKg;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _useKg ? 'KG' : 'LBS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Collapse button
                GestureDetector(
                  onTap: () => setState(() => _showSetOverlay = false),
                  child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.elevated.withOpacity(0.3),
            ),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('SET', style: _overlayHeaderStyle)),
                Expanded(flex: 2, child: Text('PREVIOUS', style: _overlayHeaderStyle)),
                Expanded(flex: 2, child: Text(_useKg ? 'KG' : 'LBS', style: _overlayHeaderStyle)),
                Expanded(flex: 2, child: Text('REPS', style: _overlayHeaderStyle)),
                SizedBox(width: 44),
              ],
            ),
          ),

          // Set rows
          ...List.generate(totalSets, (index) {
            final isCompleted = index < completedSetsForExercise.length;
            // Only show current set indicator if viewing the current exercise
            final isCurrent = isViewingCurrent && index == completedSetsForExercise.length;
            final previousSet = index < previousSetsForExercise.length
                ? previousSetsForExercise[index]
                : null;

            // Get completed set data if available
            SetLog? completedSetData;
            if (isCompleted) {
              completedSetData = completedSetsForExercise[index];
            }

            // Format previous session data
            String prevDisplay = '-';
            if (previousSet != null) {
              final prevWeight = _useKg
                  ? previousSet['weight'] as double
                  : (previousSet['weight'] as double) * 2.20462;
              prevDisplay = '${prevWeight.toStringAsFixed(0)} × ${previousSet['reps']}';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withOpacity(0.1)
                    : isCurrent
                        ? AppColors.cyan.withOpacity(0.1)
                        : Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  // Set number
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.cyan
                                : AppColors.textMuted,
                      ),
                    ),
                  ),

                  // Previous session
                  Expanded(
                    flex: 2,
                    child: Text(
                      prevDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // Weight - inline editable for current set only when viewing current exercise
                  Expanded(
                    flex: 2,
                    child: isCurrent
                        ? _buildInlineInput(
                            controller: _weightController,
                            isDecimal: true,
                          )
                        : Text(
                            isCompleted
                                ? (_useKg
                                    ? completedSetData!.weight.toStringAsFixed(0)
                                    : (completedSetData!.weight * 2.20462).toStringAsFixed(0))
                                : '-',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: isCompleted ? AppColors.success : AppColors.textMuted,
                            ),
                          ),
                  ),

                  // Reps - inline editable for current set only when viewing current exercise
                  Expanded(
                    flex: 2,
                    child: isCurrent
                        ? _buildInlineInput(
                            controller: _repsController,
                            isDecimal: false,
                          )
                        : Text(
                            isCompleted ? completedSetData!.reps.toString() : '-',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: isCompleted ? AppColors.success : AppColors.textMuted,
                            ),
                          ),
                  ),

                  // Checkmark / Complete button - only active on current exercise
                  SizedBox(
                    width: 44,
                    child: isCompleted
                        ? Icon(Icons.check_circle, size: 24, color: AppColors.success)
                        : isCurrent
                            ? GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _completeSet();
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.check, size: 18, color: Colors.black),
                                ),
                              )
                            : Icon(Icons.circle_outlined, size: 20, color: AppColors.textMuted.withOpacity(0.3)),
                  ),
                ],
              ),
            );
          }),

          // Add Set button
          GestureDetector(
            onTap: () {
              setState(() {
                _totalSetsPerExercise[_viewingExerciseIndex] = totalSets + 1;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    'Add Set',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rest timer info OR "Go to current" button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.elevated.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: isViewingCurrent
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.purple.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        'Rest: ${viewingExercise.restSeconds ?? 90}s between sets',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.purple.withOpacity(0.8),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => _viewingExerciseIndex = _currentExerciseIndex);
                      HapticFeedback.selectionClick();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_return, size: 14, color: AppColors.cyan),
                        const SizedBox(width: 4),
                        Text(
                          'Back to Current Exercise',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1);
  }

  static const _overlayHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Build inline editable input for the Set Tracker
  Widget _buildInlineInput({
    required TextEditingController controller,
    required bool isDecimal,
  }) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cyan.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.cyan,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
        ),
        onChanged: (val) {
          setState(() {}); // Trigger rebuild to update display
        },
      ),
    );
  }

  Widget _buildBottomSection(WorkoutExercise currentExercise, WorkoutExercise? nextExercise) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible instructions panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _showInstructions ? null : 0,
            child: _showInstructions
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.elevated.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.cyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Exercise details
                        _InstructionRow(
                          label: 'Reps',
                          value: currentExercise.reps != null
                              ? '${currentExercise.reps} reps'
                              : '${currentExercise.durationSeconds ?? 30}s',
                        ),
                        _InstructionRow(
                          label: 'Sets',
                          value: '${currentExercise.sets ?? 3} sets',
                        ),
                        if (currentExercise.weight != null)
                          _InstructionRow(
                            label: 'Weight',
                            value: '${currentExercise.weight} kg',
                          ),
                        _InstructionRow(
                          label: 'Rest',
                          value: '${currentExercise.restSeconds ?? 90}s between sets',
                        ),
                        if (currentExercise.notes != null && currentExercise.notes!.isNotEmpty) ...[
                          const Divider(color: AppColors.cardBorder, height: 24),
                          Text(
                            currentExercise.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Simplified bottom bar - navigation only
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.nearBlack.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Expand/collapse info button
                _GlassButton(
                  icon: _showInstructions ? Icons.expand_more : Icons.expand_less,
                  onTap: () => setState(() => _showInstructions = !_showInstructions),
                  size: 44,
                ),

                const SizedBox(width: 12),

                // Next exercise indicator (expanded)
                Expanded(
                  child: nextExercise != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_forward, size: 16, color: AppColors.cyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      nextExercise.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag, size: 16, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(
                                'Last Exercise!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(width: 12),

                // Skip exercise button
                OutlinedButton(
                  onPressed: _skipExercise,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: AppColors.cardBorder),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Glass Button
// ─────────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;
  final double size;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.cyan.withOpacity(0.3)
              : AppColors.pureBlack.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? AppColors.cyan.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isHighlighted ? AppColors.cyan : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Chip
// ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? suffix;
  final String? label;
  final Color color;
  final double scaleFactor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
    this.suffix,
    this.label,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic dimensions based on scale factor
    final horizontalPadding = (10 * scaleFactor).clamp(6.0, 14.0);
    final verticalPadding = (6 * scaleFactor).clamp(4.0, 8.0);
    final iconSize = (16 * scaleFactor).clamp(12.0, 20.0);
    final valueFontSize = (14 * scaleFactor).clamp(10.0, 18.0);
    final suffixFontSize = (10 * scaleFactor).clamp(8.0, 13.0);
    final labelFontSize = (8 * scaleFactor).clamp(6.0, 10.0);
    final innerSpacing = (4 * scaleFactor).clamp(2.0, 6.0);
    final borderRadius = (12 * scaleFactor).clamp(8.0, 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: innerSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
          if (suffix != null)
            Text(
              ' $suffix',
              style: TextStyle(
                fontSize: suffixFontSize,
                color: color.withOpacity(0.7),
              ),
            ),
          if (label != null) ...[
            SizedBox(width: innerSpacing),
            Text(
              label!,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Set Dots
// ─────────────────────────────────────────────────────────────────

class _SetDots extends StatelessWidget {
  final int totalSets;
  final int completedSets;

  const _SetDots({
    required this.totalSets,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'Set ${completedSets + 1} of $totalSets',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSets, (index) {
            final isCompleted = index < completedSets;
            final isCurrent = index == completedSets;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.cyan
                        : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppColors.cyan : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Instruction Row
// ─────────────────────────────────────────────────────────────────

class _InstructionRow extends StatelessWidget {
  final String label;
  final String value;

  const _InstructionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Number Input Field
// ─────────────────────────────────────────────────────────────────

class _NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final Color color;
  final bool isDecimal;

  const _NumberInputField({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.color,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Decrement button
          GestureDetector(
            onTap: () {
              final current = isDecimal
                  ? (double.tryParse(controller.text) ?? 0)
                  : (int.tryParse(controller.text) ?? 0);
              final newValue = isDecimal
                  ? (current - 2.5).clamp(0, 999)
                  : (current - 1).clamp(0, 999);
              controller.text = isDecimal
                  ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                  : newValue.toInt().toString();
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.remove, color: color, size: 20),
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hint,
                hintStyle: TextStyle(color: color.withOpacity(0.4)),
              ),
            ),
          ),
          // Increment button
          GestureDetector(
            onTap: () {
              final current = isDecimal
                  ? (double.tryParse(controller.text) ?? 0)
                  : (int.tryParse(controller.text) ?? 0);
              final newValue = isDecimal ? current + 2.5 : current + 1;
              controller.text = isDecimal
                  ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                  : newValue.toInt().toString();
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.add, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Option Tile (for options menu)
// ─────────────────────────────────────────────────────────────────

class _ExerciseOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExerciseOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Inline Number Input (for active workout screen)
// ─────────────────────────────────────────────────────────────────

class _InlineNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDecimal;
  final String? unitLabel;
  final VoidCallback? onUnitToggle;

  const _InlineNumberInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.isDecimal = false,
    this.unitLabel,
    this.onUnitToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with optional unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              if (unitLabel != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onUnitToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          unitLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.swap_horiz, size: 10, color: color),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Input row with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement button
              GestureDetector(
                onTap: () {
                  final current = isDecimal
                      ? (double.tryParse(controller.text) ?? 0)
                      : (int.tryParse(controller.text) ?? 0);
                  final newValue = isDecimal
                      ? (current - 2.5).clamp(0.0, 999.0)
                      : (current - 1).clamp(0, 999);
                  controller.text = isDecimal
                      ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                      : newValue.toInt().toString();
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, color: color, size: 18),
                ),
              ),
              // Value field
              SizedBox(
                width: 60,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              // Increment button
              GestureDetector(
                onTap: () {
                  final current = isDecimal
                      ? (double.tryParse(controller.text) ?? 0)
                      : (int.tryParse(controller.text) ?? 0);
                  final newValue = isDecimal ? current + 2.5 : current + 1;
                  controller.text = isDecimal
                      ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                      : newValue.toInt().toString();
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: color, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
