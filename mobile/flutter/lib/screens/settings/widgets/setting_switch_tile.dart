import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';

/// A setting tile with an integrated switch for boolean options.
///
/// Used for settings that can be toggled on/off.
class SettingSwitchTile extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// The current value of the switch.
  final bool value;

  /// Callback when the switch value changes.
  final ValueChanged<bool> onChanged;

  /// Custom icon color.
  final Color? iconColor;

  /// Whether the switch is enabled.
  final bool enabled;

  const SettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Honour the user's accent — previously hardcoded cyan thumb on the
    // theme's default purple track produced a two-tone switch that clashed
    // with the rest of the settings surface. Matching thumb + tinted track
    // keeps the pill reading as a single accent colour.
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? (value ? iconColor : textMuted) ?? textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
