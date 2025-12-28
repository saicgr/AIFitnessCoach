import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/lottie_animations.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
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
  Map<int, int> _exerciseRatings = {};
  // Per-exercise difficulty (exercise index -> difficulty)
  Map<int, String> _exerciseDifficulties = {};
  // Whether to show exercise feedback section
  bool _showExerciseFeedback = false;

  // Achievements state
  Map<String, dynamic>? _achievements;
  bool _isLoadingAchievements = true;
  List<Map<String, dynamic>> _newPRs = [];
  bool _showExerciseProgress = false;
  Map<String, List<Map<String, dynamic>>> _exerciseProgressData = {};
  Map<String, bool> _expandedExercises = {};

  // Confetti controller for celebrations
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAICoachFeedback();
    _loadAchievements();
    _loadExerciseProgress();

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
        debugPrint('📤 [Feedback] Submitting workout feedback: rating=$_rating, difficulty=$_difficulty');
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
        debugPrint('✅ [Feedback] Workout feedback submitted successfully');
      }

      // Refresh workouts
      await ref.read(workoutsProvider.notifier).refresh();

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

                // New PRs / Achievements Section
                if (_newPRs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNewPRsSection(),
                ],

                // Exercise Progress Section (Minimizable graphs)
                if (_exerciseProgressData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildExerciseProgressSection(),
                ],

                const SizedBox(height: 32),

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
              ..._newPRs.map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
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
                    Text(
                      '${(pr['weight_kg'] as num).toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )).toList(),
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
                ))).toList(),
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
