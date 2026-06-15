import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Data model for a single habit
class HabitData {
  final String name;
  final String? id;
  final IconData icon;
  final List<bool> last30Days;
  final int currentStreak;
  final String? route;
  final bool todayCompleted;

  const HabitData({
    required this.name,
    this.id,
    required this.icon,
    required this.last30Days,
    this.currentStreak = 0,
    this.route,
    this.todayCompleted = false,
  });
}

/// Square habit card with GitHub-style contribution grid and optional log button
class HabitCard extends ConsumerWidget {
  final HabitData habit;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final double size;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
    this.onLog,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final completedDays = habit.last30Days.where((d) => d).length;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: habit.todayCompleted
                ? accentColor.withValues(alpha: 0.4)
                : cardBorder,
            width: habit.todayCompleted ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title — auto-tracked habits ('auto_workouts', 'auto_food_log',
                  // 'auto_water') get a localized label; user-created habits keep
                  // their original (user-typed) name unchanged.
                  Text(
                    displayName(context, habit),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).habitCardLast30Days,
                    style: TextStyle(
                      fontSize: 10,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  // Grid
                  _buildGrid(accentColor, isDark),
                  const Spacer(),
                  // Footer: count + streak
                  Row(
                    children: [
                      Text(
                        '$completedDays/${habit.last30Days.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (habit.currentStreak > 0) ...[
                        Icon(Icons.local_fire_department, size: 12, color: accentColor),
                        const SizedBox(width: 2),
                        Text(
                          '${habit.currentStreak}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // FAB pinned to bottom-right corner
            if (onLog != null)
              PositionedDirectional(end: 6,
                bottom: 6,
                child: GestureDetector(
                  onTap: () {
                    HapticService.medium();
                    onLog!();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: habit.todayCompleted
                          ? accentColor
                          : cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      habit.todayCompleted ? Icons.check_rounded : Icons.add_rounded,
                      size: 16,
                      color: habit.todayCompleted
                          ? (isDark ? Colors.black : Colors.white)
                          : accentColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Color accentColor, bool isDark) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    final days = List<bool>.from(habit.last30Days);
    while (days.length < 30) days.insert(0, false);
    if (days.length > 30) days.removeRange(0, days.length - 30);

    // 6 columns x 5 rows
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (col) {
            final index = row * 6 + col;
            final completed = days[index];
            return Container(
              width: 8,
              height: 8,
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

  /// Resolve the visible title for a habit. Auto-tracked habits use the
  /// stable id assigned in `habitsProvider` (so non-en locales render
  /// localized strings); custom habits fall back to the user-typed name.
  ///
  /// Public so the Signature v2 [HabitsSection] dot-rows can reuse the exact
  /// same localized-name resolution.
  static String displayName(BuildContext context, HabitData habit) {
    final l10n = AppLocalizations.of(context);
    switch (habit.id) {
      case 'auto_workouts': return l10n.habitWorkouts;
      case 'auto_food_log': return l10n.habitFoodLog;
      case 'auto_water':    return l10n.habitWater;
    }
    return habit.name;
  }
}
