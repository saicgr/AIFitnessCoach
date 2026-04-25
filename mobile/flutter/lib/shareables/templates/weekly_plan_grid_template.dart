import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// Mon–Sun multi-day grid (matches reference Image #6 — 3-col layout, every
/// day's workout listed with its exercise rows). Used by `weeklyPlan` shares.
///
/// Falls back to a single-column "all rest" message if [Shareable.planDays]
/// is empty so the share still renders something legible.
class WeeklyPlanGridTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WeeklyPlanGridTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final days = data.planDays ?? const <SharablePlanDay>[];
    final url = data.deepLinkUrl;
    final user = data.userDisplayName?.trim();

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 52, 18, 22),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showWatermark)
                    const FitWizWatermark(
                      textColor: Color(0xFF111111),
                      iconSize: 18,
                      fontSize: 12,
                    ),
                  const Spacer(),
                  if (user != null && user.isNotEmpty)
                    Text(
                      "$user · ${data.periodLabel}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: days.isEmpty
                    ? const Center(
                        child: Text(
                          'No workouts this week',
                          style: TextStyle(color: Color(0xFF888888)),
                        ),
                      )
                    : _DayGrid(days: days, mul: mul),
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
}

class _DayGrid extends StatelessWidget {
  final List<SharablePlanDay> days;
  final double mul;

  const _DayGrid({required this.days, required this.mul});

  @override
  Widget build(BuildContext context) {
    // 3 columns desktop, 2 on portrait. Determined by aspect via available width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 540 ? 3 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) => _DayCell(day: days[i], mul: mul),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final SharablePlanDay day;
  final double mul;

  const _DayCell({required this.day, required this.mul});

  static const _weekdayShort = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  Widget build(BuildContext context) {
    final wd = _weekdayShort[day.date.weekday - 1];
    final monthDay = '${day.date.month}/${day.date.day}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: day.isRestDay ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wd,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF888888),
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                monthDay,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFFAAAAAA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (day.isRestDay)
            const Expanded(
              child: Center(
                child: Text(
                  'Rest',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else ...[
            Text(
              day.workoutName ?? '',
              style: TextStyle(
                fontSize: 12 * mul,
                fontWeight: FontWeight.w900,
                color: day.isCompleted
                    ? const Color(0xFF065F46)
                    : const Color(0xFF111111),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: day.exercises.take(6).length +
                    (day.exercises.length > 6 ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= day.exercises.length) {
                    return Text(
                      '+${day.exercises.length - 6} more',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF999999),
                      ),
                    );
                  }
                  final ex = day.exercises[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MicroThumb(url: ex.imageUrl),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            ex.name,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MicroThumb extends StatelessWidget {
  final String? url;

  const _MicroThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url!.isNotEmpty)
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (ctx, child, prog) {
                if (prog == null) return child;
                return const ColoredBox(color: Color(0xFFE5E5E5));
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
