import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/quick_action.dart';

const _quickActionOrderKey = 'quick_action_order';

final quickActionOrderProvider =
    StateNotifierProvider<QuickActionOrderNotifier, List<String>>((ref) {
  return QuickActionOrderNotifier();
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
      final valid =
          saved.where((id) => quickActionRegistry.containsKey(id)).toList();
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

final pinnedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  return order
      .take(4)
      .map((id) => quickActionRegistry[id]!)
      .toList();
});

final orderedQuickActionsProvider = Provider<List<QuickAction>>((ref) {
  final order = ref.watch(quickActionOrderProvider);
  return order
      .map((id) => quickActionRegistry[id]!)
      .toList();
});
