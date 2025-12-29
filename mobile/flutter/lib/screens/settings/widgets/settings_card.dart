import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            // Inline theme selector buttons for better UX - one tap to change
            trailing = _InlineThemeSelector(
              currentMode: themeMode,
              onChanged: (mode) {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).setTheme(mode);
              },
            );
            onTap = null; // Disable row tap since buttons handle selection
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

/// Inline theme selector with 3 buttons: System, Light, Dark
/// Provides immediate feedback without requiring a bottom sheet
class _InlineThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _InlineThemeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.pureBlack.withValues(alpha: 0.5)
        : AppColorsLight.cardBorder.withValues(alpha: 0.5);
    final selectedColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeButton(
            icon: Icons.smartphone_outlined,
            label: 'Auto',
            isSelected: currentMode == ThemeMode.system,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeButton(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isSelected: currentMode == ThemeMode.light,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeButton(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Individual theme button for the inline selector
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color textMuted;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isSelected
        ? (isDark ? AppColors.elevated : Colors.white)
        : Colors.transparent;
    final iconColor = isSelected ? selectedColor : textMuted;
    final textColor = isSelected
        ? (isDark ? Colors.white : AppColorsLight.textPrimary)
        : textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
