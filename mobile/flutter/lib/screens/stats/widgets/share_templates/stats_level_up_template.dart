import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Level Up Template - RPG/gaming style with XP bar and level ring
/// Deep purple → indigo gradient with hexagonal grid
class StatsLevelUpTemplate extends StatelessWidget {
  final int totalWorkouts;
  final int currentStreak;
  final int weeklyCompleted;
  final int weeklyGoal;
  final int longestStreak;
  final bool showWatermark;

  const StatsLevelUpTemplate({
    super.key,
    required this.totalWorkouts,
    required this.currentStreak,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.longestStreak,
    this.showWatermark = true,
  });

  int get _level => (totalWorkouts ~/ 10) + 1;

  String get _rank {
    if (_level >= 50) return 'GRANDMASTER';
    if (_level >= 30) return 'CHAMPION';
    if (_level >= 20) return 'VETERAN';
    if (_level >= 10) return 'WARRIOR';
    if (_level >= 5) return 'APPRENTICE';
    return 'ROOKIE';
  }

  int get _currentXP => (totalWorkouts % 10) * 350;
  int get _maxXP => 3500;

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
            Color(0xFF1E1045),
            Color(0xFF2E1065),
            Color(0xFF1E1B4B),
            Color(0xFF0F0A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Hexagonal grid
          Positioned.fill(
            child: CustomPaint(
              painter: _HexGridPainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Rank title
                Text(
                  _rank,
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 16),

                // Level ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _LevelRingPainter(
                      progress: _currentXP / _maxXP,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LVL',
                            style: TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '$_level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // XP bar
                Column(
                  children: [
                    // XP label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EXPERIENCE',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '${_formatNumber(_currentXP)} / ${_formatNumber(_maxXP)} XP',
                          style: const TextStyle(
                            color: Color(0xFFC4B5FD),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // XP progress bar
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: (_currentXP / _maxXP).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFA78BFA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2-column stat cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.fitness_center,
                        value: '$totalWorkouts',
                        label: 'Workouts',
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department,
                        value: '$currentStreak',
                        label: 'Streak',
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular level progress ring painter
class _LevelRingPainter extends CustomPainter {
  final double progress;

  _LevelRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color(0xFF7C3AED),
          Color(0xFFA78BFA),
          Color(0xFFC4B5FD),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF7C3AED).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Hexagonal grid background painter
class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexRadius = 20.0;
    final hexHeight = hexRadius * math.sqrt(3);

    for (double y = -hexRadius; y < size.height + hexRadius; y += hexHeight) {
      int col = 0;
      for (double x = -hexRadius; x < size.width + hexRadius; x += hexRadius * 3) {
        final offsetY = col.isOdd ? hexHeight / 2 : 0.0;
        _drawHex(canvas, Offset(x, y + offsetY), hexRadius, paint);
        col++;
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
