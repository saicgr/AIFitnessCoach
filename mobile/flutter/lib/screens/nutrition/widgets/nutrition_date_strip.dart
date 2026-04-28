import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Horizontal scrolling week-paginated date strip for the Nutrition tab.
///
/// Models the home `WeekCalendarStrip` visually but scrolls back through
/// up to one year of weeks, with a calendar icon for jumping further. Days
/// with logged meals get an accent dot under the date number; today and the
/// currently-selected day are highlighted distinctly. Future days are
/// rendered dim and tap-disabled.
class NutritionDateStrip extends ConsumerStatefulWidget {
  /// Currently selected date (driven by the parent).
  final DateTime selectedDate;

  /// Set of `yyyy-MM-dd` (local timezone) keys for days the user logged
  /// food. Empty set is allowed; cells without a key just don't show a dot.
  final Set<String> loggedDateKeys;

  /// Tap callback. The returned [DateTime] is normalized to local midnight.
  final ValueChanged<DateTime> onDaySelected;

  /// How many weeks back the strip can scroll before the user has to use
  /// the calendar icon. Defaults to 53 (≈1 year).
  final int weeksBack;

  const NutritionDateStrip({
    super.key,
    required this.selectedDate,
    required this.loggedDateKeys,
    required this.onDaySelected,
    this.weeksBack = 53,
  });

  @override
  ConsumerState<NutritionDateStrip> createState() => _NutritionDateStripState();
}

class _NutritionDateStripState extends ConsumerState<NutritionDateStrip> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(NutritionDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedWeek();
    }
  }

  void _scrollToSelectedWeek() {
    final weekConfig = ref.read(weekDisplayConfigProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekStart = weekConfig.weekStart(today);
    final sel = widget.selectedDate;
    final selWeekStart = weekConfig.weekStart(DateTime(sel.year, sel.month, sel.day));
    final diffDays = todayWeekStart.difference(selWeekStart).inDays;
    final page = (diffDays / 7).round().clamp(0, widget.weeksBack - 1);
    if (!_controller.hasClients) return;
    final currentPage = _controller.page?.round() ?? 0;
    if (currentPage == page) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openPicker(BuildContext context) async {
    HapticService.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: now.subtract(Duration(days: widget.weeksBack * 7)),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null) {
      widget.onDaySelected(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);
    final weekConfig = ref.watch(weekDisplayConfigProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekStart = weekConfig.weekStart(today);

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                reverse: true,
                itemCount: widget.weeksBack,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemBuilder: (context, pageIndex) {
                  final weekStart =
                      todayWeekStart.subtract(Duration(days: 7 * pageIndex));
                  return _WeekRow(
                    weekStart: weekStart,
                    today: today,
                    selectedDate: widget.selectedDate,
                    loggedDateKeys: widget.loggedDateKeys,
                    weekConfig: weekConfig,
                    accentColor: accentColor,
                    isDark: isDark,
                    onDaySelected: widget.onDaySelected,
                  );
                },
              ),
            ),
            // Calendar icon — jump > weeksBack with the system date picker.
            IconButton(
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: textMuted,
              ),
              tooltip: 'Pick a date',
              onPressed: () => _openPicker(context),
              splashRadius: 20,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final DateTime weekStart;
  final DateTime today;
  final DateTime selectedDate;
  final Set<String> loggedDateKeys;
  final WeekDisplayConfig weekConfig;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekRow({
    required this.weekStart,
    required this.today,
    required this.selectedDate,
    required this.loggedDateKeys,
    required this.weekConfig,
    required this.accentColor,
    required this.isDark,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final selKey = _NutritionDateStripState._dateKey(selectedDate);
    final todayKey = _NutritionDateStripState._dateKey(today);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (displayIndex) {
        final date = weekStart.add(Duration(days: displayIndex));
        final dateKey = _NutritionDateStripState._dateKey(date);
        final isToday = dateKey == todayKey;
        final isSelected = dateKey == selKey;
        final isFuture = date.isAfter(today);
        final hasLog = loggedDateKeys.contains(dateKey);

        return _DayCell(
          dayLabel: weekConfig.dayLabels[displayIndex],
          dateNumber: date.day,
          isToday: isToday,
          isSelected: isSelected,
          isFuture: isFuture,
          hasLog: hasLog,
          accentColor: accentColor,
          isDark: isDark,
          onTap: isFuture
              ? null
              : () {
                  HapticService.selection();
                  onDaySelected(DateTime(date.year, date.month, date.day));
                },
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String dayLabel;
  final int dateNumber;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final bool hasLog;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _DayCell({
    required this.dayLabel,
    required this.dateNumber,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.hasLog,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Today (selected or not) → filled accent pill with white text.
    // Everything else keeps label-above + circle-below layout.
    if (isToday) {
      return _buildTodayPill();
    }

    final Color dateColor;
    final Color labelColor;
    final FontWeight dateWeight;
    Color? cellBg;
    Border? cellBorder;

    if (isFuture) {
      dateColor = isDark ? Colors.white24 : Colors.black26;
      labelColor = dateColor;
      dateWeight = FontWeight.w400;
    } else if (isSelected) {
      // Past selected — accent outline ring, accent-colored text.
      cellBorder = Border.all(color: accentColor, width: 2);
      dateColor = accentColor;
      labelColor = accentColor;
      dateWeight = FontWeight.w700;
    } else {
      dateColor = isDark ? Colors.white : Colors.black87;
      labelColor = isDark ? Colors.white70 : Colors.black54;
      dateWeight = FontWeight.w500;
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cellBg,
                  border: cellBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dateNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: dateWeight,
                    color: dateColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: hasLog
                    ? Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Today cell: filled solid accent-green rounded-rect pill (matching the
  /// home screen's WeekCalendarStrip style) with white label + white number.
  Widget _buildTodayPill() {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: hasLog
                    ? Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper exposed for parents that want to derive the date-key set from a
/// list of `FoodLog` (or any objects with a `loggedAt` DateTime). Keeps the
/// "yyyy-MM-dd" format consistent with the strip's internal keying.
String nutritionDateKey(DateTime d) {
  final local = d.isUtc ? d.toLocal() : d;
  return DateFormat('yyyy-MM-dd').format(local);
}
