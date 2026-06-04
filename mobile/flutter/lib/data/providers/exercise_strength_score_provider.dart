import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise_strength_score.dart';
import '../services/api_client.dart';

/// Per-exercise strength score + best lift for the active-workout hexagon badge.
///
/// `family` keyed by exercise name. `autoDispose` (it's only needed while an
/// exercise card is on screen) but `keepAlive` after first success so reopening
/// the same exercise paints instantly without a spinner.
///
/// baseUrl already carries `/api/v1`, so the path is `/scores/exercise/...`.
final exerciseStrengthScoreProvider = FutureProvider.autoDispose
    .family<ExerciseStrengthScore, String>((ref, exerciseName) async {
  final link = ref.keepAlive();
  // Drop the cache after 10 minutes idle so stale scores don't linger forever.
  ref.onCancel(() {
    Future<void>.delayed(const Duration(minutes: 10), link.close);
  });

  final api = ref.read(apiClientProvider);
  final res = await api.get<Map<String, dynamic>>(
    '/scores/exercise/${Uri.encodeComponent(exerciseName)}',
  );
  return ExerciseStrengthScore.fromJson(res.data ?? const {});
});
