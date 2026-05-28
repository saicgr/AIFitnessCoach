/// F3.5 — Readiness Score card.
///
/// Compact tile that renders today's composite readiness score (0–100) with a
/// short qualitative label. Self-collapses to [SizedBox.shrink] when no data
/// is available so it composes safely into the SubCardRanker output without
/// adding empty placeholder UI to the home feed.
///
/// Self-contained: theme-aware via [ThemeColors]. Tap routes to `/recovery`
/// for the full breakdown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/recovery_provider.dart';

/// Local readiness signal — derived from the real `recoveryProvider`
/// (RHR + sleep). Returns null until Health Connect / HealthKit is
/// connected and a score is computed, which keeps the card collapsed.
final readinessScoreSignalProvider = Provider.autoDispose<int?>((ref) {
  final async = ref.watch(recoveryProvider);
  return async.maybeWhen(
    data: (r) => r?.score,
    orElse: () => null,
  );
});

class ReadinessScoreCard extends ConsumerWidget {
  /// Score 0..100 — optional override; falls back to the real recovery
  /// provider when null. Null + no real signal → collapsed.
  final int? score;

  const ReadinessScoreCard({super.key, this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = score ?? ref.watch(readinessScoreSignalProvider);
    if (s == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    final label = s >= 80
        ? 'Primed'
        : s >= 60
            ? 'Ready'
            : s >= 40
                ? 'Moderate'
                : 'Recover';

    return GestureDetector(
      onTap: () => context.go('/recovery'),
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
                Icon(Icons.bolt_outlined, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Readiness',
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
                  '$s',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Text('/100', style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (s / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: c.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
