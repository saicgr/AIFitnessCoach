/// F3.20 — Smoothed weight trend chip.
///
/// 7-day EMA of weight vs. previous 7-day EMA — surfaces the underlying
/// trend through daily water-noise. Collapses when fewer than 2 weights
/// available.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';

/// (currentEma, priorEma) in the user's body-weight unit, computed from
/// `nutritionPreferencesProvider.weightHistory` (real WeightLog rows).
///
/// EMA uses standard alpha = 2/(N+1) with N=7 (matches the "7-day EMA"
/// product label). The prior EMA replays the EMA up to the last point that
/// is ≥7 days older than the latest, giving a stable week-over-week delta.
/// Returns (null, null) when fewer than 2 weights exist → chip collapses.
final smoothedWeightTrendSignalProvider =
    Provider.autoDispose<({double? currentEma, double? priorEma, String unit})>(
        (ref) {
  final prefs = ref.watch(nutritionPreferencesProvider);
  final unit = ref.watch(weightUnitProvider); // 'lbs' | 'kg'
  // weightHistory is newest-first (cf. nutrition_preferences_provider.dart:547)
  final history = prefs.weightHistory;
  if (history.length < 2) {
    return (currentEma: null, priorEma: null, unit: unit);
  }

  // Convert to user unit + sort oldest → newest for the EMA pass.
  final useKg = unit == 'kg';
  final points = [
    for (final w in history)
      (
        at: w.loggedAt,
        value: useKg ? w.weightKg : w.weightKg * 2.20462,
      ),
  ]..sort((a, b) => a.at.compareTo(b.at));

  const n = 7;
  final alpha = 2 / (n + 1);
  double? ema;
  double? priorEma;
  final cutoff = points.last.at.subtract(const Duration(days: 7));
  for (final p in points) {
    ema = (ema == null) ? p.value : (alpha * p.value + (1 - alpha) * ema);
    // Snapshot the EMA at the last point that is still ≥7 days behind the
    // most recent weight — that's the "prior 7-day EMA" baseline.
    if (!p.at.isAfter(cutoff)) priorEma = ema;
  }
  return (
    currentEma: ema,
    priorEma: priorEma,
    unit: unit,
  );
});

class SmoothedWeightTrendChip extends ConsumerWidget {
  /// Current EMA in user's body-weight unit ('lb' or 'kg').
  final double? currentEma;

  /// 7-day prior EMA. Null disables delta display.
  final double? priorEma;

  /// Display unit; 'lb' or 'kg'.
  final String unit;

  const SmoothedWeightTrendChip({
    super.key,
    this.currentEma,
    this.priorEma,
    this.unit = 'lb',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(smoothedWeightTrendSignalProvider);
    final e = currentEma ?? signal.currentEma;
    if (e == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final pEma = priorEma ?? signal.priorEma;
    final delta = pEma != null ? e - pEma : null;
    final effectiveUnit = currentEma != null
        ? unit
        : (signal.unit == 'kg' ? 'kg' : 'lb');
    final isDown = delta != null && delta < 0;
    final isFlat = delta != null && delta.abs() < 0.1;
    final deltaColor = delta == null
        ? c.textMuted
        : (isFlat
            ? c.textMuted
            : (isDown ? c.success : c.warning));

    return GestureDetector(
      onTap: () => context.go('/progress'),
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
                Icon(Icons.trending_flat, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Weight trend (7-day)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  e.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Text(effectiveUnit,
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                const Spacer(),
                if (delta != null)
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} $effectiveUnit',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: deltaColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Smoothed across daily variance',
              style: TextStyle(fontSize: 11.5, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
