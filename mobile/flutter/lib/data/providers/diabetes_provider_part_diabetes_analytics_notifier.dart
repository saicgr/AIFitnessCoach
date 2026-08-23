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
      // Path takes {user_id} as a segment, not a query param — the backend
      // has never registered `/analytics/dashboard` (client 404'd on every
      // call). Response shape is also flatter than DiabetesDashboard, so it
      // is adapted below rather than parsed with DiabetesDashboard.fromJson,
      // which expects fields (week/month summaries, pattern insights, ...)
      // this endpoint doesn't compute.
      final response = await _client.get('/diabetes/analytics/$uid/dashboard');

      final dashboard = _dashboardFromFlatResponse(
        uid,
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
      // `/diabetes/analytics/summary` was never registered on the backend
      // (404 on every call) — `/glucose/{user_id}/summary` is the real,
      // already-shipped period-summary endpoint. Its response is flatter
      // than GlucoseSummary (no time-below/above-range split, no CV), so it
      // is adapted below rather than parsed with GlucoseSummary.fromJson.
      // The backend only distinguishes daily/weekly/(else) monthly — '90days'
      // has no matching granularity yet, so it falls back to monthly rather
      // than 404ing or fabricating a custom window.
      final response = await _client.get(
        '/diabetes/glucose/$uid/summary',
        queryParameters: {'period': period == 'week' ? 'weekly' : 'monthly'},
      );

      final summary = _glucoseSummaryFromFlatResponse(
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
      // Path takes {user_id} as a segment (backend never registered
      // `/analytics/patterns`, client 404'd) and the query param is named
      // `days`, not `days_back`. Response items are `GlucosePattern`
      // (pattern_type/description/severity/recommendation) — missing the
      // `title` PatternInsight.fromJson requires (non-nullable, no default),
      // so a raw fromJson would throw; adapted below instead.
      final response = await _client.get(
        '/diabetes/analytics/$uid/patterns',
        queryParameters: {'days': daysBack},
      );

      final List<dynamic> data = response.data['patterns'] ?? [];
      final patterns = data
          .map((json) =>
              _patternInsightFromGlucosePattern(Map<String, dynamic>.from(json)))
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

/// Builds a [DiabetesDashboard] from `GET /diabetes/analytics/{user_id}/dashboard`'s
/// actual (flat) response — `current_glucose`, `current_glucose_status`,
/// `a1c_latest`, `today_insulin_total`, `readings_today`. Only `userId` and
/// `generatedAt` are non-nullable on the model; everything the backend
/// doesn't compute (week/month summaries, pattern insights, alerts, ...) is
/// left at its default rather than fabricated.
DiabetesDashboard _dashboardFromFlatResponse(
  String userId,
  Map<String, dynamic> json,
) {
  final currentGlucose = (json['current_glucose'] as num?)?.round();
  return DiabetesDashboard(
    userId: userId,
    generatedAt: DateTime.now(),
    currentGlucose: currentGlucose,
    latestA1c: (json['a1c_latest'] as num?)?.toDouble(),
    todayInsulinUnits: (json['today_insulin_total'] as num?)?.toDouble(),
    readingsToday: (json['readings_today'] as num?)?.toInt() ?? 0,
  );
}

/// Builds a [GlucoseSummary] from `GET /diabetes/glucose/{user_id}/summary`'s
/// actual (flat) response — `reading_count`, `average_glucose`, `min_glucose`,
/// `max_glucose`, `standard_deviation`. That endpoint never populates its own
/// declared `time_in_range` field, so the range-split fields are left at
/// their honest default of 0 rather than invented.
GlucoseSummary _glucoseSummaryFromFlatResponse(Map<String, dynamic> json) {
  return GlucoseSummary(
    avgGlucose: (json['average_glucose'] as num?)?.toDouble() ?? 0,
    minGlucose: (json['min_glucose'] as num?)?.round() ?? 0,
    maxGlucose: (json['max_glucose'] as num?)?.round() ?? 0,
    readingCount: (json['reading_count'] as num?)?.toInt() ?? 0,
    standardDeviation: (json['standard_deviation'] as num?)?.toDouble(),
  );
}

/// Maps the backend's `GlucosePattern` shape (`pattern_type`, `description`,
/// `severity`, `recommendation`) into a [PatternInsight]. `title` is
/// non-nullable on `PatternInsight` with no default, so a raw
/// `PatternInsight.fromJson` on this response throws — `pattern_type` doubles
/// as the title (plain-language, `dawn_phenomenon` -> `Dawn phenomenon`).
/// `severity` maps to `confidence` on a fixed, documented scale rather than a
/// fabricated statistical figure the backend doesn't compute.
PatternInsight _patternInsightFromGlucosePattern(Map<String, dynamic> json) {
  final patternType = json['pattern_type'] as String? ?? 'pattern';
  final title = patternType
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
  const severityToConfidence = {
    'urgent': 0.95,
    'high': 0.9,
    'moderate': 0.6,
    'low': 0.3,
  };
  return PatternInsight(
    patternType: patternType,
    title: title,
    description: json['description'] as String? ?? '',
    recommendation: json['recommendation'] as String?,
    confidence: severityToConfidence[json['severity'] as String?] ?? 0.5,
  );
}

