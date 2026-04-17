import 'package:flutter/material.dart';
import '_share_common.dart';

/// Exercise Breakdown — numbered list of exercises with set × rep.
/// Poster typography; graceful degradation when exercise list is empty.
class ExerciseBreakdownTemplate extends StatelessWidget {
  final String workoutName;
  final List<ShareExerciseSummary> exercises;
  final int durationSeconds;
  final int totalSets;
  final double? totalVolumeKg;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const ExerciseBreakdownTemplate({
    super.key,
    required this.workoutName,
    this.exercises = const [],
    required this.durationSeconds,
    required this.totalSets,
    this.totalVolumeKg,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    final shown = exercises.take(8).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0B0F),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShareTrackedCaps(
            'TODAY\'S LIFTS',
            size: 10,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 3,
          ),
          const SizedBox(height: 6),
          Text(
            workoutName.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      '${exercises.isEmpty ? '—' : exercises.length} exercises',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shown.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 14),
                    itemBuilder: (context, i) {
                      final ex = shown[i];
                      final topWt = ex.topWeightKg;
                      return Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              (i + 1).toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF97316)
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ex.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${ex.sets} × ${ex.reps}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (topWt != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              formatShareWeightCompact(topWt, useKg: useKg),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          if (exercises.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+${exercises.length - 8} more',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ShareFooterStrip(
            parts: [
              formatShareDurationLong(durationSeconds),
              '$totalSets SETS',
              if (totalVolumeKg != null)
                formatShareWeight(totalVolumeKg, useKg: useKg),
            ],
            color: Colors.white.withValues(alpha: 0.5),
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
}
