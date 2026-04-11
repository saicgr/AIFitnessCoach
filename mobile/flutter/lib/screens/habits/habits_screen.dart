import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_sheet.dart';
import '../home/widgets/habit_card.dart';


part 'habits_screen_part_unified_habit_item.dart';
part 'habits_screen_part_add_habit_sheet_content.dart';

part 'habits_screen_ui.dart';


/// Provider for habits screen state
final habitsScreenProvider = StateNotifierProvider.autoDispose<HabitsScreenNotifier, HabitsScreenState>((ref) {
  // Keep alive so data persists across navigation (no re-fetch on every visit)
  ref.keepAlive();

  // Use ref.read (not ref.watch) so auth/accent changes do NOT recreate the
  // notifier and reset state to empty, which caused the black-screen flicker.
  final repository = ref.read(habitRepositoryProvider);
  final userId = ref.read(authStateProvider).user?.id ?? '';
  final accentColor = ref.read(accentColorProvider).getColor(false);

  return HabitsScreenNotifier(
    repository,
    userId,
    () => ref.read(habitsProvider),
    accentColor,
  );
});

/// Full-screen habits page showing all tracked habits in detail
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(posthogServiceProvider).capture(eventName: 'habits_viewed');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Auto-tracked habits (for stats calculation)
    final autoHabits = ref.watch(habitsProvider);

    // Unified habits from provider
    final habitsState = ref.watch(habitsScreenProvider);
    final habitsNotifier = ref.read(habitsScreenProvider.notifier);

    // Refresh unified list when auto habits change
    ref.listen(habitsProvider, (prev, next) {
      habitsNotifier.refreshUnifiedList(next);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: () => habitsNotifier.loadHabits(force: true),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16,
                    right: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary card
                        _buildSummaryCard(
                          context,
                          autoHabits: autoHabits,
                          customHabits: habitsState.customHabits,
                          completedToday: habitsState.completedToday,
                          totalHabits: habitsState.totalHabits,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 24),
                        // Hint text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              size: 14,
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hold to reorder • Swipe to delete',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Show loading spinner while initial data is fetching
                if (habitsState.isLoading && habitsState.unifiedHabits.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator(color: accentColor)),
                    ),
                  ),

                // Unified reorderable list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: habitsState.unifiedHabits.length,
                    onReorder: (oldIndex, newIndex) {
                      HapticService.medium();
                      habitsNotifier.reorderHabits(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final scale = Tween<double>(begin: 1.0, end: 1.03).animate(animation);
                          return Transform.scale(
                            scale: scale.value,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final habit = habitsState.unifiedHabits[index];
                      return _buildUnifiedHabitItem(
                        context,
                        ref,
                        index: index,
                        habit: habit,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          // Top bar: back button + centered title
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GlassBackButton(
                  onTap: () {
                    HapticService.light();
                    context.pop();
                  },
                ),
                Expanded(
                  child: Text(
                    'Your Habits',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                // Invisible spacer matching back button width for centering
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Floating add button (bottom right)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticService.medium();
                _showAddHabitSheet(context, ref, habitsState.templates);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: isDark ? Colors.black : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build unified habit card with reorder and swipe-to-delete
  Widget _buildUnifiedHabitItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required UnifiedHabitItem habit,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    // Use theme-aware accent color for auto-tracked habits, otherwise use the habit's stored color
    final effectiveColor = habit.isAutoTracked ? accentColor : habit.color;

    return Padding(
      key: ValueKey(habit.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss_${habit.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          HapticService.error();
          final message = habit.isAutoTracked
              ? 'Auto-tracked habits like "${habit.name}" cannot be deleted. They are based on your activity.'
              : 'Are you sure you want to delete "${habit.name}"? This cannot be undone.';

          if (habit.isAutoTracked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return false;
          }

          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Habit?'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          HapticService.medium();
          ref.read(habitsScreenProvider.notifier).deleteHabit(habit.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${habit.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: ReorderableDragStartListener(
          index: index,
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              // Navigate to habit detail screen
              context.push('/habit/${habit.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: habit.todayCompleted
                      ? effectiveColor.withValues(alpha: 0.5)
                      : cardBorder,
                  width: habit.todayCompleted ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Drag handle
                      Icon(
                        Icons.drag_indicator,
                        color: textSecondary.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Checkbox / log button
                      GestureDetector(
                        onTap: () {
                          HapticService.medium();
                          if (habit.isAutoTracked) {
                            // Auto-tracked: navigate to the relevant screen to log
                            if (habit.route != null) {
                              context.push(habit.route!);
                            }
                          } else {
                            // Custom: toggle completion via API
                            ref.read(habitsScreenProvider.notifier).toggleHabit(
                              habit.id,
                              !habit.todayCompleted,
                            );
                          }
                        },
                        child: habit.todayCompleted
                            ? AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: effectiveColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.check, color: isDark ? Colors.black : Colors.white, size: 18),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: effectiveColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  habit.isAutoTracked ? '+ Log' : 'Log',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: effectiveColor,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(habit.icon, color: effectiveColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    habit.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: habit.todayCompleted
                                          ? textSecondary
                                          : textPrimary,
                                      decoration: habit.todayCompleted && !habit.isAutoTracked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (habit.isAutoTracked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: textSecondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (habit.last30Days.isNotEmpty)
                              Text(
                                '${habit.last30Days.where((d) => d).length} of 30 days',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              )
                            else if (habit.description != null && habit.description!.isNotEmpty)
                              Text(
                                habit.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Streak badge
                      if (habit.currentStreak > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: effectiveColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department, size: 14, color: effectiveColor),
                              const SizedBox(width: 2),
                              Text(
                                '${habit.currentStreak}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: effectiveColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (habit.route != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: textSecondary, size: 20),
                      ],
                    ],
                  ),
                  // Mini grid for auto-tracked habits
                  if (habit.last30Days.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMiniGrid(habit.last30Days, effectiveColor, emptyColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required List<HabitData> autoHabits,
    required List<HabitWithStatus> customHabits,
    required int completedToday,
    required int totalHabits,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    // Calculate totals from auto-habits
    final autoTracked = autoHabits.fold<int>(
      0, (sum, h) => sum + h.last30Days.where((d) => d).length);
    final autoPossible = autoHabits.length * 30;
    final autoPercentage = autoPossible > 0 ? (autoTracked / autoPossible * 100).round() : 0;

    // Combined stats
    final totalCustomCompleted = customHabits.where((h) => h.todayCompleted).length;
    final autoCompletedToday = autoHabits.where((h) => h.last30Days.isNotEmpty && h.last30Days.last).length;
    final combinedTodayTotal = autoHabits.length + customHabits.length;
    final combinedTodayCompleted = autoCompletedToday + totalCustomCompleted;

    // Find longest streak across all habits
    final autoStreaks = autoHabits.map((h) => h.currentStreak).toList();
    final customStreaks = customHabits.map((h) => h.currentStreak).toList();
    final allStreaks = [...autoStreaks, ...customStreaks];
    final longestStreak = allStreaks.isNotEmpty
        ? allStreaks.reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Completed',
                  value: '$combinedTodayCompleted/$combinedTodayTotal',
                  icon: Icons.check_circle_outline,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: '30-Day Rate',
                  value: '$autoPercentage%',
                  icon: Icons.calendar_today,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Best Streak',
                  value: '$longestStreak',
                  icon: Icons.local_fire_department,
                  accentColor: accentColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: accentColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniGrid(List<bool> days, Color accentColor, Color emptyColor) {
    final paddedDays = List<bool>.from(days);
    while (paddedDays.length < 30) {
      paddedDays.insert(0, false);
    }
    if (paddedDays.length > 30) {
      paddedDays.removeRange(0, paddedDays.length - 30);
    }

    // GitHub-style contribution grid: 5 rows x 6 columns with circular dots
    const int columns = 10;
    const int rows = 3;
    const double dotSize = 10.0;
    const double spacing = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? spacing : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(columns, (colIndex) {
              final index = rowIndex * columns + colIndex;
              final completed = index < paddedDays.length ? paddedDays[index] : false;
              return Padding(
                padding: EdgeInsets.only(right: colIndex < columns - 1 ? spacing : 0),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: completed ? accentColor : emptyColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref, List<HabitTemplate> templates) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final sheetBg = isDark ? AppColors.pureBlack : Colors.white;
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Always use hardcoded defaults (API templates have duplicates)
    final allTemplates = HabitTemplate.defaults;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return GlassSheet(
          maxHeightFraction: 0.85,
          child: SafeArea(
            child: _AddHabitSheetContent(
              allTemplates: allTemplates,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              accentColor: accentColor,
              isDark: isDark,
              ref: ref,
              onCreateCustom: () {
                HapticService.medium();
                Navigator.pop(context);
                _showCreateCustomHabitSheet(context, ref);
              },
              onAddTemplate: (template) async {
                HapticService.medium();
                Navigator.pop(context);
                await ref.read(habitsScreenProvider.notifier)
                    .createHabitFromTemplate(template.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${template.name}"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              parseColor: _parseColor,
              getIconFromName: _getIconFromName,
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorHex, Color fallback) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _getIconFromName(String iconName) {
    const iconMap = {
      'check_circle': Icons.check_circle,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'do_not_disturb': Icons.do_not_disturb,
      'medication': Icons.medication,
      'directions_walk': Icons.directions_walk,
      'self_improvement': Icons.self_improvement,
      'directions_run': Icons.directions_run,
      'fitness_center': Icons.fitness_center,
      'bedtime': Icons.bedtime,
      'spa': Icons.spa,
      'no_drinks': Icons.no_drinks,
      'wb_sunny': Icons.wb_sunny,
      'menu_book': Icons.menu_book,
      'edit_note': Icons.edit_note,
      'phone_disabled': Icons.phone_disabled,
      'favorite': Icons.favorite,
      'restaurant_menu': Icons.restaurant_menu,
      'delivery_dining': Icons.delivery_dining,
      'nightlight': Icons.nightlight,
      'restaurant': Icons.restaurant,
      'soup_kitchen': Icons.soup_kitchen,
      'heart': Icons.favorite,
      'running': Icons.directions_run,
      'apple': Icons.apple,
      'star': Icons.star,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }
}
