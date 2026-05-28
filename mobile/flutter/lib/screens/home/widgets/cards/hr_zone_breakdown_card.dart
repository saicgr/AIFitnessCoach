/// F3.118 — HR zone breakdown card.
///
/// Stacked horizontal bar of time spent in each HR zone (Z1..Z5) during
/// today's session. Self-collapses if no HR data was recorded.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class HrZoneBreakdownCard extends ConsumerWidget {
  const HrZoneBreakdownCard({super.key});

  static const List<({String label, Color color})> _zones = [
    (label: 'Z1', color: Color(0xFF60A5FA)),
    (label: 'Z2', color: Color(0xFF34D399)),
    (label: 'Z3', color: Color(0xFFFACC15)),
    (label: 'Z4', color: Color(0xFFFB923C)),
    (label: 'Z5', color: Color(0xFFF87171)),
  ];

  // TODO(backend): expose `hr_zone_minutes: [z1,z2,z3,z4,z5]` on the
  // completed-workout payload (derived from BLE/wearable HR stream during
  // the session). Returns empty so the card self-collapses until then.
  List<int> _readMinutes(WidgetRef ref) {
    ref.watch(todayWorkoutProvider);
    return const [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = _readMinutes(ref);
    if (minutes.isEmpty) return const SizedBox.shrink();
    final total = minutes.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=stats');
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
            Text(
              'Heart-rate zones',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (var i = 0; i < _zones.length; i++)
                      Expanded(
                        flex: minutes[i] == 0 ? 0 : minutes[i],
                        child: Container(color: _zones[i].color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _zones.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _zones[i].color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('${_zones[i].label} ${minutes[i]}m',
                          style:
                              TextStyle(fontSize: 11.5, color: c.textSecondary)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
