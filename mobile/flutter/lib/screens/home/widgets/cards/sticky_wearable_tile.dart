/// F3.85 — Sticky wearable tile.
///
/// Persistent compact tile when a wearable has been connected but hasn't
/// pushed data in ≥24h. One-tap troubleshoot → /settings/wearables. Collapses
/// when the wearable is missing entirely (different empty state owned
/// elsewhere) or syncing normally.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/wearable_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class StaleWearableSignal {
  final String wearableLabel; // "Apple Watch", "Whoop", etc.
  final int hoursSinceLastSync;
  const StaleWearableSignal({
    required this.wearableLabel,
    required this.hoursSinceLastSync,
  });
}

/// Wires the existing [watchConnectedProvider] + [lastWatchSyncProvider]
/// (Wear OS bridge) into a "stale sync" signal. Returns null when there's no
/// connected wearable or the last sync is recent (<24h).
// TODO(backend): GET /api/v1/wearables/status for richer multi-device labels
// (Apple Watch, Whoop, Garmin) once those bridges land — current wiring covers
// the only connected wearable the app surfaces today.
final staleWearableSignalProvider =
    Provider.autoDispose<StaleWearableSignal?>((ref) {
  final connected = ref.watch(watchConnectedProvider);
  if (!connected) return null;
  final lastSync = ref.watch(lastWatchSyncProvider);
  if (lastSync == null) return null;
  final hours = DateTime.now().difference(lastSync).inHours;
  if (hours < 24) return null;
  return StaleWearableSignal(
    wearableLabel: 'Wear OS watch',
    hoursSinceLastSync: hours,
  );
});

class StickyWearableTile extends ConsumerWidget {
  const StickyWearableTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    StaleWearableSignal? signal;
    try {
      signal = ref.watch(staleWearableSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.hoursSinceLastSync < 24) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final hrs = signal.hoursSinceLastSync;
    final timeLabel = hrs >= 48 ? '${(hrs / 24).floor()} days' : '${hrs}h';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/settings/wearables');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.watch_off_rounded, size: 18, color: c.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${signal.wearableLabel} hasn\'t synced',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last data $timeLabel ago. Tap to fix.',
                      style: TextStyle(fontSize: 11.5, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
