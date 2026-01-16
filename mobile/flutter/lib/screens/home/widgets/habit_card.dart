import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Data model for a single habit
class HabitData {
  final String name;
  final IconData icon;
  final List<bool> last30Days;
  final int currentStreak;
  final String? route;

  const HabitData({
    required this.name,
    required this.icon,
    required this.last30Days,
    this.currentStreak = 0,
    this.route,
  });
}

/// Square habit card with GitHub-style contribution grid
class HabitCard extends ConsumerWidget {
  final HabitData habit;
  final VoidCallback? onTap;
  final double size;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              habit.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              'Last 30 Days',
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
            ),
            const Spacer(),
            // Grid
            _buildGrid(accentColor, isDark),
            const Spacer(),
            // Footer
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
}
