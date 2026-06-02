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

    // Summary = Today ring (col 1) + first 3 enabled tiles stacked in a single
    // column (col 2), Google-Health style. More = the remainder, chunked into
    // pages of 6 → a clean 3 rows × 2 columns grid per page.
    final summaryTiles = visible.take(3).toList();
    final moreTiles = visible.length > 3 ? visible.sublist(3) : <RingKind>[];
    final moreChunks = <List<RingKind>>[];
    for (var i = 0; i < moreTiles.length; i += 6) {
      moreChunks.add(
        moreTiles.sublist(
          i,
          i + 6 > moreTiles.length ? moreTiles.length : i + 6,
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
      child: SizedBox(
        // ALL pages share this one height so the deck reads at a constant size
        // as you swipe. Page 1 is a big ring-LEFT + a single vertical column of
        // 3 tiles on the RIGHT (Google-Health style); page 2 is a 3×2 grid.
        // Inner height = 240 − 12 top − 38 bottom (footer) = 190, which fits the
        // page-1 tile column (3×56 + 2×9 = 186) and the page-2 grid alike.
        height: 240,
        child: Stack(
          children: [
            // The cards fill the full height; their content centers, leaving a
            // bottom strip the indicator overlays so it reads as a card footer.
            Positioned.fill(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            // Dot indicator + customize gear, overlaid inside the card footer.
            // The row is a ~46px tall hit strip whose VISUAL content (small
            // dots + a borderless tune glyph) sits centered within it, so the
            // generous tap targets don't enlarge the footer's apparent height.
            Positioned(
              left: 16,
              right: 16,
              bottom: 8,
              child: _indicatorRow(c, pages.length),
            ),
          ],
        ),
      ),
    );
  }

  // ---- carousel dot indicator + customize gear (the card footer) ----
  //
  // Issue 3: the gear used to be a heavy 32px bordered circle that floated
  // over the content. It now reads as an intentional, lightweight part of the
  // card footer:
  //   • The gear is borderless (no circle / no surface fill) — just a muted
  //     tune glyph — so it sits quietly in the corner instead of stamping a
  //     button over the card.
  //   • Dots and gear share one baseline (the Row is height-bounded and both
  //     are vertically centered), with the dots optically centered via a
  //     leading spacer that matches the gear's footprint.
  //   • The gear keeps a ≥44px hit target (12px padding around a 16px glyph)
  //     even though the visual is small.
  //   • Single page → the dots are hidden entirely (nothing to page through),
  //     so the footer is just the gear in its corner.
  Widget _indicatorRow(ThemeColors c, int pageCount) {
    final showDots = pageCount > 1;
    // A fixed-height footer bar. A Stack guarantees the dots are TRULY centered
    // under the card (independent of the gear, which is pinned right) — the old
    // leading-spacer trick left them visibly off-centre. The gear is a small,
    // clearly-tappable circular button (soft fill, no hard border) so it reads
    // as an intentional control, not a stray glyph floating in the corner.
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showDots)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < pageCount; i++)
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _page == i ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? c.accent
                              : c.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: 'Customize metrics',
              child: Semantics(
                button: true,
                label: 'Customize metrics',
                child: GestureDetector(
                  onTap: () {
                    HapticService.light();
                    showMetricSettingsSheet(context, ref);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.textMuted.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

    // Big score ring on the LEFT (col 1); the metric tiles stacked in a SINGLE
    // column on the RIGHT (col 2 = N rows × 1 column), Google-Health style. The
    // row is vertically centered in the shared-height card so slides 2 & 3 read
    // at the exact same height. The ring already encodes all four pillars, so a
    // tighter 3-up stack reads cleaner than the old 2×2 grid; overflow metrics
    // (incl. Sleep when it's the 4th) live on the next swipe page.
    const double tileHeight = 56;
    const double tileGap = 9; // 3×56 + 2×9 = 186 ≤ 190 inner height
    return Container(
      decoration: _cardDecoration(c),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 38),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score ring (left). Tapping opens the stats breakdown (#15).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/stats'),
              child: SegmentedScoreRing(
                size: 116,
                strokeWidth: 11,
                segments: segments,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.score}',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Tiles stacked vertically (1 column) on the right — same compact
            // tile as page 2 so the shapes stay consistent across the deck.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: tileGap),
                    SizedBox(
                      height: tileHeight,
                      child: MetricTile(
                        key: ValueKey('tile_${tiles[i].id}'),
                        kind: tiles[i],
                        compact: true,
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

  // ---- More page: size-aware row packing.
  //
  // The deck pages every page after the Summary with up to 4 tiles. The goal
  // (issue 4) is a clean, FILLED 2×2 grid — no lonely single tile and no
  // awkward half-width Spacer when an even count is available. So:
  //   • Small (default) tiles pack 2-per-row.
  //   • A genuine odd tile (e.g. an odd metric count, or the trailing tile of
  //     an odd page) gets a FULL-WIDTH row rather than a half-row with an empty
  //     Spacer beside it — it reads as intentional, not broken.
  //   • Wide/Large tiles (My-Space size) always take a full-width row.
  // With the enriched default set the "More" page is exactly 4 small tiles →
  // a tidy 2×2.
  Widget _gridPage(ThemeColors c, List<RingKind> tiles) {
    // UNIFORM 2-column grid: every tile the same compact size, 2 per row, in a
    // clean 2xN grid. We intentionally ignore the My-Space wide/large size here
    // — those full-width rows belong to the full home grid, not the compact
    // deck, and were what made this page look "broken" (a 2-up row then two
    // lonely full-width tiles). The bottom inset leaves a clear strip for the
    // overlaid dots + gear footer so it never sits on a tile.
    // Same boxed card as the Summary + Trends pages (#6 — page 2 used to float
    // without a box). Bottom pad clears the overlaid dots + gear footer.
    return Container(
      decoration: _cardDecoration(c),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 38),
      child: Align(
        alignment: Alignment.topCenter,
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            // 56 so 3 rows (3×56 + 2×9 = 186) fit above the footer strip.
            mainAxisExtent: 56,
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
                  // Pass the FULL saved view (primary + overlays + range) so the
                  // builder restores the exact trend, not just the bare primary.
                  onTap: () => context.push('/trends/custom', extra: t),
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
    // Open the metric's OWN detail page (instant graph + history), NOT the
    // custom-trend builder (which made every tile feel slow + generic). Each
    // metric routes to its dedicated screen; nutrition metrics switch to the
    // Nutrition tab (a shell branch — use `go`, not `push`, so we don't stack
    // a second NutritionScreen and collide its static GlobalKeys).
    switch (kind) {
      case RingKind.nourish:
        context.go('/nutrition');
      case RingKind.hydration:
        context.go('/nutrition?tab=2');
      case RingKind.sleep:
        context.push('/health/sleep');
      case RingKind.move:
      case RingKind.activeEnergy:
      case RingKind.zoneMinutes:
        context.push('/neat');
      case RingKind.protein:
        context.go('/nutrition');
      case RingKind.recovery:
      case RingKind.heartRate:
      case RingKind.hrv:
      case RingKind.stress:
      case RingKind.vo2max:
      case RingKind.mindfulMinutes:
        // The Combined Health hub has per-metric history sections + graphs.
        context.push('/health/combined');
      case RingKind.sleepLatency:
      case RingKind.wakeConsistency:
      case RingKind.bedtimeWindow:
        // Sleep-derived metrics live on the Sleep detail screen.
        context.push('/health/sleep');
      case RingKind.weight:
        // Open the weight metric's OWN detail (graph + history) directly, not
        // the measurements LIST (issue #8 — tapping weight dumped you on the list).
        context.push('/measurements/weight');
      case RingKind.bodyFat:
        context.push('/measurements/bodyFat');
      case RingKind.stepStreak:
        context.push('/neat');
      case RingKind.cardioDistance:
        context.push('/stats');
      case RingKind.cycle:
        context.push('/cycle');
      case RingKind.train:
        context.push('/stats');
    }
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
      case RingKind.vo2max:
      case RingKind.sleepLatency:
      case RingKind.wakeConsistency:
      case RingKind.bedtimeWindow:
      case RingKind.activeEnergy:
      case RingKind.zoneMinutes:
      case RingKind.stepStreak:
      case RingKind.cardioDistance:
        return true;
      case RingKind.nourish:
      case RingKind.hydration:
      case RingKind.weight:
      case RingKind.train:
      case RingKind.cycle:
      case RingKind.protein:
      case RingKind.mindfulMinutes:
      case RingKind.bodyFat:
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
