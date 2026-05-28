/// F3.12 — VO2max trend chip.
///
/// Compact single-line tile showing latest VO2max (ml/kg/min) and a delta
/// vs. previous measurement. Collapses when no value is set.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/vo2max_repository.dart';

/// (latest, previous) ml/kg/min derived from the real VO2max endpoints:
///   • /vo2max/latest  → newest measurement
///   • /vo2max/history → previous point for delta
/// Returns (null, _) until at least one measurement exists, which keeps the
/// card collapsed.
final vo2maxTrendSignalProvider =
    Provider.autoDispose<({double? latest, double? previous})>((ref) {
  final latestAsync = ref.watch(vo2MaxLatestProvider);
  final historyAsync = ref.watch(vo2MaxHistoryProvider);
  final latest = latestAsync.maybeWhen(
    data: (l) => l.mlPerKgPerMin,
    orElse: () => null,
  );
  final previous = historyAsync.maybeWhen(
    data: (pts) {
      if (pts.length < 2) return null;
      // history() returns ascending — the prior point is the second-to-last.
      return pts[pts.length - 2].mlPerKgPerMin;
    },
    orElse: () => null,
  );
  return (latest: latest, previous: previous);
});

class Vo2maxTrendChip extends ConsumerWidget {
  /// Latest estimate. Null → collapsed.
  final double? latest;

  /// Optional previous-period value for delta arrow.
  final double? previous;

  const Vo2maxTrendChip({super.key, this.latest, this.previous});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(vo2maxTrendSignalProvider);
    final v = latest ?? signal.latest;
    if (v == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final prev = previous ?? signal.previous;
    final delta = (prev != null) ? v - prev : null;
    final arrow = delta == null
        ? null
        : (delta > 0.05
            ? Icons.arrow_upward
            : delta < -0.05
                ? Icons.arrow_downward
                : Icons.remove);
    final deltaColor = delta == null
        ? c.textMuted
        : (delta >= 0 ? c.success : c.warning);

    return GestureDetector(
      onTap: () => context.go('/progress'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_border, size: 16, color: c.accent),
            const SizedBox(width: 8),
            Text(
              'VO2max',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              v.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            Text(
              ' ml/kg/min',
              style: TextStyle(fontSize: 11.5, color: c.textMuted),
            ),
            if (arrow != null) ...[
              const SizedBox(width: 6),
              Icon(arrow, size: 14, color: deltaColor),
              Text(
                delta!.abs().toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: deltaColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
