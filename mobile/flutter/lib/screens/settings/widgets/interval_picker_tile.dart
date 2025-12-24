import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A tile for selecting an interval duration.
///
/// Displays a dropdown with predefined interval options.
class IntervalPickerTile extends StatelessWidget {
  /// The label text to display.
  final String label;

  /// The current interval in minutes.
  final int minutes;

  /// Callback when a new interval is selected.
  final ValueChanged<int> onChanged;

  /// Whether the current theme is dark mode.
  final bool isDark;

  /// Available interval options in minutes.
  final List<int> intervals;

  const IntervalPickerTile({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
    required this.isDark,
    this.intervals = const [30, 60, 90, 120, 180, 240],
  });

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
            value: minutes,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.cyan),
            dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
            items: intervals.map((m) {
              final hours = m ~/ 60;
              final mins = m % 60;
              final intervalLabel = hours > 0
                  ? (mins > 0 ? '${hours}h ${mins}m' : '${hours}h')
                  : '${mins}m';
              return DropdownMenuItem(
                value: m,
                child: Text(
                  intervalLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
