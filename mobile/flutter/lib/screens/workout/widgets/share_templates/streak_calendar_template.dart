import 'package:flutter/material.dart';
import '_share_common.dart';

/// Streak Calendar — month-grid heatmap of workout days with today
/// highlighted + streak + total counter.
class StreakCalendarTemplate extends StatelessWidget {
  final int? currentStreak;
  final int totalWorkouts;
  final List<DateTime> workoutDates;
  final DateTime completedAt;
  final bool showWatermark;

  const StreakCalendarTemplate({
    super.key,
    this.currentStreak,
    required this.totalWorkouts,
    this.workoutDates = const [],
    required this.completedAt,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = completedAt;
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstOfMonth.weekday % 7; // 0 = Sunday

    // Build set of yyyy-mm-dd strings for O(1) lookup
    final workoutSet = workoutDates
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1A2A), Color(0xFF05060A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShareTrackedCaps(
            _monthLabel(now),
            size: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          // Day-of-week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 26,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x88FFFFFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final day = index - firstWeekday + 1;
                final dateKey = '${now.year}-${now.month}-$day';
                final isToday = day == now.day;
                final hasWorkout = workoutSet.contains(dateKey);

                Color fill;
                Color? border;
                Color textColor;
                if (isToday) {
                  fill = const Color(0xFFF97316);
                  border = const Color(0xFFFFBA7E);
                  textColor = Colors.white;
                } else if (hasWorkout) {
                  fill = const Color(0xFFF97316).withValues(alpha: 0.55);
                  border = null;
                  textColor = Colors.white;
                } else {
                  fill = Colors.transparent;
                  border = Colors.white.withValues(alpha: 0.12);
                  textColor = Colors.white.withValues(alpha: 0.5);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: border == null
                        ? null
                        : Border.all(color: border, width: 1.2),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF97316)
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  ShareHeroNumber(
                    value: '${currentStreak ?? 0}',
                    size: 44,
                    color: const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 2),
                  ShareTrackedCaps(
                    'DAY STREAK',
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              Column(
                children: [
                  ShareHeroNumber(
                    value: '$totalWorkouts',
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 2),
                  ShareTrackedCaps(
                    'TOTAL WORKOUTS',
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ShareWatermarkBadge(enabled: showWatermark),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY',
                    'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER',
                    'NOVEMBER', 'DECEMBER'];
    return '${months[d.month - 1]} ${d.year}';
  }
}
