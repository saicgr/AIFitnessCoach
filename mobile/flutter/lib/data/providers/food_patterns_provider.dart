import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_patterns.dart';
import '../repositories/nutrition_repository.dart';

/// Query args for the top-foods provider.
class TopFoodsQuery {
  final String userId;
  final String metric;
  final String range;
  final String? date;

  const TopFoodsQuery({
    required this.userId,
    this.metric = 'calories',
    this.range = 'week',
    this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is TopFoodsQuery &&
      other.userId == userId &&
      other.metric == metric &&
      other.range == range &&
      other.date == date;

  @override
  int get hashCode => Object.hash(userId, metric, range, date);
}

class MacrosQuery {
  final String userId;
  final String range;
  final String? date;

  const MacrosQuery({
    required this.userId,
    this.range = 'week',
    this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is MacrosQuery &&
      other.userId == userId &&
      other.range == range &&
      other.date == date;

  @override
  int get hashCode => Object.hash(userId, range, date);
}

class HistoryQuery {
  final String userId;
  final String range;
  final String? date;
  final int offset;

  const HistoryQuery({
    required this.userId,
    this.range = 'week',
    this.date,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.userId == userId &&
      other.range == range &&
      other.date == date &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(userId, range, date, offset);
}

/// Mood/energy patterns for the Patterns tab (Section 3). Always 90-day window.
final foodPatternsMoodProvider = FutureProvider.autoDispose
    .family<FoodPatternsMoodResponse, String>((ref, userId) async {
  // One entry per user (no range/date key) — keepAlive so it can be
  // prewarmed from main_shell and survives Patterns-tab re-entry.
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getMoodPatterns(userId);
});

/// Top foods by nutrient for Section 2. Re-fires on metric/range change.
final topFoodsProvider = FutureProvider.autoDispose
    .family<TopFoodsResponse, TopFoodsQuery>((ref, query) async {
  // keepAlive so it survives Patterns-tab re-entry / metric/range toggles
  // within a session instead of refetching every revisit.
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getTopFoods(
    query.userId,
    metric: query.metric,
    range: query.range,
    date: query.date,
  );
});

/// Macros/calorie summary for Section 1.
final macrosSummaryProvider = FutureProvider.autoDispose
    .family<MacrosSummaryResponse, MacrosQuery>((ref, query) async {
  // keepAlive so it survives Patterns-tab re-entry / range toggles within a
  // session instead of refetching every revisit.
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getMacrosSummary(
    query.userId,
    range: query.range,
    date: query.date,
  );
});

/// Paginated meal history for Section 4.
final patternsHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, HistoryQuery>((ref, query) async {
  // keepAlive so paginated history survives Patterns-tab re-entry / range
  // toggles within a session instead of refetching every revisit.
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getPatternsHistory(
    query.userId,
    range: query.range,
    date: query.date,
    offset: query.offset,
  );
});

/// Patterns/check-in settings (backed by user_nutrition_preferences).
final patternsSettingsProvider = FutureProvider.autoDispose
    .family<PatternsSettings, String>((ref, userId) async {
  // One entry per user (no range/date key) — keepAlive so it can be
  // prewarmed from main_shell and survives Patterns-tab re-entry.
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  return repo.getPatternsSettings(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// Deepened Patterns (Phase 4B/4C — FE-D)
// ═══════════════════════════════════════════════════════════════════════════
//
// These models are hand-written (NOT @JsonSerializable) so they don't need
// build_runner — codegen is forbidden in this repo. Every field is read
// defensively from the backend's raw map so BE-1 shipping fields incrementally
// (or migrations not yet applied) degrades to gentle empty states rather than
// parse failures. All three providers keepAlive + are autoDispose families,
// mirroring the existing Patterns providers.

/// One per-symptom or per-tag correlation bucket: "Before you felt bloated"
/// with the foods that recurred (image-first), a count and a confidence pct.
class SymptomBucket {
  /// Stable key — the symptom or tag slug (e.g. `bloated`, `dairy`).
  final String key;

  /// Human label for the bucket header ("bloated", "dairy").
  final String label;

  /// How many qualifying logs fed this bucket.
  final int count;

  /// 0–100 confidence the correlation is meaningful (backend-computed).
  final int confidencePct;

  /// Foods (image-first) that recurred before/with this symptom or tag.
  final List<CorrelatedFood> foods;

  const SymptomBucket({
    required this.key,
    required this.label,
    required this.count,
    required this.confidencePct,
    required this.foods,
  });

  factory SymptomBucket.fromJson(Map<String, dynamic> j) => SymptomBucket(
        key: (j['key'] ?? j['symptom'] ?? j['tag'] ?? '').toString(),
        label: (j['label'] ?? j['key'] ?? j['symptom'] ?? j['tag'] ?? '')
            .toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
        confidencePct: (j['confidence_pct'] as num?)?.toInt() ??
            (j['pct'] as num?)?.toInt() ??
            0,
        foods: (j['foods'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => CorrelatedFood.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// A single correlated food row inside a [SymptomBucket] — image-first.
class CorrelatedFood {
  final String name;
  final String? imageUrl;
  final int occurrences;
  final String? lastLoggedAt;

  const CorrelatedFood({
    required this.name,
    this.imageUrl,
    this.occurrences = 0,
    this.lastLoggedAt,
  });

  factory CorrelatedFood.fromJson(Map<String, dynamic> j) => CorrelatedFood(
        name: (j['food_name'] ?? j['name'] ?? '').toString(),
        imageUrl: (j['image_url'] ?? j['last_image_url']) as String?,
        occurrences: (j['occurrences'] as num?)?.toInt() ??
            (j['count'] as num?)?.toInt() ??
            0,
        lastLoggedAt: (j['last_logged_at'] ?? j['logged_at']) as String?,
      );
}

/// Parsed view of the EXTENDED `/food-patterns/mood` response — adds the
/// per-symptom and per-tag correlation buckets BE-1 layers on top of the
/// existing energizing/draining lists (which the legacy [_MoodSection] still
/// reads via the typed model). Empty lists if the backend hasn't shipped them.
class SymptomTagCorrelations {
  /// Buckets keyed by symptom ("bloated", "energized", "foggy"…).
  final List<SymptomBucket> symptomBuckets;

  /// Buckets keyed by user/auto food tag ("dairy", "gluten", "spicy"…).
  final List<SymptomBucket> tagBuckets;

  /// Window the backend analyzed (days).
  final int daysWindow;

  /// Total qualifying logs across all buckets — used to gate the section.
  final int totalLogs;

  const SymptomTagCorrelations({
    this.symptomBuckets = const [],
    this.tagBuckets = const [],
    this.daysWindow = 90,
    this.totalLogs = 0,
  });

  bool get isEmpty => symptomBuckets.isEmpty && tagBuckets.isEmpty;

  factory SymptomTagCorrelations.fromJson(Map<String, dynamic> j) {
    List<SymptomBucket> parse(String key) =>
        (j[key] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => SymptomBucket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    return SymptomTagCorrelations(
      symptomBuckets: parse('symptom_buckets'),
      tagBuckets: parse('tag_buckets'),
      daysWindow: (j['days_window'] as num?)?.toInt() ?? 90,
      totalLogs: (j['total_logs_analyzed'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One "gentle change" goal track — current avg vs goal vs baseline, with a
/// small sparkline series. Drives the encouraging goal cards.
class GentleGoal {
  /// Slug — `fiber`, `protein`, `veggies`, `consistency`.
  final String key;

  /// Human label ("Fiber", "Veggie days").
  final String label;

  /// Current-window average value.
  final double current;

  /// The goal/target value (null ⇒ no goal set).
  final double? goal;

  /// Prior-window baseline average (null ⇒ not enough history).
  final double? baseline;

  /// Unit suffix ("g", "days", "%").
  final String unit;

  /// Daily/weekly series for the sparkline (chronological).
  final List<double> series;

  const GentleGoal({
    required this.key,
    required this.label,
    required this.current,
    this.goal,
    this.baseline,
    this.unit = '',
    this.series = const [],
  });

  /// Delta vs baseline (positive ⇒ trending up). Null if no baseline.
  double? get delta => baseline == null ? null : current - baseline!;

  /// Signed trend bucket: 1 up, -1 down, 0 flat/unknown.
  int get trend {
    final d = delta;
    if (d == null) return 0;
    if (d.abs() < (current.abs() * 0.03)) return 0; // within ~3% = flat
    return d > 0 ? 1 : -1;
  }

  /// Progress 0..1 toward the goal (clamped). Null if no goal.
  double? get progress {
    final g = goal;
    if (g == null || g <= 0) return null;
    return (current / g).clamp(0.0, 1.0);
  }

  factory GentleGoal.fromJson(Map<String, dynamic> j) => GentleGoal(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? j['key'] ?? '').toString(),
        current: (j['current'] as num?)?.toDouble() ??
            (j['current_avg'] as num?)?.toDouble() ??
            0,
        goal: (j['goal'] as num?)?.toDouble() ??
            (j['target'] as num?)?.toDouble(),
        baseline: (j['baseline'] as num?)?.toDouble() ??
            (j['baseline_avg'] as num?)?.toDouble(),
        unit: (j['unit'] ?? '').toString(),
        series: (j['series'] as List<dynamic>? ?? const [])
            .map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList(),
      );
}

/// Parsed view of the EXTENDED `/macros-summary` (baseline) response. Holds the
/// "gentle changes" goal tracks plus the macro/nutrient 4wk-vs-9wk baseline
/// deltas used by the bigger-picture trends block.
class MacrosBaseline {
  final List<GentleGoal> goals;

  /// Macro/nutrient baseline deltas keyed by nutrient
  /// (`calories`/`protein`/`carbs`/`fat`/`fiber`) → GentleGoal-shaped track.
  final List<GentleGoal> nutrientTracks;

  /// Window labels for the comparison ("last 4 weeks" vs "prior 4 weeks").
  final String currentLabel;
  final String baselineLabel;

  const MacrosBaseline({
    this.goals = const [],
    this.nutrientTracks = const [],
    this.currentLabel = '',
    this.baselineLabel = '',
  });

  bool get isEmpty => goals.isEmpty && nutrientTracks.isEmpty;

  factory MacrosBaseline.fromJson(Map<String, dynamic> j) {
    List<GentleGoal> parse(String key) =>
        (j[key] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => GentleGoal.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    return MacrosBaseline(
      goals: parse('goals'),
      nutrientTracks: parse('nutrient_tracks'),
      currentLabel: (j['current_label'] ?? '').toString(),
      baselineLabel: (j['baseline_label'] ?? '').toString(),
    );
  }
}

/// One day in the regularity series for the gut-health chart.
class RegularityDay {
  final String date;

  /// Count of digestion logs that day (0 ⇒ no movement recorded).
  final int count;

  /// Average Bristol type that day (1–7), null if no logs.
  final double? avgBristol;

  const RegularityDay({required this.date, this.count = 0, this.avgBristol});

  factory RegularityDay.fromJson(Map<String, dynamic> j) => RegularityDay(
        date: (j['date'] ?? '').toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
        avgBristol: (j['avg_bristol'] as num?)?.toDouble(),
      );
}

/// Parsed view of the NEW `/food-patterns/digestion` response.
class DigestionPatterns {
  /// Daily regularity series (chronological).
  final List<RegularityDay> series;

  /// Food/tag → gut correlations ("dairy days → looser stool").
  final List<SymptomBucket> correlations;

  /// "Natural rhythm" — average movements per day over the window.
  final double? avgPerDay;

  /// Share of days in the window with at least one movement (0..1).
  final double? regularityPct;

  /// Most common Bristol type (1–7), null if no data.
  final int? typicalBristol;

  final int daysWindow;

  const DigestionPatterns({
    this.series = const [],
    this.correlations = const [],
    this.avgPerDay,
    this.regularityPct,
    this.typicalBristol,
    this.daysWindow = 90,
  });

  bool get isEmpty => series.isEmpty && correlations.isEmpty;

  /// True when there's literally no movement data at all.
  bool get hasNoData =>
      (avgPerDay == null || avgPerDay == 0) &&
      series.every((d) => d.count == 0);

  factory DigestionPatterns.fromJson(Map<String, dynamic> j) =>
      DigestionPatterns(
        series: (j['series'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => RegularityDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        correlations: (j['correlations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => SymptomBucket.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        avgPerDay: (j['avg_per_day'] as num?)?.toDouble(),
        regularityPct: (j['regularity_pct'] as num?)?.toDouble(),
        typicalBristol: (j['typical_bristol'] as num?)?.toInt(),
        daysWindow: (j['days_window'] as num?)?.toInt() ?? 90,
      );
}

/// Symptom + tag correlation buckets (extended /mood). 90-day window per user.
final symptomTagCorrelationsProvider = FutureProvider.autoDispose
    .family<SymptomTagCorrelations, String>((ref, userId) async {
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  final raw = await repo.getMoodPatternsRaw(userId);
  return SymptomTagCorrelations.fromJson(raw);
});

/// "Gentle changes" goal cards + macro baselines (extended /macros-summary).
final macrosBaselineProvider = FutureProvider.autoDispose
    .family<MacrosBaseline, String>((ref, userId) async {
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  final raw = await repo.getMacrosSummaryWithBaseline(userId);
  return MacrosBaseline.fromJson(raw);
});

/// Gut-health / digestion patterns (new /digestion endpoint). Per user.
final digestionPatternsProvider = FutureProvider.autoDispose
    .family<DigestionPatterns, String>((ref, userId) async {
  ref.keepAlive();
  final repo = ref.watch(nutritionRepositoryProvider);
  final raw = await repo.getDigestionPatterns(userId);
  return DigestionPatterns.fromJson(raw);
});
