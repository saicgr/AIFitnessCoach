import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Elite Template — gold holographic premium design.
/// Cosmetic-gated (stats_card_elite, unlocks at Level 75).
class StatsEliteTemplate extends StatelessWidget {
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final int weeklyCompleted;
  final int weeklyGoal;
  final int xpLevel;
  final int xpTotal;
  final String? dateRangeLabel;
  final bool showWatermark;

  const StatsEliteTemplate({
    super.key,
    required this.totalWorkouts,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.xpLevel,
    required this.xpTotal,
    this.dateRangeLabel,
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
            Color(0xFF1A1000),
            Color(0xFF2E1D00),
            Color(0xFF1A0F00),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Gold shimmer background rings
          Positioned.fill(
            child: CustomPaint(painter: _GoldRingsPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ELITE banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFF9800),
                      Color(0xFFFFD700),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 16, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        'ELITE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                  ).createShader(bounds),
                  child: const Text(
                    'LEVEL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ).createShader(bounds),
                  child: Text(
                    '$xpLevel',
                    style: const TextStyle(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_format(xpTotal)} XP EARNED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                // Stat grid
                Row(
                  children: [
                    Expanded(child: _stat('$totalWorkouts', 'WORKOUTS')),
                    Container(width: 1, height: 36, color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    Expanded(child: _stat('$currentStreak', 'STREAK')),
                    Container(width: 1, height: 36, color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    Expanded(child: _stat('$weeklyCompleted/$weeklyGoal', 'WEEK')),
                  ],
                ),
                const SizedBox(height: 14),
                if (dateRangeLabel != null)
                  Text(
                    dateRangeLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          if (showWatermark)
            const Positioned(bottom: 14, right: 14, child: AppWatermark()),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ],
      );

  static String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return n.toString();
  }
}

class _GoldRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.15);
    for (int i = 0; i < 5; i++) {
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.04 + i * 0.02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 60.0 + i * 25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldRingsPainter oldDelegate) => false;
}
