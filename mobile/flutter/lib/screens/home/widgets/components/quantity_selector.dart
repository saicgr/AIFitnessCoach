import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';

/// A compact quantity selector widget (e.g., for dumbbell count)
/// Allows selecting between min and max values
class QuantitySelector extends StatelessWidget {
  /// Current selected value
  final int value;

  /// Callback when value changes
  final ValueChanged<int> onChanged;

  /// Minimum allowed value
  final int minValue;

  /// Maximum allowed value
  final int maxValue;

  /// Accent color for the controls
  final Color accentColor;

  /// Whether the selector is disabled
  final bool disabled;

  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.minValue = 1,
    this.maxValue = 2,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final canDecrement = value > minValue && !disabled;
    final canIncrement = value < maxValue && !disabled;

    return Container(
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: canDecrement ? () => onChanged(value - 1) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 14,
                color: canDecrement ? accentColor : colors.textMuted,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: canIncrement ? () => onChanged(value + 1) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 14,
                color: canIncrement ? accentColor : colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
