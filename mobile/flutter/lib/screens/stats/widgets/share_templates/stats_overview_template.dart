import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Overview Template - Shows activity summary with key stats
/// Dark gradient background with heatmap-style visualization
class StatsOverviewTemplate extends StatelessWidget {
  final int totalWorkouts;
  final int weeklyCompleted;
  final int weeklyGoal;
  final int currentStreak;
  final String totalTimeFormatted;
  final String dateRangeLabel;
  final bool showWatermark;

  const StatsOverviewTemplate({
    super.key,
    required this.totalWorkouts,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.currentStreak,
    required this.totalTimeFormatted,
    required this.dateRangeLabel,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF21262D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _HeatmapPatternPainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY STATS',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateRangeLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: AppColors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$currentStreak day streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Main stat
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$totalWorkouts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'WORKOUTS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Stats grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.calendar_today,
                      value: '$weeklyCompleted/$weeklyGoal',
                      label: 'This Week',
                      color: AppColors.purple,
                    ),
                    _StatItem(
                      icon: Icons.timer_outlined,
                      value: totalTimeFormatted,
                      label: 'Total Time',
                      color: AppColors.success,
                    ),
                    _StatItem(
                      icon: Icons.trending_up,
                      value: '$currentStreak',
                      label: 'Streak',
                      color: AppColors.orange,
                    ),
                  ],
                ),

                const Spacer(),

                // Watermark
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Decorative heatmap-style pattern painter
class _HeatmapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const cellSize = 12.0;
    const gap = 3.0;

    for (double x = 10; x < size.width - 10; x += cellSize + gap) {
      for (double y = 100; y < 180; y += cellSize + gap) {
        // Random-ish opacity based on position
        final opacity = ((x + y) % 50) / 500;
        paint.color = AppColors.orange.withOpacity(0.02 + opacity);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellSize, cellSize),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
