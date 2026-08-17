/// Which metrics this user's sources can actually produce — decided ONCE, and
/// then held still.
///
/// ## Why this exists
///
/// Home's metric grid spent five design rounds trying to make an empty tile
/// look acceptable. It never could, because three unrelated situations were
/// being rendered identically:
///
///   1. **a real zero** — 0 steps at 6 AM, 0 of 85 oz of water. A measurement
///      that legitimately reads zero. That is content; show the number.
///   2. **not yet today** — the metric exists for this user, but the watch has
///      not synced this morning. Show the newest real value, dated.
///   3. **no source, ever** — the user owns no device that can produce this
///      metric. It will never fill.
///
/// Only (3) is unfixable by copy, and it is the one that was being styled.
/// The answer is not a better empty tile: it is not mounting the tile.
///
/// ## How capability is decided
///
/// "Owns no watch" is not observable — no platform API reports a device
/// inventory. What IS observable is history, because authorising Health grants
/// access to PAST samples: a trailing-30-day sample count answers the question
/// immediately, at first render, with no waiting period.
///
/// Two rules, because two kinds of metric behave differently:
///
///   * **phone-native** (steps, distance, flights) — capable as soon as Health
///     is authorised. The handset's motion coprocessor is a source we know
///     statically, so a brand-new phone with zero history still mounts Steps
///     and reads a real 0. A pure sample-count rule would have failed here and
///     grown the grid the next day, which is precisely the shape-shifting the
///     founder rejected.
///   * **wearable-only** (sleep, HRV, readiness, stress, resting HR) — capable
///     only if the trailing 30 days hold at least one sample. No watch means
///     no tile, rather than a permanent dead box.
///
/// ## Why it is frozen
///
/// The decision is persisted so the grid's shape exists BEFORE the first
/// render and never changes under the user. A tile may later be ADDED (a probe
/// re-run after buying a watch, or a manual add) — and when it is, the arrival
/// is announced rather than discovered mid-scroll. Nothing is ever
/// auto-removed: Google Health silently hid vitals and sleep tiles in its May
/// 2026 update and users reported it as data loss.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The SAME provider `homeMetricTilesStorageKey` scopes on. There are two
// `currentUserIdProvider`s in this codebase (auth_provider and user_provider);
// the capability slot and the layout slot must key off one of them, or two
// halves of the same grid end up scoped to different notions of "account".
import '../../core/providers/auth_provider.dart' show currentUserIdProvider;
import '../../screens/home/widgets/ring_catalog.dart';
import '../services/health_service.dart';
import 'home_metric_tiles_provider.dart'
    show HomeMetricTile, MetricTileSource, homeMetricTilesProvider,
        kHomeMetricTileCatalog, metricNeedsWornDevice, kTodayScoreTileId,
        defaultMetricTilesFor, isPlanTileId;
import 'metric_tile_data_provider.dart'
    show metricTileDataProvider, metricScoreSeenInWindowProvider;

/// How far back the probe looks for evidence that a source exists.
///
/// Thirty days matches the baseline window the deviation copy quotes, so a
/// metric that passes the probe can also claim a baseline on its first render.
const int kCapabilityProbeDays = 30;

/// SharedPreferences slot for the resolved capability set, **per account**.
///
/// Scoped by user id for the same reason `homeMetricTilesStorageKey` is: two
/// accounts on one device do not share a device inventory. It used to be one
/// global key, so signing into a second account inherited the first's capable
/// set — and because the probe's merge is union-only (a metric that was
/// capable stays capable), the second account could never correct it back
/// down. A watch owner's grid would appear, fully mounted and permanently
/// empty, for someone who owns no watch.
String capabilityPrefsKey(String? userId) => (userId == null || userId.isEmpty)
    ? 'metric_capability_v1_anon'
    : 'metric_capability_v1_$userId';

/// The pre-scoping key. Read once, migrated into the current account's slot,
/// then deleted — an existing user's resolved capability is not thrown away
/// just because the key moved.
const String kLegacyCapabilityPrefsKey = 'metric_capability_v1';

/// The outcome of the probe: which ring kinds this user's sources can fill.
@immutable
class MetricCapability {
  /// Ring kinds that have a working source. Absent = do not mount a tile.
  final Set<RingKind> capable;

  /// When the probe last ran. Null = never probed; the grid falls back to the
  /// in-app-only set rather than guessing.
  final DateTime? probedAt;

  /// True once a probe has completed, successfully or not. Distinguishes
  /// "no capable wearable metrics" from "we have not looked yet" — the two
  /// must not render the same grid.
  final bool resolved;

  /// True once this account has EVER scored a point. One-way, and persisted.
  ///
  /// The Today Score tile's mount gate. It has to be a stored fact rather than
  /// a question asked of the data, because the score history keeps 90 days: a
  /// user who scored in March and nothing since would answer "never" and lose
  /// a tile they have been reading for months, which is precisely the
  /// disappearing-tile failure this file exists to prevent.
  final bool scoreEverScored;

  const MetricCapability({
    this.capable = const {},
    this.probedAt,
    this.resolved = false,
    this.scoreEverScored = false,
  });

  bool can(RingKind k) => capable.contains(k);

  MetricCapability copyWith({
    Set<RingKind>? capable,
    DateTime? probedAt,
    bool? resolved,
    bool? scoreEverScored,
  }) =>
      MetricCapability(
        capable: capable ?? this.capable,
        probedAt: probedAt ?? this.probedAt,
        resolved: resolved ?? this.resolved,
        // Never goes back to false: `|| this` rather than `??`, so no caller
        // can un-earn it by omitting the field on some other update.
        scoreEverScored: (scoreEverScored ?? false) || this.scoreEverScored,
      );

  Map<String, dynamic> toJson() => {
        'capable': capable.map((k) => k.id).toList(),
        'probedAt': probedAt?.toIso8601String(),
        'resolved': resolved,
        'scoreEverScored': scoreEverScored,
      };

  static MetricCapability fromJson(Map<String, dynamic> json) {
    final ids = (json['capable'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();
    return MetricCapability(
      capable: RingKind.values.where((k) => ids.contains(k.id)).toSet(),
      probedAt: json['probedAt'] != null
          ? DateTime.tryParse(json['probedAt'] as String)
          : null,
      resolved: json['resolved'] as bool? ?? false,
      scoreEverScored: json['scoreEverScored'] as bool? ?? false,
    );
  }
}

final metricCapabilityProvider =
    StateNotifierProvider<MetricCapabilityNotifier, MetricCapability>((ref) {
  return MetricCapabilityNotifier(ref);
});

class MetricCapabilityNotifier extends StateNotifier<MetricCapability> {
  final Ref _ref;

  MetricCapabilityNotifier(this._ref) : super(const MetricCapability()) {
    _load();

    // Re-probe whenever the Health connection turns ON, from ANY path: the
    // six in-app connect buttons, the onboarding screen, or a grant the user
    // made in iOS Settings while the app was backgrounded (the sync notifier
    // upgrades its own state when it detects that). Listening to the flip is
    // one chokepoint instead of six call sites, and it cannot be forgotten by
    // whoever adds the seventh.
    //
    // Only false -> true. A connection going away must never shrink the grid:
    // the tiles freeze with their last real values instead (see the paused
    // treatment), because a tile vanishing reads as data loss.
    _ref.listen<bool>(
      healthSyncProvider.select((s) => s.isConnected),
      (was, now) {
        if (now && was != true) {
          probe(healthAuthorised: true);
        }
      },
    );

  }

  /// Promote "a point is visible right now" into "this account has scored",
  /// once, permanently — the fact that makes the Today Score tile's return
  /// irreversible, since the history it would otherwise be inferred from is
  /// trimmed at 90 days.
  ///
  /// Deliberately NOT in the constructor. Subscribing there builds the score
  /// graph synchronously while the notifier is still being created, and any
  /// throw from it (an unauthenticated launch, a provider that needs a session
  /// that does not exist yet) escapes the constructor and takes the whole
  /// capability provider down with it — which would empty the grid rather than
  /// merely delay one tile.
  void _watchFirstPoint() {
    if (!mounted || state.scoreEverScored) return;
    try {
      _ref.listen<bool>(
        metricScoreSeenInWindowProvider,
        (was, now) {
          if (now) markScoreEverScored();
        },
        fireImmediately: true,
      );
    } catch (e) {
      debugPrint('📐 [Capability] first-point watch unavailable: $e');
    }
  }

  /// Records the first point this account ever scores. One-way; the Today
  /// Score tile mounts from here on, on every device this preference reaches.
  Future<void> markScoreEverScored() async {
    if (!mounted || state.scoreEverScored) return;
    state = state.copyWith(scoreEverScored: true);
    debugPrint('📐 [Capability] first point scored — Today Score tile mounts');
    await _save();
  }

  /// The account this capability set belongs to.
  ///
  /// Guarded: the id comes from the live Supabase session, which throws if it
  /// is read before Supabase initialises. Losing the id must degrade to the
  /// anonymous slot, never take persistence down with it — an unsaved
  /// capability set means the probe re-runs every launch, and (before this
  /// guard) a throw here silently stopped `_save` from ever writing.
  String? get _userId {
    try {
      return _ref.read(currentUserIdProvider);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(capabilityPrefsKey(_userId));
      if (raw == null) {
        // One-time move off the global key. Whoever is signed in when the
        // migration runs inherits it — the same assumption the global key was
        // already making, just no longer applied to everyone afterwards.
        final legacy = prefs.getString(kLegacyCapabilityPrefsKey);
        if (legacy != null) {
          await prefs.setString(capabilityPrefsKey(_userId), legacy);
          await prefs.remove(kLegacyCapabilityPrefsKey);
          raw = legacy;
        }
      }
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && mounted) {
          state = MetricCapability.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('📐 [Capability] load failed: $e');
    }
    await _resolveIfNeverProbed();
    _pushDefaultShape();
    _watchFirstPoint();
  }

  /// The backfill.
  ///
  /// [probe] used to have exactly one call site — the onboarding screen — so
  /// every account that finished onboarding before this feature shipped sat at
  /// `capable: {}` forever. `mountedMetricTilesProvider` gates on that set, so
  /// those accounts rendered ONE tile: the Today Score, reading 0. Water and
  /// Weight, which need no wearable at all, were filtered out with the sensors.
  ///
  /// Running it here — once, when nothing has ever been resolved — is the
  /// chokepoint version of the fix: it covers the pre-upgrade accounts, a
  /// reinstall, cleared preferences, and any future path that reaches Home
  /// without passing through onboarding. Already-resolved accounts are
  /// untouched, so this never re-litigates a decision that was already made.
  Future<void> _resolveIfNeverProbed() async {
    if (!mounted || state.resolved) return;
    try {
      final connected = _ref.read(healthSyncProvider).isConnected;
      debugPrint('📐 [Capability] never probed — backfilling '
          '(health connected: $connected)');
      await probe(healthAuthorised: connected);
    } catch (e) {
      // A probe that cannot run is not evidence of absence — the same rule the
      // per-metric probe already follows. Staying unresolved leaves the grid
      // on its plan-backed shape, which is a complete Home rather than a thin
      // one, and the next launch (or a Health connect) tries again. This must
      // never escape: it runs inside the notifier's constructor chain, where
      // an unhandled async error would take the whole provider down.
      debugPrint('📐 [Capability] backfill probe failed: $e');
    }
  }

  /// Hand the tile layout its account-shaped default.
  ///
  /// The shape depends on capability, and capability resolves asynchronously,
  /// so the layout cannot compute it in its own constructor. Pushing from here
  /// keeps the dependency one-directional (capability → tiles) and means the
  /// arrangement is settled before the grid's first meaningful frame.
  void _pushDefaultShape() {
    if (!mounted) return;
    try {
      _ref.read(homeMetricTilesProvider.notifier).adoptDefaultShape(
            defaultMetricTilesFor(
              capabilityResolved: state.resolved,
              capable: state.capable,
            ),
          );
    } catch (e) {
      // Same reasoning as the backfill: shaping the default is an improvement
      // to the starting layout, never a precondition for having one.
      debugPrint('📐 [Capability] default shape push failed: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          capabilityPrefsKey(_userId), jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('📐 [Capability] save failed: $e');
    }
  }

  /// Runs the probe and freezes the result.
  ///
  /// Called at onboarding-complete (whether the user connected or skipped) and
  /// again after any manual connect, so the grid's shape is known before Home
  /// first paints.
  ///
  /// [healthAuthorised] is passed in rather than read here so the caller
  /// controls the ordering — probing before the OS grant resolves would record
  /// a false negative and freeze the user into a thinner grid than they earned.
  Future<void> probe({required bool healthAuthorised}) async {
    final capable = <RingKind>{};

    // In-app and computed metrics never depend on a device: water, weight and
    // the Today Score are always mountable.
    for (final k in RingKind.values) {
      if (!_isHealthSourced(k)) capable.add(k);
    }

    if (healthAuthorised) {
      // Phone-native health metrics: authorisation IS capability. A zero-history
      // handset still counts steps from today forward, so Steps mounts now and
      // reads a real 0 rather than appearing tomorrow.
      for (final k in RingKind.values) {
        if (_isHealthSourced(k) && !metricNeedsWornDevice(k)) capable.add(k);
      }

      // Wearable-only metrics: evidence required. `hasRecentSamples` looks back
      // `kCapabilityProbeDays`; authorisation grants access to history, so this
      // resolves immediately rather than after a waiting period.
      for (final k in RingKind.values) {
        if (!_isHealthSourced(k) || !metricNeedsWornDevice(k)) continue;
        try {
          final has = await _ref
              .read(healthServiceProvider)
              .hasRecentSamples(k, days: kCapabilityProbeDays);
          if (has) capable.add(k);
        } catch (e) {
          // A probe error is NOT evidence of absence. Leave the metric out of
          // `capable` for now — the next probe can add it, and an added tile is
          // announced. Never the reverse.
          debugPrint('📐 [Capability] probe failed for ${k.id}: $e');
        }
      }
    }

    if (!mounted) return;
    state = state.copyWith(
      // Union, never replacement: a metric that was capable stays capable.
      // Dropping one would silently unmount a tile the user has been reading,
      // which is the failure mode Google Health shipped in May 2026.
      capable: {...state.capable, ...capable},
      probedAt: DateTime.now(),
      resolved: true,
    );
    await _save();
    _pushDefaultShape();
    debugPrint('📐 [Capability] resolved: '
        '${state.capable.map((k) => k.id).join(', ')}');
  }

  /// Marks a kind capable because the user explicitly added its tile. A manual
  /// add always beats the probe — the user knows about a source we cannot see.
  Future<void> markCapable(RingKind k) async {
    if (state.can(k)) return;
    state = state.copyWith(capable: {...state.capable, k});
    await _save();
  }

  bool _isHealthSourced(RingKind k) {
    switch (k) {
      case RingKind.hydration:
      case RingKind.nourish:
      case RingKind.protein:
      case RingKind.mindfulMinutes:
      case RingKind.weight:
      case RingKind.bodyFat:
      case RingKind.train:
        return false;
      default:
        return true;
    }
  }
}

/// The tiles that actually mount — the user's arrangement, filtered to what
/// their sources can produce.
///
/// This is the single place the "one Home, variable length" rule is enforced.
/// The arrangement in [homeMetricTilesProvider] is what the user chose; this
/// is what the grid draws. Filtering at READ time (rather than pruning the
/// stored arrangement) means a tile the user cannot fill today is preserved,
/// not deleted — buy a watch, re-probe, and it reappears in the slot they put
/// it in.
///
/// Before the probe resolves, only never-dependent tiles mount. Guessing and
/// then correcting would shift the grid under the user, which is the exact
/// thing this design exists to prevent.
/// The Today Score tile's mount gate: the persisted one-way fact, OR a point
/// visible in the data right now.
///
/// The OR matters in both directions. The stored flag survives the 90-day
/// history trim, and the live half means the very first point of an account's
/// life mounts the tile immediately rather than after the write lands.
final metricScoreEverScoredProvider = Provider<bool>((ref) {
  if (ref.watch(metricCapabilityProvider).scoreEverScored) return true;
  return ref.watch(metricScoreSeenInWindowProvider);
});

/// Whether one tile mounts — the whole rule, as a pure function.
///
/// Extracted so the tests exercise THIS and not a hand-rolled copy of it. The
/// copy is how the original defect shipped unnoticed: every "which tiles
/// mount" test fed a synthetic capability set that already contained
/// hydration and weight, so nothing covered the state every pre-upgrade
/// account was actually in.
bool metricTileMountable(
  String tileId, {
  required MetricCapability capability,
  required bool scoreEverScored,
  required bool planHasData,
}) {
  // The Today Score: mounts once this account has ever scored a point.
  //
  // It is an EXECUTION score — "how much of today's plan have you done" — so
  // it reads 0 every morning by construction, and on a brand-new account it
  // has never read anything else. A 56pt zero above a chart it cannot draw is
  // the same "no source yet" case every other tile is spared, and it was the
  // one tile exempted from the rule.
  //
  // The gate is history, not today's value: an account that has scored before
  // keeps its tile at 6 AM on day 300, because hiding a tile someone has been
  // reading is the failure mode this file exists to prevent. So it disappears
  // exactly once in an account's life, and returns for good the moment the
  // user earns a point.
  if (tileId == kTodayScoreTileId) return scoreEverScored;

  final spec = kHomeMetricTileCatalog[tileId];

  // Plan-backed tiles: mount when the field behind them is actually there. A
  // maintenance-goal account has no target weight, so To goal does not mount
  // rather than rendering "0 lb to go"; an ad-hoc plan has no program, so Week
  // does not mount. Same doctrine as a watch-less account and Sleep.
  if (spec?.source == MetricTileSource.plan) return planHasData;

  // ⚠️ Capability is a statement about DEVICES, and nothing else.
  //
  // Water and Weight are logged by hand: they need no watch, no grant, and no
  // probe. Gating them on the capability set is what produced a Home holding
  // ONE tile — the probe had never run for accounts that finished onboarding
  // before it existed, so `capable` was empty, and two metrics that were alive
  // and fillable the whole time were filtered out with the sensors.
  //
  // The backfill in this file fixes the empty set. This line makes the class
  // of bug unreachable: a metric that never needed a device can never be
  // withheld for lack of one, however the capability set got into that state.
  if (spec != null && spec.source != MetricTileSource.health) return true;

  final kind = RingKindX.fromId(tileId);
  if (kind == null) return true;
  return capability.can(kind);
}

final mountedMetricTilesProvider = Provider<List<HomeMetricTile>>((ref) {
  final all = ref.watch(homeMetricTilesProvider);
  final cap = ref.watch(metricCapabilityProvider);

  return all.where((t) {
    // Each input is read only when the rule actually needs it: watching every
    // plan tile's data for a grid that holds none would subscribe Home to the
    // program, plan and nutrition stores for nothing.
    return metricTileMountable(
      t.id,
      capability: cap,
      scoreEverScored: t.id == kTodayScoreTileId &&
          ref.watch(metricScoreEverScoredProvider),
      planHasData: isPlanTileId(t.id) &&
          ref.watch(metricTileDataProvider(t.id)).hasData,
    );
  }).toList(growable: false);
});
