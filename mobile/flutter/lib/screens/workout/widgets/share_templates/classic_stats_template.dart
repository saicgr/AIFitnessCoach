import 'package:flutter/material.dart';
import '_share_common.dart';

/// Classic Stats — refined 2×2 stat grid. Replaces the bland `stats_template.dart`
/// that shipped originally. Keeps the grid-paper background aesthetic but
/// promotes the hero typography and fixes the weight unit.
class ClassicStatsTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;
  final int exercisesCount;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const ClassicStatsTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    required this.exercisesCount,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1522), Color(0xFF070709)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShareTrackedCaps(
                  _formatDate(completedAt),
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 6),
                Text(
                  workoutName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                ShareTrackedCaps(
                  'WORKOUT COMPLETE',
                  size: 10,
                  color: const Color(0xFF06B6D4),
                  letterSpacing: 3,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.timer_outlined,
                                label: 'DURATION',
                                value: formatShareDurationLong(durationSeconds),
                                accent: const Color(0xFFA855F7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.fitness_center,
                                label: 'EXERCISES',
                                value: '$exercisesCount',
                                accent: const Color(0xFFA855F7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.scale,
                                label: 'VOLUME',
                                value: totalVolumeKg == null
                                    ? '—'
                                    : formatShareWeightCompact(
                                        totalVolumeKg,
                                        useKg: useKg,
                                      ),
                                accent: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.local_fire_department,
                                label: 'CALORIES',
                                value: calories == null ? '—' : '$calories',
                                accent: const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShareWatermarkBadge(enabled: showWatermark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          ShareTrackedCaps(
            label,
            size: 9,
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 2,
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x11FFFFFF)
      ..strokeWidth = 0.4;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
