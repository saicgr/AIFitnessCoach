import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
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

class FlexibilityNotifier extends StateNotifier<FlexibilityState>
    with CacheFirstMixin {
  final FlexibilityRepository _repository;
  String? _currentUserId;

  FlexibilityNotifier(this._repository) : super(const FlexibilityState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all flexibility tests — cache-first.
  ///
  /// The test catalogue is global reference data that changes rarely, so it is
  /// stored under a global slot with a long TTL. A valid disk blob renders the
  /// All-Tests tab instantly on a cold start.
  Future<void> loadTests() async {
    // Only block on the loading flag when there is genuinely nothing to show.
    if (state.tests.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    await loadCacheFirst<List<FlexibilityTest>>(
      cacheKey: 'flexibility_tests',
      // Global reference data — no user scoping. The mixin tolerates an empty
      // userId by sharing a single global slot, which is exactly right here.
      userId: '',
      ttl: const Duration(days: 7),
      fetch: () => _repository.getFlexibilityTests(),
      decode: (json) => (json['items'] as List<dynamic>)
          .map((e) => FlexibilityTest.fromJson(e as Map<String, dynamic>))
          .toList(),
      encode: (tests) => {'items': tests.map((t) => t.toJson()).toList()},
      emit: (tests, {required bool fromCache}) {
        state = state.copyWith(isLoading: false, tests: tests);
      },
      onError: (e, _) {
        if (state.tests.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load flexibility tests: $e',
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
    );
  }

  /// Load user's latest assessments — cache-first.
  Future<void> loadLatestAssessments({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('No user ID, skipping load latest assessments');
      return;
    }
    _currentUserId = uid;

    if (state.latestAssessments.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    await loadCacheFirst<Map<String, FlexibilityAssessment>>(
      cacheKey: 'flexibility_latest_assessments',
      userId: uid,
      ttl: const Duration(hours: 12),
      fetch: () async {
        final assessments = await _repository.getLatestAssessments(uid);
        final latestMap = <String, FlexibilityAssessment>{};
        for (final a in assessments) {
          latestMap[a.testType] = a;
        }
        return latestMap;
      },
      decode: (json) => (json['items'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
              k, FlexibilityAssessment.fromJson(v as Map<String, dynamic>))),
      encode: (map) =>
          {'items': map.map((k, v) => MapEntry(k, v.toJson()))},
      emit: (latestMap, {required bool fromCache}) {
        state = state.copyWith(isLoading: false, latestAssessments: latestMap);
      },
      onError: (e, _) {
        if (state.latestAssessments.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load assessments: $e',
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
    );
  }

  /// Load user's flexibility summary — cache-first.
  Future<void> loadSummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    await loadCacheFirst<FlexibilitySummary>(
      cacheKey: 'flexibility_summary',
      userId: uid,
      ttl: const Duration(hours: 12),
      fetch: () => _repository.getSummary(uid),
      decode: FlexibilitySummary.fromJson,
      encode: (s) => s.toJson(),
      emit: (summary, {required bool fromCache}) {
        state = state.copyWith(summary: summary);
      },
      // Summary is non-critical — errors stay silent (matches prior behaviour).
    );
  }

  /// Load assessment history for a specific test type — cache-first.
  ///
  /// The cache slot is keyed by the test-type filter (or 'all' for the
  /// unfiltered history) so per-test views never share a slot.
  Future<void> loadAssessmentHistory({
    String? userId,
    String? testType,
    int limit = 50,
    int? days,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    if (state.assessmentHistory.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    await loadCacheFirst<List<FlexibilityAssessment>>(
      cacheKey: 'flexibility_history_${testType ?? 'all'}',
      userId: uid,
      ttl: const Duration(hours: 12),
      fetch: () => _repository.getAssessmentHistory(
        userId: uid,
        testType: testType,
        limit: limit,
        days: days,
      ),
      decode: (json) => (json['items'] as List<dynamic>)
          .map((e) =>
              FlexibilityAssessment.fromJson(e as Map<String, dynamic>))
          .toList(),
      encode: (list) => {'items': list.map((a) => a.toJson()).toList()},
      emit: (history, {required bool fromCache}) {
        state = state.copyWith(isLoading: false, assessmentHistory: history);
      },
      onError: (e, _) {
        if (state.assessmentHistory.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load history: $e',
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
    );
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

  /// Load stretch plans for user — cache-first.
  Future<void> loadStretchPlans({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    await loadCacheFirst<List<FlexibilityStretchPlan>>(
      cacheKey: 'flexibility_stretch_plans',
      userId: uid,
      ttl: const Duration(hours: 12),
      fetch: () => _repository.getStretchPlans(uid),
      decode: (json) => (json['items'] as List<dynamic>)
          .map((e) =>
              FlexibilityStretchPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      encode: (list) => {'items': list.map((p) => p.toJson()).toList()},
      emit: (plans, {required bool fromCache}) {
        state = state.copyWith(stretchPlans: plans);
      },
      // Stretch plans are non-critical — errors stay silent (matches prior).
    );
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
