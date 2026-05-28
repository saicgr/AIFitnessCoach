/// F3.58 — Premium preview tile.
///
/// A passive showcase of a single Premium-only feature, rotated server-side
/// via `GET /api/v1/home/premium-preview-rotation`
/// (`premiumPreviewRotationProvider`). The endpoint returns `entry: null`
/// for paying users so the tile self-suppresses.
///
/// If the ranker injects `featureName`/`featureBlurb` via the constructor
/// (cached payload path), that wins and no network call is made.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PremiumPreviewTile extends ConsumerWidget {
  final bool show;
  // Optional ranker-supplied overrides. When [featureName] and
  // [featureBlurb] are non-null we skip the API call.
  final String? featureName;
  final String? featureBlurb;
  final IconData? icon;
  final String? route;

  const PremiumPreviewTile({
    super.key,
    this.show = true,
    this.featureName,
    this.featureBlurb,
    this.icon,
    this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    final fn = featureName;
    final fb = featureBlurb;
    if (fn != null && fb != null) {
      return _card(
        context,
        c,
        title: fn,
        blurb: fb,
        icon: icon ?? Icons.insights,
        route: route ?? '/paywall?source=premium_preview_$fn',
      );
    }

    final async = ref.watch(premiumPreviewRotationProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rot) {
        final entry = rot.entry;
        if (entry == null) return const SizedBox.shrink();
        return _card(
          context,
          c,
          title: entry.title,
          blurb: entry.previewBody,
          icon: _iconForFeatureKey(entry.lockedFeatureKey),
          route: entry.route,
        );
      },
    );
  }

  static IconData _iconForFeatureKey(String key) {
    switch (key) {
      case 'advanced_trends':
        return Icons.insights;
      case 'ai_form_analysis':
        return Icons.videocam_outlined;
      case 'rag_personal_coach':
        return Icons.psychology_outlined;
      case 'custom_training_splits':
        return Icons.tune;
      case 'body_comp_tracking':
        return Icons.straighten;
      case 'family_plan':
        return Icons.group_outlined;
      case 'priority_support':
        return Icons.support_agent_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  Widget _card(
    BuildContext context,
    ThemeColors c, {
    required String title,
    required String blurb,
    required IconData icon,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push(route);
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blurb,
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
            ],
          ),
        ),
      ),
    );
  }
}
