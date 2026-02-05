import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood.dart';
import '../../../data/repositories/mood_history_repository.dart';
import '../../../data/services/api_client.dart';

/// Provider for weekly mood data
final moodWeeklyProvider = FutureProvider.autoDispose<MoodWeeklyResponse?>((ref) async {
  final userId = await ref.watch(apiClientProvider).getUserId();
  if (userId == null) return null;
  return ref.watch(moodHistoryRepositoryProvider).getMoodWeekly(userId: userId);
});

/// Widget showing the last 7 days of mood data in a visual chart
class MoodWeeklyChart extends ConsumerWidget {
  const MoodWeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyData = ref.watch(moodWeeklyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklyData.when(
        data: (data) {
          if (data == null || data.days.isEmpty) {
            return _buildEmptyState(textSecondary);
          }
          return _buildChart(context, data, isDark, textPrimary, textSecondary);
        },
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildErrorState(textSecondary),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    MoodWeeklyResponse data,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and trend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            _buildTrendBadge(data.summary, isDark),
          ],
        ),
        const SizedBox(height: 16),

        // Days row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.days.map((day) {
            return _DayColumn(
              day: day,
              isDark: isDark,
              textSecondary: textSecondary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Summary stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              value: '${data.summary.totalCheckins}',
              label: 'Check-ins',
              color: textPrimary,
              textSecondary: textSecondary,
            ),
            _StatItem(
              value: data.summary.avgMoodScore.toStringAsFixed(1),
              label: 'Avg Score',
              color: textPrimary,
              textSecondary: textSecondary,
            ),
            _StatItem(
              value: '${data.daysWithCheckins.length}/7',
              label: 'Days Active',
              color: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendBadge(MoodWeeklySummary summary, bool isDark) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (summary.trend) {
      case 'improving':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green;
        icon = Icons.trending_up;
        label = 'Improving';
        break;
      case 'declining':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        icon = Icons.trending_down;
        label = 'Declining';
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        icon = Icons.trending_flat;
        label = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood_outlined,
              size: 40,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No mood data this week',
              style: TextStyle(color: textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Start tracking your mood to see trends',
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 150,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(Color textSecondary) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load mood data',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single day column in the weekly chart
class _DayColumn extends StatelessWidget {
  final MoodDayData day;
  final bool isDark;
  final Color textSecondary;

  const _DayColumn({
    required this.day,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheckin = day.hasCheckins;
    final primaryMood = day.primaryMoodEnum;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day name (abbreviated)
        Text(
          day.dayName.substring(0, 3),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Mood indicator
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasCheckin
                ? (primaryMood?.color.withValues(alpha: 0.15) ?? Colors.grey.withValues(alpha: 0.1))
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: hasCheckin
                ? Border.all(
                    color: primaryMood?.color.withValues(alpha: 0.3) ?? Colors.grey,
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: hasCheckin && primaryMood != null
                ? Text(
                    primaryMood.emoji,
                    style: const TextStyle(fontSize: 20),
                  )
                : Icon(
                    Icons.remove,
                    size: 16,
                    color: textSecondary.withValues(alpha: 0.3),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        // Check-in count
        if (day.checkinCount > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryMood?.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${day.checkinCount}x',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: primaryMood?.color ?? textSecondary,
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color textSecondary;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
