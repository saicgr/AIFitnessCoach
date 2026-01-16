import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'regenerate_workout_sheet.dart';

/// Hero workout card - prominent action-focused workout display
/// Features a big START button as the primary action
class HeroWorkoutCard extends ConsumerStatefulWidget {
  final Workout workout;

  const HeroWorkoutCard({
    super.key,
    required this.workout,
  });

  @override
  ConsumerState<HeroWorkoutCard> createState() => _HeroWorkoutCardState();
}

class _HeroWorkoutCardState extends ConsumerState<HeroWorkoutCard> {
  bool _isSkipping = false;

  String _getScheduledDateLabel(String? scheduledDate) {
    if (scheduledDate == null) return 'Scheduled';
    try {
      final date = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final workoutDate = DateTime(date.year, date.month, date.day);

      if (workoutDate == today) {
        return 'Today';
      } else if (workoutDate == tomorrow) {
        return 'Tomorrow';
      } else {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[date.weekday - 1];
      }
    } catch (_) {
      return 'Scheduled';
    }
  }

  Future<void> _regenerateWorkout() async {
    final newWorkout = await showRegenerateWorkoutSheet(
      context,
      ref,
      widget.workout,
    );

    if (newWorkout != null && mounted) {
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout regenerated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _skipWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Skip Workout?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This workout will be marked as skipped.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSkipping = true);

    final repo = ref.read(workoutRepositoryProvider);
    try {
      final success = await repo.deleteWorkout(widget.workout.id!);

      if (success && mounted) {
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Use dark background for hero card - pureBlack in dark mode, elevated (light gray) in light mode
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;

    final workout = widget.workout;
    final dateLabel = _getScheduledDateLabel(workout.scheduledDate);
    final isToday = dateLabel == 'Today';

    // Get accent color from provider for dynamic accent
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: isToday ? 0.4 : 0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            // Main colored glow shadow
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            // Subtle depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Date badge - monochrome styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workout name - tappable
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/workout/${workout.id}');
                    },
                    child: Text(
                      workout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${workout.durationMinutes ?? 45} min',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.fitness_center,
                        // Show exercise count or fallback to generic label if 0
                        label: workout.exerciseCount > 0
                            ? '${workout.exerciseCount} exercises'
                            : 'Ready to start',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Big START button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        debugPrint('🏋️ [HeroWorkoutCard] START pressed');
                        debugPrint('🏋️ [HeroWorkoutCard] workout.id=${workout.id}');
                        debugPrint('🏋️ [HeroWorkoutCard] workout.exercisesJson type=${workout.exercisesJson?.runtimeType}');
                        debugPrint('🏋️ [HeroWorkoutCard] workout.exercises.length=${workout.exercises.length}');
                        debugPrint('🏋️ [HeroWorkoutCard] workout.exerciseCount=${workout.exerciseCount}');

                        // Check if workout has exercises before navigating
                        if (workout.exercises.isEmpty) {
                          debugPrint('⚠️ [HeroWorkoutCard] Workout has no exercises! exercisesJson=${workout.exercisesJson}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Workout is not ready yet. Please try regenerating.'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                            ),
                          );
                          return;
                        }
                        debugPrint('✅ [HeroWorkoutCard] Navigating to active-workout with ${workout.exercises.length} exercises');
                        context.push('/active-workout', extra: workout);
                      },
                      style: ElevatedButton.styleFrom(
                        // Monochrome: white button in dark mode, black button in light mode
                        backgroundColor: accentColor,
                        // Contrast text: black on white button, white on black button
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'START',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Regenerate button
                      TextButton.icon(
                        onPressed: () {
                          HapticService.light();
                          _regenerateWorkout();
                        },
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        label: Text(
                          'Regenerate',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: textSecondary.withValues(alpha: 0.3),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      // Skip button
                      TextButton.icon(
                        onPressed: _isSkipping ? null : () {
                          HapticService.light();
                          _skipWorkout();
                        },
                        icon: _isSkipping
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: textSecondary,
                                ),
                              )
                            : Icon(
                                Icons.skip_next_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                        label: Text(
                          'Skip',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stat chip showing icon + label
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Card shown when today's workout is already completed
/// Shows completion status and the next scheduled workout
class CompletedWorkoutHeroCard extends ConsumerWidget {
  final Workout completedWorkout;
  final Workout nextWorkout;
  final int daysUntilNext;

  const CompletedWorkoutHeroCard({
    super.key,
    required this.completedWorkout,
    required this.nextWorkout,
    required this.daysUntilNext,
  });

  String _getNextWorkoutLabel() {
    if (daysUntilNext == 1) return 'Tomorrow';
    if (daysUntilNext == 2) return 'In 2 days';
    return 'In $daysUntilNext days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    // Use dark background for hero card - pureBlack in dark mode, elevated (light gray) in light mode
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    // Get accent color from provider for dynamic accent
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Completed workout banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s workout complete!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Next workout content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Date badge for next workout - monochrome
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getNextWorkoutLabel().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Next workout name - tappable
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      GoRouter.of(context).push('/workout/${nextWorkout.id}');
                    },
                    child: Text(
                      nextWorkout.name ?? 'Workout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${nextWorkout.durationMinutes ?? 45} min',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${nextWorkout.exerciseCount} exercises',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Preview button (not start since it's not today) - monochrome
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticService.medium();
                        GoRouter.of(context).push('/workout/${nextWorkout.id}');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_outlined, size: 22, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'PREVIEW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card shown when generating/loading workouts
class GeneratingHeroCard extends ConsumerStatefulWidget {
  final String? message;
  final String? subtitle;

  const GeneratingHeroCard({super.key, this.message, this.subtitle});

  @override
  ConsumerState<GeneratingHeroCard> createState() => _GeneratingHeroCardState();
}

class _GeneratingHeroCardState extends ConsumerState<GeneratingHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 [GeneratingHeroCard] build() called with message: ${widget.message}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use dark background for hero card - pureBlack in dark mode, elevated (light gray) in light mode
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Get accent color from provider for dynamic accent
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        children: [
          // Main card container
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator with glow effect
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Spinner
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: accentColor,
                    backgroundColor: accentColor.withValues(alpha: 0.2),
                  ),
                ),
                // Center icon
                Icon(
                  Icons.fitness_center_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.message ?? 'Loading your workout...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle ?? 'This may take a moment',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Shimmer loading bar
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  height: 4,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: accentColor.withValues(alpha: 0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Positioned(
                          left: _shimmerController.value * 140 - 40,
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  accentColor,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
            ),
          ),
          // Left accent bar overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
