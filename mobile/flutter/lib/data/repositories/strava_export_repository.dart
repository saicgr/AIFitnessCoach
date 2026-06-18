import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Riverpod provider for the Strava outbound-share repository (Workstream E4).
final stravaExportRepositoryProvider = Provider<StravaExportRepository>((ref) {
  return StravaExportRepository(ref.watch(apiClientProvider));
});

/// The user's Strava auto-share capability + preference, as returned by
/// `GET /strava-export/preference`. Mirrors `StravaSharePreferenceResponse`
/// in `backend/api/v1/strava_export.py`.
@immutable
class StravaSharePreference {
  /// Whether the user has an active Strava connection at all.
  final bool connected;

  /// Whether the connected account has the `activity:write` scope. When false,
  /// auto-share + manual push will fail until the user reconnects Strava (the
  /// scope is granted only after Strava's app review for write access).
  final bool canWrite;

  /// Whether completed workouts are auto-pushed to Strava.
  final bool autoShareToStrava;

  const StravaSharePreference({
    required this.connected,
    required this.canWrite,
    required this.autoShareToStrava,
  });

  factory StravaSharePreference.fromJson(Map<String, dynamic> json) {
    return StravaSharePreference(
      connected: (json['connected'] as bool?) ?? false,
      canWrite: (json['can_write'] as bool?) ?? false,
      autoShareToStrava: (json['auto_share_to_strava'] as bool?) ?? false,
    );
  }

  StravaSharePreference copyWith({bool? autoShareToStrava}) {
    return StravaSharePreference(
      connected: connected,
      canWrite: canWrite,
      autoShareToStrava: autoShareToStrava ?? this.autoShareToStrava,
    );
  }
}

/// Result of a manual `POST /workouts/{id}/share-to-strava` push.
@immutable
class StravaPushResult {
  final String status;
  final String? activityId;
  final String? stravaUrl;

  const StravaPushResult({
    required this.status,
    this.activityId,
    this.stravaUrl,
  });

  factory StravaPushResult.fromJson(Map<String, dynamic> json) => StravaPushResult(
        status: (json['status'] ?? 'ok') as String,
        activityId: json['activity_id'] as String?,
        stravaUrl: json['strava_url'] as String?,
      );
}

/// Thin wrapper around the Strava outbound-share endpoints. Methods throw a
/// human-readable exception on failure so the screens can render clean error
/// states — no silent fallback.
class StravaExportRepository {
  StravaExportRepository(this._client);

  final ApiClient _client;

  /// Read the user's Strava auto-share preference + capability.
  Future<StravaSharePreference> getPreference() async {
    try {
      final response = await _client.get('/strava-export/preference');
      return StravaSharePreference.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ [StravaExportRepository] getPreference failed: $e');
      rethrow;
    }
  }

  /// Toggle auto-push of completed workouts to Strava. Returns the updated
  /// preference. Throws if Strava isn't connected (backend returns 404).
  Future<StravaSharePreference> setAutoShare(bool enabled) async {
    final response = await _client.put(
      '/strava-export/preference',
      data: {'auto_share_to_strava': enabled},
    );
    return StravaSharePreference.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Push a completed workout to Strava on demand. Returns the created Strava
  /// activity (id + URL). Throws on any failure (not connected / missing scope
  /// / Strava API error) so the caller can surface it.
  Future<StravaPushResult> shareWorkout(String workoutId) async {
    final response = await _client.post(
      '/workouts/$workoutId/share-to-strava',
    );
    return StravaPushResult.fromJson(response.data as Map<String, dynamic>);
  }
}
