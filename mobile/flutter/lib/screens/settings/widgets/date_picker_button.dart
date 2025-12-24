import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A button for selecting a date.
///
/// Displays the selected date or a placeholder text.
class DatePickerButton extends StatelessWidget {
  /// The label text to display above the date.
  final String label;

  /// The currently selected date.
  final DateTime? date;

  /// Callback when the button is tapped.
  final VoidCallback onTap;

  /// Whether the current theme is dark mode.
  final bool isDark;

  const DatePickerButton({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    required this.isDark,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null
                        ? '${_months[date!.month - 1]} ${date!.day}, ${date!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? textPrimary : textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
