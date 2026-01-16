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
import '../../core/constants/workout_design.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/services/weight_suggestion_service.dart';
import '../../data/models/smart_weight_suggestion.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/rest_messages.dart';
import '../../widgets/log_1rm_sheet.dart';
import '../../widgets/weight_increments_sheet.dart';
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
import 'widgets/exercise_info_sheet.dart';
import 'widgets/exercise_options_sheet.dart';
import 'widgets/exercise_analytics_page.dart';
import 'widgets/quit_workout_dialog.dart';
// MacroFactor-style V2 components
import 'widgets/workout_top_bar_v2.dart';
import 'widgets/exercise_thumbnail_strip_v2.dart';
import 'widgets/action_chips_row.dart';
import 'widgets/set_tracking_table.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../core/services/fatigue_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/pr_detection_service.dart';
import '../../data/models/coach_persona.dart';
import '../../widgets/coach_avatar.dart';
import 'widgets/pr_inline_celebration.dart';

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

  /// Whether to hide the AI Coach FAB for this session (user long-pressed to hide)
  bool _hideAICoachForSession = false;

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
  double _weightIncrement = 2.5; // Default weight increment (kg)

  // Set tracking overlay
  final Map<int, List<Map<String, dynamic>>> _previousSets = {};
  final Map<int, int> _totalSetsPerExercise = {};
  final Map<int, RepProgressionType> _repProgressionPerExercise = {};
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

  // PR detection service
  late PRDetectionService _prDetectionService;

  // Coach persona for AI Coach button
  CoachPersona? _coachPersona;

  // Rest suggestion state (AI-powered)
  RestSuggestion? _restSuggestion;
  bool _isLoadingRestSuggestion = false;

  // Warmup/stretch state (fetched from API)
  List<WarmupExerciseData>? _warmupExercises;
  List<StretchExerciseData>? _stretchExercises;
  bool _isLoadingWarmup = true;

  // V2 UI flag - MacroFactor style design
  bool _useV2Design = true;

  // L/R mode for unilateral exercises
  bool _isLeftRightMode = false;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
    _loadWarmupAndStretches();
    _checkWarmupEnabled();
  }

  /// Check if warmup is enabled and skip to active phase if not
  void _checkWarmupEnabled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final warmupState = ref.read(warmupDurationProvider);
      if (!warmupState.warmupEnabled) {
        setState(() {
          _currentPhase = WorkoutPhase.active;
        });
        debugPrint('🏋️ [ActiveWorkout] Warmup disabled, skipping to active phase');
      }
    });
  }

  void _initializeWorkout() {
    // Initialize exercises list
    _exercises = List.from(widget.workout.exercises);

    // Guard: If no exercises, we cannot proceed
    // Note: Router should catch this case, but keep as a safety check
    if (_exercises.isEmpty) {
      debugPrint('❌ [ActiveWorkout] No exercises in workout! Cannot start.');
      // Initialize with defaults to prevent late init errors
      _repsController = TextEditingController(text: '10');
      _weightController = TextEditingController(text: '0');
      _timerController = WorkoutTimerController();
      _prDetectionService = ref.read(prDetectionServiceProvider);
      // Schedule navigation back after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
        }
      });
      return;
    }

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

    // Initialize PR detection service
    _prDetectionService = ref.read(prDetectionServiceProvider);
    _prDetectionService.startNewWorkout();
    _preloadPRHistory();

    // Load coach persona for AI Coach button
    _loadCoachPersona();

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

    // Fetch smart weight for first exercise based on history
    _fetchSmartWeightForExercise(_exercises.first);

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

  /// Go back to warmup phase from active workout
  void _goBackToWarmup() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPhase = WorkoutPhase.warmup;
    });
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

    // Store as pending - we'll finalize after RIR input
    _pendingSetLog = setLog;

    // Use HapticService for satisfying set completion feedback
    HapticService.setCompletion();
    _lastSetCompletedAt = DateTime.now();

    // Finalize the set
    _finalizeSetWithRpe();
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

    // Check for PRs
    final currentExercise = _exercises[_currentExerciseIndex];
    _checkForPRs(finalSetLog, currentExercise);

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
      // Auto-adjust weight if user underperformed (fewer reps than target)
      _autoAdjustWeightIfNeeded(finalSetLog, currentExercise);

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

  /// Auto-adjust weight for next set when user underperforms
  ///
  /// MacroFactor-style: if user completes fewer reps than target,
  /// automatically reduce weight to ensure they can hit targets.
  void _autoAdjustWeightIfNeeded(SetLog setLog, WorkoutExercise exercise) {
    final targetReps = setLog.targetReps > 0 ? setLog.targetReps : (exercise.reps ?? 10);
    final actualReps = setLog.reps;
    final currentWeight = setLog.weight;

    // Skip bodyweight exercises
    if (currentWeight <= 0) return;

    // Only adjust if significantly underperformed
    if (actualReps >= targetReps) return;

    final repRatio = actualReps / targetReps;

    // Determine weight reduction based on how much they underperformed
    double reduction;
    String message;
    if (repRatio < 0.5) {
      reduction = 0.20; // 20% drop - very hard
      message = 'Weight too heavy';
    } else if (repRatio < 0.7) {
      reduction = 0.15; // 15% drop - hard
      message = 'Adjusting weight';
    } else if (repRatio < 0.9) {
      reduction = 0.10; // 10% drop - slightly hard
      message = 'Small adjustment';
    } else {
      return; // Close enough (90%+ reps), no adjustment
    }

    // Calculate new weight rounded to equipment increment
    final equipmentIncrement = WeightIncrements.getIncrement(exercise.equipment);
    final newWeight = (currentWeight * (1 - reduction) / equipmentIncrement).round() * equipmentIncrement;

    // Ensure we don't go below minimum increment
    final adjustedWeight = newWeight.clamp(equipmentIncrement, 999.0);

    // Skip if no real change
    if ((adjustedWeight - currentWeight).abs() < 0.01) return;

    // Update weight controller for next set
    _weightController.text = adjustedWeight.toStringAsFixed(1);

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$message: ${currentWeight.toStringAsFixed(1)} → ${adjustedWeight.toStringAsFixed(1)} kg',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WorkoutDesign.rir2, // Yellow for adjustment
        ),
      );
    }
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

      // Determine if exercise is compound (based on muscle group)
      final muscleGroup = (exercise.muscleGroup ?? exercise.primaryMuscle ?? '').toLowerCase();
      final isCompound = muscleGroup.contains('chest') ||
          muscleGroup.contains('back') ||
          muscleGroup.contains('legs') ||
          muscleGroup.contains('quads') ||
          muscleGroup.contains('hamstrings') ||
          muscleGroup.contains('glutes') ||
          muscleGroup.contains('shoulders');

      final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;
      final setsRemaining = totalSets - completedSets.length;

      final response = await apiClient.dio.post(
        '/workouts/rest-suggestion',
        data: {
          'rpe': _lastSetRpe ?? 7, // Default to 7 if not tracked
          'exercise_type': 'strength',
          'exercise_name': exercise.name,
          'sets_remaining': setsRemaining > 0 ? setsRemaining : 0,
          'sets_completed': completedSets.length,
          'is_compound': isCompound,
          'muscle_group': exercise.muscleGroup ?? exercise.primaryMuscle,
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

      final nextIndex = _currentExerciseIndex + 1;
      final nextExercise = _exercises[nextIndex];

      setState(() {
        _currentExerciseIndex = nextIndex;
        _viewingExerciseIndex = _currentExerciseIndex;
      });

      // Update input controllers for new exercise
      _repsController.text = (nextExercise.reps ?? 10).toString();
      _weightController.text = (nextExercise.weight ?? 0).toString();

      // Fetch smart weight suggestion based on history (background, non-blocking)
      _fetchSmartWeightForExercise(nextExercise);

      // Fetch media for new exercise
      _fetchMediaForExercise(nextExercise);

      // Start rest between exercises
      _startRest(true);

      _currentExerciseStartTime = DateTime.now();
      _lastExerciseStartedAt = DateTime.now();
    } else {
      // All exercises complete - move to stretch phase
      // Celebratory haptic for workout completion
      HapticService.workoutComplete();

      // Check if stretch is enabled
      final stretchEnabled = ref.read(warmupDurationProvider).stretchEnabled;
      if (stretchEnabled) {
        setState(() {
          _currentPhase = WorkoutPhase.stretch;
        });
      } else {
        // Skip stretch and go directly to completion
        debugPrint('🏋️ [ActiveWorkout] Stretch disabled, skipping to completion');
        _handleStretchComplete();
      }
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

  /// Handle tap on background area (no-op since set tracking is full screen)
  void _handleVideoAreaTap() {
    // No action needed - set tracking is always visible
  }

  /// Toggle video play/pause
  void _toggleVideoPlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (_isVideoPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
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
                      'rir': s['rir'] as int?,
                      'rpe': s['rpe'] as int?,
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

  /// Fetch smart weight suggestion for an exercise based on historical data
  ///
  /// This method fetches an AI-powered weight suggestion based on:
  /// - User's 1RM for this exercise (from strength_records)
  /// - Target reps and training goal
  /// - Last session performance (RPE-based modifier)
  /// - Equipment-aware rounding
  ///
  /// The weight controller is updated in the background without blocking UI.
  Future<void> _fetchSmartWeightForExercise(WorkoutExercise exercise) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      final suggestion = await WeightSuggestionService.getSmartWeight(
        dio: apiClient.dio,
        userId: userId,
        exerciseId: exercise.exerciseId ?? exercise.libraryId ?? '',
        exerciseName: exercise.name,
        targetReps: exercise.reps ?? 10,
        goal: TrainingGoal.hypertrophy, // TODO: Get from user settings
        equipment: exercise.equipment ?? 'dumbbell',
      );

      if (mounted && suggestion != null && suggestion.suggestedWeight > 0) {
        // Only update if the fetched weight is different and higher confidence
        final currentWeight = double.tryParse(_weightController.text) ?? 0;
        if (suggestion.isHighConfidence || currentWeight == 0) {
          setState(() {
            _weightController.text = suggestion.suggestedWeight.toStringAsFixed(1);
          });
          debugPrint('✅ [SmartWeight] ${exercise.name}: ${suggestion.suggestedWeight}kg '
              '(confidence: ${(suggestion.confidence * 100).toInt()}%, '
              'source: ${suggestion.reasoning})');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmartWeight] Failed for ${exercise.name}: $e');
      // Fall back to planned weight - already set in controller
    }
  }

  /// Preload PR history for all exercises
  Future<void> _preloadPRHistory() async {
    try {
      await _prDetectionService.preloadExerciseHistory(
        ref: ref,
        exercises: _exercises,
      );
      debugPrint('✅ [PR] Preloaded exercise history for PR detection');
    } catch (e) {
      debugPrint('❌ [PR] Error preloading PR history: $e');
    }
  }

  /// Load coach persona from AI settings
  void _loadCoachPersona() {
    final aiSettings = ref.read(aiSettingsProvider);
    if (aiSettings.coachPersonaId != null) {
      // Try to find predefined coach
      final predefined = CoachPersona.findById(aiSettings.coachPersonaId);
      if (predefined != null) {
        setState(() => _coachPersona = predefined);
      } else if (aiSettings.isCustomCoach) {
        // Create custom coach from settings
        setState(() => _coachPersona = CoachPersona.custom(
          name: aiSettings.coachName ?? 'My Coach',
          coachingStyle: aiSettings.coachingStyle,
          communicationTone: aiSettings.communicationTone,
          encouragementLevel: aiSettings.encouragementLevel,
        ));
      }
    } else {
      // Default to Coach Mike
      setState(() => _coachPersona = CoachPersona.defaultCoach);
    }
  }

  /// Check for PRs after completing a set
  void _checkForPRs(SetLog setLog, WorkoutExercise exercise) {
    // Calculate total volume for the exercise
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];
    double totalVolume = 0;
    for (final set in completedSets) {
      totalVolume += set.weight * set.reps;
    }

    final detectedPRs = _prDetectionService.checkForPR(
      exerciseName: exercise.name,
      weight: setLog.weight,
      reps: setLog.reps,
      totalSets: completedSets.length,
      totalVolume: totalVolume,
    );

    if (detectedPRs.isEmpty) return;

    debugPrint('🏆 [PR] Detected ${detectedPRs.length} PR(s)!');

    // Trigger haptics
    _prDetectionService.triggerHaptics(detectedPRs);

    // Show celebration for the first PR that should be celebrated
    for (final pr in detectedPRs) {
      if (_prDetectionService.shouldShowCelebration(pr)) {
        _prDetectionService.recordCelebration();
        _prDetectionService.updateCacheAfterPR(pr);

        // Show appropriate celebration
        if (detectedPRs.length > 1) {
          _showMultiPRCelebration(detectedPRs);
        } else {
          _showSinglePRCelebration(pr);
        }
        break; // Only show one celebration
      }
    }
  }

  /// Show single PR inline celebration
  void _showSinglePRCelebration(DetectedPR pr) {
    showPRInlineCelebration(
      context: context,
      pr: pr,
      onDismiss: () {
        debugPrint('✨ [PR] Celebration dismissed');
      },
    );
  }

  /// Show multi-PR celebration
  void _showMultiPRCelebration(List<DetectedPR> prs) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => MultiPRInlineCelebration(
        prs: prs,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
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

  void _showQuitDialog() async {
    // Calculate progress for the dialog
    final totalSetsExpected = _totalSetsPerExercise.values.fold<int>(0, (sum, sets) => sum + sets);
    final totalCompletedSets = _completedSets.values.fold<int>(0, (sum, sets) => sum + sets.length);
    final exercisesWithCompletedSets = _completedSets.values.where((sets) => sets.isNotEmpty).length;

    // Calculate progress percentage
    final progressPercent = totalSetsExpected > 0
        ? ((totalCompletedSets / totalSetsExpected) * 100).round()
        : 0;

    final result = await showQuitWorkoutDialog(
      context: context,
      progressPercent: progressPercent,
      totalCompletedSets: totalCompletedSets,
      exercisesWithCompletedSets: exercisesWithCompletedSets,
      timeSpentSeconds: _timerController.workoutSeconds,
      coachPersona: ref.read(aiSettingsProvider).getCurrentCoach(),
      workoutName: widget.workout.name,
    );

    if (result != null && mounted) {
      // User confirmed quit - log the exit and navigate away
      await _logWorkoutExit(result.reason, result.notes);
      if (mounted) {
        context.pop();
      }
    }
    // If result is null, user chose to continue (tapped "Keep Going")
  }

  /// Log workout exit when user quits early
  Future<void> _logWorkoutExit(String reason, String? notes) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (widget.workout.id != null && userId != null) {
        final totalCompletedSets = _completedSets.values.fold<int>(0, (sum, sets) => sum + sets.length);
        final exercisesWithSets = _completedSets.values.where((sets) => sets.isNotEmpty).length;
        final progressPercentage = _exercises.isNotEmpty
            ? (exercisesWithSets / _exercises.length * 100)
            : 0.0;

        await workoutRepo.logWorkoutExit(
          workoutId: widget.workout.id!,
          userId: userId,
          exitReason: reason,
          exercisesCompleted: exercisesWithSets,
          totalExercises: _exercises.length,
          setsCompleted: totalCompletedSets,
          timeSpentSeconds: _timerController.workoutSeconds,
          progressPercentage: progressPercentage,
          exitNotes: notes,
        );
        debugPrint('✅ [Quit] Logged workout exit: $reason');
      }
    } catch (e) {
      debugPrint('❌ [Quit] Failed to log workout exit: $e');
    }
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark),
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.pureBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark)),
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
            child: Text('OK',
                style: TextStyle(
                    color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark), fontWeight: FontWeight.bold)),
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
        // Use V2 MacroFactor-style design
        if (_useV2Design) {
          return _buildActiveWorkoutScreenV2(isDark, backgroundColor);
        }
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
            // Background media (tappable - minimizes overlay or toggles video)
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleVideoAreaTap,
                behavior: HitTestBehavior.opaque,
                child: _buildMediaBackground(),
              ),
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
                  // Ask AI Coach button with coach persona (reactive to changes)
                  onAskAICoach: () => _showAICoachSheet(currentExercise),
                  coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
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

            // Set tracking overlay - full screen (no floating card, no minimize)
            if (!_isResting)
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).padding.top + 70,
                bottom: 90, // Leave space for bottom bar
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
                  onClose: () {}, // No close needed for full screen
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
                  onUpdateSet: (index, weight, reps) => _updateCompletedSet(index, weight, reps),
                  onDeleteSet: (index) => _deleteCompletedSet(index),
                  onQuickCompleteSet: (index, complete) => _quickCompleteSet(index, complete),
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
                  onOpenExerciseOptions: () => _showExerciseOptionsSheet(_viewingExerciseIndex),
                  isMinimized: false, // Always expanded
                  onMinimizedChanged: null, // No minimize needed
                  lastSessionData: _getLastSessionData(_viewingExerciseIndex),
                  prData: _getPrData(_viewingExerciseIndex),
                  currentWeightIncrement: _weightIncrement,
                  onWeightIncrementChanged: (value) =>
                      setState(() => _weightIncrement = value),
                  currentProgressionType: (_repProgressionPerExercise[_viewingExerciseIndex] ?? RepProgressionType.straight).displayName,
                  onOpenProgressionPicker: () => _showProgressionPicker(_viewingExerciseIndex),
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
                  coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
                  onShowExerciseInfo: () => showExerciseInfoSheet(
                    context: context,
                    exercise: currentExercise,
                  ),
                ),
              ),

            // Floating AI Coach FAB (visible when not resting, not hidden for session, and enabled in settings)
            if (!_isResting && !_hideAICoachForSession && ref.watch(aiSettingsProvider).showAICoachDuringWorkouts)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 90,
                right: 20,
                child: _buildFloatingAICoachButton(currentExercise),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBackground() {
    // Simple solid background - no video/GIF in background to keep UI clean
    // User can tap "Instructions" button to see exercise video on-demand
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.pureBlack : Colors.grey.shade100,
    );
  }

  // ========================================================================
  // V2 MACROFACTOR-STYLE BUILD METHODS
  // ========================================================================

  /// Build the V2 MacroFactor-style active workout screen
  Widget _buildActiveWorkoutScreenV2(bool isDark, Color backgroundColor) {
    final currentExercise = _exercises[_currentExerciseIndex];
    final nextExercise = _currentExerciseIndex < _exercises.length - 1
        ? _exercises[_currentExerciseIndex + 1]
        : null;

    // Get set data for current exercise
    final setRows = _buildSetRowsForExercise(_viewingExerciseIndex);
    final completedExerciseIndices = _getCompletedExerciseIndices();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showQuitDialog();
        }
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
        backgroundColor: isDark ? WorkoutDesign.background : Colors.grey.shade50,
        body: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // V2 Top bar
                Consumer(
                  builder: (context, ref, _) {
                    final warmupEnabled = ref.watch(warmupDurationProvider).warmupEnabled;
                    return WorkoutTopBarV2(
                      workoutSeconds: _timerController.workoutSeconds,
                      restSecondsRemaining: _isResting ? _timerController.restSecondsRemaining : null,
                      totalRestSeconds: _isResting ? _timerController.initialRestDuration : null,
                      isPaused: _isPaused,
                      showBackButton: warmupEnabled,
                      onMenuTap: _showWorkoutPlanDrawer,
                      onBackTap: warmupEnabled ? _goBackToWarmup : null,
                      onCloseTap: _showQuitDialog,
                      onTimerTap: _togglePause,
                    );
                  },
                ),

                // Swipeable exercise content area
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // Swipe left (next exercise) - negative velocity
                      if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                        if (_viewingExerciseIndex < _exercises.length - 1) {
                          HapticFeedback.selectionClick();
                          setState(() => _viewingExerciseIndex++);
                        }
                      }
                      // Swipe right (previous exercise) - positive velocity
                      else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                        if (_viewingExerciseIndex > 0) {
                          HapticFeedback.selectionClick();
                          setState(() => _viewingExerciseIndex--);
                        }
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise title and set counter
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _exercises[_viewingExerciseIndex].name,
                                style: WorkoutDesign.titleStyle.copyWith(
                                  color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set ${(_completedSets[_viewingExerciseIndex]?.length ?? 0) + 1} of ${_totalSetsPerExercise[_viewingExerciseIndex] ?? 3}',
                                style: WorkoutDesign.subtitleStyle.copyWith(
                                  color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action chips row
                        ActionChipsRow(
                          chips: _buildActionChipsForCurrentExercise(),
                          onChipTapped: _handleChipTapped,
                          showAiChip: true,
                          hasAiNotification: _currentWeightSuggestion != null,
                          onAiChipTapped: () => _showAICoachSheet(currentExercise),
                        ),

                        const SizedBox(height: 8),

                        // Set tracking table
                        Expanded(
                          child: SingleChildScrollView(
                            child: SetTrackingTable(
                              exercise: _exercises[_viewingExerciseIndex],
                              sets: setRows,
                              useKg: _useKg,
                              activeSetIndex: _completedSets[_viewingExerciseIndex]?.length ?? 0,
                              weightController: _weightController,
                              repsController: _repsController,
                              onSetCompleted: _handleSetCompletedV2,
                              onSetUpdated: _updateCompletedSet,
                              onAddSet: () => setState(() {
                                _totalSetsPerExercise[_viewingExerciseIndex] =
                                    (_totalSetsPerExercise[_viewingExerciseIndex] ?? 3) + 1;
                              }),
                              isLeftRightMode: _isLeftRightMode,
                              allSetsCompleted: _isExerciseCompleted(_viewingExerciseIndex),
                              onSelectAllTapped: () {
                                // Toggle all sets completed
                                if (_isExerciseCompleted(_viewingExerciseIndex)) {
                                  // Already complete - do nothing or show message
                                  HapticFeedback.lightImpact();
                                }
                              },
                              onSetDeleted: (index) => _deleteCompletedSet(index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Exercise thumbnail strip (bottom navigation style)
                // Exercise thumbnail strip with accent top border
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    // Get dynamic accent color from provider
                    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Accent top border (uses selected accent color)
                        Container(
                          height: 3,
                          color: accentColor,
                        ),
                        // Thumbnail strip container
                        Container(
                          color: isDark ? WorkoutDesign.surface : Colors.white,
                          child: SafeArea(
                            top: false,
                            child: ExerciseThumbnailStripV2(
                              exercises: _exercises,
                              currentIndex: _viewingExerciseIndex,
                              completedExercises: completedExerciseIndices,
                              onExerciseTap: (index) {
                                HapticFeedback.selectionClick();
                                setState(() => _viewingExerciseIndex = index);
                              },
                              onAddTap: () => _showExerciseAddSheet(),
                              showAddButton: true,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            // Rest overlay (shows on top)
            if (_isResting)
              Positioned.fill(
                child: RestTimerOverlay(
                  restSecondsRemaining: _timerController.restSecondsRemaining,
                  initialRestDuration: _timerController.initialRestDuration,
                  restMessage: _currentRestMessage,
                  currentExercise: currentExercise,
                  completedSetsCount: _completedSets[_currentExerciseIndex]?.length ?? 0,
                  totalSets: _totalSetsPerExercise[_currentExerciseIndex] ?? 3,
                  nextExercise: nextExercise,
                  isRestBetweenExercises: _isRestingBetweenExercises,
                  onSkipRest: () => _timerController.skipRest(),
                  onLog1RM: () => _showLog1RMSheet(currentExercise),
                  weightSuggestion: _currentWeightSuggestion,
                  isLoadingWeightSuggestion: _isLoadingWeightSuggestion,
                  onAcceptWeightSuggestion: _acceptWeightSuggestion,
                  onDismissWeightSuggestion: _dismissWeightSuggestion,
                  restSuggestion: _restSuggestion,
                  isLoadingRestSuggestion: _isLoadingRestSuggestion,
                  onAcceptRestSuggestion: _acceptRestSuggestion,
                  onDismissRestSuggestion: _dismissRestSuggestion,
                  currentRpe: _lastSetRpe,
                  currentRir: _lastSetRir,
                  onRpeChanged: (rpe) => setState(() => _lastSetRpe = rpe),
                  onRirChanged: (rir) => setState(() => _lastSetRir = rir),
                  lastSetReps: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.reps
                      : null,
                  lastSetTargetReps: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.targetReps
                      : null,
                  lastSetWeight: _completedSets[_currentExerciseIndex]?.isNotEmpty == true
                      ? _completedSets[_currentExerciseIndex]!.last.weight
                      : null,
                  onAskAICoach: () => _showAICoachSheet(currentExercise),
                  coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
                ),
              ),

            // Fatigue alert modal
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

            // Floating AI Coach FAB (positioned above thumbnail strip)
            if (!_isResting && !_hideAICoachForSession && ref.watch(aiSettingsProvider).showAICoachDuringWorkouts)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 100, // Above thumbnail strip (~80px height + padding)
                right: 20,
                child: _buildFloatingAICoachButton(currentExercise),
              ),
          ],
        ),
      );
        },
      ),
    );
  }

  /// Build set row data for the V2 table
  List<SetRowData> _buildSetRowsForExercise(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final totalSets = _totalSetsPerExercise[exerciseIndex] ?? exercise.sets ?? 3;
    final completedSets = _completedSets[exerciseIndex] ?? [];
    final previousSets = _previousSets[exerciseIndex] ?? [];
    final setTargets = exercise.setTargets ?? [];

    final List<SetRowData> rows = [];

    for (int i = 0; i < totalSets; i++) {
      final isCompleted = i < completedSets.length;
      final isActive = i == completedSets.length && exerciseIndex == _currentExerciseIndex;

      // Get target data from AI
      SetTarget? setTarget;
      if (i < setTargets.length) {
        setTarget = setTargets[i];
      }

      // Get previous session data
      double? prevWeight;
      int? prevReps;
      int? prevRir;
      if (i < previousSets.length) {
        prevWeight = (previousSets[i]['weight'] as num?)?.toDouble();
        prevReps = previousSets[i]['reps'] as int?;
        prevRir = previousSets[i]['rir'] as int?;
      }

      // Get actual values if completed
      double? actualWeight;
      int? actualReps;
      if (isCompleted) {
        actualWeight = completedSets[i].weight;
        actualReps = completedSets[i].reps;
      }

      rows.add(SetRowData(
        setNumber: i + 1,
        isWarmup: setTarget?.isWarmup ?? false,
        isCompleted: isCompleted,
        isActive: isActive,
        targetWeight: setTarget?.targetWeightKg ?? prevWeight ?? exercise.weight?.toDouble(),
        targetReps: setTarget?.targetReps != null ? setTarget!.targetReps.toString() : '${exercise.reps ?? 8}-${(exercise.reps ?? 8) + 2}',
        targetRir: setTarget?.targetRir ?? 2,
        actualWeight: actualWeight,
        actualReps: actualReps,
        previousWeight: prevWeight,
        previousReps: prevReps,
        previousRir: prevRir,
      ));
    }

    return rows;
  }

  /// Get completed exercise indices
  Set<int> _getCompletedExerciseIndices() {
    final completed = <int>{};
    for (int i = 0; i < _exercises.length; i++) {
      if (_isExerciseCompleted(i)) {
        completed.add(i);
      }
    }
    return completed;
  }

  /// Check if exercise is completed
  bool _isExerciseCompleted(int exerciseIndex) {
    final completedCount = _completedSets[exerciseIndex]?.length ?? 0;
    final totalSets = _totalSetsPerExercise[exerciseIndex] ?? 3;
    return completedCount >= totalSets;
  }

  /// Build action chips for current exercise
  List<ActionChipData> _buildActionChipsForCurrentExercise() {
    return [
      WorkoutActionChips.info,
      WorkoutActionChips.warmUp,
      WorkoutActionChips.targets,
      WorkoutActionChips.swap,
      WorkoutActionChips.note,
      WorkoutActionChips.superset,
      WorkoutActionChips.equipment,
      WorkoutActionChips.increments,
      WorkoutActionChips.video,
      WorkoutActionChips.history,
      WorkoutActionChips.leftRight(isActive: _isLeftRightMode),
    ];
  }

  /// Handle chip tapped
  void _handleChipTapped(String chipId) {
    HapticFeedback.selectionClick();
    final currentExercise = _exercises[_viewingExerciseIndex];

    switch (chipId) {
      case 'info':
        showExerciseInfoSheet(
          context: context,
          exercise: currentExercise,
        );
        break;
      case 'warmup':
        // Show warmup info or toggle warmup sets
        _showWarmupSheet(currentExercise);
        break;
      case 'targets':
        // Show targets info
        _showTargetsSheet(currentExercise);
        break;
      case 'swap':
        _showExerciseOptionsSheet(_viewingExerciseIndex);
        break;
      case 'note':
        // Show notes sheet
        _showNotesSheet(currentExercise);
        break;
      case 'superset':
        // Show superset pairing
        _showSupersetSheet();
        break;
      case 'equipment':
        // Show equipment requirements
        _showEquipmentSheet(currentExercise);
        break;
      case 'video':
        // Show exercise video
        showExerciseInfoSheet(
          context: context,
          exercise: currentExercise,
        );
        break;
      case 'history':
        // Show exercise history
        _showHistorySheet(currentExercise);
        break;
      case 'lr':
        setState(() => _isLeftRightMode = !_isLeftRightMode);
        break;
      case 'increments':
        _showWeightIncrementsSheet();
        break;
    }
  }

  /// Show weight increments sheet
  void _showWeightIncrementsSheet() {
    showWeightIncrementsSheet(context);
  }

  /// Show warmup sheet
  void _showWarmupSheet(WorkoutExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(
        title: 'Warm Up',
        content: 'Warming up helps prevent injury and improves performance.\n\nRecommended: 1-2 lighter sets before working sets.',
        icon: Icons.whatshot_outlined,
      ),
    );
  }

  /// Show targets sheet
  void _showTargetsSheet(WorkoutExercise exercise) {
    final setTargets = exercise.setTargets ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? WorkoutDesign.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Set Targets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (setTargets.isEmpty)
                Text(
                  'AI targets will be generated based on your history.',
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                  ),
                )
              else
                ...setTargets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final target = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Set ${i + 1}: ${target.targetWeightKg?.toStringAsFixed(1) ?? '-'} kg × ${target.targetReps ?? '-'} @ ${target.targetRir ?? '-'} RIR',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Show notes sheet
  void _showNotesSheet(WorkoutExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? WorkoutDesign.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sticky_note_2_outlined, color: WorkoutDesign.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Exercise Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add notes about form, cues, or modifications...',
                    filled: true,
                    fillColor: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show superset sheet
  void _showSupersetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(
        title: 'Superset',
        content: 'Superset this exercise with another to save time.\n\nPair with previous or next exercise in your workout.',
        icon: Icons.repeat,
      ),
    );
  }

  /// Show equipment sheet
  void _showEquipmentSheet(WorkoutExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(
        title: 'Equipment',
        content: 'Required: ${exercise.equipment ?? 'Bodyweight'}\n\nNo equipment? Tap Swap to find alternatives.',
        icon: Icons.fitness_center,
      ),
    );
  }

  /// Show history sheet
  void _showHistorySheet(WorkoutExercise exercise) {
    final previousSets = _previousSets[_viewingExerciseIndex] ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? WorkoutDesign.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Last Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (previousSets.isEmpty)
                Text(
                  'No previous data for this exercise.',
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                  ),
                )
              else
                ...previousSets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final set = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Set ${i + 1}: ${set['weight']?.toStringAsFixed(1) ?? '-'} kg × ${set['reps'] ?? '-'} reps',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Build a simple info sheet
  Widget _buildInfoSheet({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? WorkoutDesign.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: WorkoutDesign.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Handle set completed from V2 table (checkbox tapped)
  void _handleSetCompletedV2(int setIndex) {
    // If this is the active set, complete it
    final completedCount = _completedSets[_viewingExerciseIndex]?.length ?? 0;

    if (setIndex == completedCount) {
      // Complete the active set
      _completeSet();
    } else if (setIndex < completedCount) {
      // This is a completed set - allow editing
      _editCompletedSet(setIndex);
    }
  }

  /// Show exercise add sheet (placeholder)
  void _showExerciseAddSheet() {
    // TODO: Implement add exercise sheet
    HapticFeedback.lightImpact();
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
              Icon(
                Icons.emoji_events,
                size: 80,
                color: ref.watch(accentColorProvider).getColor(isDark),
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
                  color: ref.watch(accentColorProvider).getColor(isDark),
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
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CompletionStat(
          icon: Icons.fitness_center,
          value: totalSets.toString(),
          label: 'Sets',
          isDark: isDark,
          accentColor: accentColor,
        ),
        _CompletionStat(
          icon: Icons.repeat,
          value: totalReps.toString(),
          label: 'Reps',
          isDark: isDark,
          accentColor: accentColor,
        ),
        _CompletionStat(
          icon: Icons.local_fire_department,
          value: _totalCaloriesBurned.toString(),
          label: 'Calories',
          isDark: isDark,
          accentColor: accentColor,
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
              color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark),
              isDecimal: true,
            ),
            const SizedBox(height: 16),
            NumberInputField(
              controller: editRepsController,
              icon: Icons.repeat,
              hint: 'Reps',
              color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark),
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
            child: Text('Save',
                style: TextStyle(color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark))),
          ),
        ],
      ),
    );
  }

  /// Update a completed set inline (without dialog)
  void _updateCompletedSet(int setIndex, double weight, int reps) {
    if (_completedSets[_viewingExerciseIndex] == null ||
        setIndex < 0 ||
        setIndex >= _completedSets[_viewingExerciseIndex]!.length) {
      return;
    }

    setState(() {
      final existingSet = _completedSets[_viewingExerciseIndex]![setIndex];
      _completedSets[_viewingExerciseIndex]![setIndex] = SetLog(
        reps: reps,
        weight: weight,
        completedAt: existingSet.completedAt,
        setType: existingSet.setType,
      );
    });
  }

  void _deleteCompletedSet(int setIndex) {
    setState(() {
      if (setIndex == -1) {
        // Signal to decrease total sets (remove an empty row)
        final currentTotal = _totalSetsPerExercise[_viewingExerciseIndex] ?? 3;
        final completedCount = _completedSets[_viewingExerciseIndex]?.length ?? 0;
        // Only decrease if there's at least 1 set AND more sets than completed
        if (currentTotal > 1 && currentTotal > completedCount) {
          _totalSetsPerExercise[_viewingExerciseIndex] = currentTotal - 1;
        }
      } else if (_completedSets[_viewingExerciseIndex] != null &&
          setIndex >= 0 &&
          setIndex < _completedSets[_viewingExerciseIndex]!.length) {
        // Remove a specific completed set
        _completedSets[_viewingExerciseIndex]!.removeAt(setIndex);
      }
    });
  }

  /// Quick complete or uncomplete a set by tapping its number
  void _quickCompleteSet(int setIndex, bool complete) {
    setState(() {
      if (complete) {
        // Complete the set - use target/last values or current inputs
        final exercise = _exercises[_viewingExerciseIndex];
        final previousSets = _previousSets[_viewingExerciseIndex] ?? [];

        // Get weight: try input fields first, then target, then previous
        double weight = double.tryParse(_weightController.text) ?? 0;
        if (weight == 0 && exercise.weight != null) {
          weight = exercise.weight!;
        }
        if (weight == 0 && setIndex < previousSets.length) {
          weight = (previousSets[setIndex]['weight'] as double?) ?? 0;
        }

        // Get reps: try input fields first, then target, then previous
        int reps = int.tryParse(_repsController.text) ?? 0;
        if (reps == 0 && exercise.reps != null) {
          reps = exercise.reps!;
        }
        if (reps == 0 && setIndex < previousSets.length) {
          reps = (previousSets[setIndex]['reps'] as int?) ?? 0;
        }

        // Default fallback values if still zero
        if (weight == 0) weight = 20;
        if (reps == 0) reps = 10;

        // Create set log
        final setLog = SetLog(
          weight: weight,
          reps: reps,
          completedAt: DateTime.now(),
          setType: 'working',
          targetReps: exercise.reps ?? reps,
        );

        // Insert at correct position
        _completedSets[_viewingExerciseIndex] ??= [];
        if (setIndex >= _completedSets[_viewingExerciseIndex]!.length) {
          // Append at end
          _completedSets[_viewingExerciseIndex]!.add(setLog);
        } else {
          // Insert at position
          _completedSets[_viewingExerciseIndex]!.insert(setIndex, setLog);
        }

        // Trigger completion animation
        _justCompletedSetIndex = setIndex;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _justCompletedSetIndex = null);
        });
      } else {
        // Uncomplete the set - remove it
        if (_completedSets[_viewingExerciseIndex] != null &&
            setIndex >= 0 &&
            setIndex < _completedSets[_viewingExerciseIndex]!.length) {
          _completedSets[_viewingExerciseIndex]!.removeAt(setIndex);
        }
      }
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

  /// Build floating AI Coach FAB - always visible above bottom bar
  /// Long press to hide for this session
  Widget _buildFloatingAICoachButton(WorkoutExercise currentExercise) {
    // Use ref.watch to reactively update when coach changes
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = aiSettings.getCurrentCoach();

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showHideCoachDialog();
      },
      child: CoachAvatar(
        coach: coach,
        size: 56,
        showBorder: true,
        borderWidth: 3,
        showShadow: true,
        enableTapToView: false,
        onTap: () => _showAICoachSheet(currentExercise),
      ),
    );
  }

  /// Show dialog to confirm hiding AI Coach for this session
  void _showHideCoachDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: ref.watch(accentColorProvider).getColor(isDark),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Hide AI Coach?',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'The AI Coach will be hidden for this workout session. You can still access it from Settings.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _hideAICoachForSession = true;
              });
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('AI Coach hidden for this session'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        _hideAICoachForSession = false;
                      });
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Hide',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

  /// Get last session data for an exercise (from _previousSets)
  Map<String, dynamic>? _getLastSessionData(int exerciseIndex) {
    final previousSets = _previousSets[exerciseIndex];
    if (previousSets == null || previousSets.isEmpty) {
      return null;
    }

    // Get the first set from previous session as "last" data
    final lastSet = previousSets.first;
    final weight = lastSet['weight'] as double?;
    final reps = lastSet['reps'] as int?;
    final date = lastSet['date'] as String?;

    if (weight != null && reps != null) {
      return {
        'weight': weight,
        'reps': reps,
        'date': date,
      };
    }
    return null;
  }

  /// Get PR data for an exercise (from _exerciseMaxWeights)
  Map<String, dynamic>? _getPrData(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return null;

    final exercise = _exercises[exerciseIndex];
    final prWeight = _exerciseMaxWeights[exercise.name];

    if (prWeight != null && prWeight > 0) {
      // We don't store PR reps, so estimate based on typical ranges
      // In a real implementation, you'd store both weight and reps for PR
      return {
        'weight': prWeight,
        'reps': 1, // Placeholder - ideally store actual PR reps
      };
    }
    return null;
  }

  /// Show rep progression picker sheet
  void _showProgressionPicker(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final currentProgression = _repProgressionPerExercise[exerciseIndex] ?? RepProgressionType.straight;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nearBlack : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Change Reps Progression',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Progression options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                children: RepProgressionType.values.map((type) {
                  final isSelected = type == currentProgression;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _repProgressionPerExercise[exerciseIndex] = type;
                        });
                        Navigator.pop(ctx);
                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Changed to ${type.displayName}'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withOpacity(0.1)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.04),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withOpacity(0.2)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                type.icon,
                                color: isSelected ? accentColor : textMuted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? accentColor : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Checkmark if selected
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom padding
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  /// Show exercise options sheet (3-dot menu)
  void _showExerciseOptionsSheet(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return;

    final exercise = _exercises[exerciseIndex];
    final currentProgression = _repProgressionPerExercise[exerciseIndex] ?? RepProgressionType.straight;

    showExerciseOptionsSheet(
      context: context,
      exercise: exercise,
      currentProgression: currentProgression,
      onProgressionChanged: (newProgression) {
        setState(() {
          _repProgressionPerExercise[exerciseIndex] = newProgression;
        });
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changed to ${newProgression.displayName}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReplace: () {
        // TODO: Implement exercise replacement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Replace exercise coming soon'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onViewHistory: () {
        // Open analytics page for this exercise
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseAnalyticsPage(
              exercise: exercise,
              useKg: _useKg,
              lastSessionData: _getLastSessionData(exerciseIndex),
              prData: _getPrData(exerciseIndex),
            ),
          ),
        );
      },
      onViewInstructions: () {
        showExerciseInfoSheet(
          context: context,
          exercise: exercise,
        );
      },
      onAddNotes: () {
        // Notes are handled in the set tracking overlay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use the notes section below the sets'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onRemoveFromWorkout: () {
        _removeExerciseFromWorkout(exerciseIndex);
      },
      onAddToSuperset: () {
        // TODO: Implement superset functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Superset feature coming soon'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onRemoveAndDontRecommend: () {
        _removeExerciseFromWorkout(exerciseIndex);
        // TODO: Add to blacklist for AI recommendations
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${exercise.name} removed and won\'t be recommended'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  /// Remove exercise from workout
  void _removeExerciseFromWorkout(int index) {
    if (_exercises.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last exercise'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final removedExercise = _exercises[index];

    setState(() {
      // Remove exercise and shift data
      _exercises.removeAt(index);

      // Clean up the maps for the deleted exercise
      _completedSets.remove(index);
      _totalSetsPerExercise.remove(index);
      _previousSets.remove(index);
      _repProgressionPerExercise.remove(index);

      // Shift data for exercises after the deleted one
      final newCompletedSets = <int, List<SetLog>>{};
      final newTotalSets = <int, int>{};
      final newPreviousSets = <int, List<Map<String, dynamic>>>{};
      final newRepProgressions = <int, RepProgressionType>{};

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

      _repProgressionPerExercise.forEach((key, value) {
        if (key > index) {
          newRepProgressions[key - 1] = value;
        } else {
          newRepProgressions[key] = value;
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
      _repProgressionPerExercise
        ..clear()
        ..addAll(newRepProgressions);

      // Adjust current index if needed
      if (_currentExerciseIndex >= _exercises.length) {
        _currentExerciseIndex = _exercises.length - 1;
      }
      if (_viewingExerciseIndex >= _exercises.length) {
        _viewingExerciseIndex = _exercises.length - 1;
      }
    });

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedExercise.name} removed'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              // Re-add the exercise at the same index
              _exercises.insert(index, removedExercise);
              // Shift maps back
              // Note: This is a simplified undo - full undo would restore completed sets too
            });
          },
        ),
      ),
    );
  }
}

/// Completion stat widget
class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final Color accentColor;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: accentColor),
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
