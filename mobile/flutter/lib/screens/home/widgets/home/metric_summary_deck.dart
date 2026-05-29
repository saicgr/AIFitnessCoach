/// Direction C — the compact, swipeable metric summary that sits ABOVE the
/// AI Coach card on home.
///
/// Three pages: **Summary** (segmented Today ring + the first enabled metric
/// tiles) · **More** (the rest of the enabled tiles) · **Trends** (large chart
/// / custom-trend entry). Below the deck: a Log / Trends / Start action row.
/// Log opens the glassmorphic [showQuickLogSheet]; the AI Coach FAB is left
/// untouched (coach only).
///
/// Tiles read [metricValueProvider]; presentation per-metric comes from
/// [metricLayoutProvider]; which metrics + order come from the existing
/// [ringVisibilityProvider]. The ✎ button opens the existing customize sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/metric_value.dart';
import '../../../../data/models/today_score.dart';
import '../../../../data/providers/metric_layout_provider.dart';
import '../../../../data/providers/metric_value_provider.dart';
import '../../../../data/providers/saved_trends_provider.dart';
import '../../../../data/providers/today_score_provider.dart';
import '../../../../data/services/haptic_service.dart';
import 'metric_settings_sheet.dart';
import '../ring_catalog.dart';
import '../segmented_score_ring.dart';
import 'unified_home_widgets.dart' show kHomeHPad;

class MetricSummaryDeck extends ConsumerStatefulWidget {
  const MetricSummaryDeck({super.key});

  @override
  ConsumerState<MetricSummaryDeck> createState() => _MetricSummaryDeckState();
}

class _MetricSummaryDeckState extends ConsumerState<MetricSummaryDeck> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final visible = ref.watch(ringVisibilityProvider);

    // Summary = Today ring + first 4 enabled tiles. More = the remainder,
    // chunked into pages of 4 (2 rows) so no page overflows the deck height.
    final summaryTiles = visible.take(4).toList();
    final moreTiles = visible.length > 4 ? visible.sublist(4) : <RingKind>[];
    final moreChunks = <List<RingKind>>[];
    for (var i = 0; i < moreTiles.length; i += 4) {
      moreChunks.add(
        moreTiles.sublist(
          i,
          i + 4 > moreTiles.length ? moreTiles.length : i + 4,
        ),
      );
    }

    // Stable keys on every page so the PageView reconciles by identity, not
    // by position. The page COUNT changes one frame after first paint — the
    // ring list async-loads from prefs and may add the Recovery ring, flipping
    // pages from [Summary, Trends] to [Summary, More, Trends]. Without keys
    // that count/type change reparents render objects across page slots and
    // triggers the duplicate-GlobalKey / wrong-build-scope / "not in the same
    // render tree" / null-check cascade that blanked the workout & nutrition
    // tiles. Keying the children stops the whole cascade.
    final pages = <Widget>[
      KeyedSubtree(
        key: const ValueKey('deck_summary'),
        child: _summaryPage(c, summaryTiles),
      ),
      for (var ci = 0; ci < moreChunks.length; ci++)
        KeyedSubtree(
          key: ValueKey('deck_more_$ci'),
          child: _gridPage(c, moreChunks[ci]),
        ),
      KeyedSubtree(
        key: const ValueKey('deck_trends'),
        child: _trendsPage(c),
      ),
    ];
    final labels = <String>[
      'Summary',
      for (var i = 0; i < moreChunks.length; i++)
        moreChunks.length == 1 ? 'Metrics' : 'Metrics ${i + 1}',
      'Trends',
    ];

    // If the page count shrank below the parked page (e.g. a metric was hidden
    // so a "More" page vanished), clamp now and snap the controller next frame
    // so it can never sit on a page index that no longer exists.
    if (_page > pages.length - 1) _page = pages.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final last = pages.length - 1;
      if ((_controller.page ?? 0).round() > last) {
        _controller.jumpToPage(last);
      }
    });

    return Padding(
      padding: kHomeHPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(c, labels),
          const SizedBox(height: 8),
          SizedBox(
            height: 176,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          // The Log / Trends / Start action row was removed (issue 1): "Trends"
          // duplicated this deck's own Trends tab + every tile's tap-through,
          // "Start" duplicated the workout card's play button, and "Log"
          // duplicated the quick-actions "Log Food" chip + the nav "+". The
          // quick-actions row (its own home section) now carries those jobs.
        ],
      ),
    );
  }

  // ---- header: segmented tabs + dots + edit ----
  Widget _header(ThemeColors c, List<String> labels) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _page == i ? c.textPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _page == i ? c.background : c.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        // The page-indicator dots were removed: the labeled Summary / More /
        // Trends pills above already show the active page, so the dots were
        // redundant signal competing for the same glance (declutter, issue 4).
        // Customize button — labeled for a11y + a long-press tooltip so the
        // tune glyph reads as "Customize metrics", not an ambiguous icon.
        Tooltip(
          message: 'Customize metrics',
          child: Semantics(
            button: true,
            label: 'Customize metrics',
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                showMetricSettingsSheet(context, ref);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.cardBorder),
                ),
                child:
                    Icon(Icons.tune_rounded, size: 16, color: c.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Summary page: segmented ring + 4 tiles ----
  Widget _summaryPage(ThemeColors c, List<RingKind> tiles) {
    final score = ref.watch(todayScoreProvider);
    final segments = <ScoreRingSegment>[
      for (final kind in const [
        ContributorKind.train,
        ContributorKind.fuel,
        ContributorKind.move,
        ContributorKind.sleep,
      ])
        ScoreRingSegment(
          weight: kBaseContributorWeights[kind]!,
          completion: score.contributor(kind).applicable
              ? score.contributor(kind).completion
              : 0,
          color: _contributorColor(kind),
          trackColor: _contributorColor(kind).withValues(alpha: 0.18),
        ),
    ];

    return Container(
      decoration: _cardDecoration(c),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          SegmentedScoreRing(
            size: 118,
            strokeWidth: 11,
            segments: segments,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.score}',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                // Fixed tile HEIGHT (not aspect ratio): two rows then fit the
                // deck identically on every width (SE..Pro Max). Aspect-ratio
                // sizing made wide screens clip the bottom row (issue 3).
                mainAxisExtent: 62,
              ),
              children: [
                for (final kind in tiles)
                  MetricTile(
                    key: ValueKey('tile_${kind.id}'),
                    kind: kind,
                    compact: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- More page: size-aware row packing. Small tiles pair 2-per-row;
  // Wide/Large tiles take a full-width row (honoring the My Space size). ----
  Widget _gridPage(ThemeColors c, List<RingKind> tiles) {
    final layout = ref.watch(metricLayoutProvider.notifier);
    bool isFull(RingKind k) {
      final s = layout.configFor(k).size;
      return s == MetricSize.wide || s == MetricSize.large;
    }

    final rows = <Widget>[];
    var i = 0;
    while (i < tiles.length) {
      final a = tiles[i];
      if (isFull(a)) {
        rows.add(SizedBox(
          height: 66,
          child: MetricTile(key: ValueKey('tile_${a.id}'), kind: a),
        ));
        i += 1;
      } else if (i + 1 < tiles.length && !isFull(tiles[i + 1])) {
        final b = tiles[i + 1];
        rows.add(
          SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(child: MetricTile(key: ValueKey('tile_${a.id}'), kind: a)),
                const SizedBox(width: 9),
                Expanded(child: MetricTile(key: ValueKey('tile_${b.id}'), kind: b)),
              ],
            ),
          ),
        );
        i += 2;
      } else {
        rows.add(
          SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(child: MetricTile(key: ValueKey('tile_${a.id}'), kind: a)),
                const SizedBox(width: 9),
                const Spacer(),
              ],
            ),
          ),
        );
        i += 1;
      }
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 9),
            rows[r],
          ],
        ],
      ),
    );
  }

  // ---- Trends page: your saved custom trends + a build CTA ----
  Widget _trendsPage(ThemeColors c) {
    final saved = ref.watch(savedTrendsProvider).valueOrNull ?? const [];
    if (saved.isEmpty) return _trendsEmpty(c);

    return Container(
      decoration: _cardDecoration(c),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 16, color: c.accent),
              const SizedBox(width: 7),
              Text(
                'Your trends',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/trends/custom'),
                child: Text(
                  '+ New',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: saved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (_, i) {
                final t = saved[i];
                return GestureDetector(
                  onTap: () => context.push('/trends/custom', extra: t.primary),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded, size: 16, color: c.accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          t.range.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendsEmpty(ThemeColors c) {
    return GestureDetector(
      onTap: () => context.push('/trends/custom'),
      child: Container(
        decoration: _cardDecoration(c),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  'Custom trends',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plot any metrics together — weight vs sleep, calories vs '
              'steps — and let your coach spot the pattern.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Build a trend',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeColors c) => BoxDecoration(
    color: c.elevated,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.cardBorder),
  );

  Color _contributorColor(ContributorKind kind) {
    switch (kind) {
      case ContributorKind.train:
        return RingKind.train.color;
      case ContributorKind.fuel:
        return RingKind.nourish.color;
      case ContributorKind.move:
        return RingKind.move.color;
      case ContributorKind.sleep:
        return RingKind.sleep.color;
    }
  }
}

// ============================================================ MetricTile

/// A single light metric tile with a value + a graph overlay matching its
/// configured chart type. Tapping opens the metric's detail/trend.
class MetricTile extends ConsumerWidget {
  final RingKind kind;
  final bool compact;
  const MetricTile({super.key, required this.kind, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final m = ref.watch(metricValueProvider(kind));
    final cfg = ref.watch(metricLayoutProvider.notifier).configFor(kind);

    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Stack(
          children: [
            // graph overlay
            Positioned.fill(
              child: IgnorePointer(
                child: _Overlay(value: m, chart: cfg.chart),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          m.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 10 : 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Empty metric → an actionable CTA ("Connect" / "Log")
                  // instead of a bare "—" that reads as broken (issue 3).
                  if (m.isEmpty)
                    Row(
                      children: [
                        Icon(
                          _emptyCtaIsConnect(kind)
                              ? Icons.add_link_rounded
                              : Icons.add_rounded,
                          size: compact ? 13 : 15,
                          color: c.accent,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _emptyCtaLabel(kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13 : 14,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          m.headline,
                          style: TextStyle(
                            fontSize: compact ? 17 : 19,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: c.textPrimary,
                          ),
                        ),
                        if (m.unit.isNotEmpty) ...[
                          const SizedBox(width: 3),
                          Text(
                            m.unit,
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w700,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (!compact && m.deltaLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      m.deltaLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    // Trend-backed metrics open the custom-trend screen pre-seeded with that
    // metric; metrics without a trend series open the generic builder.
    final tm = trendMetricForRing(kind);
    context.push('/trends/custom', extra: tm);
  }

  /// Whether an empty metric's CTA should read "Connect" (needs a wearable /
  /// Health source) vs "Log" (the user can enter it manually). Used only for
  /// the zero-data tile state so an empty tile invites action instead of
  /// showing a bare dash.
  bool _emptyCtaIsConnect(RingKind kind) {
    switch (kind) {
      case RingKind.move:
      case RingKind.sleep:
      case RingKind.heartRate:
      case RingKind.recovery:
      case RingKind.hrv:
      case RingKind.stress:
        return true;
      case RingKind.nourish:
      case RingKind.hydration:
      case RingKind.weight:
      case RingKind.train:
      case RingKind.cycle:
        return false;
    }
  }

  String _emptyCtaLabel(RingKind kind) =>
      _emptyCtaIsConnect(kind) ? 'Connect' : 'Log';
}

/// Small inline metric visualisation (sparkline / bars / mini-ring / gauge)
/// for compact contexts like the "My Space → Metrics" rows. Mirrors the tile
/// overlay logic at a fixed small size.
class MetricRowViz extends ConsumerWidget {
  final RingKind kind;
  final double width;
  final double height;
  const MetricRowViz({
    super.key,
    required this.kind,
    this.width = 44,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(metricValueProvider(kind));
    final cfg = ref.watch(metricLayoutProvider.notifier).configFor(kind);
    if (m.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _DashPainter(ThemeColors.of(context).cardBorder),
        ),
      );
    }
    Widget paint;
    switch (cfg.chart) {
      case MetricChart.line:
      case MetricChart.area:
        final s = m.series;
        paint = (s != null && s.length >= 2)
            ? CustomPaint(
                painter: _SparkPainter(
                  s,
                  m.color,
                  fill: cfg.chart == MetricChart.area,
                ),
              )
            : _DashViz(m.color);
        break;
      case MetricChart.bars:
        paint = CustomPaint(painter: _BarsPainter(m.color));
        break;
      case MetricChart.ring:
        final pct = m.pct ?? 0;
        paint = CustomPaint(painter: _MiniRingPainter(pct, m.color));
        return SizedBox(width: height, height: height, child: paint);
      case MetricChart.number:
        paint = _DashViz(m.color);
        break;
    }
    return SizedBox(width: width, height: height, child: paint);
  }
}

class _DashViz extends StatelessWidget {
  final Color color;
  const _DashViz(this.color);
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashPainter(color.withValues(alpha: 0.4)));
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 3, y), p);
      x += 6;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Paints the faint graph overlay behind a tile's number.
class _Overlay extends StatelessWidget {
  final MetricValue value;
  final MetricChart chart;
  const _Overlay({required this.value, required this.chart});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    switch (chart) {
      case MetricChart.line:
      case MetricChart.area:
        final s = value.series;
        if (s == null || s.length < 2) return const SizedBox.shrink();
        return CustomPaint(
          painter: _SparkPainter(
            s,
            value.color,
            fill: chart == MetricChart.area,
          ),
        );
      case MetricChart.bars:
        return CustomPaint(painter: _BarsPainter(value.color));
      case MetricChart.ring:
        final pct = value.pct;
        if (pct == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(painter: _MiniRingPainter(pct, value.color)),
            ),
          ),
        );
      case MetricChart.number:
        return const SizedBox.shrink();
    }
  }
}

class _SparkPainter extends CustomPainter {
  final List<MetricSpark> pts;
  final Color color;
  final bool fill;
  _SparkPainter(this.pts, this.color, {this.fill = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in the bottom ~46% of the tile so it sits behind the number.
    final top = size.height * 0.54;
    final h = size.height - top;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = pts[i].x * size.width;
      final y = top + (1 - pts[i].y) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.14));
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.pts != pts || old.color != color || old.fill != fill;
}

class _BarsPainter extends CustomPainter {
  final Color color;
  _BarsPainter(this.color);
  static const _heights = [0.4, 0.75, 0.95, 0.6, 0.35];

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * 0.5;
    final h = size.height - top - 6;
    final paint = Paint()..color = color.withValues(alpha: 0.30);
    final n = _heights.length;
    final gap = 4.0;
    final bw = (size.width - 16 - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final bh = h * _heights[i];
      final x = 8 + i * (bw + gap);
      final r = RRect.fromLTRBR(
        x,
        size.height - 6 - bh,
        x + bw,
        size.height - 6,
        const Radius.circular(2),
      );
      canvas.drawRRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color;
}

class _MiniRingPainter extends CustomPainter {
  final double pct;
  final Color color;
  _MiniRingPainter(this.pct, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final arc = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5708,
      6.2832 * pct.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.pct != pct || old.color != color;
}
