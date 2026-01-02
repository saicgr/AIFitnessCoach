import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diabetes_profile.dart';
import '../models/diabetes_analytics.dart';
import '../models/glucose_reading.dart';
import '../models/insulin_dose.dart';
import '../services/api_client.dart';

// ============================================
// Diabetes Profile State & Notifier
// ============================================

/// State for diabetes profile
class DiabetesProfileState {
  final DiabetesProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const DiabetesProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  DiabetesProfileState copyWith({
    DiabetesProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return DiabetesProfileState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if profile exists
  bool get hasProfile => profile != null;

  /// Check if user uses insulin
  bool get usesInsulin => profile?.usesInsulin ?? false;

  /// Get diabetes type display name
  String get diabetesTypeDisplay =>
      profile?.diabetesTypeEnum.displayName ?? 'Not Set';

  /// Get treatment approach display name
  String get treatmentDisplay =>
      profile?.treatmentApproachEnum.displayName ?? 'Not Set';

  /// Get monitoring method display name
  String get monitoringDisplay =>
      profile?.monitoringMethodEnum.displayName ?? 'Not Set';

  /// Get target range display
  String get targetRangeDisplay {
    if (profile == null) return '70-100 mg/dL';
    return '${profile!.targetFastingMin}-${profile!.targetFastingMax} mg/dL';
  }
}

/// Notifier for diabetes profile
class DiabetesProfileNotifier extends StateNotifier<DiabetesProfileState> {
  final ApiClient _client;
  String? _currentUserId;

  DiabetesProfileNotifier(this._client) : super(const DiabetesProfileState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load diabetes profile for user
  Future<void> loadProfile({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[DiabetesProfile] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('[DiabetesProfile] Loading profile for $uid');
      final response = await _client.get(
        '/diabetes/profile',
        queryParameters: {'user_id': uid},
      );

      if (response.data != null) {
        final profile = DiabetesProfile.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        state = state.copyWith(profile: profile, isLoading: false);
        debugPrint('[DiabetesProfile] Loaded profile: ${profile.diabetesType}');
      } else {
        state = state.copyWith(isLoading: false);
        debugPrint('[DiabetesProfile] No profile found');
      }
    } catch (e) {
      debugPrint('[DiabetesProfile] Error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load diabetes profile: $e',
      );
    }
  }

  /// Create or update diabetes profile
  Future<bool> saveProfile({
    required String diabetesType,
    DateTime? diagnosisDate,
    String treatmentApproach = 'diet_exercise',
    String monitoringMethod = 'finger_prick',
    int targetFastingMin = 70,
    int targetFastingMax = 100,
    double? targetA1c,
    int hypoThreshold = 70,
    int hyperThreshold = 180,
    String glucoseUnit = 'mg/dL',
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[DiabetesProfile] No user ID for save');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      debugPrint('[DiabetesProfile] Saving profile for $uid');
      final response = await _client.post(
        '/diabetes/profile',
        data: {
          'user_id': uid,
          'diabetes_type': diabetesType,
          'diagnosis_date': diagnosisDate?.toIso8601String(),
          'treatment_approach': treatmentApproach,
          'monitoring_method': monitoringMethod,
          'target_fasting_min': targetFastingMin,
          'target_fasting_max': targetFastingMax,
          'target_a1c': targetA1c,
          'hypo_threshold': hypoThreshold,
          'hyper_threshold': hyperThreshold,
          'glucose_unit': glucoseUnit,
        },
      );

      final profile = DiabetesProfile.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      state = state.copyWith(profile: profile, isSaving: false);
      debugPrint('[DiabetesProfile] Profile saved successfully');
      return true;
    } catch (e) {
      debugPrint('[DiabetesProfile] Error saving profile: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save diabetes profile: $e',
      );
      return false;
    }
  }

  /// Update specific profile fields
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final uid = _currentUserId;
    if (uid == null || state.profile == null) {
      debugPrint('[DiabetesProfile] No user ID or profile for update');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      debugPrint('[DiabetesProfile] Updating profile for $uid');
      final response = await _client.patch(
        '/diabetes/profile/${state.profile!.id}',
        data: updates,
        queryParameters: {'user_id': uid},
      );

      final profile = DiabetesProfile.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      state = state.copyWith(profile: profile, isSaving: false);
      debugPrint('[DiabetesProfile] Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('[DiabetesProfile] Error updating profile: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update diabetes profile: $e',
      );
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh profile
  Future<void> refresh({String? userId}) async {
    await loadProfile(userId: userId);
  }
}

// ============================================
// Glucose Readings State & Notifier
// ============================================

/// State for glucose readings
class GlucoseReadingsState {
  final List<GlucoseReading> readings;
  final GlucoseReading? latestReading;
  final DailyGlucoseSummary? todaySummary;
  final List<DailyGlucoseSummary> dailySummaries;
  final bool isLoading;
  final bool isAdding;
  final String? error;

  const GlucoseReadingsState({
    this.readings = const [],
    this.latestReading,
    this.todaySummary,
    this.dailySummaries = const [],
    this.isLoading = false,
    this.isAdding = false,
    this.error,
  });

  GlucoseReadingsState copyWith({
    List<GlucoseReading>? readings,
    GlucoseReading? latestReading,
    DailyGlucoseSummary? todaySummary,
    List<DailyGlucoseSummary>? dailySummaries,
    bool? isLoading,
    bool? isAdding,
    String? error,
    bool clearError = false,
    bool clearLatest = false,
  }) {
    return GlucoseReadingsState(
      readings: readings ?? this.readings,
      latestReading:
          clearLatest ? null : (latestReading ?? this.latestReading),
      todaySummary: todaySummary ?? this.todaySummary,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      isLoading: isLoading ?? this.isLoading,
      isAdding: isAdding ?? this.isAdding,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get reading count
  int get readingCount => readings.length;

  /// Check if there are any readings
  bool get hasReadings => readings.isNotEmpty;

  /// Get latest glucose value
  int? get latestValue => latestReading?.glucoseValue;

  /// Get today's average
  double? get todayAverage => todaySummary?.avgGlucose;

  /// Get today's time in range
  double? get todayTimeInRange => todaySummary?.timeInRangePercent;
}

/// Notifier for glucose readings
class GlucoseReadingsNotifier extends StateNotifier<GlucoseReadingsState> {
  final ApiClient _client;
  String? _currentUserId;

  GlucoseReadingsNotifier(this._client) : super(const GlucoseReadingsState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load glucose readings for a date range
  Future<void> loadReadings({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[GlucoseReadings] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('[GlucoseReadings] Loading readings for $uid');
      final response = await _client.get(
        '/diabetes/glucose/readings',
        queryParameters: {
          'user_id': uid,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['readings'] ?? [];
      final readings = data
          .map((json) => GlucoseReading.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Sort by recorded_at descending
      readings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      final latest = readings.isNotEmpty ? readings.first : null;

      state = state.copyWith(
        readings: readings,
        latestReading: latest,
        isLoading: false,
      );
      debugPrint('[GlucoseReadings] Loaded ${readings.length} readings');
    } catch (e) {
      debugPrint('[GlucoseReadings] Error loading readings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load glucose readings: $e',
      );
    }
  }

  /// Load today's summary
  Future<void> loadTodaySummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[GlucoseReadings] Loading today summary for $uid');
      final response = await _client.get(
        '/diabetes/glucose/summary/today',
        queryParameters: {'user_id': uid},
      );

      final summary = DailyGlucoseSummary.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      state = state.copyWith(todaySummary: summary);
      debugPrint('[GlucoseReadings] Loaded today summary: ${summary.readingCount} readings');
    } catch (e) {
      debugPrint('[GlucoseReadings] Error loading today summary: $e');
    }
  }

  /// Load daily summaries for a date range
  Future<void> loadDailySummaries({
    String? userId,
    int daysBack = 7,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[GlucoseReadings] Loading daily summaries for $uid');
      final response = await _client.get(
        '/diabetes/glucose/summary/daily',
        queryParameters: {
          'user_id': uid,
          'days_back': daysBack,
        },
      );

      final List<dynamic> data = response.data['summaries'] ?? [];
      final summaries = data
          .map((json) =>
              DailyGlucoseSummary.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      state = state.copyWith(dailySummaries: summaries);
      debugPrint('[GlucoseReadings] Loaded ${summaries.length} daily summaries');
    } catch (e) {
      debugPrint('[GlucoseReadings] Error loading daily summaries: $e');
    }
  }

  /// Add a new glucose reading
  Future<GlucoseReading?> addReading({
    required int glucoseValue,
    required String mealContext,
    String? readingType,
    DateTime? recordedAt,
    String? notes,
    String? foodLogId,
    int? carbsConsumed,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[GlucoseReadings] No user ID for add');
      return null;
    }

    state = state.copyWith(isAdding: true, clearError: true);

    try {
      debugPrint('[GlucoseReadings] Adding reading: $glucoseValue mg/dL');
      final response = await _client.post(
        '/diabetes/glucose/readings',
        data: {
          'user_id': uid,
          'glucose_value': glucoseValue,
          'meal_context': mealContext,
          'reading_type': readingType ?? 'manual',
          'recorded_at': (recordedAt ?? DateTime.now()).toIso8601String(),
          if (notes != null) 'notes': notes,
          if (foodLogId != null) 'food_log_id': foodLogId,
          if (carbsConsumed != null) 'carbs_consumed': carbsConsumed,
        },
      );

      final reading = GlucoseReading.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      // Add to list and update latest
      final updatedReadings = [reading, ...state.readings];
      state = state.copyWith(
        readings: updatedReadings,
        latestReading: reading,
        isAdding: false,
      );

      debugPrint('[GlucoseReadings] Reading added successfully');
      return reading;
    } catch (e) {
      debugPrint('[GlucoseReadings] Error adding reading: $e');
      state = state.copyWith(
        isAdding: false,
        error: 'Failed to add glucose reading: $e',
      );
      return null;
    }
  }

  /// Delete a glucose reading
  Future<bool> deleteReading(String readingId) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      debugPrint('[GlucoseReadings] Deleting reading: $readingId');
      await _client.delete(
        '/diabetes/glucose/readings/$readingId',
        queryParameters: {'user_id': uid},
      );

      // Remove from list
      final updatedReadings =
          state.readings.where((r) => r.id != readingId).toList();
      final latest =
          updatedReadings.isNotEmpty ? updatedReadings.first : null;

      state = state.copyWith(
        readings: updatedReadings,
        latestReading: latest,
      );

      debugPrint('[GlucoseReadings] Reading deleted successfully');
      return true;
    } catch (e) {
      debugPrint('[GlucoseReadings] Error deleting reading: $e');
      return false;
    }
  }

  /// Load all glucose data
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.wait([
        loadReadings(userId: uid),
        loadTodaySummary(userId: uid),
        loadDailySummaries(userId: uid),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('[GlucoseReadings] Error loading all data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load glucose data: $e',
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

// ============================================
// Insulin Doses State & Notifier
// ============================================

/// State for insulin doses
class InsulinDosesState {
  final List<InsulinDose> doses;
  final InsulinDose? latestDose;
  final DailyInsulinSummary? todaySummary;
  final List<DailyInsulinSummary> dailySummaries;
  final bool isLoading;
  final bool isAdding;
  final String? error;

  const InsulinDosesState({
    this.doses = const [],
    this.latestDose,
    this.todaySummary,
    this.dailySummaries = const [],
    this.isLoading = false,
    this.isAdding = false,
    this.error,
  });

  InsulinDosesState copyWith({
    List<InsulinDose>? doses,
    InsulinDose? latestDose,
    DailyInsulinSummary? todaySummary,
    List<DailyInsulinSummary>? dailySummaries,
    bool? isLoading,
    bool? isAdding,
    String? error,
    bool clearError = false,
    bool clearLatest = false,
  }) {
    return InsulinDosesState(
      doses: doses ?? this.doses,
      latestDose: clearLatest ? null : (latestDose ?? this.latestDose),
      todaySummary: todaySummary ?? this.todaySummary,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      isLoading: isLoading ?? this.isLoading,
      isAdding: isAdding ?? this.isAdding,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get dose count
  int get doseCount => doses.length;

  /// Check if there are any doses
  bool get hasDoses => doses.isNotEmpty;

  /// Get today's total units
  double get todayTotalUnits => todaySummary?.totalUnits ?? 0;

  /// Get today's basal units
  double get todayBasalUnits => todaySummary?.basalUnits ?? 0;

  /// Get today's bolus units
  double get todayBolusUnits => todaySummary?.bolusUnits ?? 0;
}

/// Notifier for insulin doses
class InsulinDosesNotifier extends StateNotifier<InsulinDosesState> {
  final ApiClient _client;
  String? _currentUserId;

  InsulinDosesNotifier(this._client) : super(const InsulinDosesState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load insulin doses for a date range
  Future<void> loadDoses({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[InsulinDoses] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('[InsulinDoses] Loading doses for $uid');
      final response = await _client.get(
        '/diabetes/insulin/doses',
        queryParameters: {
          'user_id': uid,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['doses'] ?? [];
      final doses = data
          .map((json) => InsulinDose.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Sort by administered_at descending
      doses.sort((a, b) => b.administeredAt.compareTo(a.administeredAt));

      final latest = doses.isNotEmpty ? doses.first : null;

      state = state.copyWith(
        doses: doses,
        latestDose: latest,
        isLoading: false,
      );
      debugPrint('[InsulinDoses] Loaded ${doses.length} doses');
    } catch (e) {
      debugPrint('[InsulinDoses] Error loading doses: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load insulin doses: $e',
      );
    }
  }

  /// Load today's summary
  Future<void> loadTodaySummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[InsulinDoses] Loading today summary for $uid');
      final response = await _client.get(
        '/diabetes/insulin/summary/today',
        queryParameters: {'user_id': uid},
      );

      final summary = DailyInsulinSummary.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      state = state.copyWith(todaySummary: summary);
      debugPrint('[InsulinDoses] Loaded today summary: ${summary.totalUnits} units');
    } catch (e) {
      debugPrint('[InsulinDoses] Error loading today summary: $e');
    }
  }

  /// Load daily summaries for a date range
  Future<void> loadDailySummaries({
    String? userId,
    int daysBack = 7,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    try {
      debugPrint('[InsulinDoses] Loading daily summaries for $uid');
      final response = await _client.get(
        '/diabetes/insulin/summary/daily',
        queryParameters: {
          'user_id': uid,
          'days_back': daysBack,
        },
      );

      final List<dynamic> data = response.data['summaries'] ?? [];
      final summaries = data
          .map((json) =>
              DailyInsulinSummary.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      state = state.copyWith(dailySummaries: summaries);
      debugPrint('[InsulinDoses] Loaded ${summaries.length} daily summaries');
    } catch (e) {
      debugPrint('[InsulinDoses] Error loading daily summaries: $e');
    }
  }

  /// Add a new insulin dose
  Future<InsulinDose?> addDose({
    required String insulinName,
    required String insulinType,
    required double units,
    String? deliveryMethod,
    String? injectionSite,
    DateTime? administeredAt,
    String? notes,
    String? glucoseReadingId,
    int? carbsCovered,
    double? correctionUnits,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[InsulinDoses] No user ID for add');
      return null;
    }

    state = state.copyWith(isAdding: true, clearError: true);

    try {
      debugPrint('[InsulinDoses] Adding dose: $units units of $insulinName');
      final response = await _client.post(
        '/diabetes/insulin/doses',
        data: {
          'user_id': uid,
          'insulin_name': insulinName,
          'insulin_type': insulinType,
          'units': units,
          'delivery_method': deliveryMethod ?? 'pen',
          if (injectionSite != null) 'injection_site': injectionSite,
          'administered_at':
              (administeredAt ?? DateTime.now()).toIso8601String(),
          if (notes != null) 'notes': notes,
          if (glucoseReadingId != null) 'glucose_reading_id': glucoseReadingId,
          if (carbsCovered != null) 'carbs_covered': carbsCovered,
          if (correctionUnits != null) 'correction_units': correctionUnits,
        },
      );

      final dose = InsulinDose.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      // Add to list and update latest
      final updatedDoses = [dose, ...state.doses];
      state = state.copyWith(
        doses: updatedDoses,
        latestDose: dose,
        isAdding: false,
      );

      debugPrint('[InsulinDoses] Dose added successfully');
      return dose;
    } catch (e) {
      debugPrint('[InsulinDoses] Error adding dose: $e');
      state = state.copyWith(
        isAdding: false,
        error: 'Failed to add insulin dose: $e',
      );
      return null;
    }
  }

  /// Delete an insulin dose
  Future<bool> deleteDose(String doseId) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      debugPrint('[InsulinDoses] Deleting dose: $doseId');
      await _client.delete(
        '/diabetes/insulin/doses/$doseId',
        queryParameters: {'user_id': uid},
      );

      // Remove from list
      final updatedDoses = state.doses.where((d) => d.id != doseId).toList();
      final latest = updatedDoses.isNotEmpty ? updatedDoses.first : null;

      state = state.copyWith(
        doses: updatedDoses,
        latestDose: latest,
      );

      debugPrint('[InsulinDoses] Dose deleted successfully');
      return true;
    } catch (e) {
      debugPrint('[InsulinDoses] Error deleting dose: $e');
      return false;
    }
  }

  /// Load all insulin data
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.wait([
        loadDoses(userId: uid),
        loadTodaySummary(userId: uid),
        loadDailySummaries(userId: uid),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('[InsulinDoses] Error loading all data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load insulin data: $e',
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

// ============================================
// Diabetes Analytics State & Notifier
// ============================================

/// State for diabetes analytics
class DiabetesAnalyticsState {
  final DiabetesDashboard? dashboard;
  final GlucoseSummary? weekSummary;
  final GlucoseSummary? monthSummary;
  final List<PatternInsight> patternInsights;
  final WeeklyDiabetesReport? weeklyReport;
  final bool isLoading;
  final bool isLoadingReport;
  final String? error;

  const DiabetesAnalyticsState({
    this.dashboard,
    this.weekSummary,
    this.monthSummary,
    this.patternInsights = const [],
    this.weeklyReport,
    this.isLoading = false,
    this.isLoadingReport = false,
    this.error,
  });

  DiabetesAnalyticsState copyWith({
    DiabetesDashboard? dashboard,
    GlucoseSummary? weekSummary,
    GlucoseSummary? monthSummary,
    List<PatternInsight>? patternInsights,
    WeeklyDiabetesReport? weeklyReport,
    bool? isLoading,
    bool? isLoadingReport,
    String? error,
    bool clearError = false,
  }) {
    return DiabetesAnalyticsState(
      dashboard: dashboard ?? this.dashboard,
      weekSummary: weekSummary ?? this.weekSummary,
      monthSummary: monthSummary ?? this.monthSummary,
      patternInsights: patternInsights ?? this.patternInsights,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      isLoading: isLoading ?? this.isLoading,
      isLoadingReport: isLoadingReport ?? this.isLoadingReport,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if dashboard is loaded
  bool get hasDashboard => dashboard != null;

  /// Get current glucose from dashboard
  int? get currentGlucose => dashboard?.currentGlucose;

  /// Get time in range (weekly)
  double get weeklyTimeInRange => weekSummary?.timeInRangePercent ?? 0;

  /// Get time in range (monthly)
  double get monthlyTimeInRange => monthSummary?.timeInRangePercent ?? 0;

  /// Get glucose variability (CV%)
  double? get glucoseVariability => weekSummary?.glucoseVariability;

  /// Check if variability is high
  bool get hasHighVariability => weekSummary?.hasHighVariability ?? false;

  /// Get estimated A1C
  double? get estimatedA1c => dashboard?.estimatedA1c ?? monthSummary?.estimatedA1c;

  /// Get pattern count
  int get patternCount => patternInsights.length;

  /// Has high-confidence patterns
  bool get hasSignificantPatterns =>
      patternInsights.any((p) => p.isHighConfidence);
}

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

// ============================================
// Providers
// ============================================

/// Diabetes profile provider
final diabetesProfileProvider =
    StateNotifierProvider<DiabetesProfileNotifier, DiabetesProfileState>((ref) {
  final client = ref.watch(apiClientProvider);
  return DiabetesProfileNotifier(client);
});

/// Glucose readings provider
final glucoseReadingsProvider =
    StateNotifierProvider<GlucoseReadingsNotifier, GlucoseReadingsState>((ref) {
  final client = ref.watch(apiClientProvider);
  return GlucoseReadingsNotifier(client);
});

/// Insulin doses provider
final insulinDosesProvider =
    StateNotifierProvider<InsulinDosesNotifier, InsulinDosesState>((ref) {
  final client = ref.watch(apiClientProvider);
  return InsulinDosesNotifier(client);
});

/// Diabetes analytics provider
final diabetesAnalyticsProvider =
    StateNotifierProvider<DiabetesAnalyticsNotifier, DiabetesAnalyticsState>(
        (ref) {
  final client = ref.watch(apiClientProvider);
  return DiabetesAnalyticsNotifier(client);
});

// ============================================
// Convenience Providers
// ============================================

/// Quick access to diabetes profile
final diabetesProfileDataProvider = Provider<DiabetesProfile?>((ref) {
  return ref.watch(diabetesProfileProvider).profile;
});

/// Quick access to profile loading state
final diabetesProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(diabetesProfileProvider).isLoading;
});

/// Quick access to whether user has diabetes profile
final hasDiabetesProfileProvider = Provider<bool>((ref) {
  return ref.watch(diabetesProfileProvider).hasProfile;
});

/// Quick access to whether user uses insulin
final usesInsulinProvider = Provider<bool>((ref) {
  return ref.watch(diabetesProfileProvider).usesInsulin;
});

/// Quick access to latest glucose reading
final latestGlucoseReadingProvider = Provider<GlucoseReading?>((ref) {
  return ref.watch(glucoseReadingsProvider).latestReading;
});

/// Quick access to latest glucose value
final latestGlucoseValueProvider = Provider<int?>((ref) {
  return ref.watch(glucoseReadingsProvider).latestValue;
});

/// Quick access to today's glucose summary
final todayGlucoseSummaryProvider = Provider<DailyGlucoseSummary?>((ref) {
  return ref.watch(glucoseReadingsProvider).todaySummary;
});

/// Quick access to today's time in range
final todayTimeInRangeProvider = Provider<double?>((ref) {
  return ref.watch(glucoseReadingsProvider).todayTimeInRange;
});

/// Quick access to glucose readings list
final glucoseReadingsListProvider = Provider<List<GlucoseReading>>((ref) {
  return ref.watch(glucoseReadingsProvider).readings;
});

/// Quick access to glucose readings loading state
final glucoseReadingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(glucoseReadingsProvider).isLoading;
});

/// Quick access to latest insulin dose
final latestInsulinDoseProvider = Provider<InsulinDose?>((ref) {
  return ref.watch(insulinDosesProvider).latestDose;
});

/// Quick access to today's insulin summary
final todayInsulinSummaryProvider = Provider<DailyInsulinSummary?>((ref) {
  return ref.watch(insulinDosesProvider).todaySummary;
});

/// Quick access to today's total insulin units
final todayInsulinUnitsProvider = Provider<double>((ref) {
  return ref.watch(insulinDosesProvider).todayTotalUnits;
});

/// Quick access to insulin doses list
final insulinDosesListProvider = Provider<List<InsulinDose>>((ref) {
  return ref.watch(insulinDosesProvider).doses;
});

/// Quick access to insulin doses loading state
final insulinDosesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(insulinDosesProvider).isLoading;
});

/// Quick access to diabetes dashboard
final diabetesDashboardProvider = Provider<DiabetesDashboard?>((ref) {
  return ref.watch(diabetesAnalyticsProvider).dashboard;
});

/// Quick access to current glucose from dashboard
final currentDashboardGlucoseProvider = Provider<int?>((ref) {
  return ref.watch(diabetesAnalyticsProvider).currentGlucose;
});

/// Quick access to weekly time in range
final weeklyTimeInRangeProvider = Provider<double>((ref) {
  return ref.watch(diabetesAnalyticsProvider).weeklyTimeInRange;
});

/// Quick access to estimated A1C
final estimatedA1cProvider = Provider<double?>((ref) {
  return ref.watch(diabetesAnalyticsProvider).estimatedA1c;
});

/// Quick access to glucose variability
final glucoseVariabilityProvider = Provider<double?>((ref) {
  return ref.watch(diabetesAnalyticsProvider).glucoseVariability;
});

/// Quick access to pattern insights
final diabetesPatternInsightsProvider = Provider<List<PatternInsight>>((ref) {
  return ref.watch(diabetesAnalyticsProvider).patternInsights;
});

/// Quick access to analytics loading state
final diabetesAnalyticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(diabetesAnalyticsProvider).isLoading;
});

/// Quick access to weekly report
final weeklyDiabetesReportProvider = Provider<WeeklyDiabetesReport?>((ref) {
  return ref.watch(diabetesAnalyticsProvider).weeklyReport;
});

// ============================================
// Auto-Loading Provider
// ============================================

/// Auto-loading provider that loads all diabetes data when user ID is available
final diabetesDataProvider = FutureProvider.autoDispose<bool>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();

  if (userId == null) {
    return false;
  }

  // Set user ID and load data for all providers
  final profileNotifier = ref.read(diabetesProfileProvider.notifier);
  final glucoseNotifier = ref.read(glucoseReadingsProvider.notifier);
  final insulinNotifier = ref.read(insulinDosesProvider.notifier);
  final analyticsNotifier = ref.read(diabetesAnalyticsProvider.notifier);

  profileNotifier.setUserId(userId);
  glucoseNotifier.setUserId(userId);
  insulinNotifier.setUserId(userId);
  analyticsNotifier.setUserId(userId);

  // Load all data in parallel
  await Future.wait([
    profileNotifier.loadProfile(),
    glucoseNotifier.loadAll(),
    insulinNotifier.loadAll(),
    analyticsNotifier.loadDashboard(),
  ]);

  return true;
});
