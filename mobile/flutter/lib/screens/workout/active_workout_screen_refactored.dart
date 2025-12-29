/// Refactored Active Workout Screen
///
/// This is a modularized version of the active workout screen that composes
/// smaller, reusable widgets while keeping the business logic in the main state.
///
/// Structure:
/// - Main screen composition (~400 lines)
/// - Uses extracted widgets from widgets/ folder
/// - Uses controllers from controllers/ folder
/// - Uses models from models/ folder
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/providers/social_provider.dart';
import '../../data/rest_messages.dart';
import '../../widgets/log_1rm_sheet.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../challenges/widgets/challenge_quit_dialog.dart';

// Import modular components
import 'controllers/workout_timer_controller.dart';
import 'models/workout_state.dart';
import 'widgets/warmup_phase_screen.dart';
import 'widgets/stretch_phase_screen.dart';
import 'widgets/rest_timer_overlay.dart';
import 'widgets/workout_top_overlay.dart';
import 'widgets/set_tracking_overlay.dart';
import 'widgets/workout_bottom_bar.dart';
import 'widgets/number_input_widgets.dart';

/// Active workout screen with modular composition
class ActiveWorkoutScreenRefactored extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const ActiveWorkoutScreenRefactored({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutScreenRefactored> createState() =>
      _ActiveWorkoutScreenRefactoredState();
}

class _ActiveWorkoutScreenRefactoredState
    extends ConsumerState<ActiveWorkoutScreenRefactored> {
  // Phase state
  WorkoutPhase _currentPhase = WorkoutPhase.warmup;

  // Workout state
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  bool _isRestingBetweenExercises = false;
  bool _isPaused = false;
  bool _showInstructions = false;
  bool _showExerciseList = false;

  // Video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = true;
  String? _imageUrl;
  String? _videoUrl;
  bool _isLoadingMedia = true;

  // Timer controller
  late WorkoutTimerController _timerController;
  String _currentRestMessage = '';

  // Set tracking
  final Map<int, List<SetLog>> _completedSets = {};
  int _totalCaloriesBurned = 0;

  // Input controllers
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _useKg = true;

  // Set tracking overlay
  bool _showSetOverlay = true;
  Map<int, List<Map<String, dynamic>>> _previousSets = {};
  final Map<int, int> _totalSetsPerExercise = {};
  int _viewingExerciseIndex = 0;

  // Exercises list
  late List<WorkoutExercise> _exercises;

  // Tracking state
  int _totalDrinkIntakeMl = 0;
  bool _isActiveRowExpanded = true;
  final List<Map<String, dynamic>> _restIntervals = [];
  DateTime? _lastSetCompletedAt;
  DateTime? _lastExerciseStartedAt;
  bool _lastSetWasFast = false;
  final Map<int, int> _exerciseTimeSeconds = {};
  DateTime? _currentExerciseStartTime;
  bool _isDoneButtonPressed = false;
  int? _justCompletedSetIndex;
  bool _isLoadingHistory = true;
  final Map<String, double> _exerciseMaxWeights = {};

  // Warmup/stretch state (fetched from API)
  List<WarmupExerciseData>? _warmupExercises;
  List<StretchExerciseData>? _stretchExercises;
  bool _isLoadingWarmup = true;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
    _loadWarmupAndStretches();
  }

  void _initializeWorkout() {
    // Initialize exercises list
    _exercises = List.from(widget.workout.exercises);

    // Initialize input controllers
    final firstExercise = _exercises[0];
    _repsController =
        TextEditingController(text: (firstExercise.reps ?? 10).toString());
    _weightController =
        TextEditingController(text: (firstExercise.weight ?? 0).toString());

    // Initialize timer controller
    _timerController = WorkoutTimerController();
    _timerController.onWorkoutTick = (_) => setState(() {});
    _timerController.onRestTick = (_) => setState(() {});
    _timerController.onRestComplete = _handleRestComplete;

    // Start workout timer
    _timerController.startWorkoutTimer();

    // Initialize tracking data
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      _totalSetsPerExercise[i] = exercise.sets ?? 3;
      _previousSets[i] = [];
    }

    // Fetch historical data
    _fetchExerciseHistory();

    // Initialize time tracking
    _currentExerciseStartTime = DateTime.now();
    _lastExerciseStartedAt = DateTime.now();
  }

  /// Load personalized warmup and stretch exercises from API
  Future<void> _loadWarmupAndStretches() async {
    final workoutId = widget.workout.id;
    if (workoutId == null) {
      setState(() => _isLoadingWarmup = false);
      return;
    }

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final data = await workoutRepo.generateWarmupAndStretches(workoutId);

      if (!mounted) return;

      final warmupData = data['warmup'] ?? [];
      final stretchData = data['stretches'] ?? [];

      setState(() {
        if (warmupData.isNotEmpty) {
          _warmupExercises = warmupData.map<WarmupExerciseData>((e) => WarmupExerciseData(
            name: e['name']?.toString() ?? 'Exercise',
            duration: (e['duration_seconds'] as num?)?.toInt() ?? 30,
            icon: _getIconForExercise(e['name']?.toString() ?? ''),
          )).toList();
        }

        if (stretchData.isNotEmpty) {
          _stretchExercises = stretchData.map<StretchExerciseData>((e) => StretchExerciseData(
            name: e['name']?.toString() ?? 'Stretch',
            duration: (e['duration_seconds'] as num?)?.toInt() ?? 30,
            icon: _getIconForStretch(e['name']?.toString() ?? ''),
          )).toList();
        }

        _isLoadingWarmup = false;
      });

      debugPrint('✅ [Warmup] Loaded ${_warmupExercises?.length ?? 0} warmup exercises');
      debugPrint('✅ [Stretch] Loaded ${_stretchExercises?.length ?? 0} stretch exercises');
    } catch (e) {
      debugPrint('❌ [Warmup] Error loading warmup/stretches: $e');
      if (mounted) {
        setState(() => _isLoadingWarmup = false);
      }
    }
  }

  /// Map exercise name to appropriate icon for warmup
  IconData _getIconForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('jump') || lower.contains('jack') || lower.contains('cardio') || lower.contains('run')) {
      return Icons.directions_run;
    }
    if (lower.contains('circle') || lower.contains('rotation') || lower.contains('twist')) {
      return Icons.loop;
    }
    if (lower.contains('swing') || lower.contains('lunge') || lower.contains('step')) {
      return Icons.swap_horiz;
    }
    if (lower.contains('squat') || lower.contains('leg')) {
      return Icons.airline_seat_legroom_extra;
    }
    if (lower.contains('arm') || lower.contains('shoulder') || lower.contains('push')) {
      return Icons.fitness_center;
    }
    if (lower.contains('cat') || lower.contains('cow') || lower.contains('spine')) {
      return Icons.pets;
    }
    if (lower.contains('hip') || lower.contains('glute')) {
      return Icons.sports_gymnastics;
    }
    return Icons.whatshot; // Default warmup icon
  }

  /// Map exercise name to appropriate icon for stretches
  IconData _getIconForStretch(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('quad') || lower.contains('leg') || lower.contains('hamstring')) {
      return Icons.airline_seat_legroom_extra;
    }
    if (lower.contains('chest') || lower.contains('pec')) {
      return Icons.open_with;
    }
    if (lower.contains('back') || lower.contains('lat') || lower.contains('spine')) {
      return Icons.accessibility_new;
    }
    if (lower.contains('shoulder') || lower.contains('arm') || lower.contains('tricep')) {
      return Icons.fitness_center;
    }
    if (lower.contains('hip') || lower.contains('glute') || lower.contains('piriformis')) {
      return Icons.sports_gymnastics;
    }
    if (lower.contains('calf') || lower.contains('ankle')) {
      return Icons.directions_walk;
    }
    return Icons.self_improvement; // Default stretch icon
  }

  @override
  void dispose() {
    _timerController.dispose();
    _videoController?.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ========================================================================
  // PHASE HANDLERS
  // ========================================================================

  void _handleWarmupComplete() {
    HapticFeedback.heavyImpact();
    setState(() {
      _currentPhase = WorkoutPhase.active;
    });
    _fetchMediaForExercise(_exercises[0]);
  }

  void _handleSkipWarmup() {
    _handleWarmupComplete();
  }

  void _handleStretchComplete() {
    setState(() {
      _currentPhase = WorkoutPhase.complete;
    });
    _saveWorkoutCompletion();
  }

  void _handleSkipStretch() {
    _handleStretchComplete();
  }

  void _handleRestComplete() {
    setState(() {
      _isResting = false;
      _isRestingBetweenExercises = false;
    });
    HapticFeedback.heavyImpact();
  }

  // ========================================================================
  // WORKOUT LOGIC
  // ========================================================================

  void _completeSet() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    final setLog = SetLog(
      reps: reps,
      weight: _useKg ? weight : weight * 0.453592,
    );

    setState(() {
      _completedSets[_currentExerciseIndex] ??= [];
      _completedSets[_currentExerciseIndex]!.add(setLog);
      _justCompletedSetIndex = _completedSets[_currentExerciseIndex]!.length - 1;
    });

    // Clear animation after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _justCompletedSetIndex = null);
      }
    });

    // Check if exercise is complete
    final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;
    final completedCount = _completedSets[_currentExerciseIndex]?.length ?? 0;

    if (completedCount >= totalSets) {
      // Exercise complete - move to next or finish
      _moveToNextExercise();
    } else {
      // Start rest between sets
      _startRest(false);
    }

    HapticFeedback.heavyImpact();
    _lastSetCompletedAt = DateTime.now();
  }

  void _startRest(bool betweenExercises) {
    final restSeconds =
        _exercises[_currentExerciseIndex].restSeconds ?? (betweenExercises ? 120 : 90);

    setState(() {
      _isResting = true;
      _isRestingBetweenExercises = betweenExercises;
      _currentRestMessage = restMessages[
          DateTime.now().millisecondsSinceEpoch % restMessages.length];
    });

    _timerController.startRestTimer(restSeconds);

    // Track rest interval
    _restIntervals.add({
      'exercise_id': _exercises[_currentExerciseIndex].id,
      'exercise_name': _exercises[_currentExerciseIndex].name,
      'rest_seconds': restSeconds,
      'rest_type': betweenExercises ? 'between_exercises' : 'between_sets',
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      // Track time for current exercise
      if (_currentExerciseStartTime != null) {
        _exerciseTimeSeconds[_currentExerciseIndex] =
            DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
      }

      setState(() {
        _currentExerciseIndex++;
        _viewingExerciseIndex = _currentExerciseIndex;
      });

      // Update input controllers for new exercise
      final exercise = _exercises[_currentExerciseIndex];
      _repsController.text = (exercise.reps ?? 10).toString();
      _weightController.text = (exercise.weight ?? 0).toString();

      // Fetch media for new exercise
      _fetchMediaForExercise(exercise);

      // Start rest between exercises
      _startRest(true);

      _currentExerciseStartTime = DateTime.now();
      _lastExerciseStartedAt = DateTime.now();
    } else {
      // All exercises complete - move to stretch phase
      setState(() {
        _currentPhase = WorkoutPhase.stretch;
      });
    }
  }

  void _skipExercise() {
    _moveToNextExercise();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    _timerController.setPaused(_isPaused);
  }

  // ========================================================================
  // DATA FETCHING
  // ========================================================================

  Future<void> _fetchExerciseHistory() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    final repository = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      await _fetchSingleExerciseHistory(repository, userId, exercise, i);
    }

    if (mounted) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _fetchSingleExerciseHistory(
    WorkoutRepository repository,
    String userId,
    WorkoutExercise exercise,
    int exerciseIndex,
  ) async {
    try {
      final lastPerformance = await repository.getExerciseLastPerformance(
        userId: userId,
        exerciseName: exercise.name,
      );

      if (lastPerformance != null && lastPerformance['sets'] != null) {
        final sets = lastPerformance['sets'] as List;
        if (mounted) {
          setState(() {
            _previousSets[exerciseIndex] = sets
                .map((s) => {
                      'set': s['set_number'] ?? 1,
                      'weight': (s['weight_kg'] as num?)?.toDouble() ?? 0.0,
                      'reps': s['reps_completed'] ?? 10,
                    })
                .toList();
          });
        }

        for (final set in sets) {
          final weight = (set['weight_kg'] as num?)?.toDouble() ?? 0.0;
          final currentMax = _exerciseMaxWeights[exercise.name] ?? 0.0;
          if (weight > currentMax) {
            _exerciseMaxWeights[exercise.name] = weight;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load history for ${exercise.name}: $e');
    }
  }

  Future<void> _fetchMediaForExercise(WorkoutExercise exercise) async {
    setState(() => _isLoadingMedia = true);

    // Dispose previous video controller
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    // Check for video or image URL
    final videoUrl = exercise.videoUrl ?? exercise.videoS3Path;
    final imageUrl = exercise.gifUrl ?? exercise.imageS3Path;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();

        if (mounted) {
          setState(() {
            _videoUrl = videoUrl;
            _isVideoInitialized = true;
            _isVideoPlaying = true;
            _isLoadingMedia = false;
          });
        }
      } catch (e) {
        // Fall back to image
        setState(() {
          _imageUrl = imageUrl;
          _isLoadingMedia = false;
        });
      }
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      setState(() {
        _imageUrl = imageUrl;
        _isLoadingMedia = false;
      });
    } else {
      setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _saveWorkoutCompletion() async {
    // Build completion data
    final setData = <Map<String, dynamic>>[];
    _completedSets.forEach((exerciseIndex, sets) {
      for (int i = 0; i < sets.length; i++) {
        final set = sets[i];
        setData.add({
          'exercise_index': exerciseIndex,
          'exercise_name': _exercises[exerciseIndex].name,
          'set_number': i + 1,
          'reps_completed': set.reps,
          'weight_kg': set.weight,
          'set_type': set.setType,
        });
      }
    });

    final completionData = {
      'workout_id': widget.workout.id,
      'total_time_seconds': _timerController.workoutSeconds,
      'calories_burned': _totalCaloriesBurned,
      'drink_intake_ml': _totalDrinkIntakeMl,
      'sets': setData,
      'rest_intervals': _restIntervals,
      'exercise_times': _exerciseTimeSeconds,
    };

    try {
      final repository = ref.read(workoutRepositoryProvider);
      // Save workout completion
      debugPrint('Workout completion data: ${jsonEncode(completionData)}');
    } catch (e) {
      debugPrint('Failed to save workout completion: $e');
    }
  }

  // ========================================================================
  // DIALOGS
  // ========================================================================

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quit Workout?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your progress will be lost. Are you sure you want to quit?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  void _showNumberInputDialog(
      TextEditingController controller, bool isDecimal) {
    final editController = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isDecimal ? 'Enter Weight (${_useKg ? 'kg' : 'lbs'})' : 'Enter Reps',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.cyan,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.pureBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cyan),
            ),
          ),
          onSubmitted: (value) {
            if (!isDecimal) {
              final intVal =
                  int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
              controller.text = intVal.toString();
            } else {
              controller.text = value;
            }
            setState(() {});
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (!isDecimal) {
                final intVal = int.tryParse(
                        editController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
                    0;
                controller.text = intVal.toString();
              } else {
                controller.text = editController.text;
              }
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('OK',
                style: TextStyle(
                    color: AppColors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLog1RMSheet(WorkoutExercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Log1RMSheet(exerciseName: exercise.name),
    );
  }

  // ========================================================================
  // BUILD METHOD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Route to appropriate phase screen
    switch (_currentPhase) {
      case WorkoutPhase.warmup:
        // Use personalized warmups from API if available, otherwise defaults
        return WarmupPhaseScreen(
          workoutSeconds: _timerController.workoutSeconds,
          exercises: _warmupExercises ?? defaultWarmupExercises,
          onSkipWarmup: _handleSkipWarmup,
          onWarmupComplete: _handleWarmupComplete,
          onQuitRequested: _showQuitDialog,
        );

      case WorkoutPhase.stretch:
        // Use personalized stretches from API if available, otherwise defaults
        return StretchPhaseScreen(
          workoutSeconds: _timerController.workoutSeconds,
          exercises: _stretchExercises ?? defaultStretchExercises,
          onSkipAll: _handleSkipStretch,
          onStretchComplete: _handleStretchComplete,
        );

      case WorkoutPhase.complete:
        return _buildCompletionScreen(isDark, backgroundColor);

      case WorkoutPhase.active:
        return _buildActiveWorkoutScreen(isDark, backgroundColor);
    }
  }

  Widget _buildActiveWorkoutScreen(bool isDark, Color backgroundColor) {
    final currentExercise = _exercises[_currentExerciseIndex];
    final nextExercise = _currentExerciseIndex < _exercises.length - 1
        ? _exercises[_currentExerciseIndex + 1]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showQuitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Background media
            Positioned.fill(
              child: _buildMediaBackground(),
            ),

            // Rest overlay
            if (_isResting)
              Positioned.fill(
                child: RestTimerOverlay(
                  restSecondsRemaining: _timerController.restSecondsRemaining,
                  initialRestDuration: _timerController.initialRestDuration,
                  restMessage: _currentRestMessage,
                  currentExercise: currentExercise,
                  completedSetsCount:
                      _completedSets[_currentExerciseIndex]?.length ?? 0,
                  totalSets: _totalSetsPerExercise[_currentExerciseIndex] ?? 3,
                  nextExercise: nextExercise,
                  isRestBetweenExercises: _isRestingBetweenExercises,
                  onSkipRest: () => _timerController.skipRest(),
                  onLog1RM: () => _showLog1RMSheet(currentExercise),
                ),
              ),

            // Top overlay
            if (!_isResting)
              WorkoutTopOverlay(
                workoutSeconds: _timerController.workoutSeconds,
                isPaused: _isPaused,
                totalExercises: _exercises.length,
                currentExerciseIndex: _currentExerciseIndex,
                totalCompletedSets: _completedSets.values
                    .fold(0, (sum, sets) => sum + sets.length),
                onTogglePause: _togglePause,
                onShowExerciseList: () =>
                    setState(() => _showExerciseList = true),
                onQuit: _showQuitDialog,
              ),

            // Set tracking overlay
            if (!_isResting && _showSetOverlay)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 70,
                child: SetTrackingOverlay(
                  exercise: _exercises[_viewingExerciseIndex],
                  viewingExerciseIndex: _viewingExerciseIndex,
                  currentExerciseIndex: _currentExerciseIndex,
                  totalExercises: _exercises.length,
                  totalSets: _totalSetsPerExercise[_viewingExerciseIndex] ?? 3,
                  completedSets:
                      _completedSets[_viewingExerciseIndex] ?? [],
                  previousSets: _previousSets[_viewingExerciseIndex] ?? [],
                  useKg: _useKg,
                  weightController: _weightController,
                  repsController: _repsController,
                  isActiveRowExpanded: _isActiveRowExpanded,
                  justCompletedSetIndex: _justCompletedSetIndex,
                  isDoneButtonPressed: _isDoneButtonPressed,
                  onToggleRowExpansion: () =>
                      setState(() => _isActiveRowExpanded = !_isActiveRowExpanded),
                  onCompleteSet: _completeSet,
                  onToggleUnit: _toggleUnit,
                  onClose: () => setState(() => _showSetOverlay = false),
                  onPreviousExercise: _viewingExerciseIndex > 0
                      ? () => setState(() => _viewingExerciseIndex--)
                      : null,
                  onNextExercise: _viewingExerciseIndex < _exercises.length - 1
                      ? () => setState(() => _viewingExerciseIndex++)
                      : null,
                  onAddSet: () => setState(() {
                    _totalSetsPerExercise[_viewingExerciseIndex] =
                        (_totalSetsPerExercise[_viewingExerciseIndex] ?? 3) + 1;
                  }),
                  onBackToCurrentExercise: () =>
                      setState(() => _viewingExerciseIndex = _currentExerciseIndex),
                  onEditSet: (index) => _editCompletedSet(index),
                  onDeleteSet: (index) => _deleteCompletedSet(index),
                  onDoneButtonPressDown: () =>
                      setState(() => _isDoneButtonPressed = true),
                  onDoneButtonPressUp: () {
                    setState(() => _isDoneButtonPressed = false);
                    HapticFeedback.heavyImpact();
                    _completeSet();
                  },
                  onDoneButtonPressCancel: () =>
                      setState(() => _isDoneButtonPressed = false),
                  onShowNumberInputDialog: _showNumberInputDialog,
                ),
              ),

            // Bottom bar
            if (!_isResting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: WorkoutBottomBar(
                  currentExercise: currentExercise,
                  nextExercise: nextExercise,
                  showInstructions: _showInstructions,
                  isResting: _isResting,
                  onToggleInstructions: () =>
                      setState(() => _showInstructions = !_showInstructions),
                  onSkip: _isResting
                      ? () => _timerController.skipRest()
                      : _skipExercise,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBackground() {
    if (_isLoadingMedia) {
      return Container(
        color: AppColors.pureBlack,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.pureBlack,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.elevated,
          child: const Center(
            child: Icon(Icons.fitness_center, size: 80, color: AppColors.cyan),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.elevated,
      child: const Center(
        child: Icon(Icons.fitness_center, size: 80, color: AppColors.cyan),
      ),
    );
  }

  Widget _buildCompletionScreen(bool isDark, Color backgroundColor) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 100,
                color: AppColors.cyan,
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms)
                  .then()
                  .shake(duration: 300.ms),
              const SizedBox(height: 24),
              Text(
                'Workout Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                WorkoutTimerController.formatTime(_timerController.workoutSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 32),
              _buildCompletionStats(isDark),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStats(bool isDark) {
    final totalSets =
        _completedSets.values.fold(0, (sum, sets) => sum + sets.length);
    final totalReps = _completedSets.values.fold(
        0, (sum, sets) => sum + sets.fold(0, (s, set) => s + set.reps));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CompletionStat(
          icon: Icons.fitness_center,
          value: totalSets.toString(),
          label: 'Sets',
          isDark: isDark,
        ),
        _CompletionStat(
          icon: Icons.repeat,
          value: totalReps.toString(),
          label: 'Reps',
          isDark: isDark,
        ),
        _CompletionStat(
          icon: Icons.local_fire_department,
          value: _totalCaloriesBurned.toString(),
          label: 'Calories',
          isDark: isDark,
        ),
      ],
    );
  }

  void _toggleUnit() {
    setState(() {
      final currentVal = double.tryParse(_weightController.text) ?? 0;
      if (_useKg) {
        final lbsVal = currentVal * 2.20462;
        _weightController.text =
            lbsVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      } else {
        final kgVal = currentVal * 0.453592;
        _weightController.text =
            kgVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }
      _useKg = !_useKg;
    });
  }

  void _editCompletedSet(int setIndex) {
    // Show edit dialog
    final set = _completedSets[_viewingExerciseIndex]![setIndex];
    final editWeightController =
        TextEditingController(text: set.weight.toStringAsFixed(1));
    final editRepsController = TextEditingController(text: set.reps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Text('Edit Set ${setIndex + 1}',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NumberInputField(
              controller: editWeightController,
              icon: Icons.fitness_center,
              hint: 'Weight',
              color: AppColors.cyan,
              isDecimal: true,
            ),
            const SizedBox(height: 16),
            NumberInputField(
              controller: editRepsController,
              icon: Icons.repeat,
              hint: 'Reps',
              color: AppColors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _completedSets[_viewingExerciseIndex]![setIndex] = SetLog(
                  reps: int.tryParse(editRepsController.text) ?? set.reps,
                  weight:
                      double.tryParse(editWeightController.text) ?? set.weight,
                  completedAt: set.completedAt,
                  setType: set.setType,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }

  void _deleteCompletedSet(int setIndex) {
    setState(() {
      _completedSets[_viewingExerciseIndex]!.removeAt(setIndex);
    });
  }
}

/// Completion stat widget
class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.cyan),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }
}
