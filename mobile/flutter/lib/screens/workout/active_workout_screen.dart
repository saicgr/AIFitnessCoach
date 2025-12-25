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

/// Log for a single set
class SetLog {
  final int reps;
  final double weight;
  final DateTime completedAt;
  final String setType; // 'working', 'warmup', 'failure', 'amrap'

  SetLog({
    required this.reps,
    required this.weight,
    DateTime? completedAt,
    this.setType = 'working',
  }) : completedAt = completedAt ?? DateTime.now();
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

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
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
  int _initialRestDuration = 0; // Track initial rest for progress bar
  String _currentRestMessage = ''; // Current encouragement message

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
    // Initialize completed sets tracking
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      _totalSetsPerExercise[i] = exercise.sets ?? 3;
      // Initialize with empty data - will be populated from API
      _previousSets[i] = [];
    }
    // Fetch historical data from backend
    _fetchExerciseHistory();
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

  /// Handle tap on video/screen background
  /// - If overlay is showing: hide it to show full video
  /// - If overlay is hidden: toggle BOTH video and workout pause
  void _handleScreenTap() {
    if (_showSetOverlay) {
      // First tap: hide overlay to show full video
      setState(() => _showSetOverlay = false);
      HapticFeedback.lightImpact();
    } else {
      // Overlay is hidden, toggle both video and workout timer
      _togglePause();
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

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);

        // Haptic countdown warnings
        if (_restSecondsRemaining == 5) {
          HapticFeedback.lightImpact();
        } else if (_restSecondsRemaining == 3) {
          HapticFeedback.mediumImpact();
        } else if (_restSecondsRemaining == 2) {
          HapticFeedback.mediumImpact();
        } else if (_restSecondsRemaining == 1) {
          HapticFeedback.mediumImpact();
        }

        if (_restSecondsRemaining == 0) _endRest();
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _endRest() {
    _restTimer?.cancel();
    final wasRestingBetweenExercises = _isRestingBetweenExercises;
    setState(() {
      _isResting = false;
      _isRestingBetweenExercises = false;
      _restSecondsRemaining = 0;
    });
    // Strong haptic feedback when rest ends
    HapticFeedback.heavyImpact();
    // Additional vibration pattern for better notification
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });

    // If we were resting between exercises, move to the next exercise now
    if (wasRestingBetweenExercises) {
      _moveToNextExercise();
    }
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
    final completedSetIndex = _completedSets[_currentExerciseIndex]!.length;
    setState(() {
      _completedSets[_currentExerciseIndex]!.add(SetLog(reps: reps, weight: weight));
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

    if (_currentSet < totalSets) {
      // Move to next set, keep the same weight/reps for convenience
      setState(() => _currentSet++);
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

  /// Delete a completed set (from swipe action)
  void _deleteCompletedSet(int exerciseIndex, int setIndex) {
    final sets = _completedSets[exerciseIndex];
    if (sets == null || setIndex >= sets.length) return;

    setState(() {
      sets.removeAt(setIndex);
      // If we deleted a set from the current exercise, adjust current set counter
      if (exerciseIndex == _currentExerciseIndex) {
        _currentSet = sets.length + 1;
      }
    });
    HapticFeedback.mediumImpact();
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
                    );
                  });
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
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
    setState(() => _isInStretchPhase = false);
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

    // Start stretch phase instead of immediately completing
    _startStretchPhase();
  }

  Future<void> _finalizeWorkoutCompletion() async {
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
        // Challenge data (if this workout was from a challenge)
        'challengeId': widget.challengeId,
        'challengeData': widget.challengeData,
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

  void _showQuitDialog() {
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

    String? selectedReason;
    final TextEditingController notesController = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColorsLight.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title with progress
                Row(
                  children: [
                    Icon(Icons.exit_to_app, color: isDark ? AppColors.orange : AppColorsLight.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Workout Early?',
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$progressPercent% complete • $totalCompletedSets sets done',
                            style: TextStyle(
                              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
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
                    color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressPercent >= 50 ? (isDark ? AppColors.cyan : AppColorsLight.cyan) : (isDark ? AppColors.orange : AppColorsLight.orange),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Question
                Text(
                  'Why are you ending early?',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
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
                    _buildReasonChip('too_tired', 'Too tired', Icons.battery_1_bar, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('out_of_time', 'Out of time', Icons.timer_off, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('not_feeling_well', 'Not feeling well', Icons.sick, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('equipment_unavailable', 'Equipment busy', Icons.fitness_center, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('injury', 'Pain/Injury', Icons.healing, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                    _buildReasonChip('other', 'Other reason', Icons.more_horiz, selectedReason, isDark, (reason) {
                      setModalState(() => selectedReason = reason);
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Optional notes
                TextField(
                  controller: notesController,
                  style: TextStyle(color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)...',
                    hintStyle: TextStyle(color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.6)),
                    filled: true,
                    fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
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
                          side: BorderSide(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Keep Going',
                          style: TextStyle(color: isDark ? AppColors.cyan : AppColorsLight.cyan, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _logWorkoutExitAndQuit(
                            selectedReason ?? 'quick_exit',
                            notesController.text.isEmpty ? null : notesController.text,
                            exercisesWithCompletedSets,
                            totalCompletedSets,
                            progressPercent.toDouble(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.orange : AppColorsLight.orange,
                          foregroundColor: Colors.white,
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

  Widget _buildReasonChip(
    String value,
    String label,
    IconData icon,
    String? selectedReason,
    bool isDark,
    Function(String) onSelected,
  ) {
    final isSelected = selectedReason == value;
    final orangeColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor.withOpacity(0.2) : elevatedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? orangeColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? orangeColor : textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? orangeColor : textSecondaryColor,
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
    int selectedAmount = 250; // Default 250ml
    bool useOz = false; // false = ml, true = oz
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Convert display amounts based on unit
          String formatAmount(int ml) {
            if (useOz) {
              return '${(ml / 29.5735).toStringAsFixed(1)} oz';
            }
            return '${ml}ml';
          }

          String formatTotal() {
            if (useOz) {
              return '${(_totalDrinkIntakeMl / 29.5735).toStringAsFixed(1)} oz';
            }
            return '${(_totalDrinkIntakeMl / 1000).toStringAsFixed(2)}L';
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
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

                  // Title with unit toggle
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
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
                              'Total: ${formatTotal()}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Unit toggle
                      GestureDetector(
                        onTap: () {
                          setModalState(() => useOz = !useOz);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Text(
                            useOz ? 'oz' : 'ml',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick amount buttons - common sizes
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDrinkAmountChip(250, selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                      _buildDrinkAmountChip(350, selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                      _buildDrinkAmountChip(500, selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                      _buildDrinkAmountChip(750, selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                      _buildDrinkAmountChip(1000, selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                      // 1 gallon = 3785ml
                      _buildDrinkAmountChipLabeled(3785, '1 gal', selectedAmount, useOz, (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Custom input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Custom amount',
                            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                            filled: true,
                            fillColor: AppColors.elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixText: useOz ? 'oz' : 'ml',
                            suffixStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              setModalState(() {
                                // Convert to ml if using oz
                                selectedAmount = useOz ? (parsed * 29.5735).round() : parsed.round();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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
                        'Log ${formatAmount(selectedAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrinkAmountChip(int amountMl, int selected, bool useOz, Function(int) onTap) {
    final isSelected = amountMl == selected;
    String label = useOz ? '${(amountMl / 29.5735).toStringAsFixed(1)}oz' : '${amountMl}ml';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(amountMl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkAmountChipLabeled(int amountMl, String label, int selected, bool useOz, Function(int) onTap) {
    final isSelected = amountMl == selected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(amountMl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Show warmup screen if in warmup phase
    if (_isInWarmupPhase) {
      return _buildWarmupScreen(context, isDark, backgroundColor);
    }

    // Show stretch screen if in stretch phase (after workout, before completion)
    if (_isInStretchPhase) {
      return _buildStretchScreen(context, isDark, backgroundColor);
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          // Challenge banner (if this is a challenge workout)
          if (widget.challengeId != null && widget.challengeData != null) ...[
            _buildChallengeBanner(),
            const SizedBox(height: 8),
          ],

          // Top row: Close, title, pause - more compact
          Row(
            children: [
              _GlassButton(
                icon: Icons.close,
                onTap: _showQuitDialog,
                size: 32,
                isSubdued: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_currentExerciseIndex + 1}/${_exercises.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _GlassButton(
                icon: Icons.list_alt,
                onTap: _showExerciseListDrawer,
                size: 36,
              ),
              const SizedBox(width: 6),
              _GlassButton(
                icon: _showSetOverlay ? Icons.table_chart : Icons.table_chart_outlined,
                onTap: () => setState(() => _showSetOverlay = !_showSetOverlay),
                isHighlighted: _showSetOverlay,
                size: 36,
              ),
              const SizedBox(width: 6),
              _GlassButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                onTap: _togglePause,
                isHighlighted: _isPaused,
                size: 36,
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
                      // Water - tappable
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showDrinkIntakeDialog();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${(_totalDrinkIntakeMl / 1000).toStringAsFixed(2)}L',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.add_circle_outline, size: 12, color: Colors.blue.withOpacity(0.5)),
                          ],
                        ),
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

  /// Build 1RM prompt button for rest overlay
  Widget _build1RMPrompt(
    WorkoutExercise exercise,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
  ) {
    // Check if user just did a heavy set (low reps suggest strength work)
    final completedSets = _completedSets[_currentExerciseIndex] ?? [];
    final lastSet = completedSets.isNotEmpty ? completedSets.last : null;

    // Show prompt if: just completed a heavy set (5 or fewer reps) or any working set
    final showPrompt = lastSet != null;

    if (!showPrompt) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log 1RM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
                Text(
                  'Track your max',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.orange.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRestOverlay() {
    // Calculate progress (1.0 = full, 0.0 = done)
    final progress = _initialRestDuration > 0
        ? _restSecondsRemaining / _initialRestDuration
        : 0.0;

    // Get next exercise info
    final hasNextExercise = _currentExerciseIndex < _exercises.length - 1;
    final nextExercise = hasNextExercise
        ? _exercises[_currentExerciseIndex + 1]
        : null;

    // Check if this is a rest between sets (not exercises)
    final currentExercise = _exercises[_currentExerciseIndex];
    final completedSetsCount = _completedSets[_currentExerciseIndex]?.length ?? 0;
    final totalSets = _totalSetsPerExercise[_currentExerciseIndex] ?? currentExercise.sets ?? 3;
    // Use the explicit flag if set, otherwise fall back to computed check
    final isRestBetweenSets = !_isRestingBetweenExercises && completedSetsCount < totalSets;

    // Theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.pureBlack.withOpacity(0.92)
        : AppColorsLight.surface.withOpacity(0.98);
    final cardBg = isDark
        ? AppColors.elevated.withOpacity(0.8)
        : AppColorsLight.elevated;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;
    final subtitleColor = isDark ? Colors.white70 : AppColorsLight.textSecondary;

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // REST label
              Text(
                'REST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple.withOpacity(0.8),
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 12),

              // Large timer
              Text(
                '${_restSecondsRemaining}s',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1,
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              Container(
                height: 6,
                width: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.15) : AppColorsLight.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    width: 200 * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple,
                          AppColors.purple.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // AI Coach encouragement message
              if (_currentRestMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: AppColors.purple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentRestMessage,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Next up section
              if (isRestBetweenSets)
                // Rest between sets - show current exercise set info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.replay,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT SET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.withOpacity(0.8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentExercise.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set ${completedSetsCount + 1} of $totalSets',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0)
              else if (nextExercise != null)
                // Rest between exercises - show next exercise
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.skip_next,
                          color: Colors.green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT UP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.withOpacity(0.8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextExercise.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${nextExercise.sets ?? 3} sets · ${nextExercise.reps ?? 10} reps${nextExercise.weight != null && nextExercise.weight! > 0 ? ' · ${nextExercise.weight}kg' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // Log 1RM button - shown during rest
              _build1RMPrompt(currentExercise, cardBg, textColor, subtitleColor),

              const Spacer(flex: 2),

              // Skip Rest button
              TextButton.icon(
                onPressed: _endRest,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.skip_next, color: AppColors.purple, size: 20),
                label: const Text(
                  'Skip Rest',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
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

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayBg = isDark
        ? AppColors.pureBlack.withOpacity(0.92)
        : AppColorsLight.elevated.withOpacity(0.98);
    final overlayBorder = isDark
        ? AppColors.cardBorder.withOpacity(0.4)
        : AppColorsLight.cardBorder.withOpacity(0.5);
    final headerBg = isDark
        ? AppColors.elevated.withOpacity(0.6)
        : AppColorsLight.glassSurface.withOpacity(0.8);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final inputBg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final rowBorder = isDark
        ? AppColors.cardBorder.withOpacity(0.2)
        : AppColorsLight.cardBorder.withOpacity(0.3);

    // iOS-style blur effect with ClipRRect and BackdropFilter
    // Reduced blur for better content visibility behind
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10 : 8,
          sigmaY: isDark ? 10 : 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            // More translucent background to see content behind
            color: isDark
                ? AppColors.pureBlack.withOpacity(0.65)
                : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppColorsLight.cardBorder.withOpacity(0.4),
            ),
            // Subtle shadows for visual separation from background
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with exercise navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          : textMuted.withOpacity(0.3),
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
                          color: isViewingCurrent ? AppColors.cyan : textPrimary,
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
                              color: textMuted,
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
                          : textMuted.withOpacity(0.3),
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
              color: isDark
                  ? AppColors.elevated.withOpacity(0.3)
                  : AppColorsLight.glassSurface.withOpacity(0.6),
            ),
            child: Row(
              children: [
                SizedBox(width: 36, child: Center(child: Text('SET', style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textMuted,
                  letterSpacing: 0.5,
                )))),
                Expanded(flex: 3, child: Center(child: Text('PREVIOUS', style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textMuted,
                  letterSpacing: 0.5,
                )))),
                Expanded(flex: 4, child: Center(child: Text(_useKg ? 'KG' : 'LBS', style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                  letterSpacing: 0.5,
                )))),
                const SizedBox(width: 8), // Gap between KG and REPS
                Expanded(flex: 4, child: Center(child: Text('REPS', style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                  letterSpacing: 0.5,
                )))),
                const SizedBox(width: 50), // Match max checkmark button width
              ],
            ),
          ),

          // Warmup set rows (2 warmup sets displayed with "W" label)
          ...List.generate(2, (warmupIndex) => _buildWarmupSetRow(
            setLabel: 'W',
            repRange: _getRepRange(viewingExercise),
            rowBorder: rowBorder,
            textMuted: textMuted,
            textSecondary: textSecondary,
          )),

          // Working set rows
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

            // Check if this is the expanded active row
            final isExpanded = isCurrent && _isActiveRowExpanded;

            // Calculate opacity for non-active rows when expanded
            final rowOpacity = (isCurrent || !_isActiveRowExpanded) ? 1.0 : 0.5;

            // Active row is much more prominent
            final rowWidget = GestureDetector(
              onTap: isCurrent ? () {
                setState(() => _isActiveRowExpanded = !_isActiveRowExpanded);
                // More satisfying haptic for expand/collapse
                HapticFeedback.mediumImpact();
              } : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: rowOpacity,
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: isCurrent
                    ? EdgeInsets.symmetric(horizontal: 2, vertical: isExpanded ? 6 : 3)
                    : EdgeInsets.zero,
                padding: EdgeInsets.symmetric(
                  horizontal: isCurrent ? 8 : 10,
                  vertical: isExpanded ? 16 : (isCurrent ? 8 : 5),
                ),
                decoration: BoxDecoration(
                  // Active row: subtle gradient background (premium feel)
                  gradient: isCurrent
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.cyan.withOpacity(isExpanded ? 0.18 : 0.12),
                            AppColors.electricBlue.withOpacity(isExpanded ? 0.12 : 0.08),
                            AppColors.cyan.withOpacity(isExpanded ? 0.08 : 0.05),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        )
                      : null,
                  color: isCompleted
                      ? AppColors.success.withOpacity(0.08)
                      : isCurrent
                          ? null // Using gradient
                          : Colors.transparent,
                  borderRadius: isCurrent ? BorderRadius.circular(isExpanded ? 16 : 12) : null,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.cyan.withOpacity(isExpanded ? 0.4 : 0.3),
                          width: isExpanded ? 1.5 : 1,
                        )
                      : Border(
                          bottom: BorderSide(color: rowBorder),
                        ),
                  // Soft ambient glow for active row (premium, not gamey)
                  boxShadow: isCurrent
                      ? [
                          // Outer soft glow - large blur, no spread
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(isExpanded ? 0.15 : 0.1),
                            blurRadius: isExpanded ? 16 : 10,
                            spreadRadius: 0,
                          ),
                          // Inner subtle highlight
                          BoxShadow(
                            color: AppColors.electricBlue.withOpacity(0.05),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: isExpanded
                    // EXPANDED VIEW - Large, tactile controls with animations
                    ? Column(
                        key: const ValueKey('expanded'),
                        children: [
                          // Collapse hint - fades in with delay
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.cyan.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to collapse',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.cyan.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 50.ms, duration: 200.ms),
                          const SizedBox(height: 12),
                          // Large KG and REPS side by side - fades in with delay
                          Row(
                            children: [
                              // KG section
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      _useKg ? 'WEIGHT (KG)' : 'WEIGHT (LBS)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.cyan,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildExpandedInput(
                                      controller: _weightController,
                                      isDecimal: true,
                                      accentColor: AppColors.cyan,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // REPS section
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'REPS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.purple,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildExpandedInput(
                                      controller: _repsController,
                                      isDecimal: false,
                                      accentColor: AppColors.purple,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 80.ms, duration: 200.ms),
                          const SizedBox(height: 16),
                          // Large complete button - pops in with spring scale
                          _buildExpandedCompleteButton()
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 200.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.0, 1.0),
                              delay: 100.ms,
                              duration: 300.ms,
                              curve: Curves.elasticOut,
                            ),
                        ],
                      )
                    // COMPACT VIEW - Normal row
                    : Row(
                        key: const ValueKey('compact'),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Set number - compact, centered
                          SizedBox(
                            width: 36,
                            child: Center(
                              child: Container(
                                width: isCurrent ? 28 : 22,
                                height: isCurrent ? 28 : 22,
                                decoration: isCurrent
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.cyan.withOpacity(0.2),
                                        border: Border.all(color: AppColors.cyan, width: 1.5),
                                      )
                                    : null,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: isCurrent ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? AppColors.success
                                          : isCurrent
                                              ? AppColors.cyan
                                              : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Previous session
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                prevDisplay,
                                style: TextStyle(
                                  fontSize: isCurrent ? 13 : 12,
                                  color: isCurrent
                                      ? textSecondary
                                      : textMuted.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),

                          // Weight - inline editable for current set only when viewing current exercise
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: isCurrent
                                  ? _buildInlineInput(
                                      controller: _weightController,
                                      isDecimal: true,
                                      isActive: true,
                                      accentColor: AppColors.cyan,
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
                                        color: isCompleted ? AppColors.success : textMuted,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(width: 8), // Gap between KG and REPS

                          // Reps - inline editable for current set only when viewing current exercise
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: isCurrent
                                  ? _buildInlineInput(
                                      controller: _repsController,
                                      isDecimal: false,
                                      isActive: true,
                                      accentColor: AppColors.purple,
                                    )
                                  : Text(
                                      isCompleted ? completedSetData!.reps.toString() : '-',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                        color: isCompleted ? AppColors.success : textMuted,
                                      ),
                                    ),
                            ),
                          ),

                          // Checkmark / Complete button - CIRCULAR with neon ring
                          SizedBox(
                            width: 50, // Consistent width for alignment
                            child: isCompleted
                                // Completed state - green checkmark with burst animation
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Burst effect for just-completed set
                                      if (_justCompletedSetIndex == index)
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.success, width: 2),
                                          ),
                                        ).animate()
                                          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.4, 1.4), duration: 400.ms)
                                          .fadeOut(duration: 400.ms),
                                      // Second burst ring
                                      if (_justCompletedSetIndex == index)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.success.withOpacity(0.3),
                                          ),
                                        ).animate()
                                          .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.8, 1.8), duration: 500.ms, delay: 50.ms)
                                          .fadeOut(duration: 400.ms, delay: 100.ms),
                                      // Main checkmark
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.success.withOpacity(0.15),
                                          border: Border.all(color: AppColors.success, width: 2),
                                        ),
                                        child: const Icon(Icons.check_rounded, size: 20, color: AppColors.success),
                                      ).animate()
                                        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.elasticOut),
                                    ],
                                  )
                                : isCurrent
                                    // Active set - clean circular button with soft glow
                                    ? GestureDetector(
                                        onTapDown: (_) => setState(() => _isDoneButtonPressed = true),
                                        onTapUp: (_) {
                                          setState(() => _isDoneButtonPressed = false);
                                          HapticFeedback.heavyImpact();
                                          _completeSet();
                                        },
                                        onTapCancel: () => setState(() => _isDoneButtonPressed = false),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 100),
                                          width: _isDoneButtonPressed ? 40 : 44,
                                          height: _isDoneButtonPressed ? 40 : 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: _isDoneButtonPressed
                                                  ? [AppColors.electricBlue, AppColors.cyan]
                                                  : [AppColors.cyan, AppColors.electricBlue],
                                            ),
                                            boxShadow: [
                                              // Soft ambient glow (premium feel)
                                              BoxShadow(
                                                color: AppColors.cyan.withOpacity(_isDoneButtonPressed ? 0.35 : 0.2),
                                                blurRadius: _isDoneButtonPressed ? 12 : 8,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.check_rounded, size: 26, color: Colors.white),
                                        ),
                                      )
                                    // Pending set - subtle outline
                                    : Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: textMuted.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                          ),
                        ],
                      ),
                ), // Close AnimatedSwitcher
              ), // Close AnimatedContainer
              ), // Close AnimatedOpacity
            );

            // Return with animations - reduced opacity for completed sets
            if (isCompleted) {
              // Wrap completed sets with Dismissible for swipe actions
              return Dismissible(
                key: Key('set_${_viewingExerciseIndex}_$index'),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: AppColors.cyan, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.delete, color: AppColors.error, size: 20),
                    ],
                  ),
                ),
                onUpdate: (details) {
                  // Haptic feedback when swipe threshold is reached
                  if (details.reached && details.previousReached == false) {
                    HapticFeedback.mediumImpact();
                  }
                },
                confirmDismiss: (direction) async {
                  HapticFeedback.selectionClick();
                  if (direction == DismissDirection.startToEnd) {
                    // Swipe right to edit - don't dismiss, just open editor
                    _editCompletedSet(_viewingExerciseIndex, index);
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    // Swipe left to delete - confirm first
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.elevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Delete Set?',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: Text(
                          'Are you sure you want to delete Set ${index + 1}?',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _deleteCompletedSet(_viewingExerciseIndex, index);
                  }
                },
                child: Opacity(
                  opacity: 0.6, // Reduce cognitive load on completed sets
                  child: rowWidget,
                ),
              );
            } else if (isCurrent) {
              return rowWidget.animate().shimmer(
                duration: 2000.ms,
                color: AppColors.cyan.withOpacity(0.1),
              );
            } else {
              return rowWidget;
            }
          }),

          // Add Set button - distinct card
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _totalSetsPerExercise[_viewingExerciseIndex] = totalSets + 1;
                });
                // Satisfying haptic for adding a set
                HapticFeedback.mediumImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan.withOpacity(0.15),
                        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.add, size: 16, color: AppColors.cyan),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Add Set',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Rest timer info - distinct card with clear separation
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.purple.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: isViewingCurrent
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.purple.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.timer_outlined, size: 14, color: AppColors.purple),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rest: ${viewingExercise.restSeconds ?? 90}s between sets',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.purple,
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
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.keyboard_return, size: 14, color: AppColors.cyan),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Back to Current Exercise',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
        ), // Close Container
      ), // Close BackdropFilter
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1); // Close ClipRRect with animation
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
    bool isActive = false,
    Color accentColor = AppColors.cyan,
  }) {
    final increment = isDecimal ? 2.5 : 1.0;
    // Larger tap targets for easier use during workouts (10-15% bigger)
    final buttonWidth = isActive ? 32.0 : 28.0;
    final height = isActive ? 40.0 : 36.0;
    final iconSize = isActive ? 18.0 : 16.0;
    final fontSize = isActive ? 15.0 : 13.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isActive
        ? (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite)
        : (isDark ? AppColors.elevated : AppColorsLight.glassSurface);
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(isActive ? 10 : 8),
        border: Border.all(
          color: isActive ? accentColor : accentColor.withOpacity(0.5),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Minus button - compact but tappable
          GestureDetector(
            onTap: () {
              if (isDecimal) {
                final current = double.tryParse(controller.text) ?? 0;
                final newVal = (current - increment).clamp(0.0, 999.0);
                controller.text = newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
              } else {
                final current = int.tryParse(controller.text) ?? 0;
                final newVal = (current - 1).clamp(0, 999);
                controller.text = newVal.toString();
              }
              setState(() {});
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: buttonWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.15),
                        ],
                      )
                    : null,
                color: isActive ? null : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(isActive ? 8 : 7),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: isActive ? Colors.white : accentColor,
                ),
              ),
            ),
          ),
          // Text display - tappable to edit via dialog
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showNumberInputDialog(controller, isDecimal);
              },
              child: Container(
                height: height,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    controller.text.isEmpty ? '0' : controller.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: isActive ? textColor : accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Plus button - compact but tappable
          GestureDetector(
            onTap: () {
              if (isDecimal) {
                final current = double.tryParse(controller.text) ?? 0;
                final newVal = current + increment;
                controller.text = newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
              } else {
                final current = int.tryParse(controller.text) ?? 0;
                final newVal = current + 1;
                controller.text = newVal.toString();
              }
              setState(() {});
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: buttonWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.15),
                        ],
                      )
                    : null,
                color: isActive ? null : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(isActive ? 8 : 7),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: isActive ? Colors.white : accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get rep range string for an exercise
  String _getRepRange(WorkoutExercise exercise) {
    if (exercise.reps != null) {
      final reps = exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    } else if (exercise.durationSeconds != null) {
      return '${exercise.durationSeconds}s';
    }
    return '8-12';
  }

  /// Build warmup set row for the Set Tracker (display only, not interactive)
  Widget _buildWarmupSetRow({
    required String setLabel,
    required String repRange,
    required Color rowBorder,
    required Color textMuted,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: rowBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set label (W for warmup)
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    setLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Previous (dash for warmup)
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted.withOpacity(0.5),
                ),
              ),
            ),
          ),
          // Weight (dash for warmup - user decides warmup weight)
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Rep range
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                repRange,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          // Empty space for checkmark column alignment
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  /// Build expanded input for the Set Tracker (larger, more tactile)
  Widget _buildExpandedInput({
    required TextEditingController controller,
    required bool isDecimal,
    required Color accentColor,
  }) {
    final increment = isDecimal ? 2.5 : 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Large minus button with glow effect
          _GlowingIncrementButton(
            icon: Icons.remove,
            accentColor: accentColor,
            isLeft: true,
            onTap: () {
              if (isDecimal) {
                final current = double.tryParse(controller.text) ?? 0;
                final newVal = (current - increment).clamp(0.0, 999.0);
                controller.text = newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
              } else {
                final current = int.tryParse(controller.text) ?? 0;
                final newVal = (current - 1).clamp(0, 999);
                controller.text = newVal.toString();
              }
              setState(() {});
            },
          ),
          // Large text display - tappable to edit
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showNumberInputDialog(controller, isDecimal);
              },
              child: Container(
                height: 64,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    controller.text.isEmpty ? '0' : controller.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Large plus button with glow effect
          _GlowingIncrementButton(
            icon: Icons.add,
            accentColor: accentColor,
            isLeft: false,
            onTap: () {
              if (isDecimal) {
                final current = double.tryParse(controller.text) ?? 0;
                final newVal = current + increment;
                controller.text = newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
              } else {
                final current = int.tryParse(controller.text) ?? 0;
                final newVal = current + 1;
                controller.text = newVal.toString();
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// Build expanded complete button for the Set Tracker
  Widget _buildExpandedCompleteButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isDoneButtonPressed = true),
      onTapUp: (_) {
        setState(() {
          _isDoneButtonPressed = false;
          // Keep expanded state for next set - better UX
        });
        HapticFeedback.heavyImpact();
        _completeSet();
      },
      onTapCancel: () => setState(() => _isDoneButtonPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: _isDoneButtonPressed ? 52 : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDoneButtonPressed
                ? [AppColors.electricBlue, AppColors.cyan]
                : [AppColors.cyan, AppColors.electricBlue],
          ),
          boxShadow: [
            // Soft ambient glow (premium, not gamey)
            BoxShadow(
              color: AppColors.cyan.withOpacity(_isDoneButtonPressed ? 0.3 : 0.18),
              blurRadius: _isDoneButtonPressed ? 14 : 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 28, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'COMPLETE SET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show a dialog to edit the number value
  void _showNumberInputDialog(TextEditingController controller, bool isDecimal) {
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cyan, width: 2),
            ),
          ),
          onSubmitted: (value) {
            // For reps, convert to integer
            if (!isDecimal) {
              final intVal = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              // For reps, convert to integer
              if (!isDecimal) {
                final intVal = int.tryParse(editController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                controller.text = intVal.toString();
              } else {
                controller.text = editController.text;
              }
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(WorkoutExercise currentExercise, WorkoutExercise? nextExercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: isDark
                          ? AppColors.elevated.withOpacity(0.95)
                          : AppColorsLight.elevated.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                      ),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
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
              color: isDark
                  ? AppColors.nearBlack.withOpacity(0.95)
                  : AppColorsLight.elevated.withOpacity(0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: isDark ? null : Border(
                top: BorderSide(color: AppColorsLight.cardBorder.withOpacity(0.3)),
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
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

                // Next exercise indicator - MORE PROMINENT sticky drawer style
                Expanded(
                  child: nextExercise != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.cyan.withOpacity(0.15),
                                AppColors.electricBlue.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cyan.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Arrow icon with animation hint
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.cyan),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: AppColors.cyan.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      nextExercise.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
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
                      // Last exercise - celebration style
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.success.withOpacity(0.15),
                                AppColors.success.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.success),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Last Exercise!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(width: 12),

                // Skip button - skips rest when resting, skips exercise otherwise
                OutlinedButton(
                  onPressed: _isResting ? _endRest : _skipExercise,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(
                      color: _isResting
                          ? AppColors.purple.withOpacity(0.5)
                          : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                    ),
                    foregroundColor: _isResting
                        ? AppColors.purple
                        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isResting ? 'Skip Rest' : 'Skip'),
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
  final bool isTappable;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
    this.suffix,
    this.label,
    this.scaleFactor = 1.0,
    this.isTappable = false,
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
        border: Border.all(
          color: isTappable ? color.withOpacity(0.5) : color.withOpacity(0.3),
          width: isTappable ? 1.5 : 1.0,
        ),
        // Add subtle glow for tappable items
        boxShadow: isTappable
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: innerSpacing),
          Text(
            // If paused, just show the label instead of time + PAUSED to save space
            label != null ? label! : value,
            style: TextStyle(
              fontSize: label != null ? labelFontSize : valueFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: label != null ? null : 'monospace',
              color: label != null ? AppColors.orange : color,
            ),
          ),
          if (suffix != null && label == null)
            Text(
              suffix!,
              style: TextStyle(
                fontSize: suffixFontSize,
                color: color.withOpacity(0.7),
              ),
            ),
          // Add tap indicator for tappable chips
          if (isTappable) ...[
            SizedBox(width: innerSpacing * 0.5),
            Icon(Icons.add_circle_outline, size: iconSize * 0.7, color: color.withOpacity(0.5)),
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
