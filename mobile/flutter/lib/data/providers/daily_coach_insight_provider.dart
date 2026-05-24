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
  final String headline;
  final String body;
  final CoachCta? ctaPrimary;
  final CoachCta? ctaSecondary;
  final String leadingPillar; // train | nourish | move | sleep | all_done
  final bool isFallback;

  const DailyCoachInsight({
    required this.headline,
    required this.body,
    this.ctaPrimary,
    this.ctaSecondary,
    required this.leadingPillar,
    this.isFallback = false,
  });

  factory DailyCoachInsight.fromJson(Map<String, dynamic> json) {
    return DailyCoachInsight(
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
final dailyCoachInsightProvider =
    FutureProvider.autoDispose<DailyCoachInsight>((ref) async {
  final tz = ref.watch(timezoneProvider).timezone;
  // Today in the user's local tz — server keys cache by this date.
  final localDate = DateTime.now();
  final args = _InsightArgs(
    localDate: DateTime(localDate.year, localDate.month, localDate.day),
    tz: tz,
  );
  return _fetchInsight(ref, args);
});

/// Manual refresh — pass `?refresh=true` to bust the server cache. Use after
/// a workout completion / day-rollover / large meal logged.
final dailyCoachInsightRefreshProvider =
    FutureProvider.autoDispose
        .family<DailyCoachInsight, DateTime>((ref, date) async {
  final tz = ref.watch(timezoneProvider).timezone;
  return _fetchInsight(
    ref,
    _InsightArgs(
      localDate: DateTime(date.year, date.month, date.day),
      tz: tz,
      refresh: true,
    ),
  );
});

Future<DailyCoachInsight> _fetchInsight(Ref ref, _InsightArgs args) async {
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get<Map<String, dynamic>>(
      '/api/v1/coach/daily-insight',
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
  switch (kind) {
    case ContributorKind.train:
      return (
        const CoachCta(label: 'Start workout', route: '/workouts/today'),
        const CoachCta(label: 'See plan', route: '/workouts/today'),
      );
    case ContributorKind.fuel:
      return (
        const CoachCta(label: 'Log meal', route: '/nutrition/log'),
        const CoachCta(label: 'See plan', route: '/nutrition'),
      );
    case ContributorKind.move:
      return (
        const CoachCta(label: 'Add walk', route: '/neat'),
        const CoachCta(label: 'See plan', route: '/neat'),
      );
    case ContributorKind.sleep:
      return (
        const CoachCta(label: 'Sleep tonight', route: '/sleep-detail'),
        const CoachCta(label: 'See plan', route: '/sleep-detail'),
      );
    case null:
      return (
        const CoachCta(label: 'Open today', route: '/'),
        const CoachCta(label: 'See plan', route: '/workouts/today'),
      );
  }
}
