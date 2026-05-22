/// Month-grid calendar for the Cycle "Calendar" tab.
///
/// Each day cell is coloured by its predicted phase, period days are marked
/// with a flow dot, the fertile window is shaded, the ovulation day carries a
/// star, and "today" is ringed. Tapping a day surfaces that day's log (view
/// / edit). Month navigation is capped at the current month (no future).
///
/// Grid layout modelled on `screens/mood/widgets/mood_calendar_heatmap.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../../../data/services/haptic_service.dart';
import '../cycle_visuals.dart';

/// A logged day's compact summary, keyed by date for the calendar.
class CycleDayLog {
  final DateTime date;
  final double? bbtCelsius;
  final String? periodFlow;
  final List<String> symptoms;
  final String? mucus;
  final String? lhResult;

  const CycleDayLog({
    required this.date,
    this.bbtCelsius,
    this.periodFlow,
    this.symptoms = const [],
    this.mucus,
    this.lhResult,
  });

  bool get hasAnything =>
      bbtCelsius != null ||
      periodFlow != null ||
      symptoms.isNotEmpty ||
      mucus != null ||
      lhResult != null;
}

class CycleCalendar extends StatefulWidget {
  final CyclePrediction? prediction;
  final List<CyclePeriod> periods;

  /// Logged days keyed by local-midnight date.
  final Map<DateTime, CycleDayLog> logsByDay;
  final Color accent;

  /// Tapping a day cell — opens that day's log (view / edit).
  final void Function(DateTime day, CycleDayLog? log) onDayTap;

  const CycleCalendar({
    super.key,
    required this.prediction,
    required this.periods,
    required this.logsByDay,
    required this.accent,
    required this.onDayTap,
  });

  @override
  State<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<CycleCalendar> {
  late DateTime _month; // first day of the displayed month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    HapticService.selection();
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year > now.year ||
        (_month.year == now.year && _month.month >= now.month)) {
      return;
    }
    HapticService.selection();
    setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
  }

  /// All period dates as a set for fast membership lookup.
  Set<int> get _periodDays {
    final out = <int>{};
    for (final p in widget.periods) {
      final end = p.endDate ?? p.startDate;
      var d = CycleDates.dateOnly(p.startDate);
      final last = CycleDates.dateOnly(end);
      var guard = 0;
      while (!d.isAfter(last) && guard < 60) {
        out.add(_dayKey(d));
        d = d.add(const Duration(days: 1));
        guard++;
      }
    }
    return out;
  }

  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    final firstWeekday = _month.weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final today = CycleDates.dateOnly(DateTime.now());
    final periodDays = _periodDays;
    final ovu = widget.prediction?.ovulationDate;

    // Leading blanks so day 1 aligns under its weekday column.
    final leading = firstWeekday - 1;
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      cells.add(_dayCell(
        date: date,
        fg: fg,
        isDark: isDark,
        isToday: CycleDates.sameDay(date, today),
        isPeriod: periodDays.contains(_dayKey(date)),
        isOvulation: ovu != null && CycleDates.sameDay(date, ovu),
        log: widget.logsByDay[CycleDates.dateOnly(date)],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left_rounded, color: fg),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Expanded(
                child: Text(
                  CycleDates.monthYear(_month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _canGoNext ? _nextMonth : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _canGoNext
                      ? fg
                      : fg.withValues(alpha: 0.25),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Weekday header.
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 12),
          _legend(fg),
        ],
      ),
    );
  }

  Widget _dayCell({
    required DateTime date,
    required Color fg,
    required bool isDark,
    required bool isToday,
    required bool isPeriod,
    required bool isOvulation,
    required CycleDayLog? log,
  }) {
    final phase = widget.prediction == null
        ? null
        : cyclePhaseForDate(widget.prediction!, date);
    final phaseColor = isPeriod
        ? CyclePhaseColors.menstrual
        : CyclePhaseColors.of(phase);
    final isFuture = date.isAfter(CycleDates.dateOnly(DateTime.now()));

    return GestureDetector(
      onTap: () {
        HapticService.light();
        widget.onDayTap(CycleDates.dateOnly(date), log);
      },
      child: Container(
        decoration: BoxDecoration(
          color: phase == null && !isPeriod
              ? Colors.transparent
              : phaseColor.withValues(
                  alpha: isFuture ? 0.12 : 0.24),
          borderRadius: BorderRadius.circular(9),
          border: isToday
              ? Border.all(color: widget.accent, width: 1.6)
              : Border.all(
                  color: fg.withValues(alpha: 0.05),
                ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isFuture
                    ? fg.withValues(alpha: 0.4)
                    : fg.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight:
                    isToday ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            // Ovulation star (top-right).
            if (isOvulation)
              Positioned(
                top: 2,
                right: 3,
                child: Icon(Icons.star_rounded,
                    size: 9, color: CyclePhaseColors.ovulation),
              ),
            // Period flow dot (bottom).
            if (isPeriod)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: CyclePhaseColors.menstrual,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            // Logged-data indicator (bottom-right small dot).
            if (log != null && log.hasAnything && !isPeriod)
              Positioned(
                bottom: 3,
                right: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color fg) {
    Widget item(Color c, String label, {bool star = false, bool dot = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (star)
            Icon(Icons.star_rounded, size: 11, color: c)
          else if (dot)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            )
          else
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg.withValues(alpha: 0.55), fontSize: 10)),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        item(CyclePhaseColors.menstrual, 'Period', dot: true),
        item(CyclePhaseColors.follicular, 'Follicular'),
        item(CyclePhaseColors.ovulation, 'Fertile'),
        item(CyclePhaseColors.luteal, 'Luteal'),
        item(CyclePhaseColors.ovulation, 'Ovulation', star: true),
      ],
    );
  }
}
