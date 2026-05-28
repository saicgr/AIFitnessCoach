/// F3.9 — Body Battery tile.
///
/// Garmin-style 0–100 energy reserve. Self-collapses when no data is
/// available. Tap routes to `/recovery`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';

// TODO(backend): GET /api/v1/health/body-battery — Garmin-style composite
// requires a continuous-HRV / charge-discharge model that combines HRV +
// activity + stress + sleep over the day. HRV is unavailable (HC scope drop,
// 2026-05-07) and no first-party "body battery" derivation exists on the
// backend; recovery score (ReadinessScoreCard) is the closest single-shot proxy.
final bodyBatterySignalProvider = Provider.autoDispose<int?>((ref) => null);

class BodyBatteryTile extends ConsumerWidget {
  /// 0..100 — null collapses.
  final int? battery;

  const BodyBatteryTile({super.key, this.battery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = battery ?? ref.watch(bodyBatterySignalProvider);
    if (b == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final pct = (b / 100).clamp(0.0, 1.0);
    final label = b >= 75
        ? 'Charged'
        : b >= 50
            ? 'Steady'
            : b >= 25
                ? 'Low'
                : 'Drained';

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
                Icon(Icons.battery_charging_full, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Body battery',
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
              '$b',
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
