import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'trend_correlation.dart';

/// =========================================================================
/// TrendAiInsightCard — AI analysis of the metrics currently on the chart
/// =========================================================================
///
/// Posts the exact series the Custom Trends screen is displaying to
/// `POST /insights/{user_id}/trend-analysis` (Gemini-backed) and renders a
/// concise plain-English read: direction, notable changes, and — when overlay
/// metrics are present — whether they move together or oppositely.
///
/// Honest by design: it never fabricates. With <3 days of data the backend
/// returns a "keep logging" message; on failure this card shows a retry.

/// One series, ready to ship to the analysis endpoint.
class TrendInsightSeries {
  final String label;
  final String unit;
  final bool isPrimary;
  final List<TrendPoint> points;

  const TrendInsightSeries({
    required this.label,
    required this.unit,
    required this.isPrimary,
    required this.points,
  });
}

/// Immutable request payload — also the cache key for [_trendInsightProvider].
@immutable
class TrendInsightRequest {
  final String rangeLabel;
  final List<TrendInsightSeries> series;
  final Map<String, int> events;
  final Map<String, double> correlations;

  const TrendInsightRequest({
    required this.rangeLabel,
    required this.series,
    this.events = const {},
    this.correlations = const {},
  });

  /// Stable shape signature — drives provider caching so we don't re-call
  /// Gemini on every rebuild, only when the displayed data actually changes.
  String get _signature {
    final s = series
        .map((e) => '${e.label}:${e.points.length}:${e.isPrimary}')
        .join(';');
    final c = (correlations.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value.toStringAsFixed(2)}')
        .join(',');
    final ev = (events.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join(',');
    return '$rangeLabel|$s|$c|$ev';
  }

  @override
  bool operator ==(Object other) =>
      other is TrendInsightRequest && other._signature == _signature;

  @override
  int get hashCode => _signature.hashCode;
}

/// Fetches a Gemini-backed insight for the requested trend shape.
final _trendInsightProvider = FutureProvider.family
    .autoDispose<String, TrendInsightRequest>((ref, req) async {
  final auth = ref.watch(authStateProvider);
  final userId = auth.user?.id;
  if (userId == null) {
    throw Exception('Sign in to see AI insights.');
  }
  final client = ref.read(apiClientProvider);
  final response = await client.post(
    '/insights/$userId/trend-analysis',
    data: {
      'range_label': req.rangeLabel,
      'series': [
        for (final s in req.series)
          {
            'label': s.label,
            'unit': s.unit,
            'is_primary': s.isPrimary,
            'points': [
              for (final p in s.points)
                [
                  p.date.toIso8601String().split('T').first,
                  double.parse(p.value.toStringAsFixed(2)),
                ],
            ],
          },
      ],
      'events': req.events,
      'correlations': req.correlations,
    },
  );
  final data = response.data;
  final insight =
      (data is Map ? data['insight'] : null) as String? ?? '';
  if (insight.trim().isEmpty) {
    throw Exception('No insight returned.');
  }
  return insight.trim();
});

/// The AI Insight card rendered below the chart + controls.
class TrendAiInsightCard extends ConsumerWidget {
  final TrendInsightRequest request;

  const TrendAiInsightCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final async = ref.watch(_trendInsightProvider(request));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: 0.12),
            colors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 16, color: colors.accent),
              ),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).trendAiInsightAiInsight,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary)),
              const Spacer(),
              if (!async.isLoading)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    ref.invalidate(_trendInsightProvider(request));
                  },
                  child: Icon(Icons.refresh_rounded,
                      size: 18, color: colors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => _loading(context, colors),
            error: (e, _) => _error(context, colors, ref),
            data: (insight) => Text(
              insight,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading(BuildContext context, ThemeColors colors) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(colors.accent),
          ),
        ),
        const SizedBox(width: 10),
        Text(AppLocalizations.of(context)!.trendAiInsightReadingYourTrends,
            style: TextStyle(fontSize: 13, color: colors.textMuted)),
      ],
    );
  }

  Widget _error(BuildContext context, ThemeColors colors, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.trendAiInsightCouldnTGenerateAn,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            HapticService.light();
            ref.invalidate(_trendInsightProvider(request));
          },
          style: TextButton.styleFrom(foregroundColor: colors.accent),
          child: Text(AppLocalizations.of(context)!.buttonRetry),
        ),
      ],
    );
  }
}
