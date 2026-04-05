part of 'set_adjustment_sheet.dart';


/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Set value editor with +/- buttons
class _SetValueEditor extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isInteger;
  final bool enabled;
  final void Function(double) onChanged;

  const _SetValueEditor({
    required this.label,
    required this.value,
    required this.unit,
    required this.isInteger,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final step = isInteger ? 1.0 : 2.5;
    final displayValue = isInteger
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Decrease button
            GestureDetector(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value - step);
                    }
                  : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? AppColors.orange.withOpacity(0.15)
                      : textMuted.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: enabled ? AppColors.orange : textMuted,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$displayValue${unit.isNotEmpty ? ' $unit' : ''}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: enabled ? textPrimary : textMuted,
                  ),
                ),
              ),
            ),
            // Increase button
            GestureDetector(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value + step);
                    }
                  : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? AppColors.cyan.withOpacity(0.15)
                      : textMuted.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: enabled ? AppColors.cyan : textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

