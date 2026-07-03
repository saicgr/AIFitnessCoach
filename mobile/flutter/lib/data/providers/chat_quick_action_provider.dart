import 'dart:convert';
import 'package:collection/collection.dart';
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

/// Daypart-preferred pill ids, most-relevant first. Applied ONLY when the
/// user has never customized their order (a hand-arranged strip must win) —
/// at 7 PM "Scan Food" (log dinner) beats "Check My Form", in the morning
/// the workout shortcuts lead.
List<String> _daypartPreferredOrder(int hour) {
  if (hour >= 5 && hour <= 10) {
    return const ['quick_workout', 'scan_food', 'check_form', 'nutrition_advice', 'analyze_menu'];
  }
  if (hour >= 17 && hour <= 23) {
    return const ['scan_food', 'analyze_menu', 'nutrition_advice', 'quick_workout', 'check_form'];
  }
  return const ['scan_food', 'quick_workout', 'analyze_menu', 'check_form', 'nutrition_advice'];
}

final chatVisiblePillsProvider = Provider<List<ChatQuickAction>>((ref) {
  final order = ref.watch(chatQuickActionOrderProvider);
  final isDefaultOrder =
      const ListEquality<String>().equals(order, defaultChatQuickActionOrder);
  if (!isDefaultOrder) {
    // User-customized order is sacred — no daypart reshuffling.
    return order.take(5).map((id) => chatQuickActionRegistry[id]!).toList();
  }
  final preferred = _daypartPreferredOrder(DateTime.now().hour);
  final ranked = List<String>.from(order)
    ..sort((a, b) {
      final ia = preferred.indexOf(a);
      final ib = preferred.indexOf(b);
      // Unlisted ids keep their default relative position after listed ones.
      final ra = ia == -1 ? preferred.length + order.indexOf(a) : ia;
      final rb = ib == -1 ? preferred.length + order.indexOf(b) : ib;
      return ra.compareTo(rb);
    });
  return ranked.take(5).map((id) => chatQuickActionRegistry[id]!).toList();
});

final chatAllActionsProvider = Provider<List<ChatQuickAction>>((ref) {
  final order = ref.watch(chatQuickActionOrderProvider);
  return order
      .map((id) => chatQuickActionRegistry[id]!)
      .toList();
});
