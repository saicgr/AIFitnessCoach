import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reorderable / toggleable cards in the NUTRITION STATS section.
///
/// The week-at-a-glance scalar strip is intentionally NOT here: it's the
/// section's pinned header and always renders first.
enum NutritionStatCard {
  inflammation,
  calorieTrend,
  macroBreakdown,
  tdee,
  adherence,
  fuelingSplit,
}

extension NutritionStatCardMeta on NutritionStatCard {
  /// Stable key persisted to SharedPreferences (decoupled from enum index so
  /// reordering the enum declaration never corrupts a saved layout).
  String get key => name;

  /// Human label shown in the customize sheet.
  String get label => switch (this) {
        NutritionStatCard.inflammation => 'Inflammation',
        NutritionStatCard.calorieTrend => 'Calorie trend',
        NutritionStatCard.macroBreakdown => 'Macro breakdown',
        NutritionStatCard.tdee => 'TDEE & energy balance',
        NutritionStatCard.adherence => 'Adherence',
        NutritionStatCard.fuelingSplit => 'Fueling split',
      };

  static NutritionStatCard? fromKey(String key) {
    for (final c in NutritionStatCard.values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// Immutable layout: an explicit card order plus the set the user hid.
@immutable
class NutritionStatsLayout {
  final List<NutritionStatCard> order;
  final Set<NutritionStatCard> hidden;

  const NutritionStatsLayout({required this.order, required this.hidden});

  /// Default — every card visible, in declaration order.
  factory NutritionStatsLayout.defaults() => NutritionStatsLayout(
        order: List.of(NutritionStatCard.values),
        hidden: const {},
      );

  /// The cards to actually render, in order, skipping hidden ones.
  List<NutritionStatCard> get visible =>
      order.where((c) => !hidden.contains(c)).toList();

  bool isHidden(NutritionStatCard c) => hidden.contains(c);

  NutritionStatsLayout copyWith({
    List<NutritionStatCard>? order,
    Set<NutritionStatCard>? hidden,
  }) =>
      NutritionStatsLayout(
        order: order ?? this.order,
        hidden: hidden ?? this.hidden,
      );
}

/// Persists the NUTRITION STATS card layout (order + hidden set) to
/// SharedPreferences. Local-only and instant — mirrors the custom-trend
/// persistence pattern. New enum values added in a future build are appended to
/// the end of a saved order automatically, so a layout saved today never drops
/// a card shipped tomorrow.
class NutritionStatsLayoutNotifier extends StateNotifier<NutritionStatsLayout> {
  NutritionStatsLayoutNotifier() : super(NutritionStatsLayout.defaults()) {
    _load();
  }

  static const _kOrderKey = 'nutrition_stats_card_order_v1';
  static const _kHiddenKey = 'nutrition_stats_card_hidden_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getStringList(_kOrderKey);
      final savedHidden = prefs.getStringList(_kHiddenKey) ?? const [];

      // Rebuild the order from saved keys, dropping unknown keys and appending
      // any enum value that wasn't saved (a newly shipped card).
      final order = <NutritionStatCard>[];
      if (savedOrder != null) {
        for (final k in savedOrder) {
          final c = NutritionStatCardMeta.fromKey(k);
          if (c != null && !order.contains(c)) order.add(c);
        }
      }
      for (final c in NutritionStatCard.values) {
        if (!order.contains(c)) order.add(c);
      }

      final hidden = <NutritionStatCard>{};
      for (final k in savedHidden) {
        final c = NutritionStatCardMeta.fromKey(k);
        if (c != null) hidden.add(c);
      }

      state = NutritionStatsLayout(order: order, hidden: hidden);
    } catch (e) {
      debugPrint('⚠️ [NutritionStatsLayout] load failed: $e');
    }
  }

  Future<void> _persist(NutritionStatsLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kOrderKey, layout.order.map((c) => c.key).toList());
      await prefs.setStringList(
          _kHiddenKey, layout.hidden.map((c) => c.key).toList());
    } catch (e) {
      debugPrint('⚠️ [NutritionStatsLayout] persist failed: $e');
    }
  }

  /// Move a card from [oldIndex] to [newIndex] in the full order list (indices
  /// are into the customize sheet's full list, not the visible subset).
  void reorder(int oldIndex, int newIndex) {
    final order = List.of(state.order);
    if (oldIndex < 0 || oldIndex >= order.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final card = order.removeAt(oldIndex);
    order.insert(newIndex.clamp(0, order.length), card);
    state = state.copyWith(order: order);
    _persist(state);
  }

  void toggleHidden(NutritionStatCard card) {
    final hidden = Set.of(state.hidden);
    if (!hidden.remove(card)) hidden.add(card);
    state = state.copyWith(hidden: hidden);
    _persist(state);
  }

  void reset() {
    state = NutritionStatsLayout.defaults();
    _persist(state);
  }
}

final nutritionStatsLayoutProvider = StateNotifierProvider<
    NutritionStatsLayoutNotifier, NutritionStatsLayout>(
  (ref) => NutritionStatsLayoutNotifier(),
);
