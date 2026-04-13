import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/providers/insights_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../widgets/share_template_sheet.dart';
import 'share_templates/insights_narrative_template.dart';
import 'share_templates/insights_progress_template.dart';
import 'share_templates/insights_prs_template.dart';
import 'share_templates/insights_report_card_template.dart';
import 'share_templates/insights_streak_template.dart';
import 'share_templates/insights_summary_template.dart';

/// Opens the share-template carousel for the current insights period.
///
/// 6 templates, each period-aware via [periodName]:
/// Report Card / Summary / AI / PRs / Streak / Body.
///
/// Supports every period the Reports & Insights screen exposes:
/// 1W / 1M / 3M / 6M / 1Y / YTD / Custom. The periodName renders as the
/// hero title on each slide so the recipient instantly knows the timeframe.
class ShareInsightsSheet {
  const ShareInsightsSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final state = ref.read(insightsProvider);
    final report = state.report;
    final totals = report?.totals;
    final prev = report?.previousTotals;
    final period = state.selectedPeriod;
    final narrative = state.narrative;
    final customRange = state.customRange;

    // Pull recent PRs once so the PRs slide can render a real list.
    final prStats = ref.read(prStatsProvider);
    final prRows = (prStats?.recentPrs ?? const []).take(4).map((pr) {
      final date = DateTime.tryParse(pr.achievedAt);
      final dateStr = date != null ? DateFormat('MMM d').format(date) : '';
      final weight = pr.weightKg.toStringAsFixed(0);
      final detail = dateStr.isEmpty
          ? '${weight}kg x ${pr.reps}'
          : '${weight}kg • $dateStr';
      return PrDisplayRow(
        exerciseName: pr.exerciseDisplayName,
        detail: detail,
      );
    }).toList();

    final periodName = _periodName(period, customRange);
    final shortLabel = _shortLabel(period, customRange);
    final dateRange = _dateRange(report, period, customRange);

    await ShareTemplateSheet.show(
      context: context,
      title: 'Share Report',
      caption: 'My FitWiz ${periodName.toLowerCase()} report',
      subject: 'My FitWiz Report',
      templatesBuilder: (showWatermark) => [
        ShareTemplateDef(
          name: 'Report',
          backgroundGradient: const [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          content: InsightsReportCardTemplate(
            periodName: periodName,
            dateRangeLabel: dateRange,
            workoutsCompleted: totals?.workoutsCompleted ?? 0,
            workoutsScheduled: totals?.workoutsScheduled ?? 0,
            totalTimeMinutes: totals?.totalTimeMinutes ?? 0,
            totalCalories: totals?.totalCalories ?? 0,
            totalPrs: totals?.totalPrs ?? 0,
            maxStreak: totals?.maxStreak ?? 0,
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'Summary',
          backgroundGradient: const [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF0D1117),
          ],
          content: InsightsSummaryTemplate(
            periodLabel: shortLabel,
            periodName: periodName,
            dateRangeLabel: dateRange,
            workoutsCompleted: totals?.workoutsCompleted ?? 0,
            totalTimeMinutes: totals?.totalTimeMinutes ?? 0,
            totalCalories: totals?.totalCalories ?? 0,
            totalPrs: totals?.totalPrs ?? 0,
            prevWorkouts: prev?.workoutsCompleted,
            prevTimeMinutes: prev?.totalTimeMinutes,
            prevCalories: prev?.totalCalories,
            prevPrs: prev?.totalPrs,
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'AI',
          backgroundGradient: const [
            Color(0xFF0F1724),
            Color(0xFF0B2B3F),
            Color(0xFF062029),
          ],
          content: InsightsNarrativeTemplate(
            periodLabel: shortLabel,
            periodName: periodName,
            summary: narrative?.summary,
            highlights: narrative?.highlights ?? const [],
            tips: narrative?.tips ?? const [],
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'PRs',
          backgroundGradient: const [
            Color(0xFF1A1008),
            Color(0xFF422006),
            Color(0xFF1A1008),
          ],
          content: InsightsPrsTemplate(
            periodName: periodName,
            dateRangeLabel: dateRange,
            totalPrs: totals?.totalPrs ?? 0,
            prs: prRows,
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'Streak',
          backgroundGradient: const [
            Color(0xFF1C1917),
            Color(0xFF7F1D1D),
            Color(0xFF1C1917),
          ],
          content: InsightsStreakTemplate(
            periodName: periodName,
            dateRangeLabel: dateRange,
            maxStreak: totals?.maxStreak ?? 0,
            workoutsCompleted: totals?.workoutsCompleted ?? 0,
            workoutsScheduled: totals?.workoutsScheduled ?? 0,
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'Body',
          backgroundGradient: const [
            Color(0xFF180C2E),
            Color(0xFF2D1B4E),
            Color(0xFF180C2E),
          ],
          content: InsightsProgressTemplate(
            periodLabel: shortLabel,
            periodName: periodName,
            dateRangeLabel: dateRange,
            maxStreak: totals?.maxStreak ?? 0,
            weightChangeKg: totals?.weightChangeKg,
            bodyFatChange: totals?.bodyFatChange,
            avgReadiness: totals?.avgReadiness,
            avgNutritionAdherence: totals?.avgNutritionAdherence,
            showWatermark: showWatermark,
          ),
        ),
      ],
    );
  }

  /// Hero title for each template: "WEEKLY", "MONTHLY", "QUARTERLY",
  /// "HALF-YEAR", "YEARLY", "YTD", or "CUSTOM".
  static String _periodName(InsightsPeriod period, DateTimeRange? custom) {
    if (custom != null) return 'CUSTOM';
    switch (period) {
      case InsightsPeriod.oneWeek:
        return 'WEEKLY';
      case InsightsPeriod.oneMonth:
        return 'MONTHLY';
      case InsightsPeriod.threeMonths:
        return 'QUARTERLY';
      case InsightsPeriod.sixMonths:
        return 'HALF-YEAR';
      case InsightsPeriod.oneYear:
        return 'YEARLY';
      case InsightsPeriod.yearToDate:
        return 'YTD';
    }
  }

  /// Short chip label (e.g. "1W", "YTD", "CUSTOM"). Used by templates that
  /// already show a small period chip in the header row.
  static String _shortLabel(InsightsPeriod period, DateTimeRange? custom) {
    if (custom != null) return 'CUSTOM';
    return period.label;
  }

  static String _dateRange(
    dynamic report,
    InsightsPeriod period,
    DateTimeRange? custom,
  ) {
    if (custom != null) {
      return _formatRange(
          DateFormat('yyyy-MM-dd').format(custom.start),
          DateFormat('yyyy-MM-dd').format(custom.end));
    }
    if (report != null) {
      return _formatRange(report.startDate as String, report.endDate as String);
    }
    return _fallbackDateRange(period);
  }

  static String _formatRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      if (s.year != e.year) {
        return '${DateFormat('MMM d, yyyy').format(s)} - ${DateFormat('MMM d, yyyy').format(e)}';
      }
      if (s.month == e.month) {
        return '${DateFormat('MMM d').format(s)} - ${e.day}';
      }
      return '${DateFormat('MMM d').format(s)} - ${DateFormat('MMM d').format(e)}';
    } catch (_) {
      return '$start - $end';
    }
  }

  static String _fallbackDateRange(InsightsPeriod period) {
    final end = DateTime.now();
    final start = period == InsightsPeriod.yearToDate
        ? DateTime(end.year, 1, 1)
        : end.subtract(Duration(days: period.days));
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
  }
}
