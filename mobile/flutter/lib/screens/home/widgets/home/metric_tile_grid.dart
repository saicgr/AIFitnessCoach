/// The customisable metric tile grid that sits directly under the Home banner
/// stack — the section that replaced the four-cell hero-score strip.
///
/// Layout is a 6-column grid: **L** spans 6, **M** spans 3, **S** spans 2, and
/// tiles are packed into rows in the user's order ([packMetricTileRows]). The
/// packing is a pure function so a page's height is known before layout, which
/// is what lets the two pages live in a fixed-height [PageView] without a
/// measure pass.
///
/// Two pages, and only two. **Page 1 is the daily glance; page 2 is opt-in
/// depth.** Nothing is ever auto-assigned to page 2 — a tile is there because
/// someone dragged it there — so page 2 cannot rot into a dumping ground. It
/// follows that a default account has no page 2 and no [PageView] in its tree,
/// which is why **the dots render only inside the pager branch**: a dot is a
/// promise that a swipe exists, and drawing one over a plain Column promised a
/// gesture the widget tree could not perform. Page 2 is taught in edit mode,
/// by the drop strip that actually creates it.
///
/// **When every tile is dark the section stops repeating itself.** Emptiness
/// used to be decided per tile in isolation, so a fresh account rendered the
/// same "connect Health" instruction five times. [metricGridDarknessProvider]
/// aggregates it, and [MetricSetupPanel] absorbs the tiles that share one
/// action into one panel with one button — while tiles that carry real data
/// (water, weight: logged in-app, alive without a wearable) stay on the grid.
///
/// Edit mode ships in build one, not as a fast-follow: drag-to-reorder with a
/// live drop placeholder, per-tile remove, an S/M/L control on the focused
/// tile, and one Add slot where adding a metric IS enabling it. The same
/// editor widget is what My Space → Metrics renders, so there is exactly one
/// customiser rather than a second parallel one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_metric_tiles_provider.dart';
import '../../../../data/providers/metric_capability_provider.dart';
import '../../../../data/providers/metric_layout_provider.dart'
    show MetricSize;
import '../../../../data/providers/metric_tile_data_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../widgets/health_connect_sheet.dart';
import '../quick_log_sheet.dart' show showQuickLogSheet;
import '../ring_catalog.dart' show RingKindX;
import 'metric_tile_card.dart';
import 'unified_home_widgets.dart' show kHomeHPad;

/// Columns in the tile grid.
const int kMetricGridColumns = 6;

/// Gutter between tiles, both axes.
const double kMetricTileGap = 10;

/// Share of the grid width one page occupies when a second page exists.
///
/// The remainder is the peek. Page 1 stays FLUSH with the left edge of every
/// other Home card (`padEnds: false` — Flutter's default centres the page and
/// would inset the whole section by half the peek), and only page 2 bleeds past
/// the right edge: ≈22pt on a 390pt phone, the mockup's measurement.
const double kMetricPageViewportFraction = 0.94;

/// The page-dots row. Rendered **only alongside a mounted [PageView]** — one
/// dot per reachable page, never a dot for a page nothing can swipe to.
const Key kMetricTilePageDotsKey = ValueKey('metricTilePageDots');

/// Re-packs the tiles that survive a collapsed page into full rows.
///
/// Rows of at most three, sized by how many are in the row — 1 → L, 2 → M,
/// 3 → S — so two survivors read as a deliberate pair instead of two thirds of
/// a row with a hole where the absorbed tiles used to be. Reuses the three
/// existing sizes exactly: no new geometry, and [packMetricTileRows] lays the
/// result out unchanged.
///
/// Render-only. Nothing here is persisted; the user's stored sizes come back
/// untouched on the first build that does not collapse.
List<HomeMetricTile> repackMetricSurvivors(List<HomeMetricTile> survivors) {
  final out = <HomeMetricTile>[];
  for (var i = 0; i < survivors.length; i += 3) {
    final end = i + 3 > survivors.length ? survivors.length : i + 3;
    final size = switch (end - i) {
      1 => MetricSize.large,
      2 => MetricSize.wide,
      _ => MetricSize.small,
    };
    for (var j = i; j < end; j++) {
      out.add(survivors[j].copyWith(size: size));
    }
  }
  return out;
}

/// A preset's chip label in the reader's language. The preset table itself is
/// a code constant (it carries sizes and pages, not copy), so the label is
/// mapped by id here rather than duplicating the table into the bundles.
String metricTilePresetLabel(AppLocalizations l10n, MetricTilePreset p) =>
    switch (p.id) {
      'minimal' => l10n.metricGridPresetMinimal,
      'training_day' => l10n.metricGridPresetTrainingDay,
      'recovery' => l10n.metricGridPresetRecovery,
      _ => p.label,
    };

/// Packs [tiles] into rows of at most [kMetricGridColumns] columns, preserving
/// order. Pure — the grid, the page-height calculation and the tests all use
/// this one implementation.
List<List<HomeMetricTile>> packMetricTileRows(List<HomeMetricTile> tiles) {
  final rows = <List<HomeMetricTile>>[];
  var current = <HomeMetricTile>[];
  var used = 0;
  for (final t in tiles) {
    final span = metricTileSpan(t.size);
    if (used + span > kMetricGridColumns && current.isNotEmpty) {
      rows.add(current);
      current = <HomeMetricTile>[];
      used = 0;
    }
    current.add(t);
    used += span;
  }
  if (current.isNotEmpty) rows.add(current);
  return rows;
}

/// Height a packed page occupies, gaps included. [textScale] is threaded so
/// the pager reserves the same height the tiles will actually take.
double metricGridHeight(List<HomeMetricTile> tiles, {double textScale = 1}) {
  final rows = packMetricTileRows(tiles);
  if (rows.isEmpty) return 0;
  var h = 0.0;
  for (final row in rows) {
    var tallest = 0.0;
    for (final t in row) {
      final th = metricTileHeight(t.size, textScale: textScale);
      if (th > tallest) tallest = th;
    }
    h += tallest;
  }
  return h + kMetricTileGap * (rows.length - 1);
}

/// Pixel width of a tile spanning [size] inside a [available]-wide grid.
double metricTileWidth(MetricSize size, double available) {
  final col =
      (available - kMetricTileGap * (kMetricGridColumns - 1)) / kMetricGridColumns;
  final span = metricTileSpan(size);
  return col * span + kMetricTileGap * (span - 1);
}

// ══════════════════════════════════════════════════════ the Home section

class HomeMetricTileGrid extends ConsumerStatefulWidget {
  const HomeMetricTileGrid({super.key});

  @override
  ConsumerState<HomeMetricTileGrid> createState() => _HomeMetricTileGridState();
}

class _HomeMetricTileGridState extends ConsumerState<HomeMetricTileGrid> {
  final PageController _pager =
      PageController(viewportFraction: kMetricPageViewportFraction);
  int _page = 0;
  bool _editing = false;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    // Capability-filtered: the arrangement is what the user chose, this is
    // what their sources can fill. A tile they cannot fill is not rendered
    // empty — it is not rendered. See metric_capability_provider.dart.
    final tiles = ref.watch(mountedMetricTilesProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    // Every tile removed and not editing: collapse rather than leave a header
    // hovering over nothing (same call the strip made when Health was dark).
    if (tiles.isEmpty && !_editing) return const SizedBox.shrink();

    final pageOne = tilesOnPage(tiles, 1);
    final pageTwo = tilesOnPage(tiles, 2);

    // ── The first-run branch. This is the only place both _StaticGrid and
    // the connect card are reached from, so nothing can render one of them
    // around it.
    //
    // Editing never collapses: the editor exists to move and remove the real
    // tiles, and it cannot do that to tiles a panel has swallowed.
    // Rounds 4 and 5 collapsed a page of dark tiles into a setup panel. That
    // whole mechanism is gone: a tile only mounts if its source can produce a
    // number (metric_capability_provider.dart), so a page of dark tiles is no
    // longer a state the grid can reach. What used to be "four tiles that
    // cannot fill" is now four tiles that were never mounted, and the screen
    // keeps ONE shape instead of swapping into a panel.
    //
    // The darkness aggregate survives only to decide whether the connect card
    // is worth showing — never to restructure the grid.
    final dark1 = ref.watch(metricGridDarknessProvider(1));
    final dark2 =
        pageTwo.isEmpty ? null : ref.watch(metricGridDarknessProvider(2));
    const collapsed1 = false;
    const collapsed2 = false;

    // The connect affordance renders EXACTLY ONCE per grid, ever — but the
    // suppression keys off whether a panel is actually OFFERING it, not merely
    // on something having collapsed. A page that collapsed around "nothing
    // logged yet" says nothing about Health, and dropping the card there would
    // trade five copies of one instruction for zero.
    // Connect is offered by the coach's ranked to-do list, the pencil's
    // add-sheet and the Health tab — three surfaces, zero tiles. The card here
    // is the fallback for a user who has capable tiles but has since stopped
    // flowing data; it never advertises a metric they have no device for.
    final showConnect =
        !_editing && ref.watch(metricTilesNeedHealthConnectProvider);

    return Padding(
      padding: kHomeHPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(c, l10n),
          if (_editing) ...[
            const SizedBox(height: 2),
            Text(
              l10n.metricGridEditHint,
              style: ZType.lbl(
                10,
                color: c.textMuted,
                weight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            const MetricTileGridEditor(),
          ] else ...[
            const SizedBox(height: 10),
            if (pageTwo.isEmpty)
              _pageBody(pageOne, dark1, collapsed1)
            else ...[
              SizedBox(
                height: [
                  _pageHeight(pageOne, dark1, collapsed1, textScale),
                  _pageHeight(pageTwo, dark2!, collapsed2, textScale),
                ].reduce((a, b) => a > b ? a : b),
                child: PageView(
                  controller: _pager,
                  // Page 1 flush left, page 2 peeking — see
                  // [kMetricPageViewportFraction]. The peek is the viewport
                  // fraction alone; an extra per-page inset would shrink every
                  // page-1 tile and shift the section off the card grid.
                  padEnds: false,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    // Each page keeps its own top alignment: the pager box is
                    // the taller of the two, and a short page must not stretch
                    // to fill it.
                    Align(
                      alignment: Alignment.topCenter,
                      child: _pageBody(pageOne, dark1, collapsed1),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _pageBody(pageTwo, dark2, collapsed2),
                    ),
                  ],
                ),
              ),
              // Dots live INSIDE this branch, with the pager they describe.
              const SizedBox(height: 11),
              _PageDots(count: 2, active: _page, colors: c),
            ],
            // The mockup's band is 15 above the connect card.
            if (showConnect) ...[
              const SizedBox(height: 15),
              _ConnectHealthCard(colors: c),
            ],
          ],
        ],
      ),
    );
  }

  /// One page's content: the user's real layout, or — when that page has gone
  /// dark enough to stop meaning anything — the panel followed by whatever
  /// still carries data.
  Widget _pageBody(
    List<HomeMetricTile> tiles,
    MetricGridDarkness dark,
    bool collapsed,
  ) {
    if (!collapsed) {
      return _StaticGrid(tiles: tiles, onOpen: _open, onEdit: _startEditing);
    }
    final survivors = repackMetricSurvivors(dark.survivors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel first, then the survivors. A deliberate deviation from the
        // user's order, scoped to this state only — stored order and sizes are
        // untouched and return on the first build that does not collapse.
        MetricSetupPanel(darkness: dark, onOpen: _open),
        if (survivors.isNotEmpty) ...[
          const SizedBox(height: kMetricTileGap),
          _StaticGrid(tiles: survivors, onOpen: _open, onEdit: _startEditing),
        ],
      ],
    );
  }

  /// [_pageBody]'s height, known before layout — the property that lets the
  /// pager be a fixed-height box with no measure pass. [metricSetupPanelHeight]
  /// is a ceiling and every text inside the panel is line-capped to match, so
  /// the reservation can only ever be too generous, never too small.
  double _pageHeight(
    List<HomeMetricTile> tiles,
    MetricGridDarkness dark,
    bool collapsed,
    double textScale,
  ) {
    if (!collapsed) return metricGridHeight(tiles, textScale: textScale);
    final survivors = repackMetricSurvivors(dark.survivors);
    final grid = survivors.isEmpty
        ? 0.0
        : metricGridHeight(survivors, textScale: textScale) + kMetricTileGap;
    return metricSetupPanelHeight(dark, textScale: textScale) + grid;
  }

  Widget _header(ThemeColors c, AppLocalizations l10n) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editing swaps the section kicker for the mockup's masthead pair:
          // a display-face title and the reassurance that nothing here needs
          // saving — there is no Cancel, so the promise has to be stated.
          if (_editing)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.metricGridEditTiles,
                    style: ZType.disp(22, color: c.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.metricGridChangesSaveInstantly,
                    style: ZType.lbl(
                      10,
                      color: c.textMuted,
                      weight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              // Uppercased here rather than in the bundles, like every other
              // tracked label on this screen (`data.label.toUpperCase()` in
              // the tile body). The retired `metricGridMyMetrics` shouted from
              // inside the .arb, which left each translator to decide the
              // casing and produced a header that was uppercase in some
              // languages and not others.
              l10n.metricGridToday.toUpperCase(),
              style: ZType.lbl(10.5, color: c.textMuted, letterSpacing: 2),
            ),
            const Spacer(),
          ],
          const SizedBox(width: 10),
          if (_editing)
            GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _editing = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.metricGridDone,
                  style: ZType.lbl(12, color: c.accentContrast, letterSpacing: 1.8),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _startEditing,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.cardBorder),
                  color: c.surface,
                ),
                child: Icon(Icons.edit_outlined, size: 13, color: c.textSecondary),
              ),
            ),
        ],
      );

  void _startEditing() {
    if (_editing) return;
    HapticService.medium();
    setState(() => _editing = true);
  }

  void _open(String route) {
    HapticService.light();
    try {
      context.push(route);
    } catch (_) {
      // Route not registered in this build flavor — no-op, never a crash.
    }
  }
}

/// The read-only grid: rows of tiles, each tapping through to its metric.
class _StaticGrid extends ConsumerWidget {
  final List<HomeMetricTile> tiles;
  final ValueChanged<String> onOpen;
  final VoidCallback onEdit;

  const _StaticGrid({
    required this.tiles,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = packMetricTileRows(tiles);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: kMetricTileGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) const SizedBox(width: kMetricTileGap),
                    _LiveTile(
                      tile: rows[r][i],
                      width:
                          metricTileWidth(rows[r][i].size, constraints.maxWidth),
                      onOpen: onOpen,
                      onEdit: onEdit,
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LiveTile extends ConsumerWidget {
  final HomeMetricTile tile;
  final double width;
  final ValueChanged<String> onOpen;
  final VoidCallback onEdit;

  const _LiveTile({
    required this.tile,
    required this.width,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(metricTileDataProvider(tile.id));
    return RepaintBoundary(
      child: MetricTileCard(
        data: data,
        size: tile.size,
        width: width,
        onTap: () => onOpen(data.route),
        onLongPress: onEdit,
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int active;
  final ThemeColors colors;

  const _PageDots({
    required this.count,
    required this.active,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Row(
        key: kMetricTilePageDotsKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: i == active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == active
                    ? colors.accent.withValues(alpha: 0.6)
                    : colors.textMuted.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      );
}

// ═══════════════════════════════════════════════ the first-run panel

// Panel geometry. These are named because [metricSetupPanelHeight] must be the
// exact arithmetic of what [MetricSetupPanel.build] lays out — the pager needs
// the height before layout, and a guessed number would either clip the panel or
// leave a hole under it. Every value is a CEILING for its slot, and every text
// in the panel is line-capped to match, so the reservation cannot come up short.
const double _kPanelPad = 14;
/// The `Border.all` stroke, which a `BoxDecoration` adds INSIDE the box on
/// every edge — 2pt of height the padding arithmetic would otherwise miss.
const double _kPanelBorder = 1;
const double _kPanelKickerH = 14;
const double _kPanelKickerGap = 7;
const double _kPanelTitleH = 24;
const double _kPanelTitleGap = 12;
const double _kPanelChipsH = 22;
const double _kPanelChipsGap = 7;
const double _kPanelBodyLineH = 16;
const int _kPanelBodyLines = 2;
const double _kPanelCtaGap = 9;
const double _kPanelPrimaryCtaH = 35;
const double _kPanelLinkH = 16;
const double _kPanelSepGap = 12;
const double _kPanelHairline = 1;
const double _kPanelFooterGap = 12;
const double _kPanelFooterTopGap = 11;
const double _kPanelFooterH = 14;

/// Height [MetricSetupPanel] occupies for [dark], gaps and padding included.
double metricSetupPanelHeight(MetricGridDarkness dark, {double textScale = 1}) {
  final groups = dark.darkByAction.keys.toList();
  if (groups.isEmpty) return 0;
  final primary = dark.primaryAction;
  var h = _kPanelKickerH + _kPanelKickerGap + _kPanelTitleH + _kPanelTitleGap;
  for (var i = 0; i < groups.length; i++) {
    if (i > 0) h += _kPanelSepGap + _kPanelHairline + _kPanelSepGap;
    h += _kPanelChipsH +
        _kPanelChipsGap +
        _kPanelBodyLineH * _kPanelBodyLines +
        _kPanelCtaGap +
        (groups[i] == primary ? _kPanelPrimaryCtaH : _kPanelLinkH);
  }
  h += _kPanelFooterGap + _kPanelHairline + _kPanelFooterTopGap + _kPanelFooterH;
  return h * textScale.clamp(1.0, 2.0) +
      _kPanelPad * 2 +
      _kPanelBorder * 2;
}

/// The consolidated first-run state: one panel that says how many metrics are
/// waiting, which ones, and the single thing that turns each group on.
///
/// It replaces the tiles it absorbs — and ONLY those. A tile with real data is
/// never swept in here, because "connect Health" is not what a manually logged
/// water total is waiting for, and a tile whose reason has no CTA
/// ([MetricEmptyAction.none]) is not either: it already names the one signal it
/// is missing, which is more than this panel could say for it.
class MetricSetupPanel extends ConsumerWidget {
  final MetricGridDarkness darkness;
  final ValueChanged<String> onOpen;

  const MetricSetupPanel({
    super.key,
    required this.darkness,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final groups = darkness.darkByAction.entries.toList();
    if (groups.isEmpty) return const SizedBox.shrink();
    final primary = darkness.primaryAction;
    final source = _healthSourceName(context);

    return Container(
      padding: const EdgeInsets.all(_kPanelPad),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _kPanelKickerH,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 12, color: c.accent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    // The real count, not a rounded reassurance.
                    l10n.metricSetupPanelKicker(darkness.actionableDarkCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        ZType.lbl(10.5, color: c.accent, letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _kPanelKickerGap),
          SizedBox(
            height: _kPanelTitleH,
            child: Text(
              l10n.metricSetupPanelTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: _kPanelTitleGap),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: _kPanelSepGap),
              Container(height: _kPanelHairline, color: c.hairline),
              const SizedBox(height: _kPanelSepGap),
            ],
            _group(
              context: context,
              ref: ref,
              colors: c,
              action: groups[i].key,
              tiles: groups[i].value,
              isPrimary: groups[i].key == primary,
              source: source,
              l10n: l10n,
            ),
          ],
          const SizedBox(height: _kPanelFooterGap),
          Container(height: _kPanelHairline, color: c.hairline),
          const SizedBox(height: _kPanelFooterTopGap),
          SizedBox(
            height: _kPanelFooterH,
            child: Text(
              // The promise the whole empty-state grammar rests on.
              l10n.metricSetupPanelFooter,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors colors,
    required MetricEmptyAction action,
    required List<MetricTileData> tiles,
    required bool isPrimary,
    required String source,
    required AppLocalizations l10n,
  }) {
    final body = switch (action) {
      MetricEmptyAction.connectHealth =>
        l10n.metricSetupPanelHealthBody(source),
      MetricEmptyAction.logInApp => l10n.metricSetupPanelLogBody,
      MetricEmptyAction.finishSetup => l10n.metricSetupPanelSetupBody,
      MetricEmptyAction.none => '',
    };
    final cta = switch (action) {
      MetricEmptyAction.connectHealth =>
        l10n.metricSetupPanelHealthCta(source),
      MetricEmptyAction.logInApp => l10n.metricSetupPanelLogCta,
      MetricEmptyAction.finishSetup => l10n.metricSetupPanelSetupCta,
      MetricEmptyAction.none => '',
    };

    void act() {
      HapticService.selection();
      switch (action) {
        case MetricEmptyAction.connectHealth:
          showHealthConnectSheet(context, ref);
        case MetricEmptyAction.logInApp:
          showQuickLogSheet(context, ref);
        case MetricEmptyAction.finishSetup:
          // The first absorbed tile's own destination — the screen that
          // actually unblocks it, not a generic settings hub.
          onOpen(tiles.first.route);
        case MetricEmptyAction.none:
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kPanelChipsH,
          child: Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                // Loose flex, never a scroll view: a horizontal scrollable
                // inside the pager would eat the page swipe. Four chips share
                // the width and ellipsise instead.
                Flexible(
                  child: _chip(colors, tiles[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: _kPanelChipsGap),
        SizedBox(
          height: _kPanelBodyLineH * _kPanelBodyLines,
          child: Text(
            body,
            maxLines: _kPanelBodyLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: _kPanelCtaGap),
        Semantics(
          button: true,
          label: cta,
          child: GestureDetector(
            onTap: act,
            behavior: HitTestBehavior.opaque,
            child: isPrimary
                ? _primaryCta(colors, cta)
                : _linkCta(colors, cta),
          ),
        ),
      ],
    );
  }

  /// One absorbed tile, named. Inert on purpose — it is a receipt for a tile
  /// that is no longer on screen, not a second tap target competing with the
  /// one button the group is offering.
  Widget _chip(ThemeColors c, MetricTileData data) => CustomPaint(
        painter: MetricTileDashedBorder(color: c.cardBorder, radius: 7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metricTileGlyph(data.id), size: 10, color: c.textMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  data.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(
                    9.5,
                    color: c.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _primaryCta(ThemeColors c, String label) => Container(
        height: _kPanelPrimaryCtaH,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.lbl(
                  12.5,
                  color: c.accentContrast,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.arrow_forward_rounded, size: 13, color: c.accentContrast),
          ],
        ),
      );

  Widget _linkCta(ThemeColors c, String label) => SizedBox(
        height: _kPanelLinkH,
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.lbl(11, color: c.accent, letterSpacing: 1.5),
              ),
            ),
            Icon(Icons.chevron_right, size: 11, color: c.accent),
            const Spacer(),
          ],
        ),
      );
}

/// The 10pt glyph a metric wears on its panel chip. A UI concern, so it lives
/// with the UI: the tile catalogue is a data table and does not carry icons.
IconData metricTileGlyph(String tileId) => switch (tileId) {
      kTodayScoreTileId => Icons.bolt_rounded,
      'move' => Icons.directions_walk_rounded,
      'sleep' || 'sleep_latency' || 'wake_consistency' || 'bedtime_window' =>
        Icons.bedtime_rounded,
      'recovery' => Icons.battery_charging_full_rounded,
      'hrv' || 'heart_rate' => Icons.favorite_rounded,
      'stress' => Icons.psychology_rounded,
      'hydration' => Icons.water_drop_rounded,
      'weight' || 'body_fat' => Icons.monitor_weight_rounded,
      'nourish' || 'protein' => Icons.restaurant_rounded,
      'train' => Icons.fitness_center_rounded,
      'active_energy' => Icons.local_fire_department_rounded,
      'zone_minutes' || 'vo2max' || 'cardio_distance' =>
        Icons.monitor_heart_rounded,
      'mindful_minutes' => Icons.self_improvement_rounded,
      'step_streak' => Icons.local_fire_department_rounded,
      'cycle' => Icons.calendar_month_rounded,
      _ => Icons.insights_rounded,
    };

// ══════════════════════════════════════════════════════════ edit mode

/// Drag-to-reorder, resize, remove and add — the whole customiser, in one
/// widget so Home's in-place edit mode and My Space → Metrics are the same
/// surface editing the same store.
class MetricTileGridEditor extends ConsumerStatefulWidget {
  const MetricTileGridEditor({super.key});

  @override
  ConsumerState<MetricTileGridEditor> createState() =>
      _MetricTileGridEditorState();
}

class _MetricTileGridEditorState extends ConsumerState<MetricTileGridEditor> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tiles = ref.watch(homeMetricTilesProvider);
    final pageOne = tilesOnPage(tiles, 1);
    final pageTwo = tilesOnPage(tiles, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page 1 needs no chip while it is the only populated page — a label
        // over the only grid on screen is chrome explaining itself.
        if (pageTwo.isNotEmpty) ...[
          _pageLabel(c, l10n.metricGridPageOneLabel),
          const SizedBox(height: 8),
        ],
        _EditableGrid(
          tiles: pageOne,
          page: 1,
          selected: _selected,
          onSelect: _select,
          colors: c,
        ),
        const SizedBox(height: 12),
        _AddMetricSlot(colors: c, onTap: () => _openAddSheet(context)),
        const SizedBox(height: 14),
        // An empty page 2 collapses to one dashed strip rather than a second
        // full-height drop zone: edit mode must not be taller than the grid it
        // is editing.
        if (pageTwo.isEmpty)
          _PageTwoStrip(colors: c)
        else ...[
          _pageLabel(c, l10n.metricGridPageTwoLabel),
          const SizedBox(height: 8),
          _EditableGrid(
            tiles: pageTwo,
            page: 2,
            selected: _selected,
            onSelect: _select,
            colors: c,
          ),
        ],
        const SizedBox(height: 14),
        _PresetsRow(colors: c),
      ],
    );
  }

  void _select(String id) {
    HapticService.selection();
    setState(() => _selected = _selected == id ? null : id);
  }

  Widget _pageLabel(ThemeColors c, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: c.cardBorder),
          ),
          child: Text(
            text,
            style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.8),
          ),
        ),
      );

  Future<void> _openAddSheet(BuildContext context) async {
    HapticService.light();
    await showGlassSheet<void>(
      context: context,
      builder: (_) => const GlassSheet(child: AddMetricTileSheet()),
    );
  }
}

class _EditableGrid extends ConsumerWidget {
  final List<HomeMetricTile> tiles;
  final int page;
  final String? selected;
  final ValueChanged<String> onSelect;
  final ThemeColors colors;

  const _EditableGrid({
    required this.tiles,
    required this.page,
    required this.selected,
    required this.onSelect,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(homeMetricTilesProvider.notifier);

    // Whole-page drop target: dropping in the gutter moves the tile to the end
    // of this page, which is how a tile crosses between pages.
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        HapticService.light();
        notifier.moveTo(details.data, page: page);
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        if (tiles.isEmpty) {
          return _EmptyPageZone(
            colors: colors,
            highlight: highlight,
            label: AppLocalizations.of(context).metricGridDragBackToPage(page),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final rows = packMetricTileRows(tiles);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: highlight
                    ? colors.accent.withValues(alpha: 0.06)
                    : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < rows.length; r++) ...[
                    if (r > 0) const SizedBox(height: kMetricTileGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < rows[r].length; i++) ...[
                          if (i > 0) const SizedBox(width: kMetricTileGap),
                          _EditableTile(
                            tile: rows[r][i],
                            width: metricTileWidth(
                                rows[r][i].size, constraints.maxWidth),
                            selected: selected == rows[r][i].id,
                            onSelect: onSelect,
                            colors: colors,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EditableTile extends ConsumerWidget {
  final HomeMetricTile tile;
  final double width;
  final bool selected;
  final ValueChanged<String> onSelect;
  final ThemeColors colors;

  const _EditableTile({
    required this.tile,
    required this.width,
    required this.selected,
    required this.onSelect,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final data = ref.watch(metricTileDataProvider(tile.id));
    final notifier = ref.read(homeMetricTilesProvider.notifier);
    // Position within its OWN page — "#4 on page 2" is what the user sees,
    // not an index into a flat list they never look at.
    final position =
        tilesOnPage(ref.watch(homeMetricTilesProvider), tile.page)
            .indexWhere((t) => t.id == tile.id);

    final card = MetricTileCard(
      data: data,
      size: tile.size,
      width: width,
      chartRecedes: true,
      placementLine: AppLocalizations.of(context).metricGridPlacementLine(
        metricSizeLetter(tile.size),
        tile.page,
        position + 1,
      ),
    );

    final decorated = Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Tiles lift while editing so structure reads over data. The
            // shadow follows the theme's ladder — a dark-mode alpha dropped
            // onto a light background reads as soot.
            boxShadow: [
              BoxShadow(
                color: (c.isDark ? Colors.black : const Color(0xFF111827))
                    .withValues(alpha: c.isDark ? 0.28 : 0.14),
                blurRadius: c.isDark ? 16 : 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: card,
        ),
        Positioned(
          top: 7,
          right: 32,
          child: Icon(Icons.drag_indicator, size: 13, color: c.textMuted),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              notifier.remove(tile.id);
            },
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
              child: const Icon(Icons.remove, size: 13, color: Colors.white),
            ),
          ),
        ),
        if (selected)
          Positioned(
            left: 0,
            right: 0,
            bottom: 7,
            child: Center(
              // A three-chip segment is wider than an S tile on a 320pt
              // phone; scale it down rather than overflow the row.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _SizeSegment(
                  current: tile.size,
                  colors: c,
                  onPick: (s) {
                    HapticService.light();
                    notifier.setSize(tile.id, s);
                  },
                ),
              ),
            ),
          ),
      ],
    );

    // Long-press to lift, not drag-to-lift: Home is a scroll view, and an
    // immediate Draggable would swallow every vertical drag that starts on a
    // tile. The delay is short so the gesture still feels like "grab it".
    return LongPressDraggable<String>(
      data: tile.id,
      delay: const Duration(milliseconds: 200),
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.rotate(
        angle: -0.052, // the mockup's 3° lift
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.95,
            child: MetricTileCard(
              data: data,
              size: tile.size,
              width: width,
              chartRecedes: true,
              placementLine: AppLocalizations.of(context).metricGridDragging,
            ),
          ),
        ),
      ),
      childWhenDragging: _DropPlaceholder(
        width: width,
        height: metricTileHeightFor(context, tile.size),
        colors: c,
      ),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != tile.id,
        onAcceptWithDetails: (details) {
          HapticService.light();
          notifier.moveTo(details.data, targetId: tile.id);
        },
        builder: (context, candidate, _) => Opacity(
          opacity: candidate.isEmpty ? 1 : 0.55,
          child: GestureDetector(
            onTap: () => onSelect(tile.id),
            behavior: HitTestBehavior.opaque,
            child: decorated,
          ),
        ),
      ),
    );
  }
}

class _DropPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final ThemeColors colors;

  const _DropPlaceholder({
    required this.width,
    required this.height,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        // Dashed, like every other placeholder in the grid — a solid accent
        // outline would read as a filled tile mid-drag, not a target.
        painter: MetricTileDashedBorder(
          color: colors.accent,
          radius: 14,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colors.accent.withValues(alpha: 0.14),
          ),
          child: Text(
            AppLocalizations.of(context).metricGridDropHere,
            style: ZType.lbl(9.5, color: colors.accent, letterSpacing: 1.8),
          ),
        ),
      );
}

/// The collapsed page-2 editor: one dashed strip that is also the drop target
/// for moving a tile across. No second grid, no second header — page 2 gets
/// space on screen when it has content, and a sentence when it does not.
class _PageTwoStrip extends ConsumerWidget {
  final ThemeColors colors;

  const _PageTwoStrip({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(homeMetricTilesProvider.notifier);
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        HapticService.light();
        notifier.moveTo(details.data, page: 2);
      },
      builder: (context, candidate, _) {
        final hot = candidate.isNotEmpty;
        return Opacity(
          opacity: hot ? 1 : 0.55,
          child: CustomPaint(
            painter: MetricTileDashedBorder(
              color: hot ? colors.accent : colors.cardBorder,
              radius: 14,
              strokeWidth: hot ? 1.5 : 1,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).metricGridPageTwoDragHint,
                maxLines: 2,
                style: ZType.lbl(
                  9.5,
                  color: hot ? colors.accent : colors.textMuted,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Named layouts under the Add slot. A preset carries sizes and page
/// assignment, not just a list of metrics, so tapping one never silently
/// flattens the arrangement the user built.
class _PresetsRow extends ConsumerWidget {
  final ThemeColors colors;

  const _PresetsRow({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeMetricTilePresetProvider);
    final notifier = ref.read(homeMetricTilesProvider.notifier);
    // "My layout" is the dirty state. It is offered as a destination only when
    // there is something to go back to — a chip that does nothing is worse
    // than no chip.
    final showMine = active == null || notifier.hasLayoutBeforePreset;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.metricGridPresets,
          style: ZType.lbl(9.5, color: colors.textMuted, letterSpacing: 2),
        ),
        if (showMine)
          _PresetChip(
            label: l10n.metricGridPresetMyLayout,
            active: active == null,
            colors: colors,
            onTap: active == null
                ? null
                : () {
                    HapticService.light();
                    notifier.restoreLayoutBeforePreset();
                  },
          ),
        for (final preset in kMetricTilePresets)
          _PresetChip(
            label: metricTilePresetLabel(l10n, preset),
            active: active?.id == preset.id,
            colors: colors,
            onTap: () {
              HapticService.medium();
              notifier.applyPreset(preset);
            },
          ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final ThemeColors colors;
  final VoidCallback? onTap;

  const _PresetChip({
    required this.label,
    required this.active,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? colors.accent : colors.cardBorder,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: ZType.lbl(
              9.5,
              color: active ? colors.accent : colors.textSecondary,
              letterSpacing: 1.6,
            ),
          ),
        ),
      );
}

/// The one recovery path for a grid whose sensor tiles are dark. It promises
/// exactly what connecting does and nothing else — no estimated numbers appear
/// anywhere as a consolation.
class _ConnectHealthCard extends ConsumerWidget {
  final ThemeColors colors;

  const _ConnectHealthCard({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        showHealthConnectSheet(context, ref);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              // Platform-aware: an Android user told to connect "Apple Health"
              // has been handed an impossible instruction. Mirrors
              // `_platformSourceName` in combined_health_screen.dart and the
              // "Apple Health / Health Connect" phrasing in today_score_card.
              AppLocalizations.of(context)
                  .metricSetupPanelHealthCta(_healthSourceName(context)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              AppLocalizations.of(context).metricGridConnectBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppLocalizations.of(context).metricGridConnectCta,
                style: ZType.lbl(12, color: c.accentContrast, letterSpacing: 1.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPageZone extends StatelessWidget {
  final ThemeColors colors;
  final bool highlight;
  final String label;

  const _EmptyPageZone({
    required this.colors,
    required this.highlight,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: highlight
              ? colors.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color: highlight ? colors.accent : colors.cardBorder,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: ZType.lbl(
            9.5,
            color: highlight ? colors.accent : colors.textMuted,
            letterSpacing: 1.8,
          ),
        ),
      );
}

class _SizeSegment extends StatelessWidget {
  final MetricSize current;
  final ThemeColors colors;
  final ValueChanged<MetricSize> onPick;

  const _SizeSegment({
    required this.current,
    required this.colors,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in const [
            MetricSize.small,
            MetricSize.wide,
            MetricSize.large,
          ])
            GestureDetector(
              onTap: () => onPick(s),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                color: s == current ? c.accent : Colors.transparent,
                child: Text(
                  metricSizeLetter(s),
                  style: ZType.lbl(
                    9.5,
                    color: s == current ? c.accentContrast : c.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddMetricSlot extends StatelessWidget {
  final ThemeColors colors;
  final VoidCallback onTap;

  const _AddMetricSlot({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          // Dashed, not solid: the slot is a placeholder, and next to the
          // dashed empty tiles a solid outline reads as a real card.
          painter: MetricTileDashedBorder(
            color: colors.cardBorder,
            radius: 14,
            strokeWidth: 1.5,
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).metricGridAddMetric,
                  style:
                      ZType.lbl(10.5, color: colors.textMuted, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Every metric Zealova can source, health-connected or manual. Tapping one
/// places it — adding IS enabling; there is no enable-elsewhere-then-drag
/// second step.
class AddMetricTileSheet extends ConsumerWidget {
  const AddMetricTileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final available = ref.watch(unplacedMetricTilesProvider);
    final notifier = ref.read(homeMetricTilesProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            l10n.metricGridAddMetric,
            style: ZType.lbl(11, color: c.textMuted, letterSpacing: 2),
          ),
        ),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.metricGridEveryMetricPlaced,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: available.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final spec = available[i];
                // Deliberately NOT reading each metric's live value here:
                // watching ~18 metricTileDataProviders at once would kick off a
                // trend fetch per row just to open a picker. The row says where
                // the metric comes from; the number arrives when it is placed.
                return GestureDetector(
                  onTap: () {
                    HapticService.light();
                    // A manual add beats the probe. The probe can only see
                    // evidence — 30 days of samples — so a user who just
                    // bought a watch, or whose ring syncs through a source we
                    // could not sample, would otherwise place a tile that
                    // `mountedMetricTilesProvider` immediately filters back
                    // out. They know about a source we cannot see; believe
                    // them. (`markCapable` was written for exactly this and
                    // then never called from anywhere.)
                    final kind = RingKindX.fromId(spec.id);
                    if (kind != null) {
                      ref
                          .read(metricCapabilityProvider.notifier)
                          .markCapable(kind);
                    }
                    notifier.add(spec.id);
                    Navigator.of(context).maybePop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: c.elevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            // What the tile will actually say once placed —
                            // picking "Move" and getting a tile headed STEPS
                            // is a small lie the sheet doesn't need to tell.
                            spec.tileLabel,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          switch (spec.source) {
                            MetricTileSource.health => l10n.metricGridSourceHealth,
                            MetricTileSource.inApp => l10n.metricGridSourceInApp,
                            MetricTileSource.computed =>
                              l10n.metricGridSourceComputed,
                            // Where a plan tile's number comes from is the
                            // same answer as a computed one from the reader's
                            // side: the app worked it out, they did not log it.
                            MetricTileSource.plan =>
                              l10n.metricGridSourceComputed,
                          },
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.add, size: 18, color: c.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Name of the platform's health aggregator. iOS/macOS read Apple Health;
/// everything else reads Health Connect. Same rule as
/// `combined_health_screen.dart`'s `_platformSourceName` — kept local rather
/// than imported so the tile grid does not depend on a screen.
String _healthSourceName(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ||
            Theme.of(context).platform == TargetPlatform.macOS
        ? 'Apple Health'
        : 'Health Connect';
