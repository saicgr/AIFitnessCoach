import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/timezone_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'setting_tile.dart';

/// A card container for grouping related settings items.
///
/// Handles theme toggles and provides consistent styling for settings groups.
class SettingsCard extends ConsumerWidget {
  /// The list of setting items to display.
  final List<SettingItemData> items;

  const SettingsCard({
    super.key,
    required this.items,
  });

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ThemeOptionTile(
              icon: Icons.smartphone_outlined,
              title: 'System',
              subtitle: 'Follow device settings',
              isSelected: themeMode == ThemeMode.system,
              onTap: () {
                ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _ThemeOptionTile(
              icon: Icons.light_mode_outlined,
              title: 'Light',
              subtitle: 'Always use light theme',
              isSelected: themeMode == ThemeMode.light,
              onTap: () {
                ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOptionTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark',
              subtitle: 'Always use dark theme',
              isSelected: themeMode == ThemeMode.dark,
              onTap: () {
                ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTimezoneSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTimezone = ref.read(timezoneProvider).timezone;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Timezone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: commonTimezones.length,
                  itemBuilder: (context, index) {
                    final tz = commonTimezones[index];
                    final isSelected = tz.id == currentTimezone;
                    return _TimezoneOptionTile(
                      timezone: tz,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(timezoneProvider.notifier).setTimezone(tz.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final timezoneState = ref.watch(timezoneProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkModeActive = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isFollowingSystem = themeMode == ThemeMode.system;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          Widget? trailing;
          VoidCallback? onTap = item.onTap;

          if (item.isThemeSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getThemeLabel(themeMode),
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showThemeSelector(context, ref);
          } else if (item.isTimezoneSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timezoneState.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showTimezoneSelector(context, ref);
          } else if (item.isFollowSystemToggle) {
            trailing = Switch(
              value: isFollowingSystem,
              onChanged: (value) {
                if (value) {
                  ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
                } else {
                  ref.read(themeModeProvider.notifier).setTheme(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  );
                }
              },
              activeColor: AppColors.cyan,
            );
          } else if (item.isThemeToggle) {
            trailing = Switch(
              value: isDarkModeActive,
              onChanged: isFollowingSystem
                  ? null
                  : (value) {
                      ref.read(themeModeProvider.notifier).setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
              activeColor: AppColors.cyan,
            );
          } else {
            trailing = item.trailing;
          }

          return Column(
            children: [
              SettingTile(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: onTap,
                trailing: trailing,
                showChevron: !item.isThemeToggle &&
                    !item.isFollowSystemToggle &&
                    !item.isThemeSelector &&
                    !item.isTimezoneSelector,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
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

/// A tile for theme selection in the bottom sheet.
class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.cyan : textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A tile for timezone selection in the bottom sheet.
class _TimezoneOptionTile extends StatelessWidget {
  final TimezoneData timezone;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimezoneOptionTile({
    required this.timezone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timezone.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  Text(
                    '${timezone.region} • ${timezone.currentOffset}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
