import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/accessibility/accessibility_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/section_header.dart';

/// The App Mode section for selecting display mode (Normal, Senior, Kids).
class AppModeSection extends StatelessWidget {
  const AppModeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'APP MODE'),
        SizedBox(height: 12),
        _AppModeCard(),
      ],
    );
  }
}

/// The accessibility section for configuring accessibility settings.
///
/// Allows users to adjust font size and other accessibility options.
class AccessibilitySection extends StatelessWidget {
  const AccessibilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'ACCESSIBILITY'),
        SizedBox(height: 12),
        _AccessibilitySettingsCard(),
      ],
    );
  }
}

/// App Mode card for selecting Normal, Senior, or Kids mode.
class _AppModeCard extends ConsumerWidget {
  const _AppModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accessibilitySettings = ref.watch(accessibilityProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Current Mode Header
          ListTile(
            leading: Icon(
              Icons.phone_android,
              color: textSecondary,
              size: 22,
            ),
            title: const Text('Current Mode', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              _getModeDescription(accessibilitySettings.mode),
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getModeColor(accessibilitySettings.mode).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getModeColor(accessibilitySettings.mode),
                ),
              ),
              child: Text(
                _getModeName(accessibilitySettings.mode),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getModeColor(accessibilitySettings.mode),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Mode selection buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AppModeButton(
                    label: 'Normal',
                    icon: Icons.apps,
                    description: 'Full features',
                    isSelected: accessibilitySettings.mode == AccessibilityMode.normal,
                    color: AppColors.cyan,
                    onTap: () {
                      ref.read(accessibilityProvider.notifier).setMode(AccessibilityMode.normal);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppModeButton(
                    label: 'Senior',
                    icon: Icons.accessibility_new,
                    description: 'Simplified',
                    isSelected: accessibilitySettings.mode == AccessibilityMode.senior,
                    color: AppColors.purple,
                    onTap: () {
                      ref.read(accessibilityProvider.notifier).setMode(AccessibilityMode.senior);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppModeButton(
                    label: 'Kids',
                    icon: Icons.child_care,
                    description: 'Coming soon',
                    isSelected: false,
                    isDisabled: true,
                    color: AppColors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Kids Mode coming soon!'),
                          backgroundColor: elevatedColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeDescription(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.senior:
        return 'Larger text, simpler navigation';
      case AccessibilityMode.kids:
        return 'Fun & easy interface';
      case AccessibilityMode.normal:
        return 'Standard experience with all features';
    }
  }

  String _getModeName(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.senior:
        return 'Senior';
      case AccessibilityMode.kids:
        return 'Kids';
      case AccessibilityMode.normal:
        return 'Normal';
    }
  }

  Color _getModeColor(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.senior:
        return AppColors.purple;
      case AccessibilityMode.kids:
        return AppColors.orange;
      case AccessibilityMode.normal:
        return AppColors.cyan;
    }
  }
}

/// App Mode selection button
class _AppModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final bool isDisabled;
  final Color color;
  final VoidCallback onTap;

  const _AppModeButton({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDisabled ? Colors.transparent : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDisabled ? cardBorder.withOpacity(0.5) : cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? color
                  : (isDisabled ? textMuted.withOpacity(0.5) : textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDisabled ? textMuted.withOpacity(0.5) : textMuted),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isDisabled ? textMuted.withOpacity(0.5) : textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilitySettingsCard extends ConsumerWidget {
  const _AccessibilitySettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accessibilitySettings = ref.watch(accessibilityProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Font Size
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_size, color: textSecondary, size: 22),
                    const SizedBox(width: 12),
                    const Text('Font Size', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(
                      _getFontSizeLabel(accessibilitySettings.fontScale),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.cyan,
                    inactiveTrackColor: cardBorder,
                    thumbColor: AppColors.cyan,
                    overlayColor: AppColors.cyan.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: accessibilitySettings.fontScale,
                    min: 0.85,
                    max: 1.5,
                    divisions: 13,
                    onChanged: (value) {
                      ref.read(accessibilityProvider.notifier).setFontScale(value);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Aa', style: TextStyle(fontSize: 12, color: textMuted)),
                    Text('Aa', style: TextStyle(fontSize: 20, color: textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // High Contrast toggle
          SwitchListTile(
            secondary: Icon(Icons.contrast, color: textSecondary, size: 22),
            title: const Text('High Contrast', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              'Increase color contrast for better visibility',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            value: accessibilitySettings.highContrast,
            activeColor: AppColors.cyan,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleHighContrast();
            },
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Large Buttons toggle
          SwitchListTile(
            secondary: Icon(Icons.touch_app, color: textSecondary, size: 22),
            title: const Text('Large Buttons', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              'Bigger touch targets for easier tapping',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            value: accessibilitySettings.largeButtons,
            activeColor: AppColors.cyan,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleLargeButtons();
            },
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Reduce Animations toggle
          SwitchListTile(
            secondary: Icon(Icons.animation, color: textSecondary, size: 22),
            title: const Text('Reduce Animations', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              'Minimize motion effects',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            value: accessibilitySettings.reduceAnimations,
            activeColor: AppColors.cyan,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleReduceAnimations();
            },
          ),
        ],
      ),
    );
  }

  String _getFontSizeLabel(double scale) {
    if (scale <= 0.9) return 'Small';
    if (scale <= 1.05) return 'Normal';
    if (scale <= 1.2) return 'Large';
    if (scale <= 1.35) return 'Extra Large';
    return 'Maximum';
  }
}

