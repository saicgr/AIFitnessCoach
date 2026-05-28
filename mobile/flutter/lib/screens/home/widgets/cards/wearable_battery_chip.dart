/// F3.66 — Wearable battery low chip.
///
/// Compact informational chip that surfaces when the connected wearable
/// reports < ~15% battery. No CTA beyond acknowledgement / dismiss; the
/// signal is just "charge it before bed."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';

// Live signal: `GET /api/v1/wearables/battery` returns the latest stored
// snapshot (one row per user). Chip fires when battery < 15%; collapses
// otherwise. Constructor overrides remain for ranker / tests.

class WearableBatteryChip extends ConsumerWidget {
  final bool show;
  final int? batteryPercent;
  final String deviceLabel;

  const WearableBatteryChip({
    super.key,
    this.show = true,
    this.batteryPercent,
    this.deviceLabel = 'Wearable',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    // Prefer constructor override, otherwise read live from backend.
    int? pct = batteryPercent;
    String label = deviceLabel;
    if (pct == null) {
      final live = ref.watch(wearableBatteryProvider).valueOrNull;
      if (live == null) return const SizedBox.shrink();
      pct = live.batteryPct;
      if (live.source != null && live.source!.isNotEmpty) {
        label = _formatSource(live.source!);
      }
    }
    if (pct == null || pct >= 15) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.battery_alert,
                size: 18, color: c.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label battery at $pct% — charge before bed for overnight readings.',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 'apple_watch' → 'Apple Watch', 'whoop' → 'Whoop', etc.
  String _formatSource(String raw) {
    if (raw.isEmpty) return 'Wearable';
    final parts = raw.split('_').where((s) => s.isNotEmpty).toList();
    return parts
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
