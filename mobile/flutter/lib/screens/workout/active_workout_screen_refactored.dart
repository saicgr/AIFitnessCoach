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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/weight_suggestion_service.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/rest_messages.dart';
import '../../widgets/log_1rm_sheet.dart';
import '../ai_settings/ai_settings_screen.dart';

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
import 'widgets/set_row.dart'; // For RpeRirSelector
import 'widgets/fatigue_alert_modal.dart';
import 'widgets/workout_plan_drawer.dart';
import 'widgets/breathing_guide_sheet.dart';
import 'widgets/hydration_dialog.dart';
import 'widgets/workout_ai_coach_sheet.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../core/services/fatigue_service.dart';
import '../../core/providers/user_provider.dart';
import '../../data/services/haptic_service.dart';

/// Active workout screen with modular composition
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen> {
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
  final int _totalCaloriesBurned = 0;

  // Input controllers
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _useKg = true; // Initialized from user preference
  bool _unitInitialized = false; // Track if unit has been initialized from user preference

  // Set tracking overlay
  bool _showSetOverlay = true;
  final Map<int, List<Map<String, dynamic>>> _previousSets = {};
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
  final bool _lastSetWasFast = false;
  final Map<int, int> _exerciseTimeSeconds = {};
  DateTime? _currentExerciseStartTime;
  bool _isDoneButtonPressed = false;
  int? _justCompletedSetIndex;
  bool _isLoadingHistory = true;
  final Map<String, double> _exerciseMaxWeights = {};

  // RPE/RIR and weight suggestion state
  int? _lastSetRpe;
  int? _lastSetRir;
  WeightSuggestion? _currentWeightSuggestion;
  final bool _showRpeSelector = false;
  bool _isLoadingWeightSuggestion = false; // Loading state for AI suggestion
  SetLog? _pendingSetLog; // Set waiting for RPE/RIR input

  // Fatigue detection state
  FatigueAlertData? _fatigueAlertData;
  bool _showFatigueAlert = false;

  // Rest suggestion state (AI-powered)
  RestSuggestion? _restSuggestion;
  bool _isLoadingRestSuggestion = false;

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
    // Stop the workout timer when workout completes
    _timerController.stopWorkoutTimer();
    // Start completion process - this will save to backend and navigate
    _finalizeWorkoutCompletion();
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
    final exercise = _exercises[_currentExerciseIndex];
    final targetReps = exercise.reps ?? 10;

    final setLog = SetLog(
      reps: reps,
      weight: _useKg ? weight : weight * 0.453592,
      targetReps: targetReps,
    );

    // Store as pending - we'll finalize after RPE input
    _pendingSetLog = setLog;

    // Skip RPE selector - directly finalize the set
    // RPE tracking is optional - users can enable it in settings
    _finalizeSetWithRpe();

    // Use HapticService for satisfying set completion feedback
    HapticService.setCompletion();
    _lastSetCompletedAt = DateTime.now();
  }

  /// Show the RPE/RIR selector bottom sheet
  void _showRpeSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Force user to respond
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: RpeRirSelector(
            currentRpe: _lastSetRpe,
            currentRir: _lastSetRir,
            onRpeChanged: (rpe) => setState(() => _lastSetRpe = rpe),
            onRirChanged: (rir) => setState(() => _lastSetRir = rir),
            onDone: () {
              Navigator.pop(context);
              _finalizeSetWithRpe();
            },
          ),
        ),
      ),
    );
  }

  /// Finalize the set log with RPE/RIR and continue
  void _finalizeSetWithRpe() {
    if (_pendingSetLog == null) return;

    // Update set log with RPE/RIR
    final finalSetLog = _pendingSetLog!.copyWith(
      rpe: _lastSetRpe,
      rir: _lastSetRir,
    );

    setState(() {
      _completedSets[_currentExerciseIndex] ??= [];
      _completedSets[_currentExerciseIndex]!.add(finalSetLog);
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

      // Fetch AI-powered suggestions during rest
      _fetchAIWeightSuggestion(finalSetLog);
      _fetchRestSuggestion();
      _checkFatigue();
    }

    // Reset for next set
    _pendingSetLog = null;
    // Don't reset RPE/RIR - keep for context but allow changes
  }

  /// Fetch AI-powered weight suggestion from the backend
  Future<void> _fetchAIWeightSuggestion(SetLog setLog) async {
    final exercise = _exercises[_currentExerciseIndex];
    final isLastSet = (_completedSets[_currentExerciseIndex]?.length ?? 0) >=
        (_totalSetsPerExercise[_currentExerciseIndex] ?? 3);
    final equipmentIncrement = WeightIncrements.getIncrement(exercise.equipment);

    // Set loading state
    setState(() => _isLoadingWeightSuggestion = true);

    try {
      // Get API client and user ID
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // No user - use rule-based fallback
        _useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
        return;
      }

      // Get AI settings for personalized suggestions
      final aiSettings = ref.read(aiSettingsProvider);

      // Try AI-powered suggestion with personalized AI settings
      final aiSuggestion = await WeightSuggestionService.getAISuggestion(
        dio: apiClient.dio,
        userId: userId,
        exerciseName: exercise.name,
        exerciseId: exercise.id,
        equipment: exercise.equipment ?? 'dumbbell',
        muscleGroup: exercise.muscleGroup ?? 'unknown',
        setNumber: _completedSets[_currentExerciseIndex]?.length ?? 1,
        totalSets: _totalSetsPerExercise[_currentExerciseIndex] ?? 3,
        repsCompleted: setLog.reps,
        targetReps: setLog.targetReps,
        weightKg: setLog.weight,
        rpe: _lastSetRpe,
        rir: _lastSetRir,
        isLastSet: isLastSet,
        fitnessLevel: 'intermediate', // TODO: Get from user profile
        goals: [], // TODO: Get from user profile
        // Pass AI settings for personalized coaching
        coachingStyle: aiSettings?.coachingStyle ?? 'motivational',
        communicationTone: aiSettings?.communicationTone ?? 'encouraging',
        encouragementLevel: aiSettings?.encouragementLevel ?? 0.7,
        responseLength: aiSettings?.responseLength ?? 'balanced',
      );

      if (!mounted) return;

      if (aiSuggestion != null) {
        setState(() {
          _currentWeightSuggestion = aiSuggestion;
          _isLoadingWeightSuggestion = false;
        });
        print('✅ [AI Weight] Got AI suggestion: ${aiSuggestion.type} '
            'to ${aiSuggestion.suggestedWeight}kg');
      } else {
        // AI failed - use rule-based fallback
        _useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
      }
    } catch (e) {
      print('❌ [AI Weight] Error fetching suggestion: $e');
      if (!mounted) return;
      _useRuleBasedSuggestion(setLog, exercise, isLastSet, equipmentIncrement);
    }
  }

  /// Fallback to rule-based suggestion when AI is unavailable
  void _useRuleBasedSuggestion(
    SetLog setLog,
    WorkoutExercise exercise,
    bool isLastSet,
    double equipmentIncrement,
  ) {
    setState(() {
      _currentWeightSuggestion = WeightSuggestionService.generateSuggestion(
        currentWeight: setLog.weight,
        targetReps: setLog.targetReps,
        actualReps: setLog.reps,
        rpe: _lastSetRpe,
        rir: _lastSetRir,
        equipmentIncrement: equipmentIncrement,
        isLastSet: isLastSet,
      );
      _isLoadingWeightSuggestion = false;
    });
  }

  /// Handle accepting a weight suggestion
  void _acceptWeightSuggestion(double newWeight) {
    setState(() {
      _weightController.text = newWeight.toStringAsFixed(1);
      _currentWeightSuggestion = null; // Clear suggestion after accepting
    });
    HapticFeedback.mediumImpact();
  }

  /// Handle dismissing a weight suggestion
  void _dismissWeightSuggestion() {
    setState(() {
      _currentWeightSuggestion = null;
    });
  }

  // ========================================================================
  // FATIGUE DETECTION & REST SUGGESTIONS (AI Features)
  // ========================================================================

  /// Check for fatigue after completing a set
  Future<void> _checkFatigue() async {
    final exercise = _exercises[_currentExerciseIndex];
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];

    // Need at least 2 sets to detect fatigue
    if (completedSets.length < 2) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      final currentWeight = double.tryParse(_weightController.text) ?? 0;

      // Build set data for fatigue check
      final setsData = completedSets.map((s) => FatigueSetData(
        reps: s.reps,
        weight: s.weight,
        rpe: s.rpe,
        rir: s.rir,
        targetReps: exercise.reps,
      )).toList();

      final exerciseType = FatigueService.getExerciseType(
        exercise.muscleGroup,
        exercise.name,
      );

      final alertData = await FatigueService.checkFatigue(
        dio: apiClient.dio,
        setsData: setsData,
        currentWeight: currentWeight,
        exerciseType: exerciseType,
        targetReps: exercise.reps,
      );

      if (!mounted) return;

      if (alertData != null && alertData.fatigueDetected) {
        setState(() {
          _fatigueAlertData = alertData;
          _showFatigueAlert = true;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('❌ [Fatigue] Error checking fatigue: $e');
    }
  }

  /// Fetch AI-powered rest suggestion
  Future<void> _fetchRestSuggestion() async {
    final exercise = _exercises[_currentExerciseIndex];
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];

    if (completedSets.isEmpty) return;

    setState(() => _isLoadingRestSuggestion = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        setState(() => _isLoadingRestSuggestion = false);
        return;
      }

      final response = await apiClient.dio.post(
        '/workouts/rest-suggestions',
        data: {
          'user_id': userId,
          'exercise_name': exercise.name,
          'exercise_id': exercise.id ?? exercise.libraryId ?? '',
          'muscle_group': exercise.muscleGroup ?? 'unknown',
          'set_number': completedSets.length,
          'total_sets': _totalSetsPerExercise[_currentExerciseIndex] ?? 3,
          'last_set_reps': completedSets.last.reps,
          'last_set_weight': completedSets.last.weight,
          'last_set_rpe': _lastSetRpe,
          'last_set_rir': _lastSetRir,
          'default_rest_seconds': exercise.restSeconds ?? 90,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final suggestion = RestSuggestion.fromJson(response.data);
        setState(() {
          _restSuggestion = suggestion;
          _isLoadingRestSuggestion = false;
        });
        debugPrint('✅ [Rest] Got suggestion: ${suggestion.suggestedSeconds}s - ${suggestion.reasoning}');
      } else {
        setState(() => _isLoadingRestSuggestion = false);
      }
    } catch (e) {
      debugPrint('❌ [Rest] Error fetching suggestion: $e');
      if (mounted) {
        setState(() => _isLoadingRestSuggestion = false);
      }
    }
  }

  /// Handle accepting fatigue suggestion (reduce weight)
  void _handleAcceptFatigueSuggestion() {
    if (_fatigueAlertData != null && _fatigueAlertData!.suggestedWeight > 0) {
      _weightController.text = _fatigueAlertData!.suggestedWeight.toStringAsFixed(1);
    }
    setState(() {
      _showFatigueAlert = false;
      _fatigueAlertData = null;
    });
    HapticFeedback.mediumImpact();
  }

  /// Handle dismissing fatigue alert (continue as planned)
  void _handleDismissFatigueAlert() {
    setState(() {
      _showFatigueAlert = false;
      _fatigueAlertData = null;
    });
  }

  /// Accept rest suggestion - restart timer with new duration
  void _acceptRestSuggestion(int seconds) {
    // Restart rest timer with the suggested duration
    _timerController.startRestTimer(seconds);
    setState(() => _restSuggestion = null);
    HapticFeedback.mediumImpact();
  }

  /// Dismiss rest suggestion
  void _dismissRestSuggestion() {
    setState(() => _restSuggestion = null);
  }

  void _startRest(bool betweenExercises) {
    final exercise = _exercises[_currentExerciseIndex];
    final restSeconds = exercise.restSeconds ?? (betweenExercises ? 120 : 90);

    // Get AI settings for personalized message
    final aiSettings = ref.read(aiSettingsProvider);

    // Build context from the last completed set for intelligent feedback
    RestContext? context;
    final exerciseSets = _completedSets[_currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastSet = exerciseSets.last;
      final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;

      // Check if this was a PR by comparing to exercise history
      bool isPR = false;
      final previousMaxWeight = _exerciseMaxWeights[exercise.name] ?? 0.0;
      if (lastSet.weight > 0 && lastSet.weight > previousMaxWeight) {
        isPR = true;
      }

      // Check if weight increased from previous set in this workout
      double? previousWeight;
      if (exerciseSets.length > 1) {
        previousWeight = exerciseSets[exerciseSets.length - 2].weight;
      }

      context = RestContext(
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        reps: lastSet.reps,
        weightLifted: lastSet.weight,
        previousWeight: previousWeight,
        isLastSet: exerciseSets.length >= totalSets,
        isLastExercise: _currentExerciseIndex >= _exercises.length - 1,
        isPR: isPR,
        // Check if set was completed unusually fast (possible form issue)
        wasFast: lastSet.reps > 0 &&
            DateTime.now().difference(lastSet.completedAt).inSeconds.abs() < 5,
      );
    } else {
      // No sets completed - set was skipped
      context = RestContext(
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        reps: 0, // Indicates skipped set
        isLastSet: false,
        isLastExercise: _currentExerciseIndex >= _exercises.length - 1,
      );
    }

    final message = RestMessages.getMessage(
      aiSettings.coachingStyle,
      aiSettings.encouragementLevel,
      context: context,
    );

    setState(() {
      _isResting = true;
      _isRestingBetweenExercises = betweenExercises;
      _currentRestMessage = message;
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

      // Haptic feedback for exercise transition
      HapticService.exerciseTransition();

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
      // Celebratory haptic for workout completion
      HapticService.workoutComplete();
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
    _imageUrl = null;

    final apiClient = ref.read(apiClientProvider);
    final exerciseName = exercise.name;

    // 1. First try to use URLs from exercise model (if populated)
    final modelVideoUrl = exercise.videoUrl ?? exercise.videoS3Path;
    final modelImageUrl = exercise.gifUrl ?? exercise.imageS3Path;

    // 2. If model has URLs, use them directly
    if (modelImageUrl != null && modelImageUrl.isNotEmpty) {
      setState(() {
        _imageUrl = modelImageUrl;
        _isLoadingMedia = false;
      });
    }

    if (modelVideoUrl != null && modelVideoUrl.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(modelVideoUrl));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0); // Mute audio
        _videoController!.play();

        if (mounted) {
          setState(() {
            _videoUrl = modelVideoUrl;
            _isVideoInitialized = true;
            _isVideoPlaying = true;
          });
        }
        return; // Success - exit early
      } catch (e) {
        debugPrint('❌ [Media] Model video failed: $e');
      }
    }

    // 3. Fallback: Fetch from API endpoints (like old screen)
    // First fetch image (faster)
    try {
      final imageResponse = await apiClient.dio.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );
      if (imageResponse.data?['url'] != null && mounted) {
        setState(() {
          _imageUrl = imageResponse.data['url'];
          _isLoadingMedia = false;
        });
        debugPrint('✅ [Media] Image loaded from API: $_imageUrl');
      }
    } catch (e) {
      debugPrint('❌ [Media] Image API fetch failed: $e');
    }

    // Then fetch video (slower, plays over image)
    try {
      final videoResponse = await apiClient.dio.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );
      if (videoResponse.data?['url'] != null) {
        final videoUrl = videoResponse.data['url'];
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0); // Mute audio
        _videoController!.play();

        if (mounted) {
          setState(() {
            _videoUrl = videoUrl;
            _isVideoInitialized = true;
            _isVideoPlaying = true;
          });
        }
        debugPrint('✅ [Media] Video loaded from API: $videoUrl');
      }
    } catch (e) {
      debugPrint('❌ [Media] Video API fetch failed: $e');
      // Keep showing image fallback
    }

    // Final fallback - show placeholder
    if (mounted && _imageUrl == null && !_isVideoInitialized) {
      setState(() => _isLoadingMedia = false);
    }
  }

  /// Finalize workout: save to backend, get PRs, and navigate to complete screen
  Future<void> _finalizeWorkoutCompletion() async {
    setState(() => _currentPhase = WorkoutPhase.complete);

    // Variables to pass to workout complete screen
    String? workoutLogId;
    int totalCompletedSets = 0;
    int totalReps = 0;
    double totalVolumeKg = 0.0;
    int totalRestSeconds = 0;
    double avgRestSeconds = 0.0;
    List<PersonalRecordInfo>? personalRecords;
    PerformanceComparisonInfo? performanceComparison;

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Debug logging to trace workoutLogId issues
      debugPrint('🔍 [Complete] workout.id: ${widget.workout.id}');
      debugPrint('🔍 [Complete] userId: $userId');

      if (widget.workout.id != null && userId != null) {
        // 1. Create workout log with all sets
        debugPrint('🏋️ Saving workout log to backend...');
        final setsJson = _buildSetsJson();
        final metadata = _buildWorkoutMetadata();
        debugPrint('🔍 [Complete] setsJson length: ${setsJson.length}');

        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: widget.workout.id!,
          userId: userId,
          setsJson: setsJson,
          totalTimeSeconds: _timerController.workoutSeconds,
          metadata: jsonEncode(metadata),
        );

        // 2. Log individual set performances
        if (workoutLog != null) {
          debugPrint('✅ Workout log created: ${workoutLog['id']}');
          workoutLogId = workoutLog['id'] as String;
          await _logAllSetPerformances(workoutLogId, userId);
        } else {
          debugPrint('❌ [Complete] createWorkoutLog returned null - workoutLogId will be null');
        }

        // 3. Log drink intake if any
        if (_totalDrinkIntakeMl > 0) {
          await workoutRepo.logDrinkIntake(
            workoutId: widget.workout.id!,
            userId: userId,
            amountMl: _totalDrinkIntakeMl,
            drinkType: 'water',
          );
          debugPrint('💧 Logged drink intake: ${_totalDrinkIntakeMl}ml');
        }

        // 4. Calculate stats for workout complete screen
        totalCompletedSets = _completedSets.values.fold<int>(
          0, (sum, list) => sum + list.length,
        );
        final exercisesWithSets = _completedSets.values.where((l) => l.isNotEmpty).length;

        // Calculate total reps and volume
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

        // 5. Log workout exit
        await workoutRepo.logWorkoutExit(
          workoutId: widget.workout.id!,
          userId: userId,
          exitReason: 'completed',
          exercisesCompleted: exercisesWithSets,
          totalExercises: _exercises.length,
          setsCompleted: totalCompletedSets,
          timeSpentSeconds: _timerController.workoutSeconds,
          progressPercentage: _exercises.isNotEmpty
              ? (exercisesWithSets / _exercises.length * 100)
              : 100.0,
        );
        debugPrint('✅ Workout exit logged as completed');

        // 6. Mark workout as complete and get PRs
        final completionResponse = await workoutRepo.completeWorkout(widget.workout.id!);
        debugPrint('✅ Workout marked as complete');

        if (completionResponse != null && completionResponse.hasPRs) {
          personalRecords = completionResponse.personalRecords;
          debugPrint('🏆 Got ${personalRecords.length} PRs from completion API');
        }

        if (completionResponse != null && completionResponse.performanceComparison != null) {
          performanceComparison = completionResponse.performanceComparison;
          debugPrint('📊 Got performance comparison');
        }
      } else {
        debugPrint('❌ [Complete] Skipping workout log creation: workout.id=${widget.workout.id}, userId=$userId');
      }
    } catch (e) {
      debugPrint('❌ Failed to complete workout: $e');
    }

    // Build exercises performance data for complete screen
    final exercisesPerformance = <Map<String, dynamic>>[];
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final sets = _completedSets[i] ?? [];
      if (sets.isNotEmpty) {
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
      debugPrint('🏋️ [Complete] Navigating to workout-complete with workoutLogId: $workoutLogId');
      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _timerController.workoutSeconds,
        'calories': _totalCaloriesBurned,
        'drinkIntakeMl': _totalDrinkIntakeMl,
        'restIntervals': _restIntervals.length,
        'workoutLogId': workoutLogId,
        'exercisesPerformance': exercisesPerformance,
        'totalRestSeconds': totalRestSeconds,
        'avgRestSeconds': avgRestSeconds,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
        'challengeId': widget.challengeId,
        'challengeData': widget.challengeData,
        'personalRecords': personalRecords,
        'performanceComparison': performanceComparison,
      });
    }
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
          if (sets[j].rpe != null) 'rpe': sets[j].rpe,
          if (sets[j].rir != null) 'rir': sets[j].rir,
        });
      }
    }

    return jsonEncode(allSets);
  }

  /// Build comprehensive workout metadata JSON
  Map<String, dynamic> _buildWorkoutMetadata() {
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
    };
  }

  /// Log all set performances to backend
  Future<void> _logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      final sets = _completedSets[i] ?? [];

      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        try {
          await workoutRepo.logSetPerformance(
            workoutLogId: workoutLogId,
            exerciseId: exercise.exerciseId ?? exercise.libraryId ?? exercise.name,
            exerciseName: exercise.name,
            setNumber: j + 1,
            repsCompleted: setLog.reps,
            weightKg: setLog.weight,
            userId: userId,
            rpe: setLog.rpe?.toDouble(),
            rir: setLog.rir,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to log set performance: $e');
        }
      }
    }
    debugPrint('💪 Logged ${_completedSets.values.fold<int>(0, (s, l) => s + l.length)} set performances');
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
      builder: (context) => Log1RMSheet(
        exerciseName: exercise.name,
        exerciseId: exercise.id ?? exercise.libraryId ?? '',
      ),
    );
  }

  // ========================================================================
  // BUILD METHOD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    // Initialize weight unit from user preference on first build
    if (!_unitInitialized) {
      _unitInitialized = true;
      _useKg = ref.read(useKgProvider);
    }

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

            // Rest overlay with weight suggestion
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
                  // Weight suggestion props
                  weightSuggestion: _currentWeightSuggestion,
                  isLoadingWeightSuggestion: _isLoadingWeightSuggestion,
                  onAcceptWeightSuggestion: _acceptWeightSuggestion,
                  onDismissWeightSuggestion: _dismissWeightSuggestion,
                  // Rest suggestion props (AI-powered)
                  restSuggestion: _restSuggestion,
                  isLoadingRestSuggestion: _isLoadingRestSuggestion,
                  onAcceptRestSuggestion: _acceptRestSuggestion,
                  onDismissRestSuggestion: _dismissRestSuggestion,
                  // RPE/RIR input during rest
                  currentRpe: _lastSetRpe,
                  currentRir: _lastSetRir,
                  onRpeChanged: (rpe) => setState(() => _lastSetRpe = rpe),
                  onRirChanged: (rir) => setState(() => _lastSetRir = rir),
                  // Last set performance data for display
                  lastSetReps: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.reps
                      : null,
                  lastSetTargetReps: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.targetReps
                      : null,
                  lastSetWeight: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.weight
                      : null,
                  // Ask AI Coach button
                  onAskAICoach: () => context.push('/chat'),
                ),
              ),

            // Fatigue alert modal (AI-powered)
            if (_showFatigueAlert && _fatigueAlertData != null)
              Positioned.fill(
                child: FatigueAlertModal(
                  alertData: _fatigueAlertData!,
                  currentWeight: double.tryParse(_weightController.text) ?? 0,
                  exerciseName: currentExercise.name,
                  onAcceptSuggestion: _handleAcceptFatigueSuggestion,
                  onContinueAsPlanned: _handleDismissFatigueAlert,
                  onStopExercise: _skipExercise,
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
                top: MediaQuery.of(context).padding.top + 90,
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
                  onSkipExercise: _skipExercise,
                  onOpenWorkoutPlan: _showWorkoutPlanDrawer,
                ),
              ),

            // Bottom bar with action buttons
            if (!_isResting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: WorkoutBottomBar(
                  currentExercise: currentExercise,
                  nextExercise: nextExercise,
                  allExercises: _exercises,
                  currentExerciseIndex: _currentExerciseIndex,
                  completedSetsPerExercise: _completedSets.map(
                    (key, value) => MapEntry(key, value.length),
                  ),
                  showInstructions: _showInstructions,
                  isResting: _isResting,
                  onToggleInstructions: () =>
                      setState(() => _showInstructions = !_showInstructions),
                  onSkip: _isResting
                      ? () => _timerController.skipRest()
                      : _skipExercise,
                  onExerciseTap: (index) {
                    setState(() => _viewingExerciseIndex = index);
                  },
                  // New action button callbacks
                  currentCompletedSets:
                      _completedSets[_currentExerciseIndex]?.length ?? 0,
                  onAddSet: () => setState(() {
                    _totalSetsPerExercise[_currentExerciseIndex] =
                        (_totalSetsPerExercise[_currentExerciseIndex] ?? 3) + 1;
                  }),
                  onDeleteSet: () {
                    final sets = _completedSets[_currentExerciseIndex];
                    if (sets != null && sets.isNotEmpty) {
                      setState(() => sets.removeLast());
                    }
                  },
                  onAddWater: _showHydrationDialog,
                  onOpenBreathingGuide: () => _showBreathingGuide(currentExercise),
                  onOpenAICoach: () => _showAICoachSheet(currentExercise),
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
    // This shows briefly while saving to backend before navigating to WorkoutCompleteScreen
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: AppColors.cyan,
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms)
                  .then()
                  .shake(duration: 300.ms),
              const SizedBox(height: 24),
              Text(
                'Saving workout...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.cyan,
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

  // ========================================================================
  // BOTTOM BAR ACTION METHODS
  // ========================================================================

  /// Show hydration dialog and sync with nutrition tab
  Future<void> _showHydrationDialog() async {
    final amount = await showHydrationDialog(
      context: context,
      totalIntakeMl: _totalDrinkIntakeMl,
    );

    if (amount != null && amount > 0) {
      // Update local workout state
      setState(() => _totalDrinkIntakeMl += amount);

      // Sync with hydration provider (nutrition tab)
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final success = await ref.read(hydrationProvider.notifier).logHydration(
          userId: userId,
          drinkType: 'water',
          amountMl: amount,
          workoutId: widget.workout.id,
          notes: 'Logged during workout',
        );

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '${amount}ml water logged'
                  : 'Water logged locally (sync failed)'),
              duration: const Duration(seconds: 2),
              backgroundColor: success ? AppColors.success : AppColors.orange,
            ),
          );
        }
      } else {
        // User not logged in, just show local confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${amount}ml water logged'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Show breathing guide for the current exercise
  void _showBreathingGuide(WorkoutExercise exercise) {
    showBreathingGuide(
      context: context,
      exercise: exercise,
    );
  }

  /// Show AI coach chat sheet
  void _showAICoachSheet(WorkoutExercise exercise) {
    final currentWeight = double.tryParse(_weightController.text) ?? exercise.weight ?? 0;
    final completedSetsCount = _completedSets[_currentExerciseIndex]?.length ?? 0;
    final totalSetsCount = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;
    final remainingExercises = _exercises.sublist(_currentExerciseIndex + 1);

    showWorkoutAICoachSheet(
      context: context,
      ref: ref,
      currentExercise: exercise,
      completedSets: completedSetsCount,
      totalSets: totalSetsCount,
      currentWeight: currentWeight,
      useKg: _useKg,
      remainingExercises: remainingExercises,
    );
  }

  /// Show workout plan drawer with reorderable exercises
  void _showWorkoutPlanDrawer() {
    showWorkoutPlanDrawer(
      context: context,
      exercises: _exercises,
      currentExerciseIndex: _currentExerciseIndex,
      completedSetsPerExercise: _completedSets.map(
        (key, value) => MapEntry(key, value.length),
      ),
      totalSetsPerExercise: _totalSetsPerExercise,
      onJumpToExercise: (index) {
        setState(() {
          _viewingExerciseIndex = index;
        });
      },
      onReorder: (reorderedExercises) {
        setState(() {
          // Rebuild the exercise list with new order
          _exercises.clear();
          _exercises.addAll(reorderedExercises);
        });
      },
      onSwapExercise: (index) {
        // TODO: Open exercise swap sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swap ${_exercises[index].name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onDeleteExercise: (index) {
        setState(() {
          // Remove exercise and shift data
          _exercises.removeAt(index);

          // Clean up the maps for the deleted exercise
          _completedSets.remove(index);
          _totalSetsPerExercise.remove(index);
          _previousSets.remove(index);

          // Shift data for exercises after the deleted one
          final newCompletedSets = <int, List<SetLog>>{};
          final newTotalSets = <int, int>{};
          final newPreviousSets = <int, List<Map<String, dynamic>>>{};

          _completedSets.forEach((key, value) {
            if (key > index) {
              newCompletedSets[key - 1] = value;
            } else {
              newCompletedSets[key] = value;
            }
          });

          _totalSetsPerExercise.forEach((key, value) {
            if (key > index) {
              newTotalSets[key - 1] = value;
            } else {
              newTotalSets[key] = value;
            }
          });

          _previousSets.forEach((key, value) {
            if (key > index) {
              newPreviousSets[key - 1] = value;
            } else {
              newPreviousSets[key] = value;
            }
          });

          _completedSets
            ..clear()
            ..addAll(newCompletedSets);
          _totalSetsPerExercise
            ..clear()
            ..addAll(newTotalSets);
          _previousSets
            ..clear()
            ..addAll(newPreviousSets);

          // Adjust current index if needed
          if (_currentExerciseIndex >= _exercises.length) {
            _currentExerciseIndex = _exercises.length - 1;
          }
          if (_viewingExerciseIndex >= _exercises.length) {
            _viewingExerciseIndex = _exercises.length - 1;
          }
        });
      },
      onAddExercise: () {
        // TODO: Open exercise add sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add exercise feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
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
