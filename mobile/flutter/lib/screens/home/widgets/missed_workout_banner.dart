import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/scheduling_provider.dart';
import '../../../data/repositories/scheduling_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../workout/widgets/reschedule_sheet.dart';

/// Banner showing missed workout(s) with quick action buttons
///
/// Displays when user has missed workout(s) from the past 3 days.
/// Provides quick actions: "Do Today" and "Skip It"
class MissedWorkoutBanner extends ConsumerStatefulWidget {
  const MissedWorkoutBanner({super.key});

  @override
  ConsumerState<MissedWorkoutBanner> createState() => _MissedWorkoutBannerState();
}

class _MissedWorkoutBannerState extends ConsumerState<MissedWorkoutBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticService.light();
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isDismissed = true);
      }
    });
  }

  Future<void> _handleDoToday(MissedWorkout workout) async {
    HapticService.medium();

    // Show reschedule sheet for more options
    final result = await showRescheduleSheet(
      context,
      ref,
      workout: workout,
    );

    if (result == true && mounted) {
      // Successfully rescheduled, dismiss banner
      _dismiss();
    }
  }

  Future<void> _handleSkip(MissedWorkout workout) async {
    HapticService.light();

    // Show skip reason picker
    final skipReasons = await ref.read(skipReasonsProvider.future);

    if (!mounted) return;

    final selectedReason = await showModalBottomSheet<SkipReasonCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _SkipReasonSheet(
        workout: workout,
        reasons: skipReasons,
      ),
    );

    if (selectedReason != null && mounted) {
      final notifier = ref.read(schedulingActionProvider.notifier);
      final success = await notifier.skipWorkout(
        workout.id,
        reasonCategory: selectedReason.id,
      );

      if (success && mounted) {
        _dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout skipped'),
            backgroundColor: AppColors.elevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final missedWorkoutsAsync = ref.watch(missedWorkoutsProvider);
    final actionState = ref.watch(schedulingActionProvider);

    return missedWorkoutsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (workouts) {
        if (workouts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show the most recent missed workout
        final workout = workouts.first;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: _buildBanner(context, workout, actionState.isLoading),
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, MissedWorkout workout, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and dismiss button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: AppColors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missed Workout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workout.missedDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dismiss button
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Workout details
              Text(
                "You missed ${workout.dayPossessive} ${workout.name}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              // Workout info chips
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.fitness_center,
                    label: workout.type,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${workout.durationMinutes} min',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.format_list_numbered,
                    label: '${workout.exercisesCount} exercises',
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Do Today button (primary)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _handleDoToday(workout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Do Today',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Skip button (secondary)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _handleSkip(workout),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                        ),
                      ),
                      child: const Text(
                        'Skip It',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Show count of other missed workouts if more than 1
              if (ref.read(missedWorkoutsProvider).valueOrNull?.length != null &&
                  ref.read(missedWorkoutsProvider).valueOrNull!.length > 1) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '+${ref.read(missedWorkoutsProvider).valueOrNull!.length - 1} more missed workouts',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small info chip for workout details
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting skip reason
class _SkipReasonSheet extends StatelessWidget {
  final MissedWorkout workout;
  final List<SkipReasonCategory> reasons;

  const _SkipReasonSheet({
    required this.workout,
    required this.reasons,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Why are you skipping?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps us adjust your schedule',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Reason options
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reasons.length,
              itemBuilder: (context, index) {
                final reason = reasons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticService.light();
                        Navigator.pop(context, reason);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (reason.emoji != null) ...[
                              Text(
                                reason.emoji!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                reason.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: textSecondary,
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

          // Skip without reason button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {
                // Return a generic "other" reason
                Navigator.pop(
                  context,
                  SkipReasonCategory(id: 'other', displayName: 'Other'),
                );
              },
              child: Text(
                'Skip without reason',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
