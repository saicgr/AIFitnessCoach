/// F3.56 — Usage-based upsell banner.
///
/// Surfaces after the user has hit a meaningful free-quota proxy threshold
/// (e.g. N chat turns or N scan attempts) inside a session. This is a
/// presentation-only widget — actual eligibility comes from upstream
/// providers via the SubCardRanker. When [show] is false the widget
/// renders zero-height (self-collapsing) so the PageView slot disappears.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/subscription_provider.dart';
import '../../../../core/providers/usage_tracking_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class UsageUpsellBanner extends ConsumerWidget {
  /// Whether to render the banner at all. The ranker passes `false` once
  /// the user dismisses or completes the upsell flow.
  final bool show;

  /// How many "free" units they have left (chat turns / scans). When null,
  /// computed live from the usage-tracking provider (min remaining across
  /// the active feature limits).
  final int? unitsRemaining;

  /// Optional label for the unit ("chats", "scans"). Defaults to "uses".
  final String unitLabel;

  const UsageUpsellBanner({
    super.key,
    this.show = true,
    this.unitsRemaining,
    this.unitLabel = 'uses',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Premium users never see the upsell — gate on the live subscription tier.
    final isPremium = ref.watch(
        subscriptionProvider.select((s) => s.isPremiumOrHigher));
    if (isPremium) return const SizedBox.shrink();

    // Resolve units-remaining from the live usage-limits map when caller
    // doesn't override. Picks the smallest non-null `remaining` so the most
    // pressing cap drives the copy.
    int resolvedRemaining = unitsRemaining ?? 0;
    if (unitsRemaining == null) {
      final usage = ref.watch(usageTrackingProvider);
      int? smallest;
      for (final limit in usage.limits.values) {
        final r = limit.remaining;
        if (r == null) continue;
        if (smallest == null || r < smallest) smallest = r;
      }
      if (smallest == null) return const SizedBox.shrink();
      resolvedRemaining = smallest;
    }

    final isLimit = resolvedRemaining <= 0;
    final headline = isLimit
        ? 'You\'ve hit today\'s free limit'
        : 'Only $resolvedRemaining free $unitLabel left today';
    final body = isLimit
        ? 'Go unlimited with Premium — 7 day free trial.'
        : 'Tap to remove the cap with Premium.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/paywall?source=home_usage_banner');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.workspace_premium,
                    size: 18, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                          fontSize: 11.5,
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
