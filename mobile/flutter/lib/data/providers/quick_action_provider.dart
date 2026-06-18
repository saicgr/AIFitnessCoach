import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/quick_action.dart';
import 'nutrition_preferences_provider.dart';

const _quickActionOrderKey = 'quick_action_order';
// `_quickActionExpandedKey` retired — signature-v2 dropped the "Show two rows"
// mode for a single fixed pinned row. Replaced by `_quickActionsHomeVisibleKey`
// below (the "Show on home screen" toggle, default OFF).
const _quickActionsHomeVisibleKey = 'quick_actions_home_visible';
// One-shot migration flag — bumped 2026-04-25 when slot-5 default was
// flipped from 'scan_food' (document scanner) to 'photo_food' (single
// camera shot of a meal). Users who customized their layout before that
// release still had 'scan_food' pinned; this migration moves them to
// the new default once.
const _quickActionMigrationKey = 'quick_action_migration_v2';
// v3 (2026-05): meditation moved from the removed home "Mind" card into quick
// actions — inserts 'meditate' at slot 6 for existing saved layouts once.
const _quickActionMigrationV3Key = 'quick_action_migration_v3';

final quickActionOrderProvider =
    StateNotifierProvider<QuickActionOrderNotifier, List<String>>((ref) {
      return QuickActionOrderNotifier();
    });

/// Whether the pinned quick-actions row is shown on the home screen.
/// SharedPreferences-backed, DEFAULT FALSE — the home screen is clean unless
/// the user explicitly opts into surfacing their pinned shortcuts. Replaces the
/// retired `quickActionsExpandedProvider` ("Show two rows").
final quickActionsHomeVisibleProvider =
    StateNotifierProvider<QuickActionsHomeVisibleNotifier, bool>((ref) {
      return QuickActionsHomeVisibleNotifier();
    });

class QuickActionOrderNotifier extends StateNotifier<List<String>> {
  QuickActionOrderNotifier() : super(List.from(defaultQuickActionOrder)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_quickActionOrderKey);
    if (json != null) {
      final saved = List<String>.from(jsonDecode(json));
      List<String> valid = saved
          .where((id) => quickActionRegistry.containsKey(id))
          .toList();

      // Migration v2: swap legacy 'scan_food' in the first 5 slots
      // (Pinned / home row 1) for the new 'photo_food' default. Keep
      // 'scan_food' in the order so the user can still access it via the
      // More sheet — just demote it past the pinned cutoff. Idempotent
      // via the SharedPreferences flag so it never runs twice.
      final migrated = prefs.getBool(_quickActionMigrationKey) ?? false;
      if (!migrated) {
        final pinnedCount = 5;
        final scanIdx = valid.indexOf('scan_food');
        if (scanIdx != -1 &&
            scanIdx < pinnedCount &&
            !valid.contains('photo_food')) {
          valid[scanIdx] = 'photo_food';
          // Append the original scan_food + barcode_food so they live in
          // the More sheet and don't disappear.
          if (!valid.contains('scan_food')) valid.add('scan_food');
        }
        if (!valid.contains('barcode_food')) valid.add('barcode_food');
        await prefs.setBool(_quickActionMigrationKey, true);
        await prefs.setString(_quickActionOrderKey, jsonEncode(valid));
      }

      // Migration v3: surface 'meditate' at slot 6 (index 5) for existing
      // saved layouts so it shows on the home row instead of being appended at
      // the end by the loop below. Idempotent via the v3 flag.
      final migratedV3 = prefs.getBool(_quickActionMigrationV3Key) ?? false;
      if (!migratedV3) {
        valid.remove('meditate');
        valid.insert(valid.length < 5 ? valid.length : 5, 'meditate');
        await prefs.setBool(_quickActionMigrationV3Key, true);
        await prefs.setString(_quickActionOrderKey, jsonEncode(valid));
      }

      for (final id in defaultQuickActionOrder) {
        if (!valid.contains(id)) valid.add(id);
      }
      state = valid;
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<String>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = list;
    await _save();
  }

  Future<void> resetToDefault() async {
    state = List.from(defaultQuickActionOrder);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quickActionOrderKey, jsonEncode(state));
  }
}

class QuickActionsHomeVisibleNotifier extends StateNotifier<bool> {
  QuickActionsHomeVisibleNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Default OFF — the pinned quick-actions row only appears on home once the
    // user turns on "Show on home screen" in the customize sheet.
    state = prefs.getBool(_quickActionsHomeVisibleKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickActionsHomeVisibleKey, state);
  }
}

/// Home `CompactQuickActionsRow` slot IDs.
///
/// A single fixed row of the first 6 ordered/pinned IDs (slot 7 = the fixed
/// "More" tile, appended by the row widget). "More" is never part of the order
/// list — it is rendered separately in [quick_actions_row.dart]. The old
/// two-row "expanded" mode was retired in signature-v2.
List<String> homeQuickActionSlotIds(
  List<String> order, {
  bool hideWater = false,
}) {
  return order
      .where((id) => quickActionRegistry.containsKey(id))
      // Gap 6 — drop the water quick-action when hydration tracking is off.
      .where((id) => !(hideWater && id == 'water'))
      .take(6)
      .toList();
}

/// Gap 6 — true when the user has water tracking enabled (default true).
bool _hydrationEnabled(Ref ref) =>
    ref
        .watch(nutritionPreferencesProvider)
        .preferences
        ?.hydrationTrackingEnabled ??
    true;

/// The pinned shortcut bar — first 6 actions in the user's order (slot 7 =
/// the fixed "More" tile, appended by the row widget).
final pinnedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  final hideWater = !_hydrationEnabled(ref);
  return order
      .where((id) => quickActionRegistry.containsKey(id))
      .where((id) => !(hideWater && id == 'water'))
      .take(6)
      .map((id) => quickActionRegistry[id]!)
      .toList();
});

final orderedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  final hideWater = !_hydrationEnabled(ref);
  return order
      .where((id) => quickActionRegistry.containsKey(id))
      .where((id) => !(hideWater && id == 'water'))
      .map((id) => quickActionRegistry[id]!)
      .toList();
});
