/// The Home metric-tile layout: which metrics are on the grid, in what order,
/// at what size, and on which of the two pages.
///
/// This is the *single* source of truth for the customisable tile grid that
/// replaced the four-cell hero-score strip under the Home masthead. It is
/// deliberately one store rather than three:
///
///  * `ringVisibilityProvider` owns the **ring deck's** order (today_score_card
///    / customize_rings_sheet still read it) — it is a `List<RingKind>`, so it
///    structurally cannot hold the Today Score tile, which is not a ring.
///  * `metricLayoutProvider` owns chart style / colour / range for the metric
///    rows, and its `MetricSize` enum is reused here verbatim so "S / M / L"
///    means the same thing in both places.
///
/// A tile therefore carries the three things the grid needs and nothing else:
/// [HomeMetricTile.id], [HomeMetricTile.size] and [HomeMetricTile.page].
///
/// **Migration.** An existing user's metric layout is never discarded. On the
/// first load under this key we look for a persisted *ring* order
/// ([ringOrderStorageKey]) — the order they set in My Space → Metrics before
/// tiles existed — and rebuild it as tiles verbatim (same metrics, same
/// sequence), with the Today Score hero prepended. Everything lands on page 1:
/// nothing auto-fills page 2, ever (that is the product rule the mockup calls
/// out — page 2 exists only because a user dragged something there). A user
/// with no ring customisation gets [kDefaultMetricTiles], the daily-glance set.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/auth_provider.dart';
import '../../screens/home/widgets/ring_catalog.dart';
import 'metric_layout_provider.dart' show MetricSize, MetricSizeX;

/// The Today Score tile's id. Not a [RingKind]: the score is the composite the
/// four contributor rings feed, so it has no ring of its own.
const String kTodayScoreTileId = 'today_score';

/// Where a tile's number comes from — decides what its empty state says.
enum MetricTileSource {
  /// A wearable / platform health source (Apple Health, Health Connect).
  /// Missing → "No source · connect Health".
  health,

  /// The user logs it inside Zealova (water, weight, food).
  /// Missing → "Nothing logged yet".
  inApp,

  /// Computed from in-app activity; never dark on a fresh install.
  computed,
}

/// How a tile phrases its distance from the 30-day baseline.
enum MetricDeviationStyle {
  /// "12% below your 30-day baseline".
  percent,

  /// "6 pts above your 30-day baseline" — for 0–100 scores, where a percent
  /// change of a percent-shaped number reads as nonsense.
  points,

  /// "1.2 lb below your 30-day baseline" — for slow body metrics where a
  /// fraction of a percent is the honest but useless framing.
  absolute,
}

/// Static description of one metric that can occupy a tile.
@immutable
class MetricTileSpec {
  /// Stable persistence id. Matches [RingKindX.id] for ring-backed metrics.
  final String id;

  /// The metric's name in lists and settings — the ring's own label.
  final String label;

  /// The tracked uppercase kicker on the tile, which is NOT always the ring's
  /// label: a ring is a scored contributor ("Move", "Recovery", "Hydration")
  /// while a tile shows the raw number underneath it, so the tile says what
  /// the number is — STEPS, READY, WATER. See [_kTileKickerOverrides].
  final String tileLabel;

  /// The ring this tile reads, or null for [kTodayScoreTileId].
  final RingKind? ring;

  final MetricTileSource source;
  final MetricDeviationStyle deviationStyle;

  /// Size a freshly-added tile takes.
  final MetricSize defaultSize;

  /// Detail route opened on tap. Falls back to a no-op when the route isn't
  /// registered in the running flavor (see the tile's tap handler).
  final String route;

  const MetricTileSpec({
    required this.id,
    required this.label,
    required this.tileLabel,
    required this.ring,
    required this.source,
    required this.route,
    this.deviationStyle = MetricDeviationStyle.percent,
    this.defaultSize = MetricSize.small,
  });
}

/// Tile kickers that deliberately differ from the ring's label. The ring is a
/// scored contributor; the tile is the number itself, so it says what the
/// number is. Everything not listed here uses the ring's own label verbatim.
///
/// These sit beside the ring labels in `ring_catalog.dart` as code constants
/// rather than in the `.arb` bundles, for the same reason those do: the metric
/// catalogue is one table and splitting half of it into localisation keys
/// would leave the two halves free to drift.
const Map<String, String> _kTileKickerOverrides = {
  'move': 'Steps',
  'recovery': 'Ready',
  'hydration': 'Water',
};

MetricTileSource _sourceFor(RingKind k) {
  switch (k) {
    case RingKind.hydration:
    case RingKind.nourish:
    case RingKind.protein:
    case RingKind.mindfulMinutes:
      return MetricTileSource.inApp;
    case RingKind.weight:
    case RingKind.bodyFat:
      // Logged by hand or synced from a smart scale — either way the user's
      // own log is the primary source, so "connect Health" is the wrong ask.
      return MetricTileSource.inApp;
    case RingKind.train:
      return MetricTileSource.computed;
    default:
      return MetricTileSource.health;
  }
}

MetricDeviationStyle _deviationStyleFor(RingKind k) {
  switch (k) {
    case RingKind.recovery:
    case RingKind.stress:
      return MetricDeviationStyle.points;
    case RingKind.weight:
    case RingKind.bodyFat:
      return MetricDeviationStyle.absolute;
    default:
      return MetricDeviationStyle.percent;
  }
}

MetricSize _defaultSizeFor(RingKind k) {
  switch (k) {
    case RingKind.move:
    case RingKind.sleep:
      return MetricSize.wide;
    default:
      return MetricSize.small;
  }
}

/// Route for a ring-backed tile. The universal metric-detail screen
/// (`/metric/:id`) already resolves every id the registry knows; the rest fall
/// back to the health hub, which is where the strip these tiles replaced went.
String _routeFor(RingKind k) {
  switch (k) {
    case RingKind.sleep:
    case RingKind.sleepLatency:
    case RingKind.wakeConsistency:
    case RingKind.bedtimeWindow:
      return '/health/sleep';
    case RingKind.hrv:
    case RingKind.vo2max:
      return '/health/vitals';
    case RingKind.train:
    case RingKind.nourish:
    case RingKind.move:
    case RingKind.activeEnergy:
    case RingKind.recovery:
    case RingKind.hydration:
    case RingKind.weight:
    case RingKind.heartRate:
    case RingKind.protein:
      // Ids covered by `metricRegistry` — the universal detail screen.
      return '/metric/${k.id}';
    default:
      return '/health/combined';
  }
}

/// Every metric that can be placed on the grid: the Today Score plus the full
/// ring catalogue. This is what the Add-metric sheet lists — "adding a metric
/// IS enabling it", there is no separate enable step.
final Map<String, MetricTileSpec> kHomeMetricTileCatalog = {
  kTodayScoreTileId: const MetricTileSpec(
    id: kTodayScoreTileId,
    label: 'Today Score',
    tileLabel: 'Today Score',
    ring: null,
    source: MetricTileSource.computed,
    deviationStyle: MetricDeviationStyle.points,
    defaultSize: MetricSize.large,
    route: '/health/combined',
  ),
  for (final k in RingKind.values)
    k.id: MetricTileSpec(
      id: k.id,
      label: k.label,
      tileLabel: _kTileKickerOverrides[k.id] ?? k.label,
      ring: k,
      source: _sourceFor(k),
      deviationStyle: _deviationStyleFor(k),
      defaultSize: _defaultSizeFor(k),
      route: _routeFor(k),
    ),
};

/// One placed tile.
@immutable
class HomeMetricTile {
  final String id;
  final MetricSize size;

  /// 1 = the daily glance, 2 = opt-in depth. Never anything else.
  final int page;

  const HomeMetricTile({
    required this.id,
    required this.size,
    this.page = 1,
  });

  MetricTileSpec? get spec => kHomeMetricTileCatalog[id];

  HomeMetricTile copyWith({MetricSize? size, int? page}) => HomeMetricTile(
        id: id,
        size: size ?? this.size,
        page: page ?? this.page,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'size': size.id,
        'page': page,
      };

  /// Returns null for a blob that no longer maps to a real metric (a ring
  /// removed from the catalogue) — the caller drops it rather than rendering
  /// a tile with no source.
  static HomeMetricTile? fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! String || !kHomeMetricTileCatalog.containsKey(id)) return null;
    final page = (j['page'] as num?)?.toInt() ?? 1;
    return HomeMetricTile(
      id: id,
      size: MetricSizeX.fromId(j['size'] as String?),
      page: page == 2 ? 2 : 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HomeMetricTile &&
      other.id == id &&
      other.size == size &&
      other.page == page;

  @override
  int get hashCode => Object.hash(id, size, page);

  @override
  String toString() => 'HomeMetricTile($id, ${size.id}, p$page)';
}

/// The daily-glance default, straight from the mockup: one hero + two halves +
/// three thirds, all on page 1. Page 2 starts empty on purpose.
const List<HomeMetricTile> kDefaultMetricTiles = [
  HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
  HomeMetricTile(id: 'move', size: MetricSize.wide),
  HomeMetricTile(id: 'sleep', size: MetricSize.wide),
  HomeMetricTile(id: 'recovery', size: MetricSize.small),
  HomeMetricTile(id: 'hydration', size: MetricSize.small),
  HomeMetricTile(id: 'weight', size: MetricSize.small),
];

/// A named starting arrangement. A preset carries **everything the layout is**
/// — which metrics, in what order, at what size, on which page — because a
/// preset that only picked metrics would silently flatten a user's sizing the
/// moment they tapped it.
@immutable
class MetricTilePreset {
  /// Stable id (never shown).
  final String id;

  /// Chip label.
  final String label;

  final List<HomeMetricTile> tiles;

  const MetricTilePreset({
    required this.id,
    required this.label,
    required this.tiles,
  });
}

/// The presets offered under the Add slot. Kept deliberately short: three
/// named layouts and the user's own. Every id here must exist in
/// [kHomeMetricTileCatalog] — `metricTilePresetsAreValid` asserts it in tests.
const List<MetricTilePreset> kMetricTilePresets = [
  MetricTilePreset(
    id: 'minimal',
    label: 'Minimal',
    tiles: [
      HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
      HomeMetricTile(id: 'move', size: MetricSize.small),
      HomeMetricTile(id: 'sleep', size: MetricSize.small),
      HomeMetricTile(id: 'hydration', size: MetricSize.small),
    ],
  ),
  MetricTilePreset(
    id: 'training_day',
    label: 'Training day',
    tiles: [
      HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
      HomeMetricTile(id: 'train', size: MetricSize.wide),
      HomeMetricTile(id: 'move', size: MetricSize.wide),
      HomeMetricTile(id: 'protein', size: MetricSize.small),
      HomeMetricTile(id: 'hydration', size: MetricSize.small),
      HomeMetricTile(id: 'active_energy', size: MetricSize.small),
    ],
  ),
  MetricTilePreset(
    id: 'recovery',
    label: 'Recovery',
    tiles: [
      HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
      HomeMetricTile(id: 'sleep', size: MetricSize.wide),
      HomeMetricTile(id: 'recovery', size: MetricSize.wide),
      HomeMetricTile(id: 'hrv', size: MetricSize.small),
      HomeMetricTile(id: 'heart_rate', size: MetricSize.small),
      HomeMetricTile(id: 'stress', size: MetricSize.small),
    ],
  ),
];

/// True when [tiles] is exactly [preset]'s arrangement — same metrics, same
/// order, same sizes, same pages. Anything else is the user's own layout.
bool metricTilesMatchPreset(List<HomeMetricTile> tiles, MetricTilePreset p) {
  if (tiles.length != p.tiles.length) return false;
  for (var i = 0; i < tiles.length; i++) {
    if (tiles[i] != p.tiles[i]) return false;
  }
  return true;
}

/// SharedPreferences key, scoped per account so switching users on one device
/// doesn't bleed layouts. `_v1` is the migration version: bump it only to
/// force-reseed, which discards a user's arrangement.
String homeMetricTilesStorageKey(String? userId) =>
    (userId == null || userId.isEmpty)
        ? 'home_metric_tiles_v1_anon'
        : 'home_metric_tiles_v1_$userId';

/// Collapses duplicate ids (first wins) and clamps pages to 1..2.
List<HomeMetricTile> _sanitise(List<HomeMetricTile> input) {
  final seen = <String>{};
  final out = <HomeMetricTile>[];
  for (final t in input) {
    if (!kHomeMetricTileCatalog.containsKey(t.id)) continue;
    if (!seen.add(t.id)) continue;
    out.add(t.page == 2 ? t : t.copyWith(page: 1));
  }
  return out;
}

class HomeMetricTilesNotifier extends StateNotifier<List<HomeMetricTile>> {
  final Ref _ref;

  /// True once a user (or the migration) has written a layout. Until then the
  /// in-memory state is the default and is intentionally NOT persisted, so a
  /// future default change still reaches untouched accounts.
  bool _persisted = false;

  HomeMetricTilesNotifier(this._ref) : super(kDefaultMetricTiles) {
    _load();
  }

  String? get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(homeMetricTilesStorageKey(_userId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final tiles = <HomeMetricTile>[];
          for (final entry in decoded) {
            if (entry is Map) {
              final t = HomeMetricTile.fromJson(Map<String, dynamic>.from(entry));
              if (t != null) tiles.add(t);
            }
          }
          _persisted = true;
          if (mounted) state = _sanitise(tiles);
          return;
        }
      }
      await _seedFromRingLayout(prefs);
    } catch (e) {
      debugPrint('⚠️ [MetricTiles] load failed, using defaults: $e');
    }
  }

  /// One-time migration off the pre-tiles world.
  ///
  /// A user who reordered / added metrics in My Space → Metrics has that order
  /// persisted as ring ids. Rebuild it as tiles in the SAME sequence so their
  /// arrangement survives the swap; prepend the Today Score hero (which the
  /// strip showed and the ring list could never hold). Sizes come from each
  /// metric's spec default because size was never rendered on Home before this
  /// build — there is no visible sizing to preserve, and reading the async
  /// metric-layout store here would make the migration racy.
  Future<void> _seedFromRingLayout(SharedPreferences prefs) async {
    final raw = prefs.getString(ringOrderStorageKey(_userId));
    if (raw == null || raw.isEmpty) return; // never customised → defaults
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final tiles = <HomeMetricTile>[
      const HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
    ];
    for (final entry in decoded) {
      if (entry is! String) continue;
      final kind = RingKindX.fromId(entry);
      if (kind == null) continue;
      final spec = kHomeMetricTileCatalog[kind.id];
      if (spec == null) continue;
      tiles.add(HomeMetricTile(id: spec.id, size: spec.defaultSize));
    }
    if (tiles.length == 1) return; // nothing usable → defaults

    final migrated = _sanitise(tiles);
    if (mounted) state = migrated;
    _persisted = true;
    await _write(prefs, migrated);
  }

  Future<void> _write(
      SharedPreferences prefs, List<HomeMetricTile> tiles) async {
    await prefs.setString(
      homeMetricTilesStorageKey(_userId),
      jsonEncode([for (final t in tiles) t.toJson()]),
    );
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persisted = true;
      await _write(prefs, state);
    } catch (e) {
      debugPrint('⚠️ [MetricTiles] persist failed: $e');
    }
  }

  /// Whether a layout has been written for this account.
  bool get hasPersistedLayout => _persisted;

  void _set(List<HomeMetricTile> next) {
    state = _sanitise(next);
    _persist();
  }

  /// Move the tile at [oldIndex] so it sits at [newIndex] in the flat list.
  /// Indices are into the full (both pages) list.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final next = List<HomeMetricTile>.of(state);
    final moved = next.removeAt(oldIndex);
    final target = newIndex.clamp(0, next.length);
    next.insert(target, moved);
    _set(next);
  }

  /// Drag-and-drop primitive: put [movedId] immediately before [targetId] and
  /// adopt the target's page. When [targetId] is null the tile goes to the end
  /// of [page] (used by the page-2 drop zone).
  void moveTo(String movedId, {String? targetId, int? page}) {
    final from = state.indexWhere((t) => t.id == movedId);
    if (from < 0) return;
    final next = List<HomeMetricTile>.of(state);
    var moved = next.removeAt(from);

    if (targetId != null) {
      final at = next.indexWhere((t) => t.id == targetId);
      if (at < 0) return;
      moved = moved.copyWith(page: page ?? next[at].page);
      next.insert(at, moved);
    } else {
      final destination = page ?? moved.page;
      moved = moved.copyWith(page: destination);
      next.insert(_appendIndexFor(next, destination), moved);
    }
    _set(next);
  }

  void setSize(String id, MetricSize size) {
    final i = state.indexWhere((t) => t.id == id);
    if (i < 0 || state[i].size == size) return;
    final next = List<HomeMetricTile>.of(state);
    next[i] = next[i].copyWith(size: size);
    _set(next);
  }

  void setPage(String id, int page) {
    final i = state.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final clamped = page == 2 ? 2 : 1;
    if (state[i].page == clamped) return;
    moveTo(id, page: clamped);
  }

  /// Hide a tile. The metric and its history are untouched — it stays in the
  /// Add sheet, exactly like My Space's show/hide semantics.
  void remove(String id) {
    if (!state.any((t) => t.id == id)) return;
    _set(state.where((t) => t.id != id).toList(growable: false));
  }

  /// Place a metric. Adding IS enabling: one act, sized and live.
  void add(String id, {MetricSize? size, int page = 1}) {
    final spec = kHomeMetricTileCatalog[id];
    if (spec == null || state.any((t) => t.id == id)) return;
    final tile = HomeMetricTile(
      id: id,
      size: size ?? spec.defaultSize,
      page: page == 2 ? 2 : 1,
    );
    final next = List<HomeMetricTile>.of(state);
    next.insert(_appendIndexFor(next, tile.page), tile);
    _set(next);
  }

  void resetToDefault() => _set(kDefaultMetricTiles);

  /// The arrangement the user had before they tried a preset, so "My layout"
  /// is a real destination rather than a decorative chip. In memory only — a
  /// preset the user kept across a relaunch IS their layout by then.
  List<HomeMetricTile>? _layoutBeforePreset;

  /// Whether tapping "My layout" would restore something.
  bool get hasLayoutBeforePreset => _layoutBeforePreset != null;

  /// Apply a named preset — metrics, order, sizes and pages together.
  void applyPreset(MetricTilePreset preset) {
    if (metricTilesMatchPreset(state, preset)) return;
    if (!kMetricTilePresets.any((p) => metricTilesMatchPreset(state, p))) {
      _layoutBeforePreset = List<HomeMetricTile>.of(state);
    }
    _set(preset.tiles);
  }

  /// Put back the layout the user had before the first preset tap.
  void restoreLayoutBeforePreset() {
    final previous = _layoutBeforePreset;
    if (previous == null) return;
    _layoutBeforePreset = null;
    _set(previous);
  }

  /// Index at which a tile belonging to [page] should be appended so the flat
  /// list stays grouped page-1-then-page-2 (the pager reads runs, not a sort).
  static int _appendIndexFor(List<HomeMetricTile> tiles, int page) {
    if (page == 2) return tiles.length;
    final lastOnPageOne = tiles.lastIndexWhere((t) => t.page == 1);
    return lastOnPageOne + 1; // -1 + 1 == 0 when page 1 is empty
  }
}

/// Tiles on one page, in order. Lives here rather than in the grid widget so
/// the aggregate providers can page-partition without a data → screens import.
List<HomeMetricTile> tilesOnPage(List<HomeMetricTile> tiles, int page) =>
    [for (final t in tiles) if (t.page == page) t];

/// The Home metric grid's tiles, in flat render order across both pages.
final homeMetricTilesProvider =
    StateNotifierProvider<HomeMetricTilesNotifier, List<HomeMetricTile>>((ref) {
  ref.watch(currentUserIdProvider); // one layout per account
  return HomeMetricTilesNotifier(ref);
});

/// The preset the current arrangement exactly matches, or null — which is the
/// "My layout" (dirty) state the chip row shows as active.
final activeMetricTilePresetProvider = Provider<MetricTilePreset?>((ref) {
  final tiles = ref.watch(homeMetricTilesProvider);
  for (final p in kMetricTilePresets) {
    if (metricTilesMatchPreset(tiles, p)) return p;
  }
  return null;
});

/// Metrics not currently on the grid — the Add-metric sheet's contents.
final unplacedMetricTilesProvider = Provider<List<MetricTileSpec>>((ref) {
  final placed = {for (final t in ref.watch(homeMetricTilesProvider)) t.id};
  return [
    for (final spec in kHomeMetricTileCatalog.values)
      if (!placed.contains(spec.id)) spec,
  ];
});
