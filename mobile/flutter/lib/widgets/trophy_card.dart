import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../data/models/trophy.dart';

/// Trophy card with tier-based visual styling and animations
class TrophyCard extends StatefulWidget {
  final TrophyProgress trophyProgress;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;

  const TrophyCard({
    super.key,
    required this.trophyProgress,
    this.onTap,
    this.showProgress = true,
    this.compact = false,
  });

  @override
  State<TrophyCard> createState() => _TrophyCardState();
}

class _TrophyCardState extends State<TrophyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Only animate for earned gold/platinum/diamond trophies
    final tier = widget.trophyProgress.trophy.trophyTier;
    if (widget.trophyProgress.isEarned &&
        (tier == TrophyTier.gold ||
            tier == TrophyTier.platinum ||
            tier == TrophyTier.diamond)) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trophy = widget.trophyProgress.trophy;
    final isEarned = widget.trophyProgress.isEarned;
    final tier = trophy.trophyTier;

    if (widget.compact) {
      return _buildCompactCard(context, trophy, isEarned, tier);
    }

    return _buildFullCard(context, trophy, isEarned, tier);
  }

  Widget _buildCompactCard(
    BuildContext context,
    Trophy trophy,
    bool isEarned,
    TrophyTier tier,
  ) {
    final primaryColor = tier.primaryColor;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEarned
              ? primaryColor.withValues(alpha: 0.15)
              : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? primaryColor.withValues(alpha: 0.4)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            _buildTrophyIcon(trophy, isEarned, tier, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trophyProgress.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEarned
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isEarned)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 18,
              )
            else if (widget.showProgress)
              Text(
                '${widget.trophyProgress.progressPercentage.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard(
    BuildContext context,
    Trophy trophy,
    bool isEarned,
    TrophyTier tier,
  ) {
    final primaryColor = tier.primaryColor;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEarned
              ? primaryColor.withValues(alpha: 0.1)
              : AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEarned
                ? primaryColor.withValues(alpha: 0.4)
                : AppColors.cardBorder,
            width: isEarned ? 2 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and tier
            Row(
              children: [
                _buildTrophyIcon(trophy, isEarned, tier, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trophyProgress.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEarned
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildTierBadge(tier, isEarned),
                    ],
                  ),
                ),
                if (isEarned)
                  Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              widget.trophyProgress.displayDescription,
              style: TextStyle(
                fontSize: 13,
                color: isEarned ? AppColors.textSecondary : AppColors.textMuted,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Progress bar (if not earned and showProgress)
            if (!isEarned && widget.showProgress) ...[
              const SizedBox(height: 12),
              _buildProgressBar(tier),
            ],

            // XP Reward
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${trophy.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trophy.hasMerchReward) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          size: 12,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Merch',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyIcon(
    Trophy trophy,
    bool isEarned,
    TrophyTier tier, {
    double size = 48,
  }) {
    final primaryColor = tier.primaryColor;
    final gradientColors = tier.gradientColors;

    // For locked trophies, show grayscale
    if (!isEarned) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textMuted.withValues(alpha: 0.2),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            trophy.icon,
            style: TextStyle(
              fontSize: size * 0.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    // For earned trophies with shimmer animation
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                ...gradientColors,
                gradientColors.first,
              ],
              transform: GradientRotation(
                _shimmerController.value * 2 * 3.14159,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              trophy.icon,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierBadge(TrophyTier tier, bool isEarned) {
    final color = tier.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEarned ? color.withValues(alpha: 0.2) : AppColors.cardBorder,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEarned ? color.withValues(alpha: 0.5) : AppColors.textMuted.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        tier.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isEarned ? color : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildProgressBar(TrophyTier tier) {
    final progress = widget.trophyProgress.progressFraction;
    final color = tier.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '${widget.trophyProgress.currentValue.toInt()} / ${widget.trophyProgress.trophy.thresholdValue?.toInt() ?? 0}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: AppColors.textMuted.withValues(alpha: 0.2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Grid of trophy cards
class TrophyGrid extends StatelessWidget {
  final List<TrophyProgress> trophies;
  final void Function(TrophyProgress)? onTrophyTap;
  final int crossAxisCount;
  final bool compact;

  const TrophyGrid({
    super.key,
    required this.trophies,
    this.onTrophyTap,
    this.crossAxisCount = 2,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: trophies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final trophy = trophies[index];
          return TrophyCard(
            trophyProgress: trophy,
            compact: true,
            onTap: onTrophyTap != null ? () => onTrophyTap!(trophy) : null,
          );
        },
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: trophies.length,
      itemBuilder: (context, index) {
        final trophy = trophies[index];
        return TrophyCard(
          trophyProgress: trophy,
          onTap: onTrophyTap != null ? () => onTrophyTap!(trophy) : null,
        );
      },
    );
  }
}

/// Category header with trophy count
class TrophyCategoryHeader extends StatelessWidget {
  final TrophyCategory category;
  final int earnedCount;
  final int totalCount;

  const TrophyCategoryHeader({
    super.key,
    required this.category,
    required this.earnedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            category.iconData,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: earnedCount > 0
                  ? AppColors.green.withValues(alpha: 0.15)
                  : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$earnedCount / $totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: earnedCount > 0 ? AppColors.green : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
