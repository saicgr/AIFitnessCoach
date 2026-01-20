import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/habit_card.dart';

/// State notifier for managing habits from API
class HabitsScreenNotifier extends StateNotifier<HabitsScreenState> {
  final HabitRepository _repository;
  final String _userId;

  HabitsScreenNotifier(this._repository, this._userId)
      : super(const HabitsScreenState()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final todayResponse = await _repository.getTodayHabits(_userId);
      final templates = await _repository.getHabitTemplates();
      state = state.copyWith(
        isLoading: false,
        habits: todayResponse.habits,
        totalHabits: todayResponse.totalHabits,
        completedToday: todayResponse.completedToday,
        completionPercentage: todayResponse.completionPercentage,
        templates: templates,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleHabit(String habitId, bool completed) async {
    try {
      await _repository.toggleTodayHabit(_userId, habitId, completed);
      // Optimistic update
      final updatedHabits = state.habits.map((h) {
        if (h.id == habitId) {
          return h.copyWith(todayCompleted: completed);
        }
        return h;
      }).toList();

      final newCompletedCount = updatedHabits.where((h) => h.todayCompleted).length;
      state = state.copyWith(
        habits: updatedHabits,
        completedToday: newCompletedCount,
        completionPercentage: updatedHabits.isEmpty
            ? 0.0
            : (newCompletedCount / updatedHabits.length * 100),
      );
    } catch (e) {
      // Reload on error
      await loadHabits();
    }
  }

  Future<void> createHabitFromTemplate(String templateId) async {
    try {
      await _repository.createHabitFromTemplate(_userId, templateId);
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(_userId, habitId);
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class HabitsScreenState {
  final bool isLoading;
  final String? error;
  final List<HabitWithStatus> habits;
  final int totalHabits;
  final int completedToday;
  final double completionPercentage;
  final List<HabitTemplate> templates;

  const HabitsScreenState({
    this.isLoading = false,
    this.error,
    this.habits = const [],
    this.totalHabits = 0,
    this.completedToday = 0,
    this.completionPercentage = 0.0,
    this.templates = const [],
  });

  HabitsScreenState copyWith({
    bool? isLoading,
    String? error,
    List<HabitWithStatus>? habits,
    int? totalHabits,
    int? completedToday,
    double? completionPercentage,
    List<HabitTemplate>? templates,
  }) {
    return HabitsScreenState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      habits: habits ?? this.habits,
      totalHabits: totalHabits ?? this.totalHabits,
      completedToday: completedToday ?? this.completedToday,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      templates: templates ?? this.templates,
    );
  }
}

/// Provider for habits screen state
final habitsScreenProvider = StateNotifierProvider.autoDispose<HabitsScreenNotifier, HabitsScreenState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';
  return HabitsScreenNotifier(repository, userId);
});

/// Full-screen habits page showing all tracked habits in detail
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // Auto-tracked habits (from workouts, nutrition, hydration)
    final autoHabits = ref.watch(habitsProvider);

    // Custom habits from API
    final habitsState = ref.watch(habitsScreenProvider);
    final habitsNotifier = ref.read(habitsScreenProvider.notifier);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Your Habits',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: accentColor),
            onPressed: () => _showAddHabitSheet(context, ref, habitsState.templates),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: habitsNotifier.loadHabits,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            _buildSummaryCard(
              context,
              autoHabits: autoHabits,
              customHabits: habitsState.habits,
              completedToday: habitsState.completedToday,
              totalHabits: habitsState.totalHabits,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentColor,
            ),
            const SizedBox(height: 24),

            // Auto-tracked section
            Text(
              'AUTO-TRACKED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...autoHabits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAutoHabitCard(
                context,
                habit: habit,
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                accentColor: accentColor,
                isDark: isDark,
              ),
            )),

            const SizedBox(height: 24),

            // Custom habits section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOM HABITS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (habitsState.habits.isEmpty)
                  GestureDetector(
                    onTap: () => _showAddHabitSheet(context, ref, habitsState.templates),
                    child: Text(
                      '+ Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (habitsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (habitsState.habits.isEmpty)
              _buildEmptyState(
                context,
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                accentColor: accentColor,
                onAddPressed: () => _showAddHabitSheet(context, ref, habitsState.templates),
              )
            else
              ...habitsState.habits.map((habit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCustomHabitCard(
                  context,
                  ref,
                  habit: habit,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              )),

            const SizedBox(height: 80), // Bottom padding
          ],
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
    final combinedTodayTotal = autoHabits.length + totalHabits;
    final combinedTodayCompleted = autoCompletedToday + totalCustomCompleted;

    final longestStreak = autoHabits.isNotEmpty
        ? autoHabits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b)
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

  Widget _buildAutoHabitCard(
    BuildContext context, {
    required HabitData habit,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    final completedDays = habit.last30Days.where((d) => d).length;
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        if (habit.route != null) {
          context.push(habit.route!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(habit.icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '$completedDays of 30 days',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (habit.currentStreak > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            _buildMiniGrid(habit.last30Days, accentColor, emptyColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHabitCard(
    BuildContext context,
    WidgetRef ref, {
    required HabitWithStatus habit,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isDark,
  }) {
    final habitColor = _parseColor(habit.color, accentColor);

    return GestureDetector(
      onLongPress: () => _showHabitOptions(context, ref, habit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: habit.todayCompleted ? habitColor.withValues(alpha: 0.5) : cardBorder,
            width: habit.todayCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                HapticService.medium();
                ref.read(habitsScreenProvider.notifier).toggleHabit(
                  habit.id,
                  !habit.todayCompleted,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: habit.todayCompleted ? habitColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: habit.todayCompleted ? habitColor : cardBorder,
                    width: 2,
                  ),
                ),
                child: habit.todayCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: habitColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconFromName(habit.icon),
                color: habitColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: habit.todayCompleted
                          ? textSecondary
                          : textPrimary,
                      decoration: habit.todayCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (habit.description != null && habit.description!.isNotEmpty)
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
            // Streak
            if (habit.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, size: 14, color: habitColor),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: habitColor,
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

  Widget _buildEmptyState(
    BuildContext context, {
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required VoidCallback onAddPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_task,
            size: 48,
            color: textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No custom habits yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create habits to track your daily routines',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
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

    // 5 rows x 6 columns
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (col) {
        return Column(
          children: List.generate(5, (row) {
            final index = row * 6 + col;
            final completed = index < paddedDays.length ? paddedDays[index] : false;
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: completed ? accentColor : emptyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
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

    // Use local templates if API returned empty
    final displayTemplates = templates.isEmpty ? HabitTemplate.defaults : templates;

    // Group by category
    final grouped = <HabitCategory, List<HabitTemplate>>{};
    for (final t in displayTemplates) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Add Habit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final category in HabitCategory.values)
                        if (grouped.containsKey(category)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              category.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...grouped[category]!.map((template) {
                            final templateColor = _parseColor(template.color, AppColors.accent);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () async {
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
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: templateColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getIconFromName(template.icon),
                                          color: templateColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              template.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              template.description,
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
                                      Icon(Icons.add_circle_outline,
                                        color: templateColor, size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHabitOptions(BuildContext context, WidgetRef ref, HabitWithStatus habit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final sheetBg = isDark ? AppColors.pureBlack : Colors.white;

    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive Habit'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(habitsScreenProvider.notifier).deleteHabit(habit.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Archived "${habit.name}"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Permanently',
                  style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, habit);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, HabitWithStatus habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('This will permanently delete "${habit.name}" and all its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(habitsScreenProvider.notifier).deleteHabit(habit.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${habit.name}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
