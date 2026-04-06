import 'package:flutter/material.dart';
import '../../widgets/glass_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../widgets/lottie_animations.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/personal_goals_service.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/subjective_feedback_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../data/models/subjective_feedback.dart';
import '../challenges/widgets/challenge_complete_dialog.dart';
import '../challenges/widgets/challenge_friends_dialog.dart';
import 'widgets/hydration_dialog.dart';
import 'widgets/sauna_dialog.dart';
import 'widgets/ai_coach_report_card.dart';
import 'widgets/share_workout_sheet.dart';
import 'widgets/trophies_earned_sheet.dart';
import 'widgets/trophy_celebration_overlay.dart';
import '../../widgets/heart_rate_chart.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/repositories/sauna_repository.dart';
import '../../data/services/health_service.dart';
import '../../core/theme/accent_color_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/complete_screen_helper_widgets.dart';
export 'widgets/complete_screen_helper_widgets.dart' show HeartRateReadingData;

part 'workout_complete_screen_ui_1.dart';
part 'workout_complete_screen_ui_2.dart';

part 'workout_complete_screen_ext_1.dart';
part 'workout_complete_screen_ext_2.dart';


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
  // Whether to show detailed feedback (difficulty, per-exercise, subjective)
  bool _showDetailedFeedback = false;

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
    _extInitState();
  }

  // Sauna logging state
  int? _saunaMinutes;
  int? _saunaCalories;

  /// Fire-and-forget: write completed workout to Health Connect / HealthKit.
  Future<void> _syncWorkoutToHealth() async {
    try {
      final syncState = ref.read(healthSyncProvider);
      if (!syncState.isConnected) return;

      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('health_sync_workouts_write') ?? true)) return;

      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(seconds: widget.duration));

      await ref.read(healthSyncProvider.notifier).writeWorkoutToHealth(
        workoutType: widget.workout.type ?? 'strength',
        startTime: startTime,
        endTime: endTime,
        totalCaloriesBurned: widget.calories,
        title: widget.workout.name ?? 'FitWiz Workout',
      );
    } catch (e) {
      debugPrint('⚠️ [Health] Non-critical: workout health sync failed: $e');
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

  Future<void> _showWaterDialog() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final hydrationState = ref.read(hydrationProvider);
    final totalIntake = hydrationState.todaySummary?.totalMl ?? 0;

    // Import is already at top of file
    final result = await showHydrationDialog(
      context: context,
      totalIntakeMl: totalIntake,
    );
    if (result != null && mounted) {
      ref.read(hydrationProvider.notifier).logHydration(
        userId: userId,
        drinkType: result.drinkType.value,
        amountMl: result.amountMl,
        workoutId: widget.workout.id,
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ),
              TextButton(
                onPressed: _handleSkipRating,
                child: Text(
                  'Skip rating',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  // AI Coach Report Card (muscles worked, stats, AI insight)
                  AiCoachReportCard(
                    exercises: widget.workout.exercises,
                    aiSummary: _aiSummary,
                    isLoadingSummary: _isLoadingSummary,
                    isExpanded: _isAiReviewExpanded,
                    onToggleExpand: () => setState(() => _isAiReviewExpanded = !_isAiReviewExpanded),
                    totalSets: widget.totalSets ?? 0,
                    totalVolumeKg: widget.totalVolumeKg ?? 0,
                    durationSeconds: widget.duration,
                    newPRs: _newPRs,
                    performanceComparison: widget.performanceComparison,
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
                  const SizedBox(height: 6),
                  Text(
                    'Your ratings help us personalize your future workouts',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Trophies Section - Shows PRs and achievements earned (animation handled in method)
                  _buildTrophiesSection(elevated),

                  const SizedBox(height: 16),

                  // Secondary Actions Row
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 0,
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
                      // Challenge button commented out - not yet functional
                      // TextButton.icon(
                      //   onPressed: _showChallengeFriendsDialog,
                      //   icon: const Icon(Icons.emoji_events, size: 16),
                      //   label: const Text(
                      //     'Challenge',
                      //     style: TextStyle(fontSize: 13),
                      //   ),
                      //   style: TextButton.styleFrom(
                      //     foregroundColor: AppColors.orange,
                      //   ),
                      // ),
                      TextButton.icon(
                        onPressed: _saunaMinutes != null ? null : _showSaunaDialog,
                        icon: Icon(
                          Icons.hot_tub_rounded,
                          size: 16,
                          color: _saunaMinutes != null ? AppColors.textMuted : null,
                        ),
                        label: Text(
                          _saunaMinutes != null ? '${_saunaMinutes}min' : 'Sauna',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showWaterDialog,
                        icon: const Icon(Icons.water_drop_rounded, size: 16),
                        label: const Text(
                          'Water',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.teal,
                        ),
                      ),
                      if (widget.workout.id != null)
                        TextButton.icon(
                          onPressed: () => context.push('/workout-summary/${widget.workout.id}'),
                          icon: const Icon(Icons.summarize_outlined, size: 16),
                          label: const Text(
                            'Summary',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.orange,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showDetailedFeedback = !_showDetailedFeedback),
                        icon: Icon(
                          _showDetailedFeedback ? Icons.expand_less : Icons.rate_review_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _showDetailedFeedback ? 'Less' : 'Detailed feedback',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.purple,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  // Sauna confirmation chip
                  if (_saunaMinutes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE65100).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hot_tub_rounded, size: 16, color: Color(0xFFE65100)),
                            const SizedBox(width: 8),
                            Text(
                              '$_saunaMinutes min sauna · ~$_saunaCalories cal',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Detailed feedback section (gated behind toggle)
                  if (_showDetailedFeedback) ...[
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
                        DifficultyOption(
                          label: 'Too Easy',
                          icon: Icons.sentiment_very_satisfied,
                          isSelected: _difficulty == 'too_easy',
                          onTap: () => setState(() => _difficulty = 'too_easy'),
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        DifficultyOption(
                          label: 'Just Right',
                          icon: Icons.sentiment_satisfied,
                          isSelected: _difficulty == 'just_right',
                          onTap: () => setState(() => _difficulty = 'just_right'),
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        DifficultyOption(
                          label: 'Too Hard',
                          icon: Icons.sentiment_dissatisfied,
                          isSelected: _difficulty == 'too_hard',
                          onTap: () => setState(() => _difficulty = 'too_hard'),
                          color: AppColors.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Per-exercise feedback
                    Text(
                      'Rate exercises',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildCompactExerciseFeedback(),
                    ),
                  ],

                  const SizedBox(height: 16),
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
}
