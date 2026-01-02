import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flexibility_assessment.dart';
import '../services/api_client.dart';

/// Flexibility repository provider
final flexibilityRepositoryProvider = Provider<FlexibilityRepository>((ref) {
  return FlexibilityRepository(ref.watch(apiClientProvider));
});

/// Repository for flexibility assessment operations
class FlexibilityRepository {
  final ApiClient _client;

  FlexibilityRepository(this._client);

  // ─────────────────────────────────────────────────────────────────
  // Flexibility Tests
  // ─────────────────────────────────────────────────────────────────

  /// Get all available flexibility tests
  Future<List<FlexibilityTest>> getFlexibilityTests() async {
    try {
      final response = await _client.get('/flexibility/tests');
      final data = response.data as List;
      return data.map((json) => FlexibilityTest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting flexibility tests: $e');
      rethrow;
    }
  }

  /// Get a specific flexibility test by ID
  Future<FlexibilityTest> getFlexibilityTest(String testId) async {
    try {
      final response = await _client.get('/flexibility/tests/$testId');
      return FlexibilityTest.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting flexibility test: $e');
      rethrow;
    }
  }

  /// Get tests by muscle group
  Future<List<FlexibilityTest>> getTestsByMuscle(String muscle) async {
    try {
      final response = await _client.get('/flexibility/tests/by-muscle/$muscle');
      final tests = response.data['tests'] as List? ?? [];
      return tests.map((json) => FlexibilityTest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting tests by muscle: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Assessments
  // ─────────────────────────────────────────────────────────────────

  /// Record a new flexibility assessment
  Future<RecordAssessmentResponse> recordAssessment({
    required String userId,
    required String testType,
    required double measurement,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '/flexibility/user/$userId/assessment',
        data: {
          'test_type': testType,
          'measurement': measurement,
          if (notes != null) 'notes': notes,
        },
      );
      return RecordAssessmentResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error recording assessment: $e');
      rethrow;
    }
  }

  /// Get user's assessment history
  Future<List<FlexibilityAssessment>> getAssessmentHistory({
    required String userId,
    String? testType,
    int limit = 50,
    int? days,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (testType != null) queryParams['test_type'] = testType;
      if (days != null) queryParams['days'] = days;

      final response = await _client.get(
        '/flexibility/user/$userId/assessments',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => FlexibilityAssessment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting assessment history: $e');
      rethrow;
    }
  }

  /// Get latest assessment for each test type
  Future<List<FlexibilityAssessment>> getLatestAssessments(String userId) async {
    try {
      final response = await _client.get('/flexibility/user/$userId/assessments/latest');
      final assessments = response.data['assessments'] as List? ?? [];
      return assessments.map((json) => FlexibilityAssessment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting latest assessments: $e');
      rethrow;
    }
  }

  /// Delete an assessment
  Future<bool> deleteAssessment(String userId, String assessmentId) async {
    try {
      final response = await _client.delete(
        '/flexibility/user/$userId/assessment/$assessmentId',
      );
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Error deleting assessment: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Progress Tracking
  // ─────────────────────────────────────────────────────────────────

  /// Get progress for a specific test type
  Future<FlexibilityTrend> getProgress({
    required String userId,
    required String testType,
    int days = 90,
  }) async {
    try {
      final response = await _client.get(
        '/flexibility/user/$userId/progress/$testType',
        queryParameters: {'days': days},
      );
      return FlexibilityTrend.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting progress: $e');
      rethrow;
    }
  }

  /// Get overall flexibility summary
  Future<FlexibilitySummary> getSummary(String userId) async {
    try {
      final response = await _client.get('/flexibility/user/$userId/summary');
      return FlexibilitySummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting summary: $e');
      rethrow;
    }
  }

  /// Get flexibility score
  Future<FlexibilityScoreResponse> getFlexibilityScore(String userId) async {
    try {
      final response = await _client.get('/flexibility/user/$userId/score');
      return FlexibilityScoreResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting flexibility score: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Stretch Plans
  // ─────────────────────────────────────────────────────────────────

  /// Get all stretch plans for a user
  Future<List<FlexibilityStretchPlan>> getStretchPlans(String userId) async {
    try {
      final response = await _client.get('/flexibility/user/$userId/stretch-plans');
      final plans = response.data['plans'] as List? ?? [];
      return plans.map((json) => FlexibilityStretchPlan.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting stretch plans: $e');
      rethrow;
    }
  }

  /// Get stretch plan for a specific test type
  Future<FlexibilityStretchPlan> getStretchPlanForTest(String userId, String testType) async {
    try {
      final response = await _client.get('/flexibility/user/$userId/stretch-plan/$testType');
      return FlexibilityStretchPlan.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting stretch plan: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Evaluation (Without Saving)
  // ─────────────────────────────────────────────────────────────────

  /// Evaluate a measurement without saving
  Future<Map<String, dynamic>> evaluateMeasurement({
    required String testType,
    required double measurement,
    required String gender,
    required int age,
  }) async {
    try {
      final response = await _client.post(
        '/flexibility/evaluate',
        queryParameters: {
          'test_type': testType,
          'measurement': measurement,
          'gender': gender,
          'age': age,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error evaluating measurement: $e');
      rethrow;
    }
  }

  /// Get recommendations for a test type and rating
  Future<List<StretchRecommendation>> getRecommendations(String testType, String rating) async {
    try {
      final response = await _client.get('/flexibility/recommendations/$testType/$rating');
      final recommendations = response.data['recommendations'] as List? ?? [];
      return recommendations.map((json) => StretchRecommendation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      rethrow;
    }
  }
}
