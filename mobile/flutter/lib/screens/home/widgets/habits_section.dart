import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/habit.dart';
import '../../../data/providers/habits_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'habit_card.dart';

/// Provider to fetch custom habits for home section
final customHabitsHomeProvider = FutureProvider.autoDispose<List<HabitWithStatus>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) return [];

  final repository = ref.watch(habitRepositoryProvider);
  try {
    final response = await repository.getTodayHabits(userId);
    return response.habits;
  } catch (e) {
    debugPrint('❌ [CustomHabitsHome] Error fetching habits: $e');
    return [];
  }
});

/// Provider to load saved habit order from SharedPreferences
final _savedHabitOrderProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) return [];
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('habit_order_$userId') ?? [];
  } catch (_) {
    return [];
  }
});

/// Habits section with horizontally scrollable square cards
/// Includes auto-tracked habits (Workouts, Food Log, Water) and custom habits from API
class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Auto-tracked habits (Workouts, Food Log, Water) — tag with stable IDs
    final autoTrackedHabits = ref.watch(habitsProvider).map((h) {
      final id = 'auto_${h.name.toLowerCase().replaceAll(' ', '_')}';
      return HabitData(name: h.name, id: id, icon: h.icon, last30Days: h.last30Days,
          currentStreak: h.currentStreak, route: h.route, todayCompleted: h.todayCompleted);
    }).toList();

    // Custom habits from API
    final customHabitsAsync = ref.watch(customHabitsHomeProvider);

    // Convert custom habits to HabitData format for display
    final customHabitCards = customHabitsAsync.when(
      data: (habits) => habits.map((h) => _convertToHabitData(h)).toList(),
      loading: () => <HabitData>[],
      error: (_, __) => <HabitData>[],
    );

    // Saved habit order from SharedPreferences
    final savedOrder = ref.watch(_savedHabitOrderProvider).valueOrNull ?? [];

    // Combine auto-tracked + custom habits, then sort by saved order
    List<HabitData> allHabits;
    if (savedOrder.isNotEmpty) {
      final habitsById = <String, HabitData>{};
      for (final h in autoTrackedHabits) {
        habitsById[h.id ?? h.name] = h;
      }
      for (final h in customHabitCards) {
        habitsById[h.id ?? h.name] = h;
      }
      final ordered = <HabitData>[];
      for (final id in savedOrder) {
        if (habitsById.containsKey(id)) {
          ordered.add(habitsById.remove(id)!);
        }
      }
      ordered.addAll(habitsById.values);
      allHabits = ordered;
    } else {
      allHabits = [...autoTrackedHabits, ...customHabitCards];
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with View All button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/habits'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable square cards
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // +1 for the "Add Habit" card at the end
              itemCount: allHabits.length + 1,
              itemBuilder: (context, index) {
                // Last item is the "Add Habit" card
                if (index == allHabits.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: _AddHabitCard(
                      onTap: () => _showAddHabitSheet(context, ref),
                    ),
                  );
                }

                final habit = allHabits[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HabitCard(
                    habit: habit,
                    size: 140,
                    onTap: () {
                      if (habit.route != null) {
                        context.push(habit.route!);
                      } else {
                        // Custom habit - navigate to habits screen
                        context.push('/habits');
                      }
                    },
                    onLog: () {
                      if (habit.route != null) {
                        // Auto-tracked habit — navigate to log screen
                        context.push(habit.route!);
                      } else {
                        // Custom habit — toggle via API
                        final authState = ref.read(authStateProvider);
                        final userId = authState.user?.id;
                        if (userId == null) return;
                        // Find matching custom habit to get its ID
                        final customHabits = customHabitsAsync.valueOrNull ?? [];
                        final match = customHabits.where((h) => h.name == habit.name).firstOrNull;
                        if (match != null) {
                          final repository = ref.read(habitRepositoryProvider);
                          repository.toggleTodayHabit(userId, match.id, !habit.todayCompleted).then((_) {
                            ref.invalidate(customHabitsHomeProvider);
                          });
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Convert HabitWithStatus from API to HabitData for HabitCard
  HabitData _convertToHabitData(HabitWithStatus habit) {
    // Generate last 30 days data based on completion rate
    // For now, we mark today as completed if todayCompleted is true
    final last30Days = List<bool>.filled(30, false);

    // Mark today based on completion status
    if (habit.todayCompleted) {
      last30Days[29] = true;
    }

    // Estimate some completion based on 7-day rate
    // This is a rough approximation - ideally we'd fetch actual history
    final completedDays = (habit.completionRate7d * 7).round();
    for (int i = 0; i < completedDays && i < 7; i++) {
      last30Days[28 - i] = true;
    }

    return HabitData(
      name: habit.name,
      id: habit.id,
      icon: _getIconData(habit.icon),
      last30Days: last30Days,
      currentStreak: habit.currentStreak,
      route: null, // Custom habits don't have a specific route
      todayCompleted: habit.todayCompleted,
    );
  }

  /// Parse icon string to IconData
  IconData _getIconData(String iconName) {
    final iconMap = {
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
      'local_fire_department': Icons.local_fire_department,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref) {
    context.push('/habits?addHabit=true');
  }
}

/// "Add Habit" card widget
class _AddHabitCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _AddHabitCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Habit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

