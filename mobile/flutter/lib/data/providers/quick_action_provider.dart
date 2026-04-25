import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/quick_action.dart';

const _quickActionOrderKey = 'quick_action_order';
const _quickActionExpandedKey = 'quick_action_expanded';
// One-shot migration flag — bumped 2026-04-25 when slot-5 default was
// flipped from 'scan_food' (document scanner) to 'photo_food' (single
// camera shot of a meal). Users who customized their layout before that
// release still had 'scan_food' pinned; this migration moves them to
// the new default once.
const _quickActionMigrationKey = 'quick_action_migration_v2';

final quickActionOrderProvider =
    StateNotifierProvider<QuickActionOrderNotifier, List<String>>((ref) {
  return QuickActionOrderNotifier();
});

final quickActionsExpandedProvider =
    StateNotifierProvider<QuickActionsExpandedNotifier, bool>((ref) {
  return QuickActionsExpandedNotifier();
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
      List<String> valid =
          saved.where((id) => quickActionRegistry.containsKey(id)).toList();

      // Migration v2: swap legacy 'scan_food' in the first 5 slots
      // (Pinned / home row 1) for the new 'photo_food' default. Keep
      // 'scan_food' in the order so the user can still access it via the
      // More sheet — just demote it past the pinned cutoff. Idempotent
      // via the SharedPreferences flag so it never runs twice.
      final migrated = prefs.getBool(_quickActionMigrationKey) ?? false;
      if (!migrated) {
        final pinnedCount = 5;
        final scanIdx = valid.indexOf('scan_food');
        if (scanIdx != -1 && scanIdx < pinnedCount &&
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

class QuickActionsExpandedNotifier extends StateNotifier<bool> {
  QuickActionsExpandedNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_quickActionExpandedKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickActionExpandedKey, state);
  }
}

/// Row 1 of the shortcut bar — first 5 actions in the user's order.
final pinnedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  return order
      .take(5)
      .map((id) => quickActionRegistry[id]!)
      .toList();
});

final orderedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  return order
      .map((id) => quickActionRegistry[id]!)
      .toList();
});

/// Row 2 of the shortcut bar — actions 6-9. Slot 10 is the fixed "More" tile
/// rendered separately in [quick_actions_row.dart].
final secondRowActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  return order
      .skip(5)
      .take(4)
      .map((id) => quickActionRegistry[id]!)
      .toList();
});
