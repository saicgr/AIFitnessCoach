/// `rhrDeltaProvider` — fetches today's resting heart rate vs the user's
/// 14-day baseline (`GET /api/v1/health/rhr-delta`).
///
/// Feeds the F3.120 RhrDeltaCard. The card self-collapses when no RHR
/// signal is available; provider returns null on any failure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../services/api_client.dart';

class RhrDelta {
  final int? todayRhrBpm;
  final double? baselineRhrBpm;
  final double? deltaBpm;
  final int daysObserved;

  /// Backend-computed: delta >= 3bpm for 2 consecutive days (today + yest).
  final bool elevated;

  const RhrDelta({
    required this.todayRhrBpm,
    required this.baselineRhrBpm,
    required this.deltaBpm,
    required this.daysObserved,
    required this.elevated,
  });

  /// Whether the card has enough data to render meaningfully — both today
  /// and the baseline must be present.
  bool get hasSignal =>
      todayRhrBpm != null && baselineRhrBpm != null && daysObserved >= 3;

  factory RhrDelta.fromJson(Map<String, dynamic> json) => RhrDelta(
        todayRhrBpm: (json['today_rhr_bpm'] as num?)?.toInt(),
        baselineRhrBpm: (json['baseline_rhr_bpm'] as num?)?.toDouble(),
        deltaBpm: (json['delta_bpm'] as num?)?.toDouble(),
        daysObserved: (json['days_observed'] as num?)?.toInt() ?? 0,
        elevated: (json['elevated'] as bool?) ?? false,
      );
}

final rhrDeltaProvider = FutureProvider.autoDispose<RhrDelta?>((ref) async {
  if (Supabase.instance.client.auth.currentSession == null) return null;
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get<Map<String, dynamic>>('/health/rhr-delta');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return RhrDelta.fromJson(data);
  } catch (_) {
    return null;
  }
});
