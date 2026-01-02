import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill_progression.dart';
import '../services/api_client.dart';

/// Skill Progression repository provider
final skillProgressionRepositoryProvider = Provider<SkillProgressionRepository>((ref) {
  return SkillProgressionRepository(ref.watch(apiClientProvider));
});

/// Repository for skill progression operations
class SkillProgressionRepository {
  final ApiClient _client;

  SkillProgressionRepository(this._client);

  // ─────────────────────────────────────────────────────────────────
  // Progression Chains
  // ─────────────────────────────────────────────────────────────────

  /// Get all available progression chains
  Future<List<ProgressionChain>> getProgressionChains({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _client.get(
        '/skill-progressions/chains',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data as List;
      return data.map((json) => ProgressionChain.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting progression chains: $e');
      rethrow;
    }
  }

  /// Get a specific chain with all its steps
  Future<ProgressionChain> getChainWithSteps(String chainId) async {
    try {
      final response = await _client.get('/skill-progressions/chains/$chainId');
      return ProgressionChain.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting chain with steps: $e');
      rethrow;
    }
  }

  /// Get all steps for a chain
  Future<List<ProgressionStep>> getChainSteps(String chainId) async {
    try {
      final response = await _client.get('/skill-progressions/chains/$chainId/steps');
      final data = response.data as List;
      return data.map((json) => ProgressionStep.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting chain steps: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // User Progress
  // ─────────────────────────────────────────────────────────────────

  /// Get user's progress for all chains
  Future<List<UserSkillProgress>> getUserProgress(String userId) async {
    try {
      final response = await _client.get('/skill-progressions/user/$userId/progress');
      final data = response.data as List;
      return data.map((json) => UserSkillProgress.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      rethrow;
    }
  }

  /// Get user's progress for a specific chain
  Future<UserSkillProgress?> getUserChainProgress(String userId, String chainId) async {
    try {
      final response = await _client.get(
        '/skill-progressions/user/$userId/progress/$chainId',
      );
      if (response.data == null) return null;
      return UserSkillProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting user chain progress: $e');
      // Return null if not found (user hasn't started this chain)
      return null;
    }
  }

  /// Get user's skill progression summary
  Future<SkillProgressionSummary> getUserSummary(String userId) async {
    try {
      final response = await _client.get('/skill-progressions/user/$userId/summary');
      return SkillProgressionSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting user summary: $e');
      rethrow;
    }
  }

  /// Start a new progression chain for user
  Future<UserSkillProgress> startChain(String userId, String chainId) async {
    try {
      final response = await _client.post(
        '/skill-progressions/user/$userId/start',
        data: {'chain_id': chainId},
      );
      return UserSkillProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error starting chain: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Attempts & Progress Updates
  // ─────────────────────────────────────────────────────────────────

  /// Log an attempt at a progression step
  Future<ProgressionAttempt> logAttempt({
    required String userId,
    required String chainId,
    required String stepId,
    required int stepOrder,
    int? repsCompleted,
    int? setsCompleted,
    int? holdSeconds,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '/skill-progressions/user/$userId/attempt',
        data: {
          'chain_id': chainId,
          'step_id': stepId,
          'step_order': stepOrder,
          if (repsCompleted != null) 'reps_completed': repsCompleted,
          if (setsCompleted != null) 'sets_completed': setsCompleted,
          if (holdSeconds != null) 'hold_seconds': holdSeconds,
          if (notes != null) 'notes': notes,
        },
      );
      return ProgressionAttempt.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging attempt: $e');
      rethrow;
    }
  }

  /// Manually unlock the next step (admin or after meeting criteria)
  Future<UserSkillProgress> unlockNextStep(String userId, String chainId) async {
    try {
      final response = await _client.post(
        '/skill-progressions/user/$userId/unlock-next',
        data: {'chain_id': chainId},
      );
      return UserSkillProgress.fromJson(response.data);
    } catch (e) {
      debugPrint('Error unlocking next step: $e');
      rethrow;
    }
  }

  /// Get attempt history for a chain
  Future<List<ProgressionAttempt>> getAttemptHistory({
    required String userId,
    required String chainId,
    int? stepOrder,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (stepOrder != null) {
        queryParams['step_order'] = stepOrder;
      }

      final response = await _client.get(
        '/skill-progressions/user/$userId/attempts/$chainId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => ProgressionAttempt.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting attempt history: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────────────────────────

  /// Get all available categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _client.get('/skill-progressions/categories');
      final data = response.data as List;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      rethrow;
    }
  }
}
