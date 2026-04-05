part of 'inventory_screen.dart';


/// Card widget for displaying a consumable item
class _ConsumableCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;
  final int count;
  final String? actionLabel;
  final bool isLoading;
  final bool isDisabled;
  final String? disabledReason;
  final String? helperText;
  final VoidCallback? onAction;
  // Theme parameters
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;
  final Color cardBorder;

  const _ConsumableCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.count,
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
    required this.cardBorder,
    this.actionLabel,
    this.isLoading = false,
    this.isDisabled = false,
    this.disabledReason,
    this.helperText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = count > 0 && !isDisabled && actionLabel != null;
    final disabledBgColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? iconColor.withValues(alpha: 0.3)
              : cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: count > 0 ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: count > 0 ? iconColor : iconColor.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
                // Count badge
                if (count > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'x$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: count > 0 ? textColor : textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: count > 0 ? textMuted : textMuted.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText!,
                    style: TextStyle(
                      color: textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (disabledReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    disabledReason!,
                    style: TextStyle(
                      color: AppColors.warning.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Button
          if (actionLabel != null)
            ElevatedButton(
              onPressed: canUse && !isLoading ? onAction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canUse ? iconColor : disabledBgColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: disabledBgColor,
                disabledForegroundColor: textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Text(
                      actionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }
}


/// Card widget for daily crate options
class _DailyCrateCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final bool isAvailable;
  final bool isLocked;
  final String? lockedReason;
  final VoidCallback? onTap;
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;
  final Color cardBorder;

  const _DailyCrateCard({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.isAvailable,
    required this.isLocked,
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
    required this.cardBorder,
    this.lockedReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? () {
        HapticService.light();
        onTap?.call();
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? color.withValues(alpha: 0.4) : cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isAvailable ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: isAvailable ? null : textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isAvailable ? textColor : textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isAvailable ? textMuted : textMuted.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  if (lockedReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lockedReason!,
                      style: TextStyle(
                        color: isLocked ? AppColors.warning.withValues(alpha: 0.9) : textMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lock or arrow icon
            if (isLocked)
              Icon(
                Icons.lock_outline,
                color: textMuted.withValues(alpha: 0.5),
                size: 24,
              )
            else if (isAvailable)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

