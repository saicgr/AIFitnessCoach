import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';

/// A card showing weekly workout progress with a progress bar and day indicators
class WeeklyProgressCard extends ConsumerWidget {
  /// Number of completed workouts this week
  final int completed;

  /// Total number of workouts planned for this week
  final int total;

  /// Whether to use dark theme
  final bool isDark;

  const WeeklyProgressCard({
    super.key,
    required this.completed,
    required this.total,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = total > 0 ? completed / total : 0.0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1; // 0-indexed
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed of $total workouts',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              // Large percentage number with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress * 100),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return Text(
                    '${animatedValue.toInt()}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      height: 1.0,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: glassSurface,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isToday = index == today;
              final isPast = index < today;
              final dayProgress = isPast ? 1.0 : (isToday && completed > 0 ? 0.5 : 0.0);

              return Column(
                children: [
                  // Circular ring for each day
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 3,
                          color: glassSurface,
                        ),
                        // Progress ring
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: dayProgress),
                          duration: Duration(milliseconds: 600 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 3,
                            backgroundColor: Colors.transparent,
                            color: isPast || (isToday && value > 0)
                                ? accentColor
                                : Colors.transparent,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Check icon for completed days
                        if (isPast)
                          Icon(
                            Icons.check,
                            size: 14,
                            color: accentColor,
                          )
                        // Today indicator dot
                        else if (isToday)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? accentColor : textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
