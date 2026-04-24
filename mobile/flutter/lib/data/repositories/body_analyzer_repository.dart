import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_analyzer.dart';
import '../services/api_client.dart';

/// DI provider for the Body Analyzer repository.
final bodyAnalyzerRepositoryProvider =
    Provider<BodyAnalyzerRepository>((ref) {
  return BodyAnalyzerRepository(ref.watch(apiClientProvider));
});

/// Thin HTTP wrapper for /api/v1/body-analyzer/* endpoints.
///
/// Each method returns the typed model; errors bubble up so UI can show
/// banner/toast. The screen layer converts Dio exceptions into human
/// copy — we don't swallow them here per the
/// `feedback_no_silent_fallbacks.md` rule.
class BodyAnalyzerRepository {
  final ApiClient _client;
  BodyAnalyzerRepository(this._client);

  /// POST /body-analyzer/analyze
  Future<BodyAnalyzerAnalyzeResponse> analyze({
    required List<String> photoIds,
    bool includeMeasurements = true,
    String? userContext,
  }) async {
    debugPrint('🧬 [BodyAnalyzer] analyze | photos=${photoIds.length}');
    final resp = await _client.post(
      '/body-analyzer/analyze',
      data: BodyAnalyzerRequest(
        photoIds: photoIds,
        includeMeasurements: includeMeasurements,
        userContext: userContext,
      ).toJson(),
    );
    return BodyAnalyzerAnalyzeResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /body-analyzer/extract-measurements
  Future<PhotoMeasurementExtractionResponse> extractMeasurements({
    required List<String> photoIds,
  }) async {
    final resp = await _client.post(
      '/body-analyzer/extract-measurements',
      data: {'photo_ids': photoIds},
    );
    return PhotoMeasurementExtractionResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /body-analyzer/snapshots
  Future<List<BodyAnalyzerSnapshot>> listSnapshots({int limit = 30}) async {
    final resp = await _client.get(
      '/body-analyzer/snapshots',
      queryParameters: {'limit': limit},
    );
    final data = resp.data as List<dynamic>;
    return data
        .map((e) =>
            BodyAnalyzerSnapshot.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /body-analyzer/latest
  Future<BodyAnalyzerSnapshot?> latestSnapshot() async {
    final resp = await _client.get('/body-analyzer/latest');
    if (resp.data == null) return null;
    return BodyAnalyzerSnapshot.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /body-analyzer/body-age
  Future<BodyAgeResult> bodyAge() async {
    final resp = await _client.get('/body-analyzer/body-age');
    return BodyAgeResult.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  /// POST /body-analyzer/retune-proposal
  Future<RetuneProposal> createRetuneProposal({
    required String bodyAnalyzerSnapshotId,
  }) async {
    final resp = await _client.post(
      '/body-analyzer/retune-proposal',
      data: {'body_analyzer_snapshot_id': bodyAnalyzerSnapshotId},
    );
    return RetuneProposal.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  /// POST /body-analyzer/retune-proposal/{id}/preview
  Future<RetunePreview> previewRetune(String proposalId) async {
    final resp = await _client.post(
      '/body-analyzer/retune-proposal/$proposalId/preview',
    );
    return RetunePreview.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  /// POST /body-analyzer/retune-proposal/{id}/apply
  Future<RetuneApplyResponse> applyRetune(String proposalId) async {
    final resp = await _client.post(
      '/body-analyzer/retune-proposal/$proposalId/apply',
    );
    return RetuneApplyResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /body-analyzer/retune-proposal/{id}/dismiss
  Future<void> dismissRetune(String proposalId, {String? reason}) async {
    await _client.post(
      '/body-analyzer/retune-proposal/$proposalId/dismiss',
      data: {'reason': reason},
    );
  }

  /// POST /body-analyzer/apply-posture-correctives
  Future<ApplyCorrectivesResponse> applyPostureCorrectives({
    required String bodyAnalyzerSnapshotId,
  }) async {
    final resp = await _client.post(
      '/body-analyzer/apply-posture-correctives',
      data: {'body_analyzer_snapshot_id': bodyAnalyzerSnapshotId},
    );
    return ApplyCorrectivesResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /body-analyzer/trigger-deload-check
  Future<DeloadCheckResult> triggerDeloadCheck() async {
    final resp = await _client.post('/body-analyzer/trigger-deload-check');
    return DeloadCheckResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio Coach repository
// ---------------------------------------------------------------------------

final audioCoachRepositoryProvider =
    Provider<AudioCoachRepository>((ref) {
  return AudioCoachRepository(ref.watch(apiClientProvider));
});

class AudioCoachRepository {
  final ApiClient _client;
  AudioCoachRepository(this._client);

  /// GET /audio-coach/daily-brief
  Future<AudioCoachBrief> dailyBrief() async {
    final resp = await _client.get('/audio-coach/daily-brief');
    return AudioCoachBrief.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /audio-coach/mark-listened
  Future<void> markListened(String briefId) async {
    await _client.post(
      '/audio-coach/mark-listened',
      data: {'brief_id': briefId},
    );
  }
}

// ---------------------------------------------------------------------------
// Menstrual cycle repository
// ---------------------------------------------------------------------------

final menstrualCycleRepositoryProvider =
    Provider<MenstrualCycleRepository>((ref) {
  return MenstrualCycleRepository(ref.watch(apiClientProvider));
});

class MenstrualCycleRepository {
  final ApiClient _client;
  MenstrualCycleRepository(this._client);

  /// Simple Supabase table passthrough endpoints — wrapped via a dedicated
  /// thin cycle router if/when we want it; for now we use the generic
  /// /users/me settings POST + a new cycle-logs endpoint if added.
  ///
  /// NOTE: No backend router was added for cycle logs (out of scope of this
  /// ship) — the toggle is written via `/users/me` settings update, and
  /// cycle logs use the supabase-direct table inserts via a future `/cycle`
  /// router. Current UI only exposes the opt-in toggle + single cycle log
  /// form; writes round-trip through the standard users settings endpoint.
  Future<void> setCycleAwareReminders(bool enabled) async {
    await _client.patch(
      '/users/me',
      data: {'cycle_aware_reminders': enabled},
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly volume per muscle (scores endpoint extension)
// ---------------------------------------------------------------------------

final weeklyVolumeRepositoryProvider =
    Provider<WeeklyVolumeRepository>((ref) {
  return WeeklyVolumeRepository(ref.watch(apiClientProvider));
});

class WeeklyVolumeRepository {
  final ApiClient _client;
  WeeklyVolumeRepository(this._client);

  Future<List<WeeklyVolumeEntry>> perMuscle() async {
    final resp = await _client.get('/scores/weekly-volume-per-muscle');
    final data = resp.data as Map<String, dynamic>;
    final raw = (data['muscles'] as List<dynamic>? ?? const []);
    return raw
        .map((e) =>
            WeeklyVolumeEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
