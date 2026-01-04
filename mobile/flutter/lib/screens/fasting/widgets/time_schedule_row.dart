import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

/// Compact inline row showing start time (tappable) and calculated end time
class TimeScheduleRow extends StatelessWidget {
  final DateTime startTime;
  final int durationMinutes;
  final ValueChanged<DateTime> onStartTimeChanged;
  final bool isDark;

  const TimeScheduleRow({
    super.key,
    required this.startTime,
    required this.durationMinutes,
    required this.onStartTimeChanged,
    required this.isDark,
  });

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  bool get _endsNextDay {
    return endTime.day != startTime.day;
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    return '${hours}h';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: isDark ? AppColors.purple : AppColorsLight.purple,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final newStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      onStartTimeChanged(newStartTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showTimePicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              // Start time section
              Icon(
                Icons.play_circle_outline_rounded,
                size: 18,
                color: purple,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(startTime),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: textMuted,
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: textMuted,
                ),
              ),

              // End time section
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _formatTime(endTime),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_endsNextDay) ...[
                const SizedBox(width: 2),
                Text(
                  '+1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],

              const Spacer(),

              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(durationMinutes),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
