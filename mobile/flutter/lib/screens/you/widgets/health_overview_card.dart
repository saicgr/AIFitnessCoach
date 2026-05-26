import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../home/widgets/cards/combined_health_card.dart';
import '../../home/widgets/cards/last_night_sleep_card.dart';
import '../../home/widgets/cards/todays_health_card.dart';

/// Surface 5.A.2 — Single Health card on the You/Overview tab.
///
/// Previously the Overview rendered three independently-bordered health cards
/// (TodaysHealthCard + LastNightSleepCard + CombinedHealthCard). That was
/// three cards for the same conceptual surface. This wrapper composes them
/// into one outer card with three internal sections and a final "Trends"
/// chevron row that taps into the Combined Health hub.
///
/// The three child cards self-pad internally — to avoid double-insets we let
/// them retain their internal padding and remove the outer surface from each
/// child's render path by stacking them in a tight Column without an extra
/// shell. Children also self-hide when their data isn't available (no Health
/// permission, no sleep last night), so a first-day user sees only the rows
/// that have something to show.
///
/// The three original card files remain in place — they are still used by
/// `tile_factory.dart` on the Home tab's tile grid. This wrapper is the You
/// hub's single entry point only.
class HealthOverviewCard extends ConsumerWidget {
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  const HealthOverviewCard({
    super.key,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODAY — steps, active energy, HR tiles. Hosts the refresh
        // affordance via its existing header.
        TodaysHealthCard(
          onRefresh: onRefresh,
          isRefreshing: isRefreshing,
        ),
        const SizedBox(height: 8),
        // LAST NIGHT — sleep score, duration, stages.
        const LastNightSleepCard(),
        const SizedBox(height: 8),
        // TRENDS — single chevron row into the Combined Health hub.
        // Replaces the standalone CombinedHealthCard's full surface to avoid
        // a third bordered card on the same conceptual section.
        _TrendsRow(c: c),
        const SizedBox(height: 8),
        // Self-hiding sibling — CombinedHealthCard still renders its data
        // body when Health is connected; keep it underneath the trends row
        // so users who tap through still see the same content.
        const CombinedHealthCard(),
      ],
    );
  }
}

class _TrendsRow extends StatelessWidget {
  final ThemeColors c;
  const _TrendsRow({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          HapticFeedback.selectionClick();
          context.push('/health/combined');
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trends',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
