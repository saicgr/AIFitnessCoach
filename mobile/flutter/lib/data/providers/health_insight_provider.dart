/// Health-coaching insight provider (Phase C3) — backs the home-screen
/// [HealthInsightCard] and the `BannerType.healthCoaching` banner.
///
/// Hits the three backend proactive-coaching endpoints added in Phase C1:
///   • `GET /insights/{uid}/daily-briefing`  — morning readiness briefing
///   • `GET /insights/{uid}/health-anomaly`  — resting-HR anomaly alert
///   • `GET /insights/{uid}/activity-nudge`  — activity / step-goal nudge
///
/// Each endpoint returns either `{has_message: true, type, pattern, message,
/// facts}` or a clean `{has_message: false, reason}` empty state (no wearable,
/// no consent, nothing to flag).
///
/// Surfacing rules (Phase F edge case 34 — "briefing + anomaly + activity
/// nudge same day → daily cap, briefing has priority"):
///   • the day's single best message is chosen with priority
///     daily_briefing > health_anomaly > activity_nudge;
///   • the card / banner shows ONLY when that message exists AND has not been
///     dismissed today (per-day SharedPreferences key);
///   • any API / loading error self-hides — the failure stays loud in logs
///     (`feedback_no_silent_fallbacks.md`: the error is NOT swallowed into a
///     fake "no message"; it surfaces as an AsyncError the card treats as
///     "hide").
///
/// A 6h SharedPreferences cache keeps the home screen painting instantly and
/// avoids re-hitting three endpoints on every home rebuild. The cache window
/// is short so a briefing dismissed-then-recomputed picture stays current
/// through the day.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// SharedPreferences key for the cached insight payload.
const String _kHealthInsightCacheKey = 'health_insight_cache_v1';

/// SharedPreferences key prefix for per-day dismissal. The full key is
/// `health_insight_dismissed_<localdate>` so the dismissal naturally expires
/// on date rollover and the next day's briefing shows again.
const String _kHealthInsightDismissPrefix = 'health_insight_dismissed_';

/// 6h cache window — short enough that a briefing recomputed after the user's
/// activity sync lands is picked up the same day.
const Duration _healthInsightCacheTtl = Duration(hours: 6);

/// Local-date key (`YYYY-MM-DD`) used for the shared deterministic notif id
/// and the per-day dismissal key. Reasons purely in device-local time per
/// `feedback_user_local_time_only.md`.
String healthInsightLocalDateKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// One proactive health-coaching message resolved for the day.
@immutable
class HealthInsight {
  /// Backend message type: `daily_briefing` | `health_anomaly` |
  /// `activity_nudge`.
  final String type;

  /// Backend pattern key (e.g. `poor_night`, `rhr_elevated`, `behind`).
  final String pattern;

  /// The full human, grounded coaching message — rendered verbatim on the
  /// home card. For a `daily_briefing` this is the Phase-E4 multi-part
  /// cross-domain game plan (sleep readout + workout + nutrition + one swap).
  final String message;

  /// The brief one-line version of [message] — what the notification banner
  /// carries (e.g. "Recovery 41 — lighter session planned, protein +15g. Tap
  /// for today's plan."). Backend `brief_message`; falls back to [message]
  /// for older payloads / non-briefing types where the two are identical.
  final String briefMessage;

  /// The domains the Phase-E4 game plan narrates (`workout`, `nutrition`).
  /// Empty for a good-night briefing, an anomaly, or an activity nudge.
  final List<String> domains;

  const HealthInsight({
    required this.type,
    required this.pattern,
    required this.message,
    String? briefMessage,
    this.domains = const [],
  }) : briefMessage = briefMessage ?? message;

  factory HealthInsight.fromJson(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? '';
    final brief = json['brief_message'] as String?;
    final rawDomains = json['domains'];
    return HealthInsight(
      type: json['type'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      message: message,
      // Fall back to the full message when the backend omits brief_message
      // (older payload, or a type that has no separate brief line).
      briefMessage:
          (brief != null && brief.trim().isNotEmpty) ? brief : message,
      domains: rawDomains is List
          ? rawDomains.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'pattern': pattern,
        'message': message,
        'brief_message': briefMessage,
        'domains': domains,
      };

  /// Priority for picking the day's single message — lower wins.
  /// Briefing > anomaly > activity nudge (Phase F edge case 34).
  int get _priority {
    switch (type) {
      case 'daily_briefing':
        return 0;
      case 'health_anomaly':
        return 1;
      case 'activity_nudge':
        return 2;
      default:
        return 99;
    }
  }

  /// Short human title for the card header + banner + bell entry.
  String get title {
    switch (type) {
      case 'daily_briefing':
        return 'Your readiness today';
      case 'health_anomaly':
        return 'Heads up on your recovery';
      case 'activity_nudge':
        return 'Activity check-in';
      default:
        return 'Health insight';
    }
  }

  /// Deep-link route. The anomaly alert is HR-centric → the Combined Health
  /// hub; the briefing and activity nudge land on the Sleep detail screen
  /// (which carries the expanded readiness / game-plan view).
  String get route {
    switch (type) {
      case 'health_anomaly':
        return '/health/combined';
      default:
        return '/health/sleep';
    }
  }

  /// Shared deterministic id `<type>_<localdate>` so a push and its banner /
  /// card dedupe to ONE notification-bell entry (Phase E edge case 29).
  String get notifId => '${type}_${healthInsightLocalDateKey()}';
}

/// Resolved health-insight state for the home card + banner.
@immutable
class HealthInsightState {
  /// The day's single best message, or null when there is nothing to surface.
  final HealthInsight? insight;

  /// True when the user dismissed today's insight (per-day key).
  final bool dismissedToday;

  const HealthInsightState({this.insight, this.dismissedToday = false});

  /// Empty / "nothing to show" state.
  static const HealthInsightState none = HealthInsightState();

  /// The card / banner renders only when there is a message with copy AND it
  /// has not been dismissed today.
  bool get shouldShow =>
      insight != null &&
      insight!.message.trim().isNotEmpty &&
      !dismissedToday;
}

/// FutureProvider.autoDispose — recomputed when the home screen mounts.
///
/// Resolution order:
///   1. Apply the per-day dismissal gate (a dismissed day self-hides without
///      a network hit beyond the prefs read).
///   2. Read the 6h cache; if fresh, use it.
///   3. Otherwise call the three endpoints, pick the priority message,
///      persist it, and return it.
final healthInsightProvider =
    FutureProvider.autoDispose<HealthInsightState>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final dismissedToday = _isDismissedToday(prefs);

  // 1. 6h cache — cheapest path, no network. Still folds in the dismissal so
  //    a same-day dismiss hides a cached message instantly. A fresh cache
  //    entry with a null insight (a "no message" day) is also a hit, so we
  //    don't re-hit three endpoints on every home rebuild.
  final cached = _readCache(prefs);
  if (cached != null) {
    debugPrint(
        '🩺 [HealthInsight] cache hit — type=${cached.insight?.type ?? "none"}');
    return HealthInsightState(
      insight: cached.insight,
      dismissedToday: dismissedToday,
    );
  }

  // 2. Network. Errors bubble — the provider surfaces AsyncError; the card /
  //    banner treat that as "hide" but the failure stays loud in logs.
  final apiClient = ref.read(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) {
    debugPrint('🩺 [HealthInsight] no user resolved — hiding');
    return HealthInsightState.none;
  }

  final insight = await _fetchBest(apiClient, userId);
  debugPrint('🩺 [HealthInsight] API result — type=${insight?.type ?? "none"}');
  await _writeCache(prefs, insight);
  return HealthInsightState(insight: insight, dismissedToday: dismissedToday);
});

/// Persist a per-day dismissal and invalidate the provider so the card +
/// banner disappear. The next day's insight shows again automatically because
/// the dismissal key is date-scoped.
Future<void> dismissHealthInsight(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(
    '$_kHealthInsightDismissPrefix${healthInsightLocalDateKey()}',
    true,
  );
  debugPrint('🩺 [HealthInsight] dismissed by user for today');
  ref.invalidate(healthInsightProvider);
}

// ─── Internals ───────────────────────────────────────────────────────────────

/// Fetch all three endpoints and return the highest-priority message.
///
/// Each endpoint is independently guarded — one failing (or returning a clean
/// `has_message: false`) never blocks the others. If EVERY endpoint fails,
/// the error is rethrown so the provider surfaces an AsyncError rather than a
/// fake "no message" (`feedback_no_silent_fallbacks.md`).
Future<HealthInsight?> _fetchBest(ApiClient apiClient, String userId) async {
  const paths = <String>[
    '/insights/$_userIdToken/daily-briefing',
    '/insights/$_userIdToken/health-anomaly',
    '/insights/$_userIdToken/activity-nudge',
  ];

  final found = <HealthInsight>[];
  Object? lastError;
  int failures = 0;

  for (final template in paths) {
    final path = template.replaceFirst(_userIdToken, userId);
    try {
      final response = await apiClient.get<Map<String, dynamic>>(path);
      final data = response.data ?? const {};
      if (data['has_message'] == true) {
        final insight = HealthInsight.fromJson(data);
        if (insight.message.trim().isNotEmpty) found.add(insight);
      }
    } catch (e) {
      failures++;
      lastError = e;
      debugPrint('⚠️ [HealthInsight] $path failed: $e');
    }
  }

  // Every endpoint failed → surface the error, don't fake an empty state.
  if (failures == paths.length && lastError != null) {
    throw lastError;
  }

  if (found.isEmpty) return null;
  found.sort((a, b) => a._priority.compareTo(b._priority));
  return found.first;
}

/// Placeholder token replaced with the resolved user id — keeps the path list
/// a `const`.
const String _userIdToken = '{uid}';

/// True when today's insight was dismissed by the user.
bool _isDismissedToday(SharedPreferences prefs) {
  return prefs.getBool(
        '$_kHealthInsightDismissPrefix${healthInsightLocalDateKey()}',
      ) ??
      false;
}

/// A fresh cache hit. [insight] is null on a cached "no message" day — that is
/// still a hit (the network is skipped during the TTL). A `null` _CacheResult
/// (not a result with a null insight) means no usable cache.
class _CacheResult {
  final HealthInsight? insight;
  const _CacheResult(this.insight);
}

/// Returns a [_CacheResult] when a cache entry exists, is within the 6h TTL,
/// and is for today; otherwise null (forcing a network refresh).
_CacheResult? _readCache(SharedPreferences prefs) {
  final raw = prefs.getString(_kHealthInsightCacheKey);
  if (raw == null) return null;
  try {
    final map = json.decode(raw) as Map<String, dynamic>;
    final savedAtIso = map['saved_at'] as String?;
    if (savedAtIso == null) return null;
    final savedAt = DateTime.tryParse(savedAtIso);
    if (savedAt == null) return null;
    if (DateTime.now().difference(savedAt) >= _healthInsightCacheTtl) {
      return null;
    }
    // The cache must also be for TODAY — a stale yesterday cache must never
    // resurface an old briefing past midnight.
    if (map['date'] != healthInsightLocalDateKey()) return null;
    final insightMap = map['insight'];
    if (insightMap is! Map) return const _CacheResult(null);
    final insight = HealthInsight.fromJson(
      Map<String, dynamic>.from(insightMap),
    );
    if (insight.message.trim().isEmpty) return const _CacheResult(null);
    return _CacheResult(insight);
  } catch (e) {
    debugPrint('⚠️ [HealthInsight] cache parse failed, ignoring: $e');
    return null;
  }
}

Future<void> _writeCache(SharedPreferences prefs, HealthInsight? insight) async {
  // A `null` insight is still cached (as an empty marker) so a "no message"
  // day doesn't re-hit three endpoints on every home rebuild.
  final payload = json.encode({
    'saved_at': DateTime.now().toIso8601String(),
    'date': healthInsightLocalDateKey(),
    'insight': insight?.toJson(),
  });
  await prefs.setString(_kHealthInsightCacheKey, payload);
}
