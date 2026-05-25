/// "Fertility window" mini timeline — a horizontal 28-day strip on the
/// Today tab that places today, the predicted ovulation day and the 6-day
/// fertile band on a single glance-readable bar.
///
/// Pure paint: no extra API calls. All dates derive from the supplied
/// [CyclePrediction]. Always renders — when the prediction is low-
/// confidence we still draw an estimated window with a small caption so the
/// user knows it's an estimate (rather than hiding the card outright).
library;

import 'package:flutter/material.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_visuals.dart';

import '../../../l10n/generated/app_localizations.dart';
class TodayFertilityWindowStrip extends StatelessWidget {
  /// The active cycle prediction. May be null — the card still renders with
  /// a "log a period" hint.
  final CyclePrediction? prediction;

  /// Pink cycle accent.
  final Color accent;

  const TodayFertilityWindowStrip({
    super.key,
    required this.prediction,
    required this.accent,
  });

  /// Window length of the strip in cycle-days.
  static const int _windowDays = 28;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final today = CycleDates.dateOnly(DateTime.now());
    final p = prediction;

    // Anchor: prefer last period start (cycle day 1 = lastPeriodStart),
    // else 28-day window centred on today.
    final anchor = p?.lastPeriodStart != null
        ? CycleDates.dateOnly(p!.lastPeriodStart!)
        : today.subtract(const Duration(days: 14));

    // todayOffset can fall outside 0.._windowDays-1 if the cycle is very
    // long or very stale — clamp for display but show a tiny caption when
    // we did so.
    final rawOffset = today.difference(anchor).inDays;
    final offsetInWindow =
        rawOffset >= 0 && rawOffset < _windowDays ? rawOffset : null;

    int? fertileStartOffset;
    int? fertileEndOffset;
    final fs = p?.fertileWindowStart;
    final fe = p?.fertileWindowEnd;
    if (fs != null && fe != null) {
      final start = CycleDates.dateOnly(fs).difference(anchor).inDays;
      final end = CycleDates.dateOnly(fe).difference(anchor).inDays;
      // Clip to window.
      fertileStartOffset = start.clamp(0, _windowDays - 1);
      fertileEndOffset = end.clamp(0, _windowDays - 1);
      if (fertileEndOffset < fertileStartOffset) {
        fertileStartOffset = null;
        fertileEndOffset = null;
      }
    }

    int? ovulationOffset;
    final ov = p?.ovulationDate;
    if (ov != null) {
      final o = CycleDates.dateOnly(ov).difference(anchor).inDays;
      if (o >= 0 && o < _windowDays) ovulationOffset = o;
    }

    final lowConfidence = p == null || p.confidence != 'high';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
              Icon(Icons.favorite_rounded,
                  size: 16, color: CyclePhaseColors.ovulation),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).todayFertilityWindowFertilityWindow,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (lowConfidence)
                Text(
                  AppLocalizations.of(context).todayFertilityWindowLowConfidenceEstimate,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            const trackHeight = 14.0;
            return SizedBox(
              height: 38,
              child: Stack(
                children: [
                  // Base track.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 12,
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                  // Fertile band.
                  if (fertileStartOffset != null && fertileEndOffset != null)
                    Positioned(
                      left: _xFor(fertileStartOffset, w),
                      top: 12,
                      child: Container(
                        height: trackHeight,
                        width: _xFor(fertileEndOffset + 1, w) -
                            _xFor(fertileStartOffset, w),
                        decoration: BoxDecoration(
                          color: CyclePhaseColors.ovulation
                              .withValues(alpha: lowConfidence ? 0.35 : 0.55),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  // Ovulation marker.
                  if (ovulationOffset != null)
                    Positioned(
                      left: _xFor(ovulationOffset, w) - 5,
                      top: 6,
                      child: Container(
                        width: 10,
                        height: 26,
                        decoration: BoxDecoration(
                          color: CyclePhaseColors.ovulation,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1.2),
                        ),
                      ),
                    ),
                  // Today pin.
                  if (offsetInWindow != null)
                    Positioned(
                      left: _xFor(offsetInWindow, w) - 6,
                      top: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.6),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 26,
                            color: accent.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          // Compact day-axis labels.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AxisLabel(text: 'Day 1', fg: fg),
              _AxisLabel(text: 'Day 14', fg: fg),
              _AxisLabel(text: 'Day $_windowDays', fg: fg),
            ],
          ),
        ],
      ),
    );
  }

  /// X-pixel for a given cycle-day offset on a track of width [w].
  static double _xFor(int offset, double w) =>
      (offset.clamp(0, _windowDays).toDouble() / _windowDays) * w;
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final Color fg;
  const _AxisLabel({required this.text, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: fg.withValues(alpha: 0.45),
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
