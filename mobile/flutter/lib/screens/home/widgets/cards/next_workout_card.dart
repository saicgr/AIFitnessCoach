import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/difficulty_utils.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/image_url_cache.dart';
import '../components/stat_badge.dart';
import '../../../../widgets/app_dialog.dart';
import '../regenerate_workout_sheet.dart';
import 'exercise_image_thumbnail.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// The main workout card showing the next scheduled workout
/// Displays workout details with start, customize, and skip actions
class NextWorkoutCard extends ConsumerStatefulWidget {
  /// The workout to display
  final Workout workout;

  /// Callback when start button is pressed
  final VoidCallback onStart;

  /// Whether to show the "Upcoming" link (hide on Workouts screen)
  final bool showUpcomingLink;

  const NextWorkoutCard({
    super.key,
    required this.workout,
    required this.onStart,
    this.showUpcomingLink = true,
  });

  @override
  ConsumerState<NextWorkoutCard> createState() => _NextWorkoutCardState();
}

class _NextWorkoutCardState extends ConsumerState<NextWorkoutCard> {
  bool _isSkipping = false;

  @override
  void initState() {
    super.initState();
    _preFetchExerciseImages();
  }

  void _preFetchExerciseImages() {
    final exercises = widget.workout.exercises;
    if (exercises.isEmpty) return;
    final names = exercises.map((e) => e.name).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return;
    // Batch pre-fetch all exercise image URLs in one API call
    final apiClient = ref.read(apiClientProvider);
    ImageUrlCache.batchPreFetch(names, apiClient);
  }

  bool _isQuickWorkout(Workout w) {
    final method = w.generationMethod?.toLowerCase() ?? '';
    if (method == 'quick_rule_based' || method == 'ai_quick_workout') {
      return true;
    }
    final duration = w.durationMinutes ?? w.durationMinutesMax ?? 0;
    return duration > 0 && duration <= 15 && w.exerciseCount <= 5;
  }

  String _formatTypeLabel(String? type) {
    const typeLabels = {
      'push': 'Push',
      'pull': 'Pull',
      'legs': 'Legs',
      'full_body': 'Full Body',
      'upper_body': 'Upper Body',
      'upper': 'Upper Body',
      'lower_body': 'Lower Body',
      'lower': 'Lower Body',
      'core': 'Core',
      'strength': 'Strength',
      'recovery': 'Recovery',
      'cardio': 'Cardio',
      'mobility': 'Mobility',
      'stretch': 'Stretch',
    };
    if (type == null || type.isEmpty) return 'Strength';
    return typeLabels[type.toLowerCase()] ?? type.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'Scheduled';
    // Parse date from string directly to avoid timezone shift
    final dateStr = scheduledDate.split('T')[0];
    final parts = dateStr.split('-');
    if (parts.length != 3) return 'Scheduled';
    try {
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (date == today) {
        return 'Today';
      } else if (date == tomorrow) {
        return 'Tomorrow';
      } else {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      }
    } catch (_) {
      return 'Scheduled';
    }
  }

  Future<void> _regenerateWorkout() async {
    // Show the regenerate customization sheet
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    // If a new workout was returned, refresh the list
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
    // Show confirmation dialog
    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutOptionsSkipWorkout,
      message: AppLocalizations.of(context).nextWorkoutCardThisWorkoutWillBe,
      confirmText: 'Skip',
      icon: Icons.skip_next_rounded,
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      // Reschedule to mark as skipped - move to yesterday so it's "past"
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        // Refresh workouts silently (no loading flash)
        await ref.read(workoutsProvider.notifier).silentRefresh();
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
            content: Text(AppLocalizations.of(context).nextWorkoutCardCouldNotSkipWorkout),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSkipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final workout = widget.workout;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final exercises = workout.exercises;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              elevatedColor,
              elevatedColor.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badges row with View Upcoming link
                  Row(
                    children: [
                      // Badges - tappable to view workout detail
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticService.selection();
                            context.push('/workout/${workout.id}', extra: workout);
                          },
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Scheduled date badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getScheduledDateLabel(workout.scheduledDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Workout type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTypeLabel(workout.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Quick workout badge
                              if (_isQuickWorkout(workout))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).quickActionsRowQuick,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DifficultyUtils.getDisplayName(workout.difficulty ?? 'medium'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // View Upcoming link (hidden on Workouts screen)
                      if (widget.showUpcomingLink)
                        GestureDetector(
                          onTap: () {
                            HapticService.light();
                            // Navigate to Workouts tab and scroll to upcoming section
                            context.go('/workouts?scrollTo=upcoming');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context).workoutsUpcoming,
                                style: TextStyle(
                                  color: ref.colors(context).accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: ref.colors(context).accent,
                                size: 16,
                              ),
                            ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title - tappable to view workout detail
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}', extra: workout);
                    },
                    child: Text(
                      workout.name ?? AppLocalizations.of(context).navWorkout,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row - tappable to view workout detail
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}', extra: workout);
                    },
                    child: Row(
                      children: [
                        StatPill(
                          icon: Icons.timer_outlined,
                          value: workout.formattedDurationShort,
                        ),
                        const SizedBox(width: 12),
                        StatPill(
                          icon: Icons.fitness_center,
                          value: '${workout.exerciseCount} exercises',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons row - Start and quick actions
                  Row(
                    children: [
                      // Main Start button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticService.medium();
                            context.push('/active-workout', extra: workout);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: Text(AppLocalizations.of(context).buttonStart),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Regenerate icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticService.light();
                            _regenerateWorkout();
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          color: accentColor,
                          tooltip: AppLocalizations.of(context).workoutActionsRegenerate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip icon button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isSkipping
                              ? null
                              : () {
                                  HapticService.light();
                                  _skipWorkout();
                                },
                          icon: _isSkipping
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.skip_next, size: 20),
                          color: AppColors.textMuted,
                          tooltip: AppLocalizations.of(context).onboardingSkip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exercise preview strip at bottom - tappable to view workout
            // detail. Tiles shrink-to-fit so the full count is always
            // visible (no hidden off-screen tiles). Beyond 14 tiles we
            // truncate to "12 + (+N more)" so individual tiles stay
            // readable.
            if (exercises.isNotEmpty)
              GestureDetector(
                onTap: () {
                  HapticService.selection();
                  context.push('/workout/${workout.id}', extra: workout);
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const hPad = 12.0;
                      const gap = 8.0;
                      const maxTile = 44.0;
                      const minTile = 28.0;
                      final available = constraints.maxWidth - hPad * 2;
                      final total = exercises.length;
                      // Reserve a slot for the "+N more" badge if we
                      // would otherwise shrink below the readability floor.
                      double tileFor(int n) =>
                          (available - (n - 1) * gap) / n;
                      var visible = total;
                      var tileSize = tileFor(visible).clamp(minTile, maxTile);
                      if (tileFor(total) < minTile) {
                        // Find the largest `visible` count whose tile size
                        // is >= minTile, leaving room for the +N badge.
                        visible = ((available + gap) / (minTile + gap))
                            .floor()
                            .clamp(1, total - 1);
                        tileSize =
                            tileFor(visible + 1).clamp(minTile, maxTile);
                      }
                      final remaining = total - visible;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: 8,
                        ),
                        itemCount: visible + (remaining > 0 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < visible) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == visible - 1 && remaining == 0
                                    ? 0
                                    : gap,
                              ),
                              child: ExerciseImageThumbnail(
                                exercise: exercises[index],
                                size: tileSize.toDouble(),
                              ),
                            );
                          }
                          return _MoreBadge(
                            count: remaining,
                            size: tileSize.toDouble(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
    );
  }
}

class _MoreBadge extends StatelessWidget {
  final int count;
  final double size;
  const _MoreBadge({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
