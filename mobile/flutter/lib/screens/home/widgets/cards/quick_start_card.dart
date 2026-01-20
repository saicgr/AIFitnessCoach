import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Quick Start Card Widget
///
/// A prominent home screen card that enables a "just exercise without thinking"
/// experience. One tap takes users directly to their workout.
///
/// Features:
/// - Large "START TODAY'S WORKOUT" button with pulse animation
/// - Today's workout summary (name, duration, exercise count, muscle focus)
/// - Rest day state with "View Upcoming" link
/// - Subtle glow animation to draw attention
class QuickStartCard extends ConsumerStatefulWidget {
  final bool isDark;

  const QuickStartCard({
    super.key,
    this.isDark = true,
  });

  @override
  ConsumerState<QuickStartCard> createState() => _QuickStartCardState();
}

class _QuickStartCardState extends ConsumerState<QuickStartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _viewUpcoming() {
    HapticService.light();
    context.push('/schedule');
  }

  @override
  Widget build(BuildContext context) {
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider);
    final isDark = widget.isDark;

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: todayWorkoutAsync.when(
        loading: () => _buildLoadingState(elevatedColor, textMuted),
        error: (error, stack) =>
            _buildErrorState(elevatedColor, textColor, textMuted, error),
        data: (response) {
          if (response == null) {
            return _buildNoDataState(elevatedColor, textColor, textMuted);
          }

          // Always prioritize showing a workout (today's or next available)
          if (response.hasWorkoutToday && response.todayWorkout != null) {
            return _buildWorkoutReadyState(
              elevatedColor,
              textColor,
              textMuted,
              response.todayWorkout!,
            );
          } else if (response.nextWorkout != null) {
            // Show next workout if today is rest day
            return _buildWorkoutReadyState(
              elevatedColor,
              textColor,
              textMuted,
              response.nextWorkout!,
              isNextWorkout: true,
            );
          } else {
            return _buildRestDayState(
              elevatedColor,
              textColor,
              textMuted,
              response,
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingState(Color elevatedColor, Color textMuted) {
    final accentColor = ref.colors(context).accent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: accentColor.withValues(alpha: 0.2)),
          right: BorderSide(color: accentColor.withValues(alpha: 0.2)),
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading today\'s workout...',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    Object error,
  ) {
    final accentColor = ref.colors(context).accent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          right: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          bottom: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'Could not load workout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(todayWorkoutProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(
    Color elevatedColor,
    Color textColor,
    Color textMuted,
  ) {
    final accentColor = ref.colors(context).accent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
          right: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
          bottom: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, color: textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            'No workouts scheduled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a workout program to get started!',
            style: TextStyle(fontSize: 14, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutReadyState(
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    TodayWorkoutSummary workout, {
    bool isNextWorkout = false,
  }) {
    final typeColor = AppColors.getWorkoutTypeColor(workout.type);
    final accentColor = ref.colors(context).accent;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  elevatedColor,
                  elevatedColor.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: _glowAnimation.value),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: _glowAnimation.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => _startWorkoutFromSummary(workout),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with "TODAY" badge
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final accentColor = ref.colors(context).accent;
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNextWorkout ? Icons.event : Icons.today,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNextWorkout ? 'TOMORROW' : 'TODAY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      workout.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Workout name
              Text(
                workout.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStatPill(
                    Icons.timer_outlined,
                    workout.formattedDurationShort,
                    textMuted,
                  ),
                  const SizedBox(width: 12),
                  _buildStatPill(
                    Icons.fitness_center,
                    '${workout.exerciseCount} exercises',
                    textMuted,
                  ),
                ],
              ),

              // Muscle focus chips
              if (workout.primaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: workout.primaryMuscles.take(3).map((muscle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        muscle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.purple.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Big START button
              Builder(
                builder: (context) {
                  final accentColor = ref.colors(context).accent;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startWorkoutFromSummary(workout),
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text(
                        'START WORKOUT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayState(
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    TodayWorkoutResponse response,
  ) {
    final accentColor = ref.colors(context).accent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
          right: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
          bottom: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rest day icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa,
              color: AppColors.purple,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Rest day message
          Text(
            'Rest Day',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.restDayMessage ?? 'Take it easy today!',
            style: TextStyle(fontSize: 14, color: textMuted),
            textAlign: TextAlign.center,
          ),

          // Next workout preview
          if (response.nextWorkout != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: ${response.nextWorkout!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          response.daysUntilNext == 1
                              ? 'Tomorrow'
                              : 'In ${response.daysUntilNext} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // View upcoming button
          TextButton.icon(
            onPressed: _viewUpcoming,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('View Upcoming'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textMuted),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkoutFromSummary(TodayWorkoutSummary summary) async {
    HapticService.medium();

    // Log quick start tap for analytics
    ref.read(workoutRepositoryProvider).logQuickStart(summary.id);

    // Fetch full workout data and navigate
    final repository = ref.read(workoutRepositoryProvider);
    final workout = await repository.getWorkout(summary.id);

    if (workout != null && mounted) {
      context.push('/active-workout', extra: workout);
    }
  }
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
