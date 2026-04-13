import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: streak + consistency.
/// Big {PERIOD} / STREAK title, oversize streak number, flame flourish,
/// and completion/total badges. Reads maxStreak from the period's totals —
/// "longest consecutive-day streak during this window" semantically.
class InsightsStreakTemplate extends StatelessWidget {
  final String periodName;
  final String dateRangeLabel;
  final int maxStreak;
  final int workoutsCompleted;
  final int workoutsScheduled;
  final bool showWatermark;

  const InsightsStreakTemplate({
    super.key,
    required this.periodName,
    required this.dateRangeLabel,
    required this.maxStreak,
    required this.workoutsCompleted,
    required this.workoutsScheduled,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = maxStreak > 0;

    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1C1917),
            Color(0xFF7F1D1D),
            Color(0xFF1C1917),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _EmberPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      periodName,
                      style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'STREAK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                // Hero flame + number
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFB923C),
                          size: 72,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$maxStreak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasStreak
                              ? (maxStreak == 1 ? 'DAY STREAK' : 'DAYS STREAK')
                              : 'LET\'S START ONE',
                          style: TextStyle(
                            color: const Color(0xFFF97316)
                                .withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Supporting badges
                Row(
                  children: [
                    Expanded(
                      child: _BadgePill(
                        icon: Icons.check_circle_rounded,
                        label: 'WORKOUTS',
                        value: workoutsScheduled > 0
                            ? '$workoutsCompleted / $workoutsScheduled'
                            : '$workoutsCompleted',
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BadgePill(
                        icon: Icons.trending_up_rounded,
                        label: 'RATE',
                        value: workoutsScheduled > 0
                            ? '${(workoutsCompleted / workoutsScheduled * 100).round()}%'
                            : '—',
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scattered warm embers — emulates glow rising from the fire.
class _EmberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.55),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final dot = Paint()
      ..color = const Color(0xFFFB923C).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    const points = <Offset>[
      Offset(0.18, 0.12), Offset(0.82, 0.18), Offset(0.12, 0.32),
      Offset(0.88, 0.40), Offset(0.22, 0.74), Offset(0.78, 0.80),
      Offset(0.50, 0.08), Offset(0.58, 0.88),
    ];
    const radii = <double>[1.6, 1.2, 1.8, 1.4, 1.5, 1.1, 1.3, 1.7];
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
        Offset(points[i].dx * size.width, points[i].dy * size.height),
        radii[i],
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
