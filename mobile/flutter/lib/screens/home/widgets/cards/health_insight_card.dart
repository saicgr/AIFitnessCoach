/// Home-screen health-coaching insight card (Phase C3).
///
/// Surfaces the day's single proactive coaching message — the morning
/// readiness briefing, a resting-HR anomaly alert, or an activity / step-goal
/// nudge — from the Phase C1 `/insights` endpoints, resolved by
/// [healthInsightProvider] (briefing has priority when several apply).
///
/// Render rules (all enforced in [HealthInsightState.shouldShow], mirrored
/// here defensively):
///   • shows ONLY when the day has a message AND it has not been dismissed
///     today (per-day SharedPreferences key — tomorrow's briefing returns);
///   • the endpoints return a clean "no message" for a healthy user / no
///     wearable / no consent, so the card self-hides then;
///   • hides on any API / loading error (the failure stays loud in logs).
///
/// Self-hiding sibling pattern (the [DeloadRecommendationCard] / [SmartInsightCard]
/// model — no new home `TileType`, build_runner is forbidden): registered in
/// `tile_factory.dart`'s `sleepScore` case ABOVE [LastNightSleepCard],
/// collapsing to [SizedBox.shrink] whenever there is nothing to show.
///
/// Universal-bell contribution: the moment a real message resolves, the card
/// records it in the notification bell via [BannerNotificationMapper] using
/// the shared deterministic id `<type>_<localdate>`, so a coaching push and
/// this card / the banner dedupe to ONE bell entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/utils/banner_notification_mapper.dart';
import '../../../../data/providers/health_insight_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../notifications/notifications_screen.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// The health-coaching insight card. Returns [SizedBox.shrink] whenever the
/// resolved state says it should not show — safe to place unconditionally in
/// a tile list, exactly like [DeloadRecommendationCard].
class HealthInsightCard extends ConsumerWidget {
  final bool isDark;

  const HealthInsightCard({super.key, this.isDark = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(healthInsightProvider);

    // Loading and error both collapse to nothing — the card must never flash
    // a spinner or an error state on the home screen. Failures are still
    // logged inside the provider so the bug surfaces.
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (!state.shouldShow) return const SizedBox.shrink();
        final insight = state.insight!;
        // Record this insight in the universal notification bell the moment
        // it appears (not only on dismiss). The deterministic id dedupes it
        // against a coaching push for the same type + day, and
        // NotificationsNotifier.addNotification ignores a duplicate id, so
        // repeated home rebuilds add nothing.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(notificationsProvider.notifier).addNotification(
                NotificationItem(
                  id: insight.notifId,
                  title: insight.title,
                  // The bell is a compact inbox — it carries the BRIEF
                  // one-line version of the game plan, matching the coaching
                  // push (Phase E4). The full multi-part plan is on this card
                  // and the deep-linked /health/sleep screen.
                  body: insight.briefMessage,
                  type: BannerNotificationMapper.healthCoachingType,
                  timestamp: DateTime.now(),
                ),
              );
        });
        return _HealthInsightCardBody(insight: insight, isDark: isDark);
      },
    );
  }
}

class _HealthInsightCardBody extends ConsumerWidget {
  final HealthInsight insight;
  final bool isDark;

  const _HealthInsightCardBody({required this.insight, required this.isDark});

  /// Per-type icon — keeps the card visually distinct from the deload /
  /// smart-insight siblings.
  IconData get _icon {
    switch (insight.type) {
      case 'daily_briefing':
        return Icons.wb_sunny_rounded;
      case 'health_anomaly':
        return Icons.monitor_heart_rounded;
      case 'activity_nudge':
        return Icons.directions_walk_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  /// Icon for one Phase-E4 game-plan domain chip.
  static IconData _domainIcon(String domain) {
    switch (domain) {
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  /// Human label for one Phase-E4 game-plan domain chip.
  static String _domainLabel(String domain) {
    switch (domain) {
      case 'workout':
        return 'Training';
      case 'nutrition':
        return 'Nutrition';
      default:
        return domain;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return GestureDetector(
      // Tapping the card deep-links to the relevant detail screen — the Sleep
      // detail screen for the briefing / activity nudge, the Combined Health
      // hub for the resting-HR anomaly.
      onTap: () {
        HapticService.light();
        context.push(insight.route);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          // Subtle accent-tinted border — reads as a coaching nudge, not a
          // plain stat tile.
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon chip + title + dismiss ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                // Per-day dismiss — small, low-emphasis, generous tap target.
                // The insight returns tomorrow because the dismissal key is
                // date-scoped.
                InkWell(
                  onTap: () {
                    HapticService.light();
                    dismissHealthInsight(ref);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Body: the full coaching message, verbatim. For a poor-night
            //    daily briefing this is the Phase-E4 cross-domain game plan
            //    (sleep readout + workout + nutrition + one concrete swap). ──
            Text(
              insight.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textMuted,
              ),
            ),
            // ── Game-plan domain chips — only when the briefing narrates a
            //    cross-domain plan (Phase E4). Shows Sleep + each narrated
            //    domain so the card reads as one connected plan, not a tip. ──
            if (insight.domains.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DomainChip(
                    icon: Icons.bedtime_rounded,
                    label: AppLocalizations.of(context).sleepDetailSleep,
                    accent: accent,
                    isDark: isDark,
                  ),
                  for (final domain in insight.domains)
                    _DomainChip(
                      icon: _domainIcon(domain),
                      label: _domainLabel(domain),
                      accent: accent,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // ── Footer: deep-link affordance ──
            Row(
              children: [
                Text(
                  insight.type == 'health_anomaly'
                      ? 'View health details'
                      // A cross-domain game plan deep-links to the expanded
                      // plan on /health/sleep (Phase E4).
                      : insight.domains.isNotEmpty
                          ? 'View your full plan'
                          : 'View your readiness',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 11, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small labeled chip for one domain of the Phase-E4 cross-domain game plan
/// (Sleep / Training / Nutrition) — surfaces, at a glance, that the briefing
/// is one connected plan spanning several domains.
class _DomainChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;

  const _DomainChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
