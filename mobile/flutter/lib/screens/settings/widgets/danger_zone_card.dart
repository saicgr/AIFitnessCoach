import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A data class representing a dangerous action item.
class DangerItemData {
  /// The icon to display.
  final IconData icon;

  /// The main title text.
  final String title;

  /// The subtitle text describing the action.
  final String subtitle;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  const DangerItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// A card container for dangerous/destructive actions.
///
/// Styled with error colors to indicate the severity of the actions.
class DangerZoneCard extends StatelessWidget {
  /// The list of danger items to display.
  final List<DangerItemData> items;

  const DangerZoneCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
