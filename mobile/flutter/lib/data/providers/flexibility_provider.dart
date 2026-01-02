import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flexibility_assessment.dart';
import '../repositories/flexibility_repository.dart';

// ============================================
// State Classes
// ============================================

/// State for flexibility assessments
class FlexibilityState {
  final bool isLoading;
  final String? error;
  final List<FlexibilityTest> tests;
  final List<FlexibilityAssessment> assessmentHistory;
  final Map<String, FlexibilityAssessment> latestAssessments;
  final FlexibilitySummary? summary;
  final FlexibilityTest? selectedTest;
  final FlexibilityTrend? selectedTestTrend;
  final List<FlexibilityStretchPlan> stretchPlans;
  final RecordAssessmentResponse? lastRecordedAssessment;

  const FlexibilityState({
    this.isLoading = false,
    this.error,
    this.tests = const [],
    this.assessmentHistory = const [],
    this.latestAssessments = const {},
    this.summary,
    this.selectedTest,
    this.selectedTestTrend,
    this.stretchPlans = const [],
    this.lastRecordedAssessment,
  });

  FlexibilityState copyWith({
    bool? isLoading,
    String? error,
    List<FlexibilityTest>? tests,
    List<FlexibilityAssessment>? assessmentHistory,
    Map<String, FlexibilityAssessment>? latestAssessments,
    FlexibilitySummary? summary,
    FlexibilityTest? selectedTest,
    FlexibilityTrend? selectedTestTrend,
    List<FlexibilityStretchPlan>? stretchPlans,
    RecordAssessmentResponse? lastRecordedAssessment,
    bool clearError = false,
    bool clearSelectedTest = false,
    bool clearTrend = false,
    bool clearLastRecorded = false,
  }) {
    return FlexibilityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      tests: tests ?? this.tests,
      assessmentHistory: assessmentHistory ?? this.assessmentHistory,
      latestAssessments: latestAssessments ?? this.latestAssessments,
      summary: summary ?? this.summary,
      selectedTest: clearSelectedTest ? null : (selectedTest ?? this.selectedTest),
      selectedTestTrend: clearTrend ? null : (selectedTestTrend ?? this.selectedTestTrend),
      stretchPlans: stretchPlans ?? this.stretchPlans,
      lastRecordedAssessment: clearLastRecorded ? null : (lastRecordedAssessment ?? this.lastRecordedAssessment),
    );
  }

  /// Get latest assessment for a specific test type
  FlexibilityAssessment? getLatestForTest(String testType) {
    return latestAssessments[testType];
  }

  /// Get tests that haven't been assessed yet
  List<FlexibilityTest> get unassessedTests {
    return tests.where((t) => !latestAssessments.containsKey(t.id)).toList();
  }

  /// Get tests that have been assessed
  List<FlexibilityTest> get assessedTests {
    return tests.where((t) => latestAssessments.containsKey(t.id)).toList();
  }

  /// Get tests with poor or fair ratings (priority improvements)
  List<FlexibilityTest> get testsNeedingImprovement {
    return tests.where((t) {
      final assessment = latestAssessments[t.id];
      if (assessment == null) return false;
      return assessment.rating == 'poor' || assessment.rating == 'fair';
    }).toList();
  }
}

// ============================================
// State Notifier
// ============================================

class FlexibilityNotifier extends StateNotifier<FlexibilityState> {
  final FlexibilityRepository _repository;
  String? _currentUserId;

  FlexibilityNotifier(this._repository) : super(const FlexibilityState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all flexibility tests
  Future<void> loadTests() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tests = await _repository.getFlexibilityTests();
      state = state.copyWith(isLoading: false, tests: tests);
      debugPrint('Loaded ${tests.length} flexibility tests');
    } catch (e) {
      debugPrint('Error loading flexibility tests: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load flexibility tests: $e',
      );
    }
  }

  /// Load user's latest assessments
  Future<void> loadLatestAssessments({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('No user ID, skipping load latest assessments');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final assessments = await _repository.getLatestAssessments(uid);
      final latestMap = <String, FlexibilityAssessment>{};
      for (final a in assessments) {
        latestMap[a.testType] = a;
      }

      state = state.copyWith(
        isLoading: false,
        latestAssessments: latestMap,
      );
      debugPrint('Loaded ${assessments.length} latest assessments');
    } catch (e) {
      debugPrint('Error loading latest assessments: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load assessments: $e',
      );
    }
  }

  /// Load user's flexibility summary
  Future<void> loadSummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final summary = await _repository.getSummary(uid);
      state = state.copyWith(summary: summary);
      debugPrint('Loaded flexibility summary: ${summary.overallScore}');
    } catch (e) {
      debugPrint('Error loading summary: $e');
    }
  }

  /// Load assessment history for a specific test type
  Future<void> loadAssessmentHistory({
    String? userId,
    String? testType,
    int limit = 50,
    int? days,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final history = await _repository.getAssessmentHistory(
        userId: uid,
        testType: testType,
        limit: limit,
        days: days,
      );

      state = state.copyWith(
        isLoading: false,
        assessmentHistory: history,
      );
      debugPrint('Loaded ${history.length} assessment history records');
    } catch (e) {
      debugPrint('Error loading assessment history: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load history: $e',
      );
    }
  }

  /// Record a new assessment
  Future<RecordAssessmentResponse?> recordAssessment({
    required String testType,
    required double measurement,
    String? notes,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.recordAssessment(
        userId: uid,
        testType: testType,
        measurement: measurement,
        notes: notes,
      );

      // Update latest assessments
      final updatedLatest = Map<String, FlexibilityAssessment>.from(state.latestAssessments);
      updatedLatest[testType] = FlexibilityAssessment(
        id: response.assessment.id,
        userId: response.assessment.userId,
        testType: response.assessment.testType,
        measurement: response.assessment.measurement,
        unit: response.assessment.unit,
        rating: response.assessment.rating,
        percentile: response.assessment.percentile,
        notes: response.assessment.notes,
        assessedAt: response.assessment.assessedAt,
      );

      state = state.copyWith(
        isLoading: false,
        latestAssessments: updatedLatest,
        lastRecordedAssessment: response,
      );

      debugPrint('Recorded assessment: ${response.message}');

      // Refresh summary in background
      loadSummary(userId: uid);

      return response;
    } catch (e) {
      debugPrint('Error recording assessment: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to record assessment: $e',
      );
      return null;
    }
  }

  /// Load progress trend for a specific test
  Future<void> loadTestProgress({
    required String testType,
    int days = 90,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final trend = await _repository.getProgress(
        userId: uid,
        testType: testType,
        days: days,
      );

      state = state.copyWith(
        isLoading: false,
        selectedTestTrend: trend,
      );
      debugPrint('Loaded trend for $testType: ${trend.totalAssessments} assessments');
    } catch (e) {
      debugPrint('Error loading progress: $e');
      state = state.copyWith(
        isLoading: false,
        clearTrend: true,
      );
    }
  }

  /// Load stretch plans for user
  Future<void> loadStretchPlans({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final plans = await _repository.getStretchPlans(uid);
      state = state.copyWith(stretchPlans: plans);
      debugPrint('Loaded ${plans.length} stretch plans');
    } catch (e) {
      debugPrint('Error loading stretch plans: $e');
    }
  }

  /// Select a specific test for detailed view
  void selectTest(FlexibilityTest test) {
    state = state.copyWith(selectedTest: test);
  }

  /// Clear selected test
  void clearSelectedTest() {
    state = state.copyWith(clearSelectedTest: true, clearTrend: true);
  }

  /// Clear last recorded assessment
  void clearLastRecorded() {
    state = state.copyWith(clearLastRecorded: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Delete an assessment
  Future<bool> deleteAssessment(String assessmentId, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    try {
      final success = await _repository.deleteAssessment(uid, assessmentId);

      if (success) {
        // Remove from history if present
        final updatedHistory = state.assessmentHistory
            .where((a) => a.id != assessmentId)
            .toList();

        state = state.copyWith(assessmentHistory: updatedHistory);

        // Refresh latest assessments
        await loadLatestAssessments(userId: uid);
        await loadSummary(userId: uid);
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting assessment: $e');
      state = state.copyWith(error: 'Failed to delete assessment: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    await Future.wait([
      loadTests(),
      loadLatestAssessments(userId: uid),
      loadSummary(userId: uid),
      loadStretchPlans(userId: uid),
    ]);
  }
}

// ============================================
// Providers
// ============================================

/// Main flexibility provider
final flexibilityProvider =
    StateNotifierProvider<FlexibilityNotifier, FlexibilityState>((ref) {
  final repository = ref.watch(flexibilityRepositoryProvider);
  return FlexibilityNotifier(repository);
});

/// All flexibility tests (convenience provider)
final flexibilityTestsProvider = Provider<List<FlexibilityTest>>((ref) {
  return ref.watch(flexibilityProvider).tests;
});

/// Latest assessments map (convenience provider)
final latestAssessmentsProvider = Provider<Map<String, FlexibilityAssessment>>((ref) {
  return ref.watch(flexibilityProvider).latestAssessments;
});

/// Flexibility summary (convenience provider)
final flexibilitySummaryProvider = Provider<FlexibilitySummary?>((ref) {
  return ref.watch(flexibilityProvider).summary;
});

/// Selected test (convenience provider)
final selectedFlexibilityTestProvider = Provider<FlexibilityTest?>((ref) {
  return ref.watch(flexibilityProvider).selectedTest;
});

/// Selected test trend (convenience provider)
final selectedFlexibilityTrendProvider = Provider<FlexibilityTrend?>((ref) {
  return ref.watch(flexibilityProvider).selectedTestTrend;
});

/// Stretch plans (convenience provider)
final stretchPlansProvider = Provider<List<FlexibilityStretchPlan>>((ref) {
  return ref.watch(flexibilityProvider).stretchPlans;
});

/// Tests needing improvement (convenience provider)
final testsNeedingImprovementProvider = Provider<List<FlexibilityTest>>((ref) {
  return ref.watch(flexibilityProvider).testsNeedingImprovement;
});

/// Unassessed tests (convenience provider)
final unassessedTestsProvider = Provider<List<FlexibilityTest>>((ref) {
  return ref.watch(flexibilityProvider).unassessedTests;
});

/// Loading state (convenience provider)
final flexibilityLoadingProvider = Provider<bool>((ref) {
  return ref.watch(flexibilityProvider).isLoading;
});

/// Error state (convenience provider)
final flexibilityErrorProvider = Provider<String?>((ref) {
  return ref.watch(flexibilityProvider).error;
});

/// Last recorded assessment (convenience provider)
final lastRecordedAssessmentProvider = Provider<RecordAssessmentResponse?>((ref) {
  return ref.watch(flexibilityProvider).lastRecordedAssessment;
});

/// Assessment for a specific test type (family provider)
final assessmentForTestProvider =
    Provider.family<FlexibilityAssessment?, String>((ref, testType) {
  return ref.watch(flexibilityProvider).getLatestForTest(testType);
});

/// Assessment history (convenience provider)
final assessmentHistoryProvider = Provider<List<FlexibilityAssessment>>((ref) {
  return ref.watch(flexibilityProvider).assessmentHistory;
});
