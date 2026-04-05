part of 'trophy_room_screen.dart';


/// Trophy card with tier-based visual styling
class _TrophyCard extends StatelessWidget {
  final TrophyProgress trophyProgress;
  final VoidCallback? onTap;
  final bool isDark;
  final Color textColor;
  final Color textMuted;
  final Color elevatedColor;
  final Color cardBorder;
  final Color accentColor;

  const _TrophyCard({
    required this.trophyProgress,
    this.onTap,
    required this.isDark,
    required this.textColor,
    required this.textMuted,
    required this.elevatedColor,
    required this.cardBorder,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final trophy = trophyProgress.trophy;
    final isEarned = trophyProgress.isEarned;
    final isMystery = trophyProgress.isMystery;
    final tier = trophy.trophyTier;
    final primaryColor = isMystery ? AppColors.purple : tier.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEarned
              ? primaryColor.withValues(alpha: 0.15)
              : isMystery
                  ? AppColors.purple.withValues(alpha: 0.08)
                  : elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? primaryColor.withValues(alpha: 0.4)
                : isMystery
                    ? AppColors.purple.withValues(alpha: 0.3)
                    : cardBorder,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEarned
                    ? LinearGradient(
                        colors: tier.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEarned
                    ? null
                    : isMystery
                        ? AppColors.purple.withValues(alpha: 0.2)
                        : textMuted.withValues(alpha: 0.2),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  trophyProgress.displayIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trophyProgress.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? textColor : (isMystery ? AppColors.purple : textMuted),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trophyProgress.displayDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontStyle: isMystery ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? primaryColor.withValues(alpha: 0.2)
                              : isMystery
                                  ? AppColors.purple.withValues(alpha: 0.15)
                                  : textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trophyProgress.displayTier,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isEarned ? primaryColor : (isMystery ? AppColors.purple : textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trophyProgress.displayXp,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Progress indicator
                      if (!isEarned)
                        Text(
                          '${trophyProgress.progressPercentage.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trophyProgress.progressPercentage > 0 ? AppColors.orange : textMuted,
                          ),
                        ),
                    ],
                  ),
                  // Progress bar
                  if (!isEarned && !isMystery) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: trophyProgress.progressFraction,
                        minHeight: 4,
                        backgroundColor: textMuted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(primaryColor.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status icon
            const SizedBox(width: 8),
            if (isEarned)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}


/// Trophy detail bottom sheet
class _TrophyDetailSheet extends StatelessWidget {
  final TrophyProgress trophyProgress;
  final bool isDark;
  final Color textColor;
  final Color textMuted;
  final Color elevatedColor;
  final Color accentColor;

  const _TrophyDetailSheet({
    required this.trophyProgress,
    required this.isDark,
    required this.textColor,
    required this.textMuted,
    required this.elevatedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final trophy = trophyProgress.trophy;
    final tier = trophy.trophyTier;
    final isEarned = trophyProgress.isEarned;
    final isMystery = trophyProgress.isMystery;
    final primaryColor = isMystery ? AppColors.purple : tier.primaryColor;

    return GlassSheet(
        child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Trophy icon with tier styling
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isEarned && !isMystery
                              ? LinearGradient(colors: tier.gradientColors)
                              : null,
                          color: isEarned
                              ? null
                              : isMystery
                                  ? AppColors.purple.withValues(alpha: 0.2)
                                  : textMuted.withValues(alpha: 0.2),
                          boxShadow: isEarned
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            trophyProgress.displayIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        trophyProgress.displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isMystery ? AppColors.purple : textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          trophyProgress.displayTier,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        trophyProgress.displayDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                          height: 1.5,
                          fontStyle: isMystery ? FontStyle.italic : FontStyle.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Progress or earned date
                      if (isEarned)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Earned ${_formatDate(trophyProgress.earnedAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isMystery)
                        Column(
                          children: [
                            Text(
                              '${trophyProgress.currentValue.toInt()} / ${trophy.thresholdValue?.toInt() ?? 0} ${trophy.thresholdUnit ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: trophyProgress.progressFraction,
                                  minHeight: 8,
                                  backgroundColor: textMuted.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation(primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trophyProgress.progressPercentage.round()}% complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.help_outline,
                                color: AppColors.purple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Progress hidden until discovered',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Rewards
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  trophyProgress.displayXp,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trophy.hasMerchReward && !isMystery)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
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
                                    size: 16,
                                    color: AppColors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    trophy.merchReward!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}

