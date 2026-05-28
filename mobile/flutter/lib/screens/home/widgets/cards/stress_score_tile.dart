/// F3.10 — Stress Score tile.
///
/// Continuous-stress 0–100 (low → high). Self-collapses when missing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';

// TODO(backend): GET /api/v1/health/stress-score — continuous-stress 0..100
// is HRV-variance-derived (Garmin/Whoop style: short-window RMSSD / pNN50
// fluctuation). HRV is unavailable post Health Connect scope drop
// (2026-05-07); no first-party stress derivation exists on the backend.
final stressScoreSignalProvider = Provider.autoDispose<int?>((ref) => null);

class StressScoreTile extends ConsumerWidget {
  /// 0..100 (higher = more stress). Null → collapsed.
  final int? stress;

  const StressScoreTile({super.key, this.stress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = stress ?? ref.watch(stressScoreSignalProvider);
    if (s == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final pct = (s / 100).clamp(0.0, 1.0);
    final label = s >= 75
        ? 'High'
        : s >= 50
            ? 'Elevated'
            : s >= 25
                ? 'Balanced'
                : 'Calm';
    // Stress is inverse-positive: high score uses the warning color from the
    // theme so users can see severity at a glance. The c.warning getter falls
    // back to a theme-appropriate orange.
    final stressColor = s >= 50 ? c.warning : c.accent;

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
                Icon(Icons.psychology_outlined, size: 16, color: stressColor),
                const SizedBox(width: 6),
                Text(
                  'Stress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$s',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: c.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(stressColor),
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
