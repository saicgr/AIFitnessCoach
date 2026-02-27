import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats PRs Template - Shows Personal Records summary
/// Clean design highlighting recent PRs and achievements
class StatsPRsTemplate extends StatelessWidget {
  final List<PRData> recentPRs;
  final int totalPRCount;
  final String dateRangeLabel;
  final bool showWatermark;

  const StatsPRsTemplate({
    super.key,
    required this.recentPRs,
    required this.totalPRCount,
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative PR badges background
          Positioned.fill(
            child: CustomPaint(
              painter: _PRBadgePainter(),
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
                  'PERSONAL RECORDS',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  dateRangeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // PR Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info.withOpacity(0.3),
                        AppColors.purple.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.military_tech,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalPRCount PRs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent PRs list
                Expanded(
                  child: recentPRs.isEmpty
                      ? _EmptyPRsState()
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentPRs.take(4).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pr = recentPRs[index];
                            return _PRCard(pr: pr);
                          },
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

/// Personal Record data model
class PRData {
  final String exerciseName;
  final String value;
  final String unit;
  final String date;
  final PRType type;

  const PRData({
    required this.exerciseName,
    required this.value,
    required this.unit,
    required this.date,
    this.type = PRType.weight,
  });
}

enum PRType {
  weight,
  reps,
  time,
  distance,
}

class _PRCard extends StatelessWidget {
  final PRData pr;

  const _PRCard({required this.pr});

  IconData get _typeIcon {
    switch (pr.type) {
      case PRType.weight:
        return Icons.fitness_center;
      case PRType.reps:
        return Icons.repeat;
      case PRType.time:
        return Icons.timer;
      case PRType.distance:
        return Icons.straighten;
    }
  }

  Color get _typeColor {
    switch (pr.type) {
      case PRType.weight:
        return AppColors.info;
      case PRType.reps:
        return AppColors.purple;
      case PRType.time:
        return AppColors.orange;
      case PRType.distance:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _typeIcon,
              color: _typeColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Exercise name and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  pr.date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // PR value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${pr.value} ${pr.unit}',
              style: TextStyle(
                color: _typeColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPRsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No PRs yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          Text(
            'Keep pushing to set records!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative PR badge pattern painter
class _PRBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw some decorative stars/badges
    final positions = [
      Offset(30, 80),
      Offset(size.width - 40, 120),
      Offset(50, size.height - 120),
      Offset(size.width - 50, size.height - 100),
    ];

    for (final pos in positions) {
      // Outer glow
      paint.color = Colors.amber.withOpacity(0.05);
      canvas.drawCircle(pos, 20, paint);

      // Inner star
      paint.color = Colors.amber.withOpacity(0.08);
      _drawStar(canvas, pos, 8, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadius = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : radius * innerRadius;

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

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
