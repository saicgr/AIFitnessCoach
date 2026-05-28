/// F3.77 — Strain vs recovery mismatch card.
///
/// Fires when wearable-derived strain (HR, training load) outpaces recovery
/// (HRV, RHR, sleep efficiency) for ≥3 consecutive days. Suggests a
/// lighter/active-recovery session and links to the recovery dashboard.
///
/// TODO(backend): the live `/insights/strain-recovery-mismatch` endpoint
/// substitutes `sleep_minutes` for recovery because HRV is unavailable
/// (HC scope dropped 2026-05-07). When HRV returns, swap the recovery
/// proxy in `backend/api/v1/home_insights.py` for an HRV-weighted score.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/strain_recovery_mismatch_provider.dart';
import '../../../../data/services/haptic_service.dart';

class StrainRecoveryMismatch {
  /// Number of weeks the trend has been observed over (3 weeks today).
  final int consecutiveDays;
  /// Synthetic strain score (0-100) derived from the trend classification.
  final int strainScore;
  /// Synthetic recovery score (0-100) derived from the trend classification.
  final int recoveryScore;
  const StrainRecoveryMismatch({
    required this.consecutiveDays,
    required this.strainScore,
    required this.recoveryScore,
  });

  int get gap => strainScore - recoveryScore;
}

/// Server-backed strain/recovery mismatch — `GET /insights/strain-recovery-mismatch`.
///
/// The backend classifies each 21-day series as up/flat/down. We map that
/// pair to a synthetic 0-100 score so the existing card layout (which is
/// score/gap-driven) keeps working without a deeper refactor:
///   - strain "up"   → 80,  "flat" → 50,  "down" → 30
///   - recovery same scale, then card shows gap >= 20 only when there's a
///     real mismatch (recommend_deload == true).
int _scoreForStrain(String t) {
  switch (t) {
    case 'up':
      return 80;
    case 'down':
      return 30;
    default:
      return 50;
  }
}

int _scoreForRecovery(String t) {
  switch (t) {
    case 'up':
      return 70;
    case 'down':
      return 30;
    default:
      return 45;
  }
}

final strainRecoveryMismatchProvider =
    Provider.autoDispose<StrainRecoveryMismatch?>((ref) {
  final async = ref.watch(strainRecoveryMismatchApiProvider);
  return async.when(
    data: (api) {
      if (!api.recommendDeload) return null;
      return StrainRecoveryMismatch(
        // Card gate is `consecutiveDays < 3`. weeks_observed is 3 by default,
        // and the card copy reads "For N days running" — 21 days ≈ 3 weeks
        // of rolling window, so feed days directly.
        consecutiveDays: api.weeksObserved * 7,
        strainScore: _scoreForStrain(api.strainTrend),
        recoveryScore: _scoreForRecovery(api.recoveryTrend),
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class StrainRecoveryMismatchCard extends ConsumerWidget {
  const StrainRecoveryMismatchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    StrainRecoveryMismatch? data;
    try {
      data = ref.watch(strainRecoveryMismatchProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (data == null || data.consecutiveDays < 3 || data.gap < 20) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bolt_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Strain is outrunning recovery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'For ${data.consecutiveDays} days running, your load has been high while recovery markers are low (gap: ${data.gap} pts). A lighter session today protects next week.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.medium();
                  context.push('/workout/active-recovery');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Switch to active recovery',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
