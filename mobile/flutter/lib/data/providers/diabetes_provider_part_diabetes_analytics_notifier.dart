part of 'diabetes_provider.dart';


/// Notifier for diabetes analytics
class DiabetesAnalyticsNotifier extends StateNotifier<DiabetesAnalyticsState> {
  final ApiClient _client;
  String? _currentUserId;

  DiabetesAnalyticsNotifier(this._client)
      : super(const DiabetesAnalyticsState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load comprehensive dashboard
  Future<void> loadDashboard({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[DiabetesAnalytics] No user ID, skipping dashboard load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('[DiabetesAnalytics] Loading dashboard for $uid');
      final response = await _client.get(
        '/diabetes/analytics/dashboard',
        queryParameters: {'user_id': uid},
      );

      final dashboard = DiabetesDashboard.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      state = state.copyWith(
        dashboard: dashboard,
        weekSummary: dashboard.weekSummary,
        monthSummary: dashboard.monthSummary,
        patternInsights: dashboard.patternInsights,
        isLoading: false,
      );
      debugPrint('[DiabetesAnalytics] Dashboard loaded successfully');
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading dashboard: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load diabetes dashboard: $e',
      );
    }
  }

  /// Load glucose summary for a period
  Future<void> loadSummary({
    String? userId,
    required String period, // 'week', 'month', '90days'
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[DiabetesAnalytics] Loading $period summary for $uid');
      final response = await _client.get(
        '/diabetes/analytics/summary',
        queryParameters: {
          'user_id': uid,
          'period': period,
        },
      );

      final summary = GlucoseSummary.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      if (period == 'week') {
        state = state.copyWith(weekSummary: summary);
      } else if (period == 'month') {
        state = state.copyWith(monthSummary: summary);
      }

      debugPrint('[DiabetesAnalytics] Loaded $period summary');
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading $period summary: $e');
    }
  }

  /// Load pattern insights
  Future<void> loadPatterns({String? userId, int daysBack = 30}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[DiabetesAnalytics] Loading patterns for $uid');
      final response = await _client.get(
        '/diabetes/analytics/patterns',
        queryParameters: {
          'user_id': uid,
          'days_back': daysBack,
        },
      );

      final List<dynamic> data = response.data['patterns'] ?? [];
      final patterns = data
          .map((json) =>
              PatternInsight.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      state = state.copyWith(patternInsights: patterns);
      debugPrint('[DiabetesAnalytics] Loaded ${patterns.length} patterns');
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading patterns: $e');
    }
  }

  /// Load weekly report
  Future<void> loadWeeklyReport({String? userId, DateTime? weekStart}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    state = state.copyWith(isLoadingReport: true);

    try {
      debugPrint('[DiabetesAnalytics] Loading weekly report for $uid');
      final response = await _client.get(
        '/diabetes/analytics/weekly-report',
        queryParameters: {
          'user_id': uid,
          if (weekStart != null) 'week_start': weekStart.toIso8601String(),
        },
      );

      final report = WeeklyDiabetesReport.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      state = state.copyWith(
        weeklyReport: report,
        isLoadingReport: false,
      );
      debugPrint('[DiabetesAnalytics] Weekly report loaded');
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading weekly report: $e');
      state = state.copyWith(isLoadingReport: false);
    }
  }

  /// Get time in range data for charts
  Future<List<Map<String, dynamic>>> getTimeInRangeHistory({
    String? userId,
    int daysBack = 30,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return [];

    try {
      debugPrint('[DiabetesAnalytics] Loading TIR history for $uid');
      final response = await _client.get(
        '/diabetes/analytics/time-in-range',
        queryParameters: {
          'user_id': uid,
          'days_back': daysBack,
        },
      );

      final List<dynamic> data = response.data['history'] ?? [];
      return data.map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading TIR history: $e');
      return [];
    }
  }

  /// Load all analytics data
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.wait([
        loadDashboard(userId: uid),
        loadPatterns(userId: uid),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('[DiabetesAnalytics] Error loading all data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics data: $e',
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }
}

