import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

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
                    const AppWatermark(
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
                  fontFamily: 'Anton',
                  fontSize: 26 * mul,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0.2,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              // Accent header rule: picks up the user's in-app accent so the
              // card reads as colored, not hardcoded green.
              Container(
                height: 3,
                width: 64,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(2),
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
                    : _DayGrid(
                        days: days,
                        mul: mul,
                        accentColor: data.accentColor,
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
}

class _DayGrid extends StatelessWidget {
  final List<SharablePlanDay> days;
  final double mul;
  final Color accentColor;

  const _DayGrid({
    required this.days,
    required this.mul,
    required this.accentColor,
  });

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
            childAspectRatio: 0.74,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) =>
              _DayCell(day: days[i], mul: mul, accentColor: accentColor),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final SharablePlanDay day;
  final double mul;
  final Color accentColor;

  const _DayCell({
    required this.day,
    required this.mul,
    required this.accentColor,
  });

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
    final completed = day.isCompleted;
    // Completed days get an accent-tinted fill + border so they pop, rather
    // than a hardcoded green.
    final fill = day.isRestDay
        ? const Color(0xFFF0F0F0)
        : completed
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.08), Colors.white)
            : Colors.white;
    final borderColor = completed && !day.isRestDay
        ? accentColor.withValues(alpha: 0.45)
        : const Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: completed && !day.isRestDay ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wd,
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: completed && !day.isRestDay
                      ? accentColor
                      : const Color(0xFF888888),
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                monthDay,
                style: const TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 10,
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
                    fontFamily: 'Barlow Condensed',
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w600,
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
                color: completed
                    ? Color.alphaBlend(
                        accentColor.withValues(alpha: 0.85),
                        const Color(0xFF111111))
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '+${day.exercises.length - 6} more',
                        style: const TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999),
                        ),
                      ),
                    );
                  }
                  final ex = day.exercises[i];
                  final subtitle = _setsRepsLine(ex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MicroThumb(url: ex.imageUrl),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF222222),
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Barlow Condensed',
                                    fontSize: 9,
                                    color: Color(0xFF8A8A8A),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
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

  /// "{n} sets · {reps} reps" subtitle under each exercise name, BW-aware.
  /// Returns null when the exercise carries no set data so the row collapses
  /// to just the name rather than showing a hollow "0 sets" line.
  static String? _setsRepsLine(ShareableExercise ex) {
    final sets = ex.sets;
    if (sets.isEmpty) return null;
    final setCount = sets.length;
    // Representative rep count: prefer the modal target/logged reps so the
    // line reads "3 sets · 10 reps" rather than a per-set range.
    final reps = sets.first.targetReps ?? sets.first.reps;
    final setLabel = setCount == 1 ? '1 set' : '$setCount sets';
    if (ex.sets.every((s) => s.isBodyweight)) {
      // Bodyweight movement: show "BW" instead of a weight.
      return reps > 0 ? '$setLabel · $reps reps · BW' : '$setLabel · BW';
    }
    if (reps <= 0) return setLabel;
    final repLabel = reps == 1 ? '1 rep' : '$reps reps';
    return '$setLabel · $repLabel';
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
