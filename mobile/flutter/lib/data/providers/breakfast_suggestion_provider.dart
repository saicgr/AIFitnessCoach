/// `breakfastSuggestionProvider` — Gemini-backed personalized breakfast
/// suggestion line for the home nutrition card's morning slot.
///
/// Calls the SAME endpoint as [dailyCoachInsightProvider]
/// (`GET /api/v1/coach/daily-insight`) but with `source=nutrition_card_morning`,
/// which routes through a dedicated prompt (`backend/services/gemini/
/// daily_insight_prompt.py`) that RAGs the user's recent breakfast logs so the
/// returned `body` references their typical pattern (e.g. "oats + eggs hits
/// your 30g target").
///
/// CACHING
/// - The backend persists per `(user_id, local_date, source, stat_context)`,
///   so server-side dedup happens for free.
/// - Client side we add a thin in-memory TTL of 4 hours, keyed by user-local
///   YYYY-MM-DD, scoped to provider lifetime via `autoDispose` +
///   `keepAlive()`. We don't want the 24h home-insight cache here because the
///   breakfast suggestion is only relevant from wakeup → ~11am; a refetch
///   later in the morning (e.g. user reopens the app at 10:30) should pick
///   up any new RAG signal from food logs added since wakeup.
///
/// FALLBACK
/// - On network error, missing session, or pre-tz-init, returns a
///   [DailyCoachInsight] carrying the deterministic copy
///   ("Aim 30g protein + 50g carbs.") with `isFallback=true`. The UI never
///   blocks on the network — it renders the fallback immediately if the
///   request fails. Per Zealova policy fallback is ONLY for the error path,
///   never the primary render path.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/providers/timezone_provider.dart';
import '../services/api_client.dart';
import 'daily_coach_insight_provider.dart';

/// Deterministic copy shown when the server is unreachable. Mirrors the
/// original `_BreakfastSlotRow` literal so behaviour is unchanged on the
/// failure path.
const String kBreakfastSuggestionFallbackBody =
    'Aim 30g protein + 50g carbs.';

/// In-memory TTL cache. Key = `${userId}|${YYYY-MM-DD}`. Value = (timestamp,
/// insight). Lives at module scope so reopening the home tab within the TTL
/// reuses the same response without an HTTP call.
const Duration _kBreakfastInsightTtl = Duration(hours: 4);
final Map<String, _CachedInsight> _kBreakfastInsightCache = {};

class _CachedInsight {
  final DateTime fetchedAt;
  final DailyCoachInsight insight;
  _CachedInsight(this.fetchedAt, this.insight);
}

/// The morning breakfast suggestion for today, in user-local time.
///
/// `autoDispose` so it's released when the user leaves the home tab; the
/// module-level cache holds the last value, so re-subscribing is cheap.
final breakfastSuggestionProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) async {
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading) {
    return _fallback();
  }
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    return _fallback();
  }

  final now = DateTime.now();
  final dateString =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final cacheKey = '${session.user.id}|$dateString';

  final cached = _kBreakfastInsightCache[cacheKey];
  if (cached != null &&
      DateTime.now().difference(cached.fetchedAt) < _kBreakfastInsightTtl) {
    return cached.insight;
  }

  final api = ref.read(apiClientProvider);
  try {
    // Path is `/coach/daily-insight` (NOT `/api/v1/coach/daily-insight`) —
    // the api client baseUrl already carries `/api/v1`. See sibling
    // `daily_coach_insight_provider.dart` for the dio path-merge gotcha.
    final res = await api.get<Map<String, dynamic>>(
      '/coach/daily-insight',
      queryParameters: {
        'date': dateString,
        'tz': tzState.timezone,
        'source': 'nutrition_card_morning',
      },
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return _fallback();
    }
    final insight = DailyCoachInsight.fromJson(data);
    // Only cache real server responses — a fallback shouldn't poison the
    // cache and prevent a real retry on the next render.
    if (!insight.isFallback && insight.body.trim().isNotEmpty) {
      _kBreakfastInsightCache[cacheKey] =
          _CachedInsight(DateTime.now(), insight);
    }
    return insight;
  } catch (_) {
    return _fallback();
  }
});

DailyCoachInsight _fallback() => const DailyCoachInsight(
      headline: 'Breakfast suggestion',
      body: kBreakfastSuggestionFallbackBody,
      leadingPillar: 'nourish',
      isFallback: true,
    );
