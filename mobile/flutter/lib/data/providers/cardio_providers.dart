import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cardio_log.dart';
import '../repositories/cardio_log_repository.dart';
import '../services/api_client.dart';

/// Riverpod providers for the cardio-logs feature (see
/// `backend/api/v1/cardio_logs.py`). Deliberately kept minimal — the
/// history screen drives its own filter state locally and passes the
/// params into `cardioLogsProvider.family`, so we don't need a
/// StateNotifier for basic list rendering.

final cardioLogRepositoryProvider = Provider<CardioLogRepository>((ref) {
  return CardioLogRepository(ref.watch(apiClientProvider));
});

/// Filter parameters for a cardio history query. Using a dedicated class
/// keeps the `.family` parameter hashable + equatable so two identical
/// queries share the cached result (Riverpod dedupes on equality).
class CardioLogsFilter {
  final String userId;
  final String? activityType;
  final DateTime? from;
  final DateTime? to;
  final int limit;

  const CardioLogsFilter({
    required this.userId,
    this.activityType,
    this.from,
    this.to,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioLogsFilter &&
          other.userId == userId &&
          other.activityType == activityType &&
          other.from == from &&
          other.to == to &&
          other.limit == limit);

  @override
  int get hashCode => Object.hash(userId, activityType, from, to, limit);
}

/// Paginated list of cardio sessions matching a filter.
///
/// Pass a filter via `ref.watch(cardioLogsProvider(filter))`. Adding
/// `.autoDispose` keeps the cache out of memory when the history screen
/// isn't mounted — important because a 5-year Strava import can easily
/// produce 1000+ rows.
final cardioLogsProvider = FutureProvider.autoDispose
    .family<List<CardioLog>, CardioLogsFilter>((ref, filter) async {
  final repo = ref.watch(cardioLogRepositoryProvider);
  return repo.getUserCardioLogs(
    userId: filter.userId,
    activityType: filter.activityType,
    from: filter.from,
    to: filter.to,
    limit: filter.limit,
  );
});

/// Aggregated summary for the given user. Lightweight (single row
/// response) — safe to watch from the home screen and the cardio screen.
final cardioSummaryProvider = FutureProvider.autoDispose
    .family<CardioSummary, String>((ref, userId) async {
  final repo = ref.watch(cardioLogRepositoryProvider);
  return repo.getSummary(userId);
});
