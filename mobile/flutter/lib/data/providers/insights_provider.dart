import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/insights_report.dart';
import '../repositories/weekly_summary_repository.dart';

/// Available time periods for insights
enum InsightsPeriod {
  oneWeek('1W', 'Weekly', 7),
  oneMonth('1M', 'Monthly', 30),
  threeMonths('3M', 'Quarterly', 90),
  sixMonths('6M', 'Half-Year', 180),
  oneYear('1Y', 'Yearly', 365);

  final String label;
  final String periodLabel;
  final int days;
  const InsightsPeriod(this.label, this.periodLabel, this.days);

  String get groupBy {
    switch (this) {
      case InsightsPeriod.oneWeek:
      case InsightsPeriod.oneMonth:
        return 'day';
      case InsightsPeriod.threeMonths:
      case InsightsPeriod.sixMonths:
        return 'week';
      case InsightsPeriod.oneYear:
        return 'month';
    }
  }
}

/// State for the insights screen
class InsightsState {
  final InsightsPeriod selectedPeriod;
  final InsightsReport? report;
  final InsightsAiNarrative? narrative;
  final bool isLoadingReport;
  final bool isGeneratingNarrative;
  final String? error;

  const InsightsState({
    this.selectedPeriod = InsightsPeriod.oneWeek,
    this.report,
    this.narrative,
    this.isLoadingReport = false,
    this.isGeneratingNarrative = false,
    this.error,
  });

  InsightsState copyWith({
    InsightsPeriod? selectedPeriod,
    InsightsReport? report,
    InsightsAiNarrative? narrative,
    bool? isLoadingReport,
    bool? isGeneratingNarrative,
    String? error,
    bool clearNarrative = false,
    bool clearReport = false,
  }) {
    return InsightsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      report: clearReport ? null : (report ?? this.report),
      narrative: clearNarrative ? null : (narrative ?? this.narrative),
      isLoadingReport: isLoadingReport ?? this.isLoadingReport,
      isGeneratingNarrative: isGeneratingNarrative ?? this.isGeneratingNarrative,
      error: error,
    );
  }
}

/// Provider for insights state management
final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier(ref.watch(weeklySummaryRepositoryProvider));
});

class InsightsNotifier extends StateNotifier<InsightsState> {
  final WeeklySummaryRepository _repository;

  InsightsNotifier(this._repository) : super(const InsightsState());

  final _dateFormat = DateFormat('yyyy-MM-dd');

  String get _startDate {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: state.selectedPeriod.days));
    return _dateFormat.format(start);
  }

  String get _endDate => _dateFormat.format(DateTime.now());

  /// Select a new time period and load data
  Future<void> selectPeriod(InsightsPeriod period, String userId) async {
    state = state.copyWith(
      selectedPeriod: period,
      clearReport: true,
      clearNarrative: true,
    );
    await loadReport(userId);
  }

  /// Load report data for the selected period
  Future<void> loadReport(String userId) async {
    state = state.copyWith(isLoadingReport: true, error: null);
    try {
      final report = await _repository.getInsightsReport(
        userId,
        startDate: _startDate,
        endDate: _endDate,
        groupBy: state.selectedPeriod.groupBy,
      );
      state = state.copyWith(isLoadingReport: false, report: report);
    } catch (e) {
      state = state.copyWith(isLoadingReport: false, error: e.toString());
    }
  }

  /// Generate AI narrative for the selected period
  Future<void> generateNarrative(String userId) async {
    if (state.isGeneratingNarrative) return;
    state = state.copyWith(isGeneratingNarrative: true, error: null);
    try {
      final narrative = await _repository.generateInsightNarrative(
        userId,
        startDate: _startDate,
        endDate: _endDate,
        periodLabel: state.selectedPeriod.periodLabel,
      );
      state = state.copyWith(isGeneratingNarrative: false, narrative: narrative);
    } catch (e) {
      state = state.copyWith(isGeneratingNarrative: false, error: e.toString());
    }
  }
}
