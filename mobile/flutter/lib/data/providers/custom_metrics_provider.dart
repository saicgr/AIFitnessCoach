import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/trends/trend_correlation.dart' show TrendPoint;
import '../repositories/auth_repository.dart';
import '../repositories/metrics_repository.dart';

/// Providers for user-defined custom metrics on the Metrics dashboard.
///
/// Two pieces:
///  * [customMetricsProvider] — the user's custom metric *definitions*.
///  * [customMetricHistoryProvider] — one metric's logged history, already
///    shaped into [TrendPoint]s (ascending by date) so a tile can feed it
///    straight into `StatChange.fromPoints` + `Sparkline`.
///
/// Both read the signed-in user from [authStateProvider] (the same source the
/// trend engine uses) and are `autoDispose` so they refetch on a fresh visit
/// rather than serving a stale session's data. Neither fabricates data: when
/// there is no user they return empty, and the repository surfaces real errors.

/// The user's custom metric definitions. Empty when signed out.
final customMetricsProvider =
    FutureProvider.autoDispose<List<CustomMetricDef>>((ref) async {
  final userId = ref.watch(authStateProvider).user?.id;
  if (userId == null) return const [];
  final repo = ref.watch(metricsRepositoryProvider);
  return repo.listCustomMetrics(userId);
});

/// Parameters for [customMetricHistoryProvider]: which metric and how far back.
class CustomMetricHistoryArgs {
  final String metricId;
  final int days;

  const CustomMetricHistoryArgs(this.metricId, {this.days = 90});

  @override
  bool operator ==(Object other) =>
      other is CustomMetricHistoryArgs &&
      other.metricId == metricId &&
      other.days == days;

  @override
  int get hashCode => Object.hash(metricId, days);
}

/// One custom metric's logged history as date-ascending [TrendPoint]s, ready
/// for `StatChange.fromPoints` and `Sparkline`. Returns an empty list when
/// signed out; the repository throws on a real network failure so the tile can
/// surface it rather than silently degrade.
final customMetricHistoryProvider = FutureProvider.autoDispose
    .family<List<TrendPoint>, CustomMetricHistoryArgs>((ref, args) async {
  final userId = ref.watch(authStateProvider).user?.id;
  if (userId == null) return const [];
  final repo = ref.watch(metricsRepositoryProvider);
  final logs = await repo.customMetricHistory(
    metricId: args.metricId,
    userId: userId,
    days: args.days,
  );
  final points = [for (final l in logs) l.toTrendPoint()]
    ..sort((a, b) => a.date.compareTo(b.date));
  return points;
});
