import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/habits_provider.dart';
import 'habit_card.dart';

/// Habits section with horizontally scrollable square cards
class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final habits = ref.watch(habitsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your Habits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable square cards
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < habits.length - 1 ? 12 : 0),
                  child: HabitCard(
                    habit: habit,
                    size: 140,
                    onTap: () {
                      if (habit.route != null) {
                        context.push(habit.route!);
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
}
