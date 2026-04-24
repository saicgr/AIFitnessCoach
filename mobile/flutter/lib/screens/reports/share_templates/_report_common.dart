import 'package:flutter/material.dart';

/// Shared types & helpers for every report share template.
///
/// Kept intentionally small: the heavy-lifting UI primitives
/// (ShareHeroNumber, ShareTrackedCaps, formatShareWeight, ShareWatermarkBadge,
/// ShareLockOverlay, ShareFooterStrip) live in
/// `lib/screens/workout/widgets/share_templates/_share_common.dart` and are
/// imported directly by each report template — no duplication.

/// The universe of reports that can flow through ReportShareSheet. One enum
/// value per Reports-Hub row so the sheet can tailor copy, hero number
/// extraction, and accent palette without a giant switch at every call site.
enum ReportType {
  personalRecords,
  muscleAnalytics,
  nutrition,
  achievements,
  milestones,
  periodInsights,
  progressCharts,
  oneRm,
  exerciseHistory,
  bodyMeasurements,
}

/// One labelled highlight row — rendered by Receipt (as line items), Stat-
/// Grid (as tiles), and Trading-Card / Wrapped (as accent strips).
///
/// [label] is rendered all-caps; the template does the uppercasing so callers
/// can keep natural-case values ("Bench Press") in their source data.
class ReportHighlight {
  final String label;
  final String value;
  const ReportHighlight({required this.label, required this.value});
}

/// Payload passed from the calling screen → ReportShareSheet → each template.
///
/// The templates intentionally read from [primaryStats] and [highlights]
/// generically — they never switch on [reportType] — so that a new report
/// can be plumbed in by the caller without a template touch.
class ReportShareData {
  /// Which report this is (drives hub copy, default accents, etc.).
  final ReportType reportType;

  /// Human title ("Personal Records"). Rendered case-preserved; templates
  /// uppercase it where their design calls for it.
  final String title;

  /// Period the report covers, already uppercased by caller ("APR 2026").
  final String periodLabel;

  /// Free-form numeric/string stats. Keys templates look up:
  ///   'hero_value'  — optional override for the big number
  ///   'hero_unit'   — optional unit label next to the hero value
  ///   'pr_count', 'top_lift', 'workouts', 'minutes', 'calories',
  ///   'streak', 'volume_kg', 'exercises_count' — used by [heroMetricFor]
  final Map<String, dynamic> primaryStats;

  /// Highlight rows to show. Empty → Receipt + StatGrid lock overlay.
  final List<ReportHighlight> highlights;

  /// User display name, nullable → falls back to 'Lifter' in templates.
  final String? userDisplayName;

  /// Avatar URL for Trading Card; null → initials pill.
  final String? userAvatarUrl;

  /// Accent color. Use the AccentColorScope value converted via
  /// `.getColor(isDark)` at the call site so we get a ready-to-render [Color].
  final Color accentColor;

  /// Deep link to the report. Null for this release — "Copy link" button is
  /// omitted by the sheet when null.
  final String? deepLinkUrl;

  const ReportShareData({
    required this.reportType,
    required this.title,
    required this.periodLabel,
    required this.primaryStats,
    required this.highlights,
    required this.accentColor,
    this.userDisplayName,
    this.userAvatarUrl,
    this.deepLinkUrl,
  });
}

// ───────────────────────── Hero extraction helpers ─────────────────────────
//
// Every template asks "what's the single hero number on this card?" and
// "what's the unit?". We centralize the lookup so templates stay thin.
//
// Resolution order:
//   1. explicit primaryStats['hero_value'] + ['hero_unit']
//   2. report-type-specific default (highest-signal stat for that report)
//   3. highlight[0] if present
//   4. '--'

/// Returns the big number that should dominate a template, as a string
/// (already formatted — no further formatting in the template).
String heroMetricFor(ReportShareData d) {
  final explicit = d.primaryStats['hero_value'];
  if (explicit != null) return explicit.toString();

  switch (d.reportType) {
    case ReportType.personalRecords:
      final n = d.primaryStats['pr_count'];
      if (n != null) return n.toString();
      break;
    case ReportType.periodInsights:
      final w = d.primaryStats['workouts'];
      if (w != null) return w.toString();
      break;
    case ReportType.exerciseHistory:
      final n = d.primaryStats['exercises_count'];
      if (n != null) return n.toString();
      break;
    case ReportType.milestones:
      final n = d.primaryStats['milestones_count'];
      if (n != null) return n.toString();
      break;
    case ReportType.nutrition:
      final n = d.primaryStats['calories'];
      if (n != null) return n.toString();
      break;
    case ReportType.achievements:
      final n = d.primaryStats['achievements_count'];
      if (n != null) return n.toString();
      break;
    case ReportType.progressCharts:
      final n = d.primaryStats['workouts'];
      if (n != null) return n.toString();
      break;
    case ReportType.oneRm:
      final n = d.primaryStats['max_1rm'];
      if (n != null) return n.toString();
      break;
    case ReportType.muscleAnalytics:
      final n = d.primaryStats['strength_score'];
      if (n != null) return n.toString();
      break;
    case ReportType.bodyMeasurements:
      final n = d.primaryStats['weight'];
      if (n != null) return n.toString();
      break;
  }

  if (d.highlights.isNotEmpty) return d.highlights.first.value;
  return '--';
}

/// Returns the unit/caption shown next to [heroMetricFor]. Empty string if
/// no obvious unit applies (count-style metrics).
String heroUnitFor(ReportShareData d) {
  final explicit = d.primaryStats['hero_unit'];
  if (explicit != null) return explicit.toString();

  switch (d.reportType) {
    case ReportType.personalRecords:
      return 'PRs';
    case ReportType.periodInsights:
      return 'workouts';
    case ReportType.exerciseHistory:
      return 'exercises';
    case ReportType.milestones:
      return 'milestones';
    case ReportType.nutrition:
      return 'kcal';
    case ReportType.achievements:
      return 'earned';
    case ReportType.progressCharts:
      return 'workouts';
    case ReportType.oneRm:
      return '1RM';
    case ReportType.muscleAnalytics:
      return 'score';
    case ReportType.bodyMeasurements:
      return '';
  }
}

/// Returns up to 3 short (label, value) substats shown beneath the hero.
///
/// Derived by taking highlights beyond the hero when applicable, otherwise
/// falling back to report-specific stat bundles.
List<ReportHighlight> subStatsFor(ReportShareData d) {
  // If caller provided highlights, those are the substats (capped to 3).
  if (d.highlights.isNotEmpty) {
    return d.highlights.take(3).toList();
  }

  // Otherwise, synthesize from primaryStats. We pick at most 3 keys in a
  // domain-appropriate order.
  final subs = <ReportHighlight>[];
  void add(String label, dynamic v) {
    if (v == null || subs.length >= 3) return;
    subs.add(ReportHighlight(label: label, value: v.toString()));
  }

  switch (d.reportType) {
    case ReportType.periodInsights:
      add('MINUTES', d.primaryStats['minutes']);
      add('CALORIES', d.primaryStats['calories']);
      add('STREAK', d.primaryStats['streak']);
      break;
    case ReportType.personalRecords:
      add('TOP LIFT', d.primaryStats['top_lift']);
      add('VOLUME', d.primaryStats['volume']);
      add('SESSIONS', d.primaryStats['sessions']);
      break;
    case ReportType.nutrition:
      add('PROTEIN', d.primaryStats['protein']);
      add('CARBS', d.primaryStats['carbs']);
      add('FAT', d.primaryStats['fat']);
      break;
    case ReportType.milestones:
      add('POINTS', d.primaryStats['points']);
      add('TIER', d.primaryStats['tier']);
      add('NEXT', d.primaryStats['next']);
      break;
    case ReportType.progressCharts:
      add('VOLUME', d.primaryStats['volume']);
      add('DAYS', d.primaryStats['days']);
      add('GAIN', d.primaryStats['gain']);
      break;
    case ReportType.exerciseHistory:
      add('TOP PICK', d.primaryStats['top_exercise']);
      add('SESSIONS', d.primaryStats['sessions']);
      add('STREAK', d.primaryStats['streak']);
      break;
    case ReportType.oneRm:
      add('SQUAT', d.primaryStats['squat']);
      add('BENCH', d.primaryStats['bench']);
      add('DEADLIFT', d.primaryStats['deadlift']);
      break;
    case ReportType.muscleAnalytics:
      add('TOP GROUP', d.primaryStats['top_group']);
      add('AVG SCORE', d.primaryStats['avg_score']);
      add('SETS', d.primaryStats['sets']);
      break;
    case ReportType.bodyMeasurements:
      add('BODY FAT', d.primaryStats['body_fat']);
      add('WAIST', d.primaryStats['waist']);
      add('CHEST', d.primaryStats['chest']);
      break;
    case ReportType.achievements:
      add('TROPHIES', d.primaryStats['trophies']);
      add('RARE', d.primaryStats['rare']);
      add('STREAK', d.primaryStats['streak']);
      break;
  }
  return subs;
}

/// Default gradient seeded from the accent color — templates that want a
/// solid accent-tinted canvas (Classic, Wrapped) use this so their
/// background tracks whatever accent the user picked in settings.
List<Color> accentGradient(Color accent) {
  return [
    Color.lerp(accent, Colors.black, 0.35)!,
    Color.lerp(accent, Colors.black, 0.7)!,
    const Color(0xFF05050A),
  ];
}

/// Two-letter initials from a display name. Falls back to 'YOU'.
String initialsOf(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return 'YOU';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts[1][0]).toUpperCase();
}
