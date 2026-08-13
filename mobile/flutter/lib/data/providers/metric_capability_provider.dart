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

import '../../screens/home/widgets/ring_catalog.dart';
import '../services/health_service.dart';
import 'home_metric_tiles_provider.dart'
    show HomeMetricTile, homeMetricTilesProvider, metricNeedsWornDevice,
        kTodayScoreTileId;

/// How far back the probe looks for evidence that a source exists.
///
/// Thirty days matches the baseline window the deviation copy quotes, so a
/// metric that passes the probe can also claim a baseline on its first render.
const int kCapabilityProbeDays = 30;

/// SharedPreferences slot for the resolved capability set.
const String kCapabilityPrefsKey = 'metric_capability_v1';

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

  const MetricCapability({
    this.capable = const {},
    this.probedAt,
    this.resolved = false,
  });

  bool can(RingKind k) => capable.contains(k);

  MetricCapability copyWith({
    Set<RingKind>? capable,
    DateTime? probedAt,
    bool? resolved,
  }) =>
      MetricCapability(
        capable: capable ?? this.capable,
        probedAt: probedAt ?? this.probedAt,
        resolved: resolved ?? this.resolved,
      );

  Map<String, dynamic> toJson() => {
        'capable': capable.map((k) => k.id).toList(),
        'probedAt': probedAt?.toIso8601String(),
        'resolved': resolved,
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

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kCapabilityPrefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      if (!mounted) return;
      state = MetricCapability.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('📐 [Capability] load failed: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kCapabilityPrefsKey, jsonEncode(state.toJson()));
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
final mountedMetricTilesProvider = Provider<List<HomeMetricTile>>((ref) {
  final all = ref.watch(homeMetricTilesProvider);
  final cap = ref.watch(metricCapabilityProvider);

  return all.where((t) {
    // The Today Score is computed from in-app activity — always mountable.
    if (t.id == kTodayScoreTileId) return true;
    final kind = RingKindX.fromId(t.id);
    if (kind == null) return true;
    return cap.can(kind);
  }).toList(growable: false);
});
