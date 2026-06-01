/// `dailyCoachInsightProvider` — fetches the Gemini-backed daily coach insight
/// from the backend (`GET /api/v1/coach/daily-insight`).
///
/// Backend handles caching (per-user, per-local-date), cost capping, and
/// ground-truth guardrails (see backend/api/v1/coach/daily_insight.py).
/// Client always renders SOMETHING — when the server is unreachable or
/// returns an error, falls back to the deterministic `coachHeadline()` +
/// `coachBody()` from `score_coach_line.dart` so the hero card never blanks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/today_score.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import 'today_score_provider.dart';
import '../../services/score_coach_line.dart';
import '../../core/providers/timezone_provider.dart';

/// One coach CTA — label + route to navigate to on tap.
class CoachCta {
  final String label;
  final String route;
  const CoachCta({required this.label, required this.route});

  factory CoachCta.fromJson(Map<String, dynamic> json) => CoachCta(
        label: (json['label'] as String?) ?? '',
        route: (json['route'] as String?) ?? '/',
      );
}

/// One quick-reply chip on a daily insight (`chips[]` in the backend
/// contract). Exactly one of [route] / [action] may be set:
///   * [route]  → navigate there on tap (deep link).
///   * [action] → dispatch an existing workout-card action kind (one of
///     log_water_now, log_breakfast, plan_tomorrow_meals, start_wind_down,
///     start_workout_now).
///   * neither  → label-only suggestion; tapping sends [label] as a user
///     chat message.
class InsightChip {
  final String label;
  final String? route;
  final String? action;

  /// Optional action context the backend attaches to a chip (e.g. the injury
  /// recovery check-in carries `body_part` / `injury_id` so the chip handler
  /// knows which injury to act on). Forwarded verbatim into the action payload
  /// on dispatch. Empty for the common route / label-only chips.
  final Map<String, dynamic> actionContext;

  const InsightChip({
    required this.label,
    this.route,
    this.action,
    this.actionContext = const {},
  });

  factory InsightChip.fromJson(Map<String, dynamic> json) {
    String? clean(Object? v) {
      final s = v as String?;
      if (s == null || s.trim().isEmpty) return null;
      return s.trim();
    }

    // Collect any extra string/num context keys (body_part, injury_id, …) the
    // backend attached alongside label/route/action.
    const reserved = {'label', 'route', 'action', 'kind', 'route_or_action'};
    final ctx = <String, dynamic>{};
    json.forEach((k, v) {
      if (!reserved.contains(k) && (v is String || v is num || v is bool)) {
        ctx[k] = v;
      }
    });

    return InsightChip(
      label: (json['label'] as String?)?.trim() ?? '',
      route: clean(json['route']),
      action: clean(json['action']),
      actionContext: ctx,
    );
  }
}

/// The daily coach insight returned by the backend (or built deterministically
/// as a fallback). `isFallback` flags whether the server actually generated
/// this — a small UI indicator can be shown when true.
class DailyCoachInsight {
  /// Server-persisted insight id (UUID). Null on the deterministic
  /// fallback path (the row isn't persisted there). Plan §1c.5 — the
  /// chat seeded coach turn keys on this to dedupe across reopen.
  final String? insightId;
  final String headline;
  final String body;
  final CoachCta? ctaPrimary;
  final CoachCta? ctaSecondary;
  final String leadingPillar; // train | nourish | move | sleep | all_done
  final bool isFallback;

  /// Which open-state surface produced this insight. Mirrors the backend
  /// `source` field: 'greeting' (LIGHT, rotating), 'morning_brief' /
  /// 'evening_recap' (RICH briefing), or 'home' (coach hero card).
  final String source;

  /// Quick-reply chips (`chips[]`). Empty when the backend sent none.
  final List<InsightChip> chips;

  /// Grounded inline graph blocks (`blocks[]`) for a RICH briefing — sleep
  /// ring + recovery signals + steps, rendered by GenericBlocksRenderer.
  /// Empty for light/home sources or when the user has no health data.
  final List<Map<String, dynamic>> blocks;

  const DailyCoachInsight({
    this.insightId,
    required this.headline,
    required this.body,
    this.ctaPrimary,
    this.ctaSecondary,
    required this.leadingPillar,
    this.isFallback = false,
    this.source = 'home',
    this.chips = const [],
    this.blocks = const [],
  });

  /// True when this is a RICH morning/evening briefing (vs a light greeting
  /// or the home card). The chat open-ladder seeds a briefing card only for
  /// these AND only when there is a real multi-line body.
  bool get isRichBriefing =>
      (source == 'morning_brief' || source == 'evening_recap') &&
      body.trim().isNotEmpty;

  /// True when this is the LIGHT time-of-day greeting (deterministic,
  /// rotates each call) used for the living empty state.
  bool get isGreeting => source == 'greeting';

  factory DailyCoachInsight.fromJson(Map<String, dynamic> json) {
    final rawChips = json['chips'];
    final chips = <InsightChip>[];
    if (rawChips is List) {
      for (final c in rawChips) {
        if (c is Map<String, dynamic>) {
          final chip = InsightChip.fromJson(c);
          if (chip.label.isNotEmpty) chips.add(chip);
        }
      }
    }
    final rawBlocks = json['blocks'];
    final blocks = <Map<String, dynamic>>[];
    if (rawBlocks is List) {
      for (final b in rawBlocks) {
        if (b is Map) blocks.add(Map<String, dynamic>.from(b));
      }
    }
    return DailyCoachInsight(
      insightId: json['insight_id'] as String?,
      headline: (json['headline'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      ctaPrimary: json['cta_primary'] is Map<String, dynamic>
          ? CoachCta.fromJson(json['cta_primary'] as Map<String, dynamic>)
          : null,
      ctaSecondary: json['cta_secondary'] is Map<String, dynamic>
          ? CoachCta.fromJson(json['cta_secondary'] as Map<String, dynamic>)
          : null,
      leadingPillar: (json['leading_pillar'] as String?) ?? 'train',
      isFallback: (json['delivery'] as String?) == 'deterministic_fallback' ||
          (json['source'] as String?) == 'deterministic_fallback',
      source: (json['source'] as String?) ?? 'home',
      chips: chips,
      blocks: blocks,
    );
  }
}

/// Args for the family provider — date + tz + source + refresh flag.
class _InsightArgs {
  final DateTime localDate;
  final String tz;
  final String source;
  final bool refresh;
  const _InsightArgs({
    required this.localDate,
    required this.tz,
    this.source = 'home',
    this.refresh = false,
  });

  String get dateString =>
      '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is _InsightArgs &&
      dateString == other.dateString &&
      tz == other.tz &&
      source == other.source &&
      refresh == other.refresh;

  @override
  int get hashCode => Object.hash(dateString, tz, source, refresh);
}

/// Daily coach insight for today, in the user's local timezone. Watching this
/// provider also schedules a refresh when the day rolls over.
///
/// Gates the network call on TWO preconditions:
///   1. The timezone provider has finished initialising (otherwise the request
///      would go out with `tz=UTC` from the default state and the server caches
///      the wrong day's insight).
///   2. A Supabase session exists (otherwise we'd 401 immediately and burn a
///      retry — Dio's auth interceptor only attaches a token when there is
///      one to attach).
/// When either gate is closed we return the deterministic client fallback so
/// the hero card always renders something. Riverpod re-fires the provider
/// when `timezoneProvider` settles, so the real fetch happens then.
final dailyCoachInsightProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) async {
  // Keep alive so leaving/returning Home doesn't tear this down and refetch
  // the coach hero — it's often the FIRST card on Home.
  ref.keepAlive();
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading) {
    return _buildClientFallback(ref);
  }
  if (Supabase.instance.client.auth.currentSession == null) {
    return _buildClientFallback(ref);
  }
  final localDate = DateTime.now();
  final args = _InsightArgs(
    localDate: DateTime(localDate.year, localDate.month, localDate.day),
    tz: tzState.timezone,
    source: 'home',
  );

  // Fresh-cache-first: the disk cache (12h TTL, TZ-rollover aware) backs the
  // coach hero so it paints instantly on a warm start instead of waiting on
  // the network. Only a NON-expired, same-local-day entry is served — an
  // expired one (>12h, or a new calendar day) falls through to the network so
  // the insight refreshes each morning instead of freezing to yesterday's
  // (returning expired here + keepAlive would otherwise never refetch). The
  // REAL response is written through on success.
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final cached = await DataCacheService.instance.getCached(
    DataCacheService.coachInsightKey,
    userId: uid,
  );
  if (cached != null) {
    return DailyCoachInsight.fromJson(cached);
  }

  return _fetchInsight(ref, args, cacheKey: DataCacheService.coachInsightKey);
});

/// Picks the open-state source for Ask Coach based on the user's LOCAL hour:
///   * 05:00–10:59 → `morning_brief` (RICH briefing)
///   * 18:00–21:59 → `evening_recap` (RICH briefing)
///   * otherwise   → `greeting` (LIGHT, rotating)
/// Exposed so the chat open-ladder and tests can reason about the choice.
String chatOpenSourceForHour(int hour) {
  if (hour >= 5 && hour <= 10) return 'morning_brief';
  if (hour >= 18 && hour <= 21) return 'evening_recap';
  return 'greeting';
}

/// Insight for the Ask Coach "living open state". Distinct from the home
/// [dailyCoachInsightProvider] (source=home) so the two caches don't collide
/// and the home coach hero card keeps its own content. Source is chosen by
/// the user's local hour via [chatOpenSourceForHour].
///
/// Same gating as the home provider: wait for the timezone to settle and a
/// Supabase session to exist; otherwise return the deterministic fallback so
/// the open state never blanks. The greeting source rotates server-side on
/// every call, so this provider is `.autoDispose` — each fresh chat open
/// re-fetches a new greeting.
final chatOpenInsightProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) async {
  // NOTE: intentionally NOT keepAlive — the greeting source rotates server-side
  // on every call, so each fresh chat open must re-fetch a new greeting.
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading ||
      Supabase.instance.client.auth.currentSession == null) {
    return _buildClientFallback(ref);
  }
  final now = DateTime.now();
  final args = _InsightArgs(
    localDate: DateTime(now.year, now.month, now.day),
    tz: tzState.timezone,
    source: chatOpenSourceForHour(now.hour),
  );
  return _fetchInsight(ref, args);
});

/// Manual refresh — pass `?refresh=true` to bust the server cache. Use after
/// a workout completion / day-rollover / large meal logged.
final dailyCoachInsightRefreshProvider =
    FutureProvider.autoDispose
        .family<DailyCoachInsight, DateTime>((ref, date) async {
  // NOTE: intentionally NOT keepAlive — this is the manual `refresh=true`
  // cache-buster; pinning it would defeat its purpose.
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading ||
      Supabase.instance.client.auth.currentSession == null) {
    return _buildClientFallback(ref);
  }
  return _fetchInsight(
    ref,
    _InsightArgs(
      localDate: DateTime(date.year, date.month, date.day),
      tz: tzState.timezone,
      source: 'home',
      refresh: true,
    ),
  );
});

Future<DailyCoachInsight> _fetchInsight(Ref ref, _InsightArgs args,
    {String? cacheKey}) async {
  final api = ref.read(apiClientProvider);
  try {
    // NOTE: path is `/coach/daily-insight`, NOT `/api/v1/coach/daily-insight`.
    // The api client's baseUrl already carries `/api/v1`, and Dio 5.9.x
    // merges via plain `baseUrl + path` string concat (then `Uri.normalizePath()`
    // which does NOT collapse repeated segments). Passing `/api/v1/...` here
    // produces `/api/v1/api/v1/...` 404s — verified empirically against
    // dio-5.9.2/lib/src/options.dart line 631.
    final res = await api.get<Map<String, dynamic>>(
      '/coach/daily-insight',
      queryParameters: {
        'date': args.dateString,
        'tz': args.tz,
        'source': args.source,
        if (args.refresh) 'refresh': 'true',
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      // Write-through the REAL response so the next warm start paints instantly
      // from disk. Only the home provider passes a cacheKey.
      if (cacheKey != null) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        await DataCacheService.instance.cache(cacheKey, data, userId: uid);
      }
      return DailyCoachInsight.fromJson(data);
    }
    return _buildClientFallback(ref);
  } catch (_) {
    return _buildClientFallback(ref);
  }
}

/// Client-side deterministic fallback when the server is unreachable. Reuses
/// the existing pool-based `coachHeadline` + `coachBody` so the hero card
/// always renders something coherent.
DailyCoachInsight _buildClientFallback(Ref ref) {
  final score = ref.read(todayScoreProvider);
  final headline = coachHeadline(score) ?? 'Your coach is gathering thoughts.';
  final body = coachBody(score) ??
      'Open a few items on the score card to get a fresh take.';

  // Best-leverage pillar drives the default CTAs.
  ScoreContributor? best;
  double bestGain = 0;
  for (final c in score.applicableContributors) {
    final gain = c.effectiveWeight * (1.0 - c.completion) * 100.0;
    if (gain > bestGain) {
      bestGain = gain;
      best = c;
    }
  }
  final leading = best?.kind.name ?? 'train';
  final ctas = _defaultCtasFor(best?.kind);

  return DailyCoachInsight(
    headline: headline,
    body: body,
    ctaPrimary: ctas.$1,
    ctaSecondary: ctas.$2,
    leadingPillar: leading == 'fuel' ? 'nourish' : leading,
    isFallback: true,
  );
}

(CoachCta, CoachCta) _defaultCtasFor(ContributorKind? kind) {
  // Primary CTA is ALWAYS "Chat with coach" — this IS the coach card, so
  // talking to the coach should be the first action. Secondary CTA stays
  // context-aware. All routes must be real `app_router` paths (verified
  // 2026-05-23) — previous defaults like /workouts/today and /sleep-detail
  // didn't exist and would silently route to chat via the navigate-fallback.
  const chat = CoachCta(label: 'Chat with coach', route: '/chat');
  switch (kind) {
    case ContributorKind.train:
      return (
        chat,
        const CoachCta(label: 'Open workouts', route: '/workouts'),
      );
    case ContributorKind.fuel:
      return (
        chat,
        const CoachCta(label: 'Log meal', route: '/nutrition'),
      );
    case ContributorKind.move:
      return (
        chat,
        const CoachCta(label: 'Add walk', route: '/neat'),
      );
    case ContributorKind.sleep:
      return (
        chat,
        const CoachCta(label: 'Sleep details', route: '/health/sleep'),
      );
    case null:
      return (
        chat,
        const CoachCta(label: 'Open home', route: '/home'),
      );
  }
}
