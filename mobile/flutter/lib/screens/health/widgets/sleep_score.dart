import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Pure, unit-tested sleep-score computation + its display ring.
///
/// The score is 0-100, research-validated weighting (Sleep Foundation /
/// National Sleep Foundation duration recommendations + standard
/// efficiency/consistency literature). It is split into three components so
/// the breakdown can be shown to the user and each piece can be tested in
/// isolation:
///
///   * Duration   (max 50) — asleep minutes vs the user's sleep-duration
///                           goal. Hitting the goal scores full marks; a
///                           shortfall scales down linearly; a large
///                           over-shoot (>+90 min) is mildly penalised
///                           because oversleeping is itself a quality signal.
///   * Restfulness (max 25) — composition: efficiency (asleep / time-in-bed)
///                           plus a deep+REM stage bonus. When efficiency is
///                           unknown (partial data, case 7) this component
///                           falls back to the stage bonus alone, so the
///                           score is never faked from missing inputs.
///   * Consistency (max 25) — how close last night's mid-sleep time is to the
///                           recent average mid-sleep time. With no history
///                           (new user, case 25) this component is omitted
///                           and the score is renormalised over the two
///                           components that DO have data — never invented.
///
/// [computeSleepScore] returns null when there is not enough data to score
/// honestly (no asleep minutes at all) — the caller shows a "-" rather than
/// a fabricated number (no-mock-data rule).
class SleepScore {
  /// Total 0-100 score (renormalised over the components that have data).
  final int total;

  /// Component sub-scores on their own RAW max scales (see the `*Max`
  /// fields). These are independent of whether consistency was available —
  /// only [total] is renormalised.
  final double durationPoints; // out of [durationMax]
  final double restfulnessPoints; // out of [restfulnessMax]
  final double? consistencyPoints; // out of [consistencyMax]; null when no history

  /// The raw max of each component. [consistencyMax] is 0 when consistency
  /// was omitted (no history).
  final double durationMax;
  final double restfulnessMax;
  final double consistencyMax;

  const SleepScore({
    required this.total,
    required this.durationPoints,
    required this.restfulnessPoints,
    required this.consistencyPoints,
    required this.durationMax,
    required this.restfulnessMax,
    required this.consistencyMax,
  });

  /// Human label for the score band.
  String get label {
    if (total >= 85) return 'Excellent';
    if (total >= 70) return 'Good';
    if (total >= 50) return 'Fair';
    return 'Poor';
  }
}

/// Raw component weights before any renormalisation.
const double _kDurationWeight = 50;
const double _kRestfulnessWeight = 25;
const double _kConsistencyWeight = 25;

/// Compute a sleep score from one night's metrics.
///
/// * [asleepMinutes] — total minutes asleep that night (main sleep + naps).
/// * [goalMinutes] — the user's nightly sleep-duration goal (default 480).
/// * [efficiency] — asleep / time-in-bed, 0.0-1.0; null when unknown.
/// * [deepMinutes] / [remMinutes] — staged sleep; 0 when un-staged.
/// * [midSleepMinutesFromMidnight] — last night's mid-sleep clock time as
///   minutes from local midnight (e.g. a 23:00-07:00 night → mid-sleep 03:00
///   → 180). Null when bed/wake times are unknown.
/// * [avgMidSleepMinutesFromMidnight] — the recent-history average of the
///   same, or null when there is not enough history (new user).
///
/// Returns null when [asleepMinutes] <= 0 (nothing to score).
SleepScore? computeSleepScore({
  required int asleepMinutes,
  required int goalMinutes,
  double? efficiency,
  int deepMinutes = 0,
  int remMinutes = 0,
  int? midSleepMinutesFromMidnight,
  int? avgMidSleepMinutesFromMidnight,
}) {
  if (asleepMinutes <= 0) return null;
  final goal = goalMinutes > 0 ? goalMinutes : 480;

  // ── Duration (max 50) ────────────────────────────────────────────────
  // Full marks at goal; linear scale-down for a shortfall; mild penalty
  // for a large over-shoot (oversleeping is a quality signal too).
  double durationPoints;
  if (asleepMinutes >= goal) {
    final overshoot = asleepMinutes - goal;
    // No penalty up to +90 min; beyond that lose up to 20% of the weight.
    if (overshoot <= 90) {
      durationPoints = _kDurationWeight;
    } else {
      final excess = (overshoot - 90).clamp(0, 180);
      durationPoints =
          _kDurationWeight * (1.0 - 0.2 * (excess / 180));
    }
  } else {
    durationPoints = _kDurationWeight * (asleepMinutes / goal);
  }
  durationPoints = durationPoints.clamp(0.0, _kDurationWeight);

  // ── Restfulness (max 25) ─────────────────────────────────────────────
  // Efficiency contributes 16 of the 25; the deep+REM stage proportion
  // contributes the remaining 9. Healthy deep+REM is ~40-50% of sleep —
  // we award full stage marks at 45% and scale linearly below that.
  const double effShare = 16;
  const double stageShare = 9;

  double restfulnessPoints;
  final stageProp =
      asleepMinutes > 0 ? (deepMinutes + remMinutes) / asleepMinutes : 0.0;
  final stagePoints =
      (stageShare * (stageProp / 0.45)).clamp(0.0, stageShare);

  if (efficiency != null) {
    // Efficiency 85%+ is considered healthy; scale full marks at 0.95,
    // linear down to 0 at 0.50 (below which the night was very broken).
    final effNorm = ((efficiency - 0.50) / (0.95 - 0.50)).clamp(0.0, 1.0);
    restfulnessPoints = effShare * effNorm + stagePoints;
  } else {
    // No efficiency data (partial inputs, case 7) — fall back to the stage
    // bonus alone, scaled to the full restfulness weight so the component
    // is honestly bounded by what we actually know.
    restfulnessPoints =
        (_kRestfulnessWeight * (stageProp / 0.45)).clamp(0.0, _kRestfulnessWeight);
  }
  restfulnessPoints = restfulnessPoints.clamp(0.0, _kRestfulnessWeight);

  // ── Consistency (max 25) ─────────────────────────────────────────────
  // Distance of last night's mid-sleep from the recent average mid-sleep.
  // Within 30 min → full marks; linear to 0 at a 2.5h drift. Omitted when
  // there is no history to compare against (new user, case 25).
  double? consistencyPoints;
  if (midSleepMinutesFromMidnight != null &&
      avgMidSleepMinutesFromMidnight != null) {
    var drift =
        (midSleepMinutesFromMidnight - avgMidSleepMinutesFromMidnight).abs();
    // Mid-sleep wraps around the clock — a 23:50 vs 00:10 pair is 20 min
    // apart, not 1420. Fold any drift over 12h back across the boundary.
    if (drift > 720) drift = 1440 - drift;
    final norm = ((150 - (drift - 30)) / 150).clamp(0.0, 1.0);
    consistencyPoints = _kConsistencyWeight * norm;
  }

  // ── Renormalise the TOTAL over the components that have data ─────────
  // The component sub-scores stay on their raw scales; only `total` is
  // renormalised so a new user (no consistency) is scored fairly out of
  // the two components that DO have data.
  final double consMax =
      consistencyPoints != null ? _kConsistencyWeight : 0;
  final double rawMax = _kDurationWeight + _kRestfulnessWeight + consMax;
  final double rawPoints =
      durationPoints + restfulnessPoints + (consistencyPoints ?? 0);
  final int total = ((rawPoints / rawMax) * 100).round().clamp(0, 100);

  return SleepScore(
    total: total,
    durationPoints: durationPoints,
    restfulnessPoints: restfulnessPoints,
    consistencyPoints: consistencyPoints,
    durationMax: _kDurationWeight,
    restfulnessMax: _kRestfulnessWeight,
    consistencyMax: consMax,
  );
}

/// Color for a score band — green / lime / amber / red.
Color sleepScoreColor(int score) {
  if (score >= 85) return AppColors.success;
  if (score >= 70) return AppColors.teal;
  if (score >= 50) return AppColors.warning;
  return AppColors.error;
}

/// The Signature sleep-score frame: ONE deliberate violet progress arc beside
/// the time-asleep numeral + the three component scores as hairline Barlow
/// lines. Violet (`AppColors.macroProtein`) is the sleep family accent, used
/// once here — the arc.
class SleepScoreRing extends StatelessWidget {
  final SleepScore score;
  final bool isDark;

  /// Total minutes asleep — rendered as the big Anton "7:12" numeral beside
  /// the arc. Optional so older callers that only pass the score still work.
  final int? asleepMinutes;

  const SleepScoreRing({
    super.key,
    required this.score,
    required this.isDark,
    this.asleepMinutes,
  });

  static const Color _accent = AppColors.macroProtein; // violet — used once

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final track = isDark
        ? AppColors.hairlineStrong
        : Colors.black.withValues(alpha: 0.10);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── The one deliberate progress arc.
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _ArcPainter(
              fraction: score.total / 100,
              accent: _accent,
              track: track,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.total}',
                    style: ZType.disp(32, color: textPrimary, height: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.label.toUpperCase(),
                    style: ZType.lbl(9, color: _accent, letterSpacing: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // ── Time asleep numeral + component scores.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (asleepMinutes != null && asleepMinutes! > 0) ...[
                Text(
                  'TIME ASLEEP',
                  style: ZType.lbl(9, color: textMuted, letterSpacing: 1.8),
                ),
                const SizedBox(height: 2),
                Text(
                  '${asleepMinutes! ~/ 60}:'
                  '${(asleepMinutes! % 60).toString().padLeft(2, '0')}',
                  style: ZType.disp(34, color: textPrimary, height: 1.0),
                ),
                const SizedBox(height: 12),
              ],
              _bar('Duration', score.durationPoints, score.durationMax,
                  textMuted, textPrimary, track),
              const SizedBox(height: 7),
              _bar('Restfulness', score.restfulnessPoints,
                  score.restfulnessMax, textMuted, textPrimary, track),
              if (score.consistencyPoints != null) ...[
                const SizedBox(height: 7),
                _bar('Consistency', score.consistencyPoints!,
                    score.consistencyMax, textMuted, textPrimary, track),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(String label, double value, double max, Color labelColor,
      Color valueColor, Color track) {
    final frac = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: ZType.lbl(10, color: labelColor, letterSpacing: 1.2),
            ),
            Text(
              '${value.round()}/${max.round()}',
              style: ZType.data(10, color: valueColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 3,
            backgroundColor: track,
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
          ),
        ),
      ],
    );
  }
}

/// A single deliberate ~270° progress arc — the sleep score's only ring.
class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color accent;
  final Color track;

  _ArcPainter({
    required this.fraction,
    required this.accent,
    required this.track,
  });

  // Start at the bottom-left, sweep 270° clockwise (a gauge, not a full ring).
  static const double _start = math.pi * 0.75;
  static const double _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arcRect, _start, _sweep, false, trackPaint);

    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(arcRect, _start, _sweep * f, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.accent != accent || old.track != track;
}
