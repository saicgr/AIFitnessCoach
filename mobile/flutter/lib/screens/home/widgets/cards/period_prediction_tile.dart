/// F3.33 — Next-period prediction tile. Shows expected start date with
/// a confidence pill ("low" / "medium" / "high"). Collapses if no
/// prediction or user isn't tracking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PeriodPredictionTile extends ConsumerWidget {
  const PeriodPredictionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    bool tracks = false;
    try {
      tracks = ref.watch(hasHormonalTrackingProvider);
    } catch (_) {}
    if (!tracks) return const SizedBox.shrink();

    CyclePrediction? pred;
    try {
      pred = ref.watch(cyclePredictionProvider).valueOrNull;
    } catch (_) {}
    if (pred == null || !pred.predictionsAvailable) {
      return const SizedBox.shrink();
    }

    final daysUntil = pred.daysUntilNextPeriod;
    final lateBy = pred.periodLateBy;
    final nextDate = pred.nextPeriodDate;

    String headline;
    String sub;
    if (lateBy != null && lateBy > 0) {
      headline = 'Period · $lateBy day${lateBy == 1 ? '' : 's'} late';
      sub = 'Log a period or update tracking.';
    } else if (daysUntil != null && nextDate != null) {
      if (daysUntil == 0) {
        headline = 'Period expected today';
      } else if (daysUntil == 1) {
        headline = 'Period in 1 day';
      } else {
        headline = 'Period in $daysUntil days';
      }
      sub = 'Estimated start ${_fmtDate(nextDate)}.';
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/cycle');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🩸', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    headline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ConfidencePill(confidence: pred.confidence),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _ConfidencePill extends StatelessWidget {
  final String confidence;
  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.cardBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        confidence,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
