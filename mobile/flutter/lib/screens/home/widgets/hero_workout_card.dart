import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/workout_mutation_coordinator.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../cycle/cycle_visuals.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/image_url_cache.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'regenerate_workout_sheet.dart';
import '../../social/widgets/create_post_sheet.dart';
import '../../workout/widgets/exercise_add_sheet.dart';
import '../../../core/services/posthog_service.dart';
import '../../../shareables/shareable_sheet.dart';
import '../../../shareables/adapters/workout_adapter.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/workout_card_state_provider.dart';
import '../../settings/sections/social_privacy_section.dart' show publicShareLinksProvider;
import '../../pillar/widgets/ask_coach_button.dart';
// `workout_card_mode.dart` defines its own `CyclePhase` enum (with an
// `unknown` member) used by the pure resolver. The hero card already
// references the `hormonal_health.dart` `CyclePhase` for the phase chip
// rendering, so import the resolver under a prefix to avoid the clash.
import 'workout_card/workout_card_mode.dart' show WorkoutCardMode;


import '../../../l10n/generated/app_localizations.dart';
part 'hero_workout_card_part_completed_workout_hero_card.dart';
part 'hero_workout_card_part_stat_chip.dart';

part 'hero_workout_card_ui.dart';

part 'hero_workout_card_ext.dart';

part 'hero_workout_card_modes.dart';


/// Hero workout card - Gravl-inspired design with background image
/// Features a large background image with gradient overlay and prominent START button
class HeroWorkoutCard extends ConsumerStatefulWidget {
  final Workout workout;

  /// Whether this card is inside a carousel (removes outer padding)
  final bool inCarousel;

  const HeroWorkoutCard({
    super.key,
    required this.workout,
    this.inCarousel = false,
  });

  @override
  ConsumerState<HeroWorkoutCard> createState() => _HeroWorkoutCardState();
}

class _HeroWorkoutCardState extends ConsumerState<HeroWorkoutCard> {
  bool _isSkipping = false;
  bool _isMarkingDone = false;
  String? _backgroundImageUrl;
  bool _isLoadingImage = true;

  /// Per-type illustration map. Asset directory is fail-soft — when an
  /// asset is missing the CachedNetworkImage / Image widget falls through
  /// to the existing /exercise-images endpoint, then the accent gradient.
  ///
  /// Keys lowercased; both `type` and `focusGroup` strings route through
  /// `_typeIllustrationFor` which normalizes synonyms.
  // ONLY map keys whose PNG actually ships under assets/images/workout_types/.
  // A key pointing at a missing file makes Image.asset throw "Asset not found"
  // every build (caught by the errorBuilder, but it spams the console). Types
  // without bundled art (upper / lower / push / pull / legs / full_body / core)
  // are intentionally absent: `_typeIllustrationFor` returns null for them and
  // the card falls through to the per-exercise image, then the accent gradient.
  // Bundled files on disk: cardio, hiit, mobility, strength, yoga, saved.
  static const Map<String, String> _workoutTypeIllustrations = {
    'cardio': 'assets/images/workout_types/cardio.png',
    'hiit': 'assets/images/workout_types/hiit.png',
    'mobility': 'assets/images/workout_types/mobility.png',
    'yoga': 'assets/images/workout_types/yoga.png',
    'strength': 'assets/images/workout_types/strength.png',
    'recovery': 'assets/images/workout_types/mobility.png',
    // Resistance-training splits all reuse the bundled strength art so a
    // "Leg Day" / "Push" / "Upper" workout shows an image instead of the bare
    // orange gradient. (Only maps to PNGs that actually ship on disk.)
    'legs': 'assets/images/workout_types/strength.png',
    'push': 'assets/images/workout_types/strength.png',
    'pull': 'assets/images/workout_types/strength.png',
    'upper': 'assets/images/workout_types/strength.png',
    'lower': 'assets/images/workout_types/strength.png',
    'upper_body': 'assets/images/workout_types/strength.png',
    'lower_body': 'assets/images/workout_types/strength.png',
    'full_body': 'assets/images/workout_types/strength.png',
    'fullbody': 'assets/images/workout_types/strength.png',
    'core': 'assets/images/workout_types/strength.png',
    'arms': 'assets/images/workout_types/strength.png',
    'chest': 'assets/images/workout_types/strength.png',
    'back': 'assets/images/workout_types/strength.png',
    'shoulders': 'assets/images/workout_types/strength.png',
    'glutes': 'assets/images/workout_types/strength.png',
  };

  String? _typeIllustrationFor(Workout w) {
    final candidates = <String?>[w.type];
    for (final raw in candidates) {
      if (raw == null || raw.isEmpty) continue;
      final key = raw.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
      final path = _workoutTypeIllustrations[key];
      if (path != null) return path;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _resolveBackground();
  }

  @override
  void didUpdateWidget(HeroWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This card carries NO `key` at any of its call sites (incl. the carousel
    // PageView at hero_workout_carousel.dart), so Flutter can recycle this
    // State for a different workout. Image resolution only ran in initState,
    // so a recycled State kept the previous workout's image (or a stale
    // blank). Re-resolve whenever the underlying workout identity changes.
    if (oldWidget.workout.id != widget.workout.id) {
      _typeAssetPath = null;
      _backgroundImageUrl = null;
      _resolveBackground();
    }
  }

  /// Resolves the hero background image for the current workout.
  ///
  /// Prefers the bundled per-workout-type illustration (Surface 1.2 / 2.2) but
  /// ALWAYS prefetches the per-exercise `/exercise-images` URL as the
  /// fail-soft fallback. The `assets/images/workout_types/*.png` art is not
  /// bundled (yet), so `Image.asset` 404s and the build method's errorBuilder
  /// falls through to `_backgroundImageUrl`; without this prefetch that URL
  /// stayed null and the hero rendered blank. If the type art ever ships it
  /// simply wins and the prefetch is a no-op cost.
  void _resolveBackground() {
    _typeAssetPath = _typeIllustrationFor(widget.workout);
    // Never block the hero on the (currently missing) type asset — show the
    // accent gradient immediately and let the async fetch pop the image in.
    _isLoadingImage = false;

    final exercises = widget.workout.exercises;
    if (exercises.isEmpty) return;
    final first = exercises.first;
    final exerciseName = first.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') return;
    // The exact library row id — drives `?exercise_id=` below. Without it the
    // lookup is a name-only ilike that 404s / hits the wrong dupe, leaving
    // _backgroundImageUrl null so the hero falls back to the generic per-type
    // art forever (the "no exercise image" report).
    final exerciseId = first.exerciseId ?? first.libraryId;

    // Key the URL cache by id when available (matches ExerciseImage) so two
    // exercises sharing a display name don't pollute each other's cache.
    final cacheKey = (exerciseId != null && exerciseId.isNotEmpty)
        ? exerciseId
        : exerciseName;
    final cachedUrl = ImageUrlCache.get(cacheKey);
    if (cachedUrl != null) {
      _backgroundImageUrl = cachedUrl;
    } else {
      _fetchBackgroundImage(exerciseName, exerciseId);
    }
  }

  /// When non-null, the hero renders a bundled per-type illustration
  /// (`assets/images/workout_types/<type>.png`) as the background layer
  /// instead of fetching the per-exercise image. See `_typeIllustrationFor`.
  String? _typeAssetPath;

  Future<void> _fetchBackgroundImage(String exerciseName,
      [String? exerciseId]) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // Pass exercise_id so the backend resolves the EXACT library row (matches
      // ExerciseImage). A name-only lookup ilikes the name and 404s / picks the
      // wrong dupe — that's why the real illustration never loaded.
      final queryParams = <String, dynamic>{};
      if (exerciseId != null && exerciseId.isNotEmpty) {
        queryParams['exercise_id'] = exerciseId;
      }
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          final cacheKey = (exerciseId != null && exerciseId.isNotEmpty)
              ? exerciseId
              : exerciseName;
          await ImageUrlCache.set(cacheKey, url);
          if (cacheKey != exerciseName) {
            await ImageUrlCache.set(exerciseName, url);
          }
          setState(() {
            _backgroundImageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
      debugPrint(
          '🏋️ [HeroWorkoutCard] no per-exercise image for "$exerciseName" '
          '(id=$exerciseId, status=${response.statusCode}) — using type art');
    } catch (e) {
      debugPrint(
          '🏋️ [HeroWorkoutCard] image fetch failed for "$exerciseName" '
          '(id=$exerciseId): $e');
    }

    if (mounted) setState(() => _isLoadingImage = false);
  }

  /// Check if a workout is "missed" — scheduled for a past date and not completed
  bool _isMissedWorkout(Workout w) {
    if (w.scheduledDate == null) return false;
    try {
      final dateStr = w.scheduledDate!.split('T')[0];
      final parts = dateStr.split('-');
      if (parts.length != 3) return false;
      final scheduledDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return scheduledDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  bool _isQuickWorkout(Workout w) {
    final method = w.generationMethod?.toLowerCase() ?? '';
    if (method == 'quick_rule_based' || method == 'ai_quick_workout') {
      return true;
    }
    // Heuristic: short duration + few exercises = quick workout
    final duration = w.durationMinutes ?? w.durationMinutesMax ?? 0;
    return duration > 0 && duration <= 15 && w.exerciseCount <= 5;
  }

  String _getWorkoutTypeLabel(String? type) {
    const typeLabels = {
      'push': 'Push Day',
      'pull': 'Pull Day',
      'legs': 'Leg Day',
      'full_body': 'Full Body',
      'upper': 'Upper Body',
      'lower': 'Lower Body',
      'core': 'Core',
      'strength': 'Strength',
      'recovery': 'Recovery',
      'cardio': 'Cardio',
      'mobility': 'Mobility',
    };
    if (type == null || type.isEmpty) return '';
    return typeLabels[type.toLowerCase()] ?? '';
  }

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'TODAY';
    // Parse date from string directly to avoid timezone shift
    final dateStr = scheduledDate.split('T')[0];
    final parts = dateStr.split('-');
    if (parts.length != 3) return 'TODAY';
    try {
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      if (date == today) {
        return 'TODAY';
      } else if (date == tomorrow) {
        return 'TOMORROW';
      } else if (date == yesterday) {
        return 'YESTERDAY';
      } else if (date.isBefore(today)) {
        // Past dates: show day name for missed workouts
        final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        return weekdays[date.weekday - 1];
      } else {
        final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
        return weekdays[date.weekday - 1];
      }
    } catch (_) {
      return 'TODAY';
    }
  }

  /// Surface 2.2 — single action sheet bound to the ⋯ icon top-right of the
  /// hero card. Hosts View Details / Regenerate / Skip / Reschedule so the
  /// card surface itself stays focused on the START button.
  Future<void> _showHeroActionSheet(BuildContext context) async {
    HapticService.selection();
    final workout = widget.workout;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.elevated
          : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(AppLocalizations.of(context).heroWorkoutCardViewDetails),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/workout/${workout.id}', extra: workout);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(AppLocalizations.of(context).workoutActionsRegenerate),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _regenerateWorkout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.skip_next_rounded),
                title: Text(AppLocalizations.of(context).workoutOptionsSkipWorkout),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _skipWorkout();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_repeat_rounded),
                title: const Text('Reschedule'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  // Routes through the existing options menu's reschedule
                  // flow if present; otherwise opens the workout detail
                  // where the user can reschedule. Fail-soft.
                  context.push('/workout/${workout.id}', extra: workout);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _regenerateWorkout() async {
    final Workout? newWorkout;
    try {
      newWorkout = await showRegenerateWorkoutSheet(
        context,
        ref,
        widget.workout,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).heroWorkoutCardCouldnTRegenerateWorkout),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (newWorkout != null && mounted) {
      // Provider refresh already handled by showRegenerateWorkoutSheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).nextWorkoutCardWorkoutRegenerated),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _skipWorkout() async {
    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutOptionsSkipWorkout,
      message: AppLocalizations.of(context).workoutOptionsThisWorkoutWillBe,
      confirmText: 'Skip',
      icon: Icons.skip_next_rounded,
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
        ref.read(workoutsProvider.notifier).silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).nextWorkoutCardWorkoutSkipped),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).heroWorkoutCardCouldNotSkipWorkout),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSkipping = false);
    }
  }

  void _repeatWorkout() {
    HapticService.medium();
    context.push('/active-workout', extra: widget.workout);
  }

  Future<void> _markAsUndone() async {
    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).heroWorkoutCardUndoCompletion,
      message: AppLocalizations.of(context).heroWorkoutCardThisWillMarkThe,
      confirmText: 'Undo',
      icon: Icons.undo_rounded,
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.uncompleteWorkout(widget.workout.id!);

      if (success && mounted) {
        // Full-set refresh so muscle/score/consistency revert too (not just
        // workouts/today).
        unawaited(refreshAfterWorkoutMutation(
            source: 'uncomplete', workoutId: widget.workout.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).heroWorkoutCardWorkoutUnmarked),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).heroWorkoutCardCouldNotUndoCompletion),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _viewSummary() {
    HapticService.selection();
    // Deep-link to the Summary pane (not the default Detail pane) so the
    // user sees the high-level summary they asked for.
    context.push('/workout-summary/${widget.workout.id}?tab=summary');
  }

  /// Share a completed workout — routes through the unified
  /// `ShareableSheet` (same gallery used on the completed-workout screen)
  /// so users get rich Wrapped / Trading Card / Receipt / Workout Details
  /// templates plus the public share-link pill (with copy + revoke
  /// guidance) in one place.
  Future<void> _shareCompletedWorkout() async {
    HapticService.light();
    final workout = widget.workout;
    final id = workout.id;
    if (id == null || id.isEmpty) return;

    final streak = ref.read(currentStreakProvider);
    final shareable = WorkoutAdapter.fromCompletion(
      ref: ref,
      workoutName: workout.name ?? 'Workout',
      durationSeconds:
          (workout.estimatedDurationMinutes ?? workout.durationMinutes ?? 45) * 60,
      plannedExercises: workout.exercises,
      totalSets: workout.exercises.fold<int>(0, (a, e) => a + (e.sets ?? 0)),
      totalReps: workout.exercises.fold<int>(
          0, (a, e) => a + ((e.sets ?? 0) * (e.reps ?? 0))),
      currentStreak: streak > 0 ? streak : null,
    );
    if (shareable == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).heroWorkoutCardNothingToShareYet)),
        );
      }
      return;
    }

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    final allowPublicLinks = ref.read(publicShareLinksProvider);
    await ShareableSheet.show(
      context,
      data: shareable,
      // When the user has disabled public share links in Privacy settings
      // we suppress the link pill entirely (no URL is ever generated, the
      // image stays clean of any link footer).
      onGenerateShareLink: !allowPublicLinks
          ? null
          : () async {
              try {
                final api = ref.read(apiClientProvider);
                final res = await api.dio.post('/workouts/$id/share-link');
                final data = res.data;
                if (data is Map && data['url'] is String) return data['url'] as String;
                return null;
              } catch (e) {
                debugPrint('❌ [HeroCard] share-link failed: $e');
                return null;
              }
            },
    );
    if (mounted) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    }
  }

  void _shareToSocial() {
    HapticService.light();
    final workout = widget.workout;

    // Route through the unified ShareableSheet so users land in the same
    // gallery (Wrapped, Trading Card, Receipt, Workout Details, etc.) used
    // everywhere else in the app — instead of the legacy CreatePostSheet
    // which bypassed the shareable templates.
    // Pull live streak so the Streaks shareable template unlocks for users
    // with an active streak (item 9 fix). PRs are passed in too so the PR
    // template unlocks when applicable. Both are best-effort — null is
    // tolerated by the adapter.
    final streak = ref.read(currentStreakProvider);
    final shareable = WorkoutAdapter.fromCompletion(
      ref: ref,
      workoutName: workout.name ?? 'Workout',
      durationSeconds: (workout.estimatedDurationMinutes ?? workout.durationMinutes ?? 45) * 60,
      plannedExercises: workout.exercises,
      totalSets: workout.exercises.fold<int>(0, (a, e) => a + (e.sets ?? 0)),
      totalReps: workout.exercises.fold<int>(0, (a, e) => a + ((e.sets ?? 0) * (e.reps ?? 0))),
      currentStreak: streak > 0 ? streak : null,
    );
    if (shareable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).heroWorkoutCardNothingToShareYet)),
      );
      return;
    }
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    ShareableSheet.show(
      context,
      data: shareable,
      onGenerateShareLink: () async {
        try {
          final api = ref.read(apiClientProvider);
          final id = workout.id;
          if (id == null || id.isEmpty) return null;
          final res = await api.dio.post('/workouts/$id/share-link');
          final data = res.data;
          if (data is Map && data['url'] is String) return data['url'] as String;
          return null;
        } catch (_) {
          return null;
        }
      },
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  Future<void> _addExercises() async {
    final workout = widget.workout;
    final updatedWorkout = await showExerciseAddSheet(
      context,
      ref,
      workoutId: workout.id!,
      workoutType: workout.type ?? 'strength',
      currentExerciseNames: workout.exercises.map((e) => e.name).toList(),
    );

    if (updatedWorkout != null && mounted) {
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      ref.read(workoutsProvider.notifier).silentRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).heroWorkoutCardExerciseAdded),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workout = widget.workout;

    // P3a — resolve the smart `WorkoutCardMode`. Modes whose UI diverges
    // from the default render (live session, wind-down, recovery-lighter,
    // luteal, equipment, fasting, pre-workout fuel, comeback, PR, body
    // ask rest, refuel, bonus, yesterday-missed, vacation, error, loading)
    // get a tailored render via `buildSmartCardOverride`. Default happy-path
    // modes (`scheduledNotStarted`, `completedToday`, `noPlan`,
    // `nextWorkoutInFuture`, `nothingScheduled`, `restDayWithCoach`) fall
    // through to the existing, shipped, polished layout below.
    //
    // Gated on date: `workoutCardModeProvider` is a singleton that reads
    // *today's* signals (intensity, fasting, fuel gap, cycle phase). Past
    // / future carousel cards do NOT share today's context, so applying
    // the override to every card produced "5 LUTEAL cards in a row" — one
    // for each upcoming day. Carousel cards (`inCarousel: true`) that
    // aren't today fall through to the default illustrated layout; global
    // modes (loading / error / vacation / overtraining) still apply.
    final dateLabel = _getScheduledDateLabel(workout.scheduledDate);
    final isTodayCard = dateLabel == 'TODAY';
    final smartMode = ref.watch(workoutCardModeProvider);
    final isGlobalMode = smartMode == WorkoutCardMode.loading ||
        smartMode == WorkoutCardMode.error ||
        smartMode == WorkoutCardMode.vacationOrPaused ||
        smartMode == WorkoutCardMode.overtrainingAlert;
    if (isTodayCard || isGlobalMode) {
      final smartOverride = buildSmartCardOverride(context, smartMode);
      if (smartOverride != null) return smartOverride;
    }

    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Phase D — phase chip on the day card. Reuses the existing
    // `cyclePhaseProvider` (wraps `GET /cycle-phase/{user_id}`), so no new
    // HTTP call. When the endpoint hasn't loaded yet, fall back to deriving
    // intensity locally from the cached `cyclePredictionProvider` using the
    // same hardcoded mapping the backend uses.
    final tracksCycle = ref.watch(hasHormonalTrackingProvider);
    final phaseInfo =
        tracksCycle ? ref.watch(cyclePhaseProvider).valueOrNull : null;
    final prediction =
        tracksCycle ? ref.watch(cyclePredictionProvider).valueOrNull : null;
    final CyclePhase? phaseToday = phaseInfo?.currentPhase ?? prediction?.currentPhase;
    final String? phaseIntensity = phaseInfo?.recommendedIntensity ??
        _localIntensityFor(phaseToday);
    final bool showPhaseChip =
        tracksCycle && dateLabel == 'TODAY' && phaseToday != null;

    final cardContent = Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Background image or gradient - fills the card
            Positioned.fill(child: _buildBackground(isDark)),

            // Gradient overlay for readability - different for light/dark mode
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.9),
                          ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),

            // Content - drives the card height
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spacer replacement - fixed top padding for badges area
                  const SizedBox(height: 4),
                  // Top row: ⋯ overflow only — date + type collapsed into the
                  // single meta line below (Surface 2.2). Action sheet hosts
                  // View Details / Regenerate / Skip / Reschedule.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showHeroActionSheet(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Phase D — phase chip on the day card. Reuses cycle
                  // colours from CyclePhaseColors. Only on TODAY when cycle
                  // tracking is on AND a phase is known.
                  if (showPhaseChip) ...[
                    const SizedBox(height: 8),
                    _PhaseRecommendationChip(
                      phase: phaseToday,
                      intensity: phaseIntensity,
                      isDark: isDark,
                    ),
                  ],

                  // Flexible top gap — the card has a fixed 296pt height and
                  // a description-bearing workout pushes the natural Column
                  // height to 300pt (4px overflow seen in prod). Letting the
                  // gap shrink keeps the visual cadence on simple workouts
                  // while absorbing the extra desc line without overflow.
                  const Flexible(
                    fit: FlexFit.loose,
                    child: SizedBox(height: 60),
                  ),

                  // Workout title - large and prominent
                  Text(
                    workout.name ?? AppLocalizations.of(context).navWorkout,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: isDark
                          ? [
                              const Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Workout description (if available)
                  if (workout.description != null && workout.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      workout.description!,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                        shadows: isDark
                            ? [
                                const Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Single meta line — Surface 2.2 collapses the dual chip
                  // pair (TODAY + Upper Body) into one period-separated row
                  // sitting under the title.
                  Builder(builder: (_) {
                    final typeLabel = _getWorkoutTypeLabel(workout.type);
                    final parts = <String>[
                      dateLabel.toLowerCase() == 'today'
                          ? 'Today'
                          : dateLabel[0].toUpperCase() +
                              dateLabel.substring(1).toLowerCase(),
                      if (typeLabel.isNotEmpty) typeLabel,
                      if ((workout.durationMinutes ?? 0) > 0)
                        '${workout.durationMinutes}m',
                      if (workout.exerciseCount > 0)
                        '${workout.exerciseCount} exercises',
                    ];
                    return Text(
                      parts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Start button - full width
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticService.medium();
                        debugPrint('🏋️ [HeroWorkoutCard] START pressed');
                        debugPrint(
                          '🏋️ [HeroWorkoutCard] workout.id=${workout.id}',
                        );
                        debugPrint(
                          '🏋️ [HeroWorkoutCard] workout.exercises.length=${workout.exercises.length}',
                        );

                        if (workout.exercises.isEmpty) {
                          debugPrint(
                            '⚠️ [HeroWorkoutCard] Workout has no exercises!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context).heroWorkoutCardWorkoutIsNotReady,
                              ),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 120,
                                left: 16,
                                right: 16,
                              ),
                            ),
                          );
                          return;
                        }
                        debugPrint(
                          '✅ [HeroWorkoutCard] Navigating to active-workout with ${workout.exercises.length} exercises',
                        );
                        ref.read(posthogServiceProvider).capture(
                          eventName: 'hero_workout_started',
                          properties: {
                            'workout_name': workout.name ?? '',
                            'workout_id': workout.id ?? '',
                            'exercise_count': workout.exercises.length,
                          },
                        );
                        context.push('/active-workout', extra: workout);
                      },
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text(
                        'START',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // Surface 2.2 — View Details / Regenerate moved into the
                  // ⋯ action sheet (top-right). The START button above is
                  // the sole visible CTA on the card surface.
                ],
              ),
            ),

            // Loading indicator for skipping or marking done
            if (_isSkipping || _isMarkingDone)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),

            // Completed workout overlay — branches on synced vs Zealova so
            // an Apple-Health import never masquerades as a completed
            // Zealova plan.
            if (widget.workout.isCompleted == true)
              Positioned.fill(
                child: _buildCompletedOverlay(workout: workout, isDark: isDark),
              ),

            // Missed workout overlay (past date, not completed).
            // Contrast strategy: heavier blur + vertical gradient scrim (dark/light
            // band in the centre where the copy lives, red-tinted at the edges to
            // preserve the "missed" affordance) + full-opacity text with a shadow
            // so the workout name stays readable over any underlying hero image.
            if (widget.workout.isCompleted != true && _isMissedWorkout(workout))
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  AppColors.error.withValues(alpha: 0.35),
                                  Colors.black.withValues(alpha: 0.62),
                                  AppColors.error.withValues(alpha: 0.35),
                                ]
                              : [
                                  AppColors.error.withValues(alpha: 0.25),
                                  Colors.white.withValues(alpha: 0.85),
                                  AppColors.error.withValues(alpha: 0.25),
                                ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.error, width: 3),
                              // Solid red fill + white X — matches the
                              // Workout-Complete green tick treatment so
                              // the icon isn't tinted-on-tinted.
                              color: AppColors.error,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 36,
                              weight: 800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).missedWorkoutBannerMissedWorkout,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: isDark
                                  ? [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              workout.name ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                shadows: isDark
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOverlayButton(
                                icon: Icons.visibility,
                                label: AppLocalizations.of(context).heroWorkoutCardViewDetails,
                                onTap: () {
                                  HapticService.selection();
                                  context.push('/workout/${workout.id}', extra: workout);
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              _buildOverlayButton(
                                icon: Icons.replay,
                                label: AppLocalizations.of(context).missedWorkoutBannerDoToday,
                                onTap: _repeatWorkout,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // When in carousel, minimal padding to show peek
    if (widget.inCarousel) {
      return GestureDetector(
        onTap: () {
          HapticService.selection();
          context.push('/workout/${workout.id}', extra: workout);
        },
        child: cardContent,
      );
    }

    // When standalone, add the original padding
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/workout/${workout.id}', extra: workout);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: cardContent,
      ),
    );
  }
}

/// Phase D — local fallback for the phase→intensity mapping the backend
/// returns at `GET /cycle-phase/{user_id}.recommended_intensity`. Used when
/// the endpoint hasn't responded yet so the chip can render off the cached
/// `cyclePredictionProvider.currentPhase`. Must stay in sync with the
/// backend mapping in `services/cycle/cycle_workouts.py`.
String? _localIntensityFor(CyclePhase? phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return 'low intensity';
    case CyclePhase.follicular:
      return 'moderate intensity';
    case CyclePhase.ovulation:
      return 'high intensity recommended';
    case CyclePhase.luteal:
      return 'moderate-to-low intensity';
    case null:
      return null;
  }
}

/// Compact "{phase} · {intensity}" chip on the today day-card. Phase-tinted
/// using `CyclePhaseColors` so it reads as part of the cycle system.
class _PhaseRecommendationChip extends StatelessWidget {
  final CyclePhase phase;
  final String? intensity;
  final bool isDark;

  const _PhaseRecommendationChip({
    required this.phase,
    required this.intensity,
    required this.isDark,
  });

  String get _phaseLabel {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = CyclePhaseColors.of(phase);
    final text = (intensity != null && intensity!.isNotEmpty)
        ? '$_phaseLabel · $intensity'
        : _phaseLabel;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 11, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

