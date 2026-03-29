import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'banner_card_data.dart';

/// A uniform 84px-tall card that renders any [BannerCardData].
///
/// Used as the building block for [StackedBannerPanel]. Every banner type
/// (missed workout, wrapped, renewal, etc.) is condensed into this compact
/// single-row layout: [icon] [title + subtitle] [action button].
class CompactBannerCard extends StatelessWidget {
  final BannerCardData data;
  final VoidCallback? onDismiss;

  static const double cardHeight = 84.0;

  const CompactBannerCard({
    super.key,
    required this.data,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: data.accentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: data.accentColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Icon / emoji container
              _buildIcon(isDark),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action button
              if (data.actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: data.onAction ?? data.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: data.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    data.actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    if (data.emoji != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: data.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          data.emoji!,
          style: const TextStyle(fontSize: 20),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: data.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        data.icon ?? Icons.info_outline,
        color: data.accentColor,
        size: 20,
      ),
    );
  }
}
