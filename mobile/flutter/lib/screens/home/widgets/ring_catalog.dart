/// Canonical catalogue of all G1 rings the home screen can render, plus a
/// Riverpod-backed visibility/order model persisted to SharedPreferences.
///
/// The render layer (today_score_card.dart and friends) reads
/// [ringVisibilityProvider] to know which rings to draw and in what order. The
/// customize sheet writes to it via [RingVisibilityNotifier].
///
/// Source-provider wiring is intentionally a *string identifier* for now
/// (see [RingSpec.sourceId]); a later integration step will fan those out to
/// real data providers (today-score, sleep stage, cycle, etc.).
library;

import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/services/health_service.dart' show healthSyncProvider;
import '../../../l10n/generated/app_localizations.dart';

/// All rings the home screen knows how to render. Order = catalogue order
/// (not display order — display order lives in [RingVisibilityNotifier]).
enum RingKind {
  train,
  nourish,
  move,
  sleep,
  cycle,
  heartRate,
  hrv,
  stress,
  hydration,
  weight,
  recovery,
  // Appended (sleep/cardio metrics promoted from standalone home cards into
  // the deck). Persistence is by `.id` slug, so appending is index-safe.
  sleepLatency,
  wakeConsistency,
  bedtimeWindow,
  vo2max,
}

/// Static metadata for a single ring.
class RingSpec {
  final RingKind kind;
  final String id; // stable string id used for persistence
  final String label;
  final Color color;
  final String sourceId; // logical data-source key; wired by render layer
  final bool isCore; // core rings cannot be hidden
  final bool defaultVisible;

  const RingSpec({
    required this.kind,
    required this.id,
    required this.label,
    required this.color,
    required this.sourceId,
    required this.isCore,
    required this.defaultVisible,
  });
}

/// Catalogue lookup. Keep in sync with plan §1b table.
const Map<RingKind, RingSpec> kRingCatalog = {
  RingKind.train: RingSpec(
    kind: RingKind.train,
    id: 'train',
    label: 'Train',
    color: Color(0xFFEC8B2C),
    sourceId: 'today_score.train',
    isCore: true,
    defaultVisible: true,
  ),
  RingKind.nourish: RingSpec(
    kind: RingKind.nourish,
    id: 'nourish',
    label: 'Nourish',
    color: Color(0xFF3FA66B),
    sourceId: 'today_score.fuel',
    isCore: true,
    defaultVisible: true,
  ),
  RingKind.move: RingSpec(
    kind: RingKind.move,
    id: 'move',
    label: 'Move',
    color: Color(0xFF3E8FD0),
    sourceId: 'today_score.move',
    isCore: true,
    defaultVisible: true,
  ),
  RingKind.sleep: RingSpec(
    kind: RingKind.sleep,
    id: 'sleep',
    label: 'Sleep',
    color: Color(0xFF8B5CF6),
    sourceId: 'today_score.sleep',
    isCore: true,
    defaultVisible: true,
  ),
  RingKind.cycle: RingSpec(
    kind: RingKind.cycle,
    id: 'cycle',
    label: 'Cycle day',
    color: Color(0xFFE899B0),
    sourceId: 'cycle.day',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.heartRate: RingSpec(
    kind: RingKind.heartRate,
    id: 'heart_rate',
    label: 'Heart rate',
    color: Color(0xFFE5544D),
    sourceId: 'wearable.hr',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.hrv: RingSpec(
    kind: RingKind.hrv,
    id: 'hrv',
    label: 'HRV',
    color: Color(0xFF14B8A6),
    sourceId: 'wearable.hrv',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.stress: RingSpec(
    kind: RingKind.stress,
    id: 'stress',
    label: 'Stress',
    color: Color(0xFFF59E0B),
    sourceId: 'wearable.stress',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.hydration: RingSpec(
    kind: RingKind.hydration,
    id: 'hydration',
    label: 'Hydration',
    color: Color(0xFF06B6D4),
    sourceId: 'hydration.today',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.weight: RingSpec(
    kind: RingKind.weight,
    id: 'weight',
    label: 'Weight',
    color: Color(0xFF64748B),
    sourceId: 'weight.trend',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.recovery: RingSpec(
    kind: RingKind.recovery,
    id: 'recovery',
    label: 'Recovery',
    color: Color(0xFFA855F7),
    sourceId: 'wearable.recovery',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.sleepLatency: RingSpec(
    kind: RingKind.sleepLatency,
    id: 'sleep_latency',
    label: 'Sleep latency',
    color: Color(0xFF8B5CF6),
    sourceId: 'sleep.latency',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.wakeConsistency: RingSpec(
    kind: RingKind.wakeConsistency,
    id: 'wake_consistency',
    label: 'Wake consistency',
    color: Color(0xFFF59E0B),
    sourceId: 'sleep.wake_consistency',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.bedtimeWindow: RingSpec(
    kind: RingKind.bedtimeWindow,
    id: 'bedtime_window',
    label: 'Bedtime',
    color: Color(0xFF6366F1),
    sourceId: 'sleep.bedtime_window',
    isCore: false,
    defaultVisible: false,
  ),
  RingKind.vo2max: RingSpec(
    kind: RingKind.vo2max,
    id: 'vo2max',
    label: 'VO₂max',
    color: Color(0xFFE5544D),
    sourceId: 'wearable.vo2max',
    isCore: false,
    defaultVisible: false,
  ),
};

extension RingKindX on RingKind {
  RingSpec get spec => kRingCatalog[this]!;
  String get id => spec.id;
  String get label => spec.label;
  Color get color => spec.color;
  bool get isCore => spec.isCore;

  /// Localized display label for use in UI widgets.
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case RingKind.train: return l10n.ringLabelTrain;
      case RingKind.nourish: return l10n.ringLabelNourish;
      case RingKind.move: return l10n.ringLabelMove;
      case RingKind.sleep: return l10n.ringLabelSleep;
      case RingKind.cycle: return l10n.ringLabelCycleDay;
      case RingKind.heartRate: return l10n.ringLabelHeartRate;
      case RingKind.hrv: return l10n.ringLabelHrv;
      case RingKind.stress: return l10n.ringLabelStress;
      case RingKind.hydration: return l10n.ringLabelHydration;
      case RingKind.weight: return l10n.ringLabelWeight;
      case RingKind.recovery: return l10n.ringLabelRecovery;
      // New metrics use plain (English) labels for now — no ARB key yet, so
      // they don't require an l10n regeneration to compile/ship.
      case RingKind.sleepLatency: return 'Sleep latency';
      case RingKind.wakeConsistency: return 'Wake consistency';
      case RingKind.bedtimeWindow: return 'Bedtime';
      case RingKind.vo2max: return 'VO₂max';
    }
  }

  static RingKind? fromId(String id) {
    for (final entry in kRingCatalog.entries) {
      if (entry.value.id == id) return entry.key;
    }
    return null;
  }

  /// Canonical default order shown on first launch. Core 4 only.
  static List<RingKind> get defaultOrder => const [
        RingKind.train,
        RingKind.nourish,
        RingKind.move,
        RingKind.sleep,
      ];
}

/// Lightweight model for sheet consumers — pairs a [RingKind] with its
/// catalog spec without forcing them to call `.spec` themselves.
class RingVisibility {
  final RingKind kind;
  final bool visible;
  const RingVisibility({required this.kind, required this.visible});
}

/// SharedPreferences storage key. Scoped per user when an id is available so
/// switching accounts on the same device doesn't bleed customisations.
String _ringOrderKey(String? userId) =>
    userId == null || userId.isEmpty
        ? 'home_ring_order_anon'
        : 'home_ring_order_$userId';

class RingVisibilityNotifier extends StateNotifier<List<RingKind>> {
  final Ref _ref;
  RingVisibilityNotifier(this._ref) : super(RingKindX.defaultOrder) {
    _load();
  }

  String? get _userId => _ref.read(currentUserIdProvider);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_ringOrderKey(_userId));
      if (raw == null || raw.isEmpty) {
        // First load — no persisted order. Apply the wearable auto-enable
        // migration before the user sees the rings. See _maybeAutoEnableRecovery.
        await _maybeAutoEnableRecovery(prefs);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final ids = decoded.whereType<String>().toList(growable: false);
      final kinds = ids
          .map(RingKindX.fromId)
          .whereType<RingKind>()
          .toList(growable: false);
      if (kinds.isEmpty) return;
      // Defensive: dedupe (a legacy/corrupt blob may repeat an id, which would
      // crash the customize sheet's keyed ReorderableListView) and guarantee
      // all core rings remain in the list.
      final withCore = _ensureCorePresent(kinds);
      state = withCore;
      // Self-heal: if dedup/core-completion changed the stored order, rewrite
      // it so the corrupt blob doesn't reload (and re-dedupe) every launch.
      // ids are stable slugs without commas, so a join comparison is safe.
      if (withCore.map((k) => k.id).join(',') != ids.join(',')) {
        await _persist();
      }
      // Even with a persisted order, run the one-time auto-enable migration
      // — covers users who upgrade with an existing default order that
      // predates the Recovery ring.
      await _maybeAutoEnableRecovery(prefs);
    } catch (_) {
      // Persistence is best-effort — keep defaults on any error.
    }
  }

  /// One-time auto-enable: for users with connected wearable HRV/RHR data,
  /// add the Recovery ring to their visible list so they don't have to dig
  /// into Customize to find it. Guarded by a `home_rings_wearable_autoenable_v1`
  /// SharedPreferences flag so it only runs once per user.
  ///
  /// Plan §7. Reads `healthSyncProvider.isConnected` as the proxy for "user
  /// has wearable signals available" — more precise per-signal detection
  /// (HRV vs RHR specifically) would require touching the health-service
  /// API and is out of scope; this catches the >95% case for Apple
  /// Watch / Health Connect users.
  Future<void> _maybeAutoEnableRecovery(SharedPreferences prefs) async {
    const flagKey = 'home_rings_wearable_autoenable_v1';
    try {
      if (prefs.getBool(flagKey) == true) return;

      // Read health-sync state synchronously — by the time _load runs the
      // provider is already initialized for the existing home screen.
      final syncState = _ref.read(healthSyncProvider);
      if (!syncState.isConnected) {
        // Don't burn the migration flag — the user may connect later.
        return;
      }

      // Mark the migration done first so a transient state error doesn't
      // double-fire on the next launch.
      await prefs.setBool(flagKey, true);

      if (state.contains(RingKind.recovery)) return;
      state = [...state, RingKind.recovery];
      await _persist();
    } catch (_) {
      // Best-effort. Worst case: user manually adds via Customize sheet.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((k) => k.id).toList());
      await prefs.setString(_ringOrderKey(_userId), encoded);
    } catch (_) {
      // Best-effort; in-memory state still reflects user intent.
    }
  }

  /// Collapses duplicate kinds in [input] (first occurrence wins, caller order
  /// preserved) and appends any missing core ring.
  ///
  /// Deduping here is load-bearing, not cosmetic: the customize sheet renders
  /// the visible rings in a [ReorderableListView] keyed by `ring_${kind.id}`,
  /// so a duplicate [RingKind] reaching the UI is a hard crash — Flutter
  /// reparents the colliding GlobalKey mid-layout ("A RenderRepaintBoundary
  /// was mutated in RenderSliverList.performLayout" + "Duplicate GlobalKey
  /// detected"). Every state mutation funnels through this method, so the
  /// visible ring list can never contain a duplicate regardless of corrupt or
  /// legacy persisted data (e.g. an id persisted twice by an older build, or
  /// the async [_load] racing a synchronous mutator).
  List<RingKind> _ensureCorePresent(List<RingKind> input) {
    final seen = <RingKind>{};
    final result = <RingKind>[];
    for (final k in input) {
      if (seen.add(k)) result.add(k);
    }
    for (final core in RingKindX.defaultOrder) {
      if (seen.add(core)) result.add(core);
    }
    return result;
  }

  /// Replace the entire visible ring list (used by ReorderableListView).
  void setOrder(List<RingKind> order) {
    // [_ensureCorePresent] dedupes (preserving order) and re-adds core rings.
    state = _ensureCorePresent(order);
    _persist();
  }

  /// Append a ring at the end. No-op if already visible.
  void addRing(RingKind kind) {
    if (state.contains(kind)) return;
    state = [...state, kind];
    _persist();
  }

  /// Remove a ring. Silent no-op on core rings.
  void removeRing(RingKind kind) {
    if (kind.isCore) return;
    if (!state.contains(kind)) return;
    state = state.where((k) => k != kind).toList(growable: false);
    _persist();
  }

  /// Restore the canonical defaults (core 4 in canonical order).
  void resetToDefault() {
    state = RingKindX.defaultOrder;
    _persist();
  }
}

/// Currently visible rings, in display order.
final ringVisibilityProvider =
    StateNotifierProvider<RingVisibilityNotifier, List<RingKind>>((ref) {
  // Rebuild the notifier when the user id changes so each account loads its
  // own persisted order.
  ref.watch(currentUserIdProvider);
  return RingVisibilityNotifier(ref);
});

/// Convenience: which rings are NOT currently visible. Useful for the "add"
/// section of the customize sheet.
final hiddenRingsProvider = Provider<List<RingKind>>((ref) {
  final visible = ref.watch(ringVisibilityProvider).toSet();
  return RingKind.values
      .where((k) => !visible.contains(k))
      .toList(growable: false);
});
