import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Gap 5 — a user-named hydration bottle preset (e.g. "Stanley" = 946 ml) for
/// one-tap logging. Volume is always stored in ml regardless of display unit.
///
/// Lives in the data layer (not the hydration tab UI) so both the tab and the
/// home-screen widget sync can read it without a UI→repository import cycle.
class CustomBottle {
  final String id;
  final String label;
  final int ml;

  const CustomBottle({required this.id, required this.label, required this.ml});

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'ml': ml};

  factory CustomBottle.fromJson(Map<String, dynamic> j) => CustomBottle(
        id: j['id'] as String? ?? 'b${j.hashCode}',
        label: j['label'] as String? ?? 'Bottle',
        ml: (j['ml'] as num?)?.toInt() ?? 0,
      );
}

/// Local (SharedPreferences) persistence for a user's saved bottles. Kept
/// device-local — a personal convenience list that survives restarts without a
/// server round-trip or schema migration. Per-user keyed so multiple accounts
/// on one device don't share bottles.
class CustomBottleStore {
  static const _prefix = 'hydration_custom_bottles_v1::';

  static String _key(String userId) => '$_prefix$userId';

  static Future<List<CustomBottle>> load(String userId) async {
    if (userId.isEmpty) return const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((m) => CustomBottle.fromJson(Map<String, dynamic>.from(m)))
          .where((b) => b.ml > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(String userId, List<CustomBottle> bottles) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode(bottles.map((b) => b.toJson()).toList()),
      );
    } catch (_) {/* best-effort */}
  }
}
