import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/first_workout_forecast_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/hydration.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/fitness_snapshot_service.dart';
import '../../core/services/posthog_service.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../core/utils/weight_utils.dart';
import '../../widgets/lottie_animations.dart';
import '../../data/models/workout.dart';
import '../../data/models/cardio_pr.dart';
import '../../data/repositories/cardio_pr_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/data_cache_service.dart';
import '../../data/services/personal_goals_service.dart';
import '../../data/services/workout_completion_prewarmer.dart';
import '../../data/providers/discover_provider.dart';
import '../../data/providers/fitness_profile_provider.dart';
import '../../data/providers/fitness_shape_history_provider.dart';
import '../../data/providers/secondary_tile_providers.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/subjective_feedback_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../settings/sections/social_privacy_section.dart'
    show publicShareLinksProvider;
import '../../data/models/subjective_feedback.dart';
import '../challenges/widgets/challenge_complete_dialog.dart';
import '../challenges/widgets/challenge_friends_dialog.dart';
import 'widgets/hydration_dialog.dart';
import 'widgets/sauna_dialog.dart';
import 'widgets/workout_ai_recap_card.dart'; // B8 — merged post-workout Coach card (recap + muscles + pills + level-up)
import 'widgets/share_templates/_share_common.dart';
import '../../shareables/adapters/workout_adapter.dart';
import '../../shareables/shareable_data.dart';
import '../../shareables/shareable_sheet.dart';
// ShareableTemplate.prs — land the instant PR share directly on the PRs card.
import '../../shareables/shareable_catalog.dart' show ShareableTemplate;
import 'widgets/trophies_earned_sheet.dart';
import 'widgets/trophy_celebration_overlay.dart';
import '../../widgets/heart_rate_chart.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/design_system/zealova.dart';
import '../../data/providers/health_import_provider.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/repositories/sauna_repository.dart';
import '../../data/services/health_service.dart';
import '../../core/theme/accent_color_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/workout_photos_repository.dart';
import '../../data/repositories/strava_export_repository.dart';
import 'widgets/complete_screen_helper_widgets.dart';
import '../../widgets/exercise_image.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../l10n/generated/app_localizations.dart';
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

  /// Per-set breakdown for tap-to-expand exercise rows:
  /// [{name, sets: [{set_number, reps, weight_kg, set_type}]}]. Optional —
  /// rows fall back to the aggregate summary when absent.
  final List<Map<String, dynamic>>? exerciseSets;
  final List<Map<String, dynamic>>? plannedExercises; // NEW: For skip detection
  final Map<int, int>? exerciseTimeSeconds; // NEW: Per-exercise timing
  final int? totalRestSeconds;
  final double? avgRestSeconds;

  /// Median rest between sets/exercises, in seconds (Gravl-parity "Median
  /// rest" stat). Optional — when null the stats grid derives a median from
  /// [restIntervals] if the raw per-interval list was passed, otherwise it
  /// shows the median-of-available-aggregates. The completion route may wire
  /// this through directly from the workout-flow median computation.
  final double? medianRestSeconds;

  /// Raw rest-interval maps (each carries a `rest_seconds`), passed straight
  /// from the active-workout flow. Lets the stats grid compute a TRUE median
  /// on the completion screen without re-fetching. Optional.
  final List<Map<String, dynamic>>? restIntervals;
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

  /// Workstream 1 (Day 0-7 retention). True only on the user's first-ever
  /// completed workout — triggers the First Workout Forecast sheet after
  /// confetti fires.
  final bool isFirstWorkout;

  const WorkoutCompleteScreen({
    super.key,
    required this.workout,
    required this.duration,
    required this.calories,
    this.workoutLogId,
    this.exercisesPerformance,
    this.exerciseSets,
    this.plannedExercises,
    this.exerciseTimeSeconds,
    this.totalRestSeconds,
    this.avgRestSeconds,
    this.medianRestSeconds,
    this.restIntervals,
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
    this.isFirstWorkout = false,
  });

  @override
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  int _rating = 0;
  String _difficulty = 'just_right';
  bool _isSubmitting = false;

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
  // Cardio PRs achieved during/just-after THIS workout. Fetched on init via
  // CardioPrRepository.listAll() and filtered client-side to records with
  // achieved_at within the last 5 minutes. Empty list means nothing new —
  // the trophies sheet hides the cardio section in that case.
  List<dynamic> _newCardioPRs = [];
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

  // Surface 6c — Apple Health / Health Connect HR backfill. Populated only
  // when the live BLE/Watch capture (widget.heartRateReadings) was empty AND
  // the platform health store had HR samples in the workout window. Null
  // until the async fetch resolves; stays null (card hidden) on no-data /
  // no-permission.
  HeartRateBackfillResult? _hrBackfill;
  bool _hrBackfillAttempted = false;

  // Milestone thresholds
  static const List<int> _milestoneThresholds = [
    5,
    10,
    25,
    50,
    100,
    150,
    200,
    250,
    500,
    1000,
  ];

  @override
  void initState() {
    super.initState();
    _extInitState();
    // Surface 6c — when no live HR was captured during the workout, try to
    // backfill the heart-rate card from Apple Health / Health Connect for the
    // workout window. Permission-guarded + silent: renders nothing on no data.
    _maybeBackfillHeartRate();
    // Silently invalidate leaderboard-derived providers so Discover and the
    // fitness radar reflect this workout immediately on the next visit. No
    // user action required — data just updates.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.invalidate(discoverSnapshotProvider);
      ref.invalidate(fitnessProfileProvider);
      ref.invalidate(fitnessShapeHistoryProvider);
      // Also capture a fresh snapshot for today (debounced 1x/day internally).
      ref.read(fitnessSnapshotServiceProvider).ensureToday();
      // The Home metric deck + insight tiles (milestones, PRs, training load,
      // masteries, recovery, etc.) are keepAlive'd, so they won't pick up this
      // workout on their own. Bust their disk caches FIRST (they're fresh-cache-
      // first, so a bare invalidate would re-serve the stale disk snapshot),
      // THEN invalidate so returning to Home shows a fresh streak / PR / load
      // instead of a stale kept value (EC1). Providers aren't watched here (Home
      // not visible), so they re-run only on return — after this bust lands.
      final uid = await ref.read(apiClientProvider).getUserId();
      if (!mounted) return;
      if (uid != null) {
        await DataCacheService.instance.invalidateSecondaryTileCaches(uid);
      }
      for (final p in secondaryTileProviders) {
        ref.invalidate(p);
      }
    });
    // W1: fire the First Workout Forecast sheet ~2 seconds after mount
    // so confetti has started and the user sees their receipt briefly first.
    if (widget.isFirstWorkout) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 2200));
        if (!mounted) return;
        // Pick up user's planned sessions-per-week from preferences.
        // Fallback to 3 if unavailable.
        int sessionsPerWeek = 3;
        try {
          final apiClient = ref.read(apiClientProvider);
          final userId = await apiClient.getUserId();
          if (userId != null) {
            final resp = await apiClient.get('/users/$userId');
            final data = resp.data as Map<String, dynamic>?;
            final prefs = data?['preferences'] as Map<String, dynamic>?;
            final perWeek =
                prefs?['workouts_per_week'] ??
                prefs?['days_per_week'] ??
                data?['workouts_per_week'];
            if (perWeek is int && perWeek > 0 && perWeek <= 7) {
              sessionsPerWeek = perWeek;
            }
          }
        } catch (_) {
          /* non-critical */
        }

        // Pick highest PR improvement percent, if any
        int firstPrImprovementPct = 0;
        final prs = widget.personalRecords ?? const [];
        for (final pr in prs) {
          final pct = pr.improvementPercent;
          if (pct != null && pct > firstPrImprovementPct) {
            firstPrImprovementPct = pct.round();
          }
        }

        if (!mounted) return;
        await showFirstWorkoutForecastSheet(
          context,
          workout: widget.workout,
          totalVolumeKg: widget.totalVolumeKg ?? 0,
          caloriesBurned: widget.calories,
          durationMinutes: (widget.duration / 60).round(),
          sessionsPerWeek: sessionsPerWeek,
          firstWorkoutPrImprovementPercent: firstPrImprovementPct,
        );
      });
    }
  }

  // Sauna logging state
  int? _saunaMinutes;
  int? _saunaCalories;

  // Optional post-workout photo (Workstream C). Local file path of the picked
  // image — set immediately on capture so the Share flow can pre-select it via
  // Shareable.customPhotoPath, while the S3 upload runs in the background.
  String? _capturedPhotoPath;
  bool _isUploadingPhoto = false;

  // Workstream E4 — outbound Strava share. Connection capability is loaded
  // lazily; the "Share to Strava" affordance only renders once we know the
  // user has an active Strava account. `_sharingToStrava` gates the button
  // while the manual push round-trips.
  StravaSharePreference? _stravaPref;
  bool _sharingToStrava = false;

  /// Surface 6c — backfill HR from Apple Health / Health Connect when the
  /// live BLE/Watch capture produced no samples. Reads HR for the workout
  /// window [start, end] = [now - duration, now], computes avg/min/max +
  /// series, and stores it for the heart-rate section to render labeled
  /// "From Apple Health" / "From Health Connect". Fully guarded: no-ops when
  /// live HR already exists, and silently renders nothing on no-data /
  /// no-permission.
  Future<void> _maybeBackfillHeartRate() async {
    // Skip entirely when the workout already captured live HR.
    final live = widget.heartRateReadings;
    if (live != null && live.isNotEmpty) return;
    if (_hrBackfillAttempted) return;
    _hrBackfillAttempted = true;

    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(seconds: widget.duration));
      final result = await ref
          .read(healthImportProvider.notifier)
          .readHeartRateForRange(start, end);
      if (!mounted) return;
      if (result.hasData) {
        setState(() => _hrBackfill = result);
        if (kDebugMode) {
          debugPrint(
            '❤️ [Complete] HR backfilled from health store: '
            '${result.series.length} samples (${result.sourceLabel})',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❤️ [Complete] HR backfill failed (non-critical): $e');
      }
    }
  }

  /// Median of a list of rest_seconds values (sorted; average of the two
  /// middle values for even counts). Returns null for an empty list.
  static double? medianOfRestSeconds(List<int> restSeconds) {
    final values = restSeconds.where((v) => v > 0).toList()..sort();
    if (values.isEmpty) return null;
    final mid = values.length ~/ 2;
    if (values.length.isOdd) {
      return values[mid].toDouble();
    }
    return (values[mid - 1] + values[mid]) / 2.0;
  }

  /// The median rest (seconds) to display on the stats grid. Prefers the
  /// explicit [WorkoutCompleteScreen.medianRestSeconds] (wired from the
  /// workout-flow median), then a TRUE median computed from raw
  /// [WorkoutCompleteScreen.restIntervals], and finally falls back to the
  /// average rest (so the cell is never blank when we at least know the avg).
  double? get _effectiveMedianRestSeconds {
    if (widget.medianRestSeconds != null && widget.medianRestSeconds! > 0) {
      return widget.medianRestSeconds;
    }
    final intervals = widget.restIntervals;
    if (intervals != null && intervals.isNotEmpty) {
      final secs = <int>[
        for (final i in intervals) ((i['rest_seconds'] as num?)?.toInt() ?? 0),
      ];
      final m = medianOfRestSeconds(secs);
      if (m != null) return m;
    }
    final avg = widget.avgRestSeconds;
    if (avg != null && avg > 0) return avg;
    return null;
  }

  /// Format seconds as mm:ss (e.g. 95 → "1:35", 8 → "0:08").
  String _formatMmSs(num seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Fire-and-forget: write completed workout to Health Connect / HealthKit.
  Future<void> _syncWorkoutToHealth() async {
    try {
      final syncState = ref.read(healthSyncProvider);
      if (!syncState.isConnected) return;

      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('health_sync_workouts_write') ?? true)) return;

      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(seconds: widget.duration));

      await ref
          .read(healthSyncProvider.notifier)
          .writeWorkoutToHealth(
            workoutType: widget.workout.type ?? 'strength',
            startTime: startTime,
            endTime: endTime,
            totalCaloriesBurned: widget.calories,
            title: widget.workout.name ?? '${Branding.appName} Workout',
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
      ref
          .read(hydrationProvider.notifier)
          .logHydration(
            userId: userId,
            drinkType: result.drinkType.value,
            amountMl: result.amountMl,
            workoutId: widget.workout.id,
            source: HydrationSource.workout,
          );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // A4: clear the completion cache on dispose so a stale entry can't
    // trigger an unexpected re-push to /workout-complete after the user has
    // moved on (e.g. while browsing the share-workout sheet). The cache is
    // a UX optimization for the upcoming completion — once we've shown
    // it, it's served its purpose for this cycle.
    workoutCompletionCache.clear();
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
    final bool wasMinimalEffort =
        totalSets == 0 || totalReps == 0 || minutes < 5;
    final bool wasShortWorkout = minutes >= 5 && minutes < 15 && totalSets < 6;

    // Generate honest feedback based on actual performance
    if (wasMinimalEffort) {
      // Honest feedback for minimal effort - vary by coach personality
      return _getMinimalEffortFeedback(
        coachName,
        coachEmoji,
        minutes,
        totalSets,
      );
    } else if (wasShortWorkout) {
      // Acknowledge effort but encourage more
      return _getShortWorkoutFeedback(
        coachName,
        coachEmoji,
        minutes,
        totalSets,
        totalReps,
      );
    } else {
      // Good workout - give appropriate recognition
      return _getGoodWorkoutFeedback(
        coachName,
        coachEmoji,
        minutes,
        totalSets,
        totalReps,
        totalVolume,
      );
    }
  }

  String _getMinimalEffortFeedback(
    String coachName,
    String emoji,
    int minutes,
    int totalSets,
  ) {
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

  String _getShortWorkoutFeedback(
    String coachName,
    String emoji,
    int minutes,
    int totalSets,
    int totalReps,
  ) {
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

  String _getGoodWorkoutFeedback(
    String coachName,
    String emoji,
    int minutes,
    int totalSets,
    int totalReps,
    double totalVolume,
  ) {
    final aiSettings = ref.read(aiSettingsProvider);
    final coachId = aiSettings.coachPersonaId;
    final volumeStr = totalVolume > 0
        ? ' ${totalVolume.toStringAsFixed(0)}kg total volume!'
        : '';

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
        (pr) =>
            (pr['exercise_name'] ?? '').toString().toLowerCase() ==
            exName.toString().toLowerCase(),
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
    final backgroundColor = isDark
        ? AppColors.pureBlack
        : AppColorsLight.pureWhite;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    debugPrint('🏁 [Complete] Building workout complete screen');

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: SafeArea(
        // SafeArea already provides the device's bottom inset — the old
        // 8px bottom padding + TextButton's default padding stacked on top
        // of it produced a ~40px gap under "Skip rating". Zero it out.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instant PR shareable: when this session set a PR, offer a
              // one-tap "Share PR" that opens the share sheet pre-loaded on the
              // medal-ranked PRs card. Only shown when PRs exist.
              if (_newPRs.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ZealovaButton(
                    label: _newPRs.length == 1
                        ? 'Share your PR'
                        : 'Share your PRs',
                    onTap: _showPRShareSheet,
                    variant: ZealovaButtonVariant.ghost,
                    trailingIcon: Icons.emoji_events_rounded,
                  ),
                ),
                const SizedBox(height: 10),
              ]
              // F7 — milestone auto-card. When this session crossed a workout
              // milestone (but set no PR — PR share already covers that case),
              // surface a one-tap "Share this milestone" that lands on the
              // milestoneCard preset.
              else if (_getWorkoutMilestone() != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ZealovaButton(
                    label: 'Share this milestone',
                    onTap: _showMilestoneShareSheet,
                    variant: ZealovaButtonVariant.ghost,
                    trailingIcon: Icons.workspace_premium_rounded,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  // Secondary action — ghost (hairline outline), keeps the
                  // reserved accent for the single primary CTA.
                  Expanded(
                    child: ZealovaButton(
                      label: AppLocalizations.of(context).commonShare,
                      onTap: _showShareSheet,
                      variant: ZealovaButtonVariant.ghost,
                      trailingIcon: Icons.share_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // THE one accent CTA on this screen.
                  Expanded(
                    flex: 2,
                    child: _isSubmitting
                        ? Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ThemeColors.of(context).accent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: LottieLoading(
                                size: 20,
                                useDots: true,
                                color: ThemeColors.of(context).accentContrast,
                              ),
                            ),
                          )
                        : ZealovaButton(
                            label: AppLocalizations.of(context).commonDone,
                            onTap: _submitFeedback,
                          ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _handleSkipRating,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).workoutCompleteSkipRating.toUpperCase(),
                  style: ZType.lbl(
                    11,
                    color: textSecondary,
                    letterSpacing: 1.5,
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
                  // Title — typographic "DONE." masthead (Anton) over a
                  // Barlow kicker + the workout name, with a Fraunces human
                  // exhale line. Replaces the gradient check-circle + bold
                  // titleLarge with the Signature celebration treatment.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZealovaSectionKicker(
                        AppLocalizations.of(
                          context,
                        ).workoutCompleteWorkoutComplete,
                      ),
                      const SizedBox(height: 4),
                      // Typographic finish — orange is reserved for the DONE
                      // CTA, so the masthead is pure Anton on the text ladder
                      // (no decorative accent check icon competing for it).
                      Text(
                        'DONE.',
                        style: ZType.disp(
                          52,
                          color: ThemeColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.workout.name ??
                            AppLocalizations.of(context).navWorkout,
                        style: ZType.ser(16, color: textSecondary),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  // Signature v2 hairline stat ledger — Time · Volume ·
                  // Sets·Reps · Energy · Median rest · Records on 1px rules.
                  _buildCompactStatsGrid().animate().fadeIn(delay: 200.ms),

                  // XP + streak — the two-cell earned/streak row (Frame 2).
                  // Neutral numerals keep the single orange budget on DONE.
                  _buildXpStreakRow().animate().fadeIn(delay: 240.ms),

                  // Optional post-workout photo (Workstream C). A low-key
                  // affordance — never competes with the DONE CTA's accent;
                  // once captured it pre-selects into the Share compose flow.
                  const SizedBox(height: 12),
                  _buildAddPhotoSection().animate().fadeIn(delay: 260.ms),

                  // Workstream E4 — "Share to Strava" affordance (renders only
                  // when a Strava account is connected). Ghost-styled so it
                  // never competes with the DONE CTA's accent.
                  _buildShareToStravaSection().animate().fadeIn(delay: 280.ms),

                  // Heart Rate Section — live watch/BLE capture takes priority;
                  // otherwise the Apple Health / Health Connect backfill (6c).
                  if (widget.heartRateReadings != null &&
                      widget.heartRateReadings!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildHeartRateSection(
                      elevated,
                    ).animate().fadeIn(delay: 250.ms),
                  ] else if (_hrBackfill != null && _hrBackfill!.hasData) ...[
                    const SizedBox(height: 16),
                    _buildBackfilledHeartRateSection(
                      elevated,
                      _hrBackfill!,
                    ).animate().fadeIn(delay: 250.ms),
                  ],

                  // ONE merged Coach card (2C): AI recap + muscles-worked strip
                  // + quick pills + strength level-up, collapsed by default.
                  // Replaces the old three stacked cards (AiCoachReportCard +
                  // WorkoutAiRecapCard + ScoreLevelUpCelebration).
                  const SizedBox(height: 12),
                  WorkoutAiRecapCard(
                    workoutId: widget.workout.id ?? '',
                    workoutLogId: widget.workoutLogId,
                    workoutName: widget.workout.name ?? 'Workout',
                    workoutType: widget.workout.type ?? 'strength',
                    exercises: widget.workout.exercises
                        .map(
                          (e) => <String, dynamic>{
                            'name': e.name,
                            'sets': e.sets ?? 0,
                            'reps': e.reps ?? 0,
                            'weight_kg': e.weight ?? 0,
                            'time_seconds': e.durationSeconds ?? 0,
                          },
                        )
                        .toList(),
                    workoutExercises: widget.workout.exercises,
                    totalSets: widget.totalSets ?? 0,
                    totalReps: widget.totalReps ?? 0,
                    totalVolumeKg: widget.totalVolumeKg ?? 0,
                    totalTimeSeconds: widget.duration,
                    earnedPRs: _newPRs,
                    performanceComparison: widget.performanceComparison,
                    trainedMuscles: <String>{
                      for (final ex in widget.workout.exercises)
                        ...[ex.primaryMuscle, ex.muscleGroup, ex.bodyPart]
                            .whereType<String>()
                            .map((m) => m.trim().toLowerCase())
                            .where((m) => m.isNotEmpty),
                    },
                    totalWorkoutsCompleted: _totalWorkoutCount,
                    useKg: ref.watch(useKgForWorkoutProvider),
                  ).animate().fadeIn(delay: 320.ms),

                  // Per-exercise breakdown (sets x reps x weight + PR badges).
                  if (_buildExercisesSection() != null) ...[
                    const SizedBox(height: 16),
                    _buildExercisesSection()!.animate().fadeIn(delay: 320.ms),
                  ],

                  const SizedBox(height: 16),

                  // Rating Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ZealovaSectionKicker(
                      AppLocalizations.of(
                        context,
                      ).workoutCompleteHowWasYourWorkout,
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
                            starIndex <= _rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 36,
                            // Neutral filled stars keep the single orange budget
                            // on the DONE CTA (Signature v2 orange-once rule).
                            color: starIndex <= _rating
                                ? ThemeColors.of(context).textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      );
                    }),
                  ).animate().fadeIn(delay: 400.ms),
                  if (_rating > 0)
                    Text(
                      _getRatingLabel(_rating),
                      style: ZType.lbl(
                        12,
                        color: ThemeColors.of(context).accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).workoutCompleteYourRatingsHelpUs,
                    style: ZType.ser(13, color: textSecondary),
                  ),

                  const SizedBox(height: 16),

                  // Trophies Section - Shows PRs and achievements earned (animation handled in method)
                  _buildTrophiesSection(elevated),

                  const SizedBox(height: 16),

                  // Secondary Actions Row — visible: Do More / Sauna /
                  // Summary / Give Detailed Feedback. Water and This Week
                  // live in the "More" overflow menu to reduce vertical
                  // scroll on the completion screen.
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
                          _isExtendingWorkout
                              ? AppLocalizations.of(context).workoutReviewAdding
                              : AppLocalizations.of(
                                  context,
                                ).workoutCompleteDoMore,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saunaMinutes != null
                            ? null
                            : _showSaunaDialog,
                        icon: Icon(
                          Icons.hot_tub_rounded,
                          size: 16,
                          color: _saunaMinutes != null
                              ? AppColors.textMuted
                              : textSecondary,
                        ),
                        label: Text(
                          _saunaMinutes != null
                              ? '${_saunaMinutes}min'
                              : AppLocalizations.of(
                                  context,
                                ).workoutCompleteSauna,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                        ),
                      ),
                      if (widget.workout.id != null)
                        TextButton.icon(
                          // `?tab=summary` deep-links the pill selector on
                          // the summary screen to the Summary pane instead
                          // of Detail — matches the button's label.
                          onPressed: () => context.push(
                            '/workout-summary/${widget.workout.id}?tab=summary',
                          ),
                          icon: const Icon(Icons.summarize_outlined, size: 16),
                          label: Text(
                            AppLocalizations.of(context).workoutCompleteSummary,
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondary,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(
                          () => _showDetailedFeedback = !_showDetailedFeedback,
                        ),
                        icon: Icon(
                          _showDetailedFeedback
                              ? Icons.expand_less
                              : Icons.rate_review_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _showDetailedFeedback
                              ? AppLocalizations.of(context).workoutCompleteLess
                              : AppLocalizations.of(
                                  context,
                                ).workoutCompleteGiveDetailedFeedback,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                        ),
                      ),
                      // Overflow menu — holds the less-frequently-used
                      // actions so they don't consume a full row each.
                      PopupMenuButton<String>(
                        tooltip: AppLocalizations.of(
                          context,
                        ).workoutCompleteMoreActions,
                        position: PopupMenuPosition.under,
                        onSelected: (value) {
                          switch (value) {
                            case 'water':
                              _showWaterDialog();
                              break;
                            case 'this_week':
                              context.push('/summaries');
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'water',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  size: 18,
                                  color: AppColors.waterBlue,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).workoutCompleteLogWater,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'this_week',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insights_outlined,
                                  size: 18,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).workoutCompleteThisWeek,
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).homeMore,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  // Sauna confirmation chip
                  if (_saunaMinutes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.of(context).surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hot_tub_rounded,
                              size: 16,
                              color: ThemeColors.of(context).textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_saunaMinutes min sauna · ~$_saunaCalories cal',
                              style: ZType.lbl(
                                11,
                                color: ThemeColors.of(context).textSecondary,
                                letterSpacing: 0.8,
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ZealovaSectionKicker(
                        AppLocalizations.of(
                          context,
                        ).workoutCompleteHowWasTheDifficulty,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        DifficultyOption(
                          label: AppLocalizations.of(
                            context,
                          ).workoutCompleteTooEasy,
                          icon: Icons.sentiment_very_satisfied,
                          isSelected: _difficulty == 'too_easy',
                          onTap: () => setState(() => _difficulty = 'too_easy'),
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        DifficultyOption(
                          label: AppLocalizations.of(
                            context,
                          ).workoutCompleteJustRight,
                          icon: Icons.sentiment_satisfied,
                          isSelected: _difficulty == 'just_right',
                          onTap: () =>
                              setState(() => _difficulty = 'just_right'),
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        DifficultyOption(
                          label: AppLocalizations.of(
                            context,
                          ).workoutCompleteTooHard,
                          icon: Icons.sentiment_dissatisfied,
                          isSelected: _difficulty == 'too_hard',
                          onTap: () => setState(() => _difficulty = 'too_hard'),
                          color: AppColors.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Per-exercise feedback
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ZealovaSectionKicker(
                        AppLocalizations.of(
                          context,
                        ).workoutCompleteRateExercises,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: ThemeColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
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
