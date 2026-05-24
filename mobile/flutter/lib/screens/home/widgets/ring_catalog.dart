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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/auth_provider.dart';

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
};

extension RingKindX on RingKind {
  RingSpec get spec => kRingCatalog[this]!;
  String get id => spec.id;
  String get label => spec.label;
  Color get color => spec.color;
  bool get isCore => spec.isCore;

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
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final ids = decoded.whereType<String>();
      final kinds = ids
          .map(RingKindX.fromId)
          .whereType<RingKind>()
          .toList(growable: false);
      if (kinds.isEmpty) return;
      // Defensive: guarantee all core rings remain in the list.
      final withCore = _ensureCorePresent(kinds);
      state = withCore;
    } catch (_) {
      // Persistence is best-effort — keep defaults on any error.
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

  List<RingKind> _ensureCorePresent(List<RingKind> input) {
    final seen = input.toSet();
    final result = List<RingKind>.of(input);
    for (final core in RingKindX.defaultOrder) {
      if (!seen.contains(core)) result.add(core);
    }
    return result;
  }

  /// Replace the entire visible ring list (used by ReorderableListView).
  void setOrder(List<RingKind> order) {
    // Dedupe while preserving caller's order, then make sure core rings stay.
    final seen = <RingKind>{};
    final cleaned = <RingKind>[];
    for (final k in order) {
      if (seen.add(k)) cleaned.add(k);
    }
    state = _ensureCorePresent(cleaned);
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
