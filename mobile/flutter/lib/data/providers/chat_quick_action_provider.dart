import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/chat_quick_action.dart';

const _chatQuickActionOrderKey = 'chat_quick_action_order';

final chatQuickActionOrderProvider =
    StateNotifierProvider<ChatQuickActionOrderNotifier, List<String>>((ref) {
  return ChatQuickActionOrderNotifier();
});

class ChatQuickActionOrderNotifier extends StateNotifier<List<String>> {
  ChatQuickActionOrderNotifier() : super(List.from(defaultChatQuickActionOrder)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chatQuickActionOrderKey);
    if (json != null) {
      final saved = List<String>.from(jsonDecode(json));
      final valid =
          saved.where((id) => chatQuickActionRegistry.containsKey(id)).toList();
      for (final id in defaultChatQuickActionOrder) {
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
    state = List.from(defaultChatQuickActionOrder);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatQuickActionOrderKey, jsonEncode(state));
  }
}

final chatVisiblePillsProvider = Provider<List<ChatQuickAction>>((ref) {
  final order = ref.watch(chatQuickActionOrderProvider);
  return order
      .take(5)
      .map((id) => chatQuickActionRegistry[id]!)
      .toList();
});

final chatAllActionsProvider = Provider<List<ChatQuickAction>>((ref) {
  final order = ref.watch(chatQuickActionOrderProvider);
  return order
      .map((id) => chatQuickActionRegistry[id]!)
      .toList();
});
