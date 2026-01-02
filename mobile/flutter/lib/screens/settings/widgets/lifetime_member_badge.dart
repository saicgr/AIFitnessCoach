import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';

/// A badge widget that displays lifetime member status.
///
/// Shows:
/// - Tier badge (Veteran, Loyal, Established, New)
/// - Days as member
/// - Estimated value received
///
/// Can be displayed in:
/// - Settings screen header
/// - Profile section
/// - Subscription details
class LifetimeMemberBadge extends ConsumerWidget {
  /// Whether to show the compact version (just badge)
  final bool compact;

  /// Whether to show estimated savings
  final bool showSavings;

  /// Callback when badge is tapped
  final VoidCallback? onTap;

  const LifetimeMemberBadge({
    super.key,
    this.compact = false,
    this.showSavings = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);

    // Only show for lifetime members
    if (!subscriptionState.isLifetimeMember) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memberTier = subscriptionState.lifetimeMemberTier;

    if (compact) {
      return _CompactBadge(
        tier: memberTier,
        onTap: onTap,
      );
    }

    return _ExpandedBadge(
      tier: memberTier,
      daysAsMember: subscriptionState.daysAsMember,
      estimatedValue: subscriptionState.estimatedValueReceived,
      purchaseDate: subscriptionState.lifetimePurchaseDate,
      showSavings: showSavings,
      onTap: onTap,
      isDark: isDark,
    );
  }
}

/// Compact badge showing just the tier icon and label
class _CompactBadge extends StatelessWidget {
  final LifetimeMemberTier? tier;
  final VoidCallback? onTap;

  const _CompactBadge({
    required this.tier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _getTierColor(tier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              badgeColor.withValues(alpha: 0.3),
              badgeColor.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTierIcon(tier),
              size: 16,
              color: badgeColor,
            ),
            const SizedBox(width: 6),
            Text(
              tier?.displayName ?? 'Lifetime',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Member',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanded badge showing full lifetime member details
class _ExpandedBadge extends StatelessWidget {
  final LifetimeMemberTier? tier;
  final int daysAsMember;
  final double? estimatedValue;
  final DateTime? purchaseDate;
  final bool showSavings;
  final VoidCallback? onTap;
  final bool isDark;

  const _ExpandedBadge({
    required this.tier,
    required this.daysAsMember,
    this.estimatedValue,
    this.purchaseDate,
    required this.showSavings,
    this.onTap,
    required this.isDark,
  });

  String _formatDuration(int days) {
    if (days >= 365) {
      final years = days ~/ 365;
      final remainingMonths = (days % 365) ~/ 30;
      if (remainingMonths > 0) {
        return '$years year${years > 1 ? 's' : ''}, $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } else if (days >= 30) {
      final months = days ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getTierColor(tier);
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              badgeColor.withValues(alpha: 0.15),
              badgeColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tier badge
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        badgeColor,
                        badgeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getTierIcon(tier),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier?.displayName ?? 'Lifetime',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LIFETIME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member for ${_formatDuration(daysAsMember)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: textMuted,
                    size: 24,
                  ),
              ],
            ),

            // Savings/value section
            if (showSavings && estimatedValue != null && estimatedValue! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: AppColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Value Received',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${estimatedValue!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tier progression hint
            if (tier != null && tier != LifetimeMemberTier.veteran) ...[
              const SizedBox(height: 12),
              _TierProgressHint(
                currentTier: tier!,
                daysAsMember: daysAsMember,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows progress to next tier
class _TierProgressHint extends StatelessWidget {
  final LifetimeMemberTier currentTier;
  final int daysAsMember;

  const _TierProgressHint({
    required this.currentTier,
    required this.daysAsMember,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Calculate days to next tier
    int targetDays;
    String nextTierName;

    switch (currentTier) {
      case LifetimeMemberTier.newMember:
        targetDays = 90;
        nextTierName = 'Established';
        break;
      case LifetimeMemberTier.established:
        targetDays = 180;
        nextTierName = 'Loyal';
        break;
      case LifetimeMemberTier.loyal:
        targetDays = 365;
        nextTierName = 'Veteran';
        break;
      case LifetimeMemberTier.veteran:
        return const SizedBox.shrink();
    }

    final daysRemaining = targetDays - daysAsMember;
    final progress = daysAsMember / targetDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$daysRemaining days until $nextTierName',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getTierColor(currentTier),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Get the icon for a member tier
IconData _getTierIcon(LifetimeMemberTier? tier) {
  switch (tier) {
    case LifetimeMemberTier.veteran:
      return Icons.military_tech;
    case LifetimeMemberTier.loyal:
      return Icons.workspace_premium;
    case LifetimeMemberTier.established:
      return Icons.verified;
    case LifetimeMemberTier.newMember:
    case null:
      return Icons.star;
  }
}

/// Get the color for a member tier
Color _getTierColor(LifetimeMemberTier? tier) {
  switch (tier) {
    case LifetimeMemberTier.veteran:
      return const Color(0xFFFFD700); // Gold
    case LifetimeMemberTier.loyal:
      return const Color(0xFFC0C0C0).withBlue(180); // Silver with blue tint
    case LifetimeMemberTier.established:
      return const Color(0xFFCD7F32); // Bronze
    case LifetimeMemberTier.newMember:
    case null:
      return AppColors.cyan;
  }
}

/// A small inline badge that can be used next to usernames or in lists
class LifetimeMemberChip extends ConsumerWidget {
  final double size;

  const LifetimeMemberChip({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);

    if (!subscriptionState.isLifetimeMember) {
      return const SizedBox.shrink();
    }

    final tier = subscriptionState.lifetimeMemberTier;
    final badgeColor = _getTierColor(tier);

    return Tooltip(
      message: '${tier?.displayName ?? "Lifetime"} Member',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              badgeColor,
              badgeColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getTierIcon(tier),
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
