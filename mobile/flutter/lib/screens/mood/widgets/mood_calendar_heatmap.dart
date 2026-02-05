import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood.dart';
import '../../../data/repositories/mood_history_repository.dart';
import '../../../data/services/api_client.dart';

/// Provider for calendar mood data (parameterized by month/year)
final moodCalendarProvider = FutureProvider.autoDispose
    .family<MoodCalendarResponse?, ({int month, int year})>((ref, params) async {
  final userId = await ref.watch(apiClientProvider).getUserId();
  if (userId == null) return null;
  return ref.watch(moodHistoryRepositoryProvider).getMoodCalendar(
        userId: userId,
        month: params.month,
        year: params.year,
      );
});

/// Widget showing a GitHub-style calendar heatmap of mood data
class MoodCalendarHeatmap extends ConsumerStatefulWidget {
  const MoodCalendarHeatmap({super.key});

  @override
  ConsumerState<MoodCalendarHeatmap> createState() => _MoodCalendarHeatmapState();
}

class _MoodCalendarHeatmapState extends ConsumerState<MoodCalendarHeatmap> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    // Don't allow navigating to future months
    if (_selectedYear > now.year ||
        (_selectedYear == now.year && _selectedMonth >= now.month)) {
      return;
    }
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(
      moodCalendarProvider((month: _selectedMonth, year: _selectedYear)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final now = DateTime.now();
    final canGoNext = _selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _goToPreviousMonth,
                icon: Icon(Icons.chevron_left, color: textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _getMonthYearString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              IconButton(
                onPressed: canGoNext ? _goToNextMonth : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext ? textPrimary : textSecondary.withValues(alpha: 0.3),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          calendarData.when(
            data: (data) => _buildCalendarGrid(data, isDark, textSecondary),
            loading: () => _buildLoadingState(),
            error: (e, _) => _buildErrorState(textSecondary),
          ),

          // Summary
          if (calendarData.hasValue && calendarData.value != null) ...[
            const SizedBox(height: 16),
            _buildSummary(calendarData.value!.summary, textPrimary, textSecondary),
          ],

          // Legend
          const SizedBox(height: 12),
          _buildLegend(textSecondary),
        ],
      ),
    );
  }

  String _getMonthYearString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedMonth - 1]} $_selectedYear';
  }

  Widget _buildCalendarGrid(
    MoodCalendarResponse? data,
    bool isDark,
    Color textSecondary,
  ) {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final days = <Widget>[];

    // Add empty cells for days before the first of the month
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox(width: 32, height: 32));
    }

    // Add cells for each day of the month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      final dateStr =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayData = data?.days[dateStr];
      final isToday = _isToday(date);

      days.add(
        _CalendarDay(
          day: day,
          dayData: dayData,
          isToday: isToday,
          isFuture: date.isAfter(DateTime.now()),
          isDark: isDark,
          textSecondary: textSecondary,
        ),
      );
    }

    // Create rows of 7 days each
    final rows = <Widget>[];
    for (var i = 0; i < days.length; i += 7) {
      final rowDays = days.sublist(i, (i + 7).clamp(0, days.length));
      // Pad the last row if needed
      while (rowDays.length < 7) {
        rowDays.add(const SizedBox(width: 32, height: 32));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowDays,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildSummary(
    MoodCalendarSummary summary,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SummaryItem(
          value: '${summary.daysWithCheckins}',
          label: 'Days Tracked',
          color: textPrimary,
          textSecondary: textSecondary,
        ),
        _SummaryItem(
          value: '${summary.totalCheckins}',
          label: 'Total Check-ins',
          color: textPrimary,
          textSecondary: textSecondary,
        ),
        if (summary.mostCommonMood != null)
          _SummaryItem(
            value: Mood.fromString(summary.mostCommonMood!).emoji,
            label: 'Most Common',
            color: textPrimary,
            textSecondary: textSecondary,
          ),
      ],
    );
  }

  Widget _buildLegend(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Mood.great.color, label: 'Great'),
        const SizedBox(width: 12),
        _LegendItem(color: Mood.good.color, label: 'Good'),
        const SizedBox(width: 12),
        _LegendItem(color: Mood.tired.color, label: 'Tired'),
        const SizedBox(width: 12),
        _LegendItem(color: Mood.stressed.color, label: 'Stressed'),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(Color textSecondary) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load calendar',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single day cell in the calendar
class _CalendarDay extends StatelessWidget {
  final int day;
  final MoodCalendarDay? dayData;
  final bool isToday;
  final bool isFuture;
  final bool isDark;
  final Color textSecondary;

  const _CalendarDay({
    required this.day,
    required this.dayData,
    required this.isToday,
    required this.isFuture,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = dayData != null;
    final moodColor = hasData ? dayData!.colorValue : null;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hasData
            ? moodColor!.withValues(alpha: 0.3)
            : (isFuture
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03))),
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(
                color: isDark ? Colors.white : Colors.black,
                width: 1.5,
              )
            : null,
      ),
      child: Center(
        child: hasData && dayData!.checkinCount > 0
            ? Text(
                Mood.fromString(dayData!.primaryMood).emoji,
                style: const TextStyle(fontSize: 14),
              )
            : Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isFuture
                      ? textSecondary.withValues(alpha: 0.3)
                      : textSecondary,
                ),
              ),
      ),
    );
  }
}

/// Summary item widget
class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color textSecondary;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
