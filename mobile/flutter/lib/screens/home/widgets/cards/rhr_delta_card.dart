/// F3.120 — Resting HR delta card.
///
/// Compares today's RHR against the user's 14-day rolling baseline
/// (`GET /api/v1/health/rhr-delta`). Self-collapses if no RHR signal is
/// available (no reading today, or fewer than 3 baseline days).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/rhr_delta_provider.dart';
import '../../../../data/services/haptic_service.dart';

class RhrDeltaCard extends ConsumerWidget {
  const RhrDeltaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rhrDeltaProvider);
    final data = async.valueOrNull;
    if (data == null || !data.hasSignal) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    final rhr = data.todayRhrBpm!;
    final delta = data.deltaBpm ?? 0.0;
    final lower = delta <= -3.0;
    final tint = data.elevated
        ? const Color(0xFFF87171)
        : (lower ? const Color(0xFF34D399) : c.accent);
    final label = data.elevated
        ? 'Elevated — consider an easier session today'
        : (lower
            ? 'Below baseline — well-recovered'
            : 'Within normal range');

    final deltaText = delta == 0
        ? '±0'
        : (delta > 0
            ? '+${delta.toStringAsFixed(1)}'
            : delta.toStringAsFixed(1));

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=wearable');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_outline, color: tint, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RHR $rhr bpm ($deltaText vs baseline)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style:
                          TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
