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
/// someone dragged it there — so page 2 cannot rot into a dumping ground. When
/// page 2 is empty there is no pager and no dots: an empty page is not a
/// feature to advertise.
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
import '../../../../data/providers/metric_layout_provider.dart'
    show MetricSize;
import '../../../../data/providers/metric_tile_data_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/glass_sheet.dart';
import 'metric_tile_card.dart';
import 'unified_home_widgets.dart' show kHomeHPad;

/// Columns in the tile grid.
const int kMetricGridColumns = 6;

/// Gutter between tiles, both axes.
const double kMetricTileGap = 10;

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

/// Tiles on one page, in order.
List<HomeMetricTile> tilesOnPage(List<HomeMetricTile> tiles, int page) =>
    [for (final t in tiles) if (t.page == page) t];

// ══════════════════════════════════════════════════════ the Home section

class HomeMetricTileGrid extends ConsumerStatefulWidget {
  const HomeMetricTileGrid({super.key});

  @override
  ConsumerState<HomeMetricTileGrid> createState() => _HomeMetricTileGridState();
}

class _HomeMetricTileGridState extends ConsumerState<HomeMetricTileGrid> {
  final PageController _pager = PageController(viewportFraction: 0.93);
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
    final tiles = ref.watch(homeMetricTilesProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    // Every tile removed and not editing: collapse rather than leave a header
    // hovering over nothing (same call the strip made when Health was dark).
    if (tiles.isEmpty && !_editing) return const SizedBox.shrink();

    final pageOne = tilesOnPage(tiles, 1);
    final pageTwo = tilesOnPage(tiles, 2);

    return Padding(
      padding: kHomeHPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(c),
          if (_editing) ...[
            const SizedBox(height: 2),
            Text(
              'DRAG TO REORDER · TAP A TILE FOR SIZE · − TO REMOVE',
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
              _StaticGrid(tiles: pageOne, onOpen: _open, onEdit: _startEditing)
            else ...[
              SizedBox(
                height: [
                  metricGridHeight(pageOne, textScale: textScale),
                  metricGridHeight(pageTwo, textScale: textScale),
                ].reduce((a, b) => a > b ? a : b),
                child: PageView(
                  controller: _pager,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _StaticGrid(tiles: pageOne, onOpen: _open, onEdit: _startEditing),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _StaticGrid(tiles: pageTwo, onOpen: _open, onEdit: _startEditing),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              _PageDots(count: 2, active: _page, colors: c),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header(ThemeColors c) => Row(
        children: [
          Text(
            'MY METRICS',
            style: ZType.lbl(10.5, color: c.textMuted, letterSpacing: 2),
          ),
          const Spacer(),
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
                  'DONE',
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
    final tiles = ref.watch(homeMetricTilesProvider);
    final pageOne = tilesOnPage(tiles, 1);
    final pageTwo = tilesOnPage(tiles, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageLabel(c, 'PAGE 1 · DAILY GLANCE'),
        const SizedBox(height: 8),
        _EditableGrid(
          tiles: pageOne,
          page: 1,
          selected: _selected,
          onSelect: _select,
          colors: c,
        ),
        const SizedBox(height: 16),
        _pageLabel(c, 'PAGE 2 · DEPTH'),
        const SizedBox(height: 8),
        _EditableGrid(
          tiles: pageTwo,
          page: 2,
          selected: _selected,
          onSelect: _select,
          colors: c,
          emptyHint: 'DRAG A TILE HERE FOR PAGE 2',
        ),
        const SizedBox(height: 12),
        _AddMetricSlot(colors: c, onTap: () => _openAddSheet(context)),
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
  final String? emptyHint;

  const _EditableGrid({
    required this.tiles,
    required this.page,
    required this.selected,
    required this.onSelect,
    required this.colors,
    this.emptyHint,
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
            label: emptyHint ?? 'NO TILES ON THIS PAGE',
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
      placementLine: '${metricSizeLetter(tile.size)} · '
          'page ${tile.page} · #${position + 1}',
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
              placementLine: 'DRAGGING…',
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
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colors.accent.withValues(alpha: 0.14),
          border: Border.all(color: colors.accent, width: 1.5),
        ),
        child: Text(
          'DROP HERE',
          style: ZType.lbl(9.5, color: colors.accent, letterSpacing: 1.8),
        ),
      );
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
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.cardBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 15, color: colors.textMuted),
              const SizedBox(width: 8),
              Text(
                'ADD METRIC',
                style: ZType.lbl(10.5, color: colors.textMuted, letterSpacing: 2),
              ),
            ],
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
    final available = ref.watch(unplacedMetricTilesProvider);
    final notifier = ref.read(homeMetricTilesProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            'ADD METRIC',
            style: ZType.lbl(11, color: c.textMuted, letterSpacing: 2),
          ),
        ),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Every metric is already on your grid.',
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
                            spec.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          switch (spec.source) {
                            MetricTileSource.health => 'Health',
                            MetricTileSource.inApp => 'Logged in-app',
                            MetricTileSource.computed => 'Computed',
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
