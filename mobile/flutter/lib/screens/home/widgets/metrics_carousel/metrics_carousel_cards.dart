/// Card bodies for the Home metrics carousel. Every card is the real
/// 330×170 slot (mockup: `graphs.html`, build-spec table). Cards are pure
/// presentation — they take an already-resolved data snapshot, never read a
/// provider directly, so each is independently widget-testable (see
/// `test/screens/home/widgets/metrics_carousel_test.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/metrics_carousel_prefs.dart';
import '../../../../data/providers/combined_health_provider.dart';
import '../../../../data/providers/metrics_carousel_data_provider.dart';
import 'metrics_carousel_painters.dart';

/// Shell geometry shared with the other Home cards this sits between — the
/// challenge card and the program card (`setup_checklist_card.dart` uses
/// radius 16 / `EdgeInsets.all(14)`). Named here so the carousel cannot
/// silently drift off them again.
const double kHomeCardRadius = 16;
const double kHomeCardPadding = 14;

/// Extra bottom inset for the page-dot row painted inside the card.
const double kCarouselDotsAllowance = 20;

const double kCarouselCardWidth = 330;
const double kCarouselCardHeightNormal = 170;
const double kCarouselCardHeightTall = 240;

/// Horizontal clearance any card content must leave along the top-right
/// corner so it never sits under [_EditButton] (26px wide, offset 12px from
/// the card edge, painted in a separate `Positioned` layer OUTSIDE the
/// card's own content padding — cards must reserve this space themselves).
/// E2E row 133: `VolumeTrendCard`'s top-right delta readout ("— —") had no
/// such clearance and rendered straight through the pencil icon.
const double kCarouselEditButtonClearance = 34;

// ---------------------------------------------------------------------------
// Shell — chrome shared by every page: surface, edit button, pagination.
// ---------------------------------------------------------------------------

class CarouselCardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onEdit;
  final int pageIndex;
  final int pageCount;
  final bool tall;
  final bool isPlaceholder;

  const CarouselCardShell({
    super.key,
    required this.child,
    required this.onEdit,
    required this.pageIndex,
    required this.pageCount,
    this.tall = false,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    // NOT `ConstrainedBox(maxWidth: kCarouselCardWidth)` — that pinned the
    // card to a flat 330pt regardless of the width the PageView item slot
    // actually offers (device width minus the shared `kHomeHPad` gutters,
    // e.g. 358pt on a 390pt phone), leaving an unexplained ~28pt gap on the
    // right that every neighbouring Home card (health strip, coach card,
    // workout-complete card) fills (E2E row 137). `width: double.infinity`
    // fills whatever width the PageView item slot provides, matching them.
    //
    // Height is ALSO `double.infinity`, NOT this shell's own `tall ? ... :
    // ...` (E2E row 194): `metrics_carousel.dart` sizes the shared PageView
    // VIEWPORT from the Training page's `tall` flag alone (only Training
    // supports the taller variant), so every page's ITEM SLOT is already
    // exactly `kCarouselCardHeightTall` once Training opts in — but this
    // shell used to independently re-derive its own height from ITS OWN
    // page's `tall` (always false for every other page), leaving an ~87pt
    // dead gap between the (170px) card and "Browse programs" below on
    // every page except Training. Filling the ambient tight height the
    // item slot already provides keeps every page's card exactly as tall
    // as the viewport it's actually painted in, with no separate
    // computation to drift out of sync.
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          // Matches the Home cards this sits between (the challenge card and
          // the program card both use radius 16 / padding 14). It used to be
          // radius 14 / padding 13 — off by one on both, and off the 8px
          // grid, which is exactly why the card read as "inconsistent"
          // against its neighbours without an obvious cause.
          borderRadius: BorderRadius.circular(kHomeCardRadius),
          border: Border.all(
            color: isPlaceholder ? c.textMuted.withValues(alpha: 0.3) : c.cardBorder,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              // Bottom is the shared inset PLUS room for the page dots that
              // sit inside this card, rather than an unexplained 34.
              padding: const EdgeInsets.fromLTRB(
                kHomeCardPadding,
                kHomeCardPadding,
                kHomeCardPadding,
                kHomeCardPadding + kCarouselDotsAllowance,
              ),
              child: child,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _EditButton(onTap: onEdit, c: c),
            ),
            // Pagination guard: a single page hides the control entirely —
            // "a lone dot is a control that does nothing" (build spec).
            if (pageCount > 1) ...[
              Positioned(
                left: 13,
                bottom: 14,
                child: _PaginationDots(
                  index: pageIndex,
                  count: pageCount,
                  c: c,
                ),
              ),
              Positioned(
                right: 13,
                bottom: 12,
                child: Text(
                  '${pageIndex + 1} of $pageCount',
                  style: ZType.data(8, color: c.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeColors c;
  const _EditButton({required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.cardBorder),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.edit_outlined, size: 13, color: c.textMuted),
        ),
      ),
    );
  }
}

class _PaginationDots extends StatelessWidget {
  final int index;
  final int count;
  final ThemeColors c;
  const _PaginationDots({required this.index, required this.count, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            child: Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: i == index ? c.accent : c.textMuted.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Training page
// ---------------------------------------------------------------------------

class TrainingCard extends ConsumerWidget {
  final TrainingWeekStats stats;
  final List<CarouselSlotId> slots;
  final bool tall;

  const TrainingCard({
    super.key,
    required this.stats,
    required this.slots,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final fraction = stats.sessionsScheduled <= 0
        ? 0.0
        : (stats.sessionsCompleted / stats.sessionsScheduled).clamp(0.0, 1.0);
    // Guard: a streak of 0-2 renders muted, not accent — the accent is
    // earned. Mirrors the mockup's "day one" frame (streak=2 → grey ring).
    final streakEarned = stats.streakDays >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Semantics(
                  label:
                      '${stats.sessionsCompleted} of ${stats.sessionsScheduled} sessions this week',
                  child: CustomPaint(
                    painter: TickRingPainter(
                      fraction: fraction,
                      muted: stats.sessionsCompleted == 0,
                      trackColor: c.cardBorder,
                      tickColor: c.textMuted.withValues(alpha: 0.35),
                      accentColor: c.accent,
                      mutedColor: c.textMuted,
                    ),
                    child: stats.sessionsScheduled > 0
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${stats.sessionsCompleted}',
                                    style: ZType.disp(30, color: c.textPrimary)),
                                Text('OF ${stats.sessionsScheduled}',
                                    style: ZType.data(7.5, color: c.textMuted)),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('0',
                                    style: ZType.disp(30, color: c.textMuted)),
                                Text('SESSIONS',
                                    style: ZType.data(7.5, color: c.textMuted)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NOT a training streak — `stats.streakDays` is the
                      // app-open (login) streak (metrics_carousel_data_
                      // provider.dart wires it from xpCurrentStreakProvider).
                      // On a card that's otherwise all training metrics
                      // ("1 OF 4 sessions", volume, PRs), a bare "STREAK"
                      // read as training days and could flatly contradict
                      // the sessions ring next to it (E2E row 134).
                      Text('LOGIN STREAK', style: ZType.data(8.5, color: c.textMuted)),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: ZType.disp(26,
                              color: streakEarned ? c.accent : c.textMuted),
                          children: [
                            TextSpan(text: '${stats.streakDays}'),
                            TextSpan(
                              text: stats.streakDays == 1 ? ' day' : ' days',
                              style: TextStyle(
                                fontFamily: 'Space Mono',
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _TrainingStatStrip(stats: stats, slots: slots, tall: tall, c: c),
      ],
    );
  }
}

class _TrainingStatStrip extends ConsumerWidget {
  final TrainingWeekStats stats;
  final List<CarouselSlotId> slots;
  final bool tall;
  final ThemeColors c;

  const _TrainingStatStrip({
    required this.stats,
    required this.slots,
    required this.tall,
    required this.c,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slots.isEmpty) return const SizedBox.shrink();

    final needsSteps = slots.contains(CarouselSlotId.steps);
    int? weeklySteps;
    if (needsSteps) {
      final history = ref.watch(combinedHealthHistoryProvider).valueOrNull;
      if (history != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        weeklySteps = 0;
        for (final d in history.days) {
          final day = DateTime(d.date.year, d.date.month, d.date.day);
          if (!day.isBefore(weekStart) && !day.isAfter(today)) {
            weeklySteps = (weeklySteps ?? 0) + d.steps;
          }
        }
      }
    }

    final tiles = [
      for (final slot in slots) _tileFor(slot, weeklySteps),
    ];

    final rows = tall
        ? [tiles.take(3).toList(), tiles.skip(3).toList()]
        : [tiles];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++)
          if (rows[r].isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.cardBorder)),
                ),
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    for (int i = 0; i < rows[r].length; i++)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 9),
                          decoration: BoxDecoration(
                            border: Border(
                              right: i == rows[r].length - 1
                                  ? BorderSide.none
                                  : BorderSide(color: c.cardBorder),
                            ),
                          ),
                          child: rows[r][i],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _tileFor(CarouselSlotId slot, int? weeklySteps) {
    final valueSize = slots.length >= 5 ? 12.0 : (slots.length == 4 ? 15.0 : 19.0);
    final labelSize = slots.length >= 5 ? 5.5 : (slots.length == 4 ? 6.5 : 7.5);
    late final String value;
    late final Color color;
    switch (slot) {
      case CarouselSlotId.volumeKg:
        value = _formatThousands(stats.volumeKg.round());
        color = c.textPrimary;
        break;
      case CarouselSlotId.timeHrs:
        value = _formatHoursMinutes(stats.totalMinutes);
        color = c.textPrimary;
        break;
      case CarouselSlotId.newPrs:
        value = '${stats.newPrsThisWeek}';
        // Guard: PR count 0 → muted, not accent.
        color = stats.newPrsThisWeek > 0 ? c.accent : c.textMuted;
        break;
      case CarouselSlotId.caloriesBurned:
        value = '${stats.caloriesBurned}';
        color = c.textPrimary;
        break;
      case CarouselSlotId.exercisesDone:
        value = '${stats.exercisesDone}';
        color = c.textPrimary;
        break;
      case CarouselSlotId.steps:
        value = weeklySteps == null ? '—' : _formatThousands(weeklySteps);
        color = c.textPrimary;
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: ZType.disp(valueSize, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(slot.tileLabel, style: ZType.data(labelSize, color: c.textMuted)),
      ],
    );
  }
}

String _formatThousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return (value < 0 ? '-' : '') + buf.toString();
}

String _formatHoursMinutes(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Volume trend page
// ---------------------------------------------------------------------------

class VolumeTrendCard extends StatelessWidget {
  final VolumeTrendSnapshot data;
  const VolumeTrendCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final delta = data.deltaPercent;
    final maxKg = data.weeks.isEmpty
        ? 0.0
        : data.weeks.map((w) => w.totalVolumeKg).reduce((a, b) => a > b ? a : b);
    final normalized = [
      for (final w in data.weeks) maxKg <= 0 ? 0.0 : w.totalVolumeKg / maxKg,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TRAINING VOLUME', style: ZType.data(8.5, color: c.textMuted)),
                  Text.rich(
                    TextSpan(
                      style: ZType.disp(38, color: c.textPrimary, height: 0.84),
                      children: [
                        TextSpan(
                          text: data.currentWeekKg == null
                              ? '—'
                              : _formatThousands(data.currentWeekKg!.round()),
                        ),
                        TextSpan(
                          text: '\nKG THIS WEEK',
                          style: TextStyle(
                            fontFamily: 'Space Mono',
                            fontSize: 10,
                            letterSpacing: 1.2,
                            height: 2.2,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // Clears the shell's top-right edit button (E2E row 133) — the
              // "— —" no-comparison placeholder used to render straight
              // through the pencil icon.
              padding: const EdgeInsets.only(right: kCarouselEditButtonClearance),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Guard: fewer than 2 weeks of history → "— —", never 0%.
                  Text(
                    delta == null
                        ? '— —'
                        : '${delta >= 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: delta == null
                          ? c.textMuted
                          : (delta >= 0 ? c.accent : c.textMuted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delta == null ? 'no comparison yet' : 'vs last week',
                    style: ZType.data(8, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: AreaChartPainter(
              values: normalized,
              accentColor: c.accent,
              baselineColor: c.cardBorder,
            ),
          ),
        ),
        if (data.weeks.length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('W1', style: ZType.data(7, color: c.textMuted)),
                Text('W${data.weeks.length}', style: ZType.data(7, color: c.accent)),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery page
// ---------------------------------------------------------------------------

class RecoveryCard extends StatelessWidget {
  final RecoverySnapshot data;
  const RecoveryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final readiness = data.readiness;
    final readinessScore = readiness?.readinessScore;
    final maxMinutes = data.sleepMinutesByNight.isEmpty
        ? 0
        : data.sleepMinutesByNight.reduce((a, b) => a > b ? a : b);
    final avgMinutes = data.sleepMinutesByNight.isEmpty
        ? 0
        : data.sleepMinutesByNight.reduce((a, b) => a + b) ~/
            data.sleepMinutesByNight.length;
    final normalizedSleep = [
      for (final m in data.sleepMinutesByNight)
        maxMinutes <= 0 ? 0.0 : m / maxMinutes,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SLEEP · 7 NIGHTS', style: ZType.data(8.5, color: c.textMuted)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: ZType.disp(26, color: c.textPrimary),
                  children: [
                    TextSpan(text: _formatHoursMinutes(avgMinutes)),
                    TextSpan(
                      text: ' avg',
                      style: TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: CustomPaint(
                  painter: SleepBarsPainter(
                    values: normalizedSleep,
                    accentColor: c.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('READINESS', style: ZType.data(8.5, color: c.textMuted)),
              const SizedBox(height: 2),
              SizedBox(
                height: 56,
                width: 96,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(96, 56),
                      painter: ReadinessArcPainter(
                        fraction: (readinessScore ?? 0) / 100,
                        trackColor: c.cardBorder,
                        accentColor: c.accent,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        readinessScore == null ? '—' : '$readinessScore',
                        style: ZType.disp(22, color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                readiness?.level.name.toUpperCase() ?? '—',
                style: ZType.data(8.5, color: c.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coming-soon placeholder — Muscle balance / PR ladder. Neither had a card
// mockup to build against and both would need `fl_chart` (radar/line) which
// the build spec explicitly excludes for this pass, so toggling them on
// shows an honest "not built yet" card rather than a fabricated chart.
// ---------------------------------------------------------------------------

class ComingSoonCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const ComingSoonCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: ZType.data(9, color: c.textMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: c.textMuted, fontFamily: 'Archivo'),
          ),
        ],
      ),
    );
  }
}
