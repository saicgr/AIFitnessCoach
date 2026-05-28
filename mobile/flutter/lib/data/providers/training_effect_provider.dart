/// `trainingEffectProvider` — fetches Garmin-style aerobic + anaerobic
/// training effect scores for a completed workout
/// (`GET /api/v1/workouts/{workout_id}/training-effect`).
///
/// Feeds the F3.111 TrainingEffectCard. The card self-collapses when no
/// signal is available; we therefore return null on any failure rather than
/// throwing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../services/api_client.dart';

class TrainingEffect {
  final String workoutId;
  final double? aerobic; // 1.0-5.0, null when HR data missing
  final double anaerobic; // 1.0-5.0
  final double strainDelta; // minutes vs 14-day mean (signed)
  final String primaryBenefit; // tempo | strength | endurance | recovery

  const TrainingEffect({
    required this.workoutId,
    required this.aerobic,
    required this.anaerobic,
    required this.strainDelta,
    required this.primaryBenefit,
  });

  factory TrainingEffect.fromJson(Map<String, dynamic> json) => TrainingEffect(
        workoutId: (json['workout_id'] as String?) ?? '',
        aerobic: (json['aerobic'] as num?)?.toDouble(),
        anaerobic: (json['anaerobic'] as num?)?.toDouble() ?? 1.0,
        strainDelta: (json['strain_delta'] as num?)?.toDouble() ?? 0.0,
        primaryBenefit:
            (json['primary_benefit'] as String?) ?? 'recovery',
      );
}

/// Family-keyed on workout_id (the parent `workouts.id`, not workout_log id).
final trainingEffectProvider = FutureProvider.autoDispose
    .family<TrainingEffect?, String>((ref, workoutId) async {
  if (workoutId.isEmpty) return null;
  if (Supabase.instance.client.auth.currentSession == null) return null;
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get<Map<String, dynamic>>(
      '/workouts/$workoutId/training-effect',
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return TrainingEffect.fromJson(data);
  } catch (_) {
    return null;
  }
});
