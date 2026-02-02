import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Model for a setting item.
class SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isThemeToggle;
  final Color? iconColor;
  final Color? textColor;

  const SettingItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.isThemeToggle = false,
    this.iconColor,
    this.textColor,
  });
}

/// A settings card with multiple items and dividers.
class SettingsCard extends ConsumerWidget {
  final List<SettingItem> items;

  const SettingsCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap != null
                    ? () {
                        HapticService.selection();
                        item.onTap!();
                      }
                    : null,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: item.iconColor ?? textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            color: item.textColor,
                          ),
                        ),
                      ),
                      if (item.isThemeToggle)
                        Switch(
                          value: isDark,
                          onChanged: (value) {
                            ref.read(themeModeProvider.notifier).toggle();
                          },
                          activeThumbColor: accentColor,
                        )
                      else if (item.trailing != null)
                        item.trailing!
                      else if (item.onTap != null)
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
                  indent: 50,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
