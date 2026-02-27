import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Streak Fire Template - Bold flame celebration
/// Radial gradient orange → red → dark with flame-shaped paths
class StatsStreakFireTemplate extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final bool showWatermark;

  const StatsStreakFireTemplate({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalWorkouts,
    this.showWatermark = true,
  });

  String get _streakTitle {
    if (currentStreak >= 100) return 'LEGENDARY FLAME';
    if (currentStreak >= 30) return 'INFERNO MODE';
    if (currentStreak >= 14) return 'BLAZING';
    if (currentStreak >= 7) return 'HEATING UP';
    if (currentStreak >= 3) return 'SPARK IGNITED';
    return 'FIRE STARTER';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFFF97316),
            Color(0xFFDC2626),
            Color(0xFF7F1D1D),
            Color(0xFF1C1917),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Flame shapes
          Positioned.fill(
            child: CustomPaint(
              painter: _FlamePainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Title
                Text(
                  _streakTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 8),

                // Fire emoji row
                const Text(
                  '🔥🔥🔥',
                  style: TextStyle(fontSize: 24),
                ),

                const Spacer(),

                // Big streak number with shader mask
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFF97316),
                      Color(0xFFEF4444),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '$currentStreak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),

                const Text(
                  'DAY STREAK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),

                const Spacer(),

                // Bottom stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF97316).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FireStat(
                        value: '$longestStreak',
                        label: 'Longest',
                        icon: Icons.whatshot,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      _FireStat(
                        value: '$totalWorkouts',
                        label: 'Total',
                        icon: Icons.fitness_center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FireStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _FireStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFF97316), size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Flame-shaped decorative painter
class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Large background flame
    _drawFlame(
      canvas,
      center: Offset(cx, size.height * 0.55),
      width: size.width * 0.6,
      height: size.height * 0.45,
      color: const Color(0xFFF97316).withOpacity(0.06),
    );

    // Left flame
    _drawFlame(
      canvas,
      center: Offset(cx - 60, size.height * 0.6),
      width: size.width * 0.25,
      height: size.height * 0.3,
      color: const Color(0xFFEF4444).withOpacity(0.05),
    );

    // Right flame
    _drawFlame(
      canvas,
      center: Offset(cx + 60, size.height * 0.6),
      width: size.width * 0.25,
      height: size.height * 0.3,
      color: const Color(0xFFEF4444).withOpacity(0.05),
    );
  }

  void _drawFlame(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - height / 2);
    path.quadraticBezierTo(
      center.dx + width / 2,
      center.dy - height * 0.1,
      center.dx + width * 0.15,
      center.dy + height / 2,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + height * 0.3,
      center.dx - width * 0.15,
      center.dy + height / 2,
    );
    path.quadraticBezierTo(
      center.dx - width / 2,
      center.dy - height * 0.1,
      center.dx,
      center.dy - height / 2,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
