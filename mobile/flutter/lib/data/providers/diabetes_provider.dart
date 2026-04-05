import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diabetes_profile.dart';
import '../models/diabetes_analytics.dart';
import '../models/glucose_reading.dart';
import '../models/insulin_dose.dart';
import '../services/api_client.dart';

part 'diabetes_provider_part_diabetes_profile_notifier.dart';
part 'diabetes_provider_part_diabetes_analytics_notifier.dart';


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
