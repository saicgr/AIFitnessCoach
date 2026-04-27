import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Calendar-style 4×7 grid for `monthlyPlan` shares.
/// Each cell shows day number + workout type chip; rest days are dimmed.
class MonthlyPlanGridTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MonthlyPlanGridTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final days = data.planDays ?? const <SharablePlanDay>[];
    final user = data.userDisplayName?.trim();
    final url = data.deepLinkUrl;

    final byDate = <DateTime, SharablePlanDay>{
      for (final d in days)
        DateTime(d.date.year, d.date.month, d.date.day): d,
    };

    final firstDay = days.isNotEmpty
        ? DateTime(days.first.date.year, days.first.date.month, 1)
        : DateTime.now();
    // Monday-aligned offset. weekday: Mon=1..Sun=7. Convert to 0..6 for Mon-first.
    final offset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(offset, null),
      for (var i = 1; i <= daysInMonth; i++)
        DateTime(firstDay.year, firstDay.month, i),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final monthLabel =
        '${_monthName(firstDay.month)} ${firstDay.year}';

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showWatermark)
                    const AppWatermark(
                      textColor: Color(0xFF111111),
                      iconSize: 20,
                      fontSize: 13,
                    ),
                  const Spacer(),
                  if (user != null && user.isNotEmpty)
                    Text(
                      '@$user',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 26 * mul,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                ),
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 12 * mul,
                  color: const Color(0xFF7A7A7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _DowHeader('M'),
                  _DowHeader('T'),
                  _DowHeader('W'),
                  _DowHeader('T'),
                  _DowHeader('F'),
                  _DowHeader('S'),
                  _DowHeader('S'),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (_, i) {
                    final d = cells[i];
                    if (d == null) {
                      return const SizedBox.shrink();
                    }
                    final dayKey = DateTime(d.year, d.month, d.day);
                    final entry = byDate[dayKey];
                    return _MonthCell(date: d, entry: entry, mul: mul);
                  },
                ),
              ),
              if (url != null && url.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    url.replaceFirst(RegExp(r'^https?://'), ''),
                    style: TextStyle(
                      fontSize: 10 * mul,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }
}

class _DowHeader extends StatelessWidget {
  final String label;
  const _DowHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final DateTime date;
  final SharablePlanDay? entry;
  final double mul;

  const _MonthCell({
    required this.date,
    required this.entry,
    required this.mul,
  });

  Color _typeColor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'strength':
      case 'lifting':
      case 'gym':
        return const Color(0xFF2563EB); // blue
      case 'cardio':
      case 'run':
      case 'cycling':
        return const Color(0xFFDC2626); // red
      case 'hiit':
      case 'circuit':
        return const Color(0xFFEA580C); // orange
      case 'flexibility':
      case 'yoga':
      case 'mobility':
        return const Color(0xFF16A34A); // green
      default:
        return const Color(0xFF7C3AED); // purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorkoutDay = entry != null && !entry!.isRestDay;
    final accent = _typeColor(entry?.workoutType);
    final completed = entry?.isCompleted == true;
    return Container(
      decoration: BoxDecoration(
        color: isWorkoutDay
            ? (completed
                ? accent.withOpacity(0.18)
                : accent.withOpacity(0.08))
            : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWorkoutDay ? accent.withOpacity(0.5) : const Color(0xFFE5E5E5),
          width: 0.6,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 9,
              color: isWorkoutDay
                  ? accent
                  : const Color(0xFFAAAAAA),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isWorkoutDay)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  entry!.workoutName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7 * mul,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: completed ? accent : const Color(0xFF333333),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
