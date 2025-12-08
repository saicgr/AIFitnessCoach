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

  @override
  void initState() {
    super.initState();
    // Initialize input controllers with default values from first exercise
    final firstExercise = widget.workout.exercises[0];
    _repsController = TextEditingController(text: (firstExercise.reps ?? 10).toString());
    _weightController = TextEditingController(text: (firstExercise.weight ?? 0).toString());
    _startWorkoutTimer();
    // Initialize completed sets tracking
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      _completedSets[i] = [];
    }
    // Fetch media for first exercise
    _fetchMediaForExercise(widget.workout.exercises[0]);
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

    // Log the set (always stored in kg)
    setState(() {
      _completedSets[_currentExerciseIndex]!.add(SetLog(reps: reps, weight: weight));
    });

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
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      final nextIndex = _currentExerciseIndex + 1;
      final nextExercise = widget.workout.exercises[nextIndex];
      setState(() {
        _currentExerciseIndex = nextIndex;
        _currentSet = 1;
        _isResting = false;
        _showInstructions = false;
      });
      // Update controllers with next exercise defaults
      _repsController.text = (nextExercise.reps ?? 10).toString();
      _weightController.text = (nextExercise.weight ?? 0).toString();
      _fetchMediaForExercise(nextExercise);
      HapticFeedback.heavyImpact();
    } else {
      _completeWorkout();
    }
  }

  void _skipExercise() => _moveToNextExercise();

  Future<void> _completeWorkout() async {
    _workoutTimer?.cancel();
    _restTimer?.cancel();

    setState(() => _isComplete = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (widget.workout.id != null && userId != null) {
        // 1. Create workout log with all sets
        debugPrint('🏋️ Saving workout log to backend...');
        final setsJson = _buildSetsJson();
        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: widget.workout.id!,
          userId: userId,
          setsJson: setsJson,
          totalTimeSeconds: _workoutSeconds,
        );

        // 2. Log individual set performances
        if (workoutLog != null) {
          debugPrint('✅ Workout log created: ${workoutLog['id']}');
          final workoutLogId = workoutLog['id'] as String;
          await _logAllSetPerformances(workoutLogId, userId);
        } else {
          debugPrint('⚠️ Failed to create workout log, skipping performance logs');
        }

        // 3. Mark workout as complete in workouts table
        await workoutRepo.completeWorkout(widget.workout.id!);
        debugPrint('✅ Workout marked as complete');
      }
    } catch (e) {
      debugPrint('❌ Failed to complete workout: $e');
    }

    if (mounted) {
      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _workoutSeconds,
        'calories': _totalCaloriesBurned,
      });
    }
  }

  /// Build JSON string of all completed sets
  String _buildSetsJson() {
    final List<Map<String, dynamic>> allSets = [];

    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
      final sets = _completedSets[i] ?? [];

      for (int j = 0; j < sets.length; j++) {
        allSets.add({
          'exercise_index': i,
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

  /// Log all individual set performances to backend
  Future<void> _logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < widget.workout.exercises.length; i++) {
      final exercise = widget.workout.exercises[i];
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Quit Workout?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Quit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showExerciseListDrawer() {
    final exercises = widget.workout.exercises;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
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
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    Text(
                      'All Exercises (${exercises.length})',
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
              Divider(color: AppColors.cardBorder.withOpacity(0.3), height: 1),
              // Exercise list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isCompleted = index < _currentExerciseIndex;
                    final isCurrent = index == _currentExerciseIndex;
                    final completedSetsCount = _completedSets[index]?.length ?? 0;
                    final totalSets = exercise.sets ?? 3;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (index != _currentExerciseIndex) {
                          setState(() {
                            _currentExerciseIndex = index;
                            _currentSet = completedSetsCount + 1;
                            _isResting = false;
                            _showInstructions = false;
                          });
                          _fetchMediaForExercise(exercise);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            // Index/status
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.success
                                    : isCurrent
                                        ? AppColors.cyan
                                        : AppColors.glassSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? AppColors.pureBlack
                                              : AppColors.textMuted,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Exercise info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise.sets ?? 3} sets × ${exercise.reps ?? 10} reps',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress
                            if (isCurrent || isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.cyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isCompleted
                                      ? 'Done'
                                      : '$completedSetsCount/$totalSets',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.cyan,
                                  ),
                                ),
                              ),
                          ],
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
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workout.exercises;
    final currentExercise = exercises[_currentExerciseIndex];
    final nextExercise = _currentExerciseIndex < exercises.length - 1
        ? exercises[_currentExerciseIndex + 1]
        : null;
    final progress = (_currentExerciseIndex + 1) / exercises.length;

    return WillPopScope(
      onWillPop: () async {
        _showQuitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: Stack(
          children: [
            // Full-screen video/image background
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleVideoPlayPause,
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
                      'Exercise ${_currentExerciseIndex + 1} of ${widget.workout.exercises.length}',
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

          const SizedBox(height: 16),

          // Stats row: Timer | Calories | Set
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                icon: Icons.timer_outlined,
                value: _formatTime(_workoutSeconds),
                color: _isPaused ? AppColors.textMuted : AppColors.cyan,
                label: _isPaused ? 'PAUSED' : null,
              ),
              _StatChip(
                icon: Icons.local_fire_department,
                value: '$_totalCaloriesBurned',
                suffix: 'cal',
                color: AppColors.orange,
              ),
              _StatChip(
                icon: Icons.repeat,
                value: '$_currentSet/${exercise.sets ?? 3}',
                suffix: 'set',
                color: AppColors.purple,
              ),
            ],
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

          // Bottom bar with inline inputs
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.nearBlack.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Top row: Info toggle + Set indicators + Next exercise
                Row(
                  children: [
                    _GlassButton(
                      icon: _showInstructions ? Icons.expand_more : Icons.expand_less,
                      onTap: () => setState(() => _showInstructions = !_showInstructions),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SetDots(
                        totalSets: currentExercise.sets ?? 3,
                        completedSets: _completedSets[_currentExerciseIndex]!.length,
                      ),
                    ),
                    if (nextExercise != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.skip_next, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                nextExercise.name,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // INLINE WEIGHT & REPS INPUTS (always visible)
                Row(
                  children: [
                    // Reps input
                    Expanded(
                      child: _InlineNumberInput(
                        controller: _repsController,
                        label: 'REPS',
                        icon: Icons.repeat,
                        color: AppColors.cyan,
                        isDecimal: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Weight input with kg/lbs toggle
                    Expanded(
                      child: _InlineNumberInput(
                        controller: _weightController,
                        label: 'WEIGHT',
                        unitLabel: _useKg ? 'kg' : 'lbs',
                        onUnitToggle: () {
                          setState(() {
                            // Convert current value when toggling
                            final currentVal = double.tryParse(_weightController.text) ?? 0;
                            if (_useKg) {
                              // Converting from kg to lbs
                              final lbsVal = currentVal * 2.20462;
                              _weightController.text = lbsVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                            } else {
                              // Converting from lbs to kg
                              final kgVal = currentVal * 0.453592;
                              _weightController.text = kgVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                            }
                            _useKg = !_useKg;
                          });
                          HapticFeedback.selectionClick();
                        },
                        icon: Icons.fitness_center,
                        color: AppColors.orange,
                        isDecimal: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Skip button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipExercise,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.cardBorder),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Complete set button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isResting ? _endRest : _completeSet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _isResting ? AppColors.purple : AppColors.cyan,
                          foregroundColor: _isResting ? Colors.white : AppColors.pureBlack,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isResting ? Icons.skip_next : Icons.check,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isResting
                                  ? 'Skip Rest'
                                  : _currentSet == (currentExercise.sets ?? 3)
                                      ? 'Done'
                                      : 'Log Set $_currentSet',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
    this.suffix,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
          if (suffix != null)
            Text(
              ' $suffix',
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: const TextStyle(
                fontSize: 9,
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
