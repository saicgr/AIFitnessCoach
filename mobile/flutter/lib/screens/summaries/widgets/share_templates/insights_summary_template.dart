import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: period-level summary (1W / 1M / 3M / 6M / 1Y).
/// 2x2 grid of big numbers with previous-period deltas.
///
/// [periodName] is the capitalized period word that appears as the hero
/// title (e.g. "WEEKLY", "MONTHLY", "QUARTERLY", "HALF-YEAR", "YEARLY") —
/// lets every template in the carousel clearly advertise which time window
/// the user is sharing.
class InsightsSummaryTemplate extends StatelessWidget {
  final String periodLabel; // e.g. "1M", short chip
  final String periodName; // e.g. "MONTHLY", hero title
  final String dateRangeLabel; // e.g. "Mar 12 - Apr 11"
  final int workoutsCompleted;
  final int totalTimeMinutes;
  final int totalCalories;
  final int totalPrs;
  final int? prevWorkouts;
  final int? prevTimeMinutes;
  final int? prevCalories;
  final int? prevPrs;
  final bool showWatermark;

  const InsightsSummaryTemplate({
    super.key,
    required this.periodLabel,
    required this.periodName,
    required this.dateRangeLabel,
    required this.workoutsCompleted,
    required this.totalTimeMinutes,
    required this.totalCalories,
    required this.totalPrs,
    this.prevWorkouts,
    this.prevTimeMinutes,
    this.prevCalories,
    this.prevPrs,
    this.showWatermark = true,
  });

  String _fmtTime(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  String _fmtCalories(int kcal) {
    if (kcal >= 1000) return '${(kcal / 1000).toStringAsFixed(1)}k';
    return '$kcal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF0D1117),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFF00D9FF).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        periodLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  periodName,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                  ),
                ),
                const Text(
                  'SUMMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                _BigStatTile(
                  icon: Icons.fitness_center_rounded,
                  label: 'WORKOUTS',
                  value: '$workoutsCompleted',
                  delta: _calcDelta(workoutsCompleted, prevWorkouts),
                  color: const Color(0xFF00D9FF),
                ),
                const SizedBox(height: 10),
                _BigStatTile(
                  icon: Icons.timer_rounded,
                  label: 'TIME',
                  value: _fmtTime(totalTimeMinutes),
                  delta: _calcDelta(totalTimeMinutes, prevTimeMinutes),
                  color: const Color(0xFF60A5FA),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _HalfTile(
                        icon: Icons.local_fire_department_rounded,
                        label: 'CALORIES',
                        value: _fmtCalories(totalCalories),
                        color: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HalfTile(
                        icon: Icons.emoji_events_rounded,
                        label: 'PRs',
                        value: '$totalPrs',
                        color: const Color(0xFFFBBF24),
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

  /// Returns a (label, isPositive) tuple for a metric vs its previous period.
  /// Null previous means no comparison available.
  _DeltaInfo? _calcDelta(num current, num? previous) {
    if (previous == null || previous == 0) return null;
    final change = current - previous;
    if (change == 0) return null;
    final pct = (change / previous * 100).round();
    return _DeltaInfo(
      label: '${change > 0 ? '+' : ''}$pct%',
      isPositive: change > 0,
    );
  }
}

class _DeltaInfo {
  final String label;
  final bool isPositive;
  const _DeltaInfo({required this.label, required this.isPositive});
}

class _BigStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _DeltaInfo? delta;
  final Color color;

  const _BigStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (delta != null)
            _DeltaPill(
              label: delta!.label,
              isPositive: delta!.isPositive,
            ),
        ],
      ),
    );
  }
}

class _HalfTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HalfTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final String label;
  final bool isPositive;

  const _DeltaPill({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
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
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
