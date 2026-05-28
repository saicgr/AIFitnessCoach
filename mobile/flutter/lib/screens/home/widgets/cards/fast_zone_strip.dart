/// F3.92 — Fasting Zone Strip.
///
/// Horizontal strip of fasting zones (Anabolic → Catabolic → Fat Burn →
/// Ketosis → Deep Ketosis → Autophagy) with the user's current elapsed-
/// hours position marked. Self-collapses when no active fast.
///
/// Read defensively from `fastingProvider` so a schema drift can't crash
/// home. Tap opens `/fasting` for the full timeline view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/services/haptic_service.dart';

class FastZoneStrip extends ConsumerWidget {
  const FastZoneStrip({super.key});

  // Hours threshold + label + accent tint. Mirrors the staged-zone model used
  // inside the dedicated /fasting screen so a tap doesn't reveal a different
  // taxonomy.
  static const List<({double hours, String label, Color tint})> _zones = [
    (hours: 0, label: 'Anabolic', tint: Color(0xFF7DD3FC)),
    (hours: 4, label: 'Catabolic', tint: Color(0xFF60A5FA)),
    (hours: 12, label: 'Fat burn', tint: Color(0xFFA78BFA)),
    (hours: 16, label: 'Ketosis', tint: Color(0xFFF472B6)),
    (hours: 24, label: 'Deep keto', tint: Color(0xFFFB923C)),
    (hours: 48, label: 'Autophagy', tint: Color(0xFFFACC15)),
  ];

  double _elapsedHours(WidgetRef ref) {
    // Watch the live timer so the strip ticks. Falls through to -1
    // (self-collapse) when there's no active fast.
    final active = ref.watch(activeFastProvider);
    if (active == null) return -1;
    // Subscribe to the per-second elapsed stream for live updates.
    final liveMins = ref.watch(fastingElapsedMinutesProvider);
    final mins = liveMins > 0 ? liveMins : active.elapsedMinutes;
    return mins / 60.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = _elapsedHours(ref);
    if (hours < 0) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/fasting');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            Text(
              'Fast progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  for (var i = 0; i < _zones.length; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            right: i == _zones.length - 1 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: hours >= _zones[i].hours
                              ? _zones[i].tint.withValues(alpha: 0.35)
                              : c.cardBorder.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _zones[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: hours >= _zones[i].hours
                                ? c.textPrimary
                                : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${hours.toStringAsFixed(1)}h elapsed',
              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
