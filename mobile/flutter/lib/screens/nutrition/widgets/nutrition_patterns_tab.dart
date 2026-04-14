import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/food_patterns.dart';
import '../../../data/providers/food_patterns_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';

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
        child: Text('Sign in to see your patterns',
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
            child: _HistorySection(
              userId: userId,
              range: _range,
              date: _anchorDateStr,
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
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

  // Extent sized for worst realistic case:
  //   outer padding 8+8 = 16
  //   pill row (up to ~44 at 1.3x text scale with iOS default padding)
  //   gap 6
  //   arrow row 28
  //   = 94, plus a 10px safety margin for platform text metrics = 104.
  // We also wrap the inner Column in a FittedBox(scaleDown) so even at
  // extreme accessibility text scales the content scales down instead of
  // throwing a RenderFlex overflow.
  @override
  double get minExtent => 104;
  @override
  double get maxExtent => 104;

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

class _MacroChartsSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(macrosSummaryProvider(
      MacrosQuery(userId: userId, range: range, date: date),
    ));
    return _SectionContainer(
      title: range == 'day' ? "Today's Macros" : 'Macros & Calories',
      isDark: isDark,
      child: async.when(
        loading: () => const _LoadingStub(height: 180),
        error: (e, _) => _ErrorStub(message: 'Couldn\'t load macros'),
        data: (summary) {
          if (summary.daysCounted == 0) {
            return _EmptyStub(
              icon: Icons.pie_chart_outline,
              title: 'No meals logged',
              subtitle: 'Log a few meals to see your macro trends.',
            );
          }
          return Column(
            children: [
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: _MacroPie(summary: summary),
                    ),
                    Expanded(
                      child: _MacroLegend(summary: summary, isDark: isDark),
                    ),
                  ],
                ),
              ),
              if (range != 'day') ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: _CalorieTrend(summary: summary, isDark: isDark),
                ),
              ],
            ],
          );
        },
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

class _CalorieTrend extends StatelessWidget {
  final MacrosSummaryResponse summary;
  final bool isDark;
  const _CalorieTrend({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final points = summary.dailySeries;
    if (points.length < 2) {
      return Center(
        child: Text('Need more days of data',
            style: TextStyle(fontSize: 12, color: textMuted)),
      );
    }
    final maxCal = points.map((p) => p.calories).fold(0, (a, b) => a > b ? a : b).toDouble();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxCal * 1.2).clamp(500, 5000),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].calories.toDouble()),
            ],
            isCurved: true,
            color: AppColors.cyan,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.cyan.withValues(alpha: 0.1),
            ),
          ),
          if (summary.calorieGoal != null)
            LineChartBarData(
              spots: [
                FlSpot(0, summary.calorieGoal!.toDouble()),
                FlSpot((points.length - 1).toDouble(), summary.calorieGoal!.toDouble()),
              ],
              isCurved: false,
              color: AppColors.orange.withValues(alpha: 0.6),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
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

    return _SectionContainer(
      title: 'Foods highest in…',
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
          async.when(
            loading: () => const _LoadingStub(height: 160),
            error: (e, _) => _ErrorStub(message: 'Couldn\'t load foods'),
            data: (data) {
              if (data.items.isEmpty) {
                return _EmptyStub(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'No foods yet',
                  subtitle: 'Log meals to see your top ${_METRICS.firstWhere((e) => e.key == _metric).value.toLowerCase()} sources.',
                );
              }
              return Column(
                children: [
                  for (final item in data.items.take(8))
                    _TopFoodRow(item: item, unit: data.items.first.unit, isDark: widget.isDark),
                  if (data.items.length > 8)
                    TextButton(
                      onPressed: () {}, // Full-list screen tracked in follow-up
                      child: Text('View all ${data.items.length}'),
                    ),
                ],
              );
            },
          ),
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

// ── Section 3: Mood / energy patterns ───────────────────────────────────────

class _MoodSection extends ConsumerWidget {
  final String userId;
  final bool isDark;
  const _MoodSection({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(foodPatternsMoodProvider(userId));
    return _SectionContainer(
      title: 'Your body\'s responses',
      subtitle: 'Based on the last 90 days',
      isDark: isDark,
      child: async.when(
        loading: () => const _LoadingStub(height: 160),
        error: (e, _) => _ErrorStub(message: 'Couldn\'t load patterns'),
        data: (data) {
          if (data.checkinDisabled) {
            return _CheckinDisabledBanner(
              userId: userId,
              isDark: isDark,
              ref: ref,
            );
          }
          if (data.isEmpty) {
            return _EmptyStub(
              icon: Icons.insights_outlined,
              title: 'No patterns yet',
              subtitle: 'Log 3+ meals with a check-in to see which foods fuel you and which drag you down.',
            );
          }
          return Column(
            children: [
              if (data.drainingFoods.isNotEmpty) ...[
                _MoodListHeader(
                  label: 'Foods that drag you down',
                  color: AppColors.orange,
                  isDark: isDark,
                ),
                for (final e in data.drainingFoods)
                  _MoodFoodTile(entry: e, negative: true, isDark: isDark),
                const SizedBox(height: 12),
              ],
              if (data.energizingFoods.isNotEmpty) ...[
                _MoodListHeader(
                  label: 'Foods that energize you',
                  color: AppColors.success,
                  isDark: isDark,
                ),
                for (final e in data.energizingFoods)
                  _MoodFoodTile(entry: e, negative: false, isDark: isDark),
              ],
            ],
          );
        },
      ),
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
              'Check-ins are off',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Re-enable the post-meal check-in sheet to start building your food-mood patterns.',
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
              child: const Text('Re-enable'),
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
                        'AI guess',
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

// ── Section 4: Meal log history ─────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  final String userId;
  final String range;
  final String date;
  final bool isDark;
  const _HistorySection({
    required this.userId,
    required this.range,
    required this.date,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patternsHistoryProvider(
      HistoryQuery(userId: userId, range: range, date: date),
    ));
    return _SectionContainer(
      title: 'Meal history',
      isDark: isDark,
      child: async.when(
        loading: () => const _LoadingStub(height: 200),
        error: (e, _) => _ErrorStub(message: 'Couldn\'t load history'),
        data: (rows) {
          if (rows.isEmpty) {
            return _EmptyStub(
              icon: Icons.event_note_outlined,
              title: 'No meals this $range',
              subtitle: 'Logged meals will show up here as a timeline.',
            );
          }
          return Column(
            children: [
              for (final r in rows.take(25))
                _HistoryRow(row: r, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isDark;
  const _HistoryRow({required this.row, required this.isDark});

  String _name() {
    final items = row['food_items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) return 'Meal';
    final names = items
        .take(3)
        .map((e) => (e as Map)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'Meal';
    final more = items.length - names.length;
    return more > 0 ? '${names.join(', ')} +$more' : names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final logged = row['logged_at'] as String?;
    final time = logged != null
        ? DateFormat('MMM d · h:mm a').format(DateTime.parse(logged).toLocal())
        : '';
    final cal = (row['total_calories'] as num?)?.toInt() ?? 0;
    final p = (row['protein_g'] as num?)?.toDouble() ?? 0;
    final c = (row['carbs_g'] as num?)?.toDouble() ?? 0;
    final f = (row['fat_g'] as num?)?.toDouble() ?? 0;
    final score = row['health_score'] as int?;
    final mood = row['mood_after'] as String?;
    final imageUrl = row['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              image: imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imageUrl == null
                ? Icon(Icons.restaurant, size: 22, color: textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cal kcal · P ${p.toStringAsFixed(0)}g · C ${c.toStringAsFixed(0)}g · F ${f.toStringAsFixed(0)}g',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          if (mood != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                mood,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.purple),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor(score).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$score',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _scoreColor(score)),
              ),
            ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.orange;
    return AppColors.error;
  }
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
      title: 'Check-in & Insights',
      isDark: isDark,
      child: async.when(
        loading: () => const _LoadingStub(height: 160),
        error: (e, _) => _ErrorStub(message: 'Couldn\'t load settings'),
        data: (s) => Column(children: [
          _ToggleRow(
            title: 'Post-meal check-in',
            subtitle: 'The quick "how do you feel?" sheet after logging',
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
            title: '45-min reminder push',
            subtitle: 'Nudge if you skip the check-in',
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
            title: 'AI mood guesses',
            subtitle: 'Auto-infer mood from nutrition when you skip check-ins',
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
