import 'package:flutter/material.dart';
import '_share_common.dart';

/// PR Poster — single giant PR weight with a delta chip. Renders the
/// biggest-delta weight PR from [prsData]. Caller wraps it in a lock
/// overlay when [prsData] is empty.
class PrPosterTemplate extends StatelessWidget {
  final String workoutName;
  final List<Map<String, dynamic>> prsData;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;
  final int durationSeconds;

  const PrPosterTemplate({
    super.key,
    required this.workoutName,
    required this.prsData,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';

    // Pick the biggest weight PR by absolute delta.
    Map<String, dynamic>? best;
    double bestDelta = -1;
    for (final p in prsData) {
      final type = p['pr_type'] as String? ?? 'weight';
      if (type != 'weight') continue;
      final improvement = (p['improvement'] as num?)?.toDouble() ?? 0;
      if (improvement > bestDelta) {
        bestDelta = improvement;
        best = p;
      }
    }
    best ??= prsData.isNotEmpty ? prsData.first : null;

    final exerciseName =
        (best?['exercise'] as String?)?.toUpperCase() ?? 'NEW PR';
    final weightKg = (best?['weight_kg'] as num? ?? best?['value'] as num?)
            ?.toDouble() ??
        0;
    final displayWeight = useKg ? weightKg : weightKg * 2.20462;
    final deltaKg = (best?['improvement'] as num?)?.toDouble();
    final displayDelta =
        deltaKg == null ? null : (useKg ? deltaKg : deltaKg * 2.20462);
    final reps = (best?['reps'] as num?)?.toInt();

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 0.9,
          colors: [Color(0xFF4A1A00), Color(0xFF0A0A0A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          ShareTrackedCaps(
            'NEW PR',
            size: 11,
            color: const Color(0xFFF97316),
            letterSpacing: 4,
          ),
          const Spacer(),
          ShareHeroNumber(
            value: displayWeight.round().toString(),
            unit: useKg ? 'kg' : 'lb',
            size: 180,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            exerciseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (displayDelta != null && displayDelta > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFF97316).withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Text(
                '+${displayDelta.round()} ${useKg ? 'KG' : 'LB'} FROM LAST',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (reps != null)
            ShareTrackedCaps(
              '$reps REPS',
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 3,
            ),
          const Spacer(),
          ShareFooterStrip(
            parts: [
              workoutName,
              formatShareDurationLong(durationSeconds),
              _formatDate(completedAt),
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
