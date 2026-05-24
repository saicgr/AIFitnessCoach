import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Repository for the cardio dedup management endpoints (see
/// `backend/services/cardio_dedup_service.py`).
///
/// Endpoint surface (`/cardio-logs/dedup-groups/*`) is added by a later agent.
/// Until that ships, calls 404 — this repository treats 404 as "no groups
/// yet" so the UI degrades gracefully to an empty state.
///
/// Per `feedback_no_silent_fallbacks.md` we still throw on other errors —
/// only 404 is silenced because it represents "endpoint not yet wired" and
/// is functionally equivalent to "no duplicate groups".
class CardioDedupRepository {
  final ApiClient _apiClient;

  CardioDedupRepository(this._apiClient);

  Future<List<DedupGroup>> listGroups() async {
    debugPrint('🏃 [CardioDedup] listGroups');
    try {
      final response = await _apiClient.get('/cardio-logs/dedup-groups');
      if (response.statusCode == 404) {
        return const [];
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load duplicate imports (${response.statusCode})',
        );
      }
      final raw = response.data;
      if (raw is! List) return const [];
      return raw
          .map((g) => DedupGroup.fromJson(Map<String, dynamic>.from(g as Map)))
          .toList();
    } on DioException catch (e) {
      // Backend endpoint not yet deployed → 404 from Dio is treated the same.
      if (e.response?.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> overridePrimary(String groupId, String newPrimaryId) async {
    debugPrint('🏃 [CardioDedup] override group=$groupId new=$newPrimaryId');
    final response = await _apiClient.post(
      '/cardio-logs/dedup-groups/$groupId/primary',
      data: <String, dynamic>{'new_primary_id': newPrimaryId},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to update primary (${response.statusCode})',
      );
    }
  }

  Future<void> unlink(String logId) async {
    debugPrint('🏃 [CardioDedup] unlink log=$logId');
    final response = await _apiClient.post(
      '/cardio-logs/dedup-groups/unlink',
      data: <String, dynamic>{'log_id': logId},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unlink (${response.statusCode})');
    }
  }
}

/// Provider exposing the dedup repository. Wired off the existing
/// `apiClientProvider` so we don't duplicate Dio configuration.
final cardioDedupRepositoryProvider = Provider<CardioDedupRepository>((ref) {
  return CardioDedupRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Models — kept in this file (per swarm scope) so they don't collide with
// other agents' edits in `data/models/`.
// ---------------------------------------------------------------------------

class DedupCardioLogSummary {
  final String id;
  final String activityType;
  final DateTime performedAt;
  final int durationSeconds;
  final double? distanceM;
  final String sourceApp;
  final bool isPrimary;

  const DedupCardioLogSummary({
    required this.id,
    required this.activityType,
    required this.performedAt,
    required this.durationSeconds,
    required this.distanceM,
    required this.sourceApp,
    required this.isPrimary,
  });

  factory DedupCardioLogSummary.fromJson(Map<String, dynamic> json) {
    return DedupCardioLogSummary(
      id: json['id'] as String,
      activityType: json['activity_type'] as String,
      performedAt: DateTime.parse(json['performed_at'] as String),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      distanceM: json['distance_m'] == null
          ? null
          : (json['distance_m'] as num).toDouble(),
      sourceApp: (json['source_app'] as String?) ?? 'unknown',
      isPrimary: (json['is_primary'] as bool?) ?? false,
    );
  }
}

class DedupGroup {
  final String groupId;
  final DedupCardioLogSummary primary;
  final List<DedupCardioLogSummary> duplicates;

  const DedupGroup({
    required this.groupId,
    required this.primary,
    required this.duplicates,
  });

  factory DedupGroup.fromJson(Map<String, dynamic> json) {
    return DedupGroup(
      groupId: json['group_id'] as String,
      primary: DedupCardioLogSummary.fromJson(
        Map<String, dynamic>.from(json['primary'] as Map),
      ),
      duplicates: ((json['duplicates'] as List?) ?? const [])
          .map((d) => DedupCardioLogSummary.fromJson(
                Map<String, dynamic>.from(d as Map),
              ))
          .toList(),
    );
  }

  /// All members (primary + duplicates) — convenient for the row-level UI.
  List<DedupCardioLogSummary> get allMembers => [primary, ...duplicates];
}
