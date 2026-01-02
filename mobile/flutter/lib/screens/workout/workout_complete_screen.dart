import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/lottie_animations.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/personal_goals_service.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/subjective_feedback_provider.dart';
import '../../data/models/subjective_feedback.dart';
import '../challenges/widgets/challenge_complete_dialog.dart';
import '../challenges/widgets/challenge_friends_dialog.dart';
import 'widgets/share_workout_sheet.dart';

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final int duration;
  final int calories;
  // Additional workout performance data for AI Coach feedback
  final String? workoutLogId;
  final List<Map<String, dynamic>>? exercisesPerformance;
  final int? totalRestSeconds;
  final double? avgRestSeconds;
  final int? totalSets;
  final int? totalReps;
  final double? totalVolumeKg;

  // Challenge parameters (if workout was from a challenge)
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  // PRs detected by the backend during workout completion
  final List<PersonalRecordInfo>? personalRecords;

  // Performance comparison data - improvements/setbacks vs previous session
  final PerformanceComparisonInfo? performanceComparison;

  const WorkoutCompleteScreen({
    super.key,
    required this.workout,
    required this.duration,
    required this.calories,
    this.workoutLogId,
    this.exercisesPerformance,
    this.totalRestSeconds,
    this.avgRestSeconds,
    this.totalSets,
    this.totalReps,
    this.totalVolumeKg,
    this.challengeId,
    this.challengeData,
    this.personalRecords,
    this.performanceComparison,
  });

  @override
  ConsumerState<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  int _rating = 0;
  String _difficulty = 'just_right';
  bool _isSubmitting = false;
  String? _aiSummary;
  bool _isLoadingSummary = true;

  // Per-exercise ratings (exercise index -> rating 1-5)
  final Map<int, int> _exerciseRatings = {};
  // Per-exercise difficulty (exercise index -> difficulty)
  final Map<int, String> _exerciseDifficulties = {};
  // Whether to show exercise feedback section
  bool _showExerciseFeedback = false;

  // Achievements state
  Map<String, dynamic>? _achievements;
  bool _isLoadingAchievements = true;
  List<Map<String, dynamic>> _newPRs = [];
  bool _showExerciseProgress = false;
  Map<String, List<Map<String, dynamic>>> _exerciseProgressData = {};
  final Map<String, bool> _expandedExercises = {};

  // Exercise progression suggestions
  List<ProgressionSuggestion> _progressionSuggestions = [];
  bool _isLoadingProgressions = true;

  // Confetti controller for celebrations
  late ConfettiController _confettiController;

  // "Do More" / Extend workout state
  bool _isExtendingWorkout = false;

  // Subjective feedback state (post-workout mood/energy/confidence)
  int? _moodAfter;
  int? _energyAfter;
  int? _confidenceLevel;
  bool _feelingStronger = false;
  bool _showSubjectiveFeedback = true; // Show by default

  // Personal goals sync state
  WorkoutSyncResult? _goalSyncResult;
  bool _isLoadingGoalSync = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAICoachFeedback();

    // Use API-provided PRs if available (preferred as they're more accurate)
    if (widget.personalRecords != null && widget.personalRecords!.isNotEmpty) {
      _newPRs = widget.personalRecords!.map((pr) => {
        'exercise_name': pr.exerciseName,
        'weight_kg': pr.weightKg,
        'reps': pr.reps,
        'estimated_1rm_kg': pr.estimated1rmKg,
        'previous_pr': pr.previous1rmKg,
        'improvement_kg': pr.improvementKg,
        'improvement_percent': pr.improvementPercent,
        'celebration_message': pr.celebrationMessage,
        'is_all_time_pr': pr.isAllTimePr,
      }).toList();
      _isLoadingAchievements = false;
      // Play confetti for PRs
      Future.microtask(() => _confettiController.play());
      debugPrint('🏆 [Complete] Using ${_newPRs.length} PRs from API');
    } else {
      // Fall back to client-side detection
      _loadAchievements();
    }

    _loadExerciseProgress();
    _loadProgressionSuggestions();
    _syncWorkoutWithGoals();

    // Complete challenge if this workout was from a challenge
    if (widget.challengeId != null && widget.workoutLogId != null) {
      _completeChallenge();
    }
  }

  /// Complete challenge and show result dialog
  Future<void> _completeChallenge() async {
    try {
      final challengesService = ChallengesService(ref.read(apiClientProvider));
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      // Calculate challenged stats
      final challengedStats = {
        'duration_minutes': widget.duration,
        'total_volume': (widget.totalVolumeKg ?? 0) * 2.20462, // Convert to lbs
        'exercises_count': widget.exercisesPerformance?.length ?? 0,
        'total_sets': widget.totalSets ?? 0,
        'total_reps': widget.totalReps ?? 0,
      };

      debugPrint('🏆 [Challenge] Completing challenge ${widget.challengeId}');
      debugPrint('📊 [Challenge] Stats: $challengedStats');

      // Call complete challenge API
      final result = await challengesService.completeChallenge(
        userId: userId,
        challengeId: widget.challengeId!,
        workoutLogId: widget.workoutLogId!,
        challengedStats: challengedStats,
      );

      final didBeat = result['did_beat'] as bool? ?? false;
      final challengerName = widget.challengeData?['challenger_name'] ?? 'them';
      final workoutData = widget.challengeData?['workout_data'] as Map<String, dynamic>? ?? {};

      debugPrint(didBeat ? '🎉 [Challenge] VICTORY!' : '💪 [Challenge] Good attempt!');

      // Show challenge complete dialog after a short delay
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ChallengeCompleteDialog(
                challengerName: challengerName,
                workoutName: widget.workout.name ?? 'Workout',
                didBeat: didBeat,
                yourStats: challengedStats,
                theirStats: workoutData,
                onViewFeed: () {
                  // Navigate to social feed
                  if (mounted) {
                    context.go('/social');
                  }
                },
                onDismiss: () {
                  // Dialog dismissed
                },
              ),
            );

            // Trigger confetti if victory!
            if (didBeat) {
              _confettiController.play();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Show Challenge Friends dialog
  Future<void> _showChallengeFriendsDialog() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null || widget.workoutLogId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to challenge friends at this time'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Fetch friends list (mutual friends who follow each other)
      debugPrint('🔍 [Challenge] Fetching friends list...');
      final response = await apiClient.get(
        '/social/connections/friends/$userId',
      );

      // Backend returns list of UserProfile objects directly
      final friendsList = (response.data as List?) ?? [];
      final friends = friendsList.map((f) {
        return {
          'id': f['id'],
          'name': f['name'] ?? 'Unknown',
          'avatar_url': f['avatar_url'],
        };
      }).toList();

      if (friends.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You don\'t have any friends yet. Add some friends first!'),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Prepare workout data for challenge
      final workoutData = {
        'duration_minutes': widget.duration,
        'total_volume': (widget.totalVolumeKg ?? 0) * 2.20462, // Convert to lbs
        'exercises_count': widget.exercisesPerformance?.length ?? 0,
        'total_sets': widget.totalSets ?? 0,
        'total_reps': widget.totalReps ?? 0,
      };

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ChallengeFriendsDialog(
            userId: userId,
            workoutLogId: widget.workoutLogId!,
            workoutName: widget.workout.name ?? 'Workout',
            workoutData: workoutData,
            friends: friends,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error showing challenge dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAICoachFeedback() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Debug logging to track the AI Coach feedback flow
      debugPrint('🤖 [AI Coach] Starting feedback load...');
      debugPrint('🤖 [AI Coach] userId: $userId');
      debugPrint('🤖 [AI Coach] workoutLogId: ${widget.workoutLogId}');
      debugPrint('🤖 [AI Coach] workoutId: ${widget.workout.id}');
      debugPrint('🤖 [AI Coach] exercisesPerformance: ${widget.exercisesPerformance?.length ?? 0} exercises');

      // Only call AI Coach API if we have the required data
      if (userId != null &&
          widget.workoutLogId != null &&
          widget.workout.id != null) {

        // Build exercises list from workout exercises or provided performance data
        final exercisesList = widget.exercisesPerformance ??
            widget.workout.exercises.map((e) => {
              'name': e.name,
              'sets': e.sets ?? 3,
              'reps': e.reps ?? 10,
              'weight_kg': e.weight ?? 0.0,
            }).toList();

        final feedback = await workoutRepo.getAICoachFeedback(
          workoutLogId: widget.workoutLogId!,
          workoutId: widget.workout.id!,
          userId: userId,
          workoutName: widget.workout.name ?? 'Workout',
          workoutType: widget.workout.type ?? 'strength',
          exercises: exercisesList,
          totalTimeSeconds: widget.duration,
          totalRestSeconds: widget.totalRestSeconds ?? 0,
          avgRestSeconds: widget.avgRestSeconds ?? 0.0,
          caloriesBurned: widget.calories,
          totalSets: widget.totalSets ?? exercisesList.length * 3,
          totalReps: widget.totalReps ?? exercisesList.length * 30,
          totalVolumeKg: widget.totalVolumeKg ?? 0.0,
        );

        debugPrint('🤖 [AI Coach] API call completed, feedback: ${feedback != null ? "received (${feedback.length} chars)" : "null"}');
        if (feedback != null && mounted) {
          setState(() {
            _aiSummary = feedback;
            _isLoadingSummary = false;
          });
          return;
        }
      } else {
        debugPrint('🤖 [AI Coach] Skipping API call - missing required data');
        debugPrint('🤖 [AI Coach] userId is null: ${userId == null}');
        debugPrint('🤖 [AI Coach] workoutLogId is null: ${widget.workoutLogId == null}');
        debugPrint('🤖 [AI Coach] workoutId is null: ${widget.workout.id == null}');
      }

      // Fallback to generated summary if API call fails
      debugPrint('🤖 [AI Coach] Using fallback summary');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    } catch (e) {
      debugPrint('Error loading AI Coach feedback: $e');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    }
  }

  String _generateFallbackSummary() {
    final workout = widget.workout;
    final minutes = widget.duration ~/ 60;
    final exercises = workout.exercises.length;

    final summaries = [
      "Great workout! You crushed $exercises exercises in $minutes minutes. Your consistency is building real strength.",
      "Solid session! You're making progress every time you show up. Keep pushing, and the results will follow.",
      "Another workout in the books! Your dedication is paying off. Recovery is just as important - rest well tonight.",
      "Well done! You completed all $exercises exercises. Focus on form next time to maximize gains.",
    ];

    return summaries[DateTime.now().second % summaries.length];
  }

  Future<void> _loadAchievements() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        final achievements = await workoutRepo.getUserAchievements(userId: userId);

        if (achievements.isNotEmpty && mounted) {
          // Detect new PRs from this workout
          final newPRs = _detectNewPRs(achievements);

          setState(() {
            _achievements = achievements;
            _newPRs = newPRs;
            _isLoadingAchievements = false;
          });

          // Play confetti if there are new PRs
          if (newPRs.isNotEmpty) {
            _confettiController.play();
          }
          return;
        }
      }

      setState(() {
        _isLoadingAchievements = false;
      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      setState(() {
        _isLoadingAchievements = false;
      });
    }
  }

  List<Map<String, dynamic>> _detectNewPRs(Map<String, dynamic> achievements) {
    // Compare current workout exercises with personal records
    final prs = achievements['exercise_personal_records'] as List? ?? [];
    final currentExercises = widget.exercisesPerformance ?? [];
    final newPRs = <Map<String, dynamic>>[];

    for (final ex in currentExercises) {
      final exName = ex['name'] ?? ex['exercise_name'] ?? '';
      final exWeight = (ex['weight_kg'] ?? ex['weight'] ?? 0.0).toDouble();

      // Find matching PR
      final matchingPR = prs.firstWhere(
        (pr) => (pr['exercise_name'] ?? '').toString().toLowerCase() == exName.toString().toLowerCase(),
        orElse: () => null,
      );

      if (matchingPR != null) {
        final prWeight = (matchingPR['weight_kg'] ?? 0.0).toDouble();
        // Check if current weight equals PR (meaning this session set the PR)
        if (exWeight >= prWeight && exWeight > 0) {
          newPRs.add({
            'exercise_name': exName,
            'weight_kg': exWeight,
            'previous_pr': prWeight < exWeight ? prWeight : null,
          });
        }
      }
    }

    return newPRs;
  }

  Future<void> _loadExerciseProgress() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final exercises = widget.exercisesPerformance ?? widget.workout.exercises.map((e) => {
        'name': e.name,
      }).toList();

      // Load progress for each exercise
      final progressData = <String, List<Map<String, dynamic>>>{};
      for (final ex in exercises.take(5)) {
        final exName = ex['name'] ?? ex['exercise_name'] ?? '';
        if (exName.isEmpty) continue;

        final history = await workoutRepo.getExerciseProgress(
          userId: userId,
          exerciseName: exName,
        );

        if (history.isNotEmpty) {
          progressData[exName] = history;
          _expandedExercises[exName] = false;
        }
      }

      if (mounted) {
        setState(() {
          _exerciseProgressData = progressData;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise progress: $e');
    }
  }

  /// Load progression suggestions for exercises the user has mastered
  Future<void> _loadProgressionSuggestions() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        setState(() => _isLoadingProgressions = false);
        return;
      }

      debugPrint('Loading progression suggestions for user: $userId');
      final suggestions = await workoutRepo.getProgressionSuggestions(userId: userId);

      if (mounted) {
        setState(() {
          _progressionSuggestions = suggestions;
          _isLoadingProgressions = false;
        });

        if (suggestions.isNotEmpty) {
          debugPrint('Found ${suggestions.length} progression suggestions');
        }
      }
    } catch (e) {
      debugPrint('Error loading progression suggestions: $e');
      if (mounted) {
        setState(() => _isLoadingProgressions = false);
      }
    }
  }

  /// Sync workout with personal weekly goals
  ///
  /// After workout completion, automatically updates any weekly_volume goals
  /// that match exercises from this workout.
  Future<void> _syncWorkoutWithGoals() async {
    // Only sync if we have exercise performance data
    if (widget.exercisesPerformance == null || widget.exercisesPerformance!.isEmpty) {
      debugPrint('[GoalSync] No exercise performance data, skipping goal sync');
      return;
    }

    setState(() => _isLoadingGoalSync = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        debugPrint('[GoalSync] No user ID, skipping goal sync');
        setState(() => _isLoadingGoalSync = false);
        return;
      }

      final goalsService = PersonalGoalsService(apiClient);

      // Convert exercise performance data to the format expected by the service
      final exercises = widget.exercisesPerformance!.map((ex) {
        final name = ex['name'] ?? ex['exercise_name'] ?? '';
        final sets = ex['sets_completed'] ?? ex['sets'] ?? 0;
        final reps = ex['reps'] ?? ex['total_reps'] ?? 0;

        // Calculate total reps: sets * reps (if reps is per set) or use total_reps directly
        int totalReps = 0;
        if (ex['total_reps'] != null) {
          totalReps = ex['total_reps'] as int;
        } else if (sets > 0 && reps > 0) {
          totalReps = (sets as int) * (reps as int);
        }

        return ExercisePerformanceData(
          exerciseName: name as String,
          totalReps: totalReps,
          totalSets: sets as int,
          maxRepsInSet: reps as int,
        );
      }).toList();

      debugPrint('[GoalSync] Syncing ${exercises.length} exercises with goals');

      final result = await goalsService.syncWorkoutWithGoals(
        userId: userId,
        workoutLogId: widget.workoutLogId,
        exercises: exercises,
      );

      if (mounted) {
        setState(() {
          _goalSyncResult = result;
          _isLoadingGoalSync = false;
        });

        // Show notification if goals were updated
        if (result.hasUpdates) {
          debugPrint('[GoalSync] Updated ${result.totalGoalsUpdated} goals');

          // Show a snackbar with the result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    result.hasNewPrs ? Icons.emoji_events : Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: result.hasNewPrs ? AppColors.orange : AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View Goals',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/goals');
                },
              ),
            ),
          );

          // Play confetti if there are new PRs from goal sync
          if (result.hasNewPrs) {
            _confettiController.play();
          }
        } else {
          debugPrint('[GoalSync] No matching goals found');
        }
      }
    } catch (e) {
      debugPrint('[GoalSync] Error syncing workout with goals: $e');
      if (mounted) {
        setState(() => _isLoadingGoalSync = false);
      }
      // Don't show error to user - this is a non-critical feature
    }
  }

  /// Handle accepting a progression suggestion
  Future<void> _acceptProgression(ProgressionSuggestion suggestion) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final success = await workoutRepo.respondToProgressionSuggestion(
        userId: userId,
        exerciseName: suggestion.exerciseName,
        newExerciseName: suggestion.suggestedNextVariant,
        accepted: true,
      );

      if (success && mounted) {
        // Remove from suggestions list
        setState(() {
          _progressionSuggestions.removeWhere(
            (s) => s.exerciseName == suggestion.exerciseName
          );
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Great! ${suggestion.suggestedNextVariant} will be included in future workouts.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Play confetti for progression!
        _confettiController.play();
      }
    } catch (e) {
      debugPrint('Error accepting progression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle declining a progression suggestion
  Future<void> _declineProgression(ProgressionSuggestion suggestion, [String? reason]) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      await workoutRepo.respondToProgressionSuggestion(
        userId: userId,
        exerciseName: suggestion.exerciseName,
        newExerciseName: suggestion.suggestedNextVariant,
        accepted: false,
        declineReason: reason,
      );

      if (mounted) {
        // Remove from suggestions list
        setState(() {
          _progressionSuggestions.removeWhere(
            (s) => s.exerciseName == suggestion.exerciseName
          );
        });
      }
    } catch (e) {
      debugPrint('Error declining progression: $e');
    }
  }

  /// Show the share workout bottom sheet
  Future<void> _showShareSheet() async {
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareWorkoutSheet(
        workoutName: widget.workout.name ?? 'Workout',
        workoutLogId: widget.workoutLogId ?? '',
        durationSeconds: widget.duration,
        calories: widget.calories,
        totalVolumeKg: widget.totalVolumeKg,
        totalSets: widget.totalSets,
        totalReps: widget.totalReps,
        exercisesCount: widget.workout.exercises.length,
        newPRs: _newPRs.isNotEmpty
            ? _newPRs.map((pr) => {
                'exercise': pr['exercise_name'],
                'weight_kg': pr['weight_kg'],
                'pr_type': 'weight',
                'improvement': pr['previous_pr'] != null
                    ? (pr['weight_kg'] as double) - (pr['previous_pr'] as double)
                    : null,
              }).toList()
            : null,
        achievements: _achievements != null
            ? (_achievements!['new_achievements'] as List<dynamic>?)
                ?.map((a) => Map<String, dynamic>.from(a as Map))
                .toList()
            : null,
        currentStreak: _achievements?['streak_days'] as int?,
        totalWorkouts: _achievements?['total_workouts'] as int?,
      ),
    );
  }

  /// Handle "Do More" - extend the workout with additional AI-generated exercises
  Future<void> _extendWorkout() async {
    setState(() => _isExtendingWorkout = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null || widget.workout.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to extend workout'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isExtendingWorkout = false);
        return;
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final extendedWorkout = await workoutRepo.extendWorkout(
        workoutId: widget.workout.id!,
        userId: userId,
        additionalExercises: 3,
        additionalDurationMinutes: 15,
        focusSameMuscles: true,
      );

      setState(() => _isExtendingWorkout = false);

      if (extendedWorkout != null) {
        // Navigate to the active workout screen with the extended workout
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${extendedWorkout.exercises.length - widget.workout.exercises.length} more exercises!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to active workout with the extended workout
          context.go('/workout/active', extra: extendedWorkout);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to extend workout. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isExtendingWorkout = false);
      debugPrint('❌ Error extending workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate your workout'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null && widget.workout.id != null) {
        // Build exercise feedback list
        final exerciseFeedbackList = <Map<String, dynamic>>[];
        for (int i = 0; i < widget.workout.exercises.length; i++) {
          final exercise = widget.workout.exercises[i];
          if (_exerciseRatings.containsKey(i)) {
            exerciseFeedbackList.add({
              'user_id': userId,
              'workout_id': widget.workout.id,
              'exercise_name': exercise.name,
              'exercise_index': i,
              'rating': _exerciseRatings[i],
              'difficulty_felt': _exerciseDifficulties[i] ?? 'just_right',
              'would_do_again': true,
            });
          }
        }

        // Submit workout feedback to backend
        debugPrint('[Feedback] Submitting workout feedback: rating=$_rating, difficulty=$_difficulty');
        await apiClient.post(
          '/v1/feedback/workout/${widget.workout.id}',
          data: {
            'user_id': userId,
            'workout_id': widget.workout.id,
            'overall_rating': _rating,
            'overall_difficulty': _difficulty,
            'energy_level': _getEnergyLevel(),
            'would_recommend': _rating >= 3,
            'exercise_feedback': exerciseFeedbackList,
          },
        );

        // Submit subjective feedback (mood, energy, confidence) if provided
        if (_moodAfter != null) {
          debugPrint('[Subjective Feedback] Submitting: mood=$_moodAfter, energy=$_energyAfter, stronger=$_feelingStronger');
          try {
            final notifier = ref.read(subjectiveFeedbackProvider.notifier);
            await notifier.createPostCheckin(
              workoutId: widget.workout.id!,
              moodAfter: _moodAfter!,
              energyAfter: _energyAfter,
              confidenceLevel: _confidenceLevel,
              feelingStronger: _feelingStronger,
            );
            debugPrint('[Subjective Feedback] Successfully submitted');
          } catch (e) {
            debugPrint('[Subjective Feedback] Error (non-blocking): $e');
            // Non-blocking - don't fail the whole submission
          }
        }
        debugPrint('✅ [Feedback] Workout feedback submitted successfully');
      }

      // Refresh workouts and invalidate provider to force UI update
      await ref.read(workoutsProvider.notifier).refresh();
      ref.invalidate(workoutsProvider);

      // Refresh fitness scores (they are recalculated on the backend after workout completion)
      ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ [Feedback] Failed to submit feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Convert difficulty to energy level for backend
  String _getEnergyLevel() {
    switch (_difficulty) {
      case 'too_easy':
        return 'energized';
      case 'just_right':
        return 'good';
      case 'too_hard':
        return 'exhausted';
      default:
        return 'good';
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins min ${secs > 0 ? '$secs sec' : ''}';
    }
    return '$secs sec';
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - needs improvement';
      case 2:
        return 'Fair - could be better';
      case 3:
        return 'Good - solid workout';
      case 4:
        return 'Great - feeling strong!';
      case 5:
        return 'Excellent - crushed it! 💪';
      default:
        return 'Tap to rate your workout';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.3),
                        AppColors.cyan.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const LottieSuccess(
                    size: 64,
                    color: AppColors.success,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Workout Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  widget.workout.name ?? 'Workout',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Stats Grid - Row 1
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer,
                        value: _formatDuration(widget.duration),
                        label: 'Duration',
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.fitness_center,
                        value: '${widget.workout.exercises.length}',
                        label: 'Exercises',
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.local_fire_department,
                        value: '${widget.calories}',
                        label: 'Calories',
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // Stats Grid - Row 2 (Total Weight)
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.scale,
                        value: '${(widget.totalVolumeKg ?? 0).toStringAsFixed(0)} kg',
                        label: 'Total Weight',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.repeat,
                        value: '${widget.totalSets ?? 0}',
                        label: 'Sets',
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.format_list_numbered,
                        value: '${widget.totalReps ?? 0}',
                        label: 'Reps',
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // AI Summary
                Builder(
                  builder: (context) {
                    final isDarkAI = Theme.of(context).brightness == Brightness.dark;
                    final elevatedAI = isDarkAI ? AppColors.elevated : AppColorsLight.elevated;
                    return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: elevatedAI,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Coach Feedback',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingSummary
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: LottieLoading(
                                  size: 48,
                                  color: AppColors.cyan,
                                ),
                              ),
                            )
                          : Text(
                              _aiSummary ?? 'Great workout! Keep up the momentum.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                    ],
                  ),
                );
                  },
                ).animate().fadeIn(delay: 500.ms),

                // Share Workout Button
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showShareSheet,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Share Workout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ).animate().fadeIn(delay: 520.ms),

                // Post-Workout Subjective Feedback Section
                const SizedBox(height: 24),
                _buildSubjectiveFeedbackSection(),

                // Progression Suggestions Section
                if (_progressionSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildProgressionSuggestionsSection(),
                ],

                // New PRs / Achievements Section
                if (_newPRs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNewPRsSection(),
                ],

                // Performance Comparison Section - Improvements/Setbacks
                if (widget.performanceComparison != null) ...[
                  const SizedBox(height: 24),
                  _buildPerformanceComparisonSection(),
                ],

                // Exercise Progress Section (Minimizable graphs)
                if (_exerciseProgressData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildExerciseProgressSection(),
                ],

                const SizedBox(height: 32),

                // Feedback importance banner
                Builder(
                  builder: (context) {
                    final isDarkBanner = Theme.of(context).brightness == Brightness.dark;
                    final elevatedBanner = isDarkBanner ? AppColors.elevated : AppColorsLight.elevated;
                    final textSecondaryBanner = isDarkBanner ? AppColors.textSecondary : AppColorsLight.textSecondary;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: elevatedBanner,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: AppColors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your feedback matters!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.purple,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ratings help the AI personalize future workouts to better match your preferences and abilities.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryBanner,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 580.ms),

                const SizedBox(height: 24),

                // Rating Section
                Text(
                  'How was your workout?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: starIndex <= _rating
                              ? AppColors.orange
                              : AppColors.textMuted,
                        ),
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 600.ms),

                // Rating label
                const SizedBox(height: 8),
                Text(
                  _getRatingLabel(_rating),
                  style: TextStyle(
                    fontSize: 14,
                    color: _rating > 0 ? AppColors.orange : AppColors.textMuted,
                    fontWeight: _rating > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ).animate().fadeIn(delay: 650.ms),

                const SizedBox(height: 24),

                // Difficulty Feedback
                Text(
                  'How was the difficulty?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _DifficultyOption(
                      label: 'Too Easy',
                      icon: Icons.sentiment_very_satisfied,
                      isSelected: _difficulty == 'too_easy',
                      onTap: () => setState(() => _difficulty = 'too_easy'),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _DifficultyOption(
                      label: 'Just Right',
                      icon: Icons.sentiment_satisfied,
                      isSelected: _difficulty == 'just_right',
                      onTap: () => setState(() => _difficulty = 'just_right'),
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 12),
                    _DifficultyOption(
                      label: 'Too Hard',
                      icon: Icons.sentiment_dissatisfied,
                      isSelected: _difficulty == 'too_hard',
                      onTap: () => setState(() => _difficulty = 'too_hard'),
                      color: AppColors.error,
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 24),

                // Per-Exercise Feedback Section (expandable)
                _buildExerciseFeedbackSection(),

                const SizedBox(height: 24),

                // "Do More" Button - Extend Workout with AI-generated exercises
                // Addresses complaint: "Those few little baby exercises weren't enough"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExtendingWorkout ? null : _extendWorkout,
                    icon: _isExtendingWorkout
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: LottieLoading(size: 20, useDots: true),
                          )
                        : const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      _isExtendingWorkout ? 'Generating...' : 'Do More',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(delay: 720.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // Explanation text for "Do More"
                Text(
                  'Not enough? AI will add 3 more exercises',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 730.ms),

                const SizedBox(height: 24),

                // Challenge Friends Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showChallengeFriendsDialog,
                    icon: const Icon(Icons.emoji_events, size: 20),
                    label: const Text(
                      'Challenge Friends',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.orange,
                      side: BorderSide(color: AppColors.orange.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: LottieLoading(
                              size: 24,
                              useDots: true,
                            ),
                          )
                        : const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Skip Feedback'),
                ),
              ],
            ),
          ),
        ),
          ),
          // Confetti overlay for achievements
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.success,
                AppColors.cyan,
                AppColors.purple,
                AppColors.orange,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the post-workout subjective feedback section
  /// Allows users to track mood, energy, and confidence after workout
  Widget _buildSubjectiveFeedbackSection() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withOpacity(0.1),
                AppColors.purple.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showSubjectiveFeedback = !_showSubjectiveFeedback;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.mood,
                          size: 20,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How do you feel now?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                            Text(
                              'Track your mood to see your progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showSubjectiveFeedback ? Icons.expand_less : Icons.expand_more,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content
              if (_showSubjectiveFeedback) ...[
                Divider(height: 1, color: cardBorder.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood after workout
                      Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final isSelected = _moodAfter == level;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _moodAfter = level;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? level.moodColor.withOpacity(0.2)
                                    : elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? level.moodColor : cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level.moodEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_moodAfter != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _moodAfter!.moodLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _moodAfter!.moodColor,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Energy after workout
                      Text(
                        'Energy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final isSelected = _energyAfter == level;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _energyAfter = level;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange.withOpacity(0.2)
                                    : elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.orange : cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level.energyEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_energyAfter != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _energyAfter!.energyLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Feeling stronger toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _feelingStronger = !_feelingStronger;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _feelingStronger
                                ? AppColors.success.withOpacity(0.15)
                                : elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _feelingStronger
                                  ? AppColors.success
                                  : cardBorder,
                              width: _feelingStronger ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _feelingStronger
                                      ? AppColors.success
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _feelingStronger
                                        ? AppColors.success
                                        : textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: _feelingStronger
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Feeling stronger today!',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _feelingStronger
                                            ? AppColors.success
                                            : textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Notice improvements in your strength or endurance?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_feelingStronger)
                                const Text(
                                  '\u{1F4AA}',
                                  style: TextStyle(fontSize: 24),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 530.ms);
  }

  /// Build the exercise progression suggestions section
  /// Shows when user has exercises ready to progress to harder variants
  Widget _buildProgressionSuggestionsSection() {
    return Builder(
      builder: (context) {
        final isDarkProg = Theme.of(context).brightness == Brightness.dark;
        final elevatedProg = isDarkProg ? AppColors.elevated : AppColorsLight.elevated;
        final textSecondaryProg = isDarkProg ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withOpacity(0.15),
                AppColors.cyan.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 20,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'READY TO LEVEL UP!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve mastered these exercises. Try a harder variant?',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondaryProg,
                ),
              ),
              const SizedBox(height: 16),
              ..._progressionSuggestions.map((suggestion) => _buildProgressionCard(suggestion)),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 525.ms).slideY(begin: 0.1);
  }

  /// Build individual progression suggestion card
  Widget _buildProgressionCard(ProgressionSuggestion suggestion) {
    return Builder(
      builder: (context) {
        final isDarkCard = Theme.of(context).brightness == Brightness.dark;
        final elevatedCard = isDarkCard ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimaryCard = isDarkCard ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondaryCard = isDarkCard ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise progression path
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.exerciseName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimaryCard,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.purple.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                suggestion.suggestedNextVariant,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Difficulty badge
                  if (suggestion.difficultyIncrease != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        suggestion.difficultyIncreaseDescription,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Mastery info
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Marked as "too easy" ${suggestion.consecutiveEasySessions}x in a row',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineProgression(suggestion, 'not_ready'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondaryCard,
                        side: BorderSide(color: textSecondaryCard.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Not Yet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptProgression(suggestion),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: const Text('Level Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewPRsSection() {
    return Builder(
      builder: (context) {
        final isDarkPR = Theme.of(context).brightness == Brightness.dark;
        final textPrimaryPR = isDarkPR ? AppColors.textPrimary : AppColorsLight.textPrimary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withOpacity(0.2),
                AppColors.orange.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'NEW PERSONAL RECORDS!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._newPRs.map((pr) {
                final celebrationMessage = pr['celebration_message'] as String?;
                final improvementKg = pr['improvement_kg'] as num?;
                final improvementPercent = pr['improvement_percent'] as num?;
                final estimated1rm = pr['estimated_1rm_kg'] as num?;
                final reps = pr['reps'] as int?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${pr['exercise_name']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimaryPR,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(pr['weight_kg'] as num).toStringAsFixed(1)} kg${reps != null ? ' x $reps' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                  fontSize: 16,
                                ),
                              ),
                              if (estimated1rm != null)
                                Text(
                                  '1RM: ${estimated1rm.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimaryPR.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Show improvement if available
                      if (improvementKg != null && improvementKg > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 26),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${improvementKg.toStringAsFixed(1)} kg${improvementPercent != null ? ' (+${improvementPercent.toStringAsFixed(1)}%)' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Show AI celebration message if available
                      if (celebrationMessage != null && celebrationMessage.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: Text(
                            celebrationMessage,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: textPrimaryPR.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 550.ms).scale(
      begin: const Offset(0.9, 0.9),
      duration: 400.ms,
      curve: Curves.elasticOut,
    );
  }

  /// Build the performance comparison section showing improvements/setbacks
  Widget _buildPerformanceComparisonSection() {
    final comparison = widget.performanceComparison;
    if (comparison == null) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

        final hasImprovements = comparison.improvedCount > 0;
        final hasDeclines = comparison.declinedCount > 0;

        // Choose accent color based on overall performance
        Color accentColor;
        IconData headerIcon;
        String headerText;

        if (hasImprovements && !hasDeclines) {
          accentColor = AppColors.success;
          headerIcon = Icons.trending_up;
          headerText = 'ALL EXERCISES IMPROVED!';
        } else if (hasDeclines && !hasImprovements) {
          accentColor = AppColors.orange;
          headerIcon = Icons.trending_down;
          headerText = 'PERFORMANCE COMPARED TO LAST SESSION';
        } else if (hasImprovements && hasDeclines) {
          accentColor = AppColors.cyan;
          headerIcon = Icons.compare_arrows;
          headerText = 'PERFORMANCE COMPARISON';
        } else {
          accentColor = AppColors.cyan;
          headerIcon = Icons.analytics;
          headerText = 'PERFORMANCE MAINTAINED';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        headerIcon,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (comparison.workoutComparison.hasPrevious)
                            Text(
                              'vs last ${comparison.workoutComparison.previousPerformedAt != null ? _formatRelativeDate(comparison.workoutComparison.previousPerformedAt!) : 'session'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Summary badges
                    Row(
                      children: [
                        if (comparison.improvedCount > 0)
                          _buildCountBadge(
                            count: comparison.improvedCount,
                            icon: Icons.arrow_upward,
                            color: AppColors.success,
                          ),
                        if (comparison.declinedCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildCountBadge(
                            count: comparison.declinedCount,
                            icon: Icons.arrow_downward,
                            color: AppColors.error,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: cardBorder),

              // Exercise comparisons
              ...comparison.exerciseComparisons.map((exComp) {
                return _buildExerciseComparisonRow(exComp, textPrimary, textSecondary);
              }),

              // Overall workout comparison (if has previous)
              if (comparison.workoutComparison.hasPrevious) ...[
                Divider(height: 1, color: cardBorder),
                _buildWorkoutTotalComparison(
                  comparison.workoutComparison,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 560.ms);
      },
    );
  }

  Widget _buildCountBadge({
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseComparisonRow(
    ExerciseComparisonInfo exComp,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Determine status icon and color
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (exComp.status) {
      case 'improved':
        statusIcon = Icons.trending_up;
        statusColor = AppColors.success;
        statusText = exComp.formattedPercentDiff;
        break;
      case 'declined':
        statusIcon = Icons.trending_down;
        statusColor = AppColors.error;
        statusText = exComp.formattedPercentDiff;
        break;
      case 'maintained':
        statusIcon = Icons.remove;
        statusColor = AppColors.cyan;
        statusText = 'Same';
        break;
      default: // first_time
        statusIcon = Icons.fiber_new;
        statusColor = AppColors.purple;
        statusText = 'New';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 14, color: statusColor),
          ),
          const SizedBox(width: 12),

          // Exercise name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exComp.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (exComp.hasPrevious) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.currentMaxWeightKg != null
                        ? '${exComp.currentMaxWeightKg!.toStringAsFixed(1)} kg x ${exComp.currentReps} reps'
                        : '${exComp.currentSets} sets, ${exComp.currentReps} reps',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Difference display
          if (exComp.hasPrevious)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (exComp.weightDiffKg != null && exComp.weightDiffKg != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.formattedWeightDiff,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                ],
                if (exComp.timeDiffSeconds != null && exComp.timeDiffSeconds != 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    exComp.formattedTimeDiff,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTotalComparison(
    WorkoutComparisonInfo workoutComp,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL WORKOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Volume comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Volume',
                  current: '${workoutComp.currentTotalVolumeKg.toStringAsFixed(0)} kg',
                  diff: workoutComp.formattedVolumeDiff,
                  diffPercent: workoutComp.volumeDiffPercent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Duration comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Duration',
                  current: _formatDuration(workoutComp.currentDurationSeconds ~/ 60),
                  diff: workoutComp.formattedDurationDiff,
                  diffPercent: workoutComp.durationDiffPercent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // Reps comparison
              Expanded(
                child: _buildComparisonStat(
                  label: 'Total Reps',
                  current: '${workoutComp.currentTotalReps}',
                  diff: workoutComp.previousTotalReps != null
                      ? '${workoutComp.currentTotalReps - workoutComp.previousTotalReps! >= 0 ? '+' : ''}${workoutComp.currentTotalReps - workoutComp.previousTotalReps!}'
                      : null,
                  diffPercent: null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStat({
    required String label,
    required String current,
    String? diff,
    double? diffPercent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color? diffColor;
    if (diffPercent != null) {
      if (diffPercent > 1) {
        diffColor = AppColors.success;
      } else if (diffPercent < -1) {
        diffColor = AppColors.error;
      } else {
        diffColor = AppColors.cyan;
      }
    } else if (diff != null && diff.isNotEmpty) {
      if (diff.startsWith('+')) {
        diffColor = AppColors.success;
      } else if (diff.startsWith('-')) {
        diffColor = AppColors.error;
      } else {
        diffColor = AppColors.cyan;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          current,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        if (diff != null && diff.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            diff,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: diffColor,
            ),
          ),
        ],
      ],
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 14) {
      return 'last week';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7} weeks ago';
    } else {
      return '${diff.inDays ~/ 30} months ago';
    }
  }

  /// Build the per-exercise feedback section (expandable)
  Widget _buildExerciseFeedbackSection() {
    return Builder(
      builder: (context) {
        final isDarkFeedback = Theme.of(context).brightness == Brightness.dark;
        final elevatedFeedback = isDarkFeedback ? AppColors.elevated : AppColorsLight.elevated;
        final cardBorderFeedback = isDarkFeedback ? AppColors.cardBorder : AppColorsLight.cardBorder;
        final textSecondaryFeedback = isDarkFeedback ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final textPrimaryFeedback = isDarkFeedback ? AppColors.textPrimary : AppColorsLight.textPrimary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevatedFeedback,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderFeedback),
          ),
          child: Column(
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showExerciseFeedback = !_showExerciseFeedback;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rate Individual Exercises',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange,
                              ),
                            ),
                            Text(
                              _exerciseRatings.isEmpty
                                  ? 'Optional - helps AI adapt workouts'
                                  : '${_exerciseRatings.length} of ${widget.workout.exercises.length} rated',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryFeedback,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showExerciseFeedback ? Icons.expand_less : Icons.expand_more,
                        color: textSecondaryFeedback,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content - exercise list
              if (_showExerciseFeedback) ...[
                Divider(height: 1, color: cardBorderFeedback),
                ...widget.workout.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  final rating = _exerciseRatings[index] ?? 0;
                  final difficulty = _exerciseDifficulties[index] ?? 'just_right';

                  return _buildExerciseRatingTile(
                    index: index,
                    exerciseName: exercise.name,
                    rating: rating,
                    difficulty: difficulty,
                    textPrimary: textPrimaryFeedback,
                    textSecondary: textSecondaryFeedback,
                    cardBorder: cardBorderFeedback,
                  );
                }),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 720.ms);
  }

  /// Build a single exercise rating tile
  Widget _buildExerciseRatingTile({
    required int index,
    required String exerciseName,
    required int rating,
    required String difficulty,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name
              Text(
                exerciseName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Star rating row
              Row(
                children: [
                  // Stars
                  ...List.generate(5, (starIndex) {
                    final starValue = starIndex + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _exerciseRatings[index] = starValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          size: 24,
                          color: starValue <= rating
                              ? AppColors.orange
                              : textSecondary,
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Quick difficulty buttons
                  _MiniDifficultyButton(
                    label: 'Easy',
                    isSelected: difficulty == 'too_easy',
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'too_easy';
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _MiniDifficultyButton(
                    label: 'OK',
                    isSelected: difficulty == 'just_right',
                    color: AppColors.cyan,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'just_right';
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _MiniDifficultyButton(
                    label: 'Hard',
                    isSelected: difficulty == 'too_hard',
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _exerciseDifficulties[index] = 'too_hard';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < widget.workout.exercises.length - 1)
          Divider(height: 1, color: cardBorder),
      ],
    );
  }

  Widget _buildExerciseProgressSection() {
    return Builder(
      builder: (context) {
        final isDarkProgress = Theme.of(context).brightness == Brightness.dark;
        final elevatedProgress = isDarkProgress ? AppColors.elevated : AppColorsLight.elevated;
        final cardBorderProgress = isDarkProgress ? AppColors.cardBorder : AppColorsLight.cardBorder;
        final textSecondaryProgress = isDarkProgress ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevatedProgress,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderProgress),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with expand/collapse toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showExerciseProgress = !_showExerciseProgress;
                  });
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          size: 16,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Exercise Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                      Icon(
                        _showExerciseProgress ? Icons.expand_less : Icons.expand_more,
                        color: textSecondaryProgress,
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content
              if (_showExerciseProgress) ...[
                Divider(height: 1, color: cardBorderProgress),
                ...(_exerciseProgressData.entries.map((entry) => _buildExerciseProgressTile(
                  entry.key,
                  entry.value,
                ))),
              ],
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildExerciseProgressTile(String exerciseName, List<Map<String, dynamic>> history) {
    final isExpanded = _expandedExercises[exerciseName] ?? false;
    final maxWeight = history.fold<double>(0, (max, item) =>
      (item['weight_kg'] ?? 0.0).toDouble() > max ? (item['weight_kg'] ?? 0.0).toDouble() : max
    );

    return Builder(
      builder: (context) {
        final isDarkTile = Theme.of(context).brightness == Brightness.dark;
        final textPrimaryTile = isDarkTile ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondaryTile = isDarkTile ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final textMutedTile = isDarkTile ? AppColors.textMuted : AppColorsLight.textMuted;
        final cardBorderTile = isDarkTile ? AppColors.cardBorder : AppColorsLight.cardBorder;

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedExercises[exerciseName] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textPrimaryTile,
                        ),
                      ),
                    ),
                    Text(
                      'PR: ${maxWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryTile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: textMutedTile,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded && history.isNotEmpty) ...[
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSimpleProgressChart(history, maxWeight),
              ),
            ],
            Divider(height: 1, color: cardBorderTile),
          ],
        );
      },
    );
  }

  Widget _buildSimpleProgressChart(List<Map<String, dynamic>> history, double maxWeight) {
    final sortedHistory = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    return Builder(
      builder: (context) {
        final isDarkChart = Theme.of(context).brightness == Brightness.dark;
        final textMutedChart = isDarkChart ? AppColors.textMuted : AppColorsLight.textMuted;

        if (sortedHistory.isEmpty) {
          return Center(child: Text('No data', style: TextStyle(color: textMutedChart)));
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: sortedHistory.take(7).map((item) {
            final weight = (item['weight_kg'] ?? 0.0).toDouble();
            final heightPercent = maxWeight > 0 ? (weight / maxWeight) : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${weight.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 9, color: textMutedChart),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (60 * heightPercent).toDouble(),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Tile
// ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Difficulty Option
// ─────────────────────────────────────────────────────────────────

class _DifficultyOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _DifficultyOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : elevatedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : textMuted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mini Difficulty Button (for per-exercise rating)
// ─────────────────────────────────────────────────────────────────

class _MiniDifficultyButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MiniDifficultyButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : elevatedColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }
}
