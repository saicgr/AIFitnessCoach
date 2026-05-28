/// F3.57 — Referral gift tile.
///
/// Lightweight tile inviting the user to share a referral link with a friend
/// in exchange for a month of Premium (or whatever the active referral
/// program offers). Self-collapses when [show] is false.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/referral_provider.dart';
import '../../../../data/services/haptic_service.dart';

class ReferralGiftTile extends ConsumerWidget {
  final bool show;

  /// Optional headline override — defaults to the standard copy.
  final String? headlineOverride;

  /// Optional body override.
  final String? bodyOverride;

  const ReferralGiftTile({
    super.key,
    this.show = true,
    this.headlineOverride,
    this.bodyOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Pull live referral progress so the body can reflect the user's actual
    // standing toward the next merch tier when copy overrides aren't given.
    final summary = ref.watch(referralSummaryProvider).valueOrNull;
    final resolvedHeadline = headlineOverride ?? 'Give a friend a free month';
    final String resolvedBody;
    if (bodyOverride != null) {
      resolvedBody = bodyOverride!;
    } else if (summary != null && summary.neededForNext > 0 &&
        summary.nextMerchDisplayName.isNotEmpty) {
      resolvedBody =
          '${summary.neededForNext} more to unlock ${summary.nextMerchDisplayName}.';
    } else {
      resolvedBody = 'Share your link — you both get Premium.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/profile?tab=referrals');
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
              Text('🎁', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedHeadline,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resolvedBody,
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.accentContrast,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
