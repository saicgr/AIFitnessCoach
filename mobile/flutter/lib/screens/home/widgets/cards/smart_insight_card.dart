/// Home-screen smart-insight card (Phase D1).
///
/// Surfaces the single best cross-metric correlation from the user's own
/// health history — e.g. "your sleep and resting heart rate tend to move in
/// opposite directions". The copy is association-only (correlation, never
/// causation); the backend engine that produces it is deterministic.
///
/// Render rules (all enforced in [smartInsightProvider], mirrored here
/// defensively):
///   • shows ONLY when the endpoint returns at least one insight;
///   • the endpoint returns an empty list below 14 paired days or with no
///     wearable / no consent — so the card self-hides cleanly then;
///   • hides on any API/loading error (failure stays loud in logs).
///
/// Self-hiding sibling pattern (the [DeloadRecommendationCard] model — no new
/// TileType, build_runner is forbidden): registered in `tile_factory.dart`'s
/// `aiCoachTip` case ABOVE the AI Coach Tip card, collapsing to
/// [SizedBox.shrink] whenever there is nothing to show.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/providers/smart_insight_provider.dart';

/// The smart-insight card. Returns [SizedBox.shrink] whenever the resolved
/// state says it should not show — safe to place unconditionally in a tile
/// list, exactly like [DeloadRecommendationCard].
class SmartInsightCard extends ConsumerWidget {
  final bool isDark;

  const SmartInsightCard({super.key, this.isDark = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(smartInsightProvider);

    // Loading and error both collapse to nothing — the card must never flash
    // a spinner or an error state on the home screen. Failures are still
    // logged inside the provider so the bug surfaces.
    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (!state.shouldShow) return const SizedBox.shrink();
        return _SmartInsightCardBody(insight: state.top!, isDark: isDark);
      },
    );
  }
}

class _SmartInsightCardBody extends ConsumerWidget {
  final SmartInsight insight;
  final bool isDark;

  const _SmartInsightCardBody({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        // Subtle accent-tinted border — reads as an insight, not a stat tile.
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon chip + title + r badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.insights_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart insight',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              // Sample-size badge — "30 days" — so the user sees the evidence
              // base. Never implies a causal claim.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${insight.n} days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Body: the association-only insight sentence, verbatim ──
          Text(
            insight.insight,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
