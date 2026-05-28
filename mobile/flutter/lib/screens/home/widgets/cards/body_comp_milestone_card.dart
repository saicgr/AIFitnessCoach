/// F3.65 — Body composition milestone card.
///
/// Surfaces when a body-comp milestone is crossed (e.g. -10 lb, +5 lb LBM,
/// goal-weight reached). All copy is passed in so the widget stays free of
/// any opinion about direction or unit (lb vs kg).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/measurements_repository.dart';
import '../../../../data/services/haptic_service.dart';

class BodyCompMilestoneCard extends ConsumerWidget {
  final bool show;
  final String? milestoneLabel;
  final String? body;
  final IconData icon;

  const BodyCompMilestoneCard({
    super.key,
    this.show = true,
    this.milestoneLabel,
    this.body,
    this.icon = Icons.trending_down,
  });

  // Crossings (in lb-equivalents) we celebrate. Negative = loss, positive = gain.
  static const List<int> _lbMilestones = [-25, -20, -15, -10, -5, 5, 10, 15, 20];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Compute milestone from the live weight history when caller doesn't
    // override. We pick the largest crossed threshold (in lb) between the
    // earliest and latest weight log this user has on record.
    String resolvedLabel = milestoneLabel ?? '';
    String resolvedBody = body ?? '';
    if (milestoneLabel == null || body == null) {
      final state = ref.watch(measurementsProvider);
      final history =
          state.historyByType[MeasurementType.weight] ?? const [];
      if (history.length < 2) return const SizedBox.shrink();
      // Repository sorts history newest-first; oldest is the last entry.
      final newest = history.first;
      final oldest = history.last;
      final useKg = ref.watch(useKgProvider);
      // Convert stored value (kg) to display unit before milestone match.
      double toDisplay(double kg) => useKg ? kg : kg * 2.2046226218;
      final deltaDisplay = toDisplay(newest.value) - toDisplay(oldest.value);
      final unit = useKg ? 'kg' : 'lb';
      // Find the largest-magnitude milestone crossed in the user's display unit.
      int? crossed;
      for (final m in _lbMilestones) {
        if (m < 0 && deltaDisplay <= m) {
          if (crossed == null || m.abs() > crossed.abs()) crossed = m;
        } else if (m > 0 && deltaDisplay >= m) {
          if (crossed == null || m.abs() > crossed.abs()) crossed = m;
        }
      }
      if (crossed == null) return const SizedBox.shrink();
      resolvedLabel = milestoneLabel ?? '${crossed > 0 ? '+' : ''}$crossed $unit milestone';
      resolvedBody = body ??
          (crossed < 0
              ? 'Down ${crossed.abs()} $unit from your start weight. Steady progress.'
              : 'Up $crossed $unit from your start weight — keep building.');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/profile?tab=measurements');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: c.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedLabel,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resolvedBody,
                      style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
