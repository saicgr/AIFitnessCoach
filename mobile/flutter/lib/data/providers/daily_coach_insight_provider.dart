/// `dailyCoachInsightProvider` — fetches the Gemini-backed daily coach insight
/// from the backend (`GET /api/v1/coach/daily-insight`).
///
/// Backend handles caching (per-user, per-local-date), cost capping, and
/// ground-truth guardrails (see backend/api/v1/coach/daily_insight.py).
/// Client always renders SOMETHING — when the server is unreachable or
/// returns an error, falls back to the deterministic `coachHeadline()` +
/// `coachBody()` from `score_coach_line.dart` so the hero card never blanks.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/today_score.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import 'today_score_provider.dart';
import '../../core/services/sentry_service.dart';
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

  /// Optional pre-seeded chat prompt. When set (and no route/action), tapping
  /// the chip deep-links into the coach chat with this exact message auto-sent
  /// (via `?prompt=`), rather than sending the visible [label]. Lets a short
  /// label ("Recovery fuel") send a fuller request. Null for ordinary chips.
  final String? prompt;

  /// Optional action context the backend attaches to a chip (e.g. the injury
  /// recovery check-in carries `body_part` / `injury_id` so the chip handler
  /// knows which injury to act on). Forwarded verbatim into the action payload
  /// on dispatch. Empty for the common route / label-only chips.
  final Map<String, dynamic> actionContext;

  const InsightChip({
    required this.label,
    this.route,
    this.action,
    this.prompt,
    this.actionContext = const {},
  });

  factory InsightChip.fromJson(Map<String, dynamic> json) {
    String? clean(Object? v) {
      final s = v as String?;
      if (s == null || s.trim().isEmpty) return null;
      return s.trim();
    }

    // Collect any extra string/num context keys (body_part, injury_id, …) the
    // backend attached alongside label/route/action. `prompt` is reserved
    // (handled below) so it never leaks into the action context.
    const reserved = {
      'label', 'route', 'action', 'kind', 'route_or_action', 'prompt',
    };
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
      prompt: clean(json['prompt']),
      actionContext: ctx,
    );
  }
}

/// The daily coach insight returned by the backend (or built deterministically
/// as a fallback). `isFallback` flags whether the server actually generated
/// this — a small UI indicator can be shown when true.
/// Proactive "Coach noticed" card (Dr-Yaad audit #2) — a concrete,
/// injury-aware observation + the adjustment the engine made, with an Accept
/// action. Null when the backend surfaced nothing worth a prominent card.
class CoachNoticed {
  final String title;
  final String body;
  final String? bodyPart;
  final String? phase;
  final String? action; // e.g. 'adjust_today_workout' (Phase 2 apply-action)
  final String acceptLabel;
  final String dismissLabel;
  final String? chatSeed;

  const CoachNoticed({
    required this.title,
    required this.body,
    this.bodyPart,
    this.phase,
    this.action,
    this.acceptLabel = 'Adjust',
    this.dismissLabel = 'Talk more',
    this.chatSeed,
  });

  factory CoachNoticed.fromJson(Map<String, dynamic> json) => CoachNoticed(
        title: (json['title'] as String?) ?? 'Coach noticed',
        body: (json['body'] as String?) ?? '',
        bodyPart: json['body_part'] as String?,
        phase: json['phase'] as String?,
        action: json['action'] as String?,
        acceptLabel: (json['accept_label'] as String?) ?? 'Adjust',
        dismissLabel: (json['dismiss_label'] as String?) ?? 'Talk more',
        chatSeed: json['chat_seed'] as String?,
      );
}

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

  /// Proactive "Coach noticed" card (Dr-Yaad audit #2). Null when absent.
  final CoachNoticed? coachNoticed;

  /// True on the HOME card when today warrants proactively surfacing
  /// recovery-nutrition (server `recovery_focus`). The card then renders the
  /// recovery-fuel chip and auto-reveals the nutrition context inline instead
  /// of leaving it behind the collapsed TRENDS header.
  final bool recoveryFocus;

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
    this.coachNoticed,
    this.recoveryFocus = false,
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
      coachNoticed: json['coach_noticed'] is Map<String, dynamic>
          ? CoachNoticed.fromJson(json['coach_noticed'] as Map<String, dynamic>)
          : null,
      recoveryFocus: json['recovery_focus'] == true,
    );
  }
}

/// Args for the family provider — date + tz + source + refresh/fresh flags.
class _InsightArgs {
  final DateTime localDate;
  final String tz;
  final String source;

  /// `refresh=true` → server regenerates the AI text (headline/body),
  /// bypassing the per-day text cache. Expensive (a Gemini call).
  final bool refresh;

  /// `fresh=true` → server recomputes the grounded graph blocks fresh from the
  /// DB (bypassing its 120s block memo) WITHOUT regenerating the AI text. Cheap
  /// — used after a log so the numbers update instantly while the text stays.
  final bool fresh;

  const _InsightArgs({
    required this.localDate,
    required this.tz,
    this.source = 'home',
    this.refresh = false,
    this.fresh = false,
  });

  String get dateString =>
      '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is _InsightArgs &&
      dateString == other.dateString &&
      tz == other.tz &&
      source == other.source &&
      refresh == other.refresh &&
      fresh == other.fresh;

  @override
  int get hashCode => Object.hash(dateString, tz, source, refresh, fresh);
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
  // Gate REACTIVELY on auth + timezone. Watching `authStateProvider` (instead
  // of a one-shot `Supabase…currentSession` read) is the fix for the
  // freeze-on-fallback bug: if this first evaluates during the cold-start
  // window — timezone already resolved from cache but the Supabase session not
  // yet restored (e.g. via MainShell's prewarm read) — we return the
  // deterministic fallback, and previously `ref.keepAlive()` PINNED that
  // fallback for the whole app session because nothing re-fired. Now the
  // provider re-runs the moment auth transitions to `authenticated` and fetches
  // the real, data-grounded insight.
  //
  // keepAlive is deliberately DEFERRED to a successful fetch (cache hit below /
  // `_fetchInsight` on a real response). A gate-not-ready or network-error
  // fallback is never pinned — it stays autoDispose so the next watch retries.
  //
  // Gate on the presence of a USER (user?.id), NOT on status == authenticated.
  // AuthNotifier flips status to `loading` on every background refresh while
  // KEEPING the user (copyWith preserves it), so a status-based gate returns
  // the fallback during those windows even though the session + token are valid
  // (every other authed data provider — consistency, contextual_nudge — gates
  // on user?.id and works on-device, which is why ONLY the coach card fell back).
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading || userId == null || userId.isEmpty) {
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
    // A real, previously-fetched insight — pin it so leaving/returning Home
    // doesn't tear it down and refetch (it's often the FIRST card on Home).
    ref.keepAlive();
    return DailyCoachInsight.fromJson(cached);
  }

  return _fetchInsight(ref, args, cacheKey: DataCacheService.coachInsightKey);
});

/// Historical coach insight for a SPECIFIC past day, used by the Home timeline
/// to replay "the tip that fired that day". Returns null when no insight was
/// recorded for [day] — the backend 404s past dates with no stored row (see the
/// historical-date guard in daily_insight.py). It deliberately does NOT fall
/// back to a client-synthesized insight: a made-up tip for a past day would be
/// a lie. `.family` by day, kept alive so scrolling the timeline doesn't refetch.
final coachInsightForDateProvider = FutureProvider.autoDispose
    .family<DailyCoachInsight?, DateTime>((ref, day) async {
  ref.keepAlive();
  if (Supabase.instance.client.auth.currentSession == null) return null;
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading) return null;
  final d = DateTime(day.year, day.month, day.day);
  final dateStr =
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      '/coach/daily-insight',
      queryParameters: {
        'date': dateStr,
        'tz': tzState.timezone,
        'source': 'home',
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      // Past days with no recorded tip return a 200 with delivery="none" and a
      // blank headline/body (the backend stopped 404ing these — see the
      // historical-date guard in daily_insight.py). Treat that as "no tip".
      if ((data['delivery'] as String?) == 'none') return null;
      final insight = DailyCoachInsight.fromJson(data);
      if (insight.headline.trim().isEmpty && insight.body.trim().isEmpty) {
        return null;
      }
      return insight;
    }
    return null;
  } catch (_) {
    // 404 (legacy clients / transient error) → no historical tip.
    return null;
  }
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
/// the open state never blanks. All three sources are served cache-first with
/// stale-while-revalidate (rich briefings 12h, light greeting 90m): a warm open
/// paints instantly AND a background refresh rotates the value for the next
/// open, so it's instant without going stale. `.autoDispose` so each open
/// re-runs and picks up the freshly-revalidated cache.
final chatOpenInsightProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) async {
  // NOTE: autoDispose (not keepAlive) so each open re-runs and reads the
  // freshly-revalidated disk cache. All three sources are served cache-first
  // below (see cacheKey) with stale-while-revalidate — a warm re-open paints
  // instantly instead of blocking 5-10s on the Gemini round-trip every time.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading || userId == null || userId.isEmpty) {
    return _buildClientFallback(ref);
  }
  final now = DateTime.now();
  final source = chatOpenSourceForHour(now.hour);
  final args = _InsightArgs(
    localDate: DateTime(now.year, now.month, now.day),
    tz: tzState.timezone,
    source: source,
  );

  // Cache-first for ALL three sources (mirrors dailyCoachInsightProvider). The
  // rich briefings use a 12h TTL; the light `greeting` uses a short 90m TTL
  // (DataCacheService.chatGreetingKey). On a cache hit we paint instantly AND
  // kick a background revalidation (see below), so the greeting is both instant
  // and rotates every open — the 90m TTL only bounds the worst-case STALE paint
  // (e.g. after a long idle) before a blocking refetch. A non-expired,
  // same-local-day cached value paints instantly; the REAL response is written
  // through on success by _fetchInsight.
  final cacheKey = source == 'morning_brief'
      ? DataCacheService.chatMorningBriefKey
      : source == 'evening_recap'
          ? DataCacheService.chatEveningRecapKey
          : DataCacheService.chatGreetingKey;
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final cached = await DataCacheService.instance.getCached(
    cacheKey,
    userId: uid,
  );
  if (cached != null) {
    // Stale-while-revalidate: paint the cached value INSTANTLY, then silently
    // revalidate in the background so the NEXT open rotates — instant AND
    // fresh, instead of trading one for the other. _fetchInsight reads
    // apiClientProvider synchronously (before its first await) and, with
    // pin:false, never calls ref.keepAlive() — so the refresh captures what it
    // needs now and survives this autoDispose provider tearing down once it has
    // returned the cached value below. The background write only touches the
    // disk cache; the current view keeps the value it already painted (no
    // jarring mid-view swap), and the freshly-written greeting surfaces on the
    // next open. Failures are swallowed — the cached greeting we returned
    // stands and the next open retries.
    unawaited(() async {
      try {
        await _fetchInsight(ref, args, cacheKey: cacheKey, pin: false);
      } catch (_) {/* transient/offline — keep the cached greeting */}
    }());
    return DailyCoachInsight.fromJson(cached);
  }

  return _fetchInsight(ref, args, cacheKey: cacheKey);
});

/// TEXT refresh — `?refresh=true&fresh=true`: server regenerates the AI
/// headline/body (Gemini) AND recomputes the graph blocks fresh. Use after a
/// completion-class event (workout finished, fast ended, sleep logged, first
/// meal) and on the manual long-press / ⋮ refresh.
///
/// Crucially this WRITES THROUGH to the home disk cache (cacheKey +
/// `pin:false`): the prior implementation passed no cacheKey, so after the
/// caller did `ref.invalidate(dailyCoachInsightProvider)` the main provider
/// re-read the UNCHANGED 12h disk cache and the regenerated text never showed.
/// Writing through means the follow-up invalidate surfaces the fresh payload.
/// `pin:false` keeps the main provider the single pinned listener.
final dailyCoachInsightRefreshProvider =
    FutureProvider.autoDispose
        .family<DailyCoachInsight, DateTime>((ref, date) async {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading || userId == null || userId.isEmpty) {
    return _buildClientFallback(ref);
  }
  return _fetchInsight(
    ref,
    _InsightArgs(
      localDate: DateTime(date.year, date.month, date.day),
      tz: tzState.timezone,
      source: 'home',
      refresh: true,
      fresh: true,
    ),
    cacheKey: DataCacheService.coachInsightKey,
    pin: false,
  );
});

/// NUMBERS refresh — `?fresh=true` only: server recomputes the grounded graph
/// blocks fresh from the DB but returns the CACHED AI text (no Gemini call, no
/// cost). Use after every log so the graphs reflect the new data instantly.
/// Like the text refresh it write-throughs the home disk cache (pin:false) so a
/// follow-up `ref.invalidate(dailyCoachInsightProvider)` surfaces fresh blocks.
final dailyCoachInsightNumbersRefreshProvider =
    FutureProvider.autoDispose
        .family<DailyCoachInsight, DateTime>((ref, date) async {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading || userId == null || userId.isEmpty) {
    return _buildClientFallback(ref);
  }
  return _fetchInsight(
    ref,
    _InsightArgs(
      localDate: DateTime(date.year, date.month, date.day),
      tz: tzState.timezone,
      source: 'home',
      fresh: true,
    ),
    cacheKey: DataCacheService.coachInsightKey,
    pin: false,
  );
});

Future<DailyCoachInsight> _fetchInsight(Ref ref, _InsightArgs args,
    {String? cacheKey, bool pin = true}) async {
  final api = ref.read(apiClientProvider);
  // Up to 2 attempts. The retry exists because the most likely on-device
  // failure is a TRANSIENT one — a stale access token mid-refresh at cold
  // start, or a just-deployed/cold backend — which a ~1.5s backoff lets
  // settle (the auth interceptor refreshes the token on a 401 in between).
  // We deliberately do NOT retry a receiveTimeout (it would double a 30s
  // stall) or a 200-with-non-map body (a retry won't change the shape).
  DioException? lastErr;
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      // NOTE: path is `/coach/daily-insight`, NOT `/api/v1/coach/daily-insight`.
      // The api client's baseUrl already carries `/api/v1`, and Dio 5.9.x
      // merges via plain `baseUrl + path` string concat (then
      // `Uri.normalizePath()` which does NOT collapse repeated segments).
      // Passing `/api/v1/...` here produces `/api/v1/api/v1/...` 404s.
      final res = await api.get<Map<String, dynamic>>(
        '/coach/daily-insight',
        queryParameters: {
          'date': args.dateString,
          'tz': args.tz,
          'source': args.source,
          if (args.refresh) 'refresh': 'true',
          if (args.fresh) 'fresh': 'true',
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        // Write-through the REAL response so the next warm start paints
        // instantly from disk. Only callers that pass a cacheKey persist.
        // GUARD: never write a server FALLBACK payload (delivery=
        // deterministic_fallback — e.g. Gemini cost-capped / timed out) over a
        // good cached insight. On a text refresh that gets capped we keep the
        // prior cached AI text rather than downgrading it to a template.
        final isServerFallback =
            (data['delivery'] as String?) == 'deterministic_fallback';
        if (cacheKey != null && !isServerFallback) {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          await DataCacheService.instance.cache(cacheKey, data, userId: uid);
          // Pin only when asked (the main home provider). The numbers/text
          // write-through refreshers pass pin:false — they only need the disk
          // write, and the main provider stays the single pinned listener.
          if (pin) ref.keepAlive();
        }
        return DailyCoachInsight.fromJson(data);
      }
      // 200 but the body wasn't a JSON map — a retry won't fix the shape.
      if (kDebugMode) {
        debugPrint('⚠️ [coach-insight] HTTP ${res.statusCode} but body is '
            '${data.runtimeType}, not a JSON map — using fallback');
      }
      unawaited(SentryService.captureMessage(
        'coach daily-insight: non-map 200 body',
        tags: {'surface': 'daily_insight'},
      ));
      break;
    } on DioException catch (e) {
      lastErr = e;
      final status = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint('❌ [coach-insight] attempt ${attempt + 1}/2 failed: '
            'status=$status type=${e.type.name} msg=${e.message}');
      }
      final retryable = e.type != DioExceptionType.receiveTimeout &&
          e.type != DioExceptionType.sendTimeout;
      if (attempt == 0 && retryable) {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        continue;
      }
      break;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [coach-insight] unexpected error: $e');
      }
      break;
    }
  }
  // Surface the real cause (the catch used to swallow it, and 401s are excluded
  // from Sentry's Dio auto-capture) so we can see WHY the device falls back.
  if (lastErr != null) {
    unawaited(SentryService.captureError(
      lastErr,
      lastErr.stackTrace,
      hint: 'coach daily-insight fetch failed (after retry)',
      tags: {
        'surface': 'daily_insight',
        'http_status': '${lastErr.response?.statusCode ?? 'none'}',
        'dio_type': lastErr.type.name,
      },
    ));
  }
  return _buildClientFallback(ref);
}

/// Client-side deterministic fallback when the server is unreachable. Reuses
/// the existing pool-based `coachHeadline` + `coachBody` so the hero card
/// always renders something coherent.
DailyCoachInsight _buildClientFallback(Ref ref) {
  final score = ref.read(todayScoreProvider);
  // Personalize the offline fallback with the user's real first name (watched
  // so it fills in the moment auth resolves). Without this the fallback read
  // "Eat your way back on track, You." — the literal "You" was the giveaway
  // that the card was on the fallback path, not the server insight.
  final fullName = ref.watch(authStateProvider.select((s) => s.user?.name));
  final firstName = (fullName ?? '').trim().split(RegExp(r'\s+')).first;
  final fn = firstName.isEmpty ? null : firstName;
  final headline = coachHeadline(score, firstName: fn) ??
      'Your coach is gathering thoughts.';
  final body = coachBody(score, firstName: fn) ??
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
