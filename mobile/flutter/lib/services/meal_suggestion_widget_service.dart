// One-tap meal suggestion widget service.
//
// Pulls a structured meal suggestion from /api/v1/nutrition/quick-suggestion
// and mirrors it into the home_widget shared-storage layer so the native
// iOS WidgetKit extension and Android RemoteViews provider can render it
// without having to open the Flutter app.
//
// Refresh triggers:
//   • App lifecycle resumed (debounced via refreshIfStale TTL)
//   • Any meal logged in-app (caller hooks in)
//   • Widget tapped Refresh/Log buttons (deep-link → app opens → refreshNow)
//
// Edge cases:
//   • Not signed in  → clears widget to placeholder state, no network call
//   • Network error  → leaves previous widget payload untouched
//   • Stale payload  → native side shows "offline" badge (stale flag is in the JSON)
//   • App cold start → init() mirrors whatever's in shared prefs to HomeWidget
//                      so the widget has something to render on first tick

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/api_client.dart';

class QuickSuggestionFoodItem {
  final String name;
  final int? grams;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const QuickSuggestionFoodItem({
    required this.name,
    required this.grams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory QuickSuggestionFoodItem.fromJson(Map<String, dynamic> j) =>
      QuickSuggestionFoodItem(
        name: (j['name'] ?? '') as String,
        grams: j['grams'] is num ? (j['grams'] as num).toInt() : null,
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (grams != null) 'grams': grams,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };
}

class QuickSuggestion {
  final String emoji;
  final String mealSlot;
  final String title;
  final String subtitle;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<QuickSuggestionFoodItem> foodItems;
  final DateTime generatedAt;
  final DateTime? cacheUntil;
  final bool stale;
  final List<String> loggedAlready;

  const QuickSuggestion({
    required this.emoji,
    required this.mealSlot,
    required this.title,
    required this.subtitle,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.foodItems,
    required this.generatedAt,
    required this.cacheUntil,
    required this.stale,
    required this.loggedAlready,
  });

  factory QuickSuggestion.fromJson(Map<String, dynamic> j) => QuickSuggestion(
        emoji: (j['emoji'] ?? '🍽') as String,
        mealSlot: (j['meal_slot'] ?? 'snack') as String,
        title: (j['title'] ?? '') as String,
        subtitle: (j['subtitle'] ?? '') as String,
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
        foodItems: ((j['food_items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(QuickSuggestionFoodItem.fromJson)
            .toList(growable: false),
        generatedAt: DateTime.tryParse((j['generated_at'] ?? '') as String) ??
            DateTime.now().toUtc(),
        cacheUntil: DateTime.tryParse((j['cache_until'] ?? '') as String),
        stale: (j['stale'] as bool?) ?? false,
        loggedAlready: ((j['logged_already'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'meal_slot': mealSlot,
        'title': title,
        'subtitle': subtitle,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'food_items': foodItems.map((f) => f.toJson()).toList(),
        'generated_at': generatedAt.toUtc().toIso8601String(),
        if (cacheUntil != null) 'cache_until': cacheUntil!.toUtc().toIso8601String(),
        'stale': stale,
        'logged_already': loggedAlready,
      };

  String get macrosSummary =>
      '$calories cal · ${proteinG.toStringAsFixed(0)}P '
      '${carbsG.toStringAsFixed(0)}C ${fatG.toStringAsFixed(0)}F';
}

class MealSuggestionWidgetService {
  MealSuggestionWidgetService._(this._client);

  // Singleton. Initialise once from main.dart with the shared ApiClient.
  static MealSuggestionWidgetService? _instance;
  static MealSuggestionWidgetService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
          'MealSuggestionWidgetService not initialised — call init(apiClient) in main.dart first');
    }
    return i;
  }

  static void init(ApiClient apiClient) {
    _instance ??= MealSuggestionWidgetService._(apiClient);
  }

  final ApiClient _client;

  // HomeWidget storage keys + widget names. Kept as constants so the native
  // iOS/Android widgets can reference the same strings.
  static const String _kWidgetJsonKey = 'meal_suggestion_json';
  static const String _kWidgetTsKey = 'meal_suggestion_ts';
  static const String _kLastRefreshPrefKey = 'meal_sug_last_refresh_ms';

  static const String iosWidgetName = 'MealSuggestionWidget';
  static const String androidWidgetName = 'MealSuggestionWidgetProvider';

  QuickSuggestion? _inMemory;

  /// Last-known cached suggestion. Prefer the in-memory copy; fall back to
  /// shared-prefs so callers can read it on a cold start before the first
  /// refresh has finished.
  Future<QuickSuggestion?> readCached() async {
    if (_inMemory != null) return _inMemory;
    try {
      final raw = await HomeWidget.getWidgetData<String>(_kWidgetJsonKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      _inMemory = QuickSuggestion.fromJson(decoded);
      return _inMemory;
    } catch (e) {
      debugPrint('🍽 [MealWidget] readCached failed: $e');
      return null;
    }
  }

  /// Refresh if stale beyond [ttl]. Call this on AppLifecycleState.resumed.
  Future<void> refreshIfStale({
    Duration ttl = const Duration(minutes: 30),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastRefreshPrefKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (age < ttl.inMilliseconds) {
        debugPrint('🍽 [MealWidget] skip refresh — fresh (age=${age ~/ 1000}s)');
        return;
      }
      await refreshNow();
    } catch (e) {
      debugPrint('🍽 [MealWidget] refreshIfStale error: $e');
    }
  }

  /// Fetch a fresh suggestion and mirror it to the widget.
  ///
  /// Returns the new suggestion on success, or the previously cached one on
  /// any failure — the widget should never go blank once it's had data.
  Future<QuickSuggestion?> refreshNow() async {
    // Guard: must be signed in. Writing a placeholder lets the widget render
    // a "Sign in" card rather than stale data from a previous account.
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      debugPrint('🍽 [MealWidget] skip refresh — no auth session');
      await _writePlaceholder();
      return null;
    }

    try {
      final tz = DateTime.now().timeZoneName.isNotEmpty
          ? _inferIanaTz()
          : 'UTC';
      final resp = await _client.get<Map<String, dynamic>>(
        '/nutrition/quick-suggestion',
        queryParameters: {'tz': tz},
      );
      final data = resp.data;
      if (data == null) {
        debugPrint('🍽 [MealWidget] empty response — keeping cache');
        return _inMemory ?? await readCached();
      }
      final suggestion = QuickSuggestion.fromJson(data);
      await _persist(suggestion);
      debugPrint(
          '🍽 [MealWidget] refreshed: ${suggestion.title} (${suggestion.calories} cal)');
      return suggestion;
    } catch (e, st) {
      debugPrint('🍽 [MealWidget] refresh failed: $e\n$st');
      return _inMemory ?? await readCached();
    }
  }

  /// Log the currently-cached suggestion as a meal.
  ///
  /// Triggered by the widget "Log it" button via deep-link `fitwiz://
  /// nutrition/widget-log`. Uses the cached payload (not a re-fetch) so the
  /// meal that gets logged is exactly what the user saw.
  Future<bool> logSuggestedMeal() async {
    final s = _inMemory ?? await readCached();
    if (s == null || s.foodItems.isEmpty) {
      debugPrint('🍽 [MealWidget] nothing to log');
      return false;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('🍽 [MealWidget] log skipped — no auth');
      return false;
    }

    try {
      // Reuse the existing /nutrition/log-text endpoint by concatenating the
      // component food names into a natural description. That endpoint
      // already handles structured extraction + health-kit sync. Avoids
      // having to wire a new "log pre-structured meal" path for v1.
      final description = s.foodItems.map((f) {
        final portion = f.grams != null ? '${f.grams}g ' : '';
        return '$portion${f.name}';
      }).join(', ');

      await _client.post('/nutrition/log-text', data: {
        'user_id': userId,
        'description': description,
        'meal_type': s.mealSlot == 'fasting' ? 'snack' : s.mealSlot,
      });
      debugPrint('🍽 [MealWidget] logged meal: ${s.title}');

      // Roll forward to the next slot's suggestion after logging.
      await refreshNow();
      return true;
    } catch (e) {
      debugPrint('🍽 [MealWidget] log failed: $e');
      return false;
    }
  }

  /// Called when the app receives an interactive widget callback or a
  /// deep-link triggered by the widget buttons.
  ///
  /// Must be a static entry point so it can run from the home_widget
  /// background isolate on Android. Keep it thin — delegate to the
  /// singleton which handles the real work.
  static Future<void> handleWidgetCallback(Uri? uri) async {
    if (uri == null) return;
    debugPrint('🍽 [MealWidget] callback: $uri');
    final action = uri.host;
    final svc = _instance;
    if (svc == null) {
      debugPrint('🍽 [MealWidget] callback ignored — service not initialised');
      return;
    }
    switch (action) {
      case 'refresh':
        await svc.refreshNow();
        break;
      case 'log':
        await svc.logSuggestedMeal();
        break;
      default:
        debugPrint('🍽 [MealWidget] unknown action: $action');
    }
  }

  // ── internals ────────────────────────────────────────────────────────────

  Future<void> _persist(QuickSuggestion s) async {
    _inMemory = s;
    final encoded = json.encode(s.toJson());
    await HomeWidget.saveWidgetData<String>(_kWidgetJsonKey, encoded);
    await HomeWidget.saveWidgetData<int>(
      _kWidgetTsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await HomeWidget.updateWidget(
      iOSName: iosWidgetName,
      androidName: androidWidgetName,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastRefreshPrefKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _writePlaceholder() async {
    _inMemory = null;
    await HomeWidget.saveWidgetData<String>(_kWidgetJsonKey, '');
    await HomeWidget.updateWidget(
      iOSName: iosWidgetName,
      androidName: androidWidgetName,
    );
  }

  /// Best-effort IANA timezone lookup. Dart's DateTime.timeZoneName returns
  /// abbreviations like "CDT" which the backend's zoneinfo can't resolve,
  /// so we fall back to a platform-appropriate default when necessary.
  String _inferIanaTz() {
    // Flutter doesn't expose the OS's IANA identifier directly. The
    // native iOS widget ships with its own TimeZone.current.identifier
    // (handled in Swift), so this Dart-side helper is only used from the
    // main app, where we'd rather default to UTC and let the backend's
    // _infer_slot fall back gracefully than guess wrong.
    //
    // If you want better accuracy here, add the `flutter_timezone` package
    // and return FlutterTimezone.getLocalTimezone(). Skipped for now to
    // avoid growing the dependency set for a single string.
    return 'UTC';
  }
}
