import 'package:flutter/material.dart';
import '_share_common.dart';
import '_anatomy_painter.dart';

/// Anatomy Hero — the signature share template. Front + back body
/// silhouettes with trained muscles filled teal→cyan, sidebar lists
/// muscles sorted by set count, and a footer stat strip.
class AnatomyHeroTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int totalSets;
  final double? totalVolumeKg;
  final MuscleSetMap musclesWorked;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const AnatomyHeroTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    required this.totalSets,
    this.totalVolumeKg,
    this.musclesWorked = const {},
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final sortedMuscles = musclesWorked.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final vol = totalVolumeKg;

    return Container(
      color: const Color(0xFF05060A),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: date chip + workout name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ShareTrackedCaps(
              _formatDate(completedAt),
              size: 9,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            workoutName.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          // Anatomy + sidebar
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: AnatomyPainter(musclesWorked: musclesWorked),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShareTrackedCaps(
                        'MUSCLES',
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 9,
                      ),
                      const SizedBox(height: 8),
                      ...sortedMuscles.take(7).map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      e.key
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${e.value}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (sortedMuscles.isEmpty)
                        Text(
                          '—',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShareFooterStrip(
            parts: [
              formatShareDurationLong(durationSeconds),
              '$totalSets SETS',
              if (vol != null)
                formatShareWeight(vol, useKg: weightUnit == 'kg'),
            ],
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ShareWatermarkBadge(enabled: showWatermark),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
