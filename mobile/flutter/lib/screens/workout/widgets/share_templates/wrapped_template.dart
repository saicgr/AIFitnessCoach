import 'package:flutter/material.dart';
import '_share_common.dart';

/// Wrapped — Spotify Wrapped-inspired diagonal color blocks + 3 hero
/// numbered stats. Type-forward, highly shareable format.
class WrappedTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final double? totalVolumeKg;
  final int totalSets;
  final int exercisesCount;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const WrappedTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.totalVolumeKg,
    required this.totalSets,
    required this.exercisesCount,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    return Stack(
      children: [
        // Diagonal color blocks
        Positioned.fill(
          child: CustomPaint(painter: _WrappedBgPainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShareTrackedCaps(
                'YOUR SESSION',
                size: 11,
                color: Colors.white,
                letterSpacing: 4,
              ),
              const SizedBox(height: 2),
              Text(
                'WRAPPED',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              _WrappedBlock(
                index: '01',
                label: 'TIME',
                value: formatShareDurationLong(durationSeconds),
                color: const Color(0xFFFF006E),
              ),
              const SizedBox(height: 18),
              _WrappedBlock(
                index: '02',
                label: 'VOLUME',
                value: totalVolumeKg == null
                    ? '—'
                    : formatShareWeightCompact(totalVolumeKg, useKg: useKg),
                color: const Color(0xFF3A86FF),
              ),
              const SizedBox(height: 18),
              _WrappedBlock(
                index: '03',
                label: '${workoutName.toUpperCase()} SETS',
                value: '$totalSets',
                color: const Color(0xFFFB5607),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$exercisesCount exercises · ${_formatDate(completedAt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  ShareWatermarkBadge(enabled: showWatermark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year.toString().substring(2)}';
}

class _WrappedBlock extends StatelessWidget {
  final String index;
  final String label;
  final String value;
  final Color color;

  const _WrappedBlock({
    required this.index,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          index,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WrappedBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0C0010));
    // Diagonal neon bands
    final bands = [
      (const Color(0xFFFF006E), 0.12),
      (const Color(0xFF3A86FF), 0.09),
      (const Color(0xFFFB5607), 0.1),
    ];
    for (int i = 0; i < bands.length; i++) {
      final color = bands[i].$1.withValues(alpha: bands[i].$2);
      final path = Path();
      final yStart = size.height * (0.15 + i * 0.2);
      path.moveTo(-40, yStart);
      path.lineTo(size.width + 40, yStart - 80);
      path.lineTo(size.width + 40, yStart - 60);
      path.lineTo(-40, yStart + 20);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
