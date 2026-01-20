import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/providers/social_provider.dart';
import '../../core/providers/tts_provider.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../data/rest_messages.dart';
import '../../widgets/log_1rm_sheet.dart';
import '../../widgets/responsive_layout.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../challenges/widgets/challenge_quit_dialog.dart';
import 'widgets/transition_countdown_overlay.dart';
import 'widgets/set_adjustment_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/superset_pair_sheet.dart';
import '../../data/repositories/superset_repository.dart';
import '../../core/providers/user_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'widgets/exercise_thumbnail_strip.dart';
import 'widgets/video_pip.dart';
import 'widgets/rest_timer_overlay.dart';
import 'widgets/fatigue_alert_modal.dart';
import 'widgets/set_tracking_section.dart';
import 'widgets/hydration_dialog.dart';
import 'widgets/quit_workout_dialog.dart';
import 'mixins/exercise_management_mixin.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/models/smart_weight_suggestion.dart';
import '../../core/services/fatigue_service.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../widgets/heart_rate_display.dart';
import 'workout_complete_screen.dart' show HeartRateReadingData;

/// Log for a single set
class SetLog {
  final int reps;
  final double weight;
  final DateTime completedAt;
  final String setType; // 'working', 'warmup', 'failure', 'amrap'
  final int targetReps; // Original planned/target reps for this set

  SetLog({
    required this.reps,
    required this.weight,
    DateTime? completedAt,
    this.setType = 'working',
    this.targetReps = 0,
  }) : completedAt = completedAt ?? DateTime.now();

  /// Whether the actual reps differ from the target
  bool get differsFromTarget => targetReps > 0 && reps != targetReps;

  /// Calculate accuracy percentage (actual / target * 100)
  int get accuracyPercent => targetReps > 0 ? ((reps / targetReps) * 100).round() : 100;

  /// Whether user met or exceeded the target
  bool get metTarget => targetReps <= 0 || reps >= targetReps;
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId; // If this workout is from a challenge
  final Map<String, dynamic>? challengeData; // Challenge details (opponent, stats to beat)

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with ResponsiveMixin {
  // Warmup phase state
  bool _isInWarmupPhase = true; // Start with warmup
  int _currentWarmupIndex = 0;
  Timer? _warmupTimer;
  int _warmupSecondsRemaining = 0;
  bool _isWarmupTimerRunning = false;

  // Standard warmup exercises
  static const List<Map<String, dynamic>> _warmupExercises = [
    {'name': 'Jumping Jacks', 'duration': 60, 'icon': Icons.directions_run},
    {'name': 'Arm Circles', 'duration': 30, 'icon': Icons.loop},
    {'name': 'Hip Circles', 'duration': 30, 'icon': Icons.refresh},
    {'name': 'Leg Swings', 'duration': 30, 'icon': Icons.swap_horiz},
    {'name': 'Light Cardio', 'duration': 120, 'icon': Icons.favorite},
  ];

  // Challenge exercise phase (after main workout, before stretches - for beginners)
  bool _isInChallengePhase = false;
  bool _challengeAccepted = false;
  bool _challengeCompleted = false;
  int _challengeCurrentSet = 1;
  final List<SetLog> _challengeSets = [];

  // Stretch phase state (after workout, before completion)
  bool _isInStretchPhase = false;
  int _currentStretchIndex = 0;
  Timer? _stretchTimer;
  int _stretchSecondsRemaining = 0;
  bool _isStretchTimerRunning = false;

  // Standard stretch exercises
  static const List<Map<String, dynamic>> _stretchExercises = [
    {'name': 'Quad Stretch', 'duration': 30, 'icon': Icons.self_improvement},
    {'name': 'Hamstring Stretch', 'duration': 30, 'icon': Icons.self_improvement},
    {'name': 'Shoulder Stretch', 'duration': 30, 'icon': Icons.self_improvement},
    {'name': 'Chest Opener', 'duration': 30, 'icon': Icons.self_improvement},
    {'name': 'Cat-Cow Stretch', 'duration': 60, 'icon': Icons.self_improvement},
  ];

  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isRestingBetweenExercises = false; // Track if rest is between exercises
  bool _isPaused = false;
  bool _isComplete = false;
  bool _showInstructions = false;

  // Video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = true;
  String? _imageUrl;
  String? _videoUrl;
  bool _isLoadingMedia = true;
  bool _showVideoPip = true; // PiP video visibility

  // Timers
  Timer? _workoutTimer;
  Timer? _restTimer;
  int _workoutSeconds = 0;
  int _restSecondsRemaining = 0;
  int _initialRestDuration = 0; // Track initial rest for progress bar
  String _currentRestMessage = ''; // Current encouragement message

  // Tracking - now stores weight/reps per set
  final Map<int, List<SetLog>> _completedSets = {};
  int _totalCaloriesBurned = 0;

  // Inline input controllers for real-time weight/reps entry
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _useKg = true; // true = kg, false = lbs - initialized from user preference
  bool _unitInitialized = false; // Track if unit has been initialized from user preference

  // Set tracking overlay
  bool _showSetOverlay = true; // Show by default

  // Mock previous session data (will be fetched from API)
  final Map<int, List<Map<String, dynamic>>> _previousSets = {};

  // Dynamic sets count per exercise (can add more sets)
  final Map<int, int> _totalSetsPerExercise = {};

  // Original sets count per exercise (for tracking adjustments)
  final Map<int, int> _originalSetsPerExercise = {};

  // Set adjustments log (exercise index -> list of adjustments)
  final Map<int, List<SetAdjustment>> _setAdjustments = {};

  // Edited sets tracking (exercise index -> set index -> true if edited)
  final Map<int, Set<int>> _editedSets = {};

  // Exercise navigation in Set Tracker (independent of video/main view)
  int _viewingExerciseIndex = 0;

  // Mutable exercise list for reordering
  late List<WorkoutExercise> _exercises;

  // Mutable workout reference (can be updated after superset changes)
  Workout? _workout;

  // Drink intake tracking (in ml)
  int _totalDrinkIntakeMl = 0;

  // Expanded active row for bigger input controls (default: expanded for better UX)
  bool _isActiveRowExpanded = true;

  // Rest interval tracking
  final List<Map<String, dynamic>> _restIntervals = [];
  DateTime? _lastSetCompletedAt;
  DateTime? _lastExerciseStartedAt;
  bool _lastSetWasFast = false; // Tracks if the most recent set was completed too fast

  // Time tracking per exercise (start time -> total seconds)
  final Map<int, int> _exerciseTimeSeconds = {};
  DateTime? _currentExerciseStartTime;

  // Animation state for Done button press
  bool _isDoneButtonPressed = false;
  // Track which set just completed for burst animation
  int? _justCompletedSetIndex;

  // Historical data loading state
  bool _isLoadingHistory = true;
  // Map of exercise name -> max weight ever lifted (for accurate PR detection)
  final Map<String, double> _exerciseMaxWeights = {};

  // Transition countdown state (between exercises)
  bool _isInTransition = false;
  int _transitionSecondsRemaining = 0;
  Timer? _transitionTimer;
  static const int _transitionDuration = 7; // Configurable: 5-10 seconds
  String? _nextExerciseImageUrl; // Cached image URL for next exercise

  // AI-powered rest suggestion state
  RestSuggestion? _restSuggestion;
  bool _isLoadingRestSuggestion = false;

  // AI-powered smart weight suggestion state
  SmartWeightSuggestion? _smartWeightSuggestion;
  bool _isLoadingSmartWeight = false;
  bool _isWeightFromAiSuggestion = false;

  // Fatigue detection state
  bool _showFatigueAlert = false;
  FatigueAlertData? _fatigueAlertData;

  // Fatigue service instance
  FatigueService? _fatigueService;

  // Heart rate tracking - clear history when starting new workout
  bool _heartRateHistoryCleared = false;

  @override
  void initState() {
    super.initState();
    // Initialize mutable workout and exercises list (for reordering and superset updates)
    _workout = widget.workout;
    _exercises = List.from(widget.workout.exercises);
    // Initialize input controllers with default values from first exercise
    // Prefer AI-generated setTargets data over generic exercise weight
    final firstExercise = _exercises[0];
    final firstSetTarget = firstExercise.getTargetForSet(1);
    final initialReps = firstSetTarget?.targetReps ?? firstExercise.reps ?? 10;
    final initialWeight = firstSetTarget?.targetWeightKg ?? firstExercise.weight ?? 0;
    _repsController = TextEditingController(text: initialReps.toString());
    _weightController = TextEditingController(text: initialWeight.toString());
    _startWorkoutTimer();
    // Initialize completed sets tracking
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      final sets = exercise.sets ?? 3;
      _totalSetsPerExercise[i] = sets;
      _originalSetsPerExercise[i] = sets; // Track original for adjustment detection
      _setAdjustments[i] = [];
      _editedSets[i] = {};
      // Initialize with empty data - will be populated from API
      _previousSets[i] = [];
    }
    // Fetch historical data from backend
    _fetchExerciseHistory();
    // Initialize fatigue service
    _initFatigueService();
    // Don't fetch media yet - wait for warmup to complete
    // Media will be fetched in _finishWarmup()
    // Start exercise time tracking for first exercise
    _currentExerciseStartTime = DateTime.now();
    _lastExerciseStartedAt = DateTime.now();

    // Auto-start warmup timer for first exercise after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isInWarmupPhase) {
        _startWarmupTimer();
      }
    });
  }

  /// Fetch historical performance data for all exercises in the workout
  Future<void> _fetchExerciseHistory() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    final repository = ref.read(workoutRepositoryProvider);

    // Fetch history for all exercises in parallel
    final futures = <Future<void>>[];

    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      futures.add(_fetchSingleExerciseHistory(repository, userId, exercise, i));
    }

    // Also fetch strength records (PRs) for more accurate PR detection
    futures.add(_fetchStrengthRecords(repository, userId));

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isLoadingHistory = false);
      debugPrint('✅ [ActiveWorkout] Historical data loaded for ${_exercises.length} exercises');
    }
  }

  /// Fetch history for a single exercise
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
            _previousSets[exerciseIndex] = sets.map((s) => {
              'set': s['set_number'] ?? 1,
              'weight': (s['weight_kg'] as num?)?.toDouble() ?? 0.0,
              'reps': s['reps_completed'] ?? 10,
            }).toList();
          });
        }

        // Track max weight for PR detection
        for (final set in sets) {
          final weight = (set['weight_kg'] as num?)?.toDouble() ?? 0.0;
          final currentMax = _exerciseMaxWeights[exercise.name] ?? 0.0;
          if (weight > currentMax) {
            _exerciseMaxWeights[exercise.name] = weight;
          }
        }

        debugPrint('📊 [ActiveWorkout] Loaded ${sets.length} previous sets for ${exercise.name}');
      } else {
        debugPrint('📊 [ActiveWorkout] No previous history for ${exercise.name}');
      }
    } catch (e) {
      debugPrint('⚠️ [ActiveWorkout] Failed to load history for ${exercise.name}: $e');
    }
  }

  /// Fetch strength records (PRs) for all exercises
  Future<void> _fetchStrengthRecords(WorkoutRepository repository, String userId) async {
    try {
      final records = await repository.getStrengthRecords(
        userId: userId,
        prsOnly: true,
        limit: 100,
      );

      for (final record in records) {
        final exerciseName = record['exercise_name'] as String?;
        final weight = (record['weight_kg'] as num?)?.toDouble() ?? 0.0;

        if (exerciseName != null && weight > 0) {
          final currentMax = _exerciseMaxWeights[exerciseName] ?? 0.0;
          if (weight > currentMax) {
            _exerciseMaxWeights[exerciseName] = weight;
          }
        }
      }

      debugPrint('🏆 [ActiveWorkout] Loaded ${records.length} PRs, tracking ${_exerciseMaxWeights.length} exercises');
    } catch (e) {
      debugPrint('⚠️ [ActiveWorkout] Failed to load strength records: $e');
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _warmupTimer?.cancel();
    _stretchTimer?.cancel();
    _transitionTimer?.cancel();
    _videoController?.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WARMUP PHASE METHODS
  // ─────────────────────────────────────────────────────────────────────────

  void _startWarmupTimer() {
    final duration = _warmupExercises[_currentWarmupIndex]['duration'] as int;
    setState(() {
      _warmupSecondsRemaining = duration;
      _isWarmupTimerRunning = true;
    });

    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_warmupSecondsRemaining > 0) {
        setState(() {
          _warmupSecondsRemaining--;
        });

        // Haptic feedback at key moments
        if (_warmupSecondsRemaining == 3 || _warmupSecondsRemaining == 2 || _warmupSecondsRemaining == 1) {
          HapticFeedback.lightImpact();
        }
      } else {
        // Auto-advance to next warmup exercise
        _nextWarmupExercise();
      }
    });
  }

  void _pauseWarmupTimer() {
    _warmupTimer?.cancel();
    setState(() {
      _isWarmupTimerRunning = false;
    });
  }

  void _resumeWarmupTimer() {
    if (_warmupSecondsRemaining > 0) {
      setState(() {
        _isWarmupTimerRunning = true;
      });
      _warmupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_warmupSecondsRemaining > 0) {
          setState(() {
            _warmupSecondsRemaining--;
          });
        } else {
          _nextWarmupExercise();
        }
      });
    }
  }

  void _nextWarmupExercise() {
    _warmupTimer?.cancel();
    HapticFeedback.mediumImpact();

    if (_currentWarmupIndex < _warmupExercises.length - 1) {
      setState(() {
        _currentWarmupIndex++;
        _isWarmupTimerRunning = false;
        _warmupSecondsRemaining = 0;
      });
      // Auto-start timer for next exercise
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isInWarmupPhase) {
          _startWarmupTimer();
        }
      });
    } else {
      // Warmup complete - transition to main workout
      _finishWarmup();
    }
  }

  void _skipWarmup() {
    _warmupTimer?.cancel();
    _finishWarmup();
  }

  void _finishWarmup() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isInWarmupPhase = false;
      _isWarmupTimerRunning = false;
    });
    // Now fetch media for first exercise
    _fetchMediaForExercise(_exercises[0]);
    // Fetch smart weight suggestion for first exercise
    _fetchSmartWeight();
  }

  Widget _buildWarmupScreen(BuildContext context, bool isDark, Color backgroundColor) {
    final currentWarmup = _warmupExercises[_currentWarmupIndex];
    final warmupProgress = (_currentWarmupIndex + 1) / _warmupExercises.length;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return WillPopScope(
      onWillPop: () async {
        _showQuitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with timer and skip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: () => _showQuitDialog(),
                    ),
                    // Workout timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: AppColors.cyan),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_workoutSeconds),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Skip warmup button
                    TextButton(
                      onPressed: _skipWarmup,
                      child: Text(
                        'Skip Warmup',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Warmup header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.whatshot,
                        color: AppColors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WARM UP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentWarmupIndex + 1} of ${_warmupExercises.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: warmupProgress,
                    backgroundColor: elevatedColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                    minHeight: 6,
                  ),
                ),

                const Spacer(),

                // Current warmup exercise
                Center(
                  child: Column(
                    children: [
                      // Exercise icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentWarmup['icon'] as IconData,
                          size: 64,
                          color: AppColors.orange,
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 32),

                      // Exercise name
                      Text(
                        currentWarmup['name'] as String,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms),

                      const SizedBox(height: 16),

                      // Duration or timer
                      if (_isWarmupTimerRunning || _warmupSecondsRemaining > 0)
                        Text(
                          _formatTime(_warmupSecondsRemaining),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            color: AppColors.orange,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 2000.ms, color: AppColors.orange.withOpacity(0.3))
                      else
                        Text(
                          '${currentWarmup['duration']} sec',
                          style: TextStyle(
                            fontSize: 24,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Upcoming warmup exercises
                if (_currentWarmupIndex < _warmupExercises.length - 1) ...[
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _warmupExercises.length - _currentWarmupIndex - 1,
                      itemBuilder: (context, index) {
                        final warmup = _warmupExercises[_currentWarmupIndex + 1 + index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: elevatedColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                warmup['icon'] as IconData,
                                size: 20,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                warmup['name'] as String,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    // Start/Pause timer button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isWarmupTimerRunning) {
                            _pauseWarmupTimer();
                          } else if (_warmupSecondsRemaining > 0) {
                            _resumeWarmupTimer();
                          } else {
                            _startWarmupTimer();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isWarmupTimerRunning
                              ? AppColors.orange.withOpacity(0.3)
                              : AppColors.orange,
                          foregroundColor: _isWarmupTimerRunning
                              ? AppColors.orange
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _isWarmupTimerRunning
                              ? Icons.pause
                              : (_warmupSecondsRemaining > 0 ? Icons.play_arrow : Icons.timer),
                        ),
                        label: Text(
                          _isWarmupTimerRunning
                              ? 'Pause'
                              : (_warmupSecondsRemaining > 0 ? 'Resume' : 'Start Timer'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Next/Done button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _nextWarmupExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _currentWarmupIndex < _warmupExercises.length - 1
                              ? Icons.skip_next
                              : Icons.check,
                        ),
                        label: Text(
                          _currentWarmupIndex < _warmupExercises.length - 1
                              ? 'Next'
                              : 'Start Workout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the stretch screen UI (shown after workout, before completion)
  /// Build the challenge exercise screen (for beginners trying an advanced exercise)
  Widget _buildChallengeExerciseScreen(BuildContext context, bool isDark, Color backgroundColor) {
    final challengeExercise = widget.workout.challengeExercise!;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return WillPopScope(
      onWillPop: () async {
        // Confirm skip challenge
        final shouldSkip = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Skip Challenge?'),
            content: const Text('Are you sure you want to skip the challenge exercise?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
        if (shouldSkip == true) {
          _skipChallengeExercise();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button
                    TextButton.icon(
                      onPressed: _skipChallengeExercise,
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                      ),
                    ),
                    // Challenge badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.3),
                            Colors.deepOrange.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'CHALLENGE',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Set counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Set $_challengeCurrentSet/${challengeExercise.sets}',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _challengeCurrentSet / (challengeExercise.sets ?? 1),
                    backgroundColor: elevatedColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 4,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Video/GIF area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isLoadingMedia
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.orange),
                          )
                        : _isVideoInitialized && _videoController != null
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 64,
                                      color: Colors.orange.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      challengeExercise.name,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
              ),

              // Exercise info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      challengeExercise.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (challengeExercise.progressionFrom != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Progression from ${challengeExercise.progressionFrom}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade300,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${challengeExercise.reps} reps',
                      style: TextStyle(
                        fontSize: 18,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Completed sets display
              if (_challengeSets.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _challengeSets.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${entry.value.reps} reps',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Too Hard button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showChallengeDifficultyDialog('too_hard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade300,
                          side: BorderSide(color: Colors.red.shade300.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Too Hard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Complete Set button
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _completeChallengeSet(
                          challengeExercise.reps ?? 10,
                          0, // Bodyweight
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to rate challenge difficulty when giving up
  void _showChallengeDifficultyDialog(String difficulty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How was the challenge?'),
        content: const Text(
          'Your feedback helps us suggest better exercises next time.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishChallengeExercise(difficultyFelt: difficulty);
            },
            child: const Text('Submit & Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildStretchScreen(BuildContext context, bool isDark, Color backgroundColor) {
    final currentStretch = _stretchExercises[_currentStretchIndex];
    final stretchProgress = (_currentStretchIndex + 1) / _stretchExercises.length;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return WillPopScope(
      onWillPop: () async {
        _skipAllStretches();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with timer and skip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (skip stretches)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: _skipAllStretches,
                    ),
                    // Workout timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: AppColors.cyan),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_workoutSeconds),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Skip stretches button
                    TextButton(
                      onPressed: _skipAllStretches,
                      child: const Text(
                        'Skip All',
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stretch header - celebratory message
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COOL DOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentStretchIndex + 1} of ${_stretchExercises.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Workout complete banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withOpacity(0.2),
                        AppColors.green.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.cyan,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Great job! Time to stretch and recover.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stretchProgress,
                    backgroundColor: elevatedColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                    minHeight: 6,
                  ),
                ),

                const Spacer(),

                // Current stretch exercise
                Center(
                  child: Column(
                    children: [
                      // Exercise icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentStretch['icon'] as IconData,
                          size: 64,
                          color: AppColors.green,
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 32),

                      // Exercise name
                      Text(
                        currentStretch['name'] as String,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms),

                      const SizedBox(height: 16),

                      // Duration or timer
                      if (_isStretchTimerRunning || _stretchSecondsRemaining > 0)
                        Text(
                          _formatTime(_stretchSecondsRemaining),
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            color: AppColors.green,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 2000.ms, color: AppColors.green.withOpacity(0.3))
                      else
                        Text(
                          '${currentStretch['duration']} sec',
                          style: TextStyle(
                            fontSize: 24,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Upcoming stretch exercises
                if (_currentStretchIndex < _stretchExercises.length - 1) ...[
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _stretchExercises.length - _currentStretchIndex - 1,
                      itemBuilder: (context, index) {
                        final stretch = _stretchExercises[_currentStretchIndex + 1 + index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: elevatedColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                stretch['icon'] as IconData,
                                size: 20,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                stretch['name'] as String,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    // Start/Pause timer button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isStretchTimerRunning) {
                            _stretchTimer?.cancel();
                            setState(() => _isStretchTimerRunning = false);
                          } else if (_stretchSecondsRemaining > 0) {
                            _startStretchTimer();
                          } else {
                            _startStretchTimer();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStretchTimerRunning
                              ? AppColors.green.withOpacity(0.3)
                              : AppColors.green,
                          foregroundColor: _isStretchTimerRunning
                              ? AppColors.green
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _isStretchTimerRunning
                              ? Icons.pause
                              : (_stretchSecondsRemaining > 0 ? Icons.play_arrow : Icons.timer),
                        ),
                        label: Text(
                          _isStretchTimerRunning
                              ? 'Pause'
                              : (_stretchSecondsRemaining > 0 ? 'Resume' : 'Start Timer'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Next/Done button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _currentStretchIndex < _stretchExercises.length - 1
                            ? _skipStretch
                            : _finishStretchesAndComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          _currentStretchIndex < _stretchExercises.length - 1
                              ? Icons.skip_next
                              : Icons.check,
                        ),
                        label: Text(
                          _currentStretchIndex < _stretchExercises.length - 1
                              ? 'Next'
                              : 'Finish',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  /// Toggle weight unit between kg and lbs
  void _toggleUnit() {
    setState(() => _useKg = !_useKg);
    HapticFeedback.selectionClick();

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

  /// Add an additional set to the current exercise
  void _addSetToCurrentExercise() {
    final currentTotal = _totalSetsPerExercise[_viewingExerciseIndex] ?? 3;
    setState(() {
      _totalSetsPerExercise[_viewingExerciseIndex] = currentTotal + 1;
    });
    HapticFeedback.mediumImpact();
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

  void _startRestTimer(int seconds, {RestContext? context}) {
    // Get AI settings for personalized message
    final aiSettings = ref.read(aiSettingsProvider);
    final message = RestMessages.getMessage(
      aiSettings.coachingStyle,
      aiSettings.encouragementLevel,
      context: context,
    );

    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
      _initialRestDuration = seconds;
      _currentRestMessage = message;
    });

    // Voice announcement for rest start
    ref.read(voiceAnnouncementsProvider.notifier).announceRestStartIfEnabled(seconds);

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);

        // Haptic countdown warnings
        if (_restSecondsRemaining == 5) {
          HapticFeedback.lightImpact();
        } else if (_restSecondsRemaining == 3) {
          HapticFeedback.mediumImpact();
          // Voice countdown for last 3 seconds
          ref.read(voiceAnnouncementsProvider.notifier).announceCountdownIfEnabled(3);
          // Play countdown sound
          ref.read(soundPreferencesProvider.notifier).playCountdown(3);
        } else if (_restSecondsRemaining == 2) {
          HapticFeedback.mediumImpact();
          ref.read(voiceAnnouncementsProvider.notifier).announceCountdownIfEnabled(2);
          ref.read(soundPreferencesProvider.notifier).playCountdown(2);
        } else if (_restSecondsRemaining == 1) {
          HapticFeedback.mediumImpact();
          ref.read(voiceAnnouncementsProvider.notifier).announceCountdownIfEnabled(1);
          ref.read(soundPreferencesProvider.notifier).playCountdown(1);
        }

        if (_restSecondsRemaining == 0) _endRest();
      }
    });

    HapticFeedback.mediumImpact();

    // Fetch AI rest time suggestion
    _fetchRestSuggestion();
  }

  void _endRest() {
    _restTimer?.cancel();
    final wasRestingBetweenExercises = _isRestingBetweenExercises;
    setState(() {
      _isResting = false;
      _isRestingBetweenExercises = false;
      _restSecondsRemaining = 0;
    });

    // Voice announcement for rest end
    ref.read(voiceAnnouncementsProvider.notifier).announceRestEndIfEnabled();

    // Play rest timer end sound
    ref.read(soundPreferencesProvider.notifier).playRestTimerEnd();

    // Strong haptic feedback when rest ends
    HapticFeedback.heavyImpact();
    // Additional vibration pattern for better notification
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });

    // If we were resting between exercises, start transition countdown
    if (wasRestingBetweenExercises) {
      _startTransitionCountdown();
    }

    // Clear rest suggestion when rest ends
    setState(() {
      _restSuggestion = null;
      _isLoadingRestSuggestion = false;
    });
  }

  /// Initialize fatigue detection service
  Future<void> _initFatigueService() async {
    // FatigueService uses static methods, no initialization needed
    // We just create a placeholder to indicate fatigue detection is available
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null) {
      _fatigueService = FatigueService();
    }
  }

  /// Fetch AI rest time suggestion when rest starts
  Future<void> _fetchRestSuggestion() async {
    if (_fatigueService == null) return;

    final currentExercise = _exercises[_currentExerciseIndex];
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];
    if (completedSets.isEmpty) return;

    final lastSet = completedSets.last;

    setState(() => _isLoadingRestSuggestion = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        setState(() => _isLoadingRestSuggestion = false);
        return;
      }

      // Determine if exercise is compound (based on muscle group)
      final muscleGroup = (currentExercise.muscleGroup ?? currentExercise.primaryMuscle ?? '').toLowerCase();
      final isCompound = muscleGroup.contains('chest') ||
          muscleGroup.contains('back') ||
          muscleGroup.contains('legs') ||
          muscleGroup.contains('quads') ||
          muscleGroup.contains('hamstrings') ||
          muscleGroup.contains('glutes') ||
          muscleGroup.contains('shoulders');

      final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? 3;
      final setsRemaining = totalSets - completedSets.length;

      final response = await apiClient.post(
        '/api/v1/workouts/rest-suggestion',
        data: {
          'rpe': 7, // Default RPE, will be updated when we add RPE tracking
          'exercise_type': 'strength',
          'exercise_name': currentExercise.name,
          'sets_remaining': setsRemaining > 0 ? setsRemaining : 0,
          'sets_completed': completedSets.length,
          'is_compound': isCompound,
          'muscle_group': currentExercise.muscleGroup ?? currentExercise.primaryMuscle,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _restSuggestion = RestSuggestion.fromJson(response.data);
          _isLoadingRestSuggestion = false;
        });
      } else {
        setState(() => _isLoadingRestSuggestion = false);
      }
    } catch (e) {
      print('❌ [Rest Suggestion] Error: $e');
      setState(() => _isLoadingRestSuggestion = false);
    }
  }

  /// Fetch smart weight suggestion for next set
  Future<void> _fetchSmartWeight() async {
    final currentExercise = _exercises[_currentExerciseIndex];
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];

    setState(() => _isLoadingSmartWeight = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        setState(() => _isLoadingSmartWeight = false);
        return;
      }

      final response = await apiClient.get(
        '/api/v1/workouts/smart-weights/${Uri.encodeComponent(currentExercise.name)}',
        queryParameters: {
          'user_id': userId,
          'set_number': completedSets.length + 1,
          'target_reps': currentExercise.reps ?? 10,
          'goal_type': 'hypertrophy',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final suggestion = SmartWeightSuggestion.fromJson(response.data);
        setState(() {
          _smartWeightSuggestion = suggestion;
          _isLoadingSmartWeight = false;
          // Auto-fill weight if confidence is high
          if (suggestion.confidence > 0.7) {
            _weightController.text = suggestion.suggestedWeight.toStringAsFixed(1);
            _isWeightFromAiSuggestion = true;
          }
        });
      } else {
        setState(() => _isLoadingSmartWeight = false);
      }
    } catch (e) {
      print('❌ [Smart Weight] Error: $e');
      setState(() => _isLoadingSmartWeight = false);
    }
  }

  /// Check for fatigue after set completion
  Future<void> _checkFatigue() async {
    if (_fatigueService == null) return;

    final currentExercise = _exercises[_currentExerciseIndex];
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];
    if (completedSets.length < 2) return; // Need at least 2 sets to detect fatigue

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      // Get the current weight from controller
      final currentWeight = double.tryParse(_weightController.text) ??
          (completedSets.isNotEmpty ? completedSets.last.weight : 0.0);

      // Build sets_data matching backend FatigueCheckRequest schema
      final setsData = completedSets.map((set) => {
        'reps': set.reps,
        'weight': set.weight,
        'rpe': null, // TODO: Get from actual user input when available
        'rir': null, // TODO: Get from actual user input when available
        'is_failure': false,
        'target_reps': set.targetReps > 0 ? set.targetReps : (currentExercise.reps ?? 10),
      }).toList();

      // Determine exercise type
      String exerciseType = 'compound';
      final muscleGroup = currentExercise.muscleGroup?.toLowerCase() ?? '';
      if (muscleGroup.contains('bicep') ||
          muscleGroup.contains('tricep') ||
          muscleGroup.contains('calf') ||
          muscleGroup.contains('forearm')) {
        exerciseType = 'isolation';
      } else if (muscleGroup.contains('bodyweight') ||
                 currentExercise.equipment?.toLowerCase() == 'bodyweight') {
        exerciseType = 'bodyweight';
      }

      final response = await apiClient.post(
        '/api/workouts/fatigue-check',
        data: {
          'sets_data': setsData,
          'current_weight': currentWeight,
          'exercise_type': exerciseType,
          'target_reps': currentExercise.reps ?? 10,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final alertData = FatigueAlertData.fromJson(response.data);
        if (alertData.fatigueDetected) {
          setState(() {
            _showFatigueAlert = true;
            _fatigueAlertData = alertData;
          });
        }
      }
    } catch (e) {
      print('❌ [Fatigue Detection] Error: $e');
    }
  }

  /// Handle accepting the fatigue suggestion (reduce weight)
  void _handleAcceptFatigueSuggestion() {
    HapticFeedback.mediumImpact();
    if (_fatigueAlertData != null) {
      // Apply suggested weight
      _weightController.text = _fatigueAlertData!.suggestedWeight.toStringAsFixed(1);
    }
    setState(() {
      _showFatigueAlert = false;
      _fatigueAlertData = null;
    });
  }

  /// Handle continuing as planned (dismiss fatigue alert)
  void _handleContinueAsPlanned() {
    HapticFeedback.lightImpact();
    setState(() {
      _showFatigueAlert = false;
      _fatigueAlertData = null;
    });
  }

  /// Start transition countdown before moving to next exercise
  void _startTransitionCountdown() {
    // Check if there's actually a next exercise
    if (_currentExerciseIndex >= _exercises.length - 1) {
      // No next exercise, complete workout
      _completeWorkout();
      return;
    }

    final nextExercise = _exercises[_currentExerciseIndex + 1];

    // Pre-fetch image URL for next exercise
    _nextExerciseImageUrl = nextExercise.gifUrl ?? nextExercise.imageS3Path;

    // Voice announcement for next exercise transition
    ref.read(voiceAnnouncementsProvider.notifier).announceNextExerciseIfEnabled(nextExercise.name);

    setState(() {
      _isInTransition = true;
      _transitionSecondsRemaining = _transitionDuration;
    });

    // Initial haptic feedback
    HapticFeedback.mediumImpact();

    _transitionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_transitionSecondsRemaining > 1) {
        setState(() => _transitionSecondsRemaining--);
        // Haptic feedback each second
        if (_transitionSecondsRemaining <= 3) {
          // Stronger feedback in last 3 seconds
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      } else {
        _endTransition();
      }
    });
  }

  /// End transition countdown and move to next exercise
  void _endTransition() {
    _transitionTimer?.cancel();
    setState(() {
      _isInTransition = false;
      _transitionSecondsRemaining = 0;
      _nextExerciseImageUrl = null;
    });
    // Strong haptic when transition ends
    HapticFeedback.heavyImpact();
    _moveToNextExercise();
  }

  /// Skip the transition countdown
  void _skipTransition() {
    HapticFeedback.mediumImpact();
    _endTransition();
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
    // Store the target reps (planned reps from exercise definition)
    final targetReps = exercise.reps ?? 10;
    final completedSetIndex = _completedSets[_currentExerciseIndex]!.length;
    setState(() {
      _completedSets[_currentExerciseIndex]!.add(SetLog(
        reps: reps,
        weight: weight,
        targetReps: targetReps,
      ));
      // Trigger burst animation for this set
      _justCompletedSetIndex = completedSetIndex;

      // Update max weight tracker if this is a new PR during this session
      // This ensures subsequent sets know about the new PR
      if (weight > 0) {
        final currentMax = _exerciseMaxWeights[exercise.name] ?? 0.0;
        if (weight > currentMax) {
          _exerciseMaxWeights[exercise.name] = weight;
          debugPrint('🏆 [PR Updated] ${exercise.name}: new max = $weight kg');
        }
      }
    });

    // Clear burst animation after delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _justCompletedSetIndex = null);
    });

    // Calculate if set was completed too fast BEFORE updating _lastSetCompletedAt
    // This checks time since the PREVIOUS set was completed (i.e., during rest + this set)
    // Only applies if this is NOT the first set
    if (_lastSetCompletedAt != null && _currentSet > 1) {
      final timeSinceLastSet = DateTime.now().difference(_lastSetCompletedAt!);
      // Expected minimum: rest time + time to perform reps (~2 sec per rep)
      // For a set during rest, if they completed in less than the rest time alone, it's too fast
      final restTime = exercise.restSeconds ?? 90;
      final expectedMinDuration = Duration(seconds: restTime + (reps * 2).clamp(10, 30));
      _lastSetWasFast = timeSinceLastSet < expectedMinDuration;
    } else {
      // First set - never consider it "fast"
      _lastSetWasFast = false;
    }

    // Update last set completed time
    _lastSetCompletedAt = DateTime.now();

    // Strong success haptic pattern - celebration triple-tap
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 60), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.lightImpact();
    });

    // Check for fatigue after set completion (runs in background)
    _checkFatigue();

    // Reset AI weight suggestion flag for next set
    _isWeightFromAiSuggestion = false;

    if (_currentSet < totalSets) {
      // Move to next set
      setState(() => _currentSet++);

      // Update controllers with AI target for the new set (if available)
      final nextSetTarget = exercise.getTargetForSet(_currentSet);
      if (nextSetTarget != null) {
        if (nextSetTarget.targetWeightKg != null) {
          _weightController.text = nextSetTarget.targetWeightKg.toString();
        }
        _repsController.text = nextSetTarget.targetReps.toString();
      }

      final restTime = exercise.restSeconds ?? 90;

      // Build context for smart rest messages
      final context = _buildRestContext(
        exercise: exercise,
        weight: weight,
        reps: reps,
        setNumber: _currentSet - 1, // The set we just completed
        totalSets: totalSets,
        isLastSet: _currentSet >= totalSets,
      );

      _startRestTimer(restTime, context: context);
    } else {
      // Exercise complete - start rest before moving to next exercise
      if (_currentExerciseIndex < _exercises.length - 1) {
        // Start rest between exercises (longer rest - 2 minutes by default)
        final restBetweenExercises = 120; // 2 minutes between exercises
        setState(() {
          _isRestingBetweenExercises = true;
        });
        _startRestTimer(restBetweenExercises);
      } else {
        // Last exercise - complete workout
        _completeWorkout();
      }
    }
  }

  /// Build context for context-aware rest messages
  RestContext _buildRestContext({
    required WorkoutExercise exercise,
    required double weight,
    required int reps,
    required int setNumber,
    required int totalSets,
    required bool isLastSet,
  }) {
    // Get previous weight from actual historical data (fetched from API)
    final previousSetsData = _previousSets[_currentExerciseIndex] ?? [];
    double? previousWeight;
    if (previousSetsData.isNotEmpty && setNumber <= previousSetsData.length) {
      final prevSet = previousSetsData[setNumber - 1];
      previousWeight = (prevSet['weight'] as num?)?.toDouble();
    }

    // Detect PR using all-time max weight from strength records
    // This is more accurate than just comparing to last session
    bool isPR = false;
    if (weight > 0) {
      final allTimeMax = _exerciseMaxWeights[exercise.name] ?? 0.0;
      if (allTimeMax > 0) {
        // It's a PR if current weight exceeds all-time max
        isPR = weight > allTimeMax;
        debugPrint('🏆 [PR Check] ${exercise.name}: current=$weight kg, all-time max=$allTimeMax kg, isPR=$isPR');
      } else if (previousSetsData.isNotEmpty) {
        // Fallback: compare to last session if no PR records exist
        final maxPreviousWeight = previousSetsData
            .map((s) => (s['weight'] as num?)?.toDouble() ?? 0.0)
            .fold(0.0, (a, b) => a > b ? a : b);
        isPR = weight > maxPreviousWeight;
        debugPrint('🏆 [PR Check] ${exercise.name}: current=$weight kg, last session max=$maxPreviousWeight kg, isPR=$isPR (no all-time data)');
      }
    }

    // Detect if set was completed too fast
    // Note: wasFast is now calculated BEFORE updating _lastSetCompletedAt in _completeSet
    // The value is passed in via the _lastSetWasFast field
    final bool wasFast = _lastSetWasFast;

    // Normalize muscle group
    String? muscleGroup = exercise.primaryMuscle?.toLowerCase() ??
        exercise.muscleGroup?.toLowerCase();
    // Map to standard groups
    if (muscleGroup != null) {
      if (muscleGroup.contains('chest') || muscleGroup.contains('pec')) {
        muscleGroup = 'chest';
      } else if (muscleGroup.contains('back') || muscleGroup.contains('lat')) {
        muscleGroup = 'back';
      } else if (muscleGroup.contains('leg') ||
          muscleGroup.contains('quad') ||
          muscleGroup.contains('hamstring') ||
          muscleGroup.contains('glute')) {
        muscleGroup = 'legs';
      } else if (muscleGroup.contains('bicep') ||
          muscleGroup.contains('tricep') ||
          muscleGroup.contains('arm')) {
        muscleGroup = 'arms';
      } else if (muscleGroup.contains('shoulder') || muscleGroup.contains('delt')) {
        muscleGroup = 'shoulders';
      } else if (muscleGroup.contains('core') ||
          muscleGroup.contains('ab') ||
          muscleGroup.contains('oblique')) {
        muscleGroup = 'core';
      }
    }

    return RestContext(
      exerciseName: exercise.name,
      muscleGroup: muscleGroup,
      isPR: isPR,
      isLastSet: isLastSet,
      isLastExercise: _currentExerciseIndex >= _exercises.length - 1,
      weightLifted: weight > 0 ? weight : null,
      previousWeight: previousWeight,
      reps: reps,
      wasFast: wasFast,
    );
  }

  /// Edit a completed set (from swipe action)
  void _editCompletedSet(int exerciseIndex, int setIndex) {
    final sets = _completedSets[exerciseIndex];
    if (sets == null || setIndex >= sets.length) return;

    final setData = sets[setIndex];
    final weightController = TextEditingController(
      text: _useKg
          ? setData.weight.toStringAsFixed(1)
          : (setData.weight * 2.20462).toStringAsFixed(1),
    );
    final repsController = TextEditingController(text: setData.reps.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Set ${setIndex + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _useKg ? 'Weight (kg)' : 'Weight (lbs)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.pureBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cyan),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cyan, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reps',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.pureBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.purple),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.purple, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  var newWeight = double.tryParse(weightController.text) ?? setData.weight;
                  final newReps = int.tryParse(repsController.text) ?? setData.reps;

                  // Convert lbs to kg if needed
                  if (!_useKg) {
                    newWeight = newWeight * 0.453592;
                  }

                  setState(() {
                    sets[setIndex] = SetLog(
                      reps: newReps,
                      weight: newWeight,
                      completedAt: setData.completedAt,
                      targetReps: setData.targetReps, // Preserve original target
                    );
                    // Mark this set as edited for visual feedback
                    _editedSets[exerciseIndex]?.add(setIndex);
                  });
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  debugPrint('✅ [Workout] Edited set ${setIndex + 1} for exercise $exerciseIndex: $newWeight kg x $newReps');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _moveToNextExercise() {
    // Play exercise completion sound when finishing all sets of an exercise
    ref.read(soundPreferencesProvider.notifier).playExerciseCompletion();

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
      // Prefer AI-generated setTargets data for first set
      final firstSetTarget = nextExercise.getTargetForSet(1);
      _repsController.text = (firstSetTarget?.targetReps ?? nextExercise.reps ?? 10).toString();
      _weightController.text = (firstSetTarget?.targetWeightKg ?? nextExercise.weight ?? 0).toString();
      _fetchMediaForExercise(nextExercise);

      // Fetch smart weight suggestion for new exercise
      _fetchSmartWeight();

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
    // Prefer AI-generated setTargets data for the current set
    final setTarget = exercise.getTargetForSet(_currentSet);
    _repsController.text = (setTarget?.targetReps ?? exercise.reps ?? 10).toString();
    _weightController.text = (setTarget?.targetWeightKg ?? exercise.weight ?? 0).toString();

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
            ExerciseOptionTile(
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

            // Replace with similar (uses AI-powered swap sheet)
            ExerciseOptionTile(
              icon: Icons.swap_horiz,
              title: 'Replace Exercise',
              subtitle: 'AI-powered alternatives',
              color: AppColors.purple,
              onTap: () async {
                Navigator.pop(context); // Close this sheet
                await _showReplaceExerciseDialog(ctx, index);
              },
            ),

            const SizedBox(height: 12),

            // Skip this exercise
            ExerciseOptionTile(
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

            const SizedBox(height: 12),

            // Superset options
            if (exercise.isInSuperset) ...[
              // Remove from superset
              ExerciseOptionTile(
                icon: Icons.link_off,
                title: 'Remove from Superset',
                subtitle: 'Break the superset pair',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(ctx);
                  await _removeFromSuperset(index);
                },
              ),
            ] else ...[
              // Create superset with next exercise
              if (index < _exercises.length - 1 && !_exercises[index + 1].isInSuperset)
                ExerciseOptionTile(
                  icon: Icons.link,
                  title: 'Pair with Next Exercise',
                  subtitle: 'Create superset with ${_exercises[index + 1].name}',
                  color: AppColors.purple,
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(ctx);
                    await _createSupersetPair(index, index + 1);
                  },
                ),
              const SizedBox(height: 12),
              // Create superset (choose exercise)
              ExerciseOptionTile(
                icon: Icons.add_link,
                title: 'Create Superset',
                subtitle: 'Choose exercise to pair with',
                color: AppColors.purple,
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(ctx);
                  await _showSupersetCreationSheet(index);
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Create a superset pair between two exercises
  Future<void> _createSupersetPair(int index1, int index2) async {
    if (_workout?.id == null) return;

    try {
      final repo = ref.read(supersetRepositoryProvider);
      await repo.createSupersetPair(_workout!.id!, index1, index2);

      // Refresh workout data
      await _refreshWorkoutFromServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Superset created: ${_exercises[index1].name} + ${_exercises[index2].name}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating superset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create superset: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Remove exercise from its superset
  Future<void> _removeFromSuperset(int index) async {
    if (_workout?.id == null) return;

    final exercise = _exercises[index];
    if (!exercise.isInSuperset || exercise.supersetGroup == null) return;

    try {
      final repo = ref.read(supersetRepositoryProvider);
      await repo.removeSupersetPair(_workout!.id!, exercise.supersetGroup!);

      // Refresh workout data
      await _refreshWorkoutFromServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Superset removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error removing superset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove superset: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show the superset creation sheet
  Future<void> _showSupersetCreationSheet(int preselectedIndex) async {
    final result = await showSupersetPairSheet(
      context,
      ref,
      workoutExercises: _exercises,
      preselectedExercise: _exercises[preselectedIndex],
    );

    if (result != null && mounted) {
      // Find the indices of the selected exercises
      final index1 = _exercises.indexWhere((e) => e.name == result.exercise1.name);
      final index2 = _exercises.indexWhere((e) => e.name == result.exercise2.name);

      if (index1 != -1 && index2 != -1) {
        await _createSupersetPair(index1, index2);
      }
    }
  }

  /// Refresh workout data from server after superset changes
  Future<void> _refreshWorkoutFromServer() async {
    if (_workout?.id == null) return;

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await workoutRepo.getWorkout(_workout!.id!);

      if (updatedWorkout != null && mounted) {
        setState(() {
          _workout = updatedWorkout;
          _exercises = updatedWorkout.exercises.toList() ?? [];
        });
      }
    } catch (e) {
      debugPrint('❌ Error refreshing workout: $e');
    }
  }

  /// Show exercise swap sheet with AI suggestions
  Future<void> _showReplaceExerciseDialog(BuildContext ctx, int index) async {
    final exercise = _exercises[index];

    // Close the exercise options sheet first
    Navigator.pop(ctx);

    // Show the proper exercise swap sheet with AI suggestions
    final updatedWorkout = await showExerciseSwapSheet(
      context,
      ref,
      workoutId: widget.workout.id!,
      exercise: exercise,
    );

    if (updatedWorkout != null && mounted) {
      // Find the new exercise that replaced the old one
      final updatedExercises = updatedWorkout.exercises ?? [];

      setState(() {
        // Update the exercises list with new data
        for (int i = 0; i < updatedExercises.length && i < _exercises.length; i++) {
          _exercises[i] = updatedExercises[i];
        }

        // Reset completed sets for the swapped exercise
        _completedSets[index] = [];
      });

      // If this was the current exercise, reload media
      if (index == _currentExerciseIndex) {
        _fetchMediaForExercise(_exercises[index]);
      }

      HapticFeedback.mediumImpact();

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exercise replaced with ${_exercises[index].name}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Start the stretch phase after workout exercises are complete
  void _startStretchPhase() {
    setState(() {
      _isInStretchPhase = true;
      _currentStretchIndex = 0;
    });
    HapticFeedback.heavyImpact();
    // Auto-start stretch timer after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isInStretchPhase) {
        _startStretchTimer();
      }
    });
  }

  void _startStretchTimer() {
    final duration = _stretchExercises[_currentStretchIndex]['duration'] as int;
    setState(() {
      _stretchSecondsRemaining = duration;
      _isStretchTimerRunning = true;
    });

    _stretchTimer?.cancel();
    _stretchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stretchSecondsRemaining > 0) {
        setState(() {
          _stretchSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() => _isStretchTimerRunning = false);
        // Auto-advance to next stretch after a brief pause
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isInStretchPhase) {
            _nextStretchExercise();
          }
        });
      }
    });
  }

  void _nextStretchExercise() {
    if (_currentStretchIndex < _stretchExercises.length - 1) {
      setState(() => _currentStretchIndex++);
      // Auto-start timer for next stretch
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isInStretchPhase) {
          _startStretchTimer();
        }
      });
      HapticFeedback.mediumImpact();
    } else {
      // All stretches done - now complete the workout
      _finishStretchesAndComplete();
    }
  }

  void _skipStretch() {
    _stretchTimer?.cancel();
    setState(() {
      _isStretchTimerRunning = false;
      _stretchSecondsRemaining = 0;
    });
    _nextStretchExercise();
  }

  void _skipAllStretches() {
    _stretchTimer?.cancel();
    setState(() {
      _isStretchTimerRunning = false;
      _stretchSecondsRemaining = 0;
      _isInStretchPhase = false;
    });
    _finishStretchesAndComplete();
  }

  void _finishStretchesAndComplete() {
    // Set _isComplete FIRST to show loading screen, then clear stretch phase
    setState(() {
      _isComplete = true;
      _isInStretchPhase = false;
    });
    _finalizeWorkoutCompletion();
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

    // Check if workout has a challenge exercise to offer
    final challengeExercise = widget.workout.challengeExercise;
    if (challengeExercise != null && !_challengeAccepted && !_challengeCompleted) {
      // Show challenge offer before stretches
      _showChallengeOffer(challengeExercise);
    } else {
      // Start stretch phase instead of immediately completing
      _startStretchPhase();
    }
  }

  /// Show a dialog offering the challenge exercise
  void _showChallengeOffer(WorkoutExercise challengeExercise) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ready for a Challenge?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great workout! Want to try an advanced exercise?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challengeExercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (challengeExercise.progressionFrom != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Progression from ${challengeExercise.progressionFrom}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        Text(
                          '${challengeExercise.sets} sets × ${challengeExercise.reps} reps',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is optional - skip if you\'re tired!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _challengeCompleted = true);
              _startStretchPhase();
            },
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startChallengePhase(challengeExercise);
            },
            icon: const Icon(Icons.local_fire_department, size: 18),
            label: const Text('Let\'s Go!'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Start the challenge exercise phase
  void _startChallengePhase(WorkoutExercise challengeExercise) {
    setState(() {
      _isInChallengePhase = true;
      _challengeAccepted = true;
      _challengeCurrentSet = 1;
      _challengeSets.clear();
    });
    HapticFeedback.heavyImpact();

    // Load video for challenge exercise
    _loadChallengeExerciseMedia(challengeExercise);
  }

  /// Load media for challenge exercise
  Future<void> _loadChallengeExerciseMedia(WorkoutExercise exercise) async {
    setState(() => _isLoadingMedia = true);

    final videoUrl = exercise.gifUrl ?? exercise.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      try {
        _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        await _videoController!.play();
        setState(() {
          _isVideoInitialized = true;
          _isVideoPlaying = true;
          _videoUrl = videoUrl;
          _isLoadingMedia = false;
        });
      } catch (e) {
        debugPrint('⚠️ Failed to load challenge exercise video: $e');
        setState(() {
          _isVideoInitialized = false;
          _isLoadingMedia = false;
        });
      }
    } else {
      setState(() => _isLoadingMedia = false);
    }
  }

  /// Complete a set in the challenge exercise
  void _completeChallengeSet(int reps, double weight) {
    final challengeExercise = widget.workout.challengeExercise;
    if (challengeExercise == null) return;

    setState(() {
      _challengeSets.add(SetLog(
        reps: reps,
        weight: weight,
        targetReps: challengeExercise.reps ?? 10,
      ));
    });

    HapticFeedback.mediumImpact();

    if (_challengeCurrentSet < (challengeExercise.sets ?? 1)) {
      // More sets to go
      setState(() => _challengeCurrentSet++);
    } else {
      // Challenge complete!
      _finishChallengeExercise(difficultyFelt: 'just_right');
    }
  }

  /// Finish challenge exercise and submit feedback
  Future<void> _finishChallengeExercise({required String difficultyFelt}) async {
    final challengeExercise = widget.workout.challengeExercise;
    if (challengeExercise == null) return;

    setState(() {
      _isInChallengePhase = false;
      _challengeCompleted = true;
    });

    // Submit challenge feedback to backend
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.dio.post(
          '${ApiConstants.baseUrl}/api/v1/feedback/challenge-exercise',
          data: {
            'user_id': userId,
            'exercise_name': challengeExercise.name,
            'difficulty_felt': difficultyFelt,
            'completed': _challengeSets.isNotEmpty,
            'workout_id': widget.workout.id,
            'performance_data': {
              'sets_completed': _challengeSets.length,
              'total_reps': _challengeSets.fold<int>(0, (sum, s) => sum + s.reps),
              'avg_weight': _challengeSets.isEmpty
                  ? 0
                  : _challengeSets.fold<double>(0, (sum, s) => sum + s.weight) /
                      _challengeSets.length,
            },
          },
        );
        debugPrint('✅ Challenge exercise feedback submitted');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to submit challenge feedback: $e');
    }

    // Now start stretch phase
    _startStretchPhase();
  }

  /// Skip challenge exercise without attempting
  void _skipChallengeExercise() {
    _finishChallengeExercise(difficultyFelt: 'too_hard');
  }

  Future<void> _finalizeWorkoutCompletion() async {
    setState(() => _isComplete = true);

    // Voice announcement for workout completion
    ref.read(voiceAnnouncementsProvider.notifier).announceWorkoutCompleteIfEnabled();

    // Variables to pass to workout complete screen for AI Coach feedback
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

        // 4b. Log user-created supersets (for analytics)
        await workoutRepo.logUserSupersets(
          workoutId: widget.workout.id!,
          userId: userId,
          exercises: _exercises,
        );

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

        // 6. Mark workout as complete in workouts table and get PRs
        final completionResponse = await workoutRepo.completeWorkout(widget.workout.id!);
        debugPrint('✅ Workout marked as complete');

        // Store PRs from the response
        if (completionResponse != null && completionResponse.hasPRs) {
          personalRecords = completionResponse.personalRecords;
          debugPrint('🏆 Got ${personalRecords.length} PRs from completion API');
        }

        // Store performance comparison from the response
        if (completionResponse != null && completionResponse.performanceComparison != null) {
          performanceComparison = completionResponse.performanceComparison;
          debugPrint('📊 Got performance comparison: ${performanceComparison!.improvedCount} improved, ${performanceComparison.declinedCount} declined');
        }

        // 7. Build exercises performance data for social post
        final exercisesPerformanceForSocial = <Map<String, dynamic>>[];
        for (int i = 0; i < _exercises.length; i++) {
          final exercise = _exercises[i];
          final sets = _completedSets[i] ?? [];
          if (sets.isNotEmpty) {
            final avgWeight = sets.fold<double>(0, (sum, s) => sum + s.weight) / sets.length;
            final totalExReps = sets.fold<int>(0, (sum, s) => sum + s.reps);
            exercisesPerformanceForSocial.add({
              'name': exercise.name,
              'sets': sets.length,
              'reps': (totalExReps / sets.length).round(), // avg reps per set
              'weight_kg': avgWeight,
            });
          }
        }

        // 8. Auto-post to social feed (if enabled in privacy settings)
        try {
          final socialService = ref.read(socialServiceProvider);
          await socialService.autoPostWorkoutCompletion(
            userId: userId,
            workoutLogId: workoutLogId ?? '',
            workoutName: widget.workout.name ?? 'Workout',
            durationMinutes: (_workoutSeconds / 60).round(),
            exercisesCount: exercisesWithSets,
            totalVolume: totalVolumeKg,
            exercisesPerformance: exercisesPerformanceForSocial,
          );
          debugPrint('🎉 [Social] Workout auto-posted to feed with ${exercisesPerformanceForSocial.length} exercises');
        } catch (e) {
          debugPrint('⚠️ [Social] Failed to auto-post workout: $e');
          // Non-critical - don't block workout completion
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to complete workout: $e');
    }

    // Build exercises performance data for AI Coach feedback
    // Includes per-exercise timing and set details for context-aware feedback
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
          'time_seconds': _exerciseTimeSeconds[i] ?? 0, // Per-exercise timing
          'set_details': sets.map((s) => {
            'reps': s.reps,
            'weight_kg': s.weight,
          }).toList(), // Individual set data
        });
      }
    }

    // Build planned exercises list for skip detection
    final plannedExercises = widget.workout.exercises.map((e) => {
      'name': e.name,
      'target_sets': e.sets ?? 3,
      'target_reps': e.reps ?? 10,
      'target_weight_kg': e.weight ?? 0.0,
    }).toList();

    debugPrint('📊 [Complete] Exercises completed: ${exercisesPerformance.length}/${widget.workout.exercises.length}');
    debugPrint('📊 [Complete] Per-exercise timing available for ${_exerciseTimeSeconds.length} exercises');

    if (mounted) {
      // Calculate final calories burned (6 kcal/min as baseline, adjusted for intensity)
      // For strength training: ~6 kcal/min for moderate intensity
      final finalCaloriesBurned = (_workoutSeconds / 60 * 6).round();

      // Get heart rate data from watch (accumulated during workout)
      final hrStats = ref.read(workoutHeartRateHistoryProvider.notifier).getStats();
      final heartRateReadings = hrStats?.samples.map((r) => HeartRateReadingData.fromReading(r)).toList();

      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _workoutSeconds,
        'calories': finalCaloriesBurned,
        'drinkIntakeMl': _totalDrinkIntakeMl,
        'restIntervals': _restIntervals.length,
        // AI Coach feedback data
        'workoutLogId': workoutLogId,
        'exercisesPerformance': exercisesPerformance,
        'plannedExercises': plannedExercises, // NEW: For skip detection
        'exerciseTimeSeconds': Map.from(_exerciseTimeSeconds), // NEW: Per-exercise timing map
        'totalRestSeconds': totalRestSeconds,
        'avgRestSeconds': avgRestSeconds,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
        // Challenge data (if this workout was from a challenge)
        'challengeId': widget.challengeId,
        'challengeData': widget.challengeData,
        // PRs detected from workout completion
        'personalRecords': personalRecords,
        // Performance comparison (improvements/setbacks vs previous sessions)
        'performanceComparison': performanceComparison,
        // Heart rate data from watch (if available)
        'heartRateReadings': heartRateReadings,
        'avgHeartRate': hrStats?.avg,
        'maxHeartRate': hrStats?.max,
        'minHeartRate': hrStats?.min,
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
          setType: sets[j].setType,
        );
      }
    }

    debugPrint('✅ Logged ${_completedSets.values.fold<int>(0, (sum, list) => sum + list.length)} sets to backend');
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      // Sync video playing state with pause state
      _isVideoPlaying = !_isPaused;
    });
    // Also pause/play the video
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_isPaused) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _showQuitDialog() async {
    // If this is a challenge workout, show the Challenge Quit Dialog with psychological pressure!
    if (widget.challengeId != null && widget.challengeData != null) {
      _showChallengeQuitDialog();
      return;
    }

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

    final result = await showQuitWorkoutDialog(
      context: context,
      progressPercent: progressPercent,
      totalCompletedSets: totalCompletedSets,
      exercisesWithCompletedSets: exercisesWithCompletedSets,
    );

    if (result != null) {
      await _logWorkoutExitAndQuit(
        result.reason,
        result.notes,
        exercisesWithCompletedSets,
        totalCompletedSets,
        progressPercent.toDouble(),
      );
    }
  }

  /// Show Challenge Quit Dialog with psychological pressure!
  void _showChallengeQuitDialog() {
    final challengerName = widget.challengeData!['challenger_name'] ?? 'Someone';
    final workoutName = widget.workout.name ?? 'Workout';

    // Calculate partial stats
    int totalSets = 0;
    double totalVolume = 0;
    for (final sets in _completedSets.values) {
      for (final setLog in sets) {
        totalSets++;
        totalVolume += setLog.reps * setLog.weight;
      }
    }

    final partialStats = totalSets > 0 ? {
      'exercises_completed': _completedSets.values.where((s) => s.isNotEmpty).length,
      'sets_completed': totalSets,
      'total_volume': totalVolume,
      'duration_minutes': (_workoutSeconds / 60).round(),
    } : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChallengeQuitDialog(
        challengerName: challengerName,
        workoutName: workoutName,
        onContinue: () {
          // User chose to continue - do nothing, dialog closes
          debugPrint('💪 User decided to continue challenge!');
        },
        onConfirmQuit: (quitReason) async {
          debugPrint('🐔 User quit challenge: $quitReason');

          try {
            // Call abandon challenge API
            final challengesService = ChallengesService(ref.read(apiClientProvider));
            final apiClient = ref.read(apiClientProvider);
            final userId = await apiClient.getUserId();

            if (userId != null) {
              await challengesService.abandonChallenge(
                userId: userId,
                challengeId: widget.challengeId!,
                quitReason: quitReason,
                partialStats: partialStats,
              );

              debugPrint('✅ Challenge abandoned successfully');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challenge abandoned: $quitReason'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Error abandoning challenge: $e');
          }

          // Navigate back/quit workout
          if (mounted) {
            Navigator.pop(context); // Close workout screen
          }
        },
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

  void _logDrinkIntake(int amountMl) {
    debugPrint('💧 _logDrinkIntake called with $amountMl ml');
    debugPrint('💧 Before: _totalDrinkIntakeMl = $_totalDrinkIntakeMl');

    setState(() {
      _totalDrinkIntakeMl += amountMl;
    });

    debugPrint('💧 After: _totalDrinkIntakeMl = $_totalDrinkIntakeMl');
    HapticFeedback.mediumImpact();

    // Show brief confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('+${amountMl}ml logged (Total: ${(_totalDrinkIntakeMl / 1000).toStringAsFixed(2)}L)'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
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

                      // Check if this is a superset pair
                      final isFirstInSuperset = exercise.isSupersetFirst;
                      final isSecondInSuperset = exercise.isSupersetSecond;
                      final showSupersetConnector = isFirstInSuperset &&
                          index + 1 < _exercises.length &&
                          _exercises[index + 1].supersetGroup == exercise.supersetGroup;

                      return Container(
                        key: ValueKey('exercise_$index'),
                        margin: EdgeInsets.only(bottom: showSupersetConnector ? 0 : 12),
                        child: Column(
                          children: [
                            // Superset header for first exercise in pair
                            if (isFirstInSuperset)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link, size: 12, color: AppColors.purple),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SUPERSET ${exercise.supersetGroup}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.purple,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Material(
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
                                        : exercise.isInSuperset
                                            ? AppColors.purple.withOpacity(0.05)
                                            : AppColors.elevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.cyan.withOpacity(0.5)
                                          : exercise.isInSuperset
                                              ? AppColors.purple.withOpacity(0.3)
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
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                exercise.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Superset badge
                                            if (exercise.isInSuperset) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.purple.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.link, size: 10, color: AppColors.purple),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'SS${exercise.supersetGroup}',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.purple,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            // Drop set badge
                                            if (exercise.hasDropSets) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.trending_down, size: 10, color: AppColors.orange),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'DROP',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$totalSets sets × ${exercise.reps ?? 10} reps${exercise.hasDropSets ? ' + ${exercise.dropSetCount} drops' : ''}',
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
                        // Superset connector line between paired exercises
                        if (showSupersetConnector)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const SizedBox(width: 48),
                                Container(
                                  width: 2,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No rest',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.purple.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
    // Clear heart rate history on first build (start of new workout)
    if (!_heartRateHistoryCleared) {
      _heartRateHistoryCleared = true;
      ref.read(workoutHeartRateHistoryProvider.notifier).clear();
    }

    // Initialize weight unit from user preference on first build
    if (!_unitInitialized) {
      _unitInitialized = true;
      _useKg = ref.read(useKgProvider);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Show loading screen while completing workout (prevents flash back to exercise screen)
    if (_isComplete) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.cyan),
              const SizedBox(height: 24),
              Text(
                'Saving workout...',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show warmup screen if in warmup phase
    if (_isInWarmupPhase) {
      return _buildWarmupScreen(context, isDark, backgroundColor);
    }

    // Show stretch screen if in stretch phase (after workout, before completion)
    if (_isInStretchPhase) {
      return _buildStretchScreen(context, isDark, backgroundColor);
    }

    // Show challenge exercise screen if in challenge phase
    if (_isInChallengePhase && widget.workout.challengeExercise != null) {
      return _buildChallengeExerciseScreen(context, isDark, backgroundColor);
    }

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
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Full-screen video/GIF background
            if (_isVideoInitialized && _videoController != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else if (_imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.pureBlack),
                ),
              )
            else
              // Fallback: Dark gradient background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0A0A),
                        AppColors.pureBlack,
                        AppColors.pureBlack,
                        Color(0xFF0A0A0A),
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

            // Semi-transparent overlay (adjustable opacity based on card visibility)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: Colors.black.withOpacity(_showSetOverlay ? 0.6 : 0.3),
                ),
              ),
            ),

            // Subtle pattern overlay for depth
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [
                        AppColors.glowCyan.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
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

            // Rest timer overlay - using RestTimerOverlay widget with AI suggestions
            if (_isResting)
              Positioned.fill(
                child: RestTimerOverlay(
                  restSecondsRemaining: _restSecondsRemaining,
                  initialRestDuration: _initialRestDuration,
                  restMessage: _currentRestMessage,
                  currentExercise: _exercises[_currentExerciseIndex],
                  completedSetsCount: _completedSets[_currentExerciseIndex]?.length ?? 0,
                  totalSets: _totalSetsPerExercise[_currentExerciseIndex] ?? 3,
                  nextExercise: _currentExerciseIndex < _exercises.length - 1
                      ? _exercises[_currentExerciseIndex + 1]
                      : null,
                  isRestBetweenExercises: _isRestingBetweenExercises,
                  onSkipRest: _endRest,
                  onLog1RM: () async {
                    final exercise = _exercises[_currentExerciseIndex];
                    final result = await showLog1RMSheet(
                      context,
                      ref,
                      exerciseName: exercise.name,
                      exerciseId: exercise.exerciseId ?? exercise.libraryId ?? exercise.name.toLowerCase().replaceAll(' ', '_'),
                    );
                    if (result != null && mounted) {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('1RM logged: ${(result['estimated_1rm'] as num?)?.toStringAsFixed(1) ?? 'N/A'} kg'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  restSuggestion: _restSuggestion,
                  isLoadingRestSuggestion: _isLoadingRestSuggestion,
                  onAcceptRestSuggestion: (seconds) {
                    setState(() {
                      _restSecondsRemaining = seconds;
                      _initialRestDuration = seconds;
                    });
                  },
                  onDismissRestSuggestion: () {
                    setState(() => _restSuggestion = null);
                  },
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

            // Fatigue Alert Modal
            if (_showFatigueAlert && _fatigueAlertData != null)
              Positioned.fill(
                child: FatigueAlertModal(
                  alertData: _fatigueAlertData!,
                  currentWeight: double.tryParse(_weightController.text) ?? 0,
                  exerciseName: _exercises[_currentExerciseIndex].name,
                  onAcceptSuggestion: _handleAcceptFatigueSuggestion,
                  onContinueAsPlanned: _handleContinueAsPlanned,
                  onStopExercise: _skipExercise,
                ),
              ),

            // Transition countdown overlay (between exercises)
            if (_isInTransition && _currentExerciseIndex < _exercises.length - 1)
              Positioned.fill(
                child: _buildTransitionOverlay(),
              ),

            // Set tracking section with FuturisticSetCard
            if (_showSetOverlay && !_isResting && !_isInTransition)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 150, // Below top overlay
                child: SetTrackingSection(
                  exercise: _exercises[_viewingExerciseIndex],
                  exerciseIndex: _viewingExerciseIndex,
                  totalExercises: _exercises.length,
                  currentSetNumber: _currentSet,
                  totalSets: _totalSetsPerExercise[_viewingExerciseIndex] ?? 3,
                  completedSets: (_completedSets[_viewingExerciseIndex] ?? [])
                      .map((s) => CompletedSetData(
                            reps: s.reps,
                            weight: s.weight,
                            targetReps: s.targetReps,
                            isEdited: _editedSets[_viewingExerciseIndex]?.contains(
                                    (_completedSets[_viewingExerciseIndex] ?? []).indexOf(s)) ??
                                false,
                            setType: s.setType,
                          ))
                      .toList(),
                  previousSets: _previousSets[_viewingExerciseIndex] ?? [],
                  currentWeight: double.tryParse(_weightController.text) ?? 0,
                  currentReps: int.tryParse(_repsController.text) ?? 10,
                  weightStep: 2.5,
                  useKg: _useKg,
                  setType: 'working',
                  smartWeightSuggestion: _smartWeightSuggestion,
                  isWeightFromAiSuggestion: _isWeightFromAiSuggestion,
                  isCurrentExercise: _viewingExerciseIndex == _currentExerciseIndex,
                  isExpanded: _isActiveRowExpanded,
                  justCompletedSetIndex: _justCompletedSetIndex,
                  onWeightChanged: (value) {
                    setState(() {
                      _weightController.text = value.toStringAsFixed(1);
                      _isWeightFromAiSuggestion = false;
                    });
                  },
                  onRepsChanged: (value) {
                    setState(() => _repsController.text = value.toString());
                  },
                  onCompleteSet: _completeSet,
                  onSkipExercise: _skipExercise,
                  onSetTypeChanged: (type) {
                    // Handle set type change if needed
                    HapticFeedback.lightImpact();
                  },
                  onToggleExpand: () {
                    setState(() => _isActiveRowExpanded = !_isActiveRowExpanded);
                    HapticFeedback.mediumImpact();
                  },
                  onPreviousExercise: _viewingExerciseIndex > 0
                      ? () => setState(() => _viewingExerciseIndex--)
                      : null,
                  onNextExercise: _viewingExerciseIndex < _exercises.length - 1
                      ? () => setState(() => _viewingExerciseIndex++)
                      : null,
                  onEditSet: (index) {
                    // Open edit sheet for completed set
                    _editCompletedSet(_viewingExerciseIndex, index);
                  },
                  onAddSet: _addSetToCurrentExercise,
                  onUnitToggle: _toggleUnit,
                  nextExercise: _viewingExerciseIndex < _exercises.length - 1
                      ? _exercises[_viewingExerciseIndex + 1]
                      : null,
                ),
              ),

            // "Tap to log set" indicator when card is hidden
            if (!_showSetOverlay && !_isResting && !_isInTransition)
              Positioned(
                top: MediaQuery.of(context).padding.top + 180,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _showSetOverlay = true);
                    HapticFeedback.lightImpact();
                  },
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.elevated.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.cyan),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to log set',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Tap outside to minimize set card
            if (_showSetOverlay && !_isResting && !_isInTransition)
              Positioned(
                top: MediaQuery.of(context).padding.top + 140,
                left: 0,
                right: 0,
                height: 30,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _showSetOverlay = false);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

            // Bottom section: next exercise + collapsible instructions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSection(currentExercise, nextExercise),
            ),

            // Video is now full-screen background - PiP removed
            // Music mini player - Coming Soon (requires audio_service integration)
          ],
        ),
      ),
    );
  }

  /// Show full-screen video modal
  void _showFullScreenVideo() {
    if (!_isVideoInitialized && _imageUrl == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullScreenVideoModal(
        videoController: _videoController,
        isVideoInitialized: _isVideoInitialized,
        isVideoPlaying: _isVideoPlaying,
        imageUrl: _imageUrl,
        onTogglePlay: () {
          _toggleVideoPlayPause();
          // Rebuild the modal to reflect the change
          Navigator.pop(context);
          _showFullScreenVideo();
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTopOverlay(WorkoutExercise exercise, double progress) {
    // Responsive adjustments for split screen / narrow windows
    final isCompact = isInSplitScreen || isNarrowLayout;
    final horizontalPadding = isCompact ? 8.0 : 12.0;
    final verticalPadding = isCompact ? 6.0 : 10.0;
    final buttonSize = isCompact ? 28.0 : 36.0;
    final titleFontSize = isCompact ? 14.0 : 16.0;
    final spacing = isCompact ? 4.0 : 8.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, 8),
      child: Column(
        children: [
          // Challenge banner (if this is a challenge workout) - hide in very compact mode
          if (widget.challengeId != null && widget.challengeData != null && !isNarrowLayout) ...[
            _buildChallengeBanner(),
            SizedBox(height: spacing),
          ],

          // Top row: Minimize, title, pause - more compact
          Row(
            children: [
              _GlassButton(
                icon: Icons.keyboard_arrow_down,
                onTap: () {
                  // Minimize workout - go back but keep timer running
                  Navigator.of(context).pop();
                },
                size: isCompact ? 28.0 : 32.0,
                isSubdued: true,
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unilateral indicator (like Gravl - "each side")
                        if (exercise.isUnilateral == true)
                          Text(
                            ' (each side)',
                            style: TextStyle(
                              fontSize: isCompact ? 10.0 : 12.0,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.7),
                              shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${_currentExerciseIndex + 1}/${_exercises.length}',
                      style: TextStyle(
                        fontSize: isCompact ? 10.0 : 11.0,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Hide list button in very narrow mode
              if (!isNarrowLayout) ...[
                _GlassButton(
                  icon: Icons.list_alt,
                  onTap: _showExerciseListDrawer,
                  size: buttonSize,
                ),
                SizedBox(width: spacing * 0.75),
              ],
              _GlassButton(
                icon: _showSetOverlay ? Icons.table_chart : Icons.table_chart_outlined,
                onTap: () => setState(() => _showSetOverlay = !_showSetOverlay),
                isHighlighted: _showSetOverlay,
                size: buttonSize,
              ),
              SizedBox(width: spacing * 0.75),
              _GlassButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                onTap: _togglePause,
                isHighlighted: _isPaused,
                size: buttonSize,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar - thinner
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
              minHeight: 3,
            ),
          ),

          const SizedBox(height: 6),

          // Stats: 2x2 grid for better readability
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final statsBg = isDark
                  ? AppColors.pureBlack.withOpacity(0.5)
                  : AppColorsLight.elevated.withOpacity(0.9);
              final statsBorder = isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppColorsLight.cardBorder.withOpacity(0.3);
              final dividerColor = isDark
                  ? Colors.white.withOpacity(0.2)
                  : AppColorsLight.cardBorder.withOpacity(0.5);

              return Row(
            children: [
              // Left column: Timer + Calories
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statsBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statsBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Timer
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _isPaused ? AppColors.textMuted : AppColors.cyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPaused ? 'PAUSED' : _formatTime(_workoutSeconds),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: _isPaused ? null : 'monospace',
                              color: _isPaused ? AppColors.orange : AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 16, color: dividerColor),
                      // Calories
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 14, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalCaloriesBurned',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.orange,
                            ),
                          ),
                          Text(
                            'cal',
                            style: TextStyle(fontSize: 10, color: AppColors.orange.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Right column: Set + Water
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statsBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statsBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Set counter
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat, size: 14, color: AppColors.purple),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentSet/${exercise.sets ?? 3}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 16, color: dividerColor),
                      // Heart Rate from watch
                      const HeartRateDisplay(
                        iconSize: 14,
                        fontSize: 13,
                        showZoneLabel: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
            },
          ), // Close Builder
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Build challenge banner showing opponent and stats to beat
  Widget _buildChallengeBanner() {
    final challengerName = widget.challengeData!['challenger_name'] ?? 'Someone';
    final workoutData = widget.challengeData!['workout_data'] as Map<String, dynamic>? ?? {};
    final targetDuration = workoutData['duration_minutes'];
    final targetVolume = workoutData['total_volume'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.9),
            AppColors.red.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                    ),
                    children: [
                      const TextSpan(text: 'CHALLENGING '),
                      TextSpan(
                        text: challengerName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (targetDuration != null)
                _buildChallengeStat('⏱️', 'Beat', '$targetDuration min'),
              if (targetDuration != null && targetVolume != null)
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              if (targetVolume != null)
                _buildChallengeStat('💪', 'Beat', '${targetVolume.toStringAsFixed(0)} lbs'),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildChallengeStat(String emoji, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build the transition countdown overlay (shown before moving to next exercise)
  Widget _buildTransitionOverlay() {
    // Safety check
    if (_currentExerciseIndex >= _exercises.length - 1) {
      return const SizedBox.shrink();
    }

    final nextExercise = _exercises[_currentExerciseIndex + 1];

    return TransitionCountdownOverlay(
      secondsRemaining: _transitionSecondsRemaining,
      initialDuration: _transitionDuration,
      nextExercise: nextExercise,
      nextExerciseImageUrl: _nextExerciseImageUrl,
      onSkip: _skipTransition,
    );
  }

  // NOTE: _buildSetTrackingOverlay was removed - now using SetTrackingSection widget
  // NOTE: _buildRestOverlay was removed - now using RestTimerOverlay widget
  Widget _buildBottomSection(WorkoutExercise currentExercise, WorkoutExercise? nextExercise) {
    // Build completed sets count per exercise
    final completedSetsPerExercise = <int, int>{};
    for (int i = 0; i < _exercises.length; i++) {
      completedSetsPerExercise[i] = _completedSets[i]?.length ?? 0;
    }

    return ExerciseThumbnailStrip(
      exercises: _exercises,
      currentIndex: _currentExerciseIndex,
      completedSetsPerExercise: completedSetsPerExercise,
      totalSetsPerExercise: _totalSetsPerExercise,
      isResting: _isResting,
      onExerciseTap: (index) {
        // Allow switching to any exercise
        _makeExerciseActive(index);
      },
      onSkip: _isResting ? _endRest : _skipExercise,
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
  final bool isSubdued; // For de-emphasized buttons like close
  final double size;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
    this.isSubdued = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final bgColor = isHighlighted
        ? AppColors.cyan.withOpacity(0.3)
        : isSubdued
            ? (isDark ? AppColors.pureBlack.withOpacity(0.3) : AppColorsLight.elevated.withOpacity(0.8))
            : (isDark ? AppColors.pureBlack.withOpacity(0.5) : AppColorsLight.elevated.withOpacity(0.9));

    final borderColor = isHighlighted
        ? AppColors.cyan.withOpacity(0.5)
        : isSubdued
            ? (isDark ? Colors.white.withOpacity(0.1) : AppColorsLight.cardBorder.withOpacity(0.3))
            : (isDark ? Colors.white.withOpacity(0.2) : AppColorsLight.cardBorder.withOpacity(0.5));

    final iconColor = isHighlighted
        ? AppColors.cyan
        : isSubdued
            ? (isDark ? Colors.white.withOpacity(0.5) : AppColorsLight.textMuted)
            : (isDark ? Colors.white : AppColorsLight.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Glowing Increment Button (for +/- in expanded input)
// ─────────────────────────────────────────────────────────────────

class _GlowingIncrementButton extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final bool isLeft;
  final VoidCallback onTap;

  const _GlowingIncrementButton({
    required this.icon,
    required this.accentColor,
    required this.isLeft,
    required this.onTap,
  });

  @override
  State<_GlowingIncrementButton> createState() => _GlowingIncrementButtonState();
}

class _GlowingIncrementButtonState extends State<_GlowingIncrementButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _glowController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _glowController.reverse();
    widget.onTap();
    HapticFeedback.mediumImpact();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _glowController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowIntensity = _glowAnimation.value;
          // 30% brightness increase when pressed
          final baseOpacity = 0.4;
          final pressedOpacity = baseOpacity + (0.3 * glowIntensity);
          final baseOpacity2 = 0.2;
          final pressedOpacity2 = baseOpacity2 + (0.15 * glowIntensity);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 56,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.accentColor.withOpacity(pressedOpacity),
                  widget.accentColor.withOpacity(pressedOpacity2),
                ],
              ),
              borderRadius: BorderRadius.horizontal(
                left: widget.isLeft ? const Radius.circular(14) : Radius.zero,
                right: widget.isLeft ? Radius.zero : const Radius.circular(14),
              ),
              // Subtle glow when pressed
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.4 * glowIntensity),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft ripple effect
                if (_isPressed)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 80),
                    opacity: glowIntensity * 0.3,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                // Icon
                AnimatedScale(
                  duration: const Duration(milliseconds: 80),
                  scale: _isPressed ? 0.9 : 1.0,
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
