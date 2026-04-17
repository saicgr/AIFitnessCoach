import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Supported caption tones.
enum CaptionMode { hype, humble, roast }

/// Thin client for the backend `/share-templates/caption` endpoint.
/// Gracefully degrades to a local template string on network failure
/// so the Copy-caption UX is never blocked on the network.
class ShareCaptionService {
  ShareCaptionService(this._api);

  final ApiClient _api;

  Future<String> generate({
    required String workoutName,
    required String volumeDisplay,
    required int sets,
    required int durationSeconds,
    String? topExercise,
    int prCount = 0,
    CaptionMode mode = CaptionMode.hype,
  }) async {
    try {
      final resp = await _api.post(
        '/share-templates/caption',
        data: {
          'workout_name': workoutName,
          'volume_display': volumeDisplay,
          'sets': sets,
          'duration_seconds': durationSeconds,
          'top_exercise': topExercise,
          'pr_count': prCount,
          'mode': mode.name,
        },
      );
      final data = resp.data;
      if (data is Map && data['caption'] is String) {
        return data['caption'] as String;
      }
    } catch (e) {
      debugPrint('[ShareCaptionService] generate failed: $e');
    }
    return _fallback(
      workoutName: workoutName,
      volumeDisplay: volumeDisplay,
      sets: sets,
      durationSeconds: durationSeconds,
      mode: mode,
    );
  }

  String _fallback({
    required String workoutName,
    required String volumeDisplay,
    required int sets,
    required int durationSeconds,
    required CaptionMode mode,
  }) {
    final mins = (durationSeconds / 60).ceil();
    final base = '$workoutName · $volumeDisplay · $sets sets · ${mins}min';
    switch (mode) {
      case CaptionMode.roast:
        return '$base. Someone tell my back I\'m sorry.';
      case CaptionMode.humble:
        return '$base. Trying to stay consistent.';
      case CaptionMode.hype:
        return '🔥 Crushed $base.';
    }
  }
}
