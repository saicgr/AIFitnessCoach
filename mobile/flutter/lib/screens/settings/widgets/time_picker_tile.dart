import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A tile for selecting a time value.
///
/// Displays a label and the currently selected time with a clock icon.
class TimePickerTile extends StatelessWidget {
  /// The label text to display.
  final String label;

  /// The current time value in HH:mm format.
  final String time;

  /// Callback when a new time is selected.
  final ValueChanged<String> onTimeChanged;

  /// Whether the current theme is dark mode.
  final bool isDark;

  const TimePickerTile({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: () => _showTimePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            Row(
              children: [
                Text(
                  _formatTimeDisplay(time),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.cyan,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeDisplay(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final parts = time.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 8;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cyan,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.elevated : AppColorsLight.elevated,
              onSurface: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeChanged(newTime);
    }
  }
}
