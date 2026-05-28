/// F3.62 — Discovery insight tile.
///
/// Surfaces a single data-driven insight ("You're stronger on Tuesdays")
/// derived from history. Pure presentation — the insight is computed
/// upstream and passed in by the ranker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/discovery_insight_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Server-backed rotating-pattern insight —
/// `GET /api/v1/insights/discovery`. Surfaces the strongest of a handful of
/// candidate patterns over the last 60 days. The ranker may still pass
/// explicit `headline` / `body` via the constructor; when neither is
/// passed (the common case), the tile reads from this provider and
/// self-collapses on no signal.

class DiscoveryInsightTile extends ConsumerWidget {
  final bool show;
  /// Override headline. When null, falls back to `discoveryInsightProvider`.
  final String? headline;
  /// Override body. When null, falls back to `discoveryInsightProvider`.
  final String? body;
  final String? deepLink;

  const DiscoveryInsightTile({
    super.key,
    this.show = true,
    this.headline,
    this.body,
    this.deepLink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    // Resolve copy: prefer ranker-passed overrides, otherwise read provider.
    String? resolvedHeadline = headline;
    String? resolvedBody = body;
    if (resolvedHeadline == null || resolvedBody == null) {
      final async = ref.watch(discoveryInsightProvider);
      final apiInsight = async.maybeWhen(
        data: (d) => d.hasInsight ? d : null,
        orElse: () => null,
      );
      if (apiInsight == null) {
        // No ranker override + no server signal → self-collapse rather than
        // showing stale placeholder copy.
        return const SizedBox.shrink();
      }
      resolvedHeadline ??= apiInsight.title;
      resolvedBody ??= apiInsight.body;
    }

    final c = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          if (deepLink != null && deepLink!.isNotEmpty) {
            context.push(deepLink!);
          } else {
            context.push('/profile?tab=stats');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_outline,
                    size: 18, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedHeadline!,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      resolvedBody!,
                      style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
