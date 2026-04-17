import 'package:flutter/material.dart';
import '_share_common.dart';

/// Volume Hero — giant number + Hevy-style comparison copy + orbital
/// mini stats. Works when the user has any training volume at all.
class VolumeHeroTemplate extends StatelessWidget {
  final String workoutName;
  final double? totalVolumeKg;
  final int durationSeconds;
  final int totalSets;
  final int totalReps;
  final int exercisesCount;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const VolumeHeroTemplate({
    super.key,
    required this.workoutName,
    this.totalVolumeKg,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalReps,
    required this.exercisesCount,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    final displayVolume = totalVolumeKg == null
        ? 0.0
        : (useKg ? totalVolumeKg! : totalVolumeKg! * 2.20462);
    final formatted = displayVolume >= 10000
        ? '${(displayVolume / 1000).toStringAsFixed(1)}k'
        : displayVolume.round().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            );
    final comparison = comparisonCopyForVolume(displayVolume, useKg: useKg);

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0xFF2A1A00), Color(0xFF05060A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShareTrackedCaps(
            workoutName,
            size: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 6),
          ShareTrackedCaps(
            'TOTAL VOLUME',
            size: 9,
            color: const Color(0xFFF59E0B),
            letterSpacing: 4,
          ),
          const Spacer(),
          ShareHeroNumber(
            value: formatted,
            unit: useKg ? 'kg' : 'lb',
            size: 130,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '— that\'s $comparison —',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShareStatPill(
                icon: Icons.timer_outlined,
                value: formatShareDurationLong(durationSeconds),
                label: 'TIME',
              ),
              ShareStatPill(
                icon: Icons.fitness_center,
                value: '$exercisesCount',
                label: 'EXERCISES',
              ),
              ShareStatPill(
                icon: Icons.repeat,
                value: '$totalSets',
                label: 'SETS',
              ),
              ShareStatPill(
                icon: Icons.tag,
                value: '$totalReps',
                label: 'REPS',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ShareWatermarkBadge(enabled: showWatermark),
          ),
        ],
      ),
    );
  }
}
