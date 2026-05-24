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

  const DailyCoachInsight({
    this.insightId,
    required this.headline,
    required this.body,
    this.ctaPrimary,
    this.ctaSecondary,
    required this.leadingPillar,
    this.isFallback = false,
  });

  factory DailyCoachInsight.fromJson(Map<String, dynamic> json) {
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
      isFallback: (json['source'] as String?) == 'deterministic_fallback',
    );
  }
}

/// Args for the family provider — date + tz + refresh flag.
class _InsightArgs {
  final DateTime localDate;
  final String tz;
  final bool refresh;
  const _InsightArgs({
    required this.localDate,
    required this.tz,
    this.refresh = false,
  });

  String get dateString =>
      '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is _InsightArgs &&
      dateString == other.dateString &&
      tz == other.tz &&
      refresh == other.refresh;

  @override
  int get hashCode => Object.hash(dateString, tz, refresh);
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
  );
  return _fetchInsight(ref, args);
});

/// Manual refresh — pass `?refresh=true` to bust the server cache. Use after
/// a workout completion / day-rollover / large meal logged.
final dailyCoachInsightRefreshProvider =
    FutureProvider.autoDispose
        .family<DailyCoachInsight, DateTime>((ref, date) async {
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
      refresh: true,
    ),
  );
});

Future<DailyCoachInsight> _fetchInsight(Ref ref, _InsightArgs args) async {
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
        if (args.refresh) 'refresh': 'true',
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
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
