import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/milestone.dart';
import '../services/api_client.dart';

/// Milestones repository provider
final milestonesRepositoryProvider = Provider<MilestonesRepository>((ref) {
  return MilestonesRepository(ref.watch(apiClientProvider));
});

/// Repository for milestone and ROI operations
class MilestonesRepository {
  final ApiClient _client;

  MilestonesRepository(this._client);

  // =========================================================================
  // Milestone Definitions
  // =========================================================================

  /// Get all milestone definitions
  Future<List<MilestoneDefinition>> getMilestoneDefinitions({
    MilestoneCategory? category,
  }) async {
    try {
      String path = '/progress/milestones/definitions';
      if (category != null) {
        path += '?category=${category.name}';
      }

      final response = await _client.get(path);
      final data = response.data as List;
      return data.map((json) => MilestoneDefinition.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting milestone definitions: $e');
      rethrow;
    }
  }

  // =========================================================================
  // User Milestones
  // =========================================================================

  /// Get complete milestone progress for a user
  Future<MilestonesResponse> getMilestoneProgress(String userId) async {
    try {
      final response = await _client.get('/progress/milestones/$userId');
      return MilestonesResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting milestone progress: $e');
      rethrow;
    }
  }

  /// Get uncelebrated milestones
  Future<List<UserMilestone>> getUncelebratedMilestones(String userId) async {
    try {
      final response =
          await _client.get('/progress/milestones/$userId/uncelebrated');
      final data = response.data as List;
      return data.map((json) => UserMilestone.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting uncelebrated milestones: $e');
      rethrow;
    }
  }

  /// Mark milestones as celebrated
  Future<bool> markMilestonesCelebrated(
    String userId,
    List<String> milestoneIds,
  ) async {
    try {
      await _client.post(
        '/progress/milestones/$userId/celebrate',
        data: {'milestone_ids': milestoneIds},
      );
      return true;
    } catch (e) {
      debugPrint('Error marking milestones celebrated: $e');
      return false;
    }
  }

  /// Record milestone share
  Future<bool> recordMilestoneShare(
    String userId,
    String milestoneId,
    String platform,
  ) async {
    try {
      await _client.post(
        '/progress/milestones/$userId/share',
        data: {
          'milestone_id': milestoneId,
          'platform': platform,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error recording milestone share: $e');
      return false;
    }
  }

  /// Manually trigger milestone check
  Future<MilestoneCheckResult> checkMilestones(String userId) async {
    try {
      final response =
          await _client.post('/progress/milestones/$userId/check');
      return MilestoneCheckResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error checking milestones: $e');
      rethrow;
    }
  }

  // =========================================================================
  // ROI Metrics
  // =========================================================================

  /// Get detailed ROI metrics
  Future<ROIMetrics> getROIMetrics(
    String userId, {
    bool recalculate = false,
  }) async {
    try {
      String path = '/progress/roi/$userId';
      if (recalculate) {
        path += '?recalculate=true';
      }

      final response = await _client.get(path);
      return ROIMetrics.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting ROI metrics: $e');
      rethrow;
    }
  }

  /// Get compact ROI summary for home screen
  Future<ROISummary> getROISummary(String userId) async {
    try {
      final response = await _client.get('/progress/roi/$userId/summary');
      return ROISummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting ROI summary: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Combined Progress
  // =========================================================================

  /// Get complete progress overview (milestones + ROI)
  Future<ProgressOverview> getProgressOverview(String userId) async {
    try {
      final response = await _client.get('/progress/$userId');
      return ProgressOverview.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting progress overview: $e');
      rethrow;
    }
  }
}

/// Combined progress overview response
class ProgressOverview {
  final MilestonesResponse milestones;
  final ROISummary roi;

  const ProgressOverview({
    required this.milestones,
    required this.roi,
  });

  factory ProgressOverview.fromJson(Map<String, dynamic> json) {
    return ProgressOverview(
      milestones: MilestonesResponse.fromJson(json['milestones']),
      roi: ROISummary.fromJson(json['roi']),
    );
  }
}
