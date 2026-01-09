import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/models/habit.dart';
import '../../../../data/providers/habit_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// ============================================================
/// HABITS CARD
/// Home screen widget for displaying and tracking daily habits
/// Uses real API integration via habitsProvider
/// ============================================================
class HabitsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const HabitsCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = AppColors.teal;

    // No user logged in
    if (userId == null) {
      return _buildEmptyState(
        context,
        elevatedColor,
        textColor,
        textMuted,
        accentColor,
      );
    }

    final habitsState = ref.watch(habitsProvider(userId));

    // Loading state
    if (habitsState.isLoading && habitsState.habits.isEmpty) {
      return _buildLoadingSkeleton(elevatedColor, textMuted, accentColor);
    }

    // Error state
    if (habitsState.error != null && habitsState.habits.isEmpty) {
      return _buildErrorState(
        context,
        ref,
        userId,
        elevatedColor,
        textColor,
        textMuted,
        accentColor,
        habitsState.error!,
      );
    }

    // Empty state
    if (!habitsState.hasHabits) {
      return _buildEmptyState(
        context,
        elevatedColor,
        textColor,
        textMuted,
        accentColor,
      );
    }

    // Main content
    return _buildMainContent(
      context,
      ref,
      userId,
      habitsState,
      elevatedColor,
      textColor,
      textMuted,
      accentColor,
    );
  }

  /// Loading skeleton state
  Widget _buildLoadingSkeleton(
    Color elevatedColor,
    Color textMuted,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.limeGreen, width: 4),
            top: BorderSide(color: accentColor.withValues(alpha: 0.2)),
            right: BorderSide(color: accentColor.withValues(alpha: 0.2)),
            bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                _buildSkeletonBox(24, 24, 8, textMuted),
                const SizedBox(width: 10),
                _buildSkeletonBox(120, 16, 4, textMuted),
                const Spacer(),
                _buildSkeletonBox(40, 40, 20, textMuted),
              ],
            ),
            const SizedBox(height: 16),
            // Habit items skeleton
            for (int i = 0; i < 3; i++) ...[
              _buildHabitItemSkeleton(textMuted),
              if (i < 2) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(
      double width, double height, double radius, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildHabitItemSkeleton(Color color) {
    return Row(
      children: [
        _buildSkeletonBox(28, 28, 8, color),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonBox(double.infinity, 14, 4, color)),
        const SizedBox(width: 12),
        _buildSkeletonBox(32, 32, 16, color),
      ],
    );
  }

  /// Error state widget
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    Color accentColor,
    String error,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.limeGreen, width: 4),
            top: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            right: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            bottom: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load habits',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: TextStyle(fontSize: 12, color: AppColors.error),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(habitsProvider(userId).notifier).refresh();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state with template suggestions
  Widget _buildEmptyState(
    BuildContext context,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/habits');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.limeGreen, width: 4),
              top: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              right: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              bottom: BorderSide(color: accentColor.withValues(alpha: 0.3)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.track_changes,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Build Daily Habits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Start tracking daily habits to build consistency and achieve your goals.',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Template suggestions
              Text(
                'Quick Start:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HabitTemplate.defaults.take(4).map((template) {
                  return _buildTemplateChip(context, template, textColor);
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Add button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.medium();
                    context.push('/habits');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Your First Habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(
      BuildContext context, HabitTemplate template, Color textColor) {
    final templateColor = _parseColor(template.color);
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/habits');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: templateColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: templateColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(template.icon),
              size: 14,
              color: templateColor,
            ),
            const SizedBox(width: 6),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: templateColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Main content with habits
  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    String userId,
    HabitsState habitsState,
    Color elevatedColor,
    Color textColor,
    Color textMuted,
    Color accentColor,
  ) {
    final uncompletedHabits = habitsState.pendingHabits.take(3).toList();
    final longestStreakHabit = _getLongestStreakHabit(habitsState.habits);
    final hasMoreHabits = habitsState.habits.length > 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/habits');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.limeGreen, width: 4),
              top: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              right: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              bottom: BorderSide(color: accentColor.withValues(alpha: 0.3)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with progress
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.track_changes,
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
                          "Today's Habits",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${habitsState.completedToday}/${habitsState.totalHabits} completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular progress indicator
                  _buildProgressIndicator(
                    habitsState.completionPercentage / 100,
                    habitsState.completedToday,
                    habitsState.totalHabits,
                    textColor,
                    textMuted,
                    accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quick toggle habits (up to 3 uncompleted)
              if (uncompletedHabits.isNotEmpty) ...[
                ...uncompletedHabits.map((habit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildHabitToggleRow(
                        context, ref, userId, habit, textColor, textMuted),
                  );
                }),
              ] else ...[
                // All completed state
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All habits completed!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                              ),
                            ),
                            Text(
                              'Great job keeping up your streaks',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // View All button if more habits exist
              if (hasMoreHabits) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      HapticService.light();
                      context.push('/habits');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All ${habitsState.totalHabits} Habits',
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: accentColor, size: 16),
                      ],
                    ),
                  ),
                ),
              ],

              // Streak highlight
              if (longestStreakHabit != null &&
                  longestStreakHabit.currentStreak > 0) ...[
                const SizedBox(height: 8),
                _buildStreakHighlight(
                  longestStreakHabit,
                  textColor,
                  textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get habit with longest streak
  HabitWithStatus? _getLongestStreakHabit(List<HabitWithStatus> habits) {
    if (habits.isEmpty) return null;
    return habits.reduce(
      (a, b) => a.currentStreak > b.currentStreak ? a : b,
    );
  }

  /// Circular progress indicator
  Widget _buildProgressIndicator(
    double progress,
    int completed,
    int total,
    Color textColor,
    Color textMuted,
    Color accentColor,
  ) {
    final isComplete = completed == total && total > 0;
    final ringColor = isComplete ? AppColors.green : accentColor;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 4,
              backgroundColor: textMuted.withValues(alpha: 0.2),
              color: ringColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage text
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual habit toggle row
  Widget _buildHabitToggleRow(
    BuildContext context,
    WidgetRef ref,
    String userId,
    HabitWithStatus habit,
    Color textColor,
    Color textMuted,
  ) {
    final habitColor = _parseColor(habit.color);

    return Row(
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: habitColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              _getIconData(habit.icon),
              color: habitColor,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Habit name and streak
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (habit.currentStreak > 0)
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 12,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Toggle button
        GestureDetector(
          onTap: () {
            HapticService.medium();
            ref.read(habitsProvider(userId).notifier).toggleHabit(
                  habit.id,
                  !habit.todayCompleted,
                );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: habit.todayCompleted
                  ? AppColors.green
                  : habitColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: habit.todayCompleted
                    ? AppColors.green
                    : habitColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(
              habit.todayCompleted ? Icons.check : Icons.add,
              color: habit.todayCompleted ? Colors.white : habitColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// Streak highlight banner
  Widget _buildStreakHighlight(
    HabitWithStatus habit,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.15),
            AppColors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            '\u{1F525}', // Fire emoji
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: textMuted),
                children: [
                  TextSpan(
                    text: '${habit.currentStreak} day streak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  const TextSpan(text: ' on '),
                  TextSpan(
                    text: '"${habit.name}"',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse hex color string to Color
  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.teal;
    }
  }

  /// Get IconData from icon name string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_run':
        return Icons.directions_run;
      case 'water_drop':
        return Icons.water_drop;
      case 'restaurant':
        return Icons.restaurant;
      case 'bedtime':
        return Icons.bedtime;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'menu_book':
        return Icons.menu_book;
      case 'medication':
        return Icons.medication;
      case 'no_drinks':
        return Icons.no_drinks;
      case 'eco':
        return Icons.eco;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'spa':
        return Icons.spa;
      case 'edit_note':
        return Icons.edit_note;
      case 'do_not_disturb':
        return Icons.do_not_disturb;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'phone_disabled':
        return Icons.phone_disabled;
      case 'track_changes':
        return Icons.track_changes;
      default:
        return Icons.check_circle;
    }
  }
}
