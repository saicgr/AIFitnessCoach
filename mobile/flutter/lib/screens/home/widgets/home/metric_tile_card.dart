/// One tile of the Home metric grid.
///
/// Three sizes, ONE grammar — tracked uppercase kicker, big Anton value, a
/// valence-coloured deviation line, an accent ↗ — and the chart treatment is a
/// property of the size, never a separate setting:
///
///  * **L** (full width) — full-bleed area chart. The curve is confined to the
///    lower ~60% of the tile and the text zone carries a surface-colour veil,
///    so the 56pt numeral wins no matter what shape the data takes that day.
///  * **M** (half width) — the same chart pinned to the lower third. Text and
///    chart zones are laid out as disjoint bands, so "the deviation line landed
///    on the steepest part of the curve" is impossible by construction.
///  * **S** (third width) — compressed spark or bar strip in the lower third;
///    the deviation shortens to a label ("Above baseline"), with the full
///    sentence one tap away on the metric's detail screen.
///
/// Chart chrome is unified: stroke 1.6, endpoint dot r=2, and a dashed 30-day
/// baseline **only where a deviation is actually claimed**. When the metric has
/// no data the tile keeps its exact footprint and grammar but draws **no chart
/// at all** — a flat line through one point is a fabricated shape — and names
/// the reason in a dashed capsule.
///
/// **These tiles define the card family on Home.** The two-up "Reports · Recap"
/// row that the tile grammar was originally cut from no longer mounts on Home
/// (Reports moved to Progress, Recap to You), so this file — not
/// `reports_recap_row.dart` — is the reference for the kicker / value /
/// sub-line / accent ↗ anatomy.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/stats/state_valence.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/metric_layout_provider.dart' show MetricSize;
import '../../../../data/providers/metric_tile_data_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Tile heights, from the mockup's 6-column grid.
///
/// [textScale] grows the tile with the reader's type size instead of clamping
/// their type back down: the grid is a section in a scroll view, so a taller
/// tile costs scroll, whereas a clamped tile costs someone their accessibility
/// setting. Capped at 2× because past that the whole page is scroll anyway.
double metricTileHeight(MetricSize size, {double textScale = 1}) {
  final base = switch (size) {
    MetricSize.large => 150.0,
    MetricSize.wide => 132.0,
    MetricSize.small => 100.0,
  };
  return base * textScale.clamp(1.0, 2.0);
}

/// [metricTileHeight] at the ambient text scale.
double metricTileHeightFor(BuildContext context, MetricSize size) =>
    metricTileHeight(size,
        textScale: MediaQuery.textScalerOf(context).scale(1));

/// Columns of the 6-wide grid a tile occupies.
int metricTileSpan(MetricSize size) => switch (size) {
      MetricSize.large => 6,
      MetricSize.wide => 3,
      MetricSize.small => 2,
    };

/// The user-facing size letter. `MetricSize.wide` predates the tile grid and
/// is persisted as `wide`; it reads as **M** everywhere a human sees it.
String metricSizeLetter(MetricSize size) => switch (size) {
      MetricSize.large => 'L',
      MetricSize.wide => 'M',
      MetricSize.small => 'S',
    };

/// Fraction of the tile height the chart band occupies, measured from the
/// bottom. L is full-bleed-with-veil (treatment A); M/S get the lower-third
/// band (treatment B).
///
/// The mockup's M band is 32%, but there the text is free to hang over the top
/// of the band; here the text zone is the band's exact complement (that
/// non-overlap is structural, not a hope), and a 32% band squeezes the second
/// line of the deviation sentence. 30% keeps the sentence whole AND lands the
/// drawn curve within a point of the mockup's, because
/// [metricTileChartPlotBand] confines the curve to the middle of its band.
double _chartBandFraction(MetricSize size) => switch (size) {
      MetricSize.large => 0.58,
      MetricSize.wide => 0.30,
      MetricSize.small => 0.30,
    };

/// Where the curve sits INSIDE its band, as fractions of the band height.
/// Public so the "quiet week reads quiet" geometry is testable.
/// The mockup's M/S paths ride y 22–40 of a 52-unit band (≈42–77%) rather than
/// filling it: a quiet week has to look quiet, so the plot area is deliberately
/// a calm slice of the band instead of its full extent. L keeps the wider
/// 44–88% because the hero's curve is the tile's only texture.
({double top, double bottom}) metricTileChartPlotBand(MetricSize size) =>
    size == MetricSize.large
        ? (top: 0.44, bottom: 0.88)
        : (top: 0.40, bottom: 0.78);

/// Padding is size-specific so the text zone provably fits its content inside
/// the band left over by [_chartBandFraction] — the "never overlap" guarantee
/// for M and S is arithmetic, not a hope.
EdgeInsets _tilePadding(MetricSize size) => switch (size) {
      MetricSize.large => const EdgeInsets.fromLTRB(12, 11, 12, 9),
      MetricSize.wide => const EdgeInsets.fromLTRB(12, 10, 12, 4),
      MetricSize.small => const EdgeInsets.fromLTRB(10, 8, 10, 4),
    };

/// The tile's empty-state line, localised.
///
/// Goes through [metricEmptyCopyFor] — the same table the provider used to
/// fill the English fallbacks — so the widget layer never grows a second
/// reason → copy switch that can drift from it. An id the catalogue no longer
/// knows has no reason at all; it keeps whatever the provider wrote.
({String long, String short, bool namesSource}) metricTileEmptyCopy(
  BuildContext context,
  MetricTileData data,
) {
  final l10n = AppLocalizations.of(context);
  final reason = data.emptyReason;
  if (reason == null) {
    return (
      long: data.noDataReason ?? l10n.metricTileNoData,
      short: data.noDataReasonShort ?? data.noDataReason ?? l10n.metricTileNoData,
      namesSource: data.noDataNamesSource,
    );
  }
  return metricEmptyCopyFor(
    data.id,
    reason,
    MetricEmptyCopy(
      noSourceConnectHealth: l10n.metricTileNoSourceConnectHealth,
      connectHealthShort: l10n.metricTileConnectHealthShort,
      noHealthDataYet: l10n.metricTileNoHealthDataYet,
      noDataYet: l10n.metricTileNoDataYet,
      nothingLoggedYet: l10n.metricTileNothingLoggedYet,
      nothingLoggedShort: l10n.metricTileNothingLoggedShort,
      noPlanYetFinishSetup: l10n.metricTileNoPlanYetFinishSetup,
      finishSetupShort: l10n.metricSetupPanelSetupCta,
      needsHrv: l10n.metricTileNeedsHrv,
    ),
  );
}

class MetricTileCard extends StatelessWidget {
  final MetricTileData data;
  final MetricSize size;

  /// Laid out by the grid, which owns the 6-column arithmetic.
  final double width;

  /// Edit mode: charts drop to half strength so structure reads over data.
  final bool chartRecedes;

  final VoidCallback? onTap;

  /// Long-press on a resting tile is what opens edit mode — the gesture the
  /// mockup uses, and the one users already expect from a tile grid.
  final VoidCallback? onLongPress;

  /// Replaces the deviation sub-line while editing ("Large · page 1 · #1").
  final String? placementLine;

  const MetricTileCard({
    super.key,
    required this.data,
    required this.size,
    required this.width,
    this.chartRecedes = false,
    this.onTap,
    this.onLongPress,
    this.placementLine,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final height = metricTileHeightFor(context, size);
    final isLarge = size == MetricSize.large;
    final hasChart = data.hasData && data.series.length >= 2;
    final bandFraction = _chartBandFraction(size);
    final plot = metricTileChartPlotBand(size);
    // Edit mode shows structure only: no reference line, no ↗ — the tile is
    // being arranged, not read.
    final baselineY =
        (data.claimsDeviation && !chartRecedes) ? data.baselineY : null;

    final body = Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (hasChart)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Treatment A paints the whole tile and relies on the veil;
            // treatment B is a band that the text zone never enters.
            height: isLarge ? height : height * bandFraction,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: data.usesBars
                    ? _TileBarsPainter(
                        series: data.series,
                        baselineY: baselineY,
                        accent: c.accent,
                        baselineColor: c.textMuted,
                        opacity: chartRecedes ? 0.45 : 1,
                      )
                    : _TileLinePainter(
                        series: data.series,
                        baselineY: baselineY,
                        accent: c.accent,
                        baselineColor: c.textMuted,
                        // On the hero the curve rides the lower 60% so the
                        // numeral above it stays on clean ground; M/S ride a
                        // calm slice of their band.
                        topFraction: plot.top,
                        bottomFraction: plot.bottom,
                        opacity: chartRecedes ? 0.45 : (isLarge ? 0.8 : 1),
                      ),
                size: Size.infinite,
              ),
            ),
          ),
        if (isLarge && hasChart)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -0.35),
                  end: const Alignment(1, 0.35),
                  stops: const [0.34, 0.70],
                  colors: [c.elevated, c.elevated.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        // The text zone. For M/S it is explicitly the complement of the chart
        // band, so the two can never overlap however long the copy runs.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: isLarge ? height : height * (1 - bandFraction),
          child: _TileBody(
            data: data,
            size: size,
            colors: c,
            placementLine: placementLine,
          ),
        ),
        // The tap-through ↗ is absent while editing: an edit tile carries the
        // S/M/L segment and the remove button, and must not also read as
        // tappable-through.
        if (data.hasData && size != MetricSize.small && !chartRecedes)
          Positioned(
            right: 9,
            bottom: 7,
            child: Icon(Icons.north_east_rounded, size: 13, color: c.accent),
          ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        label: '${data.label}. '
            '${data.hasData ? data.value : metricTileEmptyCopy(context, data).long}. '
            '${data.hasData ? data.deviationLabel : ''}',
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: data.hasData
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.elevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.cardBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: body,
                  ),
                )
              : CustomPaint(
                  painter: MetricTileDashedBorder(
                    color: c.cardBorder,
                    radius: 14,
                  ),
                  // Same fill as a live tile: the dashed border carries the
                  // WHOLE distinction. A second card colour in the same row
                  // reads as a rendering fault, not a degraded metric.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.elevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: body,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TileBody extends StatelessWidget {
  final MetricTileData data;
  final MetricSize size;
  final ThemeColors colors;
  final String? placementLine;

  const _TileBody({
    required this.data,
    required this.size,
    required this.colors,
    this.placementLine,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final isLarge = size == MetricSize.large;
    final isSmall = size == MetricSize.small;

    final kickerStyle = ZType.lbl(
      isLarge ? 10.5 : 9.5,
      color: isLarge ? c.accent : c.textMuted,
      letterSpacing: isLarge ? 2 : 1.8,
    );
    final valueSize = switch (size) {
      MetricSize.large => 56.0,
      MetricSize.wide => 26.0,
      MetricSize.small => 20.0,
    };
    final unitStyle = ZType.lbl(10, color: c.textMuted, letterSpacing: 1.5);

    return Padding(
      padding: _tilePadding(size),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kickerStyle,
          ),
          SizedBox(height: isLarge ? 6 : 5),
          // Shrink-to-fit, never truncate: an ellipsised numeral ("18…") is a
          // wrong number, and a wrong number is worse than a small one.
          _ShrinkToFit(child: _TileValue(
            value: data.hasData ? data.value : '—',
            unit: data.hasData ? data.unit : '',
            denominator: data.hasData ? data.valueDenominator : null,
            big: ZType.disp(
              valueSize,
              color: data.hasData ? c.textPrimary : c.textMuted,
              height: isLarge ? 0.92 : 1.0,
            ),
            small: unitStyle,
          )),
          if (!data.hasData) ...[
            const Spacer(),
            // A 100pt S tile ellipsises the long form into a truncated
            // non-sentence, so the short form is a real string, not a
            // `maxLines` hope.
            Builder(builder: (context) {
              final copy = metricTileEmptyCopy(context, data);
              return _NoSourceCapsule(
                text: isSmall ? copy.short : copy.long,
                namesSource: copy.namesSource,
                colors: c,
              );
            }),
          ] else if (data.scoreSegments.isNotEmpty && isLarge) ...[
            // The Today Score's own arithmetic, drawn where the chart used to
            // be reserved. On day one there is no series to plot — one
            // snapshot is not a line — so the tallest tile on Home used to
            // render a numeral above an empty band. The track fills it with
            // something true at every hour of every day: what today is worth,
            // and how much of it is banked.
            const Spacer(),
            _ScoreCapacityTrack(segments: data.scoreSegments, colors: c),
          ] else ...[
            SizedBox(height: isLarge ? 9 : 5),
            Flexible(
              child: placementLine != null
                  ? Text(
                      placementLine!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(
                        isLarge ? 10 : 9,
                        color: c.textMuted,
                        weight: FontWeight.w600,
                        letterSpacing: isLarge ? 1.5 : 1.1,
                      ),
                    )
                  // The valence ramp owns this line: colour is resolved from
                  // the metric's GoodDirection and the sign of the deviation
                  // together — never from "below == bad".
                  : DeviationLine(
                      valence: data.valence,
                      deviation: data.deviation,
                      epsilon: data.deviationEpsilon,
                      label: (isSmall
                              ? data.deviationLabelShort
                              : data.deviationLabel)
                          .toUpperCase(),
                      dotSize: 6,
                      maxLines: isSmall ? 1 : 2,
                      textStyle: ZType.lbl(
                        isLarge ? 10 : 9,
                        weight: FontWeight.w600,
                        letterSpacing: isLarge ? 1.5 : 1.1,
                      ).copyWith(height: 1.5),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Left-aligned shrink-to-fit. A long value at a large accessibility text
/// size scales down inside its tile rather than losing digits to an ellipsis.
class _ShrinkToFit extends StatelessWidget {
  final Widget child;

  const _ShrinkToFit({required this.child});

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: child,
        ),
      );
}

/// Renders "7h 12m" / "183.4 lb" / "68%" with the numerals in Anton and the
/// letters in the condensed label face, per the mockup's `<small>` runs.
class _TileValue extends StatelessWidget {
  final String value;
  final String unit;

  /// What the value is out of ("of 100"). Set on the Today Score, where the
  /// numeral is a share of a total the user can still reach — without it a 0
  /// reads as a verdict rather than a measurement.
  final String? denominator;
  final TextStyle big;
  final TextStyle small;

  const _TileValue({
    required this.value,
    required this.unit,
    required this.big,
    required this.small,
    this.denominator,
  });

  static final RegExp _run = RegExp(r'[0-9][0-9.,:]*|[^0-9]+');

  @override
  Widget build(BuildContext context) {
    // No digits at all ("—", "At goal") — it IS the value, so it keeps the
    // display face.
    if (!value.contains(RegExp(r'[0-9]'))) {
      return Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: big);
    }
    final spans = <InlineSpan>[];
    for (final m in _run.allMatches(value)) {
      final text = m.group(0)!;
      final numeric = text.codeUnitAt(0) >= 0x30 && text.codeUnitAt(0) <= 0x39;
      spans.add(TextSpan(
        text: numeric ? text : text.toUpperCase(),
        style: numeric ? big : small,
      ));
    }
    if (unit.isNotEmpty) {
      spans.add(TextSpan(text: unit.toUpperCase(), style: small));
    }
    if (denominator != null && denominator!.isNotEmpty) {
      spans.add(TextSpan(text: '  ${denominator!.toUpperCase()}', style: small));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: big,
    );
  }
}

/// The Today Score's earnable slices: an outlined segment per applicable
/// contributor, widths proportional to what each is worth today, filling with
/// accent as points are banked.
///
/// Outline-until-earned is the whole point. A filled grey bar reads as a
/// progress cliché and, at 0, as a failure; a hairline outline reads as
/// capacity — a day that has not been spent yet. The segments are the score's
/// real renormalised weights, so a Health-less account shows TRAIN / NOURISH
/// only and is never shown a slice it has no way to earn.
class _ScoreCapacityTrack extends StatelessWidget {
  final List<MetricScoreSegment> segments;
  final ThemeColors colors;

  const _ScoreCapacityTrack({required this.segments, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 9,
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  flex: segments[i].weight.clamp(1, 100),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: c.cardBorder),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: segments[i].fill.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 7),
        // The legend names what the widths mean. Without it the track is
        // decoration; with it the tile teaches the score's recipe using the
        // user's own weights, and no tutorial card is ever needed.
        Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: segments[i].fill > 0 ? c.accent : null,
                        border: segments[i].fill > 0
                            ? null
                            : Border.all(color: c.cardBorder),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${segments[i].label} ${segments[i].weight}'
                            .toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.lbl(
                          9.5,
                          color: c.textMuted,
                          weight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The dashed "why this tile is dark" capsule. Never a fabricated number.
///
/// A reason that names a source ("No source · connect Health", "Nothing logged
/// yet") carries a circled-i so the capsule reads as *tap to fix*; a short
/// reason that names a missing signal ("Needs HRV") stays text-only, exactly as
/// the mockup draws the two forms.
class _NoSourceCapsule extends StatelessWidget {
  final String text;
  final bool namesSource;
  final ThemeColors colors;

  const _NoSourceCapsule({
    required this.text,
    required this.namesSource,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MetricTileDashedBorder(color: colors.cardBorder, radius: 6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(namesSource ? 5 : 7, 3, 7, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (namesSource) ...[
              Icon(Icons.info_outline, size: 10, color: colors.textMuted),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.lbl(
                  9,
                  color: colors.textMuted,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── painters

/// Unified chart chrome: area gradient, stroke 1.6, endpoint dot r=2, and the
/// dashed 30-day baseline — drawn only when [baselineY] is non-null, i.e. only
/// where the tile actually claims a deviation.
class _TileLinePainter extends CustomPainter {
  final List<double> series;
  final double? baselineY;
  final Color accent;
  final Color baselineColor;

  /// Where series value 1.0 / 0.0 land, as fractions of the painted height.
  final double topFraction;
  final double bottomFraction;
  final double opacity;

  const _TileLinePainter({
    required this.series,
    required this.baselineY,
    required this.accent,
    required this.baselineColor,
    required this.topFraction,
    required this.bottomFraction,
    required this.opacity,
  });

  double _y(double v, double h) =>
      h * (bottomFraction - v * (bottomFraction - topFraction));

  @override
  void paint(Canvas canvas, Size size) {
    final n = series.length;
    if (n < 2 || size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    final dx = w / (n - 1);

    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(i * dx, _y(series[i], h)),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }

    // Area gradient hangs BELOW the line, always — never between line and
    // reference (treatment C, rejected: it double-encodes the deviation).
    final area = Path.from(line)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.20 * opacity),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, h * topFraction, w, h * (1 - topFraction))),
    );

    if (baselineY != null) {
      _dashedLine(
        canvas,
        Offset(0, _y(baselineY!, h)),
        Offset(w, _y(baselineY!, h)),
        Paint()
          ..color = baselineColor.withValues(alpha: 0.5 * opacity)
          ..strokeWidth = 1,
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accent.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      pts.last,
      2,
      Paint()..color = accent.withValues(alpha: opacity),
    );
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    var x = a.dx;
    while (x < b.dx) {
      canvas.drawLine(
        Offset(x, a.dy),
        Offset(math.min(x + dash, b.dx), b.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TileLinePainter old) =>
      !listEqualsDouble(old.series, series) ||
      old.baselineY != baselineY ||
      old.accent != accent ||
      old.opacity != opacity ||
      old.topFraction != topFraction ||
      old.bottomFraction != bottomFraction;
}

/// Daily totals that reset (water, protein) read as bars, not a curve.
class _TileBarsPainter extends CustomPainter {
  final List<double> series;
  final double? baselineY;
  final Color accent;
  final Color baselineColor;
  final double opacity;

  const _TileBarsPainter({
    required this.series,
    required this.baselineY,
    required this.accent,
    required this.baselineColor,
    required this.opacity,
  });

  double _barHeight(double v, double h) => math.max(2.0, h * (0.15 + 0.8 * v));

  @override
  void paint(Canvas canvas, Size size) {
    final n = series.length;
    if (n < 2 || size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    final slot = w / n;
    if (baselineY != null) {
      // Same rule as the line chart: a reference line exists only where a
      // deviation is claimed.
      final y = h - _barHeight(baselineY!.clamp(0.0, 1.0), h);
      final paint = Paint()
        ..color = baselineColor.withValues(alpha: 0.5 * opacity)
        ..strokeWidth = 1;
      for (var x = 0.0; x < w; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, w), y), paint);
      }
    }
    final barW = math.max(3.0, math.min(9.0, slot * 0.62));
    for (var i = 0; i < n; i++) {
      final barH = _barHeight(series[i].clamp(0.0, 1.0), h);
      final left = i * slot + (slot - barW) / 2;
      final isLast = i == n - 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, h - barH, barW, barH),
          const Radius.circular(2),
        ),
        Paint()
          ..color =
              accent.withValues(alpha: (isLast ? 0.85 : 0.30) * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_TileBarsPainter old) =>
      !listEqualsDouble(old.series, series) ||
      old.baselineY != baselineY ||
      old.accent != accent ||
      old.opacity != opacity;
}

/// A dashed rounded-rect border — the empty tile, the no-source capsule, the
/// drop placeholder and the Add slot all share this one stroke so a dashed
/// outline means the same thing everywhere in the grid.
class MetricTileDashedBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const MetricTileDashedBorder({
    required this.color,
    required this.radius,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(MetricTileDashedBorder old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

/// Cheap element-wise compare for the painters' `shouldRepaint`.
bool listEqualsDouble(List<double> a, List<double> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
