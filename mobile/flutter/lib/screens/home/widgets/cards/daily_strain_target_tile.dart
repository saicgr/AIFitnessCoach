/// F3.108 — Daily strain target tile.
///
/// Surfaces today's training-load target on a 0-21 strain band (Whoop-style)
/// based on prior 7-day rolling load. Tap opens the wearable detail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class DailyStrainTargetTile extends ConsumerWidget {
  const DailyStrainTargetTile({super.key});

  // TODO(backend): GET /api/v1/wearable/strain (today + 7-day rolling target)
  // Returns null while no strain endpoint / provider exists so the tile
  // self-collapses rather than show synthetic numbers.
  ({double current, double target}) _readStrain(WidgetRef ref) {
    return (current: 0, target: 0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = _readStrain(ref);
    if (s.target <= 0) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final progress = (s.current / s.target).clamp(0.0, 1.0);

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
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: c.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Strain target',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${s.current.toStringAsFixed(1)} / ${s.target.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: c.cardBorder.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
