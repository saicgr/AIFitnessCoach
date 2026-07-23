import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/nutrition.dart';
import '../shareable_data.dart';

/// Adapter that maps nutrition data onto the unified `Shareable` payload so
/// the same gallery (`ShareableSheet`) handles every nutrition share —
/// backend report payloads (daily / weekly / monthly) and individual
/// `FoodLog`s / meals (`fromFoodLog` / `fromMeal` / `fromFoodLogs`).
class NutritionAdapter {
  /// Build a `Shareable` from `POST /nutrition/reports/daily`.
  static Shareable? fromDailyReport({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final calories = (json['calories_consumed'] as num?)?.toInt() ?? 0;
    final target = (json['calorie_target'] as num?)?.toInt() ?? 2000;
    final macros = (json['macros'] as Map?) ?? const {};
    final protein = (macros['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = (macros['carbs_g'] as num?)?.toDouble() ?? 0;
    final fat = (macros['fat_g'] as num?)?.toDouble() ?? 0;
    final fiber = (macros['fiber_g'] as num?)?.toDouble() ?? 0;
    final inflam = (json['inflammation_score'] as num?)?.toDouble();
    final contribs =
        ((json['inflammation_top_contributors'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
    final summary = json['ai_summary'] as String? ?? '';
    final tips = ((json['tomorrow_suggestions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final firstName = json['user_first_name'] as String?;
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) return null;
    final accent = ref.read(accentColorProvider).getColor(true);

    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null ? "$firstName's Daily Nutrition" : 'Daily Nutrition',
      periodLabel: json['date'] as String? ?? '',
      heroValue: calories,
      heroUnitSingular: 'kcal',
      highlights: [
        ShareableMetric(
          label: 'CALORIES',
          value: '$calories / $target',
          icon: Icons.local_fire_department_rounded,
          accent: const Color(0xFFFF6B35),
        ),
        ShareableMetric(
          label: 'PROTEIN',
          value: '${protein.round()}g',
          icon: Icons.egg_alt_rounded,
        ),
        ShareableMetric(
          label: 'CARBS',
          value: '${carbs.round()}g',
          icon: Icons.bakery_dining_rounded,
        ),
        ShareableMetric(
          label: 'FAT',
          value: '${fat.round()}g',
          icon: Icons.water_drop_rounded,
        ),
        if (fiber > 0)
          ShareableMetric(
            label: 'FIBER',
            value: '${fiber.round()}g',
            icon: Icons.spa_rounded,
          ),
        if (inflam != null)
          ShareableMetric(
            label: 'INFLAMMATION',
            value: inflam.toStringAsFixed(1),
            icon: Icons.healing_rounded,
            accent: inflam >= 6
                ? const Color(0xFFEF4444)
                : (inflam >= 4 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          ),
      ],
      subMetrics: [
        if (summary.isNotEmpty)
          ShareableMetric(label: 'SUMMARY', value: summary),
        for (final t in tips.take(3))
          ShareableMetric(label: 'TIP', value: t),
        if (contribs.isNotEmpty)
          ShareableMetric(
            label: 'INFLAM SOURCES',
            value: contribs.take(3).join(' · '),
          ),
      ],
      accentColor: accent,
    );
  }

  /// Build a `Shareable` from `POST /nutrition/reports/weekly`.
  ///
  /// The 7-day macro arrays go into `subMetrics` so weekly templates
  /// (`nutritionWeekMacroCircles`, `nutritionWeekBars`) can read them
  /// without a separate field.
  static Shareable? fromWeeklyReport({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final dailyCals = ((json['daily_calories'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    if (dailyCals.isEmpty) return null;
    final dailyMacros =
        ((json['daily_macros'] as List?) ?? const []).cast<Map>();
    final avg = (json['weekly_avg_calories'] as num?)?.toInt() ?? 0;
    final daysCal = (json['days_hit_calorie_goal'] as num?)?.toInt() ?? 0;
    final daysProt = (json['days_hit_protein_goal'] as num?)?.toInt() ?? 0;
    final inflTrend = ((json['inflammation_trend'] as List?) ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    final delta = (json['week_over_week_delta'] as Map?) ?? const {};
    final narrative = json['ai_narrative'] as String? ?? '';
    final firstName = json['user_first_name'] as String?;

    final pct = (delta['calories_avg_pct'] as num?)?.toDouble() ?? 0;
    final arrow = pct > 0 ? '↑' : (pct < 0 ? '↓' : '→');

    final accent = ref.read(accentColorProvider).getColor(true);
    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null
          ? "$firstName's Weekly Wrap"
          : 'Weekly Nutrition Wrap',
      periodLabel:
          '${json['week_start']} → ${json['week_end']}',
      heroValue: avg,
      heroUnitSingular: 'kcal/day',
      highlights: [
        ShareableMetric(
          label: 'AVG CAL',
          value: '$avg',
          icon: Icons.local_fire_department_rounded,
        ),
        ShareableMetric(
          label: 'GOAL HITS',
          value: '$daysCal/7',
          icon: Icons.check_circle_rounded,
          accent: const Color(0xFF10B981),
        ),
        ShareableMetric(
          label: 'PROTEIN HITS',
          value: '$daysProt/7',
          icon: Icons.egg_alt_rounded,
        ),
        ShareableMetric(
          label: 'WEEK Δ',
          value: '$arrow ${pct.abs().toStringAsFixed(1)}%',
          icon: Icons.trending_up_rounded,
        ),
      ],
      subMetrics: [
        if (narrative.isNotEmpty)
          ShareableMetric(label: 'NARRATIVE', value: narrative),
        // Encode the 7-day arrays so weekly templates can render charts.
        ShareableMetric(
          label: 'DAILY_CAL_ARRAY',
          value: dailyCals.join(','),
        ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_PROTEIN_ARRAY',
            value: dailyMacros
                .map((m) => ((m['protein_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_CARBS_ARRAY',
            value: dailyMacros
                .map((m) => ((m['carbs_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (dailyMacros.isNotEmpty)
          ShareableMetric(
            label: 'DAILY_FAT_ARRAY',
            value: dailyMacros
                .map((m) => ((m['fat_g'] as num?) ?? 0).round().toString())
                .join(','),
          ),
        if (inflTrend.isNotEmpty)
          ShareableMetric(
            label: 'INFLAM_TREND_ARRAY',
            value: inflTrend.map((v) => v.toStringAsFixed(1)).join(','),
          ),
      ],
      accentColor: accent,
    );
  }

  /// Build a `Shareable` for a monthly calendar heatmap from a 30-day
  /// summary payload (`{daily_calories: List<int>, daily_macro_hits:
  /// List<int>}` where macro_hits ∈ {0,1,2,3}).
  static Shareable? fromMonthlySummary({
    required WidgetRef ref,
    required Map<String, dynamic> json,
  }) {
    final cals = ((json['daily_calories'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    if (cals.isEmpty) return null;
    final hits = ((json['daily_macro_hits'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    final daysTracked = cals.where((c) => c > 0).length;
    final bestStreak = (json['best_streak'] as num?)?.toInt() ?? 0;
    final avg = cals.isEmpty ? 0 : (cals.reduce((a, b) => a + b) / cals.length).round();
    final accent = ref.read(accentColorProvider).getColor(true);
    final firstName = json['user_first_name'] as String?;

    return Shareable(
      kind: ShareableKind.nutrition,
      title: firstName != null
          ? "$firstName's Month in Macros"
          : 'Month in Macros',
      periodLabel: json['month_label'] as String? ?? '',
      heroValue: daysTracked,
      heroUnitSingular: 'day tracked',
      heroSuffix: daysTracked == 1 ? null : 's',
      highlights: [
        ShareableMetric(label: 'AVG CAL', value: '$avg'),
        ShareableMetric(label: 'BEST STREAK', value: '$bestStreak days'),
        ShareableMetric(label: 'TRACKED', value: '$daysTracked / ${cals.length}'),
      ],
      subMetrics: [
        ShareableMetric(label: 'CAL_ARRAY', value: cals.join(',')),
        if (hits.isNotEmpty)
          ShareableMetric(label: 'MACRO_HITS_ARRAY', value: hits.join(',')),
      ],
      accentColor: accent,
    );
  }

  // ─── Food-log shares (ShareableKind.foodLog) ───────────────────────────
  //
  // Phase A: these build photo-LESS data cards (Nutrition Facts panel, food
  // receipt, "what I ate" quote card, food score dial) plus a photo card
  // when the log carries an `image_url`. Unlike the report adapters above,
  // food shares carry their data in `nutrition` / `foodItems` (not
  // `highlights`), so `ShareableKind.foodLog.minHighlights` is 0.

  /// Build a `Shareable` from a single logged meal/food entry.
  ///
  /// Returns null when the log is genuinely empty (0 calories AND no food
  /// items) — same validation contract as the report adapters: an adapter
  /// returns a fully-populated payload or null, never a half-empty card.
  static Shareable? fromFoodLog(FoodLog log, {required Color accent}) {
    if (log.totalCalories == 0 && log.foodItems.isEmpty) return null;

    final items = _mapFoodItems(log.foodItems);
    return Shareable(
      kind: ShareableKind.foodLog,
      title: _dishTitle(log),
      mealLabel: _mealLabel(log.mealType),
      periodLabel: _shortDate(log.loggedAt),
      nutrition: _nutritionOf(
        calories: log.totalCalories,
        proteinG: log.proteinG,
        carbsG: log.carbsG,
        fatG: log.fatG,
        fiberG: log.fiberG,
      ),
      foodItems: items,
      healthScore: log.healthScore,
      logText: _nonEmpty(log.userQuery),
      foodImageUrls: _imageList([log]),
      accentColor: accent,
    );
  }

  /// Build a `Shareable` from every log of one meal type on a day (e.g. all
  /// of today's "lunch" entries) — macros are summed across the logs.
  ///
  /// Returns null when the collection is empty or every log is empty.
  static Shareable? fromMeal(
    List<FoodLog> sameMealType, {
    required Color accent,
  }) {
    final logs = _sortedByLoggedAt(sameMealType);
    if (logs.isEmpty) return null;

    final allItems = <FoodItem>[
      for (final l in logs) ...l.foodItems,
    ];
    final totalCalories = logs.fold<int>(0, (s, l) => s + l.totalCalories);
    if (totalCalories == 0 && allItems.isEmpty) return null;

    // Title: a single-log meal reads as the dish; a multi-log meal reads as
    // the meal name itself (e.g. "Lunch") since there is no one dish.
    final title = logs.length == 1
        ? _dishTitle(logs.first)
        : _mealLabel(logs.first.mealType);

    return Shareable(
      kind: ShareableKind.foodLog,
      title: title,
      mealLabel: _mealLabel(logs.first.mealType),
      periodLabel: _shortDate(logs.first.loggedAt),
      nutrition: _nutritionOf(
        calories: totalCalories,
        proteinG: logs.fold<double>(0, (s, l) => s + l.proteinG),
        carbsG: logs.fold<double>(0, (s, l) => s + l.carbsG),
        fatG: logs.fold<double>(0, (s, l) => s + l.fatG),
        fiberG: _sumFiber(logs),
      ),
      foodItems: _mapFoodItems(allItems),
      healthScore: _averageScore(logs),
      logText: logs.length == 1 ? _nonEmpty(logs.first.userQuery) : null,
      foodImageUrls: _imageList(logs),
      accentColor: accent,
    );
  }

  /// Build a `Shareable` spanning many logs across meal types (e.g. a full
  /// day) — macros summed, meal label is the generic "All meals".
  ///
  /// Returns null when the collection is empty or every log is empty.
  static Shareable? fromFoodLogs(List<FoodLog> logs, {required Color accent}) {
    final sorted = _sortedByLoggedAt(logs);
    if (sorted.isEmpty) return null;

    final allItems = <FoodItem>[
      for (final l in sorted) ...l.foodItems,
    ];
    final totalCalories = sorted.fold<int>(0, (s, l) => s + l.totalCalories);
    if (totalCalories == 0 && allItems.isEmpty) return null;

    return Shareable(
      kind: ShareableKind.foodLog,
      title: _dayTitle(sorted),
      mealLabel: 'All meals',
      periodLabel: _shortDate(sorted.first.loggedAt),
      nutrition: _nutritionOf(
        calories: totalCalories,
        proteinG: sorted.fold<double>(0, (s, l) => s + l.proteinG),
        carbsG: sorted.fold<double>(0, (s, l) => s + l.carbsG),
        fatG: sorted.fold<double>(0, (s, l) => s + l.fatG),
        fiberG: _sumFiber(sorted),
      ),
      foodItems: _mapFoodItems(allItems),
      healthScore: _averageScore(sorted),
      // A multi-meal day has no single natural-language log to quote.
      logText: null,
      foodImageUrls: _imageList(sorted),
      accentColor: accent,
    );
  }

  // ─── Food-log mapping helpers ──────────────────────────────────────────

  /// Logs in chronological order, with nulls defensively dropped.
  static List<FoodLog> _sortedByLoggedAt(List<FoodLog> logs) {
    final copy = List<FoodLog>.from(logs)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return copy;
  }

  /// Maps `FoodItem` (nullable macro fields) → `ShareableFood` (non-null).
  /// Items with a blank name are dropped so the receipt/panel never shows an
  /// empty line.
  static List<ShareableFood> _mapFoodItems(List<FoodItem> items) {
    return [
      for (final it in items)
        if (it.name.trim().isNotEmpty)
          ShareableFood(
            name: it.name.trim(),
            amount: _nonEmpty(it.amount),
            calories: it.calories ?? 0,
            proteinG: it.proteinG ?? 0,
            carbsG: it.carbsG ?? 0,
            fatG: it.fatG ?? 0,
          ),
    ];
  }

  /// Aggregate macro totals. Goals stay null in Phase A (a logged meal has
  /// no per-meal goal); fiber is null when no log carried fiber data.
  static ShareableNutrition _nutritionOf({
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double? fiberG,
  }) {
    return ShareableNutrition(
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
    );
  }

  // ─── Menu-scan shares (pre-logging) ────────────────────────────────────

  /// Share a whole scanned menu before anything is logged.
  ///
  /// When the user has already ticked dishes, the card is about that
  /// selection (their picks + running total). With nothing ticked it's the
  /// restaurant itself — top dishes at a glance. Either way it works entirely
  /// from in-memory scan state, so it's shareable the moment the scan lands
  /// and identically on a menu reopened from Saved Menus.
  static Shareable? fromMenuAnalysis({
    required String? restaurantName,
    required List<MenuItem> items,
    required Set<String> selectedIds,
    required Color accent,
    List<String> menuPhotoUrls = const [],
  }) {
    if (items.isEmpty) return null;
    final selected = items.where((i) => selectedIds.contains(i.id)).toList();
    final showing = selected.isNotEmpty ? selected : items;

    final title = (restaurantName != null && restaurantName.trim().isNotEmpty)
        ? restaurantName.trim()
        : (selected.isNotEmpty ? 'My picks' : 'Menu');
    final mealLabel = selected.isNotEmpty
        ? '${selected.length} picked'
        : '${items.length} dishes';

    final cal = showing.fold<double>(0, (s, i) => s + i.scaledCalories);
    final protein = showing.fold<double>(0, (s, i) => s + i.scaledProteinG);
    final carbs = showing.fold<double>(0, (s, i) => s + i.scaledCarbsG);
    final fat = showing.fold<double>(0, (s, i) => s + i.scaledFatG);

    return Shareable(
      kind: ShareableKind.foodLog,
      title: title,
      mealLabel: mealLabel,
      periodLabel: DateFormat('MMM d').format(DateTime.now()),
      // Only sum macros for an actual selection — summing a whole menu would
      // be a nonsense "you ate the entire restaurant" total.
      nutrition: selected.isNotEmpty
          ? _nutritionOf(
              calories: cal.round(),
              proteinG: protein,
              carbsG: carbs,
              fatG: fat,
              fiberG: null,
            )
          : null,
      foodItems: [
        for (final i in showing.take(12))
          ShareableFood(
            name: i.name,
            amount: i.description,
            calories: i.scaledCalories.round(),
            proteinG: i.scaledProteinG,
            carbsG: i.scaledCarbsG,
            fatG: i.scaledFatG,
          ),
      ],
      foodImageUrls: _menuImageUrls(showing, menuPhotoUrls),
      accentColor: accent,
    );
  }

  /// Share a single dish off a scanned menu — before logging.
  static Shareable? fromMenuItem(
    MenuItem item, {
    String? restaurantName,
    required Color accent,
  }) {
    if (item.name.trim().isEmpty) return null;
    return Shareable(
      kind: ShareableKind.foodLog,
      title: item.name,
      mealLabel: (restaurantName != null && restaurantName.trim().isNotEmpty)
          ? restaurantName.trim()
          : 'From a menu',
      periodLabel: DateFormat('MMM d').format(DateTime.now()),
      nutrition: _nutritionOf(
        calories: item.scaledCalories.round(),
        proteinG: item.scaledProteinG,
        carbsG: item.scaledCarbsG,
        fatG: item.scaledFatG,
        fiberG: item.fiberG,
      ),
      foodItems: [
        ShareableFood(
          name: item.name,
          amount: item.description ?? item.amount,
          calories: item.scaledCalories.round(),
          proteinG: item.scaledProteinG,
          carbsG: item.scaledCarbsG,
          fatG: item.scaledFatG,
        ),
      ],
      logText: item.description,
      healthScore: item.goalScore,
      foodImageUrls:
          (item.dishImageUrl ?? '').isNotEmpty ? [item.dishImageUrl!] : null,
      accentColor: accent,
    );
  }

  /// Resolved dish thumbnails first (real food), falling back to the scanned
  /// menu-page photos. Null when nothing usable — photo templates need a
  /// non-empty list.
  static List<String>? _menuImageUrls(
    List<MenuItem> items,
    List<String> menuPhotoUrls,
  ) {
    final dish = [
      for (final i in items)
        if ((i.dishImageUrl ?? '').startsWith('http')) i.dishImageUrl!,
    ];
    if (dish.isNotEmpty) return dish;
    final pages = [
      for (final u in menuPhotoUrls)
        if (u.startsWith('http')) u,
    ];
    return pages.isEmpty ? null : pages;
  }

  /// Sum of fiber across logs — null when no log reported any fiber (so
  /// templates can hide the fiber row rather than show a fake 0g).
  static double? _sumFiber(List<FoodLog> logs) {
    final withFiber = logs.where((l) => l.fiberG != null);
    if (withFiber.isEmpty) return null;
    return withFiber.fold<double>(0, (s, l) => s + (l.fiberG ?? 0));
  }

  /// Rounded average of the present health scores — null when none of the
  /// logs carry a score.
  static int? _averageScore(List<FoodLog> logs) {
    final scores = [
      for (final l in logs)
        if (l.healthScore != null) l.healthScore!,
    ];
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// Every non-empty `image_url` in chronological order — null when none
  /// (photo templates require a non-empty list).
  static List<String>? _imageList(List<FoodLog> logs) {
    final urls = [
      for (final l in logs)
        if ((l.imageUrl ?? '').trim().isNotEmpty) l.imageUrl!.trim(),
    ];
    return urls.isEmpty ? null : urls;
  }

  /// Dish name for a single log: the user's own words → else the first food
  /// item → else the joined item names → else a meal-type fallback.
  static String _dishTitle(FoodLog log) {
    final query = _nonEmpty(log.userQuery);
    if (query != null) return query;

    final named = log.foodItems
        .map((it) => it.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (named.length == 1) return named.first;
    if (named.isNotEmpty) return named.join(', ');
    return _mealLabel(log.mealType);
  }

  /// Title for a multi-meal day — the count of distinct items eaten, with a
  /// graceful singular/empty form.
  static String _dayTitle(List<FoodLog> logs) {
    final names = <String>{
      for (final l in logs)
        for (final it in l.foodItems)
          if (it.name.trim().isNotEmpty) it.name.trim().toLowerCase(),
    };
    if (names.isEmpty) return "What I Ate";
    if (names.length == 1) return "What I Ate";
    return "What I Ate Today";
  }

  /// Capitalized meal-type label ("breakfast" → "Breakfast"). Unknown/blank
  /// values fall back to "Meal" rather than rendering an empty eyebrow.
  static String _mealLabel(String mealType) {
    final t = mealType.trim();
    if (t.isEmpty) return 'Meal';
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  /// Short calendar date, e.g. "May 21". Uses the same `intl` formatting the
  /// rest of the codebase relies on.
  static String _shortDate(DateTime dt) => DateFormat('MMM d').format(dt);

  /// Returns the trimmed string, or null when it is null/blank — so callers
  /// can use `??` chains without re-checking `isEmpty`.
  static String? _nonEmpty(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}
