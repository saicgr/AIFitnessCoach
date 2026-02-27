import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Achievements Template - Shows achievements and milestones
/// Celebratory design with achievement badges
class StatsAchievementsTemplate extends StatelessWidget {
  final List<AchievementData> achievements;
  final int currentStreak;
  final int totalWorkouts;
  final bool showWatermark;

  const StatsAchievementsTemplate({
    super.key,
    required this.achievements,
    required this.currentStreak,
    required this.totalWorkouts,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF2D1B4E),
            Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative sparkles
          Positioned.fill(
            child: CustomPaint(
              painter: _SparklePainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 8),

                // Trophy icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade600,
                        Colors.amber.shade800,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                // Achievement count
                Text(
                  '${achievements.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  'Achievements Unlocked',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // Achievement badges (show up to 3 in a row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: achievements.take(3).map((achievement) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _AchievementBadge(achievement: achievement),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                // Milestone stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniStat(
                        icon: Icons.local_fire_department,
                        value: '$currentStreak',
                        label: 'Day Streak',
                        color: AppColors.orange,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _MiniStat(
                        icon: Icons.fitness_center,
                        value: '$totalWorkouts',
                        label: 'Workouts',
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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

class AchievementData {
  final String emoji;
  final String name;

  const AchievementData({required this.emoji, required this.name});
}

class _AchievementBadge extends StatelessWidget {
  final AchievementData achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Text(
            achievement.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            achievement.name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Decorative sparkle pattern painter
class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw some sparkle dots
    final positions = [
      Offset(30, 60),
      Offset(size.width - 40, 80),
      Offset(50, size.height - 150),
      Offset(size.width - 30, size.height - 180),
      Offset(size.width / 2 - 80, 120),
      Offset(size.width / 2 + 90, 100),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, 3, paint);
      paint.color = Colors.amber.withOpacity(0.05);
      canvas.drawCircle(pos, 8, paint);
      paint.color = Colors.amber.withOpacity(0.1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
