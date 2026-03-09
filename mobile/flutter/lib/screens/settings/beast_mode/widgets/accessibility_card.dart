import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/accessibility/accessibility_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class AccessibilityCard extends ConsumerWidget {
  final BeastThemeData theme;
  const AccessibilityCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilityProvider);

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visual and interaction adjustments',
            style: TextStyle(fontSize: 11, color: theme.textMuted),
          ),
          const SizedBox(height: 16),

          // High Contrast
          _AccessibilityToggle(
            icon: Icons.contrast,
            label: 'High Contrast',
            description: 'Increase color contrast for better visibility',
            value: settings.highContrast,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleHighContrast();
            },
            theme: theme,
          ),
          Divider(height: 24, color: theme.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),

          // Large Buttons
          _AccessibilityToggle(
            icon: Icons.touch_app,
            label: 'Large Buttons',
            description: 'Bigger touch targets for easier tapping',
            value: settings.largeButtons,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleLargeButtons();
            },
            theme: theme,
          ),
          Divider(height: 24, color: theme.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),

          // Reduce Animations
          _AccessibilityToggle(
            icon: Icons.animation,
            label: 'Reduce Animations',
            description: 'Minimize motion effects',
            value: settings.reduceAnimations,
            onChanged: (_) {
              ref.read(accessibilityProvider.notifier).toggleReduceAnimations();
            },
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _AccessibilityToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final BeastThemeData theme;

  const _AccessibilityToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: theme.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: theme.textMuted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.orange,
        ),
      ],
    );
  }
}
