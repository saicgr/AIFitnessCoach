import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/weekly_summary.dart';
import '../../../widgets/share_template_sheet.dart';
import 'share_templates/weekly_highlights_template.dart';
import 'share_templates/weekly_prs_template.dart';
import 'share_templates/weekly_recap_template.dart';

/// Opens the share-template carousel for a single [WeeklySummary].
///
/// Three templates: Recap (completion + stats), PRs (weekly records),
/// Highlights (AI narrative). Each template silently handles its own empty
/// state so zero-PR / no-narrative weeks still look intentional.
class ShareWeeklySummarySheet {
  const ShareWeeklySummarySheet._();

  static Future<void> show(
    BuildContext context,
    WeeklySummary summary,
  ) async {
    final dateRange = _formatWeekRange(summary.weekStart, summary.weekEnd);
    final prDetails = _parsePrDetails(summary.prDetails);

    await ShareTemplateSheet.show(
      context: context,
      title: 'Share Your Week',
      caption: 'My FitWiz week — $dateRange',
      subject: 'My FitWiz Weekly Report',
      templatesBuilder: (showWatermark) => [
        ShareTemplateDef(
          name: 'Recap',
          backgroundGradient: const [
            Color(0xFF0B1220),
            Color(0xFF1E1B4B),
            Color(0xFF0B1220),
          ],
          content: WeeklyRecapTemplate(
            dateRangeLabel: dateRange,
            workoutsCompleted: summary.workoutsCompleted,
            workoutsScheduled: summary.workoutsScheduled,
            totalTimeMinutes: summary.totalTimeMinutes,
            currentStreak: summary.currentStreak,
            prsAchieved: summary.prsAchieved,
            aiSummaryPreview: summary.aiSummary,
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
          content: WeeklyPrsTemplate(
            prDetails: prDetails,
            prsAchieved: summary.prsAchieved,
            dateRangeLabel: dateRange,
            showWatermark: showWatermark,
          ),
        ),
        ShareTemplateDef(
          name: 'Highlights',
          backgroundGradient: const [
            Color(0xFF0F0A2E),
            Color(0xFF2E1065),
            Color(0xFF1E1045),
          ],
          content: WeeklyHighlightsTemplate(
            dateRangeLabel: dateRange,
            aiSummary: summary.aiSummary,
            highlights: summary.aiHighlights ?? const [],
            encouragement: summary.aiEncouragement,
            showWatermark: showWatermark,
          ),
        ),
      ],
    );
  }

  /// WeeklySummary.prDetails is `List<Map>?` in the model but the concrete
  /// runtime type may be `List<dynamic>` or `List<Map<String, dynamic>>`
  /// depending on how it was deserialized. Normalize defensively so the
  /// template can iterate safely.
  static List<Map<String, dynamic>> _parsePrDetails(List<dynamic>? raw) {
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  static String _formatWeekRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      if (s.month == e.month) {
        return '${DateFormat('MMM d').format(s)} - ${e.day}';
      }
      return '${DateFormat('MMM d').format(s)} - ${DateFormat('MMM d').format(e)}';
    } catch (_) {
      return '$start - $end';
    }
  }
}
