import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/services/data_cache_service.dart';
import '../../../widgets/liquid_glass_action_bar.dart';
import '../../../widgets/trends/trend_chart.dart';
import '../../../widgets/trends/trend_correlation.dart' show TrendPoint;
import '../../../data/models/food_patterns.dart';
import '../../../data/providers/food_patterns_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';
import 'package:go_router/go_router.dart';
import '../log_meal_sheet.dart';
import 'gut_health_card.dart';

import '../../../l10n/generated/app_localizations.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Disk-cache helper for the four blocking Patterns sections
// ─────────────────────────────────────────────────────────────────────────────
//
// The Patterns tab's section providers are plain `FutureProvider.autoDispose`
// families (owned by other work — we may NOT rewire them onto CacheFirstMixin).
// To still get the instant-load contract we apply the cache-first pattern at
// the *widget* layer:
//
//   1. On first build a section reads its last-known payload from
//      `DataCacheService` (SharedPreferences) — synchronously-fast — and shows
//      it instantly while the provider's network fetch runs in the background.
//   2. Whenever the provider yields fresh data the section write-throughs that
//      payload to disk so the next cold start is instant too.
//   3. Only a TRUE cold install (no cache + provider still loading) ever sees a
//      placeholder — and that placeholder is a layout-matched skeleton, never a
//      blocking spinner.
//
// Each of the four section payloads gets its own SharedPreferences slot, keyed
// by user + range + anchor date so a value cached for "this week" is never
// shown for "last month". The slots live under the `cache_nutrition_patterns_*`
// prefix; `DataCacheService` applies its 1-hour default TTL (these keys are not
// in its per-key TTL override map). A stale-but-instant render followed by a
// silent provider refresh is the right trade-off for slow-moving aggregates.

/// Base cache keys for the four Patterns sections. The range/date facet is
/// appended by [_patternsCacheKey] so each (range, date) bucket is isolated.
const String _kMacrosCacheKey = 'cache_nutrition_patterns_macros';
const String _kTopFoodsCacheKey = 'cache_nutrition_patterns_topfoods';
const String _kMoodCacheKey = 'cache_nutrition_patterns_mood';
// Disk-cache slots for the deepened Patterns sections (Phase 4B/4C — FE-D).
const String _kSymptomTagCacheKey = 'cache_nutrition_patterns_symptomtag';
const String _kGentleCacheKey = 'cache_nutrition_patterns_gentle';
const String _kGutCacheKey = 'cache_nutrition_patterns_gut';

/// Build a fully-faceted cache key. The range + date (+ optional metric) are
/// folded into the key so switching the sticky range picker never shows the
/// wrong bucket's cached payload.
String _patternsCacheKey(String base, {String? range, String? date, String? metric}) {
  final buf = StringBuffer(base);
  if (range != null) buf.write('_$range');
  if (date != null) buf.write('_$date');
  if (metric != null) buf.write('_$metric');
  return buf.toString();
}

/// Read a single-object section payload from disk. Returns null on miss /
/// expiry / decode failure — callers treat that as "no cache, show skeleton".
Future<T?> _readPatternsCache<T>(
  String key,
  String userId,
  T Function(Map<String, dynamic>) decode,
) async {
  try {
    final raw = await DataCacheService.instance.getCached(key, userId: userId);
    if (raw == null) return null;
    return decode(raw);
  } catch (e) {
    debugPrint('💾 [Patterns] cache read failed for $key: $e');
    return null;
  }
}

/// Write-through a single-object section payload. Best-effort — a failed write
/// only costs the next cold start its instant render.
Future<void> _writePatternsCache(
  String key,
  String userId,
  Map<String, dynamic> json,
) async {
  try {
    await DataCacheService.instance.cache(key, json, userId: userId);
  } catch (e) {
    debugPrint('💾 [Patterns] cache write failed for $key: $e');
  }
}

/// Full Nutrition > Patterns tab: four stacked sections + a sticky range
/// picker. Built on the food_patterns_provider family so each section fires
/// its own query and renders independently.
class NutritionPatternsTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const NutritionPatternsTab({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<NutritionPatternsTab> createState() =>
      _NutritionPatternsTabState();
}

class _NutritionPatternsTabState extends ConsumerState<NutritionPatternsTab>
    with AutomaticKeepAliveClientMixin {
  String _range = 'week';
  DateTime _anchor = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  String get _anchorDateStr => DateFormat('yyyy-MM-dd').format(_anchor);

  void _setRange(String r) {
    HapticService.light();
    setState(() => _range = r);
  }

  void _stepAnchor(int direction) {
    HapticService.light();
    setState(() {
      switch (_range) {
        case 'day':
          _anchor = _anchor.add(Duration(days: direction));
        case 'week':
          _anchor = _anchor.add(Duration(days: 7 * direction));
        case 'month':
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
        default:
          break; // 90d: no stepping
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    final userId = widget.userId;
    if (userId.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).nutritionPatternsSignInToSee,
            style: TextStyle(color: textMuted)),
      );
    }

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _RangeHeaderDelegate(
              isDark: widget.isDark,
              range: _range,
              anchor: _anchor,
              onRangeChanged: _setRange,
              onStep: _stepAnchor,
            ),
          ),
          SliverToBoxAdapter(
            child: _MacroChartsSection(
              userId: userId,
              range: _range,
              date: _anchorDateStr,
              isDark: widget.isDark,
            ),
          ),
          // ── Differentiated insight first ──────────────────────────────────
          // The correlation / gut / gentle-change sections are what makes this
          // tab more than a calorie donut, so they sit directly under the
          // overview — not buried below Top Foods where users never scroll.
          //
          // Per-symptom + per-tag correlation buckets (image-first). "How foods
          // sat with you" — structured how-you-felt signal.
          SliverToBoxAdapter(
            child: _SymptomTagSection(
              userId: userId,
              isDark: widget.isDark,
            ),
          ),
          // Gut-health insights — regularity chart + natural-rhythm stats +
          // food/tag → gut correlations. Cozy, non-clinical.
          SliverToBoxAdapter(
            child: _GutHealthSection(
              userId: userId,
              isDark: widget.isDark,
            ),
          ),
          // "Gentle changes" — fiber/protein/veggies/consistency vs goals,
          // each with a sparkline + baseline delta. Encouraging, non-judgmental.
          SliverToBoxAdapter(
            child: _GentleChangesSection(
              userId: userId,
              isDark: widget.isDark,
            ),
          ),
          // "Ask about your food" — natural-language entry into the nutrition
          // coach (Phase 2E wires the patterns engine into the coach prompt).
          SliverToBoxAdapter(
            child: _AskAboutFoodCard(isDark: widget.isDark),
          ),
          SliverToBoxAdapter(
            child: _TopFoodsSection(
              userId: userId,
              range: _range,
              date: _anchorDateStr,
              isDark: widget.isDark,
            ),
          ),
          SliverToBoxAdapter(
            child: _MoodSection(
              userId: userId,
              isDark: widget.isDark,
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsRow(
              userId: userId,
              isDark: widget.isDark,
              surface: surface,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
          // Clearance for the floating tab bar + MainShell nav stacked below.
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom +
                  76 +
                  kLiquidGlassActionBarHeight +
                  16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Range Header ─────────────────────────────────────────────────────

class _RangeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final String range;
  final DateTime anchor;
  final void Function(String) onRangeChanged;
  final void Function(int) onStep;

  _RangeHeaderDelegate({
    required this.isDark,
    required this.range,
    required this.anchor,
    required this.onRangeChanged,
    required this.onStep,
  });

  // Extent sized snug to the content so the segmented control sits directly
  // under the date strip (a larger extent centered the ~78px content and left
  // a visible gap above it):
  //   outer padding 8+8 = 16
  //   pill row (~38 at normal scale)
  //   gap 6
  //   arrow row 28
  //   ≈ 88, rounded to 90.
  // The inner Column is wrapped in a FittedBox(scaleDown) (see build), so at
  // extreme accessibility text scales the content scales down to fit 90
  // instead of throwing a RenderFlex overflow — that guard is what makes a
  // tight extent safe.
  @override
  double get minExtent => 90;
  @override
  double get maxExtent => 90;

  @override
  bool shouldRebuild(covariant _RangeHeaderDelegate old) =>
      old.range != range || old.anchor != anchor || old.isDark != isDark;

  String _anchorLabel() {
    switch (range) {
      case 'day':
        return DateFormat('EEE, MMM d').format(anchor);
      case 'week':
        final weekday = anchor.weekday;
        final start = anchor.subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
      case 'month':
        return DateFormat('MMMM yyyy').format(anchor);
      default:
        return 'Last 90 days';
    }
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    Widget pill(String label, String value) {
      final selected = range == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onRangeChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: AppColors.cyan.withValues(alpha: 0.3))
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? textPrimary : textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final availableWidth = MediaQuery.of(context).size.width - 32; // minus horizontal padding
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      alignment: Alignment.center,
      // FittedBox + fixed-width SizedBox guarantees the content never throws
      // a RenderFlex overflow: on normal text scales nothing scales (fits
      // naturally inside 104 - 16 = 88px); on extreme accessibility scales
      // the whole header scales down to fit.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: SizedBox(
          width: availableWidth,
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              pill('Day', 'day'),
              pill('Week', 'week'),
              pill('Month', 'month'),
              pill('90d', '90d'),
            ]),
          ),
          const SizedBox(height: 6),
          // Use InkResponse instead of IconButton — IconButton enforces a
          // 48dp tap target that blows past our 88dp sticky-header extent
          // even when constraints/padding are set, causing a ~23px bottom
          // overflow. InkResponse respects the wrapping SizedBox exactly.
          Row(children: [
            if (range != '90d')
              SizedBox(
                width: 28,
                height: 28,
                child: InkResponse(
                  onTap: () => onStep(-1),
                  radius: 18,
                  child: Icon(Icons.chevron_left, color: textMuted, size: 20),
                ),
              )
            else
              const SizedBox(width: 28),
            Expanded(
              child: Text(
                _anchorLabel(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            if (range != '90d')
              SizedBox(
                width: 28,
                height: 28,
                child: InkResponse(
                  onTap: () => onStep(1),
                  radius: 18,
                  child: Icon(Icons.chevron_right, color: textMuted, size: 20),
                ),
              )
            else
              const SizedBox(width: 28),
          ]),
        ],
          ),
        ),
      ),
    );
  }
}

// ── Section 1: Macro / calorie trends ───────────────────────────────────────

class _MacroChartsSection extends ConsumerStatefulWidget {
  final String userId;
  final String range;
  final String date;
  final bool isDark;

  const _MacroChartsSection({
    required this.userId,
    required this.range,
    required this.date,
    required this.isDark,
  });

  @override
  ConsumerState<_MacroChartsSection> createState() =>
      _MacroChartsSectionState();
}

class _MacroChartsSectionState extends ConsumerState<_MacroChartsSection> {
  /// Last-known payload read from disk — rendered instantly on cold start while
  /// the provider's network fetch is still in flight.
  MacrosSummaryResponse? _cached;

  /// True until the very first disk read completes. While true (and the
  /// provider has no data yet) the section shows its layout-matched skeleton.
  bool _cacheChecked = false;

  /// The (range, date) the current `_cached` value belongs to — guards against
  /// showing a stale bucket after the sticky range picker changes.
  String? _cachedKey;

  String get _key => _patternsCacheKey(_kMacrosCacheKey,
      range: widget.range, date: widget.date);

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  @override
  void didUpdateWidget(covariant _MacroChartsSection old) {
    super.didUpdateWidget(old);
    // Range / anchor changed → the old cached bucket is no longer valid.
    if (old.range != widget.range || old.date != widget.date) {
      _cached = null;
      _cacheChecked = false;
      _loadCache();
    }
  }

  Future<void> _loadCache() async {
    final key = _key;
    final v = await _readPatternsCache(
        key, widget.userId, MacrosSummaryResponse.fromJson);
    if (!mounted) return;
    setState(() {
      // Only adopt the cached value if the range/date hasn't changed mid-read.
      if (key == _key) {
        _cached = v;
        _cachedKey = key;
      }
      _cacheChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(macrosSummaryProvider(
      MacrosQuery(userId: widget.userId, range: widget.range, date: widget.date),
    ));

    // Write-through whenever the provider yields fresh data for this bucket.
    final fresh = async.valueOrNull;
    if (fresh != null) {
      _writePatternsCache(_key, widget.userId, fresh.toJson());
    }

    // Cache-first resolution: prefer fresh network data, fall back to the
    // disk-cached payload (only if it belongs to the current bucket).
    final summary =
        fresh ?? (_cachedKey == _key ? _cached : null);

    return _SectionContainer(
      title: widget.range == 'day' ? AppLocalizations.of(context).nutritionPatternsTodaySMacros : AppLocalizations.of(context).nutritionPatternsNutritionTrends,
      isDark: widget.isDark,
      child: Builder(builder: (context) {
        if (summary != null) {
          if (summary.daysCounted == 0) {
            return _EmptyStub(
              icon: Icons.pie_chart_outline,
              title: AppLocalizations.of(context).nutritionPatternsNoMealsLogged,
              subtitle: AppLocalizations.of(context).nutritionPatternsLogAFewMeals,
            );
          }
          return Column(
            children: [
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(child: _MacroPie(summary: summary)),
                    Expanded(
                      child: _MacroLegend(
                          summary: summary, isDark: widget.isDark),
                    ),
                  ],
                ),
              ),
              if (widget.range != 'day') ...[
                const SizedBox(height: 16),
                _CalorieTrend(summary: summary, isDark: widget.isDark),
              ],
            ],
          );
        }
        // No data anywhere yet. Surface a hard error only once the disk read
        // has finished AND the network has failed (so a transient error never
        // blanks a section that still has a cached value to show).
        if (_cacheChecked && async.hasError) {
          return _ErrorStub(message: 'Couldn\'t load macros');
        }
        // Cold start — layout-matched skeleton (pie + legend rows).
        return const _MacroSkeleton();
      }),
    );
  }
}

/// Layout-matched skeleton for [_MacroChartsSection] — a circular pie
/// placeholder beside a stacked-line legend, sized to the real 180px row so
/// the skeleton → content swap never reflows.
class _MacroSkeleton extends StatelessWidget {
  const _MacroSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          // Pie chart placeholder — a centered shimmering circle.
          const Expanded(
            child: Center(child: SkeletonCircle(size: 120)),
          ),
          // Legend placeholder — title line + 4 short metric rows.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 110, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 70, height: 11),
                  SizedBox(height: 14),
                  SkeletonBox(width: 130, height: 12),
                  SizedBox(height: 10),
                  SkeletonBox(width: 130, height: 12),
                  SizedBox(height: 10),
                  SkeletonBox(width: 130, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPie extends StatelessWidget {
  final MacrosSummaryResponse summary;
  const _MacroPie({required this.summary});

  @override
  Widget build(BuildContext context) {
    final p = summary.avgProteinG * 4;
    final c = summary.avgCarbsG * 4;
    final f = summary.avgFatG * 9;
    final total = (p + c + f).clamp(1, double.infinity);
    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: p,
        color: AppColors.orange,
        title: '${((p / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      PieChartSectionData(
        value: c,
        color: AppColors.cyan,
        title: '${((c / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      PieChartSectionData(
        value: f,
        color: AppColors.purple,
        title: '${((f / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    ];
    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 28,
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final MacrosSummaryResponse summary;
  final bool isDark;
  const _MacroLegend({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    Widget row(String label, Color color, double grams, int? goal) {
      final pct = goal != null && goal > 0
          ? (grams / goal * 100).clamp(0, 200).round()
          : null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
            Text(
              goal != null ? '${grams.toStringAsFixed(0)}g · $pct%' : '${grams.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary.avgCalories} kcal/day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 4),
          if (summary.calorieGoal != null)
            Text(
              'Goal: ${summary.calorieGoal} kcal',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          const SizedBox(height: 12),
          row('Protein', AppColors.orange, summary.avgProteinG, summary.proteinGoal),
          row('Carbs', AppColors.cyan, summary.avgCarbsG, summary.carbsGoal),
          row('Fat', AppColors.purple, summary.avgFatG, summary.fatGoal),
        ],
      ),
    );
  }
}

/// Calorie Trends — the daily calorie series rendered through the shared
/// [TrendChart] engine (Phase G5a) so it gets EWMA smoothing, a scrub
/// tooltip, pinch-zoom and consistent theming. The calorie goal, when set,
/// is drawn as a horizontal zone band.
class _CalorieTrend extends ConsumerWidget {
  final MacrosSummaryResponse summary;
  final bool isDark;
  const _CalorieTrend({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final colors = ref.colors(context);

    // Build TrendPoints from the daily macro series — skip days that fail to
    // parse a date rather than fabricating one.
    final trendPoints = <TrendPoint>[
      for (final p in summary.dailySeries)
        if (DateTime.tryParse(p.date) != null)
          TrendPoint(
            date: DateTime.parse(p.date),
            value: p.calories.toDouble(),
          ),
    ];

    if (trendPoints.length < 2) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(AppLocalizations.of(context).nutritionPatternsNeedMoreDaysOf,
              style: TextStyle(fontSize: 12, color: textMuted)),
        ),
      );
    }

    final goal = summary.calorieGoal;
    return TrendChart(
      accent: colors.accent,
      height: 180,
      primary: TrendChartSeries(
        label: AppLocalizations.of(context).nutritionPatternsCalorieTrends,
        unit: 'kcal',
        points: trendPoints,
        zoneBands: [
          if (goal != null && goal > 0)
            TrendZoneBand(
              value: goal.toDouble(),
              label: AppLocalizations.of(context).challengeCreateFieldGoal,
              color: colors.warning,
            ),
        ],
      ),
    );
  }
}

// ── Section 2: Top foods by nutrient ────────────────────────────────────────

const _METRICS = <MapEntry<String, String>>[
  MapEntry('calories', 'Calories'),
  MapEntry('protein', 'Protein'),
  MapEntry('carbs', 'Carbs'),
  MapEntry('fat', 'Fat'),
  MapEntry('fiber', 'Fiber'),
  MapEntry('sugar', 'Sugar'),
  MapEntry('sodium', 'Sodium'),
];

/// Per-metric accent color so the P/C/F/etc. chips are visually distinct and
/// match the rest of the app's macro color language (purple=protein,
/// cyan=carbs, orange=fat). Light and dark themes use the theme-appropriate
/// darker/brighter variants already defined in AppColors / AppColorsLight.
Color _metricColor(String key, bool isDark) {
  switch (key) {
    case 'protein':
      return isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    case 'carbs':
      return isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    case 'fat':
      return isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    case 'fiber':
      return AppColors.limeGreen;
    case 'sugar':
      return AppColors.pink;
    case 'sodium':
      return AppColors.info;
    case 'calories':
    default:
      return AppColors.cyan;
  }
}

class _TopFoodsSection extends ConsumerStatefulWidget {
  final String userId;
  final String range;
  final String date;
  final bool isDark;

  const _TopFoodsSection({
    required this.userId,
    required this.range,
    required this.date,
    required this.isDark,
  });

  @override
  ConsumerState<_TopFoodsSection> createState() => _TopFoodsSectionState();
}

class _TopFoodsSectionState extends ConsumerState<_TopFoodsSection> {
  String _metric = 'calories';

  /// Per-(metric,range,date) disk-cached payloads. Keyed by the full cache key
  /// so flipping the metric chip can rehydrate instantly from a previously
  /// seen bucket while the network re-fetch runs silently.
  final Map<String, TopFoodsResponse> _cache = {};

  /// True once the first disk read for the *current* key has finished.
  bool _cacheChecked = false;

  String get _key => _patternsCacheKey(_kTopFoodsCacheKey,
      range: widget.range, date: widget.date, metric: _metric);

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  @override
  void didUpdateWidget(covariant _TopFoodsSection old) {
    super.didUpdateWidget(old);
    if (old.range != widget.range || old.date != widget.date) {
      _cacheChecked = false;
      _loadCache();
    }
  }

  Future<void> _loadCache() async {
    final key = _key;
    final v = await _readPatternsCache(
        key, widget.userId, TopFoodsResponse.fromJson);
    if (!mounted) return;
    setState(() {
      if (v != null) _cache[key] = v;
      _cacheChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(topFoodsProvider(
      TopFoodsQuery(
        userId: widget.userId,
        metric: _metric,
        range: widget.range,
        date: widget.date,
      ),
    ));

    // Write-through fresh data for this (metric, range, date) bucket.
    final fresh = async.valueOrNull;
    if (fresh != null) {
      _cache[_key] = fresh;
      _writePatternsCache(_key, widget.userId, fresh.toJson());
    }
    // Cache-first: prefer fresh, fall back to a disk-cached bucket payload.
    final data = fresh ?? _cache[_key];

    return _SectionContainer(
      title: AppLocalizations.of(context).nutritionPatternsFoodsHighestIn,
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in _METRICS)
                  () {
                    final selected = _metric == m.key;
                    final mColor = _metricColor(m.key, widget.isDark);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m.value),
                        selected: selected,
                        onSelected: (_) {
                          HapticService.light();
                          setState(() => _metric = m.key);
                        },
                        selectedColor: mColor.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: selected
                              ? mColor.withValues(alpha: 0.55)
                              : (widget.isDark
                                  ? AppColors.cardBorder
                                  : AppColorsLight.cardBorder),
                        ),
                        checkmarkColor: mColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? mColor
                              : (widget.isDark
                                  ? AppColors.textSecondary
                                  : AppColorsLight.textSecondary),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            if (data != null) {
              if (data.items.isEmpty) {
                return _EmptyStub(
                  icon: Icons.restaurant_menu_outlined,
                  title: AppLocalizations.of(context).nutritionPatternsNoFoodsYet,
                  subtitle: 'Log meals to see your top ${_METRICS.firstWhere((e) => e.key == _metric).value.toLowerCase()} sources.',
                );
              }
              // Cap at 8 visible rows; the list is built lazily so off-screen
              // rows aren't constructed until needed.
              final visible = data.items.take(8).toList();
              final unit = data.items.first.unit;
              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => _TopFoodRow(
                      item: visible[i],
                      unit: unit,
                      isDark: widget.isDark,
                    ),
                  ),
                  if (data.items.length > 8)
                    TextButton(
                      onPressed: () {}, // Full-list screen tracked in follow-up
                      child: Text('View all ${data.items.length}'),
                    ),
                ],
              );
            }
            if (_cacheChecked && async.hasError) {
              return _ErrorStub(message: 'Couldn\'t load foods');
            }
            // Cold start — 5 layout-matched food-row skeletons.
            return const _TopFoodsSkeleton();
          }),
        ],
      ),
    );
  }
}

class _TopFoodRow extends StatelessWidget {
  final TopFoodEntry item;
  final String unit;
  final bool isDark;
  const _TopFoodRow({required this.item, required this.unit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final value = item.totalValue >= 10
        ? item.totalValue.toStringAsFixed(0)
        : item.totalValue.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              image: item.lastImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.lastImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.lastImageUrl == null
                ? Icon(Icons.restaurant, size: 18, color: textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(item.foodName),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.occurrences}× · last ${_relativeDate(item.lastLoggedAt)}',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          Text(
            '$value $unit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
          ),
        ],
      ),
    );
  }

  String _title(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _relativeDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays < 1) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}

/// Layout-matched skeleton for the top-foods list — 5 rows each mirroring a
/// [_TopFoodRow] (36px leading tile + two stacked text lines + trailing value).
class _TopFoodsSkeleton extends StatelessWidget {
  const _TopFoodsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (_) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: const [
              SkeletonBox(width: 36, height: 36, radius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 13),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 8),
              SkeletonBox(width: 44, height: 13),
            ],
          ),
        );
      }),
    );
  }
}

// ── Section 3: Mood / energy patterns ───────────────────────────────────────

class _MoodSection extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const _MoodSection({required this.userId, required this.isDark});

  @override
  ConsumerState<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends ConsumerState<_MoodSection> {
  /// Disk-cached mood payload — rendered instantly on cold start. The mood
  /// query is always a fixed 90-day window so a single per-user slot suffices.
  FoodPatternsMoodResponse? _cached;
  bool _cacheChecked = false;
  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final v = await _readPatternsCache(
        _kMoodCacheKey, widget.userId, FoodPatternsMoodResponse.fromJson);
    if (!mounted) return;
    setState(() {
      _cached = v;
      _cacheChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(foodPatternsMoodProvider(widget.userId));

    final fresh = async.valueOrNull;
    if (fresh != null) {
      _writePatternsCache(_kMoodCacheKey, widget.userId, fresh.toJson());
    }
    final data = fresh ?? _cached;
    final isDark = widget.isDark;

    return _SectionContainer(
      title: AppLocalizations.of(context).nutritionPatternsYourBodySResponses,
      subtitle: AppLocalizations.of(context).nutritionPatternsBasedOnTheLast,
      isDark: isDark,
      child: Builder(builder: (context) {
        if (data != null) {
          if (data.checkinDisabled) {
            return _CheckinDisabledBanner(
              userId: widget.userId,
              isDark: isDark,
              ref: ref,
            );
          }
          if (data.isEmpty) {
            return _EmptyStub(
              icon: Icons.insights_outlined,
              title: AppLocalizations.of(context).nutritionPatternsNoPatternsYet,
              subtitle: AppLocalizations.of(context).nutritionPatternsLog3MealsWith,
            );
          }
          return Column(
            children: [
              if (data.drainingFoods.isNotEmpty) ...[
                _MoodListHeader(
                  label: AppLocalizations.of(context).nutritionPatternsFoodsThatDragYou,
                  color: AppColors.orange,
                  isDark: isDark,
                ),
                for (final e in data.drainingFoods)
                  _MoodFoodTile(entry: e, negative: true, isDark: isDark),
                const SizedBox(height: 12),
              ],
              if (data.energizingFoods.isNotEmpty) ...[
                _MoodListHeader(
                  label: AppLocalizations.of(context).nutritionPatternsFoodsThatEnergizeYou,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                for (final e in data.energizingFoods)
                  _MoodFoodTile(entry: e, negative: false, isDark: isDark),
              ],
            ],
          );
        }
        if (_cacheChecked && async.hasError) {
          return _ErrorStub(message: 'Couldn\'t load patterns');
        }
        // Cold start — header line + 3 tile skeletons matching _MoodFoodTile.
        return const _MoodSkeleton();
      }),
    );
  }
}

/// Layout-matched skeleton for [_MoodSection] — a short list header followed by
/// three mood-food-tile placeholders (each: name line + detail line + trailing
/// trend icon), mirroring the real [_MoodFoodTile] geometry.
class _MoodSkeleton extends StatelessWidget {
  const _MoodSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget tile() => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130, height: 13),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 8),
              SkeletonBox(width: 20, height: 20, radius: 10),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, top: 4),
          child: SkeletonBox(width: 160, height: 13),
        ),
        tile(),
        tile(),
        tile(),
      ],
    );
  }
}

class _CheckinDisabledBanner extends StatelessWidget {
  final String userId;
  final bool isDark;
  final WidgetRef ref;
  const _CheckinDisabledBanner({
    required this.userId,
    required this.isDark,
    required this.ref,
  });

  Future<void> _reenable(BuildContext context) async {
    HapticService.medium();
    final repo = ref.read(nutritionRepositoryProvider);
    await repo.updatePatternsSettings(userId, postMealCheckinDisabled: false);
    ref.invalidate(foodPatternsMoodProvider(userId));
    ref.invalidate(patternsSettingsProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.orange),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).nutritionPatternsCheckInsAreOff,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).nutritionPatternsReEnableThePost,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _reenable(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(AppLocalizations.of(context).nutritionPatternsReEnable),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodListHeader extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _MoodListHeader({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Container(width: 4, height: 14, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
        ),
      ]),
    );
  }
}

class _MoodFoodTile extends ConsumerWidget {
  final FoodPatternEntry entry;
  final bool negative;
  final bool isDark;
  const _MoodFoodTile({
    required this.entry,
    required this.negative,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final ratioCount = negative ? entry.negativeMoodCount : entry.positiveMoodCount;
    final total = entry.logs;
    final symptom = entry.dominantSymptom ?? (negative ? 'off' : 'good');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      _title(entry.foodName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (entry.isMostlyInferred)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context).nutritionPatternsAiGuess,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '$symptom $ratioCount of $total · ${entry.avgEnergy?.toStringAsFixed(1) ?? '—'} avg energy',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          Icon(
            negative ? Icons.trending_down : Icons.trending_up,
            color: negative ? AppColors.orange : AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _title(String raw) =>
      raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
}


// ── Section 5: Settings row ─────────────────────────────────────────────────

class _SettingsRow extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  const _SettingsRow({
    required this.userId,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patternsSettingsProvider(userId));
    return _SectionContainer(
      title: AppLocalizations.of(context).nutritionPatternsCheckInInsights,
      isDark: isDark,
      child: async.when(
        loading: () => const _LoadingStub(height: 160),
        error: (e, _) => _ErrorStub(message: 'Couldn\'t load settings'),
        data: (s) => Column(children: [
          _ToggleRow(
            title: AppLocalizations.of(context).nutritionPatternsPostMealCheckIn,
            subtitle: AppLocalizations.of(context).nutritionPatternsTheQuickHowDo,
            value: !s.postMealCheckinDisabled,
            onChanged: (v) async {
              await ref.read(nutritionRepositoryProvider)
                  .updatePatternsSettings(userId, postMealCheckinDisabled: !v);
              ref.invalidate(patternsSettingsProvider(userId));
              ref.invalidate(foodPatternsMoodProvider(userId));
            },
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _ToggleRow(
            title: AppLocalizations.of(context).nutritionPatterns45MinReminderPush,
            subtitle: AppLocalizations.of(context).nutritionPatternsNudgeIfYouSkip,
            value: s.postMealReminderEnabled,
            onChanged: (v) async {
              await ref.read(nutritionRepositoryProvider)
                  .updatePatternsSettings(userId, postMealReminderEnabled: v);
              ref.invalidate(patternsSettingsProvider(userId));
            },
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _ToggleRow(
            title: AppLocalizations.of(context).nutritionPatternsAiMoodGuesses,
            subtitle: AppLocalizations.of(context).nutritionPatternsAutoInferMoodFrom,
            value: s.passiveInferenceEnabled,
            onChanged: (v) async {
              await ref.read(nutritionRepositoryProvider)
                  .updatePatternsSettings(userId, passiveInferenceEnabled: v);
              ref.invalidate(patternsSettingsProvider(userId));
              ref.invalidate(foodPatternsMoodProvider(userId));
            },
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  final Color textMuted;
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted, height: 1.3)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.cyan),
        ],
      ),
    );
  }
}

// ── Shared bits ─────────────────────────────────────────────────────────────

class _SectionContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  final Widget child;
  const _SectionContainer({
    required this.title,
    this.subtitle,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: textMuted)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingStub extends StatelessWidget {
  final double height;
  const _LoadingStub({required this.height});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorStub extends StatelessWidget {
  final String message;
  const _ErrorStub({required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 12)),
    );
  }
}

class _EmptyStub extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyStub({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 32, color: textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Rich, ALWAYS-VISIBLE teaser shown inside a deepened-Patterns section when the
/// user hasn't captured the signal it needs yet. We deliberately never silently
/// hide these sections (the old behaviour) — that made the whole "deeper
/// patterns" capability invisible to anyone who hadn't already been tagging
/// meals. Instead we teach what the section will reveal and give a one-tap CTA
/// straight into the capture flow.
class _PatternsTeaser extends StatelessWidget {
  final IconData icon;
  final String headline;
  final List<String> bullets;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onCta;
  final bool isDark;
  const _PatternsTeaser({
    required this.icon,
    required this.headline,
    required this.bullets,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.onCta,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tc.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tc.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                headline,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 14, color: tc.accent.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(b,
                      style: TextStyle(
                          fontSize: 11.5, height: 1.35, color: textMuted)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: tc.accent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticService.light();
                onCta();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ctaIcon, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(ctaLabel,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Deepened Patterns (Phase 4B/4C — FE-D)
// ═══════════════════════════════════════════════════════════════════════════
//
// Three new analytical sections + an "ask your food" entry. All follow the
// established widget-layer disk-cache-first pattern (cache read on init →
// instant render → silent provider refresh → write-through). Every section
// fails open: a missing/unmigrated backend field degrades to a gentle empty
// state, never a blanked tab or a thrown error. Copy uses ≥4-variant pools
// keyed off real data so the prose never reads robotic, and is non-judgmental
// throughout (the "no calorie-shaming" principle).

// ── Copy variant pools ──────────────────────────────────────────────────────
// Picked deterministically off a stable seed (a food name / goal key) so the
// same row always reads the same line within a render, but the set as a whole
// feels hand-written rather than templated.

String _pick(List<String> pool, String seed) {
  if (pool.isEmpty) return '';
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return pool[h % pool.length];
}

// ── "Ask about your food" card ──────────────────────────────────────────────

/// Natural-language entry into the nutrition coach. The coach prompt is wired
/// to the patterns engine (Phase 2E) so questions like "why do I feel bloated
/// after healthy meals?" get a meal-aware answer. Deep-links to `/chat` with a
/// prefilled prompt + a source tag so the coach knows it came from Patterns.
class _AskAboutFoodCard extends StatelessWidget {
  final bool isDark;
  const _AskAboutFoodCard({required this.isDark});

  static const _prompts = <String>[
    'Why do I feel bloated after some meals?',
    'Which foods give me the most energy?',
    'What should I eat more of this week?',
    'Are my eating patterns helping my goals?',
  ];

  void _ask(BuildContext context, String prompt) {
    HapticService.light();
    final encoded = Uri.encodeComponent(prompt);
    context.push('/chat?source=nutrition_patterns&prompt=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ZealovaCard(
        variant: ZealovaCardVariant.hero,
        onTap: () => _ask(context, 'Tell me about my eating patterns.'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: tc.accent),
                const SizedBox(width: 8),
                Text('ASK ABOUT YOUR FOOD',
                    style: ZType.lbl(12, color: tc.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your coach can see these patterns. Ask anything.',
              style: ZType.ser(14, color: tc.textMuted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _prompts)
                  _AskChip(label: p, onTap: () => _ask(context, p)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AskChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AskChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: ZType.ser(12.5, color: tc.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.north_east, size: 12, color: tc.accent),
          ],
        ),
      ),
    );
  }
}

// ── Section: Symptom / tag correlation buckets ──────────────────────────────

class _SymptomTagSection extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const _SymptomTagSection({required this.userId, required this.isDark});

  @override
  ConsumerState<_SymptomTagSection> createState() => _SymptomTagSectionState();
}

class _SymptomTagSectionState extends ConsumerState<_SymptomTagSection> {
  SymptomTagCorrelations? _cached;
  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final v = await _readPatternsCache(
        _kSymptomTagCacheKey, widget.userId, SymptomTagCorrelations.fromJson);
    if (!mounted) return;
    setState(() => _cached = v);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(symptomTagCorrelationsProvider(widget.userId));
    final fresh = async.valueOrNull;
    // Note: this typed model has no toJson; we persist a compact re-encodable
    // shape so the next cold start is instant. (Buckets keep only what the UI
    // renders.) See _encodeSymptomTag.
    if (fresh != null) {
      _writePatternsCache(
          _kSymptomTagCacheKey, widget.userId, _encodeSymptomTag(fresh));
    }
    final data = fresh ?? _cached;
    final isDark = widget.isDark;

    // Always render the section so the capability is discoverable — when
    // there's no signal yet we teach + drive capture instead of vanishing.
    return _SectionContainer(
      title: 'How foods sat with you',
      subtitle: 'Grouped by how you felt and what you tagged',
      isDark: isDark,
      child: Builder(builder: (context) {
        if (data != null && !data.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in data.symptomBuckets)
                _CorrelationBucketCard(
                  bucket: b,
                  isSymptom: true,
                  isDark: isDark,
                ),
              for (final b in data.tagBuckets)
                _CorrelationBucketCard(
                  bucket: b,
                  isSymptom: false,
                  isDark: isDark,
                ),
            ],
          );
        }
        // First load with no cached payload → skeleton.
        if (data == null && async.isLoading) {
          return const _CorrelationSkeleton();
        }
        // Empty signal (or an unmigrated/failed fetch) → teach + capture CTA.
        return _PatternsTeaser(
          icon: Icons.insights_outlined,
          headline:
              'See which foods your body keeps reacting to — bloating, energy, focus and more.',
          bullets: const [
            'Tag a meal and note how it felt afterwards',
            'We surface the foods linked to each feeling',
            'Patterns sharpen after a handful of tagged meals',
          ],
          ctaLabel: 'Log a meal',
          ctaIcon: Icons.restaurant_outlined,
          onCta: () => showLogMealSheet(context, ref, autoOpenCamera: true),
          isDark: isDark,
        );
      }),
    );
  }
}

/// Persist only the fields the UI renders so the cached blob is small and
/// re-decodable by [SymptomTagCorrelations.fromJson].
Map<String, dynamic> _encodeSymptomTag(SymptomTagCorrelations c) {
  Map<String, dynamic> bucket(SymptomBucket b) => {
        'key': b.key,
        'label': b.label,
        'count': b.count,
        'confidence_pct': b.confidencePct,
        'foods': [
          for (final f in b.foods)
            {
              'food_name': f.name,
              'image_url': f.imageUrl,
              'occurrences': f.occurrences,
              'last_logged_at': f.lastLoggedAt,
            }
        ],
      };
  return {
    'symptom_buckets': [for (final b in c.symptomBuckets) bucket(b)],
    'tag_buckets': [for (final b in c.tagBuckets) bucket(b)],
    'days_window': c.daysWindow,
    'total_logs_analyzed': c.totalLogs,
  };
}

class _CorrelationBucketCard extends StatelessWidget {
  final SymptomBucket bucket;
  final bool isSymptom;
  final bool isDark;
  const _CorrelationBucketCard({
    required this.bucket,
    required this.isSymptom,
    required this.isDark,
  });

  // ── Non-judgmental header copy ──
  static const _beforeSymptom = <String>[
    'Often before you felt {x}',
    'Showed up when you felt {x}',
    'In the mix on your {x} days',
    'Around the times you felt {x}',
  ];
  static const _tagged = <String>[
    'Your {x} meals',
    'When you tagged {x}',
    'Tagged {x}',
    'Your {x}-tagged foods',
  ];

  String _header() {
    final pool = isSymptom ? _beforeSymptom : _tagged;
    return _pick(pool, bucket.key).replaceAll('{x}', bucket.label.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _header(),
                  style: ZType.lbl(12.5, color: textPrimary),
                ),
              ),
              if (bucket.confidencePct > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tc.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${bucket.confidencePct}% match',
                    style: ZType.lbl(9.5, color: tc.accent, letterSpacing: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Image-first: a horizontal rail of the actual food photos.
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bucket.foods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _CorrelatedFoodTile(
                food: bucket.foods[i],
                isDark: isDark,
              ),
            ),
          ),
          if (bucket.count > 0) ...[
            const SizedBox(height: 6),
            Text(
              _pick(const [
                'Seen across {n} meals',
                'From {n} logged meals',
                'Based on {n} meals',
                '{n} meals in this pattern',
              ], bucket.key).replaceAll('{n}', '${bucket.count}'),
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _CorrelatedFoodTile extends StatelessWidget {
  final CorrelatedFood food;
  final bool isDark;
  const _CorrelatedFoodTile({required this.food, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              image: food.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(food.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: food.imageUrl == null
                ? Icon(Icons.restaurant, size: 22, color: textMuted)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            food.name.isEmpty
                ? 'Meal'
                : food.name[0].toUpperCase() + food.name.substring(1),
            style: TextStyle(
                fontSize: 10.5, color: textPrimary, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (food.occurrences > 0)
            Text('${food.occurrences}×',
                style: TextStyle(fontSize: 9.5, color: textMuted)),
        ],
      ),
    );
  }
}

class _CorrelationSkeleton extends StatelessWidget {
  const _CorrelationSkeleton();
  @override
  Widget build(BuildContext context) {
    Widget block() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 13),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, __) =>
                    const SkeletonBox(width: 80, height: 64, radius: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
    return Column(children: [block(), block()]);
  }
}

// ── Section: "Gentle changes" goal cards ────────────────────────────────────

class _GentleChangesSection extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const _GentleChangesSection({required this.userId, required this.isDark});

  @override
  ConsumerState<_GentleChangesSection> createState() =>
      _GentleChangesSectionState();
}

class _GentleChangesSectionState
    extends ConsumerState<_GentleChangesSection> {
  MacrosBaseline? _cached;
  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final v = await _readPatternsCache(
        _kGentleCacheKey, widget.userId, MacrosBaseline.fromJson);
    if (!mounted) return;
    setState(() => _cached = v);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(macrosBaselineProvider(widget.userId));
    final fresh = async.valueOrNull;
    if (fresh != null) {
      _writePatternsCache(_kGentleCacheKey, widget.userId, _encodeBaseline(fresh));
    }
    final data = fresh ?? _cached;
    final isDark = widget.isDark;

    return _SectionContainer(
      title: 'Gentle changes',
      subtitle: 'Small nudges toward how you want to eat',
      isDark: isDark,
      child: Builder(builder: (context) {
        if (data != null && data.goals.isNotEmpty) {
          return Column(
            children: [
              for (final g in data.goals)
                _GentleGoalCard(goal: g, isDark: isDark),
              if (data.nutrientTracks.isNotEmpty) ...[
                const SizedBox(height: 8),
                _BaselineTrendsBlock(
                  tracks: data.nutrientTracks,
                  currentLabel: data.currentLabel,
                  baselineLabel: data.baselineLabel,
                  isDark: isDark,
                ),
              ],
            ],
          );
        }
        // If only nutrient tracks came back (no explicit goals), still show
        // the bigger-picture baselines.
        if (data != null && data.nutrientTracks.isNotEmpty) {
          return _BaselineTrendsBlock(
            tracks: data.nutrientTracks,
            currentLabel: data.currentLabel,
            baselineLabel: data.baselineLabel,
            isDark: isDark,
          );
        }
        if (data == null && async.isLoading) {
          return const _GentleSkeleton();
        }
        return _PatternsTeaser(
          icon: Icons.eco_outlined,
          headline:
              'Gentle nudges toward how you want to eat — built from your own trends.',
          bullets: const [
            'Track fiber, protein, veggies and consistency',
            'Compare this period against your recent baseline',
            'Fills in as you log a few more days',
          ],
          ctaLabel: 'Log a meal',
          ctaIcon: Icons.restaurant_outlined,
          onCta: () => showLogMealSheet(context, ref, autoOpenCamera: true),
          isDark: isDark,
        );
      }),
    );
  }
}

Map<String, dynamic> _encodeBaseline(MacrosBaseline b) {
  Map<String, dynamic> goal(GentleGoal g) => {
        'key': g.key,
        'label': g.label,
        'current': g.current,
        'goal': g.goal,
        'baseline': g.baseline,
        'unit': g.unit,
        'series': g.series,
      };
  return {
    'goals': [for (final g in b.goals) goal(g)],
    'nutrient_tracks': [for (final g in b.nutrientTracks) goal(g)],
    'current_label': b.currentLabel,
    'baseline_label': b.baselineLabel,
  };
}

class _GentleGoalCard extends StatelessWidget {
  final GentleGoal goal;
  final bool isDark;
  const _GentleGoalCard({required this.goal, required this.isDark});

  // Encouraging, non-judgmental delta copy. Never "you failed" — always a
  // nudge or a celebration.
  static const _up = <String>[
    'trending up',
    'climbing',
    'nudging higher',
    'on the rise',
  ];
  static const _down = <String>[
    'a touch lower lately',
    'easing off',
    'dipping a little',
    'softer this stretch',
  ];
  static const _flat = <String>[
    'holding steady',
    'right where it was',
    'staying consistent',
    'level lately',
  ];

  String _deltaPhrase() {
    switch (goal.trend) {
      case 1:
        return _pick(_up, goal.key);
      case -1:
        return _pick(_down, goal.key);
      default:
        return _pick(_flat, goal.key);
    }
  }

  String _fmt(double v) =>
      v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = _goalColor(goal.key, isDark, tc);

    final goalVal = goal.goal;
    final progress = goal.progress;
    final summary = goalVal != null
        ? '${_fmt(goal.current)}${goal.unit} avg vs ${_fmt(goalVal)}${goal.unit} goal — ${_deltaPhrase()}'
        : '${_fmt(goal.current)}${goal.unit} avg — ${_deltaPhrase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(goal.label.toUpperCase(),
                        style: ZType.lbl(11.5, color: textPrimary)),
                    const SizedBox(width: 6),
                    Icon(
                      goal.trend == 1
                          ? Icons.trending_up
                          : goal.trend == -1
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 14,
                      color: goal.trend == -1 ? textMuted : accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(summary,
                    style: TextStyle(
                        fontSize: 11.5, color: textMuted, height: 1.35)),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (goal.series.length >= 2) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              height: 36,
              child: _Sparkline(values: goal.series, color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

Color _goalColor(String key, bool isDark, ThemeColors tc) {
  switch (key) {
    case 'protein':
      return isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    case 'carbs':
      return isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    case 'fat':
      return isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    case 'fiber':
    case 'veggies':
      return AppColors.limeGreen;
    default:
      return tc.accent;
  }
}

/// Lightweight fl_chart sparkline — no axes, no grid, just the trend curve.
class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i]),
    ];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.1 + 0.01;
    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bigger-picture trends — the 4wk-vs-9wk (current vs baseline) framing across
/// macros/nutrients, each a compact row with the delta + a sparkline.
class _BaselineTrendsBlock extends StatelessWidget {
  final List<GentleGoal> tracks;
  final String currentLabel;
  final String baselineLabel;
  final bool isDark;
  const _BaselineTrendsBlock({
    required this.tracks,
    required this.currentLabel,
    required this.baselineLabel,
    required this.isDark,
  });

  String _fmt(double v) =>
      v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final compare = (currentLabel.isNotEmpty && baselineLabel.isNotEmpty)
        ? '$currentLabel vs $baselineLabel'
        : 'Recent weeks vs before';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(children: [
            Container(width: 4, height: 14, color: tc.accent),
            const SizedBox(width: 8),
            Text('THE BIGGER PICTURE',
                style: ZType.lbl(12, color: textPrimary)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(compare,
              style: TextStyle(fontSize: 11, color: textMuted)),
        ),
        for (final t in tracks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.label,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        t.baseline != null
                            ? '${_fmt(t.current)}${t.unit} now · ${_fmt(t.baseline!)}${t.unit} before'
                            : '${_fmt(t.current)}${t.unit} now',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                if (t.delta != null)
                  _DeltaPill(delta: t.delta!, unit: t.unit, isDark: isDark),
                if (t.series.length >= 2) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    height: 30,
                    child: _Sparkline(
                        values: t.series,
                        color: _goalColor(t.key, isDark, tc)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double delta;
  final String unit;
  final bool isDark;
  const _DeltaPill({required this.delta, required this.unit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    final color = up ? AppColors.success : AppColors.warning;
    final v = delta.abs();
    final txt = '${up ? '+' : '−'}${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}$unit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(txt,
          style: ZType.data(10.5, color: color)),
    );
  }
}

class _GentleSkeleton extends StatelessWidget {
  const _GentleSkeleton();
  @override
  Widget build(BuildContext context) {
    Widget row() => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 11),
                    SizedBox(height: 8),
                    SkeletonBox(width: double.infinity, height: 5, radius: 999),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBox(width: 64, height: 36, radius: 8),
            ],
          ),
        );
    return Column(children: [row(), row(), row()]);
  }
}

// ── Section: Gut-health insights (Phase 4C) ─────────────────────────────────

class _GutHealthSection extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const _GutHealthSection({required this.userId, required this.isDark});

  @override
  ConsumerState<_GutHealthSection> createState() => _GutHealthSectionState();
}

class _GutHealthSectionState extends ConsumerState<_GutHealthSection> {
  DigestionPatterns? _cached;
  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final v = await _readPatternsCache(
        _kGutCacheKey, widget.userId, DigestionPatterns.fromJson);
    if (!mounted) return;
    setState(() => _cached = v);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(digestionPatternsProvider(widget.userId));
    final fresh = async.valueOrNull;
    if (fresh != null) {
      _writePatternsCache(_kGutCacheKey, widget.userId, _encodeDigestion(fresh));
    }
    final data = fresh ?? _cached;
    final isDark = widget.isDark;

    return _SectionContainer(
      title: 'Your natural rhythm',
      subtitle: 'How your gut has been, in your own words',
      isDark: isDark,
      child: Builder(builder: (context) {
        if (data != null && !data.isEmpty && !data.hasNoData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RhythmStatsRow(data: data, isDark: isDark),
              const SizedBox(height: 14),
              _RegularityChart(series: data.series, isDark: isDark),
              if (data.correlations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _GutCorrelationsList(
                    correlations: data.correlations, isDark: isDark),
              ],
            ],
          );
        }
        // First load with no cached payload → skeleton.
        if (data == null && async.isLoading) {
          return const _GutSkeleton();
        }
        // Nothing logged yet → teach + one-tap into the gut-log sheet.
        return _PatternsTeaser(
          icon: Icons.spa_outlined,
          headline:
              'Track how your gut has been — in your own words, no clinical detail.',
          bullets: const [
            'A few taps logs each day',
            'See your regularity rhythm over time',
            'Spot foods and tags that seem connected',
          ],
          ctaLabel: 'Log gut health',
          ctaIcon: Icons.add_rounded,
          onCta: () =>
              showGutHealthSheet(context: context, userId: widget.userId),
          isDark: isDark,
        );
      }),
    );
  }
}

Map<String, dynamic> _encodeDigestion(DigestionPatterns d) => {
      'series': [
        for (final s in d.series)
          {'date': s.date, 'count': s.count, 'avg_bristol': s.avgBristol}
      ],
      'correlations': [
        for (final c in d.correlations)
          {
            'key': c.key,
            'label': c.label,
            'count': c.count,
            'confidence_pct': c.confidencePct,
            'foods': [
              for (final f in c.foods)
                {
                  'food_name': f.name,
                  'image_url': f.imageUrl,
                  'occurrences': f.occurrences,
                  'last_logged_at': f.lastLoggedAt,
                }
            ],
          }
      ],
      'avg_per_day': d.avgPerDay,
      'regularity_pct': d.regularityPct,
      'typical_bristol': d.typicalBristol,
      'days_window': d.daysWindow,
    };

class _RhythmStatsRow extends StatelessWidget {
  final DigestionPatterns data;
  final bool isDark;
  const _RhythmStatsRow({required this.data, required this.isDark});

  // Cozy, non-clinical Bristol descriptors (no graphic detail).
  static const _bristolWord = <int, String>{
    1: 'on the firm side',
    2: 'firm',
    3: 'just right',
    4: 'just right',
    5: 'on the soft side',
    6: 'soft',
    7: 'very soft',
  };

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    Widget stat(String value, String label, {Color? valueColor}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: ZType.disp(24, color: valueColor ?? textPrimary)),
              const SizedBox(height: 2),
              Text(label.toUpperCase(),
                  style: ZType.lbl(10, color: textMuted, letterSpacing: 1.2)),
            ],
          ),
        );

    final perDay = data.avgPerDay;
    final reg = data.regularityPct;
    final typical = data.typicalBristol;

    return Row(
      children: [
        if (perDay != null)
          stat(perDay.toStringAsFixed(perDay >= 10 ? 0 : 1), 'avg / day',
              valueColor: tc.accent),
        if (reg != null)
          stat('${(reg * 100).round()}%', 'regular days'),
        if (typical != null)
          stat(
            '#$typical',
            _bristolWord[typical] ?? 'typical',
          ),
      ],
    );
  }
}

/// A cozy per-day regularity strip — one soft bar per day, taller = more
/// movements. Non-clinical: no Bristol numbers on the axis.
class _RegularityChart extends StatelessWidget {
  final List<RegularityDay> series;
  final bool isDark;
  const _RegularityChart({required this.series, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    if (series.isEmpty) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text('Not enough days yet',
              style: TextStyle(fontSize: 12, color: textMuted)),
        ),
      );
    }
    // Show the most recent ~28 days so the strip stays readable.
    final recent =
        series.length > 28 ? series.sublist(series.length - 28) : series;
    final maxCount = recent.fold<int>(
        1, (m, d) => d.count > m ? d.count : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in recent)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: d.count == 0
                          ? 4
                          : 8 + (d.count / maxCount) * 32,
                      decoration: BoxDecoration(
                        color: d.count == 0
                            ? (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.07)
                            : tc.accent.withValues(
                                alpha: 0.35 + (d.count / maxCount) * 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_relLabel(recent.first.date),
                style: TextStyle(fontSize: 10, color: textMuted)),
            Text('today', style: TextStyle(fontSize: 10, color: textMuted)),
          ],
        ),
      ],
    );
  }

  String _relLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d').format(dt.toLocal());
  }
}

class _GutCorrelationsList extends StatelessWidget {
  final List<SymptomBucket> correlations;
  final bool isDark;
  const _GutCorrelationsList(
      {required this.correlations, required this.isDark});

  // Gentle "X days → Y" framing, non-alarming.
  static const _phrases = <String>[
    'On your {x} days, things ran {dir}',
    '{x} seemed to make things {dir}',
    'After {x}, your gut leaned {dir}',
    '{x} days trended {dir}',
  ];

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHAT SEEMS CONNECTED',
            style: ZType.lbl(12, color: textPrimary)),
        const SizedBox(height: 8),
        for (final c in correlations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, size: 15, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _line(c),
                    style: TextStyle(
                        fontSize: 12.5, color: textPrimary, height: 1.35),
                  ),
                ),
                if (c.confidencePct > 0)
                  Text('${c.confidencePct}%',
                      style: TextStyle(fontSize: 11, color: textMuted)),
              ],
            ),
          ),
      ],
    );
  }

  String _line(SymptomBucket c) {
    // "looser"/"firmer" hint pulled from the bucket label if the backend
    // provides a direction; otherwise neutral "differently".
    final lbl = c.label.toLowerCase();
    String dir = 'differently';
    if (lbl.contains('loose') || lbl.contains('soft')) dir = 'softer';
    if (lbl.contains('firm') || lbl.contains('hard')) dir = 'firmer';
    final foods = c.foods.isNotEmpty
        ? c.foods.first.name
        : (c.key.isNotEmpty ? c.key : 'those');
    return _pick(_phrases, c.key)
        .replaceAll('{x}', foods)
        .replaceAll('{dir}', dir);
  }
}

class _GutSkeleton extends StatelessWidget {
  const _GutSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Expanded(child: SkeletonBox(width: 60, height: 26)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(width: 60, height: 26)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(width: 60, height: 26)),
          ],
        ),
        SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 44, radius: 8),
      ],
    );
  }
}
