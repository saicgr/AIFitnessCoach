import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons, Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_first_mixin.dart';
import '../models/consistency.dart';
import '../models/progress_charts.dart';
import '../repositories/auth_repository.dart';
import '../repositories/consistency_repository.dart';
import '../repositories/fasting_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/measurements_repository.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/progress_charts_repository.dart';
import '../repositories/scores_repository.dart';
import '../repositories/trends_repository.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../../widgets/trends/trend_correlation.dart';
import 'pillar_history_provider.dart';

/// =========================================================================
/// Trends — unified data layer (Phase G6, rebuilt G8)
/// =========================================================================
///
/// One [trendSeriesProvider] adapts every charting repository into a common
/// `List<TrendPoint>` so the shared chart, the multi-metric overlay, and the
/// Pearson correlation engine all work off a single model.
///
/// A metric is only listed in [TrendMetric] if it has a REAL history source.
/// Metrics with no time-series backend are deliberately omitted — the engine
/// never fabricates data.
///
/// G8 additions:
///  * Nutrition macros now source from the per-day `macros-summary` endpoint
///    with an arbitrary-window `days` override, so logged macros (incl. TODAY)
///    show real per-day values for the WHOLE selected range — fixing the old
///    "flat 50.0 / not enough data" bug where the 7-day weekly summary starved
///    every range wider than a week.
///  * [trendEventsProvider] surfaces real event overlays (workout-completed
///    days, fasting days, rest days) for the chart's background bands.

/// Which repository feeds a given [TrendMetric].
enum TrendSource {
  measurement,
  derivedMetric,
  workoutVolume,
  nutrition,
  activity,
  hydration,
  readiness,
  strength,
  // ── Wave 1 expansion sources (trends_repository) ──────────────────────────
  micros,
  cardio,
  glucose,
  workoutFeedback,
  hormonal,
  flexibility,
  habits,
  wellbeing,
  neat,
  /// Daily pillar score (0..1 completion fraction) recomputed client-side
  /// from existing per-day history endpoints by `pillarHistoryProvider`.
  /// Added 2026-05-22 to surface the four Today-Score pillars (Train,
  /// Nourish, Move, Sleep) in Custom Trends without standing up a new
  /// backend route.
  pillarHistory,

  /// Wave-2 cardio derived metrics persisted daily into
  /// `public.cardio_metric_snapshots` by `cardio_metric_snapshot_job` and
  /// read via `/trends/cardio-series?metric=<key>`. Each [TrendMetric] of
  /// this source carries its server-side `metric_key` in [TrendMetric.metricKey].
  cardioMetricSnapshot,
}

/// High-level grouping used purely for the metric-picker UI so the now-large
/// catalog (~100 metrics) stays scannable. Independent of [TrendSource]
/// (which is about WHERE the data comes from) — a category is about what the
/// user is tracking. [icon] drives the sectioned picker UI.
enum TrendCategory {
  body('Body', Icons.straighten_rounded),
  nutrition('Nutrition', Icons.restaurant_rounded),
  micronutrients('Micronutrients', Icons.science_rounded),
  cardio('Cardio', Icons.directions_run_rounded),
  workout('Workout', Icons.fitness_center_rounded),
  activity('Activity', Icons.local_fire_department_rounded),
  wellbeing('Wellbeing', Icons.self_improvement_rounded),
  hormonal('Hormonal', Icons.favorite_rounded),
  glucose('Glucose', Icons.water_drop_rounded),
  flexibility('Flexibility', Icons.accessibility_new_rounded),
  habits('Habits', Icons.checklist_rounded);

  const TrendCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The selectable time range for a trend series.
enum TrendRange {
  d7('7D', 7),
  d30('30D', 30),
  d90('90D', 90),
  m6('6M', 182),
  y1('1Y', 365),
  all('All', 0);

  const TrendRange(this.label, this.days);

  final String label;

  /// Number of days back from today. `0` means "all available history".
  final int days;

  /// The start date for this range, or null for [TrendRange.all].
  DateTime? startDate() {
    if (days == 0) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
  }
}

/// A metric the user can plot on a trend chart. Each entry declares its
/// display name, unit, accent grouping, and which repository feeds it.
enum TrendMetric {
  // ── Body measurements (measurements_repository) ──────────────────────────
  weight('Weight', TrendSource.measurement, TrendCategory.body,
      measurementType: 'weight'),
  bodyFat('Body Fat', TrendSource.measurement, TrendCategory.body,
      unitOverride: '%', measurementType: 'body_fat'),
  chest('Chest', TrendSource.measurement, TrendCategory.body,
      measurementType: 'chest'),
  waist('Waist', TrendSource.measurement, TrendCategory.body,
      measurementType: 'waist'),
  hips('Hips', TrendSource.measurement, TrendCategory.body,
      measurementType: 'hips'),
  neck('Neck', TrendSource.measurement, TrendCategory.body,
      measurementType: 'neck'),
  shoulders('Shoulders', TrendSource.measurement, TrendCategory.body,
      measurementType: 'shoulders'),
  bicepsLeft('Biceps (L)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'biceps_left'),
  bicepsRight('Biceps (R)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'biceps_right'),
  thighLeft('Thigh (L)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'thigh_left'),
  thighRight('Thigh (R)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'thigh_right'),
  calfLeft('Calf (L)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'calf_left'),
  calfRight('Calf (R)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'calf_right'),
  forearmLeft('Forearm (L)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'forearm_left'),
  forearmRight('Forearm (R)', TrendSource.measurement, TrendCategory.body,
      measurementType: 'forearm_right'),

  // ── Derived body composition (metrics_repository — user_metrics history) ──
  bmi('BMI', TrendSource.derivedMetric, TrendCategory.body,
      unitOverride: '', metricKey: 'bmi'),
  ffmi('FFMI', TrendSource.derivedMetric, TrendCategory.body,
      unitOverride: '', metricKey: 'ffmi'),
  waistToHeight('Waist-to-Height', TrendSource.derivedMetric,
      TrendCategory.body,
      unitOverride: '', metricKey: 'waist_to_height_ratio'),
  leanMass('Lean Mass', TrendSource.derivedMetric, TrendCategory.body,
      metricKey: 'lean_body_mass'),

  // ── Workout ──────────────────────────────────────────────────────────────
  workoutVolume('Workout Volume', TrendSource.workoutVolume,
      TrendCategory.workout,
      unitOverride: 'kg'),
  strength1rm('Strength (1RM)', TrendSource.strength, TrendCategory.workout,
      unitOverride: 'kg'),

  // ── Nutrition (per-day macros-summary endpoint) ──────────────────────────
  calories('Calories', TrendSource.nutrition, TrendCategory.nutrition,
      unitOverride: 'kcal', nutritionField: 'calories'),
  protein('Protein', TrendSource.nutrition, TrendCategory.nutrition,
      unitOverride: 'g', nutritionField: 'protein'),
  carbs('Carbs', TrendSource.nutrition, TrendCategory.nutrition,
      unitOverride: 'g', nutritionField: 'carbs'),
  fat('Fat', TrendSource.nutrition, TrendCategory.nutrition,
      unitOverride: 'g', nutritionField: 'fat'),
  fiber('Fiber', TrendSource.nutrition, TrendCategory.nutrition,
      unitOverride: 'g', nutritionField: 'fiber'),

  // ── Activity (activity_service — /activity/history) ──────────────────────
  steps('Steps', TrendSource.activity, TrendCategory.activity,
      unitOverride: 'steps', metricKey: 'steps'),
  activeCalories('Active Calories', TrendSource.activity,
      TrendCategory.activity,
      unitOverride: 'kcal', metricKey: 'calories_burned'),
  sleepHours('Sleep', TrendSource.activity, TrendCategory.wellbeing,
      unitOverride: 'h', metricKey: 'sleep_minutes'),
  restingHeartRate('Resting HR', TrendSource.activity, TrendCategory.wellbeing,
      unitOverride: 'bpm', metricKey: 'resting_heart_rate'),

  // ── Hydration (hydration_repository — /hydration/logs) ───────────────────
  water('Water', TrendSource.hydration, TrendCategory.nutrition,
      unitOverride: 'ml'),

  // ── Wellbeing (scores_repository — /scores/readiness/history) ────────────
  moodScore('Mood', TrendSource.readiness, TrendCategory.wellbeing,
      unitOverride: '/7', metricKey: 'mood'),
  energyLevel('Energy', TrendSource.readiness, TrendCategory.wellbeing,
      unitOverride: '/7', metricKey: 'energy_level'),
  readinessScore('Readiness', TrendSource.readiness, TrendCategory.wellbeing,
      unitOverride: '/100', metricKey: 'readiness'),

  // ── Wellbeing — fasting (fasting_repository — /fasting/history) ──────────
  fastingHours('Fasting Hours', TrendSource.readiness, TrendCategory.wellbeing,
      unitOverride: 'h', metricKey: 'fasting_hours'),

  // ═══════════════════════════════════════════════════════════════════════
  // Wave 1 expansion — ~85 new metrics across 8 backend endpoints.
  // Every metric reads a numeric field of a `daily_series` row via
  // [seriesField]; the trends_repository fetches the row array.
  // ═══════════════════════════════════════════════════════════════════════

  // ── Micronutrients — 38 daily columns (micros-summary endpoint) ──────────
  // Vitamins.
  microVitaminA('Vitamin A', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_a_ug', color: 0xFFE0823D),
  microVitaminC('Vitamin C', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_c_mg', color: 0xFFE6A817),
  microVitaminD('Vitamin D', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_d_ug', color: 0xFFE6C419),
  microVitaminE('Vitamin E', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_e_mg', color: 0xFFB7C93D),
  microVitaminK('Vitamin K', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_k_ug', color: 0xFF6FBF4F),
  microVitaminB1('Thiamine (B1)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_b1_mg', color: 0xFF4FBF7A),
  microVitaminB2('Riboflavin (B2)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_b2_mg', color: 0xFF3DBFA0),
  microVitaminB3('Niacin (B3)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_b3_mg', color: 0xFF3DB5C0),
  microVitaminB5('Pantothenic (B5)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_b5_mg', color: 0xFF3DA5E0),
  microVitaminB6('Vitamin B6', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'vitamin_b6_mg', color: 0xFF4F8FE0),
  microVitaminB7('Biotin (B7)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_b7_ug', color: 0xFF6F7FE0),
  microVitaminB9('Folate (B9)', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_b9_ug', color: 0xFF8A6FE0),
  microVitaminB12('Vitamin B12', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'vitamin_b12_ug', color: 0xFFA85FE0),
  microCholine('Choline', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'choline_mg', color: 0xFFC04FD6),
  // Minerals.
  microCalcium('Calcium', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'calcium_mg', color: 0xFF00D9C0),
  microIron('Iron', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'iron_mg', color: 0xFFD6675C),
  microMagnesium('Magnesium', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'magnesium_mg', color: 0xFF3DC97A),
  microZinc('Zinc', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'zinc_mg', color: 0xFF7A8C9E),
  microSelenium('Selenium', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'selenium_ug', color: 0xFF9E8C7A),
  microPotassium('Potassium', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'potassium_mg', color: 0xFF4D96FF),
  microSodium('Sodium', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'sodium_mg', color: 0xFFE0A93D),
  microPhosphorus('Phosphorus', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'phosphorus_mg', color: 0xFFB05CD6),
  microCopper('Copper', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'copper_mg', color: 0xFFC9763D),
  microManganese('Manganese', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'manganese_mg', color: 0xFF8C5C3D),
  microIodine('Iodine', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'iodine_ug', color: 0xFF5C3DC9),
  microChromium('Chromium', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'chromium_ug', color: 0xFF6E7B8A),
  microMolybdenum('Molybdenum', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'µg', seriesField: 'molybdenum_ug', color: 0xFF8A7B6E),
  // Fatty acids.
  microOmega3('Omega-3', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'omega3_g', color: 0xFF3DA5E0),
  microOmega6('Omega-6', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'omega6_g', color: 0xFF6FB5E0),
  microSaturatedFat('Saturated Fat', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'saturated_fat_g', color: 0xFFE0823D),
  microTransFat('Trans Fat', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'trans_fat_g', color: 0xFFD6675C),
  microMonoFat('Monounsaturated Fat', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'monounsaturated_fat_g',
      color: 0xFF6FBF4F),
  microPolyFat('Polyunsaturated Fat', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'polyunsaturated_fat_g',
      color: 0xFF4FBF7A),
  // Other.
  microCholesterol('Cholesterol', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'cholesterol_mg', color: 0xFFE0A93D),
  microSugar('Sugar', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'sugar_g', color: 0xFFE06FA8),
  microAddedSugar('Added Sugar', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'added_sugar_g', color: 0xFFD6675C),
  microCaffeine('Caffeine', TrendSource.micros,
      TrendCategory.micronutrients,
      unitOverride: 'mg', seriesField: 'caffeine_mg', color: 0xFF8C5C3D),
  microAlcohol('Alcohol', TrendSource.micros, TrendCategory.micronutrients,
      unitOverride: 'g', seriesField: 'alcohol_g', color: 0xFFB05CD6),

  // ── Cardio (cardio sessions trends endpoint) ─────────────────────────────
  cardioDistance('Cardio Distance', TrendSource.cardio,
      TrendCategory.cardio,
      unitOverride: 'km', seriesField: 'total_distance_km', color: 0xFF3DC97A),
  cardioDuration('Cardio Duration', TrendSource.cardio,
      TrendCategory.cardio,
      unitOverride: 'min', seriesField: 'total_duration_minutes',
      color: 0xFF3DA5E0),
  cardioElevation('Elevation Gain', TrendSource.cardio,
      TrendCategory.cardio,
      unitOverride: 'm', seriesField: 'total_elevation_gain_m',
      color: 0xFF8C5C3D),
  cardioCalories('Cardio Calories', TrendSource.cardio,
      TrendCategory.cardio,
      unitOverride: 'kcal', seriesField: 'total_calories_burned',
      color: 0xFFE0823D),
  cardioAvgSpeed('Avg Speed', TrendSource.cardio, TrendCategory.cardio,
      unitOverride: 'km/h', seriesField: 'avg_speed_kmh', color: 0xFF6FBF4F),
  cardioAvgHr('Cardio Avg HR', TrendSource.cardio, TrendCategory.cardio,
      unitOverride: 'bpm', seriesField: 'avg_heart_rate', color: 0xFFD6675C),
  cardioMaxHr('Cardio Max HR', TrendSource.cardio, TrendCategory.cardio,
      unitOverride: 'bpm', seriesField: 'max_heart_rate', color: 0xFFE0675C),
  vo2Max('VO₂ Max', TrendSource.cardio, TrendCategory.cardio,
      unitOverride: 'ml/kg/min', seriesField: 'vo2_max_estimate',
      color: 0xFF00D9C0),

  // ── Workout feedback (feedback trends endpoint) ──────────────────────────
  feedbackRating('Workout Rating', TrendSource.workoutFeedback,
      TrendCategory.workout,
      unitOverride: '/5', seriesField: 'avg_overall_rating', color: 0xFFE0A93D),
  feedbackEnergy('Workout Energy', TrendSource.workoutFeedback,
      TrendCategory.workout,
      unitOverride: '/5', seriesField: 'avg_energy_level', color: 0xFF3DC97A),
  feedbackDifficulty('Workout Difficulty', TrendSource.workoutFeedback,
      TrendCategory.workout,
      unitOverride: '/5', seriesField: 'avg_overall_difficulty',
      color: 0xFFD6675C),

  // ── Glucose (diabetes glucose trends endpoint) ───────────────────────────
  glucoseAvg('Avg Glucose', TrendSource.glucose, TrendCategory.glucose,
      unitOverride: 'mg/dL', seriesField: 'avg_glucose', color: 0xFFE0823D),
  glucoseMin('Min Glucose', TrendSource.glucose, TrendCategory.glucose,
      unitOverride: 'mg/dL', seriesField: 'min_glucose', color: 0xFF3DC97A),
  glucoseMax('Max Glucose', TrendSource.glucose, TrendCategory.glucose,
      unitOverride: 'mg/dL', seriesField: 'max_glucose', color: 0xFFD6675C),
  insulinUnits('Insulin Units', TrendSource.glucose, TrendCategory.glucose,
      unitOverride: 'U', seriesField: 'total_insulin_units', color: 0xFF3DA5E0),
  a1c('A1c', TrendSource.glucose, TrendCategory.glucose,
      unitOverride: '%', seriesField: 'a1c_value', color: 0xFFB05CD6),

  // ── Hormonal / cycle (hormonal-health trends endpoint) ───────────────────
  cycleDay('Cycle Day', TrendSource.hormonal, TrendCategory.hormonal,
      unitOverride: 'd', seriesField: 'cycle_day', color: 0xFFE06FA8),
  periodFlow('Period Flow', TrendSource.hormonal, TrendCategory.hormonal,
      unitOverride: '/4', seriesField: 'period_flow', color: 0xFFD6675C),
  basalTemp('Basal Body Temp', TrendSource.hormonal,
      TrendCategory.hormonal,
      unitOverride: '°C', seriesField: 'basal_body_temperature',
      color: 0xFFE0823D),
  cycleEnergy('Cycle Energy', TrendSource.hormonal, TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'energy_level', color: 0xFF3DC97A),
  cycleSleepQuality('Cycle Sleep Quality', TrendSource.hormonal,
      TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'sleep_quality', color: 0xFF8A6FE0),
  libido('Libido', TrendSource.hormonal, TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'libido_level', color: 0xFFC04FD6),
  cycleStress('Cycle Stress', TrendSource.hormonal,
      TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'stress_level', color: 0xFFE0A93D),
  cycleMotivation('Cycle Motivation', TrendSource.hormonal,
      TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'motivation_level', color: 0xFF3DA5E0),
  cycleRecovery('Cycle Recovery', TrendSource.hormonal,
      TrendCategory.hormonal,
      unitOverride: '/5', seriesField: 'recovery_feeling', color: 0xFF4FBF7A),

  // ── Flexibility (flexibility trends endpoint) ────────────────────────────
  flexibilityMeasurement('Flexibility Measurement', TrendSource.flexibility,
      TrendCategory.flexibility,
      unitOverride: 'cm', seriesField: 'measurement', color: 0xFF3DC97A),
  flexibilityRating('Flexibility Rating', TrendSource.flexibility,
      TrendCategory.flexibility,
      unitOverride: '/5', seriesField: 'rating', color: 0xFFE0A93D),
  flexibilityPercentile('Flexibility Percentile', TrendSource.flexibility,
      TrendCategory.flexibility,
      unitOverride: '%', seriesField: 'percentile', color: 0xFF3DA5E0),

  // ── Habits (habits trends endpoint) ──────────────────────────────────────
  habitCompletion('Habit Completion', TrendSource.habits,
      TrendCategory.habits,
      unitOverride: '%', seriesField: 'completion_percentage',
      color: 0xFF3DC97A),

  // ── Wellbeing (wellbeing-trends endpoint) ────────────────────────────────
  fitnessScore('Fitness Score', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/100', seriesField: 'fitness_score', color: 0xFF3DC97A),
  wellbeingReadiness('Readiness Score', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/100', seriesField: 'readiness_score', color: 0xFF3DA5E0),
  fastingScore('Fasting Score', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/100', seriesField: 'fasting_score', color: 0xFF8A6FE0),
  morningMood('Morning Mood', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/5', seriesField: 'morning_mood', color: 0xFFE0A93D),
  morningEnergy('Morning Energy', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/5', seriesField: 'morning_energy', color: 0xFFE0823D),
  eveningMood('Evening Mood', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/5', seriesField: 'evening_mood', color: 0xFFB05CD6),
  overallDayRating('Overall Day Rating', TrendSource.wellbeing,
      TrendCategory.wellbeing,
      unitOverride: '/5', seriesField: 'overall_day_rating', color: 0xFF4FBF7A),

  // ── NEAT (neat score trends endpoint) ────────────────────────────────────
  neatScore('NEAT Score', TrendSource.neat, TrendCategory.activity,
      unitOverride: '/100', seriesField: 'neat_score', color: 0xFF3DC97A),
  neatStepGoalPct('Step Goal %', TrendSource.neat, TrendCategory.activity,
      unitOverride: '%', seriesField: 'step_goal_percentage',
      color: 0xFF3DA5E0),
  neatTotalSteps('NEAT Steps', TrendSource.neat, TrendCategory.activity,
      unitOverride: 'steps', seriesField: 'total_steps', color: 0xFFE0823D),
  neatActiveHours('Active Hours', TrendSource.neat, TrendCategory.activity,
      unitOverride: 'h', seriesField: 'active_hours', color: 0xFFE0A93D),

  // ── Today-Score pillars (pillar_history_provider) ────────────────────────
  // Each entry surfaces a 0-100 daily completion fraction for one pillar of
  // the Today Score, recomputed client-side from existing per-day history.
  pillarTrain('Train score', TrendSource.pillarHistory, TrendCategory.workout,
      unitOverride: '/100', metricKey: 'train', color: 0xFFEC8B2C),
  pillarNourish('Nourish score', TrendSource.pillarHistory,
      TrendCategory.nutrition,
      unitOverride: '/100', metricKey: 'nourish', color: 0xFF3FA66B),
  pillarMove('Move score', TrendSource.pillarHistory, TrendCategory.activity,
      unitOverride: '/100', metricKey: 'move', color: 0xFF3E8FD0),
  pillarSleep('Sleep score', TrendSource.pillarHistory,
      TrendCategory.wellbeing,
      unitOverride: '/100', metricKey: 'sleep', color: 0xFF8B5CF6),

  // ── Cardio metric snapshots (Wave-2 SLICE_TRENDS) ───────────────────────
  // 13 derived cardio metrics persisted daily by `cardio_metric_snapshot_job`.
  // Each metric resolves through `/trends/cardio-series?metric=<metric_key>`
  // and renders inside the existing "Cardio" category in the picker. Boolean
  // tags (e.g. is_hill_workout) are intentionally NOT registered — the trend
  // infra is numeric-only.
  racePredicted5k('Race 5K predicted', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 's', metricKey: 'race_predicted_5k_sec',
      color: 0xFF3DC97A),
  racePredicted10k('Race 10K predicted', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 's', metricKey: 'race_predicted_10k_sec',
      color: 0xFF3DA5E0),
  racePredictedHalf('Race Half predicted', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 's', metricKey: 'race_predicted_half_sec',
      color: 0xFF8A6FE0),
  racePredictedMarathon('Race Marathon predicted',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: 's', metricKey: 'race_predicted_marathon_sec',
      color: 0xFFB05CD6),
  trainingLoadAcute('Training Load (Acute)',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: 'TRIMP', metricKey: 'training_load_acute',
      color: 0xFFE0823D),
  trainingLoadChronic('Training Load (Chronic)',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: 'TRIMP', metricKey: 'training_load_chronic',
      color: 0xFFE0A93D),
  trainingLoadAcwr('Training Load (ACWR)',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: 'ratio', metricKey: 'training_load_acwr',
      color: 0xFFD6675C),
  cardioWeeklyDistance('Weekly Distance', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 'm', metricKey: 'cardio_weekly_distance_m',
      color: 0xFF3DC97A),
  cardioLongestRun('Longest Run (7d)', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 'm', metricKey: 'cardio_longest_run_m',
      color: 0xFF6FBF4F),
  cardioFastestMile('Fastest Mile (7d)', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 's', metricKey: 'cardio_fastest_mile_sec',
      color: 0xFF4FBF7A),
  cardioPaceAvg('Avg Pace', TrendSource.cardioMetricSnapshot,
      TrendCategory.cardio,
      unitOverride: 's/km', metricKey: 'cardio_pace_avg_sec_per_km',
      color: 0xFF00D9C0),
  cardioWeatherTemp('Avg Run Temperature',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: '°C', metricKey: 'cardio_weather_temp_at_run_c',
      color: 0xFFE0A93D),
  refuelCarbsRecommended('Refuel Carbs (Recommended)',
      TrendSource.cardioMetricSnapshot, TrendCategory.cardio,
      unitOverride: 'g', metricKey: 'refuel_carbs_recommended_g',
      color: 0xFFEC8B2C);

  const TrendMetric(
    this.displayName,
    this.source,
    this.category, {
    this.unitOverride,
    this.measurementType,
    this.nutritionField,
    this.metricKey,
    this.seriesField,
    this.color,
  });

  /// Human-readable name shown in pickers, legends and titles.
  final String displayName;

  /// Repository that feeds this metric.
  final TrendSource source;

  /// UI grouping for the metric picker.
  final TrendCategory category;

  /// Fixed unit (e.g. '%', 'kcal'). When null the unit is resolved from the
  /// user's preferred unit system at fetch time (e.g. weight → kg/lbs).
  final String? unitOverride;

  /// `MeasurementType.apiValue` when [source] is a body measurement.
  final String? measurementType;

  /// Macro field key when [source] is nutrition.
  final String? nutritionField;

  /// Generic dispatch key for derived-metric / activity / readiness sources
  /// (e.g. 'steps', 'bmi', 'mood'). Identifies which field of a shared
  /// response object this metric reads.
  final String? metricKey;

  /// `daily_series` row field this metric projects, for Wave 1 sources
  /// (micros / cardio / glucose / feedback / hormonal / flexibility /
  /// habits / wellbeing / neat). Null for legacy sources.
  final String? seriesField;

  /// Distinct ARGB colour for the metric, for the picker swatch + chart
  /// legend. Null for the legacy catalog (those use the accent / overlay
  /// palette); resolved via [accentColor].
  final int? color;

  /// Resolved series colour — the metric's own [color] when set, else a
  /// stable hash-derived hue so even legacy metrics get a distinct swatch.
  Color get accentColor {
    if (color != null) return Color(color!);
    // Deterministic fallback hue from the enum name.
    const palette = [
      0xFFE0823D, 0xFF3DA5E0, 0xFFB05CD6, 0xFF3DC97A,
      0xFFE0A93D, 0xFFD6675C, 0xFF00D9C0, 0xFF8A6FE0,
    ];
    return Color(palette[name.hashCode.abs() % palette.length]);
  }

  /// All metrics, in catalog order — for pickers.
  static List<TrendMetric> get catalog => TrendMetric.values;
}

/// A fully-resolved trend series: the points plus presentation metadata.
class TrendSeries {
  final TrendMetric metric;
  final TrendRange range;
  final List<TrendPoint> points;

  /// Resolved unit string (after unit-system conversion).
  final String unit;

  /// The date of the user's earliest-ever data point for this metric, when
  /// known. Lets the UI show an honest "logging history starts ..." note
  /// instead of a misleading empty chart when a range simply predates the
  /// user's first log.
  final DateTime? historyStart;

  const TrendSeries({
    required this.metric,
    required this.range,
    required this.points,
    required this.unit,
    this.historyStart,
  });

  bool get isEmpty => points.isEmpty;
  bool get hasEnoughForDelta => points.length >= 2;

  /// Serialises to a JSON map for the Trends disk cache.
  ///
  /// `metric` and `range` are stored by their stable enum `name` so a catalog
  /// reorder never corrupts a cached blob. The point list reuses
  /// [TrendPoint.toJson]. `historyStart` is epoch-ms or null.
  Map<String, dynamic> toJson() => {
        'metric': metric.name,
        'range': range.name,
        'unit': unit,
        'historyStart': historyStart?.millisecondsSinceEpoch,
        'points': [for (final p in points) p.toJson()],
      };

  /// Rebuilds a [TrendSeries] from [toJson]. A missing/unknown metric or range
  /// name throws — the cache layer treats that as a corrupt-blob miss and
  /// falls back to a clean network fetch (no fabricated data).
  factory TrendSeries.fromJson(Map<String, dynamic> j) {
    final metric =
        TrendMetric.values.firstWhere((m) => m.name == j['metric']);
    final range = TrendRange.values.firstWhere((r) => r.name == j['range']);
    final hs = j['historyStart'];
    return TrendSeries(
      metric: metric,
      range: range,
      unit: (j['unit'] as String?) ?? '',
      historyStart:
          hs == null ? null : DateTime.fromMillisecondsSinceEpoch(hs as int),
      points: [
        for (final raw in (j['points'] as List? ?? const []))
          TrendPoint.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
    );
  }
}

/// Immutable, hashable key for the [trendSeriesProvider] family.
@immutable
class TrendSeriesKey {
  final TrendMetric metric;
  final TrendRange range;

  const TrendSeriesKey(this.metric, this.range);

  @override
  bool operator ==(Object other) =>
      other is TrendSeriesKey &&
      other.metric == metric &&
      other.range == range;

  @override
  int get hashCode => Object.hash(metric, range);
}

/// Per-metric disk-cache TTL for the Trends instant-load layer.
///
/// Different metrics go stale at very different rates, so a single global TTL
/// would either serve stale data for slow-moving metrics or thrash the network
/// for fast ones. Buckets (all within the task's ~1–12h band):
///  * ~1h  — fast intraday metrics: nutrition macros, micros, hydration,
///           activity, glucose (logged many times a day; today's value moves).
///  * ~3h  — readiness / wellbeing check-ins, workout feedback, cardio, NEAT
///           (typically logged once a day).
///  * ~12h — slow body metrics: measurements, derived composition, strength
///           1RM, weekly workout volume, hormonal cycle, flexibility, habits
///           (change over days/weeks — a long TTL is safe and very cheap).
///
/// The notifier still ALWAYS revalidates in the background after serving the
/// cached value, so the TTL only governs whether the cached value is shown
/// instantly on open — never whether fresh data is fetched.
Duration _ttlFor(TrendMetric metric) {
  switch (metric.source) {
    case TrendSource.nutrition:
    case TrendSource.micros:
    case TrendSource.hydration:
    case TrendSource.activity:
    case TrendSource.glucose:
      return const Duration(hours: 1);
    case TrendSource.readiness:
    case TrendSource.wellbeing:
    case TrendSource.workoutFeedback:
    case TrendSource.cardio:
    case TrendSource.neat:
      return const Duration(hours: 3);
    case TrendSource.measurement:
    case TrendSource.derivedMetric:
    case TrendSource.strength:
    case TrendSource.workoutVolume:
    case TrendSource.hormonal:
    case TrendSource.flexibility:
    case TrendSource.habits:
      return const Duration(hours: 12);
    case TrendSource.pillarHistory:
      // Pillar history is recomputed on-device from other providers' caches —
      // a 1-hour TTL keeps the trend chart responsive without forcing a full
      // re-fetch every time the user opens Custom Trends.
      return const Duration(hours: 1);
    case TrendSource.cardioMetricSnapshot:
      // Snapshots are written once per day by the cron job — a 3-hour TTL
      // matches the other cardio sources.
      return const Duration(hours: 3);
  }
}

/// Disk-cache schema version for a persisted [TrendSeries] blob. Bump when
/// [TrendSeries.toJson] / [TrendPoint.toJson] change shape so stale blobs are
/// dropped rather than decoded into a wrong-shaped object.
const int _kTrendSeriesSchema = 1;

/// Unified trend-series provider (G6/G8 — instant-load Part 2).
///
/// `ref.watch(trendSeriesProvider(TrendSeriesKey(metric, range)))` returns an
/// `AsyncValue<TrendSeries>` of date-sorted [TrendPoint]s, regardless of which
/// repository the metric actually comes from.
///
/// Instant-load: this is now a cache-first [StateNotifierProvider]. On open it
/// emits the disk-cached series (if any, within [_ttlFor]) SYNCHRONOUSLY-fast,
/// then revalidates over the network and emits the fresh value — so re-opening
/// the Trends screen is instant instead of blocking on a spinner. The exposed
/// type is still `AsyncValue<TrendSeries>`, so every `.watch(...).when(...)` /
/// `.valueOrNull` call site keeps working unchanged.
final trendSeriesProvider = StateNotifierProvider.family.autoDispose<
    _TrendSeriesNotifier, AsyncValue<TrendSeries>, TrendSeriesKey>(
  (ref, key) => _TrendSeriesNotifier(ref, key)..load(),
);

/// Cache-first notifier for one (metric, range) trend series.
class _TrendSeriesNotifier extends StateNotifier<AsyncValue<TrendSeries>>
    with CacheFirstMixin {
  _TrendSeriesNotifier(this._ref, this._key)
      : super(const AsyncValue.loading());

  final Ref _ref;
  final TrendSeriesKey _key;

  /// Disposal flag tracked explicitly. [CacheFirstMixin] declares its own
  /// concrete `mounted` getter, which (by Dart mixin linearization) shadows
  /// `StateNotifier.mounted`; overriding it here with a real, dispose-aware
  /// value is what makes the mixin's mounted-guards behave correctly — so a
  /// late network response can never emit into a disposed notifier.
  bool _disposed = false;

  @override
  bool get mounted => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Run the cache-first load: emit the disk-cached series instantly (if
  /// present + in-TTL), then fetch fresh and emit again. Never throws.
  Future<void> load() => loadCacheFirst<TrendSeries>(
        // Key base — the mixin appends user-scope + schema. Metric + range
        // are part of the base so every (metric, range) pair has its own slot.
        cacheKey: 'trend_series::${_key.metric.name}::${_key.range.name}',
        userId: _ref.read(authStateProvider).user?.id ?? '',
        ttl: _ttlFor(_key.metric),
        schemaVersion: _kTrendSeriesSchema,
        fetch: () => _fetchTrendSeries(_ref, _key),
        decode: TrendSeries.fromJson,
        encode: (s) => s.toJson(),
        emit: (data, {required bool fromCache}) {
          if (!mounted) return;
          state = AsyncValue.data(data);
        },
        onError: (e, st) {
          // Surface the network failure ONLY when nothing was served from
          // cache — otherwise the cached series stays on screen (cache-first
          // contract: a transient failure never blanks a populated chart).
          if (!mounted) return;
          if (state.valueOrNull == null) state = AsyncValue.error(e, st);
        },
      );
}

/// Network fetch for one trend series — the former `FutureProvider` body,
/// extracted verbatim so the cache-first notifier can call it as its `fetch`.
Future<TrendSeries> _fetchTrendSeries(Ref ref, TrendSeriesKey key) async {
  final auth = ref.read(authStateProvider);
  final userId = auth.user?.id;
  if (userId == null) {
    return TrendSeries(
      metric: key.metric, range: key.range, points: const [], unit: '');
  }

  final metric = key.metric;
  final range = key.range;
  final start = range.startDate();

  List<TrendPoint> points;
  String unit;
  DateTime? historyStart;

  switch (metric.source) {
    case TrendSource.measurement:
      final result = await _fetchMeasurementSeries(ref, userId, metric);
      points = result.$1;
      unit = result.$2;
      break;
    case TrendSource.derivedMetric:
      final result = await _fetchDerivedMetricSeries(ref, userId, metric);
      points = result.$1;
      unit = result.$2;
      break;
    case TrendSource.workoutVolume:
      points = await _fetchVolumeSeries(ref, userId, range);
      unit = metric.unitOverride ?? 'kg';
      break;
    case TrendSource.strength:
      points = await _fetchStrengthSeries(ref, userId, range);
      unit = _strengthUnit(ref);
      break;
    case TrendSource.nutrition:
      points = await _fetchNutritionSeries(ref, userId, metric, range);
      unit = metric.unitOverride ?? '';
      break;
    case TrendSource.activity:
      final result = await _fetchActivitySeries(ref, userId, metric, range);
      points = result.$1;
      unit = result.$2;
      break;
    case TrendSource.hydration:
      points = await _fetchHydrationSeries(ref, userId, range);
      unit = metric.unitOverride ?? 'ml';
      break;
    case TrendSource.readiness:
      if (metric == TrendMetric.fastingHours) {
        points = await _fetchFastingHoursSeries(ref, userId, range);
      } else {
        points = await _fetchReadinessSeries(ref, userId, metric, range);
      }
      unit = metric.unitOverride ?? '';
      break;
    case TrendSource.micros:
    case TrendSource.cardio:
    case TrendSource.glucose:
    case TrendSource.workoutFeedback:
    case TrendSource.hormonal:
    case TrendSource.flexibility:
    case TrendSource.habits:
    case TrendSource.wellbeing:
    case TrendSource.neat:
      points = await _fetchWaveOneSeries(ref, userId, metric, range);
      unit = metric.unitOverride ?? '';
      break;
    case TrendSource.pillarHistory:
      points = await _fetchPillarHistorySeries(ref, metric, range);
      unit = metric.unitOverride ?? '/100';
      break;
    case TrendSource.cardioMetricSnapshot:
      points = await _fetchCardioSnapshotSeries(ref, metric, range);
      unit = metric.unitOverride ?? '';
      break;
  }

  // Collapse to ONE point per local calendar day BEFORE charting. Multiple
  // entries on the same day (e.g. two weigh-ins) would otherwise produce
  // points with near-identical x — fl_chart's curved line then loops back on
  // itself ("the weird Weight loop/spike"). Aggregating by day guarantees a
  // strictly-monotonic x axis for every source.
  points = _aggregateByDay(points);

  // The earliest point overall is the honest "history starts" anchor.
  if (points.isNotEmpty) {
    historyStart = points
        .map((p) => p.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  // Range-filter (skip for All) and sort ascending by date.
  if (start != null) {
    points = points.where((p) => !p.date.isBefore(start)).toList();
  }
  points.sort((a, b) => a.date.compareTo(b.date));

  return TrendSeries(
    metric: metric,
    range: range,
    points: points,
    unit: unit,
    historyStart: historyStart,
  );
}

/// Collapses a series to exactly one [TrendPoint] per local calendar day.
///
/// For a day with multiple entries the **average** is used: same-day
/// body-measurement weigh-ins are noisy (water weight, time of day), so the
/// day's mean is the honest single value — and nutrition/volume sources never
/// repeat a day, so averaging is a no-op for them. The returned point is
/// anchored to local midnight so its x is deterministic and strictly
/// increasing once sorted — eliminating the curved-line loop fl_chart drew
/// when two points shared a near-identical timestamp.
List<TrendPoint> _aggregateByDay(List<TrendPoint> points) {
  if (points.length < 2) return points;
  final sums = <DateTime, double>{};
  final counts = <DateTime, int>{};
  for (final p in points) {
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    sums[day] = (sums[day] ?? 0) + p.value;
    counts[day] = (counts[day] ?? 0) + 1;
  }
  final out = [
    for (final e in sums.entries)
      TrendPoint(date: e.key, value: e.value / counts[e.key]!),
  ];
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

// ───────────────────────────────────────────────────────────────────────────
// Source adapters
// ───────────────────────────────────────────────────────────────────────────

/// Body-measurement series → [TrendPoint]s in the user's preferred unit.
Future<(List<TrendPoint>, String)> _fetchMeasurementSeries(
  Ref ref,
  String userId,
  TrendMetric metric,
) async {
  final apiValue = metric.measurementType;
  if (apiValue == null) return (const <TrendPoint>[], '');

  final type = MeasurementType.fromApiValue(apiValue);
  if (type == null) return (const <TrendPoint>[], '');

  final auth = ref.read(authStateProvider);
  final isMetric = auth.user?.usesMetricMeasurements ?? true;

  final repo = ref.read(measurementsRepositoryProvider);
  final history = await repo.getMeasurementHistory(userId, type, limit: 365);

  final points = [
    for (final e in history)
      TrendPoint(date: e.recordedAt, value: e.getValueInUnit(isMetric)),
  ];
  final unit =
      metric.unitOverride ?? (isMetric ? type.metricUnit : type.imperialUnit);
  return (points, unit);
}

/// Weekly workout-volume series → one [TrendPoint] per week.
Future<List<TrendPoint>> _fetchVolumeSeries(
  Ref ref,
  String userId,
  TrendRange range,
) async {
  final repo = ref.read(progressChartsRepositoryProvider);
  // Map the unified range onto the volume endpoint's coarser buckets.
  final pcRange = range.days == 0
      ? ProgressTimeRange.allTime
      : (range.days <= 30
          ? ProgressTimeRange.fourWeeks
          : (range.days <= 90
              ? ProgressTimeRange.twelveWeeks
              : ProgressTimeRange.allTime));
  final data =
      await repo.getVolumeOverTime(userId: userId, timeRange: pcRange);
  final out = <TrendPoint>[];
  for (final week in data.data) {
    final d = week.weekStartDate;
    if (d == null || week.totalVolumeKg <= 0) continue;
    out.add(TrendPoint(date: d, value: week.totalVolumeKg));
  }
  return out;
}

/// Daily nutrition macro series — REAL per-day logged values.
///
/// Root-cause fix (G8): the old implementation read the 7-day weekly summary
/// (`/nutrition/summary/weekly`), which is hard-coded to today-6 → today. Any
/// range wider than a week was starved to ≤7 points, and with most days
/// unlogged only a single point survived — so the chart showed a flat line
/// and correlation reported "not enough overlapping data". TODAY's freshly
/// logged macros were also frequently lost to that 7-day clamp.
///
/// We now hit `/nutrition/food-patterns/macros-summary` with a `days` override
/// equal to the selected range, which returns one real `DailyMacroPoint` per
/// logged day across the WHOLE window (today included). Days with no logged
/// food are simply absent — never fabricated.
Future<List<TrendPoint>> _fetchNutritionSeries(
  Ref ref,
  String userId,
  TrendMetric metric,
  TrendRange range,
) async {
  final repo = ref.read(nutritionRepositoryProvider);
  // `days: 0` ⇒ all history (backend caps at ~5y). Otherwise the exact window.
  var summary = await repo.getMacrosSummaryRange(
    userId,
    days: range.days,
  );
  // Resilience: a null here means the endpoint errored (NOT "no data" — an
  // empty log set still returns a 200 with an empty daily_series). Retry once
  // against the widest available source (all-history) so a transient failure
  // on the narrow window doesn't silently drop the line. The outer provider
  // range-filters the result, so over-fetching is safe.
  if (summary == null && range.days != 0) {
    summary = await repo.getMacrosSummaryRange(userId, days: 0);
  }
  // Genuinely unreachable endpoint → honest empty series (FIX 2 surfaces the
  // per-metric "No data" note). Never fabricate points.
  if (summary == null) return const [];

  final out = <TrendPoint>[];
  for (final day in summary.dailySeries) {
    final date = DateTime.tryParse(day.date);
    if (date == null) continue;
    // A day appears in daily_series only when food was logged, so a 0 here is
    // a genuine logged 0 — keep it. Still guard the all-zero "empty" row.
    if (day.calories <= 0 &&
        day.proteinG <= 0 &&
        day.carbsG <= 0 &&
        day.fatG <= 0) {
      continue;
    }
    final double value;
    switch (metric.nutritionField) {
      case 'calories':
        value = day.calories.toDouble();
        break;
      case 'protein':
        value = day.proteinG;
        break;
      case 'carbs':
        value = day.carbsG;
        break;
      case 'fat':
        value = day.fatG;
        break;
      case 'fiber':
        value = day.fiberG;
        break;
      default:
        continue;
    }
    out.add(TrendPoint(date: date, value: value));
  }
  return out;
}

/// Derived body-composition series (BMI / FFMI / waist-to-height / lean mass)
/// → [TrendPoint]s from the `user_metrics` history endpoint.
///
/// REAL source: every `/metrics/calculate` call writes a `user_metrics` row
/// carrying bmi, ffmi, waist_to_height_ratio and lean_body_mass. The history
/// endpoint (`/metrics/history`) now exposes those derived columns, so each
/// recalculation is a genuine dated data point — never fabricated.
Future<(List<TrendPoint>, String)> _fetchDerivedMetricSeries(
  Ref ref,
  String userId,
  TrendMetric metric,
) async {
  final key = metric.metricKey;
  if (key == null) return (const <TrendPoint>[], '');

  // The /metrics/history rows (user_metrics table) carry every derived field
  // at once — bmi, ffmi, waist_to_height_ratio, lean_body_mass — so we fetch
  // the raw rows and project the requested field. Fetched directly via the
  // API client because the typed repository model only surfaces a subset.
  final entries = <Map<String, dynamic>>[];
  try {
    final client = ref.read(apiClientProvider);
    final response = await client.get(
      '/metrics/history/$userId',
      queryParameters: const {'limit': 365},
    );
    if (response.statusCode == 200 && response.data is List) {
      for (final row in response.data as List) {
        if (row is Map) entries.add(Map<String, dynamic>.from(row));
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] derived-metric series unavailable: $e');
    return (const <TrendPoint>[], metric.unitOverride ?? '');
  }

  final auth = ref.read(authStateProvider);
  final isMetric = auth.user?.usesMetricMeasurements ?? true;

  final out = <TrendPoint>[];
  for (final e in entries) {
    final raw = (e[key] as num?)?.toDouble();
    if (raw == null || raw <= 0) continue;
    final dateStr = e['recorded_at'] as String?;
    final date = dateStr == null ? null : DateTime.tryParse(dateStr);
    if (date == null) continue;
    // Lean mass is a mass — convert to the user's preferred unit. BMI / FFMI /
    // waist-to-height are unitless ratios and need no conversion.
    final value =
        (key == 'lean_body_mass' && !isMetric) ? raw * 2.20462 : raw;
    out.add(TrendPoint(date: date, value: value));
  }
  final unit = metric.unitOverride ??
      (key == 'lean_body_mass' ? (isMetric ? 'kg' : 'lbs') : '');
  return (out, unit);
}

String _strengthUnit(Ref ref) {
  final auth = ref.read(authStateProvider);
  final isMetric = auth.user?.usesMetricMeasurements ?? true;
  return isMetric ? 'kg' : 'lbs';
}

/// Strength (best estimated 1RM per day) → [TrendPoint]s from logged personal
/// records. Each PR (`/scores/personal-records`) carries a real
/// `estimated1rmKg` + `achievedAt`; the day's series value is the highest 1RM
/// achieved that day across all lifts. No PR logged ⇒ no point — never faked.
Future<List<TrendPoint>> _fetchStrengthSeries(
  Ref ref,
  String userId,
  TrendRange range,
) async {
  final repo = ref.read(scoresRepositoryProvider);
  // Cover the whole window: the PR endpoint takes a period in days. `0` (All)
  // maps to a wide 5-year lookback; the outer provider range-filters anyway.
  final periodDays = range.days == 0 ? 1825 : range.days;
  try {
    final stats = await repo.getPersonalRecords(
      userId: userId,
      limit: 500,
      periodDays: periodDays,
    );
    final auth = ref.read(authStateProvider);
    final isMetric = auth.user?.usesMetricMeasurements ?? true;
    final out = <TrendPoint>[];
    for (final pr in stats.recentPrs) {
      final date = DateTime.tryParse(pr.achievedAt);
      if (date == null || pr.estimated1rmKg <= 0) continue;
      final value =
          isMetric ? pr.estimated1rmKg : pr.estimated1rmKg * 2.20462;
      out.add(TrendPoint(date: date, value: value));
    }
    // _aggregateByDay averages same-day points; for 1RM the daily MAX is the
    // honest value, so collapse to the per-day best here first.
    return _maxByDay(out);
  } catch (e) {
    debugPrint('⚠️ [Trends] strength series unavailable: $e');
    return const [];
  }
}

/// Collapses to one point per day taking the day's MAXIMUM (used for 1RM).
List<TrendPoint> _maxByDay(List<TrendPoint> points) {
  if (points.length < 2) return points;
  final best = <DateTime, double>{};
  for (final p in points) {
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    final cur = best[day];
    if (cur == null || p.value > cur) best[day] = p.value;
  }
  final out = [
    for (final e in best.entries) TrendPoint(date: e.key, value: e.value),
  ];
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// Daily activity series (steps / active calories / sleep / resting HR) →
/// [TrendPoint]s from the synced `/activity/history` endpoint. Every row is a
/// real synced day from HealthKit / Health Connect — days with no synced data
/// are simply absent.
Future<(List<TrendPoint>, String)> _fetchActivitySeries(
  Ref ref,
  String userId,
  TrendMetric metric,
  TrendRange range,
) async {
  final service = ref.read(activityServiceProvider);
  final key = metric.metricKey;
  if (key == null) return (const <TrendPoint>[], '');

  final now = DateTime.now();
  final from = range.startDate() ??
      DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1825));
  final history = await service.getActivityHistory(
    userId,
    limit: 2000,
    fromDate: from,
    toDate: now,
  );

  final out = <TrendPoint>[];
  for (final a in history) {
    final double? value;
    switch (key) {
      case 'steps':
        value = a.steps > 0 ? a.steps.toDouble() : null;
        break;
      case 'calories_burned':
        value = a.caloriesBurned > 0 ? a.caloriesBurned : null;
        break;
      case 'sleep_minutes':
        value = (a.sleepMinutes != null && a.sleepMinutes! > 0)
            ? a.sleepMinutes! / 60.0 // minutes → hours
            : null;
        break;
      case 'resting_heart_rate':
        value = (a.restingHeartRate != null && a.restingHeartRate! > 0)
            ? a.restingHeartRate!.toDouble()
            : null;
        break;
      default:
        value = null;
    }
    if (value == null) continue;
    out.add(TrendPoint(date: a.date, value: value));
  }
  return (out, metric.unitOverride ?? '');
}

/// Hydration series → one [TrendPoint] per day of total logged water (ml).
/// REAL source: `/hydration/logs` — each [HydrationLog] is a logged drink;
/// the day's value is the sum of every log on that calendar day.
Future<List<TrendPoint>> _fetchHydrationSeries(
  Ref ref,
  String userId,
  TrendRange range,
) async {
  final repo = ref.read(hydrationRepositoryProvider);
  // `getLogs` takes a day window; All → wide 5-year lookback.
  final days = range.days == 0 ? 1825 : range.days;
  try {
    final logs = await repo.getLogs(userId, days: days);
    final perDay = <DateTime, double>{};
    for (final log in logs) {
      final when = log.loggedAt;
      if (when == null || log.amountMl <= 0) continue;
      final day = DateTime(when.year, when.month, when.day);
      perDay[day] = (perDay[day] ?? 0) + log.amountMl;
    }
    final out = [
      for (final e in perDay.entries)
        TrendPoint(date: e.key, value: e.value),
    ];
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  } catch (e) {
    debugPrint('⚠️ [Trends] hydration series unavailable: $e');
    return const [];
  }
}

/// Readiness check-in series (mood / energy / readiness score) → [TrendPoint]s
/// from `/scores/readiness/history`. Each [ReadinessScore] is a real dated
/// check-in. Mood and energy are stored 1–7 with 1 = best; we invert them to a
/// natural "higher is better" 1–7 scale for the chart. Readiness score is
/// already 0–100 higher-is-better.
Future<List<TrendPoint>> _fetchReadinessSeries(
  Ref ref,
  String userId,
  TrendMetric metric,
  TrendRange range,
) async {
  final repo = ref.read(scoresRepositoryProvider);
  final days = range.days == 0 ? 1825 : range.days;
  try {
    final history = await repo.getReadinessHistory(userId: userId, days: days);
    final key = metric.metricKey;
    final out = <TrendPoint>[];
    for (final s in history.readinessScores) {
      final date = DateTime.tryParse(s.scoreDate);
      if (date == null) continue;
      final double? value;
      switch (key) {
        case 'mood':
          // 1-7, 1=best → invert so 7=best for an intuitive chart.
          value = s.mood == null ? null : (8 - s.mood!).toDouble();
          break;
        case 'energy_level':
          value =
              s.energyLevel == null ? null : (8 - s.energyLevel!).toDouble();
          break;
        case 'readiness':
          value = s.readinessScore.toDouble();
          break;
        default:
          value = null;
      }
      if (value == null) continue;
      out.add(TrendPoint(date: date, value: value));
    }
    return out;
  } catch (e) {
    debugPrint('⚠️ [Trends] readiness series unavailable: $e');
    return const [];
  }
}

/// Fasting-hours-per-day series → [TrendPoint]s from `/fasting/history`.
/// REAL source: each [FastingRecord] has a start and (completed) end time; the
/// fast's elapsed hours are attributed to the calendar day it STARTED on. A
/// day with multiple fasts sums them; still-active fasts are excluded (no end).
Future<List<TrendPoint>> _fetchFastingHoursSeries(
  Ref ref,
  String userId,
  TrendRange range,
) async {
  final repo = ref.read(fastingRepositoryProvider);
  final now = DateTime.now();
  final start = range.startDate() ??
      DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1825));
  final startStr = start.toIso8601String().split('T').first;
  final endStr = now.toIso8601String().split('T').first;
  try {
    final records = await repo.getFastingHistory(
      userId: userId,
      limit: 1000,
      fromDate: startStr,
      toDate: endStr,
    );
    final perDay = <DateTime, double>{};
    for (final r in records) {
      final end = r.endTime;
      if (end == null) continue; // active fast → no completed duration yet
      final hours = end.difference(r.startTime).inMinutes / 60.0;
      if (hours <= 0) continue;
      final day =
          DateTime(r.startTime.year, r.startTime.month, r.startTime.day);
      perDay[day] = (perDay[day] ?? 0) + hours;
    }
    final out = [
      for (final e in perDay.entries)
        TrendPoint(date: e.key, value: e.value),
    ];
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  } catch (e) {
    debugPrint('⚠️ [Trends] fasting-hours series unavailable: $e');
    return const [];
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Wave 1 source adapter — micros / cardio / glucose / feedback / hormonal /
// flexibility / habits / wellbeing / neat
// ───────────────────────────────────────────────────────────────────────────

/// Ordinal mapping for the cycle `period_flow` enum so it can be charted as a
/// 0–4 numeric series. Any other string ⇒ skipped (no data point).
const Map<String, double> _kPeriodFlowOrdinal = {
  'none': 0,
  'spotting': 1,
  'light': 2,
  'medium': 3,
  'moderate': 3,
  'heavy': 4,
};

/// Parses one numeric value from a `daily_series` row field. Handles plain
/// numbers and — for `period_flow` — the textual flow enum. Returns null for
/// genuinely-missing / non-numeric fields so they are simply absent (never
/// fabricated as 0).
double? _seriesValue(Map<String, dynamic> row, String field) {
  final raw = row[field];
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    if (field == 'period_flow') {
      return _kPeriodFlowOrdinal[raw.trim().toLowerCase()];
    }
    return double.tryParse(raw.trim());
  }
  return null;
}

/// Generic Wave 1 series adapter. Resolves the right [TrendsRepository] call
/// for the metric's [TrendSource], then projects the metric's [seriesField]
/// from every dated row. VO₂ max and A1c live in companion series of their
/// parent payloads (`vo2_series` / `a1c_series`).
Future<List<TrendPoint>> _fetchWaveOneSeries(
  Ref ref,
  String userId,
  TrendMetric metric,
  TrendRange range,
) async {
  final field = metric.seriesField;
  if (field == null) return const [];
  final repo = ref.read(trendsRepositoryProvider);
  final days = range.days; // 0 ⇒ all history (backend honours it)

  List<Map<String, dynamic>>? rows;
  switch (metric.source) {
    case TrendSource.micros:
      rows = await repo.getMicrosSummary(userId, days: days);
      break;
    case TrendSource.cardio:
      final multi = await repo.getCardioTrends(userId, days: days);
      // VO₂ max ships in its own companion series.
      final cardioKey =
          metric == TrendMetric.vo2Max ? 'vo2_series' : 'daily_series';
      rows = multi == null ? null : multi[cardioKey];
      break;
    case TrendSource.glucose:
      final multi = await repo.getGlucoseTrends(userId, days: days);
      final glucoseKey =
          metric == TrendMetric.a1c ? 'a1c_series' : 'daily_series';
      rows = multi == null ? null : multi[glucoseKey];
      break;
    case TrendSource.workoutFeedback:
      rows = await repo.getFeedbackTrends(userId, days: days);
      break;
    case TrendSource.hormonal:
      rows = await repo.getHormonalTrends(userId, days: days);
      break;
    case TrendSource.flexibility:
      rows = await repo.getFlexibilityTrends(userId, days: days);
      break;
    case TrendSource.habits:
      rows = await repo.getHabitTrends(userId, days: days);
      break;
    case TrendSource.wellbeing:
      rows = await repo.getWellbeingTrends(userId, days: days);
      break;
    case TrendSource.neat:
      rows = await repo.getNeatTrends(userId, days: days);
      break;
    // Non-Wave-1 sources never reach here.
    case TrendSource.measurement:
    case TrendSource.derivedMetric:
    case TrendSource.workoutVolume:
    case TrendSource.nutrition:
    case TrendSource.activity:
    case TrendSource.hydration:
    case TrendSource.readiness:
    case TrendSource.strength:
    case TrendSource.pillarHistory:
    case TrendSource.cardioMetricSnapshot:
      return const [];
  }

  // null ⇒ endpoint errored; honest empty series. An empty list ⇒ no logs.
  if (rows == null) return const [];

  final out = <TrendPoint>[];
  for (final row in rows) {
    final dateStr = row['date'] as String?;
    final date = dateStr == null ? null : DateTime.tryParse(dateStr);
    if (date == null) continue;
    final value = _seriesValue(row, field);
    if (value == null) continue; // genuinely-missing field → no point
    out.add(TrendPoint(date: date, value: value));
  }
  return out;
}

// ───────────────────────────────────────────────────────────────────────────
// Event overlays
// ───────────────────────────────────────────────────────────────────────────

/// A toggleable category of day-level events drawn as background bands.
enum TrendEventKind {
  workout('Workouts'),
  fasting('Fasting'),
  rest('Rest days'),
  weighIn('Weigh-ins'),
  pr('PR days'),
  overTarget('Over-target'),
  lowSleep('Low sleep'),
  period('Period');

  const TrendEventKind(this.label);

  final String label;
}

/// All event days for the active range, grouped by kind. Each value is the
/// set of calendar days (date-only, local) the event occurred on.
class TrendEvents {
  final Map<TrendEventKind, Set<DateTime>> days;

  const TrendEvents(this.days);

  Set<DateTime> of(TrendEventKind kind) => days[kind] ?? const {};

  bool get isEmpty => days.values.every((s) => s.isEmpty);

  int count(TrendEventKind kind) => of(kind).length;
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Nights under this many hours of sleep count as a "low-sleep" day.
const double _kLowSleepHours = 6.0;

/// Real event-overlay data for the chart background.
///
/// Sources, all real — no fabrication:
///  * Workouts / Rest days → `consistency/calendar` heatmap statuses.
///  * Fasting days        → `fasting/history` records (any fast that touched
///                          the day counts).
///  * Weigh-in days       → `measurements` history — days a body-weight
///                          measurement was logged.
///  * PR days             → `scores/personal-records` — days a personal
///                          record was achieved.
///  * Over-target days    → `nutrition macros-summary` — days logged calories
///                          exceeded the user's calorie goal.
///  * Low-sleep days      → `activity/history` — nights under ~6h sleep.
final trendEventsProvider = FutureProvider.family
    .autoDispose<TrendEvents, TrendRange>((ref, range) async {
  final auth = ref.watch(authStateProvider);
  final userId = auth.user?.id;
  if (userId == null) return const TrendEvents({});

  final now = DateTime.now();
  final start = range.startDate() ??
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365));
  final startStr = start.toIso8601String().split('T').first;
  final endStr = now.toIso8601String().split('T').first;

  final workoutDays = <DateTime>{};
  final restDays = <DateTime>{};
  final fastingDays = <DateTime>{};
  final weighInDays = <DateTime>{};
  final prDays = <DateTime>{};
  final overTargetDays = <DateTime>{};
  final lowSleepDays = <DateTime>{};
  final periodDays = <DateTime>{};

  // Workout + rest days from the consistency heatmap.
  try {
    final consistency = ref.read(consistencyRepositoryProvider);
    final heatmap = await consistency.getCalendarHeatmap(
      userId: userId,
      startDateStr: startStr,
      endDateStr: endStr,
    );
    for (final d in heatmap.data) {
      final day = DateTime.tryParse(d.date);
      if (day == null) continue;
      switch (d.statusEnum) {
        case CalendarStatus.completed:
          workoutDays.add(_dayOnly(day));
          break;
        case CalendarStatus.rest:
          restDays.add(_dayOnly(day));
          break;
        case CalendarStatus.missed:
        case CalendarStatus.future:
          break;
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] workout/rest events unavailable: $e');
  }

  // Fasting days from fasting history.
  try {
    final fasting = ref.read(fastingRepositoryProvider);
    final records = await fasting.getFastingHistory(
      userId: userId,
      limit: 200,
      fromDate: startStr,
      toDate: endStr,
    );
    for (final r in records) {
      // A fast spans from start to end (or now if active). Mark every local
      // calendar day it touched so a 16h overnight fast lights up both days.
      final from = _dayOnly(r.startTime);
      final to = _dayOnly(r.endTime ?? now);
      var cursor = from;
      var guard = 0;
      while (!cursor.isAfter(to) && guard < 400) {
        fastingDays.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
        guard++;
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] fasting events unavailable: $e');
  }

  // Weigh-in days from body-weight measurement history.
  try {
    final repo = ref.read(measurementsRepositoryProvider);
    final type = MeasurementType.fromApiValue('weight');
    if (type != null) {
      final history = await repo.getMeasurementHistory(userId, type,
          limit: 365);
      for (final e in history) {
        final d = _dayOnly(e.recordedAt);
        if (d.isBefore(start) || d.isAfter(now)) continue;
        weighInDays.add(d);
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] weigh-in events unavailable: $e');
  }

  // PR days from logged personal records.
  try {
    final repo = ref.read(scoresRepositoryProvider);
    final periodDays = range.days == 0 ? 1825 : range.days;
    final stats = await repo.getPersonalRecords(
      userId: userId,
      limit: 500,
      periodDays: periodDays,
    );
    for (final pr in stats.recentPrs) {
      final d = DateTime.tryParse(pr.achievedAt);
      if (d == null) continue;
      final day = _dayOnly(d);
      if (day.isBefore(start) || day.isAfter(now)) continue;
      prDays.add(day);
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] PR events unavailable: $e');
  }

  // Over-target days: logged calories exceeded the user's calorie goal. The
  // macros-summary endpoint returns both the per-day series AND the goal.
  try {
    final repo = ref.read(nutritionRepositoryProvider);
    final summary = await repo.getMacrosSummaryRange(userId, days: range.days);
    final goal = summary?.calorieGoal;
    if (summary != null && goal != null && goal > 0) {
      for (final day in summary.dailySeries) {
        if (day.calories <= goal) continue;
        final d = DateTime.tryParse(day.date);
        if (d == null) continue;
        overTargetDays.add(_dayOnly(d));
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] over-target events unavailable: $e');
  }

  // Low-sleep days from synced activity history.
  try {
    final service = ref.read(activityServiceProvider);
    final history = await service.getActivityHistory(
      userId,
      limit: 2000,
      fromDate: start,
      toDate: now,
    );
    for (final a in history) {
      final mins = a.sleepMinutes;
      if (mins == null || mins <= 0) continue;
      if (mins / 60.0 < _kLowSleepHours) {
        lowSleepDays.add(_dayOnly(a.date));
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] low-sleep events unavailable: $e');
  }

  // Period days from the hormonal-health cycle trends. A day counts as a
  // period day when its cycle phase is menstrual OR a non-'none' flow was
  // logged — real logged cycle data, never inferred.
  try {
    final repo = ref.read(trendsRepositoryProvider);
    final rows = await repo.getHormonalTrends(userId, days: range.days);
    if (rows != null) {
      for (final row in rows) {
        final phase =
            (row['cycle_phase'] as String?)?.trim().toLowerCase();
        final flow = (row['period_flow'] as String?)?.trim().toLowerCase();
        final isPeriod = phase == 'menstrual' ||
            (flow != null && flow.isNotEmpty && flow != 'none');
        if (!isPeriod) continue;
        final d = DateTime.tryParse(row['date'] as String? ?? '');
        if (d == null) continue;
        final day = _dayOnly(d);
        if (day.isBefore(start) || day.isAfter(now)) continue;
        periodDays.add(day);
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Trends] period events unavailable: $e');
  }

  return TrendEvents({
    TrendEventKind.workout: workoutDays,
    TrendEventKind.fasting: fastingDays,
    TrendEventKind.rest: restDays,
    TrendEventKind.weighIn: weighInDays,
    TrendEventKind.pr: prDays,
    TrendEventKind.overTarget: overTargetDays,
    TrendEventKind.lowSleep: lowSleepDays,
    TrendEventKind.period: periodDays,
  });
});

/// Cardio metric-snapshot series — reads `/trends/cardio-series?metric=<key>`
/// for one of the 13 Wave-2 derived cardio metrics. Every metric is a numeric
/// per-day series of `{date, value}`; missing days are simply absent (the chart
/// honours the gap rather than fabricating zeros).
Future<List<TrendPoint>> _fetchCardioSnapshotSeries(
  Ref ref,
  TrendMetric metric,
  TrendRange range,
) async {
  final key = metric.metricKey;
  if (key == null) return const [];
  final repo = ref.read(trendsRepositoryProvider);
  final rows = await repo.getCardioSnapshotSeries(
    metricKey: key,
    days: range.days,
  );
  if (rows == null) return const [];
  final out = <TrendPoint>[];
  for (final row in rows) {
    final dateStr = row['date'] as String?;
    final date = dateStr == null ? null : DateTime.tryParse(dateStr);
    if (date == null) continue;
    final raw = row['value'];
    double? v;
    if (raw is num) {
      v = raw.toDouble();
    } else if (raw is String) {
      v = double.tryParse(raw.trim());
    }
    if (v == null) continue;
    out.add(TrendPoint(date: date, value: v));
  }
  return out;
}

/// Pillar history series — recomputes past-day completion for one of the four
/// Today-Score pillars (Train / Nourish / Move / Sleep) by delegating to
/// [pillarHistoryProvider]. Returns 0-100 values (completion × 100) so the
/// chart reads on the same axis as Oura/Whoop pillar scores.
Future<List<TrendPoint>> _fetchPillarHistorySeries(
  Ref ref,
  TrendMetric metric,
  TrendRange range,
) async {
  // Map TrendMetric → PillarKind. Anything else is a programming error.
  final PillarKind kind;
  switch (metric.metricKey) {
    case 'train':
      kind = PillarKind.train;
      break;
    case 'nourish':
      kind = PillarKind.nourish;
      break;
    case 'move':
      kind = PillarKind.move;
      break;
    case 'sleep':
      kind = PillarKind.sleep;
      break;
    default:
      return const [];
  }
  final days = range.days == 0 ? 365 : range.days;
  final history = await ref.read(
    pillarHistoryProvider(PillarHistoryKey(kind: kind, days: days)).future,
  );
  return [
    for (final d in history)
      TrendPoint(date: d.date, value: (d.completion * 100).clamp(0, 100)),
  ];
}
