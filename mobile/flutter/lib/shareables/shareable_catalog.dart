import 'package:flutter/material.dart';

import 'shareable_data.dart';
import 'templates/achievement_hero_template.dart';
import 'templates/activity_overview.dart';
import 'templates/activity_rings_template.dart';
import 'templates/boarding_pass_template.dart';
import 'templates/calendar_heatmap_template.dart';
import 'templates/chat_bubble_template.dart';
import 'templates/daily_workout_card_template.dart';
import 'templates/monthly_plan_grid_template.dart';
import 'templates/weekly_plan_grid_template.dart';
import 'templates/coach_review_template.dart';
import 'templates/elite_template.dart';
import 'templates/exercise_showcase_template.dart';
import 'templates/level_up_template.dart';
import 'templates/magazine_cover_template.dart';
import 'templates/minimal_template.dart';
import 'templates/muscle_map_template.dart';
import 'templates/news_template.dart';
import 'templates/now_playing_template.dart';
import 'templates/photo_before_after_template.dart';
import 'templates/photo_lockscreen_template.dart';
import 'templates/photo_magazine_template.dart';
import 'templates/photo_quote_template.dart';
import 'templates/photo_split_template.dart';
import 'templates/photo_stats_template.dart';
import 'templates/polaroid_template.dart';
import 'templates/pr_prediction_template.dart';
import 'templates/prs_template.dart';
import 'templates/quote_template.dart';
import 'templates/receipt_template.dart';
import 'templates/smart_insight_template.dart';
import 'templates/stat_brag_template.dart';
import 'templates/stat_grid_template.dart';
import 'templates/streak_fire_template.dart';
import 'templates/strength_radar_template.dart';
import 'templates/trading_card_template.dart';
import 'templates/volume_bars_template.dart';
import 'templates/weekly_report_template.dart';
import 'templates/weight_graph_template.dart';
import 'templates/widget_template.dart';
import 'templates/workout_details_template.dart';
import 'templates/workout_program_template.dart';
import 'templates/workout_score_template.dart';
import 'templates/workout_summary_template.dart';
import 'templates/wrapped_template.dart';

/// Every template the unified sheet can render. Order here is also the
/// default render order in the gallery.
enum ShareableTemplate {
  activityOverview,
  minimal,
  wrapped,
  news,
  receipt,
  tradingCard,
  statGrid,
  streakFire,
  prs,
  weeklyReport,
  levelUp,
  elite,
  workoutDetails,
  workoutProgram,
  workoutSummary,
  dailyWorkoutCard,
  weeklyPlanGrid,
  monthlyPlanGrid,
  // --- New viral formats ---
  magazineCover,
  widget,
  achievementHero,
  calendarHeatmap,
  activityRings,
  polaroid,
  quote,
  chatBubble,
  statBrag,
  exerciseShowcase,
  boardingPass,
  nowPlaying,
  // --- Spark (intelligence-driven, icon-only pill) ---
  coachReview,
  smartInsight,
  prPrediction,
  workoutScore,
  muscleMap,
  // --- Graph (chart-heavy templates) ---
  weightGraph,
  volumeBars,
  strengthRadar,
  // --- Studio (custom user upload — photo-driven, icon-only pill) ---
  photoStats,
  photoQuote,
  photoBeforeAfter,
  photoSplit,
  photoMagazine,
  photoLockscreen,
}

/// User-facing grouping (Tier 3 in the nested pill selector).
///
/// Layout target: 4 text pills + 2 icon-only pills fit on a typical phone
/// without horizontal scrolling. To preserve that:
///   - `cards` (was `classic` + `rich` merged) — single text pill for all
///     non-photo, non-chart, non-editorial templates.
///   - `editorial`, `playful`, `graph` — text pills.
///   - `spark` — pure-icon pill (sparkle glyph).
///   - `studio` — pure-icon pill (camera glyph) for photo-driven uploads.
///
/// `rich` is kept in the enum for backwards compatibility (older spec
/// entries still reference it) — it's treated as an alias of `cards` in
/// the UI so it renders into the same pill, never showing "Rich" as a
/// separate option.
enum ShareableCategory { classic, rich, editorial, playful, graph, spark, studio }

extension ShareableCategoryMeta on ShareableCategory {
  /// The pill we surface this category under in the UI. `rich` aliases to
  /// `classic` so the merged "Cards" pill picks up old spec entries
  /// without us having to mass-edit the registry.
  ShareableCategory get effective =>
      this == ShareableCategory.rich ? ShareableCategory.classic : this;

  String get label {
    switch (this) {
      case ShareableCategory.classic:
      case ShareableCategory.rich:
        return 'Cards';
      case ShareableCategory.editorial:
        return 'Editorial';
      case ShareableCategory.playful:
        return 'Playful';
      case ShareableCategory.graph:
        return 'Graph';
      case ShareableCategory.spark:
        return 'Spark';
      case ShareableCategory.studio:
        return 'Studio';
    }
  }

  /// Leading icon for the pill. Spark + Studio render icon-only (see
  /// [iconOnly]) so the glyph carries the meaning. Other categories
  /// return null and use text labels.
  IconData? get icon {
    switch (this) {
      case ShareableCategory.spark:
        return Icons.auto_awesome;
      case ShareableCategory.studio:
        return Icons.camera_alt_outlined;
      case ShareableCategory.graph:
        return Icons.show_chart_rounded;
      default:
        return null;
    }
  }

  /// True for categories that render as a pure-icon pill (no label text).
  /// Spark + Studio use this — the sparkle / camera glyph signals the
  /// category without consuming horizontal space, so the four text pills
  /// (Cards / Editorial / Playful / Graph) plus these two icon pills all
  /// fit on a single row without scrolling.
  bool get iconOnly =>
      this == ShareableCategory.spark || this == ShareableCategory.studio;
}

typedef ShareableTemplateBuilder = Widget Function(
  Shareable data,
  bool showWatermark,
);

class ShareableTemplateSpec {
  final ShareableTemplate template;
  final String name;
  final ShareableCategory category;
  final Set<ShareableKind> kinds;
  final int minHighlights;
  final Set<ShareableAspect> aspects;
  final bool requiresExercises;
  final bool requiresStreak;
  final bool requiresWeeklyVector;
  final bool cosmeticGated;
  final ShareableTemplateBuilder builder;

  const ShareableTemplateSpec({
    required this.template,
    required this.name,
    required this.category,
    required this.kinds,
    required this.builder,
    this.minHighlights = 0,
    this.aspects = const {
      ShareableAspect.story,
      ShareableAspect.portrait,
      ShareableAspect.square,
    },
    this.requiresExercises = false,
    this.requiresStreak = false,
    this.requiresWeeklyVector = false,
    this.cosmeticGated = false,
  });

  bool isAvailableFor(Shareable data, {bool ownsCosmetic = false}) {
    if (cosmeticGated && !ownsCosmetic) return false;
    if (!kinds.contains(data.kind) &&
        !kinds.contains(ShareableKind.statsOverview)) {
      // Templates whose kinds set lists explicit allowlist must match,
      // unless the catalog entry uses an "all kinds" wildcard via
      // listing every value (handled in the registry below).
      if (!kinds.contains(data.kind)) return false;
    }
    if (!aspects.contains(data.aspect)) return false;
    final populated =
        data.highlights.where((h) => h.isPopulated).length;
    if (populated < minHighlights) return false;
    if (requiresExercises) {
      final ex = data.exercises;
      if (ex == null || ex.isEmpty) return false;
      final anyLogged = ex.any((e) => e.sets.isNotEmpty);
      if (!anyLogged) return false;
    }
    if (requiresStreak) {
      final hasStreak = data.highlights.any(
        (h) => h.label.toUpperCase().contains('STREAK'),
      );
      if (!hasStreak) return false;
    }
    if (requiresWeeklyVector) {
      final hasWeekly = data.subMetrics.length >= 7;
      if (!hasWeekly) return false;
    }
    return true;
  }
}

/// Set containing every kind — used by templates that work everywhere
/// (Activity Overview, Minimal, Wrapped, News, Receipt, Stat Grid).
const Set<ShareableKind> _allKinds = {
  ShareableKind.periodInsights,
  ShareableKind.personalRecords,
  ShareableKind.muscleAnalytics,
  ShareableKind.oneRm,
  ShareableKind.exerciseHistory,
  ShareableKind.milestones,
  ShareableKind.progressCharts,
  ShareableKind.bodyMeasurements,
  ShareableKind.nutrition,
  ShareableKind.achievements,
  ShareableKind.statsOverview,
  ShareableKind.weeklyProgress,
  ShareableKind.streak,
  ShareableKind.workoutComplete,
  ShareableKind.wrapped,
  ShareableKind.insights,
  ShareableKind.weeklySummary,
  ShareableKind.strength,
  ShareableKind.weeklyPlan,
  ShareableKind.monthlyPlan,
};

/// Single source of truth for the template registry. Phase 2 will fill in
/// the actual `builder` widgets — for now, the registry is shape-only so
/// the sheet + pill selector can compile.
class ShareableCatalog {
  static List<ShareableTemplateSpec>? _entries;

  static List<ShareableTemplateSpec> all() {
    return _entries ??= _build();
  }

  static List<ShareableTemplateSpec> _build() {
    return [
      ShareableTemplateSpec(
        template: ShareableTemplate.activityOverview,
        name: 'Overview',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => ActivityOverviewTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.minimal,
        name: 'Minimal',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => MinimalTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.wrapped,
        name: 'Wrapped',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => WrappedTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.news,
        name: 'News',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        minHighlights: 2,
        builder: (d, w) => NewsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.receipt,
        name: 'Receipt',
        category: ShareableCategory.rich,
        kinds: _allKinds,
        minHighlights: 3,
        builder: (d, w) => ReceiptTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.tradingCard,
        name: 'Card',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.milestones,
          ShareableKind.achievements,
          ShareableKind.statsOverview,
          ShareableKind.workoutComplete,
        },
        minHighlights: 2,
        builder: (d, w) => TradingCardTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.statGrid,
        name: 'Grid',
        category: ShareableCategory.rich,
        kinds: _allKinds,
        minHighlights: 4,
        builder: (d, w) => StatGridTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.streakFire,
        name: 'Streak',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.streak,
          ShareableKind.statsOverview,
          ShareableKind.periodInsights,
        },
        requiresStreak: true,
        builder: (d, w) => StreakFireTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.prs,
        name: 'PRs',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.workoutComplete,
        },
        minHighlights: 1,
        builder: (d, w) => PRsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.weeklyReport,
        name: 'Weekly Bars',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.weeklySummary,
          ShareableKind.periodInsights,
        },
        requiresWeeklyVector: true,
        builder: (d, w) => WeeklyReportTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.levelUp,
        name: 'Level Up',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.milestones,
          ShareableKind.achievements,
        },
        builder: (d, w) => LevelUpTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.elite,
        name: 'Elite',
        category: ShareableCategory.playful,
        kinds: const {ShareableKind.statsOverview},
        minHighlights: 3,
        cosmeticGated: true,
        builder: (d, w) => EliteTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutDetails,
        name: 'Workout',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        requiresExercises: true,
        builder: (d, w) => WorkoutDetailsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutProgram,
        name: 'Program',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete, ShareableKind.wrapped},
        aspects: const {ShareableAspect.story},
        requiresExercises: true,
        builder: (d, w) => WorkoutProgramTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutSummary,
        name: 'Watch Summary',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.statsOverview,
        },
        minHighlights: 2,
        builder: (d, w) =>
            WorkoutSummaryTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.dailyWorkoutCard,
        name: 'Day',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.weeklyPlan,
          ShareableKind.monthlyPlan,
        },
        builder: (d, w) =>
            DailyWorkoutCardTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.weeklyPlanGrid,
        name: 'Week Grid',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.weeklyPlan, ShareableKind.weeklySummary},
        builder: (d, w) =>
            WeeklyPlanGridTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.monthlyPlanGrid,
        name: 'Month Grid',
        category: ShareableCategory.rich,
        kinds: const {
          ShareableKind.monthlyPlan,
          ShareableKind.wrapped,
        },
        builder: (d, w) =>
            MonthlyPlanGridTemplate(data: d, showWatermark: w),
      ),
      // ─────────── New viral formats ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.magazineCover,
        name: 'Cover',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        builder: (d, w) => MagazineCoverTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.widget,
        name: 'Widget',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => WidgetTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.achievementHero,
        name: 'Trophy',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.achievements,
          ShareableKind.milestones,
          ShareableKind.statsOverview,
        },
        builder: (d, w) =>
            AchievementHeroTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.calendarHeatmap,
        name: 'Heatmap',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.streak,
          ShareableKind.statsOverview,
          ShareableKind.wrapped,
          ShareableKind.periodInsights,
        },
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        builder: (d, w) =>
            CalendarHeatmapTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.activityRings,
        name: 'Rings',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.streak,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) =>
            ActivityRingsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.polaroid,
        name: 'Polaroid',
        category: ShareableCategory.playful,
        kinds: _allKinds,
        builder: (d, w) => PolaroidTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.quote,
        name: 'Quote',
        category: ShareableCategory.editorial,
        kinds: _allKinds,
        builder: (d, w) => QuoteTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.chatBubble,
        name: 'iMessage',
        category: ShareableCategory.playful,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.personalRecords,
          ShareableKind.milestones,
        },
        builder: (d, w) => ChatBubbleTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.statBrag,
        name: 'Brag',
        category: ShareableCategory.classic,
        kinds: _allKinds,
        builder: (d, w) => StatBragTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.exerciseShowcase,
        name: 'Showcase',
        category: ShareableCategory.rich,
        kinds: const {ShareableKind.workoutComplete},
        requiresExercises: true,
        builder: (d, w) =>
            ExerciseShowcaseTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.boardingPass,
        name: 'Boarding',
        category: ShareableCategory.editorial,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.milestones,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
        },
        builder: (d, w) => BoardingPassTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.nowPlaying,
        name: 'Playing',
        category: ShareableCategory.classic,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.statsOverview,
          ShareableKind.personalRecords,
        },
        builder: (d, w) => NowPlayingTemplate(data: d, showWatermark: w),
      ),
      // ─────────── Spark (intelligence-driven) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.coachReview,
        name: 'Coach Review',
        category: ShareableCategory.spark,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
        },
        builder: (d, w) => CoachReviewTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.smartInsight,
        name: 'Insight',
        category: ShareableCategory.graph,
        kinds: _allKinds,
        builder: (d, w) => SmartInsightTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.prPrediction,
        name: 'Projection',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.personalRecords,
          ShareableKind.statsOverview,
          ShareableKind.strength,
        },
        aspects: const {ShareableAspect.story, ShareableAspect.portrait},
        builder: (d, w) => PRPredictionTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.workoutScore,
        name: 'Score',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.streak,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => WorkoutScoreTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.muscleMap,
        name: 'Muscle Map',
        category: ShareableCategory.spark,
        kinds: const {
          ShareableKind.workoutComplete,
          ShareableKind.muscleAnalytics,
          ShareableKind.weeklyProgress,
          ShareableKind.statsOverview,
          ShareableKind.weeklySummary,
        },
        builder: (d, w) => MuscleMapTemplate(data: d, showWatermark: w),
      ),
      // ─────────── Graph (chart-heavy) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.weightGraph,
        name: 'Weight Trend',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.bodyMeasurements,
          ShareableKind.progressCharts,
          ShareableKind.statsOverview,
          ShareableKind.personalRecords,
          ShareableKind.strength,
          ShareableKind.oneRm,
          ShareableKind.weeklyProgress,
        },
        builder: (d, w) => WeightGraphTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.volumeBars,
        name: 'Volume Bars',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.weeklyProgress,
          ShareableKind.weeklySummary,
          ShareableKind.statsOverview,
          ShareableKind.periodInsights,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => VolumeBarsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.strengthRadar,
        name: 'Radar',
        category: ShareableCategory.graph,
        kinds: const {
          ShareableKind.muscleAnalytics,
          ShareableKind.statsOverview,
          ShareableKind.strength,
          ShareableKind.weeklySummary,
          ShareableKind.workoutComplete,
        },
        builder: (d, w) => StrengthRadarTemplate(data: d, showWatermark: w),
      ),
      // ─────────── Studio (custom user upload — photo-driven) ───────────
      ShareableTemplateSpec(
        template: ShareableTemplate.photoStats,
        name: 'Stat Overlay',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoStatsTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoQuote,
        name: 'Quote Overlay',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoQuoteTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoBeforeAfter,
        name: 'Before / After',
        category: ShareableCategory.studio,
        kinds: const {
          ShareableKind.bodyMeasurements,
          ShareableKind.weeklyProgress,
          ShareableKind.milestones,
          ShareableKind.statsOverview,
          ShareableKind.progressCharts,
        },
        builder: (d, w) =>
            PhotoBeforeAfterTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoSplit,
        name: 'Split',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) => PhotoSplitTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoMagazine,
        name: 'Cover Story',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) =>
            PhotoMagazineTemplate(data: d, showWatermark: w),
      ),
      ShareableTemplateSpec(
        template: ShareableTemplate.photoLockscreen,
        name: 'Lockscreen',
        category: ShareableCategory.studio,
        kinds: _allKinds,
        builder: (d, w) =>
            PhotoLockscreenTemplate(data: d, showWatermark: w),
      ),
    ];
  }

  /// Used in tests + Phase 2 when each template's real builder lands.
  @visibleForTesting
  static void overrideEntries(List<ShareableTemplateSpec> entries) {
    _entries = entries;
  }

  static List<ShareableTemplateSpec> availableFor(
    Shareable data, {
    bool ownsCosmetic = false,
  }) {
    return all()
        .where((spec) => spec.isAvailableFor(data, ownsCosmetic: ownsCosmetic))
        .toList();
  }

  static List<ShareableCategory> categoriesFor(
    Shareable data, {
    bool ownsCosmetic = false,
  }) {
    final available = availableFor(data, ownsCosmetic: ownsCosmetic);
    // `rich` aliases to `classic` post-merge — collapse via [effective]
    // so we never surface two pills with the same "Cards" label.
    final cats = available.map((e) => e.category.effective).toSet().toList();
    cats.sort((a, b) => a.index.compareTo(b.index));
    return cats;
  }

  static List<ShareableTemplateSpec> templatesInCategory(
    Shareable data,
    ShareableCategory category, {
    bool ownsCosmetic = false,
  }) {
    return all()
        .where((spec) =>
            spec.category.effective == category.effective &&
            spec.isAvailableFor(data, ownsCosmetic: ownsCosmetic))
        .toList();
  }

  static ShareableTemplateSpec specFor(ShareableTemplate t) {
    return all().firstWhere((s) => s.template == t);
  }

  /// Returns the canonical "hero" template for a given share kind so
  /// callers don't need to thread an `initialTemplate` through. Used by
  /// `ShareableSheet` when no explicit template is requested — the sheet
  /// auto-lands on the most-relevant asset for what the user is sharing
  /// (weight log → Weight Trend, workout → Workout Details, streak →
  /// Streak Fire, etc.) instead of always starting on the registry's
  /// first entry.
  ///
  /// Returns null when no specific default applies; callers should then
  /// fall back to `availableFor(data).first`.
  static ShareableTemplate? defaultTemplateForKind(ShareableKind kind) {
    switch (kind) {
      case ShareableKind.workoutComplete:
        return ShareableTemplate.workoutDetails;
      case ShareableKind.bodyMeasurements:
      case ShareableKind.progressCharts:
      case ShareableKind.oneRm:
      case ShareableKind.exerciseHistory:
        return ShareableTemplate.weightGraph;
      case ShareableKind.personalRecords:
        return ShareableTemplate.prs;
      case ShareableKind.streak:
        return ShareableTemplate.streakFire;
      case ShareableKind.milestones:
        return ShareableTemplate.levelUp;
      case ShareableKind.achievements:
        return ShareableTemplate.achievementHero;
      case ShareableKind.wrapped:
        return ShareableTemplate.wrapped;
      case ShareableKind.weeklyProgress:
      case ShareableKind.weeklySummary:
        return ShareableTemplate.weeklyReport;
      case ShareableKind.muscleAnalytics:
        return ShareableTemplate.muscleMap;
      case ShareableKind.statsOverview:
        return ShareableTemplate.activityOverview;
      case ShareableKind.nutrition:
        return ShareableTemplate.statGrid;
      case ShareableKind.insights:
        return ShareableTemplate.smartInsight;
      case ShareableKind.strength:
        return ShareableTemplate.strengthRadar;
      case ShareableKind.periodInsights:
        return ShareableTemplate.calendarHeatmap;
      case ShareableKind.weeklyPlan:
        return ShareableTemplate.weeklyPlanGrid;
      case ShareableKind.monthlyPlan:
        return ShareableTemplate.monthlyPlanGrid;
    }
  }
}
