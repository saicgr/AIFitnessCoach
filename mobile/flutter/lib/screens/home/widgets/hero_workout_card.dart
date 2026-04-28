import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../../shareables/shareable_sheet.dart';
import '../../../shareables/adapters/workout_adapter.dart';
import '../../../data/providers/consistency_provider.dart';


part 'hero_workout_card_part_completed_workout_hero_card.dart';
part 'hero_workout_card_part_stat_chip.dart';

part 'hero_workout_card_ui.dart';

part 'hero_workout_card_ext.dart';


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

  @override
  void initState() {
    super.initState();
    // Check cache synchronously to avoid loading flash
    final exercises = widget.workout.exercises;
    if (exercises.isEmpty) {
      _isLoadingImage = false;
    } else {
      final exerciseName = exercises.first.name;
      if (exerciseName.isEmpty || exerciseName == 'Exercise') {
        _isLoadingImage = false;
      } else {
        final cachedUrl = ImageUrlCache.get(exerciseName);
        if (cachedUrl != null) {
          _backgroundImageUrl = cachedUrl;
          _isLoadingImage = false;
        } else {
          _fetchBackgroundImage(exerciseName);
        }
      }
    }
  }

  Future<void> _fetchBackgroundImage(String exerciseName) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          await ImageUrlCache.set(exerciseName, url);
          setState(() {
            _backgroundImageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (_) {}

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

  Future<void> _regenerateWorkout() async {
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    if (newWorkout != null && mounted) {
      // Provider refresh already handled by showRegenerateWorkoutSheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout regenerated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _skipWorkout() async {
    final confirm = await AppDialog.destructive(
      context,
      title: 'Skip Workout?',
      message: 'This workout will be marked as skipped.',
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
            const SnackBar(
              content: Text('Workout skipped'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not skip workout'),
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
      title: 'Undo Completion?',
      message: 'This will mark the workout as not done.',
      confirmText: 'Undo',
      icon: Icons.undo_rounded,
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.uncompleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
        ref.read(workoutsProvider.notifier).silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout unmarked'),
              backgroundColor: AppColors.textMuted,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not undo completion'),
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

  Future<void> _shareCompletedWorkout() async {
    HapticService.light();
    final id = widget.workout.id;
    if (id == null || id.isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/workouts/$id/share-link');
      final data = res.data;
      String? url;
      if (data is Map && data['url'] is String) url = data['url'] as String;
      if (!mounted || url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not create share link')),
          );
        }
        return;
      }
      await Share.share(
        '${widget.workout.name ?? 'My workout'} — ${Branding.appName}\n$url',
        subject: '${Branding.appName} workout',
      );
    } catch (e) {
      debugPrint('❌ [HeroCard] share-link failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't generate share link — please try again"),
          ),
        );
      }
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
        const SnackBar(content: Text('Nothing to share yet — log a workout first')),
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
        const SnackBar(
          content: Text('Exercise added!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workout = widget.workout;

    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final dateLabel = _getScheduledDateLabel(workout.scheduledDate);

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
                  // Top row: Date label + Type chip + Menu button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chip opacity bumped (0.4→0.7 dark, 0.8→0.95 light)
                          // and font size 12→13 / weight w700→w800 so the
                          // labels stay legible over light-skeleton hero
                          // illustrations (the skeleton flesh tones drop the
                          // contrast on the previous translucent chip).
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (_getWorkoutTypeLabel(workout.type).isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                _getWorkoutTypeLabel(workout.type),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                          // Quick workout badge
                          if (_isQuickWorkout(workout)) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: isDark ? 0.4 : 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Quick',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark ? accentColor : accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Overflow menu — bumped 36→44pt to meet WCAG 2.5.8
                      // touch-target minimum + matching opacity bump.
                      GestureDetector(
                        onTap: _showOptionsMenu,
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
                    workout.name ?? 'Workout',
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

                  // Stats row
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      // Meta-line readability: bumped color opacity 0.85→1.0
                      // and weight w500→w700 so duration / exercise count
                      // pass WCAG AA against the hero gradient.
                      Text(
                        workout.formattedDurationShort,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workout.exerciseCount > 0
                            ? '${workout.exerciseCount} exercises'
                            : 'Ready to start',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
                              content: const Text(
                                'Workout is not ready yet. Please try regenerating.',
                              ),
                              backgroundColor: Colors.orange,
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
                  const SizedBox(height: 8),

                  // View Details and Regenerate row
                  Row(
                    children: [
                      // View Details / Regenerate buttons — opacity bumped
                      // (0.10→0.18 dark / 0.05→0.10 light), font 13→14 +
                      // weight w500→w700, vertical padding 8→11 so the
                      // button reaches a 44pt hit region. Icon stays 16pt
                      // but the label now passes WCAG AA contrast against
                      // the hero gradient.
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            context.push('/workout/${workout.id}', extra: workout);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _regenerateWorkout,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Regenerate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

            // Completed workout overlay
            if (widget.workout.isCompleted == true)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: AppColors.success.withValues(alpha: isDark ? 0.25 : 0.2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.success, width: 3),
                              // Solid green fill + white checkmark — the
                              // previous translucent-green fill made the
                              // green checkmark blend into the background
                              // and vanish.
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 36,
                              weight: 800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Workout Complete',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workout.name ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOverlayButton(icon: Icons.replay, label: 'Repeat', onTap: _repeatWorkout, isDark: isDark),
                              if (widget.workout.completionMethod == 'marked_done') ...[
                                const SizedBox(width: 12),
                                _buildOverlayButton(icon: Icons.undo, label: 'Undo', onTap: _markAsUndone, isDark: isDark),
                              ],
                              const SizedBox(width: 12),
                              _buildOverlayButton(icon: Icons.bar_chart, label: 'Summary', onTap: _viewSummary, isDark: isDark),
                              const SizedBox(width: 12),
                              _buildOverlayButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: _shareCompletedWorkout, isDark: isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                            'Missed Workout',
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
                                label: 'View Details',
                                onTap: () {
                                  HapticService.selection();
                                  context.push('/workout/${workout.id}', extra: workout);
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              _buildOverlayButton(
                                icon: Icons.replay,
                                label: 'Do Today',
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
