import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../core/providers/week_start_provider.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/services/haptic_service.dart';

import '../l10n/generated/app_localizations.dart';
/// Horizontal, week-paginated date strip shared by the Nutrition tab and the
/// Sleep / Combined-Health detail screens.
///
/// Originally `NutritionDateStrip`; lifted to `lib/widgets/` so the health
/// detail screens can reuse the exact same scrub affordance (one source of
/// truth for the visual + the future-day disabling + the calendar jump).
///
/// Behaviour (edge cases B from the Sleep & Health plan):
///   * Days the caller flags via [loggedDateKeys] get an accent dot — for the
///     health screens this is "a night with sleep data" / "a day with
///     activity". A day with no key just renders no dot (per-day empty state
///     surfaces inside the screen body — case 12).
///   * Today and the currently-selected day are highlighted distinctly; today
///     is always reachable even before the morning sync lands (case 13 — the
///     screen body shows the most-recent night when today has no data yet).
///   * Future days are rendered dim and tap-disabled (case 14).
///   * [weeksBack] bounds how far the strip scrolls; callers cap it to the
///     real backfill window so the strip never implies data older than the
///     app has (case 15). The calendar icon still jumps anywhere in range.
///   * DST day cells render correctly — each cell is `weekStart + N days`
///     constructed at local midnight, so a 23h / 25h DST day is still one
///     cell (case 16).
class DateStrip extends ConsumerStatefulWidget {
  /// Currently selected date (driven by the parent).
  final DateTime selectedDate;

  /// Set of `yyyy-MM-dd` (local timezone) keys for days that have data —
  /// cells with a key show an accent dot. Empty set is allowed.
  final Set<String> loggedDateKeys;

  /// Tap callback. The returned [DateTime] is normalized to local midnight.
  final ValueChanged<DateTime> onDaySelected;

  /// How many weeks back the strip can scroll before the user has to use the
  /// calendar icon. Defaults to 53 (≈1 year) for the nutrition tab; the
  /// health screens pass a smaller value matching their backfill window.
  final int weeksBack;

  const DateStrip({
    super.key,
    required this.selectedDate,
    required this.loggedDateKeys,
    required this.onDaySelected,
    this.weeksBack = 53,
  });

  @override
  ConsumerState<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends ConsumerState<DateStrip> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(DateStrip oldWidget) {
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
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
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
              tooltip: AppLocalizations.of(context).scheduleMealPickADate,
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
    final selKey = _DateStripState._dateKey(selectedDate);
    final todayKey = _DateStripState._dateKey(today);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (displayIndex) {
        final date = weekStart.add(Duration(days: displayIndex));
        final dateKey = _DateStripState._dateKey(date);
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

  /// Today cell: accent-colored day label above an accent-filled rounded-rect
  /// number pill (matching the home screen's WeekCalendarStrip style). Shares
  /// the *exact* same vertical layout as every other cell (label → 4 → 32-tall
  /// slot → 4 → dot) so all day letters stay on one baseline. The pill is
  /// slightly wider than the 32 sibling circles (minWidth 36) to mark "today"
  /// without ever protruding above the row.
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
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 32,
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$dateNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
}

/// Helper exposed for parents that want to derive the date-key set from a
/// list of objects with a DateTime. Keeps the "yyyy-MM-dd" format consistent
/// with the strip's internal keying.
String dateStripKey(DateTime d) {
  final local = d.isUtc ? d.toLocal() : d;
  return DateFormat('yyyy-MM-dd').format(local);
}
