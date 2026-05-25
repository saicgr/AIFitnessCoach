import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

/// Buddy synced workouts — Phase 6 #15.
///
/// Backend lives at /api/v1/buddy/* (start / accept / set-complete / end /
/// active / events replay). Live updates come via Supabase Realtime: the
/// `buddy_set_events` table is in `supabase_realtime` publication, so a
/// PostgresChangeEvent filtered by `session_id` delivers the partner's set
/// completion within ~200ms of insert.
///
/// Reuses the existing Supabase client (already configured in main.dart for
/// auth + live_chat), so no new realtime infrastructure.
class BuddyWorkoutService {
  BuddyWorkoutService(this._api);

  final ApiClient _api;
  RealtimeChannel? _activeChannel;

  // ─── REST ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startSession({
    String? partnerUserId,
    String? workoutId,
    List<dynamic>? exercisesSnapshot,
  }) async {
    final body = <String, dynamic>{};
    if (partnerUserId != null) body['partner_user_id'] = partnerUserId;
    if (workoutId != null) body['workout_id'] = workoutId;
    if (exercisesSnapshot != null) body['exercises_snapshot'] = exercisesSnapshot;
    final resp = await _api.post('/buddy/start', data: body);
    _ensureOk(resp.statusCode);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> acceptSession(String sessionId) async {
    final resp = await _api.post('/buddy/$sessionId/accept');
    _ensureOk(resp.statusCode);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> logSetComplete({
    required String sessionId,
    required String exerciseId,
    String? exerciseName,
    required int setNumber,
    double? weightKg,
    int? reps,
    double? rpe,
  }) async {
    final resp = await _api.post(
      '/buddy/$sessionId/set-complete',
      data: {
        'exercise_id': exerciseId,
        if (exerciseName != null) 'exercise_name': exerciseName,
        'set_number': setNumber,
        if (weightKg != null) 'weight_kg': weightKg,
        if (reps != null) 'reps': reps,
        if (rpe != null) 'rpe': rpe,
      },
    );
    _ensureOk(resp.statusCode);
  }

  Future<void> endSession(String sessionId, {bool cancelled = false}) async {
    final resp = await _api.post(
      '/buddy/$sessionId/end',
      queryParameters: {'cancelled': cancelled.toString()},
    );
    _ensureOk(resp.statusCode);
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final resp = await _api.get('/buddy/active');
    _ensureOk(resp.statusCode);
    final raw = (resp.data as Map?)?['session'];
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  Future<List<Map<String, dynamic>>> replayEvents(String sessionId) async {
    final resp = await _api.get('/buddy/$sessionId/events');
    _ensureOk(resp.statusCode);
    final raw = (resp.data as Map?)?['events'] as List? ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ─── Realtime subscription ────────────────────────────────────────────

  /// Subscribe to live set events on `session_id`. Returns the active channel
  /// — call [unsubscribe] when leaving the screen.
  ///
  /// `onEvent` fires for every newly-inserted buddy_set_events row regardless
  /// of which user posted it (the caller decides whether to filter on user_id
  /// to ignore self-echoes).
  RealtimeChannel subscribe({
    required String sessionId,
    required void Function(Map<String, dynamic> row) onEvent,
  }) {
    unsubscribe();
    final supabase = Supabase.instance.client;
    final channel = supabase
        .channel('buddy:$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'buddy_set_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            try {
              onEvent(Map<String, dynamic>.from(row));
            } catch (e) {
              debugPrint('⚠️ [BuddyWorkoutService] onEvent threw: $e');
            }
          },
        )
        .subscribe();
    _activeChannel = channel;
    debugPrint('🏋️ [BuddyWorkoutService] subscribed to buddy:$sessionId');
    return channel;
  }

  void unsubscribe() {
    final ch = _activeChannel;
    if (ch == null) return;
    try {
      Supabase.instance.client.removeChannel(ch);
    } catch (e) {
      debugPrint('⚠️ [BuddyWorkoutService] unsubscribe failed: $e');
    }
    _activeChannel = null;
  }

  void _ensureOk(int? status) {
    if (status == null || status < 200 || status >= 300) {
      throw Exception('buddy_request_failed status=$status');
    }
  }
}

final buddyWorkoutServiceProvider = Provider<BuddyWorkoutService>((ref) {
  return BuddyWorkoutService(ref.read(apiClientProvider));
});

/// Currently-active buddy session for the home banner.
final activeBuddySessionProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.read(buddyWorkoutServiceProvider).getActiveSession();
});
