import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/models/habit.dart';
import '../../../../data/providers/habit_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Habits Tile Card - Shows today's habits with quick toggle
/// Displays habit checklist with completion progress
class HabitsTileCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const HabitsTileCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get user ID
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return _buildNotLoggedIn(elevatedColor, textMuted, cardBorder);
    }

    final habitsState = ref.watch(habitsProvider(userId));
    final habits = habitsState.habits;
    final completedCount = habitsState.completedToday;
    final totalCount = habitsState.totalHabits;
    final isLoading = habitsState.isLoading;

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        completedCount: completedCount,
        totalCount: totalCount,
        isLoading: isLoading,
      );
    }

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: isLoading
          ? _buildLoadingState(textMuted)
          : habits.isEmpty
              ? _buildEmptyState(context, textMuted)
              : _buildContentState(
                  context,
                  ref,
                  userId: userId,
                  textColor: textColor,
                  textMuted: textMuted,
                  habits: habits,
                  completedCount: completedCount,
                  totalCount: totalCount,
                ),
    );
  }

  Widget _buildNotLoggedIn(Color elevatedColor, Color textMuted, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: textMuted, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sign in to track habits',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required int completedCount,
    required int totalCount,
    required bool isLoading,
  }) {
    final allDone = totalCount > 0 && completedCount >= totalCount;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/habits');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: allDone
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: allDone ? AppColors.success : textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isLoading
                  ? '...'
                  : totalCount > 0
                      ? '$completedCount/$totalCount'
                      : 'No habits',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: allDone ? AppColors.success : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading habits...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              'Habits',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Build healthy habits',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            HapticService.light();
            context.push('/habits');
          },
          icon: Icon(Icons.add, size: 18),
          label: Text('Add Habit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildContentState(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required Color textColor,
    required Color textMuted,
    required List<HabitWithStatus> habits,
    required int completedCount,
    required int totalCount,
  }) {
    // Show only first 3 habits in tile, sorted by completion status
    final sortedHabits = [...habits]
      ..sort((a, b) {
        // Incomplete first, then completed
        if (a.todayCompleted != b.todayCompleted) {
          return a.todayCompleted ? 1 : -1;
        }
        return 0;
      });
    final displayHabits = sortedHabits.take(3).toList();
    final remainingCount = habits.length - 3;
    final allDone = totalCount > 0 && completedCount >= totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(
              allDone ? Icons.check_circle : Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Today's Habits",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: allDone
                    ? AppColors.success.withValues(alpha: 0.15)
                    : textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: allDone ? AppColors.success : textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticService.light();
                context.push('/habits');
              },
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Habit list
        ...displayHabits.map((habit) => _HabitItem(
          habit: habit,
          textColor: textColor,
          textMuted: textMuted,
          onToggle: () {
            HapticService.light();
            ref
                .read(habitsProvider(userId).notifier)
                .toggleHabit(habit.id, !habit.todayCompleted);
          },
        )),

        // "View all" link if more habits
        if (remainingCount > 0) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/habits');
            },
            child: Row(
              children: [
                Text(
                  '+$remainingCount more',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],

        // All done celebration
        if (allDone && size == TileSize.full) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All habits done today!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual habit item with checkbox
class _HabitItem extends StatelessWidget {
  final HabitWithStatus habit;
  final Color textColor;
  final Color textMuted;
  final VoidCallback onToggle;

  const _HabitItem({
    required this.habit,
    required this.textColor,
    required this.textMuted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.todayCompleted;

    // Parse color from habit
    Color habitColor;
    try {
      habitColor = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      habitColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? habitColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? habitColor : textMuted,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: habitColor)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? textMuted : textColor,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (habit.currentStreak > 0)
              Flexible(
                flex: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: AppColors.orange),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
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
