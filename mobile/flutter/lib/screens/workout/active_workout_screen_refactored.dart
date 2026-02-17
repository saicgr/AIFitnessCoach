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
import '../../widgets/glass_sheet.dart';
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
import '../../data/providers/xp_provider.dart';
import 'widgets/workout_plan_drawer.dart';
import 'widgets/breathing_guide_sheet.dart';
import 'widgets/hydration_dialog.dart';
import 'widgets/hydration_quick_actions.dart';
import '../../data/models/hydration.dart';
import 'widgets/workout_ai_coach_sheet.dart';
import 'widgets/exercise_info_sheet.dart';
import 'widgets/exercise_options_sheet.dart';
import 'widgets/exercise_analytics_page.dart';
import 'widgets/quit_workout_dialog.dart';
import 'widgets/enhanced_notes_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/ai_text_input_bar.dart';
import 'widgets/parsed_exercises_preview_sheet.dart';
import 'widgets/ai_input_preview_sheet.dart';
import '../../data/models/parsed_exercise.dart';
// MacroFactor-style V2 components
import 'widgets/workout_top_bar_v2.dart';
import 'widgets/exercise_thumbnail_strip_v2.dart';
import 'widgets/action_chips_row.dart';
import 'widgets/set_tracking_table.dart';
import 'widgets/inline_rest_row.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../core/services/fatigue_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/pr_detection_service.dart';
import '../../data/models/coach_persona.dart';
import '../../widgets/coach_avatar.dart';
import 'widgets/pr_inline_celebration.dart';
import '../../core/services/rest_tip_service.dart';
import '../../core/services/achievement_prompt_service.dart';
import '../../core/services/exercise_info_service.dart';
import '../../core/providers/workout_mini_player_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../core/providers/ble_heart_rate_provider.dart';
import '../../data/services/ble_heart_rate_service.dart';
import '../../widgets/heart_rate_display.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../core/providers/tts_provider.dart';
import '../../screens/onboarding/widgets/foldable_quiz_scaffold.dart';
import 'foldable/foldable_workout_layout.dart';
import 'foldable/foldable_warmup_layout.dart';

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
  late TextEditingController _repsRightController; // For L/R mode
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
  int? _lastSetRir = 3; // Default RIR 3 (moderate) for quick-select bar
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

  // Inline rest row state
  bool _showInlineRest = false;
  int _inlineRestDuration = 90; // Default rest duration
  String? _inlineRestAiTip;
  bool _isLoadingAiTip = false;
  String? _inlineRestAchievementPrompt;
  int? _inlineRestCurrentRpe;

  // Warmup/stretch state (fetched from API)
  List<WarmupExerciseData>? _warmupExercises;
  List<StretchExerciseData>? _stretchExercises;
  bool _isLoadingWarmup = true;

  // V2 UI flag - MacroFactor style design
  bool _useV2Design = true;

  // L/R mode for unilateral exercises
  bool _isLeftRightMode = false;

  // Superset round tracking
  // Maps superset group ID -> set of exercise indices that have completed a set in this round
  // Reset when all exercises in the superset complete their set for the round
  final Map<int, Set<int>> _supersetRoundProgress = {};

  // Pre-computed superset indices cache (groupId -> sorted exercise indices)
  // Built once in initState and when exercises change, avoids repeated iteration/sorting
  Map<int, List<int>> _supersetIndicesCache = {};

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
    _loadWarmupAndStretches();
    _checkWarmupEnabled();
    _initBleHrAutoReconnect();
  }

  /// Attempt BLE HR auto-reconnect if enabled.
  void _initBleHrAutoReconnect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bleEnabled = ref.read(bleHrEnabledProvider);
      if (bleEnabled) {
        BleHeartRateService.instance.autoReconnect();
      }
    });
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

    // Pre-compute superset indices cache for O(1) lookups
    _precomputeSupersetIndices();

    // Guard: If no exercises, we cannot proceed
    // Note: Router should catch this case, but keep as a safety check
    if (_exercises.isEmpty) {
      debugPrint('❌ [ActiveWorkout] No exercises in workout! Cannot start.');
      // Initialize with defaults to prevent late init errors
      _repsController = TextEditingController(text: '10');
      _repsRightController = TextEditingController(text: '10');
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

    // Check if we're restoring from mini player
    final miniPlayerState = ref.read(workoutMiniPlayerProvider);
    final isRestoring = miniPlayerState.workout?.id == widget.workout.id &&
        miniPlayerState.workoutSeconds > 0;

    if (isRestoring) {
      debugPrint('🎬 [ActiveWorkout] Restoring from mini player - timer: ${miniPlayerState.workoutSeconds}s, exercise: ${miniPlayerState.currentExerciseIndex}');
    }

    // Initialize input controllers
    final initialExerciseIndex = isRestoring ? miniPlayerState.currentExerciseIndex : 0;
    final initialExercise = _exercises[initialExerciseIndex.clamp(0, _exercises.length - 1)];
    // Use setTargets for initial values if available, fallback to legacy fields
    final firstSetTarget = initialExercise.getTargetForSet(1);
    _repsController = TextEditingController(
        text: (firstSetTarget?.targetReps ?? initialExercise.reps ?? 10).toString());
    _repsRightController = TextEditingController(
        text: (firstSetTarget?.targetReps ?? initialExercise.reps ?? 10).toString()); // Same initial reps for L/R
    _weightController = TextEditingController(
        text: (firstSetTarget?.targetWeightKg ?? initialExercise.weight ?? 0).toString());

    // Restore exercise index if restoring
    if (isRestoring) {
      _currentExerciseIndex = miniPlayerState.currentExerciseIndex.clamp(0, _exercises.length - 1);
      _viewingExerciseIndex = _currentExerciseIndex;
      _isPaused = miniPlayerState.isPaused;
      _isResting = miniPlayerState.isResting;
      // Skip warmup phase when restoring - go directly to active workout
      _currentPhase = WorkoutPhase.active;
    }

    // Initialize timer controller
    _timerController = WorkoutTimerController();
    _timerController.onWorkoutTick = (_) => setState(() {});
    _timerController.onRestTick = (secondsRemaining) {
      setState(() {});
      // Play countdown sound + voice at 3, 2, 1
      if (secondsRemaining <= 3 && secondsRemaining > 0) {
        ref.read(soundPreferencesProvider.notifier).playCountdown(secondsRemaining);
        ref.read(voiceAnnouncementsProvider.notifier).announceCountdownIfEnabled(secondsRemaining);
      }
    };
    _timerController.onRestComplete = _handleRestComplete;

    // Initialize PR detection service
    _prDetectionService = ref.read(prDetectionServiceProvider);
    _prDetectionService.startNewWorkout();
    _preloadPRHistory();

    // Load coach persona for AI Coach button
    _loadCoachPersona();

    // Start workout timer (restore time if returning from mini player)
    _timerController.startWorkoutTimer(initialSeconds: isRestoring ? miniPlayerState.workoutSeconds : 0);

    // Announce workout start (only for fresh workouts, not restores)
    if (!isRestoring) {
      ref.read(voiceAnnouncementsProvider.notifier)
          .announceIfEnabled("Let's go! Starting ${widget.workout.name}");
    }

    // Restore rest timer if was resting
    if (isRestoring && miniPlayerState.isResting && miniPlayerState.restSecondsRemaining > 0) {
      _timerController.startRestTimer(miniPlayerState.restSecondsRemaining);
    }

    // Initialize tracking data
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      // Use setTargets length if available (includes warmup sets), otherwise fall back to exercise.sets
      _totalSetsPerExercise[i] = exercise.hasSetTargets && exercise.setTargets!.isNotEmpty
          ? exercise.setTargets!.length
          : exercise.sets ?? 3;
      _previousSets[i] = [];
    }

    // Restore completed sets if restoring from mini player
    if (isRestoring && miniPlayerState.completedSets.isNotEmpty) {
      for (final entry in miniPlayerState.completedSets.entries) {
        final exerciseIndex = entry.key;
        final setMaps = entry.value;
        if (exerciseIndex < _exercises.length) {
          _completedSets[exerciseIndex] = setMaps.map((map) => SetLog(
            reps: (map['reps'] as num?)?.toInt() ?? 0,
            weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
            setType: map['setType'] as String? ?? 'working',
            rpe: (map['rpe'] as num?)?.toInt(),
            rir: (map['rir'] as num?)?.toInt(),
            aiInputSource: map['aiInputSource'] as String?,
          )).toList();
        }
      }
      debugPrint('🎬 [ActiveWorkout] Restored ${miniPlayerState.completedSets.length} exercise completed sets');
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
            inclinePercent: (e['incline_percent'] as num?)?.toDouble(),
            speedMph: (e['speed_mph'] as num?)?.toDouble(),
            rpm: (e['rpm'] as num?)?.toInt(),
            resistanceLevel: (e['resistance_level'] as num?)?.toInt(),
            strokeRateSpm: (e['stroke_rate_spm'] as num?)?.toInt(),
            equipment: e['equipment']?.toString(),
          )).toList();
        }

        if (stretchData.isNotEmpty) {
          _stretchExercises = stretchData.map<StretchExerciseData>((e) => StretchExerciseData(
            name: e['name']?.toString() ?? 'Stretch',
            duration: (e['duration_seconds'] as num?)?.toInt() ?? 30,
            icon: _getIconForStretch(e['name']?.toString() ?? ''),
            inclinePercent: (e['incline_percent'] as num?)?.toDouble(),
            speedMph: (e['speed_mph'] as num?)?.toDouble(),
            rpm: (e['rpm'] as num?)?.toInt(),
            resistanceLevel: (e['resistance_level'] as num?)?.toInt(),
            strokeRateSpm: (e['stroke_rate_spm'] as num?)?.toInt(),
            equipment: e['equipment']?.toString(),
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
    _repsRightController.dispose();
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
    final currentExercise = _exercises[_currentExerciseIndex];
    final groupId = currentExercise.supersetGroup;

    setState(() {
      _isResting = false;
      _isRestingBetweenExercises = false;
      // Hide inline rest row and clear its state
      _showInlineRest = false;
      _inlineRestAiTip = null;
      _inlineRestAchievementPrompt = null;
    });
    HapticFeedback.heavyImpact();

    // Play rest end sound + voice announcement
    ref.read(soundPreferencesProvider.notifier).playRestTimerEnd();
    ref.read(voiceAnnouncementsProvider.notifier).announceRestEndIfEnabled();

    // If we're in a superset, navigate to the first exercise in the superset
    // that still has sets remaining
    if (groupId != null && currentExercise.isInSuperset) {
      final supersetIndices = _getSupersetIndices(groupId);
      for (final idx in supersetIndices) {
        if (!_isExerciseCompleted(idx)) {
          // Found the first superset exercise with sets remaining
          if (idx != _currentExerciseIndex) {
            _advanceToSupersetExercise(idx);
          }
          return;
        }
      }
    }
  }

  // ========================================================================
  // WORKOUT LOGIC
  // ========================================================================

  void _completeSet() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final exercise = _exercises[_currentExerciseIndex];
    // Get target reps from setTargets based on current set number
    final currentSetNumber = (_completedSets[_currentExerciseIndex]?.length ?? 0) + 1;
    final setTarget = exercise.getTargetForSet(currentSetNumber);
    final targetReps = setTarget?.targetReps ?? exercise.reps ?? 10;

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
    showGlassSheet(
      context: context,
      isDismissible: false, // Force user to respond
      enableDrag: false,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
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

    // Update data outside setState - only trigger rebuild for animation
    _completedSets[_currentExerciseIndex] ??= [];
    _completedSets[_currentExerciseIndex]!.add(finalSetLog);
    setState(() {
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
      // Play exercise completion sound
      ref.read(soundPreferencesProvider.notifier).playExerciseCompletion();

      // Exercise complete - move to next or finish
      // If in superset, check if we need to continue the round first
      final groupId = currentExercise.supersetGroup;
      if (groupId != null && currentExercise.isInSuperset) {
        // Mark this exercise done in the round
        _markSupersetExerciseDoneInRound(_currentExerciseIndex, groupId);

        // Check if there are more exercises in the superset to do
        final nextSupersetIdx = _getNextSupersetExerciseIndex(_currentExerciseIndex, groupId);
        if (nextSupersetIdx != null) {
          // More superset exercises to do - advance without rest
          _advanceToSupersetExercise(nextSupersetIdx);
        } else {
          // Superset round complete - reset and start rest before moving to next exercise
          _resetSupersetRound(groupId);
          _moveToNextExercise();
        }
      } else {
        _moveToNextExercise();
      }
    } else {
      // Auto-adjust weight if user underperformed (fewer reps than target)
      _autoAdjustWeightIfNeeded(finalSetLog, currentExercise);

      // Check if exercise is in a superset
      final groupId = currentExercise.supersetGroup;
      if (groupId != null && currentExercise.isInSuperset) {
        // Mark this exercise done in the round
        _markSupersetExerciseDoneInRound(_currentExerciseIndex, groupId);

        // Check if there are more exercises in the superset to do this round
        final nextSupersetIdx = _getNextSupersetExerciseIndex(_currentExerciseIndex, groupId);
        if (nextSupersetIdx != null) {
          // More superset exercises to do - advance without rest
          _advanceToSupersetExercise(nextSupersetIdx);
        } else {
          // Superset round complete - reset progress and start rest
          _resetSupersetRound(groupId);
          _startRest(false);

          // Fetch AI-powered suggestions during rest
          _fetchAIWeightSuggestion(finalSetLog);
          _fetchRestSuggestion();
          _checkFatigue();
        }
      } else {
        // Not in a superset - normal flow
        _startRest(false);

        // Fetch AI-powered suggestions during rest
        _fetchAIWeightSuggestion(finalSetLog);
        _fetchRestSuggestion();
        _checkFatigue();
      }
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

  // ========================================================================
  // SUPERSET WORKOUT FLOW
  // ========================================================================

  /// Pre-compute superset indices for all groups.
  /// Called once in initState and whenever _exercises changes.
  void _precomputeSupersetIndices() {
    _supersetIndicesCache = {};
    for (int i = 0; i < _exercises.length; i++) {
      final groupId = _exercises[i].supersetGroup;
      if (groupId != null) {
        _supersetIndicesCache.putIfAbsent(groupId, () => <int>[]);
        _supersetIndicesCache[groupId]!.add(i);
      }
    }
    // Sort each group by superset order
    for (final entry in _supersetIndicesCache.entries) {
      entry.value.sort((a, b) {
        final orderA = _exercises[a].supersetOrder ?? 0;
        final orderB = _exercises[b].supersetOrder ?? 0;
        return orderA.compareTo(orderB);
      });
    }
  }

  /// Get all exercise indices in a superset group (returns from pre-computed cache)
  List<int> _getSupersetIndices(int groupId) {
    return _supersetIndicesCache[groupId] ?? [];
  }

  /// Get the next exercise index in the superset round
  /// Returns null if this was the last exercise in the round (all done)
  int? _getNextSupersetExerciseIndex(int currentIndex, int groupId) {
    final supersetIndices = _getSupersetIndices(groupId);
    if (supersetIndices.isEmpty) return null;

    // Get which exercises have been done in this round
    final doneInRound = _supersetRoundProgress[groupId] ?? <int>{};

    // Find the next exercise in the superset that hasn't been done this round
    // and still has sets remaining
    for (final idx in supersetIndices) {
      if (idx != currentIndex &&
          !doneInRound.contains(idx) &&
          !_isExerciseCompleted(idx)) {
        return idx;
      }
    }

    return null; // All superset exercises done for this round
  }

  /// Mark an exercise as done for the current superset round
  void _markSupersetExerciseDoneInRound(int exerciseIndex, int groupId) {
    _supersetRoundProgress[groupId] ??= <int>{};
    _supersetRoundProgress[groupId]!.add(exerciseIndex);
    debugPrint('🔗 [Superset] Marked exercise $exerciseIndex done in round for group $groupId. Progress: ${_supersetRoundProgress[groupId]}');
  }

  /// Reset the superset round progress when all exercises have completed their set
  void _resetSupersetRound(int groupId) {
    _supersetRoundProgress[groupId] = <int>{};
    debugPrint('🔗 [Superset] Reset round progress for group $groupId');
  }

  /// Navigate to the next exercise in the superset (no rest timer)
  void _advanceToSupersetExercise(int nextIndex) {
    debugPrint('🔗 [Superset] Auto-advancing to exercise $nextIndex: ${_exercises[nextIndex].name}');

    // Track time for current exercise
    if (_currentExerciseStartTime != null) {
      _exerciseTimeSeconds[_currentExerciseIndex] =
          DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
    }

    final nextExercise = _exercises[nextIndex];

    // Haptic feedback for exercise transition (lighter than normal)
    HapticFeedback.selectionClick();

    setState(() {
      _currentExerciseIndex = nextIndex;
      _viewingExerciseIndex = nextIndex;
      // Don't start rest - we're continuing the superset
      _isResting = false;
      _showInlineRest = false;
    });

    // Update input controllers for new exercise (use setTargets if available)
    final firstSetTarget = nextExercise.getTargetForSet(1);
    _repsController.text = (firstSetTarget?.targetReps ?? nextExercise.reps ?? 10).toString();
    _repsRightController.text = (firstSetTarget?.targetReps ?? nextExercise.reps ?? 10).toString(); // Sync L/R
    _weightController.text = (firstSetTarget?.targetWeightKg ?? nextExercise.weight ?? 0).toString();

    // Fetch smart weight suggestion based on history (background, non-blocking)
    _fetchSmartWeightForExercise(nextExercise);

    // Fetch media for new exercise
    _fetchMediaForExercise(nextExercise);

    _currentExerciseStartTime = DateTime.now();
    _lastExerciseStartedAt = DateTime.now();

    // Show brief feedback
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Superset: ${nextExercise.name}')),
          ],
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.purple,
      ),
    );
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
      // Show inline rest row (only between sets, not between exercises)
      _showInlineRest = !betweenExercises;
      _inlineRestDuration = restSeconds;
      _inlineRestCurrentRpe = null; // Reset for new rest period
    });

    debugPrint('🔴 [StartRest] betweenExercises=$betweenExercises, _showInlineRest=$_showInlineRest, _isResting=$_isResting');

    _timerController.startRestTimer(restSeconds);

    // Fetch AI tip and achievement prompt for inline rest
    if (!betweenExercises) {
      debugPrint('🔴 [StartRest] Fetching AI tip and achievement prompt');
      _fetchInlineRestAiTip(exercise);
      _fetchInlineRestAchievementPrompt(exercise);
    }

    // Track rest interval
    _restIntervals.add({
      'exercise_id': _exercises[_currentExerciseIndex].id,
      'exercise_name': _exercises[_currentExerciseIndex].name,
      'rest_seconds': restSeconds,
      'rest_type': betweenExercises ? 'between_exercises' : 'between_sets',
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch AI tip for inline rest row
  Future<void> _fetchInlineRestAiTip(WorkoutExercise exercise) async {
    final exerciseSets = _completedSets[_currentExerciseIndex];
    if (exerciseSets == null || exerciseSets.isEmpty) return;

    final lastSet = exerciseSets.last;
    final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;
    final setsRemaining = totalSets - exerciseSets.length;

    setState(() => _isLoadingAiTip = true);

    try {
      final restTipService = ref.read(restTipServiceProvider);
      final tip = await restTipService.getRestTip(
        exerciseName: exercise.name,
        weightKg: lastSet.weight,
        reps: lastSet.reps,
        rpe: lastSet.rpe,
        setsRemaining: setsRemaining,
        exerciseInstructions: exercise.instructions,
      );

      if (mounted) {
        setState(() {
          _inlineRestAiTip = tip;
          _isLoadingAiTip = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ActiveWorkout] Error fetching AI tip: $e');
      if (mounted) {
        setState(() => _isLoadingAiTip = false);
      }
    }
  }

  /// Fetch achievement prompt for inline rest row
  Future<void> _fetchInlineRestAchievementPrompt(WorkoutExercise exercise) async {
    final exerciseSets = _completedSets[_currentExerciseIndex];
    if (exerciseSets == null || exerciseSets.isEmpty) return;

    final lastSet = exerciseSets.last;
    final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;

    try {
      final achievementService = ref.read(achievementPromptServiceProvider);
      final prompt = await achievementService.getPromptForSet(
        exerciseName: exercise.name,
        currentWeight: lastSet.weight,
        currentReps: lastSet.reps,
        setNumber: exerciseSets.length,
        totalSets: totalSets,
      );

      if (mounted) {
        setState(() {
          _inlineRestAchievementPrompt = prompt;
        });
      }
    } catch (e) {
      debugPrint('❌ [ActiveWorkout] Error fetching achievement prompt: $e');
    }
  }

  /// Handle inline rest RPE rating
  void _handleInlineRestRpeRating(int rpe) {
    setState(() {
      _inlineRestCurrentRpe = rpe;
      _lastSetRpe = rpe;
    });

    // Update the last completed set with the RPE
    final exerciseSets = _completedSets[_currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastIndex = exerciseSets.length - 1;
      exerciseSets[lastIndex] = exerciseSets[lastIndex].copyWith(rpe: rpe);
    }

    HapticFeedback.selectionClick();
  }

  /// Handle inline rest note added
  void _handleInlineRestNote(String note) {
    // Update the last completed set with the note
    final exerciseSets = _completedSets[_currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastIndex = exerciseSets.length - 1;
      exerciseSets[lastIndex] = exerciseSets[lastIndex].copyWith(notes: note);
    }
    HapticFeedback.mediumImpact();
  }

  /// Handle inline rest skip
  void _handleInlineRestSkip() {
    _timerController.skipRest();
  }

  /// Handle inline rest complete
  void _handleInlineRestComplete() {
    setState(() {
      _showInlineRest = false;
      _inlineRestAiTip = null;
      _inlineRestAchievementPrompt = null;
    });
  }

  /// Handle inline rest time adjustment
  void _handleInlineRestTimeAdjust(int adjustment) {
    setState(() {
      _inlineRestDuration = (_inlineRestDuration + adjustment).clamp(0, 600);
    });
    _timerController.adjustRestTime(adjustment);
  }

  /// Build inline rest row for V2 design
  Widget _buildInlineRestRowV2() {
    return InlineRestRow(
      restDurationSeconds: _inlineRestDuration,
      onRestComplete: _handleInlineRestComplete,
      onSkipRest: _handleInlineRestSkip,
      onAdjustTime: _handleInlineRestTimeAdjust,
      onRateSet: _handleInlineRestRpeRating,
      onAddNote: _handleInlineRestNote,
      onShowRpeInfo: _showRpeInfoSheet,
      achievementPrompt: _inlineRestAchievementPrompt,
      aiTip: _inlineRestAiTip,
      isLoadingAiTip: _isLoadingAiTip,
      currentRpe: _inlineRestCurrentRpe,
    );
  }

  /// Show RPE info sheet (for inline rest row)
  void _showRpeInfoSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
            Text(
              'What is RPE?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Rate of Perceived Exertion measures how hard a set felt:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // RPE scale
            _buildRpeScaleRowV2('1-4', 'Very easy, lots left in tank', AppColors.success, isDark),
            _buildRpeScaleRowV2('5-6', 'Moderate effort', AppColors.cyan, isDark),
            _buildRpeScaleRowV2('7-8', 'Hard, could do 2-3 more reps', AppColors.orange, isDark),
            _buildRpeScaleRowV2('9', 'Very hard, maybe 1 more rep', AppColors.orange, isDark),
            _buildRpeScaleRowV2('10', 'Maximum effort, couldn\'t do more', AppColors.error, isDark),

            const SizedBox(height: 24),

            // Got it button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRpeScaleRowV2(String range, String description, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _moveToNextExercise() {
    // Track time for current exercise
    if (_currentExerciseStartTime != null) {
      _exerciseTimeSeconds[_currentExerciseIndex] =
          DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
    }

    // Find next INCOMPLETE exercise (circular search starting from current)
    int? nextIndex;
    for (int i = 1; i <= _exercises.length; i++) {
      final candidateIndex = (_currentExerciseIndex + i) % _exercises.length;
      if (!_isExerciseCompleted(candidateIndex)) {
        nextIndex = candidateIndex;
        break;
      }
    }

    if (nextIndex != null) {
      // Found an incomplete exercise - navigate to it
      // Haptic feedback for exercise transition
      HapticService.exerciseTransition();

      final nextExercise = _exercises[nextIndex];

      // Voice: "Get ready for [exercise name]"
      ref.read(voiceAnnouncementsProvider.notifier)
          .announceNextExerciseIfEnabled(nextExercise.name);

      setState(() {
        _currentExerciseIndex = nextIndex!;
        _viewingExerciseIndex = nextIndex;
      });

      // Update input controllers for new exercise (use setTargets if available)
      final firstSetTarget = nextExercise.getTargetForSet(1);
      _repsController.text = (firstSetTarget?.targetReps ?? nextExercise.reps ?? 10).toString();
      _repsRightController.text = (firstSetTarget?.targetReps ?? nextExercise.reps ?? 10).toString(); // Sync L/R
      _weightController.text = (firstSetTarget?.targetWeightKg ?? nextExercise.weight ?? 0).toString();

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

      // Voice: "Congratulations! Workout complete!"
      ref.read(voiceAnnouncementsProvider.notifier).announceWorkoutCompleteIfEnabled();

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

  /// Toggle favorite status for current exercise
  Future<void> _toggleFavoriteExercise() async {
    if (_exercises.isEmpty || _currentExerciseIndex >= _exercises.length) return;

    final exercise = _exercises[_currentExerciseIndex];
    final exerciseName = exercise.name ?? 'Unknown';

    HapticFeedback.mediumImpact();

    await ref.read(favoritesProvider.notifier).toggleFavorite(
      exerciseName,
      exerciseId: exercise.id ?? exercise.libraryId,
    );
  }

  /// Minimize workout to mini player (YouTube-style)
  void _minimizeWorkout() {
    debugPrint('🎬 [Workout] Minimizing to mini player...');

    // Convert completed sets to serializable format
    final completedSetsMap = <int, List<Map<String, dynamic>>>{};
    for (final entry in _completedSets.entries) {
      completedSetsMap[entry.key] = entry.value.map((set) => {
        'reps': set.reps,
        'weight': set.weight,
        'setType': set.setType,
        'rpe': set.rpe,
        'rir': set.rir,
        'aiInputSource': set.aiInputSource,
      }).toList();
    }

    // Get current exercise name and image
    final currentExercise = _currentExerciseIndex < _exercises.length
        ? _exercises[_currentExerciseIndex]
        : null;
    final currentExerciseName = currentExercise?.name;
    final currentExerciseImageUrl = currentExercise?.gifUrl;

    // Save state to provider
    ref.read(workoutMiniPlayerProvider.notifier).minimize(
      workout: widget.workout,
      workoutSeconds: _timerController.workoutSeconds,
      currentExerciseName: currentExerciseName,
      currentExerciseImageUrl: currentExerciseImageUrl,
      currentExerciseIndex: _currentExerciseIndex,
      totalExercises: _exercises.length,
      completedSets: completedSetsMap,
      isResting: _isResting,
      restSecondsRemaining: _timerController.restSecondsRemaining,
      isPaused: _isPaused,
    );

    // Stop local timer (provider will handle it)
    _timerController.dispose();

    // Navigate back
    if (mounted) {
      context.pop();
    }
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
    // Only use direct URLs (presigned or public), NOT raw S3 paths (s3://...)
    // which require presigning via the API to avoid 403 errors.
    final modelVideoUrl = exercise.videoUrl;
    final modelImageUrl = exercise.gifUrl;

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

        // 6. Log superset usage for analytics (if any supersets were used)
        await _logSupersetUsage(userId);

        // 7. Mark workout as complete and get PRs
        final completionResponse = await workoutRepo.completeWorkout(widget.workout.id!);
        debugPrint('✅ Workout marked as complete');

        // Award XP for completing workout
        ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: widget.workout.id);

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
          // Include superset info if exercise is in a superset
          if (exercise.supersetGroup != null) 'superset_group': exercise.supersetGroup,
          if (exercise.supersetOrder != null) 'superset_order': exercise.supersetOrder,
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
      // Include superset info
      if (e.value.supersetGroup != null) 'superset_group': e.value.supersetGroup,
      if (e.value.supersetOrder != null) 'superset_order': e.value.supersetOrder,
    }).toList();

    // Build superset summary
    final supersetGroups = <int, List<Map<String, dynamic>>>{};
    for (final exercise in _exercises) {
      if (exercise.supersetGroup != null) {
        supersetGroups[exercise.supersetGroup!] ??= [];
        supersetGroups[exercise.supersetGroup!]!.add({
          'name': exercise.name,
          'muscle_group': exercise.muscleGroup,
          'order': exercise.supersetOrder,
        });
      }
    }

    return {
      'exercise_order': exerciseOrder,
      'rest_intervals': _restIntervals,
      'drink_intake_ml': _totalDrinkIntakeMl,
      if (supersetGroups.isNotEmpty) 'supersets': supersetGroups.entries.map((e) => {
        'group_id': e.key,
        'exercises': e.value,
      }).toList(),
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
            notes: setLog.notes,
            aiInputSource: setLog.aiInputSource,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to log set performance: $e');
        }
      }
    }
    debugPrint('💪 Logged ${_completedSets.values.fold<int>(0, (s, l) => s + l.length)} set performances');
  }

  /// Log superset usage to backend for analytics
  Future<void> _logSupersetUsage(String userId) async {
    // Find all superset groups
    final supersetGroups = <int, List<WorkoutExercise>>{};
    for (final exercise in _exercises) {
      if (exercise.supersetGroup != null) {
        supersetGroups[exercise.supersetGroup!] ??= [];
        supersetGroups[exercise.supersetGroup!]!.add(exercise);
      }
    }

    if (supersetGroups.isEmpty) {
      debugPrint('🔗 No supersets to log');
      return;
    }

    final apiClient = ref.read(apiClientProvider);

    for (final entry in supersetGroups.entries) {
      final groupId = entry.key;
      final exercises = entry.value;

      if (exercises.length >= 2) {
        // Sort by superset order
        exercises.sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

        // Log the superset pair (first two exercises)
        try {
          await apiClient.post(
            '/supersets/logs',
            data: {
              'user_id': userId,
              'workout_id': widget.workout.id,
              'exercise_1_name': exercises[0].name,
              'exercise_2_name': exercises[1].name,
              'exercise_1_muscle': exercises[0].muscleGroup,
              'exercise_2_muscle': exercises[1].muscleGroup,
              'superset_group': groupId,
            },
          );
          debugPrint('🔗 Logged superset group $groupId: ${exercises[0].name} + ${exercises[1].name}');

          // If more than 2 exercises (tri-set, giant set), log additional pairs
          for (int i = 2; i < exercises.length; i++) {
            await apiClient.post(
              '/supersets/logs',
              data: {
                'user_id': userId,
                'workout_id': widget.workout.id,
                'exercise_1_name': exercises[i - 1].name,
                'exercise_2_name': exercises[i].name,
                'exercise_1_muscle': exercises[i - 1].muscleGroup,
                'exercise_2_muscle': exercises[i].muscleGroup,
                'superset_group': groupId,
              },
            );
            debugPrint('🔗 Logged superset continuation: ${exercises[i - 1].name} + ${exercises[i].name}');
          }
        } catch (e) {
          // Non-critical - don't fail workout completion for superset logging
          debugPrint('⚠️ Failed to log superset: $e');
        }
      }
    }
  }

  // ========================================================================
  // AI TEXT INPUT HANDLING
  // ========================================================================

  /// Handle parsed exercises from the AI text input bar
  Future<void> _handleParsedExercises(List<ParsedExercise> exercises) async {
    if (exercises.isEmpty) return;

    // Show preview sheet for user to confirm
    final confirmedExercises = await showParsedExercisesPreview(
      context,
      ref,
      exercises: exercises,
      useKg: _useKg,
    );

    if (confirmedExercises == null || confirmedExercises.isEmpty || !mounted) {
      return;
    }

    // Add exercises to workout
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      final repo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await repo.addExercisesBatch(
        workoutId: widget.workout.id ?? '',
        userId: userId,
        exercises: confirmedExercises,
        useKg: _useKg,
      );

      if (updatedWorkout != null && mounted) {
        final newExercises = updatedWorkout.exercises;
        final addedCount = confirmedExercises.length;
        final startIndex = _exercises.length;

        setState(() {
          // Update exercises list
          _exercises = List.from(newExercises);
          _precomputeSupersetIndices();

          // Initialize tracking data for new exercises
          for (int i = startIndex; i < _exercises.length; i++) {
            _completedSets[i] = [];
            final ex = _exercises[i];
            _totalSetsPerExercise[i] = ex.hasSetTargets && ex.setTargets!.isNotEmpty
                ? ex.setTargets!.length
                : ex.sets ?? 3;
            _previousSets[i] = [];
          }
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount exercise${addedCount == 1 ? '' : 's'}'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        debugPrint('✅ [Workout] Added $addedCount exercises via AI input');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to add exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add exercises: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle V2 parsed response (sets to log + exercises to add)
  Future<void> _handleV2Parsed(ParseWorkoutInputV2Response response) async {
    if (!response.hasData) return;

    final currentExerciseName = _exercises.isNotEmpty
        ? _exercises[_viewingExerciseIndex].name
        : null;

    // Show V2 preview sheet
    final result = await showAIInputPreview(
      context,
      ref,
      response: response,
      currentExerciseName: currentExerciseName,
      useKg: _useKg,
    );

    if (result == null || !result.hasData || !mounted) {
      return;
    }

    // Handle sets to log
    if (result.setsToLog.isNotEmpty) {
      await _logSetsFromAI(result.setsToLog);
    }

    // Handle exercises to add
    if (result.exercisesToAdd.isNotEmpty) {
      await _addExercisesFromAI(result.exercisesToAdd);
    }
  }

  /// Log multiple sets from AI input to the current exercise
  Future<void> _logSetsFromAI(List<SetToLog> sets) async {
    if (sets.isEmpty || _exercises.isEmpty) return;

    final exerciseIndex = _viewingExerciseIndex;
    final exercise = _exercises[exerciseIndex];

    for (final aiSet in sets) {
      // Convert weight if necessary
      double weight = aiSet.weight;
      if (aiSet.isBodyweight) {
        weight = 0;
      } else if (_useKg && aiSet.unit == 'lbs') {
        weight = aiSet.weight / 2.20462;
      } else if (!_useKg && aiSet.unit == 'kg') {
        weight = aiSet.weight * 2.20462;
      }

      // Create a SetLog with AI input source for tracking
      final setLog = SetLog(
        reps: aiSet.reps,
        weight: weight,
        setType: aiSet.isWarmup ? 'warmup' : 'working',
        targetReps: exercise.reps ?? aiSet.reps,
        notes: aiSet.notes,
        aiInputSource: aiSet.originalInput.isNotEmpty ? aiSet.originalInput : null,
      );

      // Add to completed sets
      _completedSets[exerciseIndex] ??= [];
      _completedSets[exerciseIndex]!.add(setLog);
    }

    // Update total sets if more were added than expected
    final currentTotal = _totalSetsPerExercise[exerciseIndex] ?? 3;
    final completedCount = _completedSets[exerciseIndex]?.length ?? 0;
    if (completedCount > currentTotal) {
      _totalSetsPerExercise[exerciseIndex] = completedCount;
    }

    setState(() {});

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${sets.length} set${sets.length == 1 ? '' : 's'} for ${exercise.name}',
          ),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    debugPrint('✅ [Workout] Logged ${sets.length} sets via AI input');
  }

  /// Add exercises from AI input
  Future<void> _addExercisesFromAI(List<ExerciseToAdd> exercises) async {
    if (exercises.isEmpty) return;

    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;

      // Convert ExerciseToAdd to ParsedExercise for the repository
      final parsedExercises = exercises.map((e) {
        return ParsedExercise(
          name: e.name,
          sets: e.sets,
          reps: e.reps,
          weightKg: e.weightKg,
          weightLbs: e.weightLbs,
          restSeconds: e.restSeconds,
          originalText: e.originalText,
          confidence: e.confidence,
          notes: e.notes,
        );
      }).toList();

      final repo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await repo.addExercisesBatch(
        workoutId: widget.workout.id ?? '',
        userId: userId,
        exercises: parsedExercises,
        useKg: _useKg,
      );

      if (updatedWorkout != null && mounted) {
        final newExercises = updatedWorkout.exercises;
        final addedCount = exercises.length;
        final startIndex = _exercises.length;

        setState(() {
          // Update exercises list
          _exercises = List.from(newExercises);
          _precomputeSupersetIndices();

          // Initialize tracking data for new exercises
          for (int i = startIndex; i < _exercises.length; i++) {
            _completedSets[i] = [];
            final ex = _exercises[i];
            _totalSetsPerExercise[i] = ex.hasSetTargets && ex.setTargets!.isNotEmpty
                ? ex.setTargets!.length
                : ex.sets ?? 3;
            _previousSets[i] = [];
          }
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount exercise${addedCount == 1 ? '' : 's'}'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        debugPrint('✅ [Workout] Added $addedCount exercises via AI input');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Failed to add exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add exercises: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Log1RMSheet(
          exerciseName: exercise.name,
          exerciseId: exercise.id ?? exercise.libraryId ?? '',
        ),
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

    // Foldable detection
    final windowState = ref.watch(windowModeProvider);
    final isFoldableOpen = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    // Route to appropriate phase screen
    switch (_currentPhase) {
      case WorkoutPhase.warmup:
        if (isFoldableOpen) {
          return FoldableWarmupLayout(
            windowState: windowState,
            workoutSeconds: _timerController.workoutSeconds,
            exercises: _warmupExercises ?? defaultWarmupExercises,
            onSkipWarmup: _handleSkipWarmup,
            onWarmupComplete: _handleWarmupComplete,
            onQuitRequested: _showQuitDialog,
          );
        }
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
        if (isFoldableOpen) {
          return _buildFoldableActiveWorkout(windowState);
        }
        // Use V2 MacroFactor-style design
        if (_useV2Design) {
          return _buildActiveWorkoutScreenV2(isDark, backgroundColor);
        }
        return _buildActiveWorkoutScreen(isDark, backgroundColor);
    }
  }

  /// Build foldable-optimized active workout layout.
  Widget _buildFoldableActiveWorkout(WindowModeState windowState) {
    final setRows = _buildSetRowsForExercise(_viewingExerciseIndex);
    final completedExerciseIndices = _getCompletedExerciseIndices();
    final currentExercise = _exercises[_currentExerciseIndex];

    return FoldableWorkoutLayout(
      windowState: windowState,
      exercises: _exercises,
      currentExerciseIndex: _currentExerciseIndex,
      viewingExerciseIndex: _viewingExerciseIndex,
      completedExerciseIndices: completedExerciseIndices,
      completedSets: _completedSets,
      totalSetsPerExercise: _totalSetsPerExercise,
      videoController: _videoController,
      isVideoInitialized: _isVideoInitialized,
      imageUrl: _imageUrl,
      workoutSeconds: _timerController.workoutSeconds,
      restSecondsRemaining: _timerController.restSecondsRemaining,
      initialRestDuration: _timerController.initialRestDuration,
      isPaused: _isPaused,
      isResting: _isResting,
      isRestingBetweenExercises: _isRestingBetweenExercises,
      currentRestMessage: _currentRestMessage,
      setRows: setRows,
      useKg: _useKg,
      weightController: _weightController,
      repsController: _repsController,
      repsRightController: _isLeftRightMode ? _repsRightController : null,
      isLeftRightMode: _isLeftRightMode,
      isExerciseCompleted: _isExerciseCompleted(_viewingExerciseIndex),
      showInlineRest: _showInlineRest,
      inlineRestRowWidget: _buildInlineRestRowV2(),
      lastSetRpe: _lastSetRpe,
      lastSetRir: _lastSetRir,
      currentWeightSuggestion: _currentWeightSuggestion,
      isLoadingWeightSuggestion: _isLoadingWeightSuggestion,
      restSuggestion: _restSuggestion,
      isLoadingRestSuggestion: _isLoadingRestSuggestion,
      fatigueAlertData: _fatigueAlertData,
      showFatigueAlert: _showFatigueAlert,
      coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
      workoutId: widget.workout.id ?? '',
      actionChips: _buildActionChipsForCurrentExercise()
          .where((chip) => chip.label != 'Video' && chip.label != 'Info')
          .toList(),
      hideAICoachForSession: _hideAICoachForSession,
      onExerciseTap: (index) {
        HapticFeedback.selectionClick();
        setState(() {
          _viewingExerciseIndex = index;
          _currentExerciseIndex = index;
        });
      },
      onAddExercise: _showExerciseAddSheet,
      onQuitRequested: _showQuitDialog,
      onReorder: _onExercisesReordered,
      onCreateSuperset: _onSupersetFromDrag,
      onVideoTap: _toggleVideoPlayPause,
      onInfoTap: () => _showExerciseDetailsSheet(_exercises[_viewingExerciseIndex]),
      onSetCompleted: _handleSetCompletedV2,
      onSetUpdated: _updateCompletedSet,
      onAddSet: () => setState(() {
        _totalSetsPerExercise[_viewingExerciseIndex] =
            (_totalSetsPerExercise[_viewingExerciseIndex] ?? 3) + 1;
      }),
      onSetDeleted: (index) => _deleteCompletedSet(index),
      onToggleUnit: _toggleUnit,
      onRirTapped: (setIndex, currentRir) => _showRirPicker(setIndex, currentRir),
      onActiveRirChanged: (rir) => setState(() => _lastSetRir = rir),
      onSelectAllTapped: () {
        if (_isExerciseCompleted(_viewingExerciseIndex)) {
          HapticFeedback.lightImpact();
        }
      },
      onChipTapped: _handleChipTapped,
      onAiChipTapped: () => _showAICoachSheet(currentExercise),
      onSkipRest: () => _timerController.skipRest(),
      onLog1RM: () => _showLog1RMSheet(currentExercise),
      onAcceptWeightSuggestion: _acceptWeightSuggestion,
      onDismissWeightSuggestion: _dismissWeightSuggestion,
      onAcceptRestSuggestion: _acceptRestSuggestion,
      onDismissRestSuggestion: _dismissRestSuggestion,
      onRpeChanged: (rpe) => setState(() => _lastSetRpe = rpe),
      onRirChanged: (rir) => setState(() => _lastSetRir = rir),
      onAcceptFatigueSuggestion: _handleAcceptFatigueSuggestion,
      onDismissFatigueAlert: _handleDismissFatigueAlert,
      onStopExercise: _skipExercise,
      onExercisesParsed: (exercises) => _handleParsedExercises(exercises),
      onV2Parsed: (response) => _handleV2Parsed(response),
    );
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

            // Rest overlay with weight suggestion (only for rest between exercises)
            // Between-sets rest is handled by inline rest row in SetTrackingOverlay
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (_isResting && _isRestingBetweenExercises)
              Positioned.fill(
                child: RepaintBoundary(
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

            // Top overlay (show during active workout OR between-sets rest)
            // Wrapped in RepaintBoundary to isolate per-second timer repaints
            if (!_isResting || (_isResting && !_isRestingBetweenExercises))
              RepaintBoundary(
                child: WorkoutTopOverlay(
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
              ),

            // Set tracking overlay - full screen (no floating card, no minimize)
            // Show during active workout OR during between-sets rest (for inline rest row)
            if (!_isResting || (_isResting && !_isRestingBetweenExercises))
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
                  onEditTarget: (setIndex, weight, reps, rir) {
                    setState(() {
                      final exercise = _exercises[_viewingExerciseIndex];
                      final existingTargets = List<SetTarget>.from(exercise.setTargets ?? []);

                      // Find or create target for this set (setIndex is 0-indexed, setNumber is 1-indexed)
                      final setNumber = setIndex + 1;
                      final targetIndex = existingTargets.indexWhere((t) => t.setNumber == setNumber);
                      final newTarget = SetTarget(
                        setNumber: setNumber,
                        setType: 'working',
                        targetReps: reps,
                        targetWeightKg: weight,
                        targetRir: rir,
                      );

                      if (targetIndex >= 0) {
                        existingTargets[targetIndex] = newTarget;
                      } else {
                        existingTargets.add(newTarget);
                      }

                      _exercises[_viewingExerciseIndex] = exercise.copyWith(setTargets: existingTargets);
                    });
                  },
                  // Inline rest row props
                  showInlineRest: (() {
                    final show = _showInlineRest && _viewingExerciseIndex == _currentExerciseIndex;
                    debugPrint('🟡 [SetTrackingOverlay] showInlineRest=$show (_showInlineRest=$_showInlineRest, viewing=$_viewingExerciseIndex, current=$_currentExerciseIndex, isResting=$_isResting, isBetweenEx=$_isRestingBetweenExercises)');
                    return show;
                  })(),
                  restTimeRemaining: _timerController.restSecondsRemaining,
                  restDurationTotal: _inlineRestDuration,
                  onRestComplete: _handleInlineRestComplete,
                  onSkipRest: _handleInlineRestSkip,
                  onAdjustTime: _handleInlineRestTimeAdjust,
                  onRateRpe: _handleInlineRestRpeRating,
                  onAddSetNote: _handleInlineRestNote,
                  currentRpe: _inlineRestCurrentRpe,
                  achievementPrompt: _inlineRestAchievementPrompt,
                  aiTip: _inlineRestAiTip,
                  isLoadingAiTip: _isLoadingAiTip,
                ),
              ),

            // Bottom bar with action buttons (show during active workout OR between-sets rest)
            if (!_isResting || (_isResting && !_isRestingBetweenExercises))
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
                    setState(() {
                      _viewingExerciseIndex = index;
                      _currentExerciseIndex = index; // Allow working on any exercise
                    });
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
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          // Use landscape layout when rotated
          if (isLandscape) {
            return _buildLandscapeLayoutV2(
              isDark: isDark,
              currentExercise: currentExercise,
              nextExercise: nextExercise,
              setRows: setRows,
              completedExerciseIndices: completedExerciseIndices,
            );
          }

          // Portrait layout (original)
          return Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(
        backgroundColor: isDark ? WorkoutDesign.background : Colors.grey.shade50,
        body: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // V2 Top bar - wrapped in RepaintBoundary to isolate per-second timer repaints
                RepaintBoundary(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final warmupEnabled = ref.watch(warmupDurationProvider).warmupEnabled;
                      final favoritesState = ref.watch(favoritesProvider);
                      final currentExercise = _exercises.isNotEmpty ? _exercises[_currentExerciseIndex] : null;
                      final isFavorite = currentExercise != null
                          ? favoritesState.isFavorite(currentExercise.name ?? '')
                          : false;

                      return WorkoutTopBarV2(
                        workoutSeconds: _timerController.workoutSeconds,
                        restSecondsRemaining: _isResting ? _timerController.restSecondsRemaining : null,
                        totalRestSeconds: _isResting ? _timerController.initialRestDuration : null,
                        isPaused: _isPaused,
                        showBackButton: warmupEnabled,
                        backButtonLabel: warmupEnabled ? 'Warmup' : null,
                        onMenuTap: _showWorkoutPlanDrawer,
                        onBackTap: warmupEnabled ? _goBackToWarmup : null,
                        onCloseTap: _showQuitDialog,
                        onTimerTap: _togglePause,
                        onMinimize: _minimizeWorkout,
                        onFavoriteTap: currentExercise != null ? () => _toggleFavoriteExercise() : null,
                        isFavorite: isFavorite,
                      );
                    },
                  ),
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
                        // Exercise title and set counter with info button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise name and set counter
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _exercises[_viewingExerciseIndex].name,
                                      style: WorkoutDesign.titleStyle.copyWith(
                                        fontSize: 26, // Bigger font size
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
                              const SizedBox(width: 8),
                              // Live heart rate display (merged WearOS + BLE)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HeartRateDisplay(
                                    iconSize: 24,
                                    fontSize: 18,
                                    showZoneLabel: false,
                                  ),
                                  // BLE connection indicator
                                  Consumer(builder: (context, ref, _) {
                                    final connAsync = ref.watch(bleHrConnectionStateProvider);
                                    final connState = connAsync.whenOrNull(data: (s) => s);
                                    if (connState == null || connState == BleHrConnectionState.disconnected) {
                                      return const SizedBox.shrink();
                                    }
                                    final color = connState == BleHrConnectionState.connected
                                        ? Colors.green
                                        : Colors.orange;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.bluetooth_connected,
                                        size: 14,
                                        color: color,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Info magic pill (styled like Video chip)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showExerciseDetailsSheet(_exercises[_viewingExerciseIndex]);
                                },
                                child: Container(
                                  height: WorkoutDesign.chipHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? WorkoutDesign.surface : Colors.white,
                                    borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
                                    border: Border.all(
                                      color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Info',
                                        style: WorkoutDesign.chipStyle.copyWith(
                                          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action chips row (Superset, Warm Up, etc.) - Video moved to bottom, Info moved to title
                        ActionChipsRow(
                          chips: _buildActionChipsForCurrentExercise()
                              .where((chip) => chip.label != 'Video' && chip.label != 'Info')
                              .toList(),
                          onChipTapped: _handleChipTapped,
                          showAiChip: false,
                          hasAiNotification: _currentWeightSuggestion != null,
                          onAiChipTapped: () => _showAICoachSheet(currentExercise),
                        ),

                        const SizedBox(height: 8),

                        // Set tracking table with inline rest row
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SetTrackingTable(
                                  key: ValueKey('set_tracking_${_viewingExerciseIndex}'),
                                  exercise: _exercises[_viewingExerciseIndex],
                                  sets: setRows,
                                  useKg: _useKg,
                                  activeSetIndex: _completedSets[_viewingExerciseIndex]?.length ?? 0,
                                  weightController: _weightController,
                                  repsController: _repsController,
                                  repsRightController: _isLeftRightMode ? _repsRightController : null,
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
                                  onToggleUnit: _toggleUnit,
                                  onRirTapped: (setIndex, currentRir) => _showRirPicker(setIndex, currentRir),
                                  activeRir: _lastSetRir,
                                  onActiveRirChanged: (rir) => setState(() => _lastSetRir = rir),
                                  // Inline rest row - shows between completed and active sets
                                  showInlineRest: _showInlineRest &&
                                      _viewingExerciseIndex == _currentExerciseIndex &&
                                      !_isRestingBetweenExercises,
                                  inlineRestRowWidget: _buildInlineRestRowV2(),
                                ),

                                // AI Text Input Bar (below set table, within scrollable area)
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: AiTextInputBar(
                                    workoutId: widget.workout.id ?? '',
                                    useKg: _useKg,
                                    currentExerciseName: _exercises.isNotEmpty
                                        ? _exercises[_viewingExerciseIndex].name
                                        : null,
                                    currentExerciseIndex: _viewingExerciseIndex,
                                    lastSetWeight: _completedSets[_viewingExerciseIndex]?.isNotEmpty == true
                                        ? _completedSets[_viewingExerciseIndex]!.last.weight
                                        : null,
                                    lastSetReps: _completedSets[_viewingExerciseIndex]?.isNotEmpty == true
                                        ? _completedSets[_viewingExerciseIndex]!.last.reps
                                        : null,
                                    onExercisesParsed: (exercises) => _handleParsedExercises(exercises),
                                    onV2Parsed: (response) => _handleV2Parsed(response),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Video, Hydration, and Note quick actions row
                HydrationQuickActions(
                  onTap: () => _showHydrationDialog(),
                  onNoteTap: () => _showNotesSheet(_exercises[_viewingExerciseIndex]),
                  onVideoTap: () => _handleChipTapped('video'),
                ),

                // Exercise thumbnail strip (bottom navigation)
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: isDark ? WorkoutDesign.surface : Colors.white,
                      child: SafeArea(
                        top: false,
                        child: ExerciseThumbnailStripV2(
                          key: ValueKey('thumb_strip_${_exercises.map((e) => e.id ?? e.name).join('_')}'),
                          exercises: _exercises.toList(), // Create new list instance
                          currentIndex: _viewingExerciseIndex,
                          completedExercises: completedExerciseIndices,
                          onExerciseTap: (index) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _viewingExerciseIndex = index;
                              _currentExerciseIndex = index; // Allow working on any exercise
                            });
                          },
                          onAddTap: () => _showExerciseAddSheet(),
                          showAddButton: true,
                          onReorder: _onExercisesReordered,
                          onCreateSuperset: _onSupersetFromDrag,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Rest overlay (shows on top) - only for rest between exercises
            // Between-sets rest is handled by inline rest row
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (_isResting && _isRestingBetweenExercises)
              Positioned.fill(
                child: RepaintBoundary(
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
          );
        },
      ),
    );
  }

  // ========================================================================
  // LANDSCAPE LAYOUT METHODS
  // ========================================================================

  /// Build landscape layout with side-by-side video + set table
  Widget _buildLandscapeLayoutV2({
    required bool isDark,
    required dynamic currentExercise,
    required dynamic nextExercise,
    required List<SetRowData> setRows,
    required Set<int> completedExerciseIndices,
  }) {
    final backgroundColor = isDark ? WorkoutDesign.background : Colors.grey.shade50;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // LEFT PANEL (~35%): Video Player + Thumbnail Strip
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: Column(
                    children: [
                      // Exercise VIDEO player (auto-plays, looped)
                      Expanded(
                        child: _buildLandscapeVideoPlayer(isDark),
                      ),
                      // Horizontal thumbnail strip at bottom
                      _buildLandscapeThumbnailStrip(
                        isDark: isDark,
                        completedExerciseIndices: completedExerciseIndices,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                ),

                // Vertical divider
                VerticalDivider(width: 1, color: cardBorder, thickness: 1),

                // RIGHT PANEL (~65%): Top Bar + Set Table + Actions
                Expanded(
                  child: Column(
                    children: [
                      // Compact top bar: ← | Timer | Title | Set X/Y | ✕
                      _buildLandscapeTopBar(isDark: isDark, accentColor: accentColor),

                      // Set tracking table (gets most vertical space)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SetTrackingTable(
                            key: ValueKey('set_tracking_landscape_${_viewingExerciseIndex}'),
                            exercise: _exercises[_viewingExerciseIndex],
                            sets: setRows,
                            useKg: _useKg,
                            activeSetIndex: _completedSets[_viewingExerciseIndex]?.length ?? 0,
                            weightController: _weightController,
                            repsController: _repsController,
                            repsRightController: _isLeftRightMode ? _repsRightController : null,
                            onSetCompleted: _handleSetCompletedV2,
                            onSetUpdated: _updateCompletedSet,
                            onAddSet: () => setState(() {
                              _totalSetsPerExercise[_viewingExerciseIndex] =
                                  (_totalSetsPerExercise[_viewingExerciseIndex] ?? 3) + 1;
                            }),
                            isLeftRightMode: _isLeftRightMode,
                            allSetsCompleted: _isExerciseCompleted(_viewingExerciseIndex),
                            onSelectAllTapped: () {
                              if (_isExerciseCompleted(_viewingExerciseIndex)) {
                                HapticFeedback.lightImpact();
                              }
                            },
                            onSetDeleted: (index) => _deleteCompletedSet(index),
                            onToggleUnit: _toggleUnit,
                            onRirTapped: (setIndex, currentRir) => _showRirPicker(setIndex, currentRir),
                            activeRir: _lastSetRir,
                            onActiveRirChanged: (rir) => setState(() => _lastSetRir = rir),
                            showInlineRest: _showInlineRest &&
                                _viewingExerciseIndex == _currentExerciseIndex &&
                                !_isRestingBetweenExercises,
                            inlineRestRowWidget: _buildInlineRestRowV2(),
                          ),
                        ),
                      ),

                      // Compact action chips row (no Video chip - it's always visible)
                      _buildLandscapeActions(isDark: isDark, accentColor: accentColor),
                    ],
                  ),
                ),
              ],
            ),

            // Rest overlay (shows on top) - for rest between exercises
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (_isResting && _isRestingBetweenExercises)
              Positioned.fill(
                child: RepaintBoundary(
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Landscape video player - uses already-loaded video from state
  Widget _buildLandscapeVideoPlayer(bool isDark) {
    final exercise = _exercises[_viewingExerciseIndex];
    final backgroundColor = isDark ? AppColors.surface : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Center the media content with proper aspect ratio
            Positioned.fill(
              child: Center(
                child: _buildLandscapeMediaContent(exercise, isDark),
              ),
            ),

            // Tap overlay for pausing video / opening full screen
            if (_isVideoInitialized && _videoController != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleVideoPlayPause,
                  behavior: HitTestBehavior.translucent,
                  child: AnimatedOpacity(
                    opacity: !_isVideoPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Exercise name overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  exercise.name ?? 'Exercise',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the media content (video or image) with proper aspect ratio
  Widget _buildLandscapeMediaContent(dynamic exercise, bool isDark) {
    // Priority 1: Show video if initialized
    if (_isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    // Priority 2: Show loaded image/GIF with natural aspect ratio
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.contain, // Maintain aspect ratio
        errorBuilder: (_, __, ___) => _buildVideoPlaceholder(exercise, isDark),
      );
    }

    // Priority 3: Show loading indicator
    if (_isLoadingMedia) {
      return CircularProgressIndicator(
        color: isDark ? Colors.white70 : Colors.black54,
        strokeWidth: 2,
      );
    }

    // Priority 4: Show placeholder
    return _buildVideoPlaceholder(exercise, isDark);
  }

  Widget _buildVideoPlaceholder(dynamic exercise, bool isDark) {
    return Container(
      color: isDark ? AppColors.surface : Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              exercise.name ?? 'Exercise',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Landscape thumbnail strip - reuses the same component as portrait
  Widget _buildLandscapeThumbnailStrip({
    required bool isDark,
    required Set<int> completedExerciseIndices,
    required Color accentColor,
  }) {
    // Reuse the same ExerciseThumbnailStripV2 component for consistent behavior
    // This ensures thumbnails load correctly from API/cache
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: ExerciseThumbnailStripV2(
        key: ValueKey('thumb_strip_landscape_${_exercises.map((e) => e.id ?? e.name).join('_')}'),
        exercises: _exercises.toList(), // Create new list instance
        currentIndex: _viewingExerciseIndex,
        completedExercises: completedExerciseIndices,
        onExerciseTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _viewingExerciseIndex = index;
            _currentExerciseIndex = index;
          });
          // Fetch media for the new exercise
          _fetchMediaForExercise(_exercises[index]);
        },
        onAddTap: () => _showExerciseAddSheet(),
        showAddButton: true,
        onReorder: _onExercisesReordered,
        onCreateSuperset: _onSupersetFromDrag,
      ),
    );
  }

  /// Landscape top bar - compact with all info in one row
  Widget _buildLandscapeTopBar({
    required bool isDark,
    required Color accentColor,
  }) {
    final exercise = _exercises[_viewingExerciseIndex];
    final completedSets = _completedSets[_viewingExerciseIndex]?.length ?? 0;
    final totalSets = _totalSetsPerExercise[_viewingExerciseIndex] ?? 3;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, size: 20, color: textPrimary),
            onPressed: _handleBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Timer (uses direct getter, UI rebuilds via setState from timer callback)
          // Wrapped in RepaintBoundary to isolate per-second timer repaints
          RepaintBoundary(
            child: Text(
              _formatDuration(_timerController.workoutSeconds),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Exercise name (truncated)
          Expanded(
            child: Text(
              exercise.name ?? 'Exercise',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Set counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Set ${completedSets + 1}/$totalSets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Pause/Play button
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              size: 20,
              color: textSecondary,
            ),
            onPressed: _togglePause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Close button
          IconButton(
            icon: Icon(Icons.close, size: 20, color: textSecondary),
            onPressed: _showQuitDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  /// Landscape action chips - wrapped layout, no Video chip
  Widget _buildLandscapeActions({
    required bool isDark,
    required Color accentColor,
  }) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final chipBackground = isDark ? AppColors.surface : Colors.grey.shade100;

    // Filter out Video chip - it's always visible in left panel
    final landscapeChips = _buildActionChipsForCurrentExercise()
        .where((chip) => chip.label != 'Video')
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? WorkoutDesign.surface : Colors.white,
        border: Border(top: BorderSide(color: cardBorder)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          // Action chips
          ...landscapeChips.map((chip) => _buildLandscapeMiniChip(
                icon: chip.icon,
                label: chip.label,
                onTap: () => _handleChipTapped(chip.id),
                isDark: isDark,
                chipBackground: chipBackground,
                textColor: textSecondary,
              )),
          // Quick actions
          _buildLandscapeMiniChip(
            icon: Icons.water_drop,
            label: 'Drink',
            onTap: _showHydrationDialog,
            isDark: isDark,
            chipBackground: chipBackground,
            textColor: AppColors.quickActionWater,
            iconColor: AppColors.quickActionWater,
          ),
          _buildLandscapeMiniChip(
            icon: Icons.sticky_note_2_outlined,
            label: 'Note',
            onTap: () => _showNotesSheet(_exercises[_viewingExerciseIndex]),
            isDark: isDark,
            chipBackground: chipBackground,
            textColor: const Color(0xFFF59E0B),
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeMiniChip({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color chipBackground,
    required Color textColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    // Check if warmup is enabled and go back to warmup, otherwise show quit dialog
    final warmupEnabled = ref.read(warmupDurationProvider).warmupEnabled;
    if (warmupEnabled) {
      _goBackToWarmup();
    } else {
      _showQuitDialog();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Calculate RIR algorithmically based on set type and position
  /// Based on RP Strength methodology: progressive intensity through sets
  int? _calculateRir(String? setType, int setIndex, int totalWorkingSets) {
    final type = (setType ?? 'working').toLowerCase();

    // Warmup sets don't have RIR - they're for preparation, not stimulation
    if (type == 'warmup') return null;

    // Failure/AMRAP sets are always RIR 0 (maximum effort)
    if (type == 'failure' || type == 'amrap') return 0;

    // Drop sets maintain high intensity (RIR 1)
    if (type == 'drop') return 1;

    // Working sets: progressive RIR decrease (3 → 2 → 1)
    if (totalWorkingSets <= 1) return 2;  // Single set = moderate intensity
    if (totalWorkingSets == 2) {
      return setIndex == 0 ? 3 : 1;  // First=3, Last=1
    }
    // 3+ working sets: distribute RIR across thirds (3→2→1)
    final position = setIndex / (totalWorkingSets - 1);  // 0.0 to 1.0
    if (position < 0.33) return 3;      // First third: conservative
    if (position < 0.67) return 2;      // Middle third: moderate
    return 1;                            // Last third: approaching failure
  }

  /// Build set row data for the V2 table
  List<SetRowData> _buildSetRowsForExercise(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final totalSets = _totalSetsPerExercise[exerciseIndex] ?? exercise.sets ?? 3;
    final completedSets = _completedSets[exerciseIndex] ?? [];
    final previousSets = _previousSets[exerciseIndex] ?? [];
    final setTargets = exercise.setTargets ?? [];

    // Count working sets for RIR calculation
    final totalWorkingSets = setTargets.isNotEmpty
        ? setTargets.where((t) => t.setType.toLowerCase() == 'working').length
        : totalSets;

    final List<SetRowData> rows = [];
    int workingSetIndex = 0;

    for (int i = 0; i < totalSets; i++) {
      final isCompleted = i < completedSets.length;
      final isActive = i == completedSets.length && exerciseIndex == _viewingExerciseIndex;

      // Get target data from AI
      SetTarget? setTarget;
      if (i < setTargets.length) {
        setTarget = setTargets[i];
      }

      // Track working set index for RIR calculation
      final isWorkingSet = setTarget?.setType.toLowerCase() == 'working' ||
          (setTarget == null && i >= 0); // Fallback assumes all are working sets
      final currentWorkingIndex = isWorkingSet ? workingSetIndex : 0;
      if (setTarget?.setType.toLowerCase() == 'working') {
        workingSetIndex++;
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

      // Calculate RIR: use AI value if available, otherwise calculate algorithmically
      final calculatedRir = setTarget?.targetRir ??
          _calculateRir(setTarget?.setType, currentWorkingIndex, totalWorkingSets);

      // Get actual RIR from completed set log
      int? actualRir;
      if (isCompleted) {
        actualRir = completedSets[i].rir;
      }

      rows.add(SetRowData(
        setNumber: i + 1,
        isWarmup: setTarget?.isWarmup ?? false,
        isCompleted: isCompleted,
        isActive: isActive,
        targetWeight: setTarget?.targetWeightKg ?? prevWeight ?? exercise.weight?.toDouble(),
        targetReps: setTarget?.targetReps != null ? setTarget!.targetReps.toString() : '${exercise.reps ?? 8}-${(exercise.reps ?? 8) + 2}',
        targetRir: calculatedRir,
        actualWeight: actualWeight,
        actualReps: actualReps,
        actualRir: actualRir,
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
  /// Order: Video (leftmost), Superset, Info, Swap, L/R, More (3-dot)
  /// Note is moved to bottom bar area
  /// History and Increments are now in the More menu
  List<ActionChipData> _buildActionChipsForCurrentExercise() {
    return [
      WorkoutActionChips.video,
      WorkoutActionChips.superset,
      WorkoutActionChips.info,
      WorkoutActionChips.swap,
      WorkoutActionChips.leftRight(isActive: _isLeftRightMode),
      WorkoutActionChips.more,
    ];
  }

  /// Handle chip tapped
  void _handleChipTapped(String chipId) {
    HapticFeedback.selectionClick();
    final currentExercise = _exercises[_viewingExerciseIndex];

    switch (chipId) {
      case 'info':
        // Show exercise details (muscles, description, etc.)
        _showExerciseDetailsSheet(currentExercise);
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
        _showSwapSheet(_viewingExerciseIndex);
        break;
      case 'note':
        // Show notes sheet
        _showNotesSheet(currentExercise);
        break;
      case 'superset':
        // Show superset pairing
        _showSupersetSheet();
        break;
      case 'video':
        // Show exercise video/instructions
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
      case 'reorder':
        _showWorkoutPlanDrawer();
        break;
      case 'more':
        _showMoreMenu(currentExercise);
        break;
    }
  }

  /// Show the 3-dot "More" popup menu with History, Increments options
  void _showMoreMenu(WorkoutExercise exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200, // Position from right
        kToolbarHeight + MediaQuery.of(context).padding.top + 100, // Below top bar
        16,
        0,
      ),
      color: isDark ? WorkoutDesign.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
        ),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                'History',
                style: TextStyle(
                  color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'increments',
          child: Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                'Increments',
                style: TextStyle(
                  color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Divider before destructive action
        const PopupMenuDivider(),
        // End Workout option in red
        PopupMenuItem<String>(
          value: 'end_workout',
          child: Row(
            children: [
              Icon(
                Icons.stop_circle_outlined,
                size: 20,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'End Workout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'history') {
        _showHistorySheet(exercise);
      } else if (value == 'increments') {
        _showWeightIncrementsSheet();
      } else if (value == 'end_workout') {
        _showQuitDialog();
      }
    });
  }

  /// Show weight increments sheet
  void _showWeightIncrementsSheet() {
    showWeightIncrementsSheet(context);
  }

  /// Show exercise details sheet (muscles, description, etc.)
  /// Hybrid approach: shows static data immediately, then loads AI insights
  void _showExerciseDetailsSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _ExerciseDetailsSheetContent(
          exercise: exercise,
        ),
      ),
    );
  }

  /// Build a detail row for exercise info sheet
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show warmup sheet
  void _showWarmupSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _buildInfoSheet(
          title: 'Warm Up',
          content: 'Warming up helps prevent injury and improves performance.\n\nRecommended: 1-2 lighter sets before working sets.',
          icon: Icons.whatshot_outlined,
        ),
      ),
    );
  }

  /// Show targets sheet
  void _showTargetsSheet(WorkoutExercise exercise) {
    final setTargets = exercise.setTargets ?? [];
    showGlassSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
        ),
        );
      },
    );
  }

  /// Show enhanced notes sheet with audio, photo, and voice-to-text
  void _showNotesSheet(WorkoutExercise exercise) {
    // Get existing notes for this exercise if any
    final exerciseIndex = _exercises.indexOf(exercise);
    String existingNotes = '';
    if (exerciseIndex >= 0 && _completedSets.containsKey(exerciseIndex)) {
      final sets = _completedSets[exerciseIndex]!;
      // Get notes from the most recent set with notes
      for (final set in sets.reversed) {
        if (set.notes != null && set.notes!.isNotEmpty) {
          existingNotes = set.notes!;
          break;
        }
      }
    }

    showEnhancedNotesSheet(
      context,
      initialNotes: existingNotes,
      onSave: (notes, audioPath, photoPaths) {
        // Store notes - could be applied to current set or exercise-level
        debugPrint('📝 Notes saved: $notes');
        if (audioPath != null) debugPrint('🎤 Audio: $audioPath');
        if (photoPaths.isNotEmpty) debugPrint('📷 Photos: ${photoPaths.length}');

        // Notes are saved via the callback - can extend to store audio/photos as needed
      },
    );
  }

  /// Show superset sheet
  void _showSupersetSheet() {
    final currentExercise = _exercises[_viewingExerciseIndex];
    final isInSuperset = currentExercise.isInSuperset;
    final groupId = currentExercise.supersetGroup;

    if (isInSuperset && groupId != null) {
      // Find all exercises in this superset
      final supersetExercises = <WorkoutExercise>[];
      for (final ex in _exercises) {
        if (ex.supersetGroup == groupId) {
          supersetExercises.add(ex);
        }
      }

      showGlassSheet(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return GlassSheet(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Colors.purple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Superset (${supersetExercises.length} exercises)',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // List exercises in superset
                ...supersetExercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.name,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                // Break superset button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _breakSuperset(groupId);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Superset removed'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_off),
                    label: const Text('Break Superset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Hint text
                Center(
                  child: Text(
                    'Or drag exercises together to add more',
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
          );
        },
      );
    } else {
      // Not in a superset - show instructions
      showGlassSheet(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return GlassSheet(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Colors.purple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create Superset',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to create a superset:',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '1',
                        text: 'Long-press an exercise thumbnail below',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '2',
                        text: 'Drag it onto another exercise',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '3',
                        text: 'Release to create a superset pair',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Supersets help you save time by alternating between exercises with minimal rest.',
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildInstructionRow({
    required bool isDark,
    required String step,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Show equipment sheet
  void _showEquipmentSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _buildInfoSheet(
          title: 'Equipment',
          content: 'Required: ${exercise.equipment ?? 'Bodyweight'}\n\nNo equipment? Tap Swap to find alternatives.',
          icon: Icons.fitness_center,
        ),
      ),
    );
  }

  /// Show history sheet
  void _showHistorySheet(WorkoutExercise exercise) {
    final previousSets = _previousSets[_viewingExerciseIndex] ?? [];
    showGlassSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassSheet(
          child: Padding(
            padding: const EdgeInsets.all(20),
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

    // Persist the weight unit preference to backend
    _saveWeightUnitPreference(_useKg ? 'kg' : 'lbs');
  }

  /// Save weight unit preference to backend (non-blocking)
  Future<void> _saveWeightUnitPreference(String unit) async {
    try {
      await ref.read(authStateProvider.notifier).updateUserProfile({
        'weight_unit': unit,
      });
      debugPrint('✅ [WeightUnit] Saved preference: $unit');
    } catch (e) {
      debugPrint('⚠️ [WeightUnit] Failed to save preference: $e');
      // Don't show error to user - local toggle still works
    }
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

  /// Show RIR picker to edit target RIR for a set
  void _showRirPicker(int setIndex, int? currentRir) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedRir = currentRir ?? 2;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Set Target RIR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Set ${setIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // RIR options (0-4)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rir = index;
                      final isSelected = selectedRir == rir;
                      final color = WorkoutDesign.getRirColor(rir);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() => selectedRir = rir);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$rir',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? WorkoutDesign.getRirTextColor(rir)
                                    : color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // RIR label explanation
                  Center(
                    child: Text(
                      _getRirDescription(selectedRir),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateSetTargetRir(setIndex, selectedRir);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WorkoutDesign.getRirColor(selectedRir),
                        foregroundColor: WorkoutDesign.getRirTextColor(selectedRir),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRirDescription(int rir) {
    switch (rir) {
      case 0:
        return 'Failure - No reps left in tank';
      case 1:
        return 'Very hard - Maybe 1 more rep';
      case 2:
        return 'Hard - Could do 2 more reps';
      case 3:
        return 'Moderate - 3 reps in reserve';
      case 4:
        return 'Easy - 4+ reps in reserve';
      default:
        return '';
    }
  }

  void _updateSetTargetRir(int setIndex, int newRir) {
    // Update the exercise's set targets if available
    final exercise = _exercises[_viewingExerciseIndex];
    if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
      setState(() {
        // Create a new list with the updated RIR
        final updatedTargets = List<SetTarget>.from(exercise.setTargets!);
        final oldTarget = updatedTargets[setIndex];
        updatedTargets[setIndex] = SetTarget(
          setNumber: oldTarget.setNumber,
          setType: oldTarget.setType,
          targetWeightKg: oldTarget.targetWeightKg,
          targetReps: oldTarget.targetReps,
          targetRir: newRir,
        );
        // Update the exercise with new targets
        _exercises[_viewingExerciseIndex] = exercise.copyWith(setTargets: updatedTargets);
      });
    }
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

      // Update data outside setState - insert at correct position
      _completedSets[_viewingExerciseIndex] ??= [];
      if (setIndex >= _completedSets[_viewingExerciseIndex]!.length) {
        // Append at end
        _completedSets[_viewingExerciseIndex]!.add(setLog);
      } else {
        // Insert at position
        _completedSets[_viewingExerciseIndex]!.insert(setIndex, setLog);
      }

      // Only call setState for the animation trigger variable
      setState(() {
        _justCompletedSetIndex = setIndex;
      });
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
      setState(() {}); // Trigger rebuild for uncomplete
    }
  }

  // ========================================================================
  // BOTTOM BAR ACTION METHODS
  // ========================================================================

  /// Show hydration dialog and sync with nutrition tab
  Future<void> _showHydrationDialog([DrinkType initialType = DrinkType.water]) async {
    final result = await showHydrationDialog(
      context: context,
      totalIntakeMl: _totalDrinkIntakeMl,
      initialDrinkType: initialType,
    );

    if (result != null && result.amountMl > 0) {
      // Update local workout state
      setState(() => _totalDrinkIntakeMl += result.amountMl);

      // Sync with hydration provider (nutrition tab)
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final success = await ref.read(hydrationProvider.notifier).logHydration(
          userId: userId,
          drinkType: result.drinkType.value,
          amountMl: result.amountMl,
          workoutId: widget.workout.id,
          notes: 'Logged during workout',
        );

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '${result.amountMl}ml ${result.drinkType.label} logged'
                  : '${result.drinkType.label} logged locally (sync failed)'),
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
              content: Text('${result.amountMl}ml ${result.drinkType.label} logged'),
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

  /// Handle exercise reorder from thumbnail strip drag
  void _onExercisesReordered(int oldIndex, int newIndex) {
    // ReorderableListView passes newIndex as the position BEFORE removal
    // So if moving down (oldIndex < newIndex), we need to subtract 1
    // because after removing the item, all indices shift down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Don't do anything if indices are the same
    if (oldIndex == newIndex) return;

    debugPrint('🔄 Reordering exercise from $oldIndex to $newIndex');
    debugPrint('🔄 Before: ${_exercises.map((e) => e.name).toList()}');

    // Check if the dragged exercise is in a superset
    final draggedExercise = _exercises[oldIndex];
    final supersetGroupId = draggedExercise.supersetGroup;
    bool removedFromSuperset = false;

    // Create a new list with the reordered exercises
    final reorderedList = List<WorkoutExercise>.from(_exercises);
    var exercise = reorderedList.removeAt(oldIndex);
    reorderedList.insert(newIndex, exercise);

    // If exercise was in a superset, check if it's still adjacent to its group
    if (supersetGroupId != null) {
      // Find where other superset members are after the reorder
      final otherMemberIndices = <int>[];
      for (int i = 0; i < reorderedList.length; i++) {
        if (i != newIndex && reorderedList[i].supersetGroup == supersetGroupId) {
          otherMemberIndices.add(i);
        }
      }

      if (otherMemberIndices.isNotEmpty) {
        // Check if newIndex is adjacent to any superset member
        final isAdjacentToGroup = otherMemberIndices.any((i) => (i - newIndex).abs() == 1);

        if (!isAdjacentToGroup) {
          // Dragged away from superset - remove from group
          debugPrint('🔗 Removing ${exercise.name} from superset $supersetGroupId (dragged away)');
          exercise = exercise.copyWith(clearSuperset: true);
          reorderedList[newIndex] = exercise;
          removedFromSuperset = true;

          // If only 1 exercise remains in the superset, clear it too
          if (otherMemberIndices.length == 1) {
            final lastMemberIndex = otherMemberIndices.first;
            debugPrint('🔗 Clearing last member of superset: ${reorderedList[lastMemberIndex].name}');
            reorderedList[lastMemberIndex] = reorderedList[lastMemberIndex].copyWith(clearSuperset: true);
          }
        }
      }
    }

    debugPrint('🔄 After: ${reorderedList.map((e) => e.name).toList()}');

    // Remap all index-based state maps (create new maps first, then reassign)
    final newCompletedSets = _remapIndexMap(_completedSets, oldIndex, newIndex);
    final newTotalSets = _remapIndexMap(_totalSetsPerExercise, oldIndex, newIndex);
    final newPreviousSets = _remapIndexMap(_previousSets, oldIndex, newIndex);
    final newRepProgression = _remapIndexMap(_repProgressionPerExercise, oldIndex, newIndex);

    // Calculate new indices before setState
    final newCurrentIndex = _remapSingleIndex(_currentExerciseIndex, oldIndex, newIndex);
    final newViewingIndex = _remapSingleIndex(_viewingExerciseIndex, oldIndex, newIndex);

    setState(() {
      // Replace entire exercises list
      _exercises = reorderedList;
      _precomputeSupersetIndices();

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
        ..addAll(newRepProgression);

      // Update current/viewing indices if they were affected
      _currentExerciseIndex = newCurrentIndex;
      _viewingExerciseIndex = newViewingIndex;
    });

    // Show feedback if removed from superset
    if (removedFromSuperset) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${draggedExercise.name} removed from superset'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Helper to remap a map's integer keys after reorder
  Map<int, T> _remapIndexMap<T>(Map<int, T> original, int oldIndex, int newIndex) {
    final result = <int, T>{};
    for (final entry in original.entries) {
      final newKey = _remapSingleIndex(entry.key, oldIndex, newIndex);
      result[newKey] = entry.value;
    }
    return result;
  }

  /// Helper to remap a single index after reorder
  int _remapSingleIndex(int index, int oldIndex, int newIndex) {
    if (index == oldIndex) {
      return newIndex;
    } else if (oldIndex < newIndex) {
      // Moved down: indices between old and new shift up by 1
      if (index > oldIndex && index <= newIndex) {
        return index - 1;
      }
    } else {
      // Moved up: indices between new and old shift down by 1
      if (index >= newIndex && index < oldIndex) {
        return index + 1;
      }
    }
    return index;
  }

  /// Handle superset creation from drag-and-drop on thumbnail strip
  void _onSupersetFromDrag(int draggedIndex, int targetIndex) {
    HapticFeedback.mediumImpact();

    final draggedExercise = _exercises[draggedIndex];
    final targetExercise = _exercises[targetIndex];

    // Check if target is already in a superset - add to existing group
    final existingGroupId = targetExercise.supersetGroup;

    // Check if dragged is already in a superset
    final draggedGroupId = draggedExercise.supersetGroup;

    int groupId;
    String snackbarMessage;

    if (existingGroupId != null) {
      // Add to existing superset group
      groupId = existingGroupId;

      // Find the max order in this group
      int maxOrder = 0;
      for (final ex in _exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) {
            maxOrder = ex.supersetOrder!;
          }
        }
      }

      // Count how many exercises are in this group (for snackbar message)
      final groupCount = _exercises.where((ex) => ex.supersetGroup == groupId).length + 1;
      snackbarMessage = 'Added ${draggedExercise.name} to superset ($groupCount exercises)';

      debugPrint('🔗 Adding to superset: ${draggedExercise.name} -> group $groupId (order ${maxOrder + 1})');

      setState(() {
        // If dragged was in a different superset, remove it from that one first
        if (draggedGroupId != null && draggedGroupId != groupId) {
          // Check if its old group has only 1 other exercise - if so, clear that one too
          final oldGroupMembers = _exercises.where((ex) => ex.supersetGroup == draggedGroupId).toList();
          if (oldGroupMembers.length == 2) {
            // Only 2 in old group including dragged, so the other one should be cleared
            for (int i = 0; i < _exercises.length; i++) {
              if (_exercises[i].supersetGroup == draggedGroupId && i != draggedIndex) {
                _exercises[i] = _exercises[i].copyWith(clearSuperset: true);
              }
            }
          }
        }

        // Update dragged exercise with new group info
        _exercises[draggedIndex] = _exercises[draggedIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: maxOrder + 1,
        );

        // Move to be adjacent to the group if not already
        _moveExerciseToSuperset(draggedIndex, targetIndex);
      });
    } else if (draggedGroupId != null) {
      // Target is not in a superset, but dragged is - add target to dragged's group
      groupId = draggedGroupId;

      // Find max order in dragged's group
      int maxOrder = 0;
      for (final ex in _exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) {
            maxOrder = ex.supersetOrder!;
          }
        }
      }

      final groupCount = _exercises.where((ex) => ex.supersetGroup == groupId).length + 1;
      snackbarMessage = 'Added ${targetExercise.name} to superset ($groupCount exercises)';

      debugPrint('🔗 Adding target to dragged superset: ${targetExercise.name} -> group $groupId');

      setState(() {
        _exercises[targetIndex] = _exercises[targetIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: maxOrder + 1,
        );

        // Move target to be adjacent to the group
        _moveExerciseToSuperset(targetIndex, draggedIndex);
      });
    } else {
      // Neither is in a superset - create new one
      int maxGroup = 0;
      for (final ex in _exercises) {
        if (ex.supersetGroup != null && ex.supersetGroup! > maxGroup) {
          maxGroup = ex.supersetGroup!;
        }
      }
      groupId = maxGroup + 1;
      snackbarMessage = 'Superset: ${draggedExercise.name} + ${targetExercise.name}';

      debugPrint('🔗 Creating new superset: ${draggedExercise.name} + ${targetExercise.name} (group $groupId)');

      setState(() {
        _exercises[draggedIndex] = _exercises[draggedIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: 1,
        );
        _exercises[targetIndex] = _exercises[targetIndex].copyWith(
          supersetGroup: groupId,
          supersetOrder: 2,
        );

        // Move to be adjacent if not already
        _moveExerciseToSuperset(draggedIndex, targetIndex);
      });
    }

    // Show confirmation snackbar - clear any existing first
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(snackbarMessage, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          backgroundColor: Colors.purple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
          closeIconColor: Colors.white70,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => _breakSuperset(groupId),
          ),
        ),
      );
    }
  }

  /// Helper to move an exercise to be adjacent to a superset group
  void _moveExerciseToSuperset(int fromIndex, int toIndex) {
    // If exercises are not adjacent, move fromIndex to be next to toIndex
    if ((fromIndex - toIndex).abs() > 1) {
      final exercise = _exercises.removeAt(fromIndex);
      // Insert after target if from was after, before if from was before
      final insertAt = fromIndex > toIndex ? toIndex + 1 : toIndex;
      _exercises.insert(insertAt, exercise);
      _precomputeSupersetIndices();

      // Remap indices for the move
      final oldIdx = fromIndex;
      final newIdx = insertAt;
      if (oldIdx != newIdx) {
        final newCompletedSets = _remapIndexMap(_completedSets, oldIdx, newIdx);
        final newTotalSets = _remapIndexMap(_totalSetsPerExercise, oldIdx, newIdx);
        final newPreviousSets = _remapIndexMap(_previousSets, oldIdx, newIdx);
        final newRepProgression = _remapIndexMap(_repProgressionPerExercise, oldIdx, newIdx);

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
          ..addAll(newRepProgression);

        _currentExerciseIndex = _remapSingleIndex(_currentExerciseIndex, oldIdx, newIdx);
        _viewingExerciseIndex = _remapSingleIndex(_viewingExerciseIndex, oldIdx, newIdx);
      }
    }
  }

  /// Break a superset by clearing superset info from all exercises in the group
  void _breakSuperset(int groupId) {
    setState(() {
      for (int i = 0; i < _exercises.length; i++) {
        if (_exercises[i].supersetGroup == groupId) {
          _exercises[i] = _exercises[i].copyWith(clearSuperset: true);
        }
      }
    });
    HapticFeedback.mediumImpact();
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
          _precomputeSupersetIndices();
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
          _precomputeSupersetIndices();

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

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  /// Show exercise swap sheet for replacing an exercise
  Future<void> _showSwapSheet(int exerciseIndex) async {
    if (exerciseIndex >= _exercises.length) return;
    final workoutId = widget.workout.id;
    if (workoutId == null) return;

    final exercise = _exercises[exerciseIndex];

    final updatedWorkout = await showExerciseSwapSheet(
      context,
      ref,
      workoutId: workoutId,
      exercise: exercise,
    );

    if (updatedWorkout != null && mounted) {
      // Update local state with the swapped exercise
      setState(() {
        _exercises.clear();
        _exercises.addAll(updatedWorkout.exercises);
        _precomputeSupersetIndices();
        // Reinitialize tracking for all exercises
        _completedSets.clear();
        _totalSetsPerExercise.clear();
        _previousSets.clear();
        for (int i = 0; i < _exercises.length; i++) {
          _completedSets[i] = [];
          final exercise = _exercises[i];
          _totalSetsPerExercise[i] = exercise.hasSetTargets && exercise.setTargets!.isNotEmpty
              ? exercise.setTargets!.length
              : exercise.sets ?? 3;
          _previousSets[i] = [];
        }
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise swapped successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        Navigator.pop(context);
        _showSwapSheet(exerciseIndex);
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
      _precomputeSupersetIndices();

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
              _precomputeSupersetIndices();
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

/// Exercise Details Sheet Content - Hybrid approach
/// Shows static data immediately, then loads AI insights in the background
class _ExerciseDetailsSheetContent extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const _ExerciseDetailsSheetContent({
    required this.exercise,
  });

  @override
  ConsumerState<_ExerciseDetailsSheetContent> createState() =>
      _ExerciseDetailsSheetContentState();
}

class _ExerciseDetailsSheetContentState
    extends ConsumerState<_ExerciseDetailsSheetContent> {
  ExerciseInsights? _aiInsights;
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    _loadAiInsights();
  }

  Future<void> _loadAiInsights() async {
    try {
      final service = ref.read(exerciseInfoServiceProvider);
      final insights = await service.getExerciseInsights(
        exerciseName: widget.exercise.name,
        primaryMuscle: widget.exercise.primaryMuscle ?? widget.exercise.muscleGroup,
        equipment: widget.exercise.equipment,
        difficulty: widget.exercise.difficulty,
      );
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInsights = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use AppColors for consistent theming
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final exercise = widget.exercise;

    // Get dynamic accent color
    final accentEnum = AccentColorScope.of(context);
    final accentColor = accentEnum.getColor(isDark);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassSurface.withValues(alpha: 0.95)
                : AppColorsLight.glassSurface.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColorsLight.cardBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with title and close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exercise Info',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise name with action pills
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Video pill
                          _buildActionPill(
                            context: context,
                            icon: Icons.play_circle_outline,
                            label: 'Video',
                            onTap: () {
                              Navigator.pop(context);
                              showExerciseInfoSheet(
                                context: context,
                                exercise: exercise,
                              );
                            },
                            accentColor: accentColor,
                            isDark: isDark,
                            textMuted: textMuted,
                          ),
                          const SizedBox(width: 8),
                          // Breathing pill
                          _buildActionPill(
                            context: context,
                            icon: Icons.air,
                            label: 'Breathing',
                            onTap: () {
                              Navigator.pop(context);
                              showBreathingGuide(
                                context: context,
                                exercise: exercise,
                              );
                            },
                            accentColor: accentColor,
                            isDark: isDark,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // === EXERCISE DETAILS ===
                      _buildSectionHeader('Details', Icons.list_alt_rounded, accentColor, textPrimary),
                      const SizedBox(height: 12),

                      // Details card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Primary Muscle
                            _buildDetailRow(
                              icon: Icons.fitness_center,
                              label: 'Primary Muscle',
                              value: exercise.primaryMuscle ?? exercise.muscleGroup ?? 'Not specified',
                              color: accentColor,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            // Secondary Muscles (if available)
                            if (exercise.secondaryMuscles != null)
                              Builder(
                                builder: (context) {
                                  final secondary = exercise.secondaryMuscles;
                                  String value;
                                  if (secondary is List) {
                                    value = secondary.join(', ');
                                  } else if (secondary is String && secondary.isNotEmpty) {
                                    value = secondary;
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildDetailRow(
                                    icon: Icons.accessibility_new,
                                    label: 'Secondary Muscles',
                                    value: value,
                                    color: accentColor,
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                },
                              ),

                            // Equipment
                            _buildDetailRow(
                              icon: Icons.hardware,
                              label: 'Equipment',
                              value: exercise.equipment ?? 'Bodyweight',
                              color: accentColor,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            // Difficulty (if available)
                            if (exercise.difficulty != null)
                              _buildDetailRow(
                                icon: Icons.speed,
                                label: 'Difficulty',
                                value: exercise.difficulty!,
                                color: accentColor,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isLast: true,
                              ),
                          ],
                        ),
                      ),

                      // === SETUP & INSTRUCTIONS ===
                      const SizedBox(height: 24),
                      _buildSectionHeader('Setup', Icons.checklist_rounded, accentColor, textPrimary),
                      const SizedBox(height: 12),
                      _buildSetupInstructionsList(exercise, isDark, textPrimary, accentColor, cardBackground),

                      const SizedBox(height: 24),

                      // === AI COACH TIPS (loaded in background) ===
                      _buildAiInsightsSection(isDark, textPrimary, textSecondary, accentColor, cardBackground),

                      // Tip about Video button
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 20,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap "Video" to watch form demonstration',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header with icon
  Widget _buildSectionHeader(String title, IconData icon, Color accentColor, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build a detail row for exercise info
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(bool isDark, Color textPrimary, Color textSecondary, Color accentColor, Color cardBackground) {
    if (_isLoadingInsights) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading AI coach tips...',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_aiInsights == null || _aiInsights!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader('AI Coach Tips', Icons.auto_awesome, accentColor, textPrimary),
        const SizedBox(height: 12),

        // Tips card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Cues
              if (_aiInsights!.formCues != null) ...[
                _buildInsightItem(
                  icon: Icons.check_circle_outline,
                  title: 'Form Cues',
                  content: _aiInsights!.formCues!,
                  color: const Color(0xFF22C55E), // Green for success
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 16),
              ],

              // Common Mistakes
              if (_aiInsights!.commonMistakes != null) ...[
                _buildInsightItem(
                  icon: Icons.warning_amber_outlined,
                  title: 'Watch Out For',
                  content: _aiInsights!.commonMistakes!,
                  color: const Color(0xFFF59E0B), // Amber for warnings
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 16),
              ],

              // Pro Tip
              if (_aiInsights!.proTip != null)
                _buildInsightItem(
                  icon: Icons.lightbulb_outline,
                  title: 'Pro Tip',
                  content: _aiInsights!.proTip!,
                  color: accentColor,
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required bool isDark,
    required Color textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build an action pill button (Video, Breathing, etc.)
  Widget _buildActionPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDark,
    required Color textMuted,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build setup instructions list with numbered steps
  Widget _buildSetupInstructionsList(
    WorkoutExercise exercise,
    bool isDark,
    Color textPrimary,
    Color accentColor,
    Color cardBackground,
  ) {
    final instructions = _getSetupInstructions(exercise.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < instructions.length - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Get setup instructions based on exercise type
  List<String> _getSetupInstructions(String exerciseName) {
    final name = exerciseName.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Set up the bench at the appropriate angle (flat, incline, or decline)',
        'Grip the bar slightly wider than shoulder-width',
        'Plant your feet firmly on the ground',
        'Retract your shoulder blades and maintain a slight arch',
        'Unrack and position the weight above your chest',
      ];
    } else if (name.contains('squat')) {
      return [
        'Position the bar on your upper back (not your neck)',
        'Stand with feet shoulder-width apart, toes slightly out',
        'Brace your core before descending',
        'Keep your knees tracking over your toes',
        'Descend until thighs are parallel to the floor',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Stand with feet hip-width apart, bar over mid-foot',
        'Grip the bar just outside your legs',
        'Keep your back flat and chest up',
        'Take the slack out of the bar before pulling',
        'Drive through your heels and push hips forward',
      ];
    } else if (name.contains('row')) {
      return [
        'Hinge at the hips with a slight knee bend',
        'Keep your back flat and core engaged',
        'Grip the weight with arms extended',
        'Pull the weight toward your lower chest',
        'Squeeze your shoulder blades together at the top',
      ];
    } else if (name.contains('curl')) {
      return [
        'Stand with feet shoulder-width apart',
        'Grip the weight with palms facing up',
        'Keep your elbows close to your sides',
        'Curl the weight toward your shoulders',
        'Lower with control to full extension',
      ];
    } else if (name.contains('pull') && (name.contains('up') || name.contains('down'))) {
      return [
        'Grip the bar slightly wider than shoulder-width',
        'Hang with arms fully extended',
        'Engage your lats before pulling',
        'Pull your elbows down and back',
        'Lower with control to full extension',
      ];
    } else if (name.contains('fly') || name.contains('flye')) {
      return [
        'Lie on a flat or incline bench',
        'Hold dumbbells above your chest, palms facing',
        'Keep a slight bend in your elbows',
        'Lower the weights in an arc to the sides',
        'Squeeze your chest to bring weights back up',
      ];
    } else if (name.contains('lunge')) {
      return [
        'Stand with feet hip-width apart',
        'Step forward or backward into position',
        'Lower until your back knee nearly touches the ground',
        'Keep your front knee over your ankle',
        'Push through your front heel to return',
      ];
    }

    // Default generic instructions
    return [
      'Set up your equipment and check form',
      'Warm up with lighter weight first',
      'Position yourself in the starting position',
      'Focus on controlled movements throughout',
      'Breathe consistently - exhale on exertion',
    ];
  }
}
