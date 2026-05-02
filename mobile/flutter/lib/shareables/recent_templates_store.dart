import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the user's last-used share templates so the share sheet can
/// (a) preselect the most recent template on open, and (b) badge tiles
/// the user has touched lately. Stored client-side only — never synced
/// to the backend, since template preference is purely UX and changes
/// frequently.
class RecentTemplatesStore {
  static const _key = 'share_template_recents';
  static const _maxItems = 5;

  /// Returns the recently-used template IDs in most-recent-first order.
  /// Empty list when nothing has been stored yet.
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .take(_maxItems)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Records a template use. Prepends the id to the list, dedupes, caps
  /// at [_maxItems]. Fire-and-forget — failures are non-fatal.
  static Future<void> recordUsed(String templateId) async {
    if (templateId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final next = <String>[
      templateId,
      ...current.where((id) => id != templateId),
    ].take(_maxItems).toList();
    await prefs.setString(_key, jsonEncode(next));
  }

  /// Clears the recents list. Useful when the user signs out.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
