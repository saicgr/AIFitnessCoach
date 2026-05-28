/// F3.14 — Micronutrient gap chip.
///
/// One-line chip surfacing the single most-deficient micronutrient based on
/// today's food log vs. RDA. Self-collapses when no gap is reported.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/micronutrient_gap_provider.dart';

/// Server-backed "biggest gap today" signal — `GET /nutrition/micros/today-gap`.
///
/// Returns null fields when there's not enough logged-food signal yet (chip
/// self-collapses). The provider error path is swallowed to a null signal so
/// a transient API hiccup never crashes the home feed.
final micronutrientGapSignalProvider =
    Provider.autoDispose<({String? nutrient, double? percentOfRda})>((ref) {
  final async = ref.watch(micronutrientGapProvider);
  return async.when(
    data: (gap) => (
      nutrient: gap.hasGap ? gap.nutrient : null,
      percentOfRda: gap.hasGap ? gap.coveragePct : null,
    ),
    loading: () => (nutrient: null, percentOfRda: null),
    error: (_, __) => (nutrient: null, percentOfRda: null),
  );
});

class MicronutrientGapChip extends ConsumerWidget {
  /// Nutrient label (e.g. "Iron", "Vitamin D"). Null → collapsed.
  final String? nutrient;

  /// Percent of RDA achieved today (0..100). Null → collapsed.
  final double? percentOfRda;

  const MicronutrientGapChip({
    super.key,
    this.nutrient,
    this.percentOfRda,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(micronutrientGapSignalProvider);
    final n = nutrient ?? signal.nutrient;
    final p = percentOfRda ?? signal.percentOfRda;
    if (n == null || p == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final pctClamped = p.clamp(0.0, 100.0);

    return GestureDetector(
      onTap: () => context.go('/nutrition'),
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
                Icon(Icons.science_outlined, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Micronutrient gap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$n at ${pctClamped.toStringAsFixed(0)}% RDA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pctClamped / 100,
                minHeight: 6,
                backgroundColor: c.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(c.warning),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to see food suggestions',
              style: TextStyle(fontSize: 11.5, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
