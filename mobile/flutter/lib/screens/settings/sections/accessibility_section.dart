import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/accessibility/accessibility_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/section_header.dart';

/// The accessibility section for configuring accessibility settings.
///
/// Allows users to adjust display mode, font size, and other accessibility options.
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
          // Display Mode
          ListTile(
            leading: Icon(
              Icons.display_settings_outlined,
              color: textSecondary,
              size: 22,
            ),
            title: const Text('Display Mode', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              accessibilitySettings.mode == AccessibilityMode.senior
                  ? 'Senior Mode - Larger text, simpler navigation'
                  : 'Normal Mode - Full features',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accessibilitySettings.mode == AccessibilityMode.senior
                    ? AppColors.cyan.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accessibilitySettings.mode == AccessibilityMode.senior
                      ? AppColors.cyan
                      : cardBorder,
                ),
              ),
              child: Text(
                accessibilitySettings.mode == AccessibilityMode.senior ? 'Senior' : 'Normal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accessibilitySettings.mode == AccessibilityMode.senior
                      ? AppColors.cyan
                      : textSecondary,
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
                  child: _AccessibilityModeButton(
                    label: 'Normal',
                    icon: Icons.apps,
                    isSelected: accessibilitySettings.mode == AccessibilityMode.normal,
                    onTap: () {
                      ref.read(accessibilityProvider.notifier).setMode(AccessibilityMode.normal);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AccessibilityModeButton(
                    label: 'Senior',
                    icon: Icons.accessibility_new,
                    isSelected: accessibilitySettings.mode == AccessibilityMode.senior,
                    onTap: () {
                      ref.read(accessibilityProvider.notifier).setMode(AccessibilityMode.senior);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AccessibilityModeButton(
                    label: 'Kids',
                    icon: Icons.child_care,
                    isSelected: false,
                    isDisabled: true,
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
          Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

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

class _AccessibilityModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AccessibilityModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : (isDisabled ? Colors.transparent : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
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
                  ? AppColors.cyan
                  : (isDisabled ? textMuted.withOpacity(0.5) : textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.cyan
                    : (isDisabled ? textMuted.withOpacity(0.5) : textMuted),
              ),
            ),
            if (isDisabled) ...[
              const SizedBox(height: 2),
              Text(
                'Soon',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
