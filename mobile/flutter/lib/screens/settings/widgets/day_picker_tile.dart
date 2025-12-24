import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A tile for selecting a day of the week.
///
/// Displays a dropdown with all days of the week.
class DayPickerTile extends StatelessWidget {
  /// The label text to display.
  final String label;

  /// The current day (0 = Sunday, 6 = Saturday).
  final int day;

  /// Callback when a new day is selected.
  final ValueChanged<int> onChanged;

  /// Whether the current theme is dark mode.
  final bool isDark;

  const DayPickerTile({
    super.key,
    required this.label,
    required this.day,
    required this.onChanged,
    required this.isDark,
  });

  static const _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
          ),
          DropdownButton<int>(
            value: day,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.cyan),
            dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
            items: List.generate(7, (i) {
              return DropdownMenuItem(
                value: i,
                child: Text(
                  _days[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
