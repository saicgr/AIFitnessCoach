import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';

/// A reusable selectable chip widget for multi-select options
/// Used across workout customization sheets for equipment, focus areas, etc.
class SelectableChip extends StatelessWidget {
  /// The label text to display
  final String label;

  /// Whether this chip is currently selected
  final bool isSelected;

  /// Accent color to use when selected
  final Color accentColor;

  /// Callback when the chip is tapped
  final VoidCallback onTap;

  /// Whether the chip is disabled
  final bool disabled;

  /// Whether to show a check icon when selected
  final bool showCheckIcon;

  /// Optional trailing widget (e.g., quantity selector)
  final Widget? trailing;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.disabled = false,
    this.showCheckIcon = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.2)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : colors.cardBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && showCheckIcon) ...[
              Icon(Icons.check, size: 14, color: accentColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A chip with an "Other" / custom input toggle
class OtherInputChip extends StatelessWidget {
  /// Whether the custom input field is shown
  final bool isInputShown;

  /// Custom value if entered
  final String customValue;

  /// Accent color
  final Color accentColor;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Whether the chip is disabled
  final bool disabled;

  const OtherInputChip({
    super.key,
    required this.isInputShown,
    required this.customValue,
    required this.accentColor,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final hasValue = customValue.isNotEmpty;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue
              ? accentColor.withOpacity(0.2)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue
                ? accentColor
                : colors.cardBorder.withOpacity(0.3),
            width: hasValue ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInputShown ? Icons.close : Icons.add,
              size: 14,
              color: hasValue ? accentColor : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              hasValue ? customValue : 'Other',
              style: TextStyle(
                color: hasValue ? accentColor : colors.textSecondary,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
