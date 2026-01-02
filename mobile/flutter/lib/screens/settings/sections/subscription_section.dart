import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../widgets/widgets.dart';

/// The subscription section for the settings screen.
/// Shows current plan and provides access to subscription management.
class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptionState = ref.watch(subscriptionProvider);
    final tier = subscriptionState.tier;
    final isLifetime = tier == SubscriptionTier.lifetime;
    final isFree = tier == SubscriptionTier.free;

    final tierDisplayName = _getTierDisplayName(tier);
    final tierColor = _getTierColor(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SUBSCRIPTION'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: _getTierIcon(tier),
              title: 'Manage Subscription',
              subtitle: tierDisplayName,
              trailing: _buildPlanBadge(
                tier,
                tierColor,
                isDark,
                isLifetime,
                subscriptionState.isTrialActive,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/subscription-management');
              },
            ),
          ],
        ),
        if (isFree) ...[
          const SizedBox(height: 12),
          _buildUpgradeCard(context, isDark),
        ],
      ],
    );
  }

  Widget _buildPlanBadge(
    SubscriptionTier tier,
    Color tierColor,
    bool isDark,
    bool isLifetime,
    bool isTrialing,
  ) {
    if (isTrialing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: 12,
              color: AppColors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              'TRIAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      );
    }

    if (isLifetime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive,
              size: 12,
              color: AppColors.purple,
            ),
            const SizedBox(width: 4),
            Text(
              'LIFETIME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: tierColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/paywall-features');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan.withValues(alpha: 0.15),
              AppColors.purple.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.rocket_launch,
                color: AppColors.cyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock all features and AI coaching',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.cyan,
            ),
          ],
        ),
      ),
    );
  }

  String _getTierDisplayName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free Plan';
      case SubscriptionTier.premium:
        return 'Premium Plan';
      case SubscriptionTier.ultra:
        return 'Ultra Plan';
      case SubscriptionTier.lifetime:
        return 'Lifetime Access';
    }
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.textMuted;
      case SubscriptionTier.premium:
        return AppColors.cyan;
      case SubscriptionTier.ultra:
        return AppColors.purple;
      case SubscriptionTier.lifetime:
        return AppColors.purple;
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person_outline;
      case SubscriptionTier.premium:
        return Icons.workspace_premium;
      case SubscriptionTier.ultra:
        return Icons.diamond_outlined;
      case SubscriptionTier.lifetime:
        return Icons.all_inclusive;
    }
  }
}
