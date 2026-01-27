import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting_impact.dart';
import '../../../data/services/haptic_service.dart';
import 'mark_fasting_day_sheet.dart';

/// Calendar widget showing fasting days with tap-to-mark functionality
class FastingCalendarWidget extends ConsumerStatefulWidget {
  /// Daily data to display (from fasting impact analysis)
  final List<FastingDayData> dailyData;

  /// Whether the widget is in dark mode
  final bool isDark;

  /// User ID for marking days
  final String? userId;

  /// Callback when a day is marked
  final VoidCallback? onDayMarked;

  /// Whether to allow tapping on days to mark them
  final bool allowMarking;

  const FastingCalendarWidget({
    super.key,
    required this.dailyData,
    required this.isDark,
    this.userId,
    this.onDayMarked,
    this.allowMarking = true,
  });

  @override
  ConsumerState<FastingCalendarWidget> createState() =>
      _FastingCalendarWidgetState();
}

class _FastingCalendarWidgetState extends ConsumerState<FastingCalendarWidget> {
  late DateTime _currentMonth;
  final _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    // Default to current month or first data point's month
    if (widget.dailyData.isNotEmpty) {
      _currentMonth = DateTime(
        widget.dailyData.first.date.year,
        widget.dailyData.first.date.month,
      );
    } else {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    }
  }

  /// Get the data for a specific date
  FastingDayData? _getDataForDate(DateTime date) {
    try {
      return widget.dailyData.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if a date can be marked as a fasting day
  bool _canMarkDate(DateTime date) {
    if (!widget.allowMarking || widget.userId == null) return false;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final thirtyDaysAgo = todayOnly.subtract(const Duration(days: 30));

    // Must be in the past and within 30 days
    if (!dateOnly.isBefore(todayOnly)) return false;
    if (dateOnly.isBefore(thirtyDaysAgo)) return false;

    // Check if already marked as fasting
    final data = _getDataForDate(date);
    if (data != null && data.isFastingDay) return false;

    return true;
  }

  void _onDayTap(DateTime date) {
    if (!_canMarkDate(date)) {
      // If already a fasting day, show info
      final data = _getDataForDate(date);
      if (data != null && data.isFastingDay) {
        _showDayInfo(date, data);
      }
      return;
    }

    HapticService.light();

    // Show mark fasting day sheet
    MarkFastingDaySheet.show(
      context: context,
      userId: widget.userId!,
      initialDate: date,
      onSuccess: widget.onDayMarked,
    );
  }

  void _showDayInfo(DateTime date, FastingDayData data) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isFastingDay) ...[
              _buildInfoRow(
                icon: Icons.timer_outlined,
                label: 'Fasting',
                value: data.fastingHours != null
                    ? '${data.fastingHours!.round()}h fast'
                    : 'Completed',
                color: accentColor,
                isDark: isDark,
              ),
            ],
            if (data.hadWorkout) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.fitness_center,
                label: 'Workout',
                value: data.workoutPerformanceScore != null
                    ? '${(data.workoutPerformanceScore! * 100).round()}% completion'
                    : 'Completed',
                color: accentColor,
                isDark: isDark,
              ),
            ],
            if (data.goalsTotal > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.flag_outlined,
                label: 'Goals',
                value: '${data.goalsCompleted}/${data.goalsTotal} completed',
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
            if (data.weight != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: '${data.weight!.toStringAsFixed(1)} kg',
                color: AppColors.orange,
                isDark: isDark,
              ),
            ],
            if (data.energyLevel != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.bolt,
                label: 'Energy',
                value: '${data.energyLevel}/10',
                color: AppColors.yellow,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _previousMonth() {
    HapticService.light();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    HapticService.light();
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    // Don't go past current month
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _currentMonth = nextMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get first day of month and number of days
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate number of rows needed
    final totalCells = firstWeekday - 1 + daysInMonth;
    final numRows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(Icons.chevron_left, color: textPrimary),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays
                .map((day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          ...List.generate(numRows, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (colIndex) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  final dayNumber = cellIndex - (firstWeekday - 2);

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  final date = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    dayNumber,
                  );
                  final data = _getDataForDate(date);
                  final isToday = _isToday(date);
                  final isFastingDay = data?.isFastingDay ?? false;
                  final hasWorkout = data?.hadWorkout ?? false;
                  final canMark = _canMarkDate(date);

                  return GestureDetector(
                    onTap: () => _onDayTap(date),
                    child: _buildDayCell(
                      day: dayNumber,
                      isToday: isToday,
                      isFastingDay: isFastingDay,
                      hasWorkout: hasWorkout,
                      canMark: canMark,
                      data: data,
                      isDark: isDark,
                    ),
                  );
                }),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: accentColor,
                label: 'Fasting',
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: accentColor,
                label: 'Workout',
                isDark: isDark,
              ),
              if (widget.allowMarking && widget.userId != null) ...[
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: textMuted,
                  label: 'Tap to mark',
                  isDark: isDark,
                  isOutline: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int day,
    required bool isToday,
    required bool isFastingDay,
    required bool hasWorkout,
    required bool canMark,
    required FastingDayData? data,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    Color? backgroundColor;
    Color textColor = textPrimary;
    BoxBorder? border;

    if (isFastingDay) {
      backgroundColor = accentColor.withValues(alpha: 0.2);
      textColor = accentColor;
    }

    if (isToday) {
      border = Border.all(color: accentColor, width: 2);
    }

    if (canMark) {
      border = Border.all(
        color: cardBorder,
        width: 1,
        strokeAlign: BorderSide.strokeAlignOutside,
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isFastingDay || isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          // Workout indicator (small dot at bottom)
          if (hasWorkout)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
    bool isOutline = false,
  }) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOutline ? null : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
