import 'package:flutter/material.dart';
import '_share_common.dart';

/// Retro 80s — synthwave aesthetic. Magenta/cyan chrome sun horizon
/// with a receding grid floor. Hero stats in big retro-caps type.
class Retro80sTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final double? totalVolumeKg;
  final int totalSets;
  final int? calories;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const Retro80sTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.totalVolumeKg,
    required this.totalSets,
    this.calories,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _SynthwavePainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              ShareTrackedCaps(
                'MAX EFFORT',
                size: 11,
                color: const Color(0xFFFF71CE),
                letterSpacing: 5,
              ),
              const SizedBox(height: 14),
              // Big chrome hero "workout name"
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFEEFF),
                    Color(0xFFFF71CE),
                    Color(0xFF7B3FB3),
                  ],
                  stops: [0, 0.55, 1],
                ).createShader(rect),
                child: Text(
                  workoutName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Two-column stats with neon borders
              Row(
                children: [
                  Expanded(
                    child: _NeonBox(
                      label: 'VOLUME',
                      value: totalVolumeKg == null
                          ? '—'
                          : formatShareWeightCompact(totalVolumeKg, useKg: useKg),
                      color: const Color(0xFFFF71CE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NeonBox(
                      label: 'SETS',
                      value: '$totalSets',
                      color: const Color(0xFF01CDFE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _NeonBox(
                      label: 'TIME',
                      value: formatShareDurationLong(durationSeconds),
                      color: const Color(0xFF01CDFE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NeonBox(
                      label: 'CALORIES',
                      value: calories == null ? '—' : '$calories',
                      color: const Color(0xFFFF71CE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ShareTrackedCaps(
                '▸ ${_formatDate(completedAt)} ◂',
                size: 10,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 4,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: ShareWatermarkBadge(enabled: showWatermark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')} \'${d.year.toString().substring(2)}';
  }
}

class _NeonBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NeonBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
              shadows: [Shadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SynthwavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0033),
            Color(0xFF3F0A5C),
            Color(0xFF0C0016),
          ],
        ).createShader(Offset.zero & size),
    );
    // Sun horizon
    final sunRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.7,
      height: size.height * 0.4,
    );
    canvas.drawOval(
      sunRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEEFF), Color(0xFFFF71CE), Color(0xFF7B3FB3)],
        ).createShader(sunRect),
    );
    // Sun horizontal stripes (negative space)
    final bgPaint = Paint()..color = const Color(0xFF3F0A5C);
    for (int i = 0; i < 5; i++) {
      final y = sunRect.top + sunRect.height * (0.5 + i * 0.08);
      canvas.drawRect(
        Rect.fromLTWH(sunRect.left, y, sunRect.width, 3),
        bgPaint,
      );
    }
    // Grid floor
    final floorPaint = Paint()
      ..color = const Color(0xFF01CDFE).withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    final horizonY = size.height * 0.58;
    // Vertical lines receding
    for (int i = -8; i <= 8; i++) {
      final bottomX = size.width / 2 + i * (size.width / 6);
      canvas.drawLine(
        Offset(size.width / 2, horizonY),
        Offset(bottomX, size.height + 20),
        floorPaint,
      );
    }
    // Horizontal floor bands
    for (int i = 0; i < 6; i++) {
      final t = i / 6;
      final y = horizonY + (size.height - horizonY) * (t * t);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        floorPaint..color = const Color(0xFF01CDFE).withValues(alpha: 0.35 + t * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
