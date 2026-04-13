import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/insights_report.dart';
import '../repositories/weekly_summary_repository.dart';

/// Available time periods for insights.
///
/// `days` is a stable trailing-window size for the fixed periods. For
/// [yearToDate] it's `-1` as a sentinel — the effective start date is
/// January 1st of the current year, resolved by [InsightsNotifier] rather
/// than read off the enum. Custom ranges bypass this enum entirely via
/// [InsightsState.customRange].
enum InsightsPeriod {
  oneWeek('1W', 'Weekly', 7),
  oneMonth('1M', 'Monthly', 30),
  threeMonths('3M', 'Quarterly', 90),
  sixMonths('6M', 'Half-Year', 180),
  oneYear('1Y', 'Yearly', 365),
  yearToDate('YTD', 'Year-to-Date', -1);

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
      case InsightsPeriod.yearToDate:
        // YTD spans up to ~12 months — bucket by month for readable charts.
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

  /// User-picked arbitrary date range. When non-null it takes precedence
  /// over [selectedPeriod] — the screen shows "Custom" in the period selector
  /// and every downstream date-range derivation uses these bounds.
  final DateTimeRange? customRange;

  const InsightsState({
    this.selectedPeriod = InsightsPeriod.oneWeek,
    this.report,
    this.narrative,
    this.isLoadingReport = false,
    this.isGeneratingNarrative = false,
    this.error,
    this.customRange,
  });

  /// True when a user-supplied custom range is active.
  bool get isCustomRange => customRange != null;

  InsightsState copyWith({
    InsightsPeriod? selectedPeriod,
    InsightsReport? report,
    InsightsAiNarrative? narrative,
    bool? isLoadingReport,
    bool? isGeneratingNarrative,
    String? error,
    DateTimeRange? customRange,
    bool clearNarrative = false,
    bool clearReport = false,
    bool clearCustomRange = false,
  }) {
    return InsightsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      report: clearReport ? null : (report ?? this.report),
      narrative: clearNarrative ? null : (narrative ?? this.narrative),
      isLoadingReport: isLoadingReport ?? this.isLoadingReport,
      isGeneratingNarrative: isGeneratingNarrative ?? this.isGeneratingNarrative,
      error: error,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
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

  /// Effective start date given current (selectedPeriod, customRange, YTD).
  /// Custom range wins; otherwise YTD resolves to Jan 1 this year; otherwise
  /// the selectedPeriod.days trailing window.
  DateTime get _startDateTime {
    final now = DateTime.now();
    final range = state.customRange;
    if (range != null) return range.start;
    if (state.selectedPeriod == InsightsPeriod.yearToDate) {
      return DateTime(now.year, 1, 1);
    }
    return now.subtract(Duration(days: state.selectedPeriod.days));
  }

  DateTime get _endDateTime {
    final range = state.customRange;
    if (range != null) return range.end;
    return DateTime.now();
  }

  String get _startDate => _dateFormat.format(_startDateTime);
  String get _endDate => _dateFormat.format(_endDateTime);

  /// groupBy bucket size for the current range. Custom ranges pick a sane
  /// bucket from the total span: <= 31 days → day, <= 180 days → week,
  /// otherwise month.
  String get _groupBy {
    final range = state.customRange;
    if (range == null) return state.selectedPeriod.groupBy;
    final totalDays = range.end.difference(range.start).inDays;
    if (totalDays <= 31) return 'day';
    if (totalDays <= 180) return 'week';
    return 'month';
  }

  /// Period label shown to the AI generator and pill UI. Custom/YTD fall
  /// back to descriptive strings instead of the enum's periodLabel.
  String get _periodLabel {
    if (state.customRange != null) return 'Custom';
    return state.selectedPeriod.periodLabel;
  }

  /// Select a new time period and load data. Clears any active custom range.
  Future<void> selectPeriod(InsightsPeriod period, String userId) async {
    state = state.copyWith(
      selectedPeriod: period,
      clearReport: true,
      clearNarrative: true,
      clearCustomRange: true,
    );
    await loadReport(userId);
  }

  /// Apply a user-picked custom date range and reload.
  Future<void> setCustomRange(DateTimeRange range, String userId) async {
    state = state.copyWith(
      customRange: range,
      clearReport: true,
      clearNarrative: true,
    );
    await loadReport(userId);
  }

  /// Clear a custom range (falls back to the last-selected preset period).
  Future<void> clearCustomRange(String userId) async {
    state = state.copyWith(
      clearCustomRange: true,
      clearReport: true,
      clearNarrative: true,
    );
    await loadReport(userId);
  }

  /// Load report data for the selected period.
  ///
  /// Stale-while-revalidate: if the repository has a fresh cached report for
  /// the same (user, period) key we emit it immediately so the screen paints
  /// without a skeleton, then refresh from the network in the background and
  /// update when it returns. The user-perceived load time on a period toggle
  /// inside the same session is zero.
  Future<void> loadReport(String userId) async {
    final startDate = _startDate;
    final endDate = _endDate;
    final groupBy = _groupBy;

    final cached = _repository.getCachedInsightsReport(
      userId,
      startDate: startDate,
      endDate: endDate,
      groupBy: groupBy,
    );

    if (cached != null) {
      // Paint cached data; keep isLoadingReport=false so the skeleton stays
      // hidden. Background refresh below will overwrite with fresh data.
      state = state.copyWith(isLoadingReport: false, report: cached, error: null);
    } else {
      state = state.copyWith(isLoadingReport: true, error: null);
    }

    try {
      final report = await _repository.getInsightsReport(
        userId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );
      state = state.copyWith(isLoadingReport: false, report: report);
    } catch (e) {
      // If we had cached data, keep it on screen and surface the error quietly.
      state = state.copyWith(
        isLoadingReport: false,
        error: e.toString(),
      );
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
        periodLabel: _periodLabel,
      );
      state = state.copyWith(isGeneratingNarrative: false, narrative: narrative);
    } catch (e) {
      state = state.copyWith(isGeneratingNarrative: false, error: e.toString());
    }
  }
}
