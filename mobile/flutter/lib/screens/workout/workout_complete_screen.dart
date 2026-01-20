import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../widgets/lottie_animations.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/personal_goals_service.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/subjective_feedback_provider.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../data/models/subjective_feedback.dart';
import '../challenges/widgets/challenge_complete_dialog.dart';
import '../challenges/widgets/challenge_friends_dialog.dart';
import 'widgets/share_workout_sheet.dart';
import 'widgets/trophies_earned_sheet.dart';
import 'widgets/trophy_celebration_overlay.dart';
import '../../widgets/heart_rate_chart.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/health_service.dart';
import '../../core/theme/accent_color_provider.dart';

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final int duration;
  final int calories;
  // Additional workout performance data for AI Coach feedback
  final String? workoutLogId;
  final List<Map<String, dynamic>>? exercisesPerformance;
  final List<Map<String, dynamic>>? plannedExercises; // NEW: For skip detection
  final Map<int, int>? exerciseTimeSeconds; // NEW: Per-exercise timing
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

  // Heart rate data from watch during workout
  final List<HeartRateReadingData>? heartRateReadings;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;

  const WorkoutCompleteScreen({
    super.key,
    required this.workout,
    required this.duration,
    required this.calories,
    this.workoutLogId,
    this.exercisesPerformance,
    this.plannedExercises,
    this.exerciseTimeSeconds,
    this.totalRestSeconds,
    this.avgRestSeconds,
    this.totalSets,
    this.totalReps,
    this.totalVolumeKg,
    this.challengeId,
    this.challengeData,
    this.personalRecords,
    this.performanceComparison,
    this.heartRateReadings,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
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
  bool _isAiReviewExpanded = false;

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

  // Total workout count for milestone detection
  int _totalWorkoutCount = 0;

  // Milestone thresholds
  static const List<int> _milestoneThresholds = [5, 10, 25, 50, 100, 150, 200, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    debugPrint('🏁 [Complete] Workout complete screen loaded: ${widget.workout.id}');
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Play workout completion sound
    Future.microtask(() {
      ref.read(soundPreferencesProvider.notifier).playWorkoutCompletion();
    });

    _loadAICoachFeedback();

    // Load total workout count for milestone detection
    _loadTotalWorkoutCount();

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
      // Show full-screen trophy celebration overlay
      Future.microtask(() {
        _showTrophyCelebration();
      });
      debugPrint('🏆 [Complete] Using ${_newPRs.length} PRs from API - showing celebration');
    } else {
      // Fall back to client-side detection
      _loadAchievements();
    }

    // Skip loading these for simplified single-screen layout
    // _loadExerciseProgress();
    // _loadProgressionSuggestions();
    _syncWorkoutWithGoals();

    // Complete challenge if this workout was from a challenge
    if (widget.challengeId != null && widget.workoutLogId != null) {
      _completeChallenge();
    }
  }

  /// Load total workout count for milestone detection
  Future<void> _loadTotalWorkoutCount() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      // Fetch user stats to get total workout count
      final response = await apiClient.get('/users/$userId/stats');
      if (response.statusCode == 200 && response.data != null) {
        final stats = response.data as Map<String, dynamic>;
        setState(() {
          _totalWorkoutCount = (stats['total_workouts'] as int?) ?? 0;
        });
        debugPrint('📊 [Complete] Total workouts: $_totalWorkoutCount');
      }
    } catch (e) {
      debugPrint('❌ [Complete] Error loading workout count: $e');
    }
  }

  /// Check if current workout count is a milestone
  int? _getWorkoutMilestone() {
    if (_totalWorkoutCount <= 0) return null;
    if (_milestoneThresholds.contains(_totalWorkoutCount)) {
      return _totalWorkoutCount;
    }
    return null;
  }

  /// Get the next milestone for AI feedback
  Map<String, dynamic>? _getNextMilestone() {
    if (_totalWorkoutCount <= 0) return null;
    for (final m in _milestoneThresholds) {
      if (_totalWorkoutCount < m) {
        return {
          'type': 'workout_count',
          'value': m,
          'remaining': m - _totalWorkoutCount,
        };
      }
    }
    return null;
  }

  /// Show full-screen trophy celebration overlay
  void _showTrophyCelebration() {
    // Get new achievements from achievements map
    final newAchievements = (_achievements?['new_achievements'] as List?)
        ?.map((a) => Map<String, dynamic>.from(a as Map))
        .toList();

    // Check for milestone
    final milestone = _getWorkoutMilestone();

    // Get current streak
    final currentStreak = _achievements?['current_streak'] as int?;

    // Only show celebration if there are trophies to celebrate
    final hasTrophies = _newPRs.isNotEmpty ||
        (newAchievements != null && newAchievements.isNotEmpty) ||
        milestone != null;

    if (!hasTrophies || !mounted) return;

    debugPrint('🏆 [Complete] Showing trophy celebration: ${_newPRs.length} PRs, ${newAchievements?.length ?? 0} achievements, milestone: $milestone');

    // Play confetti on the underlying screen
    _confettiController.play();

    // Show full-screen celebration overlay
    showTrophyCelebration(
      context: context,
      newPRs: _newPRs,
      newAchievements: newAchievements,
      workoutMilestone: milestone,
      currentStreak: currentStreak,
    );
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
      debugPrint('🤖 [AI Coach] plannedExercises: ${widget.plannedExercises?.length ?? 0} exercises');
      debugPrint('🤖 [AI Coach] totalSets: ${widget.totalSets}, totalReps: ${widget.totalReps}');

      // Try to call AI Coach API if we have minimum required data (userId and workoutId)
      // workoutLogId is optional - we can still generate feedback without it
      if (userId != null && widget.workout.id != null) {
        // Build exercises list from workout exercises or provided performance data
        final exercisesList = widget.exercisesPerformance ??
            widget.workout.exercises.map((e) => {
              'name': e.name,
              'sets': e.sets ?? 3,
              'reps': e.reps ?? 10,
              'weight_kg': e.weight ?? 0.0,
            }).toList();

        // Build planned exercises list for skip detection (from widget or from workout definition)
        final plannedExercisesList = widget.plannedExercises ??
            widget.workout.exercises.map((e) => {
              'name': e.name,
              'target_sets': e.sets ?? 3,
              'target_reps': e.reps ?? 10,
              'target_weight_kg': e.weight ?? 0.0,
            }).toList();

        // Get AI settings for coach personality
        final aiSettings = ref.read(aiSettingsProvider);

        // Use actual workoutLogId if available, otherwise use a temp ID (won't be indexed)
        final effectiveWorkoutLogId = widget.workoutLogId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

        final feedback = await workoutRepo.getAICoachFeedback(
          workoutLogId: effectiveWorkoutLogId,
          workoutId: widget.workout.id!,
          userId: userId,
          workoutName: widget.workout.name ?? 'Workout',
          workoutType: widget.workout.type ?? 'strength',
          exercises: exercisesList,
          totalTimeSeconds: widget.duration,
          totalRestSeconds: widget.totalRestSeconds ?? 0,
          avgRestSeconds: widget.avgRestSeconds ?? 0.0,
          caloriesBurned: widget.calories,
          totalSets: widget.totalSets ?? 0, // Use actual value, don't fake it
          totalReps: widget.totalReps ?? 0, // Use actual value, don't fake it
          totalVolumeKg: widget.totalVolumeKg ?? 0.0,
          // Pass coach personality settings
          coachName: aiSettings.coachName,
          coachingStyle: aiSettings.coachingStyle,
          communicationTone: aiSettings.communicationTone,
          encouragementLevel: aiSettings.encouragementLevel,
          // Pass enhanced context for skip detection and timing
          plannedExercises: plannedExercisesList,
          exerciseTimeSeconds: widget.exerciseTimeSeconds,
          // Pass trophy/achievement context for personalized feedback
          earnedPRs: _newPRs.isNotEmpty ? _newPRs : null,
          earnedAchievements: (_achievements?['new_achievements'] as List?)
              ?.map((a) => Map<String, dynamic>.from(a as Map))
              .toList(),
          totalWorkoutsCompleted: _totalWorkoutCount > 0 ? _totalWorkoutCount : null,
          nextMilestone: _getNextMilestone(),
        );

        debugPrint('🤖 [AI Coach] API call completed, feedback: ${feedback != null ? "received (${feedback.length} chars)" : "null"}');
        if (feedback != null && mounted) {
          setState(() {
            _aiSummary = feedback;
            _isLoadingSummary = false;
          });
          return;
        } else {
          debugPrint('🤖 [AI Coach] API returned null feedback, using fallback');
        }
      } else {
        debugPrint('🤖 [AI Coach] Skipping API call - missing required data');
        debugPrint('🤖 [AI Coach] userId is null: ${userId == null}');
        debugPrint('🤖 [AI Coach] workoutId is null: ${widget.workout.id == null}');
        debugPrint('🤖 [AI Coach] workout.id value: "${widget.workout.id}"');
      }

      // Fallback to generated summary if API call fails
      debugPrint('🤖 [AI Coach] Using fallback summary');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [AI Coach] Error loading feedback: $e');
      debugPrint('❌ [AI Coach] Stack trace: $stackTrace');
      setState(() {
        _aiSummary = _generateFallbackSummary();
        _isLoadingSummary = false;
      });
    }
  }

  String _generateFallbackSummary() {
    final minutes = widget.duration ~/ 60;
    final totalSets = widget.totalSets ?? 0;
    final totalReps = widget.totalReps ?? 0;
    final totalVolume = widget.totalVolumeKg ?? 0.0;

    // Get the current coach settings
    final aiSettings = ref.read(aiSettingsProvider);
    final coach = ref.read(aiSettingsProvider.notifier).getCurrentCoach();
    final coachName = coach?.name ?? aiSettings.coachName ?? 'Coach';
    final coachEmoji = coach?.emoji ?? '💪';

    // Determine workout quality based on actual metrics
    final bool wasMinimalEffort = totalSets == 0 || totalReps == 0 || minutes < 5;
    final bool wasShortWorkout = minutes >= 5 && minutes < 15 && totalSets < 6;

    // Generate honest feedback based on actual performance
    if (wasMinimalEffort) {
      // Honest feedback for minimal effort - vary by coach personality
      return _getMinimalEffortFeedback(coachName, coachEmoji, minutes, totalSets);
    } else if (wasShortWorkout) {
      // Acknowledge effort but encourage more
      return _getShortWorkoutFeedback(coachName, coachEmoji, minutes, totalSets, totalReps);
    } else {
      // Good workout - give appropriate recognition
      return _getGoodWorkoutFeedback(coachName, coachEmoji, minutes, totalSets, totalReps, totalVolume);
    }
  }

  String _getMinimalEffortFeedback(String coachName, String emoji, int minutes, int totalSets) {
    final aiSettings = ref.read(aiSettingsProvider);
    final tone = aiSettings.communicationTone;
    final coachId = aiSettings.coachPersonaId;

    switch (coachId) {
      case 'coach_mike':
        return "$emoji Hey champ, looks like today was a quick one. That's okay - what matters is showing up! Ready to go harder next time?";
      case 'dr_sarah':
        return "Session data: $minutes min, $totalSets sets. For optimal results, aim for 20+ minutes and progressive overload. We'll build from here.";
      case 'sergeant_max':
        return "💥 Soldier, that was barely a warm-up! $totalSets sets won't build a warrior. I expect you back here giving 100% next time!";
      case 'zen_maya':
        return "🧘 Sometimes we need lighter days. If today wasn't your full practice, that's okay. Honor where you are and return when ready.";
      case 'hype_danny':
        return "🔥 Yo that was a quick sesh! No worries tho, we all have off days. Come back tomorrow and we go CRAZY fr fr!!";
      default:
        if (tone == 'tough-love') {
          return "Let's be real - $totalSets sets in $minutes minutes isn't a full workout. Show up stronger next time.";
        }
        return "Quick session today! Every bit counts, but aim for more next time to see real progress. You've got this!";
    }
  }

  String _getShortWorkoutFeedback(String coachName, String emoji, int minutes, int totalSets, int totalReps) {
    final aiSettings = ref.read(aiSettingsProvider);
    final coachId = aiSettings.coachPersonaId;

    switch (coachId) {
      case 'coach_mike':
        return "$emoji Good effort showing up! $totalSets sets, $totalReps reps - that's a start. Push for a few more sets next time and watch the gains roll in!";
      case 'dr_sarah':
        return "Recorded: $totalSets sets, $totalReps reps in $minutes min. Research suggests 10+ working sets per muscle group weekly for hypertrophy. Consider extending future sessions.";
      case 'sergeant_max':
        return "💥 $totalSets sets done. It's something, recruit! But I know you've got more in the tank. Next session - no holding back!";
      case 'zen_maya':
        return "🧘 $minutes minutes of mindful movement. Every rep is a step on your journey. When you're ready, we can deepen the practice together.";
      case 'hype_danny':
        return "🔥 Ayo $totalSets sets logged! Not bad but we're just warming up bestie!! Next time we go FULL SEND!! 💪";
      default:
        return "Nice work getting $totalSets sets in! A solid foundation - try adding a couple more sets next session to level up.";
    }
  }

  String _getGoodWorkoutFeedback(String coachName, String emoji, int minutes, int totalSets, int totalReps, double totalVolume) {
    final aiSettings = ref.read(aiSettingsProvider);
    final coachId = aiSettings.coachPersonaId;
    final volumeStr = totalVolume > 0 ? ' ${totalVolume.toStringAsFixed(0)}kg total volume!' : '';

    switch (coachId) {
      case 'coach_mike':
        return "$emoji BOOM! $totalSets sets, $totalReps reps in $minutes minutes! That's what I'm talking about, champ!$volumeStr Keep this energy!";
      case 'dr_sarah':
        return "Excellent session. $totalSets sets, $totalReps reps, $minutes min.$volumeStr This volume supports progressive overload. Prioritize protein and sleep for recovery.";
      case 'sergeant_max':
        return "💥 NOW we're talking! $totalSets sets, $totalReps reps - that's soldier material!$volumeStr Hit the rack and recover. DISMISSED!";
      case 'zen_maya':
        return "🧘 Beautiful practice today. $totalSets sets completed with intention.$volumeStr Honor your body with rest and nourishment now.";
      case 'hype_danny':
        return "🔥🔥 YOOOO $totalSets sets and $totalReps reps?! You're literally built different no cap!!$volumeStr That's my GOAT!! 🐐";
      default:
        return "Great workout! $totalSets sets, $totalReps reps in $minutes minutes.$volumeStr Your consistency is building real results!";
    }
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

          // Show full-screen trophy celebration if there are trophies
          Future.microtask(() {
            _showTrophyCelebration();
          });
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
    debugPrint('📝 [Feedback] Starting feedback submission...');
    debugPrint('📝 [Feedback] Rating: $_rating, Difficulty: $_difficulty');
    debugPrint('📝 [Feedback] Exercise ratings count: ${_exerciseRatings.length}');
    debugPrint('📝 [Feedback] Workout ID: ${widget.workout.id}');

    if (_rating == 0) {
      debugPrint('⚠️ [Feedback] Rating is 0 - prompting user');
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
      debugPrint('📝 [Feedback] User ID: $userId');

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
        debugPrint('📝 [Feedback] Exercise feedback list: ${exerciseFeedbackList.length} exercises');

        // Submit workout feedback to backend
        debugPrint('📝 [Feedback] Calling POST /feedback/workout/${widget.workout.id}...');
        final response = await apiClient.post(
          '/feedback/workout/${widget.workout.id}',
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
        debugPrint('✅ [Feedback] Workout feedback API response: ${response.statusCode}');

        // Submit subjective feedback (mood, energy, confidence) if provided
        if (_moodAfter != null) {
          debugPrint('📝 [Subjective Feedback] Submitting: mood=$_moodAfter, energy=$_energyAfter, stronger=$_feelingStronger');
          try {
            final notifier = ref.read(subjectiveFeedbackProvider.notifier);
            await notifier.createPostCheckin(
              workoutId: widget.workout.id!,
              moodAfter: _moodAfter!,
              energyAfter: _energyAfter,
              confidenceLevel: _confidenceLevel,
              feelingStronger: _feelingStronger,
            );
            debugPrint('✅ [Subjective Feedback] Successfully submitted');
          } catch (e) {
            debugPrint('⚠️ [Subjective Feedback] Error (non-blocking): $e');
            // Non-blocking - don't fail the whole submission
          }
        }
        debugPrint('✅ [Feedback] All feedback submitted successfully');
      } else {
        debugPrint('⚠️ [Feedback] Missing userId or workoutId - skipping submission');
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
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    debugPrint('🏁 [Complete] Building workout complete screen');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Title Row (compact)
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.orange, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Workout Complete!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.workout.name ?? 'Workout',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  // Compact Stats Grid (2 rows x 3 cols)
                  _buildCompactStatsGrid().animate().fadeIn(delay: 200.ms),

                  // Heart Rate Section (if watch data available)
                  if (widget.heartRateReadings != null && widget.heartRateReadings!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildHeartRateSection(elevated).animate().fadeIn(delay: 250.ms),
                  ],

                  const SizedBox(height: 12),

                  // AI Feedback (tappable to expand)
                  GestureDetector(
                    onTap: _isLoadingSummary ? null : () {
                      setState(() => _isAiReviewExpanded = !_isAiReviewExpanded);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withOpacity(0.08),
                            AppColors.purple.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _isLoadingSummary
                                    ? const SizedBox(
                                        height: 40,
                                        child: Center(
                                          child: LottieLoading(size: 24, color: AppColors.orange),
                                        ),
                                      )
                                    : Text(
                                        _aiSummary ?? 'Great workout! Keep up the momentum.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          height: 1.4,
                                        ),
                                        maxLines: _isAiReviewExpanded ? null : 3,
                                        overflow: _isAiReviewExpanded ? null : TextOverflow.ellipsis,
                                      ),
                              ),
                              if (!_isLoadingSummary && (_aiSummary?.length ?? 0) > 100)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    _isAiReviewExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  // Rating Section
                  Text(
                    'How was your workout?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starIndex <= _rating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: starIndex <= _rating ? AppColors.orange : AppColors.textMuted,
                          ),
                        ),
                      );
                    }),
                  ).animate().fadeIn(delay: 400.ms),
                  if (_rating > 0)
                    Text(
                      _getRatingLabel(_rating),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Difficulty Section
                  Text(
                    'How was the difficulty?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DifficultyOption(
                        label: 'Too Easy',
                        icon: Icons.sentiment_very_satisfied,
                        isSelected: _difficulty == 'too_easy',
                        onTap: () => setState(() => _difficulty = 'too_easy'),
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _DifficultyOption(
                        label: 'Just Right',
                        icon: Icons.sentiment_satisfied,
                        isSelected: _difficulty == 'just_right',
                        onTap: () => setState(() => _difficulty = 'just_right'),
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 8),
                      _DifficultyOption(
                        label: 'Too Hard',
                        icon: Icons.sentiment_dissatisfied,
                        isSelected: _difficulty == 'too_hard',
                        onTap: () => setState(() => _difficulty = 'too_hard'),
                        color: AppColors.error,
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  // Trophies Section - Shows PRs and achievements earned (animation handled in method)
                  _buildTrophiesSection(elevated),

                  const Spacer(),

                  // Primary Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showShareSheet,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            side: BorderSide(color: AppColors.orange.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.orange, AppColors.purple],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: LottieLoading(size: 20, useDots: true, color: Colors.white),
                                  )
                                : const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 12),

                  // Secondary Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _isExtendingWorkout ? null : _extendWorkout,
                        icon: _isExtendingWorkout
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: LottieLoading(size: 14, useDots: true),
                              )
                            : const Icon(Icons.add, size: 16),
                        label: Text(
                          _isExtendingWorkout ? 'Adding...' : 'Do More',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.purple,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: textSecondary.withOpacity(0.3),
                      ),
                      TextButton.icon(
                        onPressed: _showChallengeFriendsDialog,
                        icon: const Icon(Icons.emoji_events, size: 16),
                        label: const Text(
                          'Challenge',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.orange,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: textSecondary.withOpacity(0.3),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showExerciseFeedback = !_showExerciseFeedback),
                        icon: Icon(
                          _showExerciseFeedback ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                        ),
                        label: const Text(
                          'Rate Exercises',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.purple,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),

                  // Expandable Exercise Feedback (shown in bottom sheet if tapped)
                  if (_showExerciseFeedback) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: elevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildCompactExerciseFeedback(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
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
                AppColors.orange,
                AppColors.purple,
                Color(0xFFFFD700), // Gold
                AppColors.green,
                AppColors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact stats grid for single-screen layout
  Widget _buildCompactStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactStatTile(
                icon: Icons.timer,
                value: _formatDuration(widget.duration),
                label: 'Time',
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatTile(
                icon: Icons.fitness_center,
                value: '${widget.workout.exercises.length}',
                label: 'Exercises',
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatTile(
                icon: Icons.local_fire_department,
                value: '${widget.calories}',
                label: 'Cal',
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactStatTile(
                icon: Icons.scale,
                value: '${(widget.totalVolumeKg ?? 0).toStringAsFixed(0)}kg',
                label: 'Volume',
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatTile(
                icon: Icons.repeat,
                value: '${widget.totalSets ?? 0}',
                label: 'Sets',
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactStatTile(
                icon: Icons.tag,
                value: '${widget.totalReps ?? 0}',
                label: 'Reps',
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Heart rate section with enhanced chart, zone breakdown, and fitness metrics
  Widget _buildHeartRateSection(Color elevated) {
    final readings = widget.heartRateReadings!
        .map((r) => r.toReading())
        .toList();

    // Get user age for accurate max HR calculation
    final authState = ref.watch(authStateProvider);
    final userAge = authState.user?.age ?? 30; // Default to 30 if not available
    final maxHR = calculateMaxHR(userAge);

    // Get resting heart rate from daily activity if available
    final activityState = ref.watch(dailyActivityProvider);
    final restingHR = activityState.today?.restingHeartRate;

    // Calculate workout duration in minutes
    final durationMinutes = (widget.duration / 60).round();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.favorite,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Heart Rate Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Compact heart rate chart (graph + stats + zone breakdown)
          HeartRateWorkoutChart(
            readings: readings,
            avgBpm: widget.avgHeartRate,
            maxBpm: widget.maxHeartRate,
            minBpm: widget.minHeartRate,
            maxHR: maxHR,
            restingHR: restingHR,
            durationMinutes: durationMinutes,
            totalCalories: widget.calories,
            showZoneBreakdown: true, // Show zones in compact view
            showTrainingEffect: false,
            showVO2Max: false,
            showFatBurnMetrics: false,
          ),
          const SizedBox(height: 12),

          // View All Metrics button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showHeartRateMetricsSheet(
                readings: readings,
                maxHR: maxHR,
                restingHR: restingHR,
                durationMinutes: durationMinutes,
              ),
              icon: Icon(Icons.analytics_outlined, size: 18, color: accentColor),
              label: Text(
                'View All Metrics',
                style: TextStyle(color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show detailed heart rate metrics in a bottom sheet
  void _showHeartRateMetricsSheet({
    required List<HeartRateReading> readings,
    required int maxHR,
    required int? restingHR,
    required int durationMinutes,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.read(accentColorProvider).getColor(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Heart Rate Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  // Scrollable content with all metrics
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: HeartRateWorkoutChart(
                        readings: readings,
                        avgBpm: widget.avgHeartRate,
                        maxBpm: widget.maxHeartRate,
                        minBpm: widget.minHeartRate,
                        maxHR: maxHR,
                        restingHR: restingHR,
                        durationMinutes: durationMinutes,
                        totalCalories: widget.calories,
                        showZoneBreakdown: true,
                        showTrainingEffect: true,
                        showVO2Max: restingHR != null,
                        showFatBurnMetrics: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact exercise feedback list for inline display
  Widget _buildCompactExerciseFeedback() {
    final exercises = widget.workout.exercises;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final rating = _exerciseRatings[index] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIdx) {
                  return GestureDetector(
                    onTap: () => setState(() => _exerciseRatings[index] = starIdx + 1),
                    child: Icon(
                      (starIdx + 1) <= rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: (starIdx + 1) <= rating ? AppColors.orange : AppColors.textMuted,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build the trophies section showing PRs and achievements earned
  Widget _buildTrophiesSection(Color elevated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Calculate trophy count
    final newAchievements = (_achievements?['new_achievements'] as List<dynamic>?)?.length ?? 0;
    final totalTrophies = _newPRs.length + newAchievements;
    final streak = _achievements?['streak_days'] as int? ?? 0;
    final totalWorkouts = _achievements?['total_workouts'] as int? ?? 1;
    final hasAchievements = totalTrophies > 0;

    Widget trophiesCard = GestureDetector(
      onTap: () => showTrophiesEarnedSheet(
        context,
        newPRs: _newPRs,
        achievements: _achievements,
        totalWorkouts: totalWorkouts,
        currentStreak: streak > 0 ? streak : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasAchievements
                ? [
                    AppColors.orange.withOpacity(0.2),
                    AppColors.purple.withOpacity(0.15),
                  ]
                : [
                    AppColors.orange.withOpacity(0.1),
                    AppColors.purple.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasAchievements
                ? AppColors.orange.withOpacity(0.5)
                : AppColors.orange.withOpacity(0.2),
            width: hasAchievements ? 1.5 : 1,
          ),
          boxShadow: hasAchievements
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Trophy icon with badge - animated when achievements
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.orange, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: hasAchievements
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                )
                    .animate(onPlay: (controller) => hasAchievements ? controller.repeat(reverse: true) : null)
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: hasAchievements ? const Offset(1.08, 1.08) : const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                if (hasAchievements)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: elevated, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        '$totalTrophies',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.15, 1.15),
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasAchievements)
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), AppColors.orange],
                          ).createShader(bounds),
                          child: const Text(
                            'Trophies Earned!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .shimmer(
                              duration: 1500.ms,
                              color: Colors.white.withOpacity(0.3),
                            )
                      else
                        Text(
                          'Trophies & Milestones',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hasAchievements ? AppColors.orange : textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAchievements
                        ? '${_newPRs.length} PRs${newAchievements > 0 ? ', $newAchievements badges' : ''} - Tap to view'
                        : streak > 0
                            ? '$streak day streak, $totalWorkouts total workouts'
                            : 'Track your progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasAchievements ? AppColors.orange.withOpacity(0.8) : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Add entrance animation and subtle glow pulse for achievements
    if (hasAchievements) {
      return trophiesCard
          .animate()
          .fadeIn(delay: 550.ms, duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut)
          .then()
          .shimmer(
            delay: 200.ms,
            duration: 1800.ms,
            color: AppColors.orange.withOpacity(0.15),
          );
    }

    return trophiesCard;
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
// Compact Stat Tile (for single-screen layout)
// ─────────────────────────────────────────────────────────────────

class _CompactStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactStatTile({
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: textMuted,
                  ),
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

/// Heart rate reading data for workout completion screen.
/// This is a simplified version of HeartRateReading for passing between screens.
class HeartRateReadingData {
  final int bpm;
  final DateTime timestamp;

  const HeartRateReadingData({
    required this.bpm,
    required this.timestamp,
  });

  /// Convert from HeartRateReading provider model
  factory HeartRateReadingData.fromReading(HeartRateReading reading) {
    return HeartRateReadingData(
      bpm: reading.bpm,
      timestamp: reading.timestamp,
    );
  }

  /// Convert to HeartRateReading for chart widget
  HeartRateReading toReading() {
    return HeartRateReading(
      bpm: bpm,
      timestamp: timestamp,
    );
  }
}
