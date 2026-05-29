import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// API client for the mindfulness pipeline (migration 2214 + api/v1/mindfulness.py).
///
/// Backs the "Mindfulness minutes" key metric. A completed in-app meditation /
/// breathwork session POSTs to `/mindfulness/log`; the home ring and the
/// metrics dashboard card read today's aggregate back from `/mindfulness/today`.
final mindfulnessServiceProvider = Provider<MindfulnessService>((ref) {
  return MindfulnessService(ref.read(apiClientProvider));
});

/// Today's mindful-minutes aggregate.
class MindfulnessToday {
  /// Total minutes logged today (user-local day).
  final int minutes;

  /// Soft daily target (default 10 min).
  final int targetMinutes;

  /// Number of sessions behind [minutes].
  final int sessionCount;

  const MindfulnessToday({
    required this.minutes,
    required this.targetMinutes,
    required this.sessionCount,
  });

  factory MindfulnessToday.fromJson(Map<String, dynamic> json) => MindfulnessToday(
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
        targetMinutes: (json['target_minutes'] as num?)?.toInt() ?? 10,
        sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      );

  MindfulnessToday copyWith({int? minutes}) => MindfulnessToday(
        minutes: minutes ?? this.minutes,
        targetMinutes: targetMinutes,
        sessionCount: sessionCount,
      );

  /// Fraction of target reached, clamped 0..1 (the ring never overfills even
  /// when the user beats the goal — plan edge case Q).
  double get progress =>
      targetMinutes > 0 ? (minutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

  bool get goalMet => targetMinutes > 0 && minutes >= targetMinutes;
}

/// One day's mindful minutes for the sparkline.
class MindfulnessDayPoint {
  final DateTime date;
  final int minutes;

  const MindfulnessDayPoint({required this.date, required this.minutes});

  factory MindfulnessDayPoint.fromJson(Map<String, dynamic> json) =>
      MindfulnessDayPoint(
        date: DateTime.parse(json['date'] as String),
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}

class MindfulnessService {
  final ApiClient _apiClient;

  MindfulnessService(this._apiClient);

  /// Today's total mindful minutes (in-app log aggregate). Returns null on a
  /// non-200 so the provider can show an honest error state — never a fake 0.
  Future<MindfulnessToday?> getToday(String userId) async {
    final response = await _apiClient.get('/mindfulness/today/$userId');
    if (response.statusCode == 200 && response.data != null) {
      return MindfulnessToday.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Per-day minutes for the sparkline (zero-filled to exactly [days] points,
  /// ending today — date-true x-axis, gaps render as gaps).
  Future<List<MindfulnessDayPoint>> getHistory(String userId,
      {int days = 7}) async {
    final response = await _apiClient.get(
      '/mindfulness/history/$userId',
      queryParameters: {'days': days},
    );
    if (response.statusCode == 200 && response.data != null) {
      final list =
          (response.data as Map<String, dynamic>)['days'] as List<dynamic>? ??
              const [];
      return list
          .map((e) => MindfulnessDayPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Record a completed session. Returns today's running total so the caller
  /// can reconcile the ring without a second round-trip.
  Future<MindfulnessToday?> logSession({
    required String source,
    String? meditationSlug,
    required int durationSeconds,
  }) async {
    final response = await _apiClient.post('/mindfulness/log', data: {
      'source': source,
      if (meditationSlug != null) 'meditation_slug': meditationSlug,
      'duration_seconds': durationSeconds,
    });
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data != null) {
      return MindfulnessToday.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }
}
