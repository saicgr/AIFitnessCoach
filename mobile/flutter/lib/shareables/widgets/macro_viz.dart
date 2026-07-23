import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_data.dart';
import 'macro_painters.dart';

/// The visual heart of food sharing — one pure [StatelessWidget] that renders
/// a [ShareableNutrition] in any of the 14 [MacroVizStyle]s.
///
/// It is intentionally static (no animation): the share-capture pipeline
/// screenshots the widget tree, so every style must paint a final, complete
/// frame the instant it is laid out. Every style is built to:
///   • render with zero overflow / zero exceptions at sticker scale
///     (`scale` ≈ 0.6) and full-card scale (`scale` ≈ 1.4);
///   • degrade gracefully when [nutrition] is all zeros (it shows the empty
///     structure, never a crash and never invented numbers).
///
/// The public constructor is a contract other share-template agents code
/// against — do not change its shape.
class MacroViz extends StatelessWidget {
  final ShareableNutrition nutrition;
  final MacroVizStyle style;

  /// Calorie-emphasis color (rings, gauges, big numbers lean on this).
  final Color accentColor;

  /// Foreground text/label color. Defaults to opaque white.
  final Color textColor;

  /// Multiplies every internal size — fonts, strokes, paddings — so the same
  /// widget works as a tiny sticker (~0.6) and a full card layer (~1.4).
  final double scale;

  /// When true, content sits on a frosted translucent plate (a blurred,
  /// faintly-filled rounded panel) so the viz stays legible over a photo.
  final bool glass;

  /// Optional meal health score 1–10. Where a style has a natural center
  /// (rings, coin), it can replace the calorie figure there.
  final int? healthScore;

  /// When true, ring/donut styles add a 4th fiber ring/wedge.
  final bool showFiber;

  const MacroViz({
    super.key,
    required this.nutrition,
    required this.style,
    required this.accentColor,
    this.textColor = const Color(0xFFFFFFFF),
    this.scale = 1.0,
    this.glass = false,
    this.healthScore,
    this.showFiber = false,
  });

  // ─── Macro color shorthands (app-wide constants) ───────────────────────
  Color get _pColor => AppColors.macroProtein; // 0xFFA855F7
  Color get _cColor => AppColors.macroCarbs; //   0xFF06B6D4
  Color get _fColor => AppColors.macroFat; //     0xFFF97316
  Color get _fiberColor => AppColors.green; //    0xFF22C55E

  Color get _muted => textColor.withValues(alpha: 0.62);
  Color get _faint => textColor.withValues(alpha: 0.30);

  // ─── Derived nutrition values ──────────────────────────────────────────
  // Macro grams; `null` = genuinely unknown (single-item/meal share) and must
  // render "—", never "0g". Aggregate shares carry a non-null value. Negative
  // inputs clamp to 0 (a share never shows a negative gram count).
  double? get _proteinG => _clampMacro(nutrition.proteinG);
  double? get _carbsG => _clampMacro(nutrition.carbsG);
  double? get _fatG => _clampMacro(nutrition.fatG);
  double? get _fiberG => _clampMacro(nutrition.fiberG);
  static double? _clampMacro(double? v) => v == null ? null : math.max(0.0, v);
  int get _calories => math.max(0, nutrition.calories);

  /// Grams label for display: "32g" for a known macro, "—" for a genuinely-
  /// unknown one (null). Single source for every gram label this widget prints
  /// — routed through the shareables-layer helper so a null never shows "0g".
  String _macroLabel(double? g) => shareableMacroGrams(g);

  /// Bare grams number ("32" / "—"), for centers/labels that carry the unit
  /// separately or none at all.
  String _macroValue(double? g) => shareableMacroGramsValue(g);

  /// Calorie contribution of each macro (4/4/9 kcal per gram). The basis for
  /// every "by calorie share" style (pie, plate, stacked bar, waffle) — the
  /// painters size wedges/segments by these relative values directly. An
  /// UNKNOWN macro (null) contributes 0 kcal, so its wedge/segment is simply
  /// not drawn (excluded from the chart), never a misleading 0-gram slice.
  double get _pKcal => (_proteinG ?? 0) * 4;
  double get _cKcal => (_carbsG ?? 0) * 4;
  double get _fKcal => (_fatG ?? 0) * 9;

  /// True when there is genuinely nothing to show (no calories and no known
  /// macro grams). An unknown macro (null) counts as nothing here.
  bool get _isEmpty =>
      _calories == 0 &&
      (_proteinG ?? 0) == 0 &&
      (_carbsG ?? 0) == 0 &&
      (_fatG ?? 0) == 0;

  /// Goal-relative progress for a macro, clamped to allow a 1.5× overshoot
  /// lick. Returns null when no goal is set for that macro.
  double? _progress(double value, double? goal) {
    if (goal == null || goal <= 0) return null;
    return (value / goal).clamp(0.0, 1.5);
  }

  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = _buildStyle();
    if (!glass) return content;

    // Frosted translucent plate behind the content for legibility on photos.
    final pad = 18.0 * scale;
    final radius = 24.0 * scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildStyle() {
    switch (style) {
      case MacroVizStyle.appleRings:
        return _appleRings();
      case MacroVizStyle.calorieRing:
        return _calorieRing();
      case MacroVizStyle.donutTrio:
        return _donutTrio();
      case MacroVizStyle.macroPie:
        return _macroPie();
      case MacroVizStyle.plate:
        return _plate();
      case MacroVizStyle.gauge:
        return _gauge();
      case MacroVizStyle.stackedBar:
        return _stackedBar();
      case MacroVizStyle.progressBars:
        return _progressBars();
      case MacroVizStyle.columnChart:
        return _columnChart();
      case MacroVizStyle.numbers:
        return _numbers();
      case MacroVizStyle.pills:
        return _pills();
      case MacroVizStyle.coin:
        return _coin();
      case MacroVizStyle.waffle:
        return _waffle();
      case MacroVizStyle.label:
        return _label();
    }
  }

  // ─── Shared text helpers ───────────────────────────────────────────────

  /// "32" — grams as an integer string (food shares show whole grams).
  String _g(double v) => v.round().toString();

  Text _text(
    String value, {
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double height = 1.05,
  }) {
    return Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: size * scale,
        fontWeight: weight,
        color: color ?? textColor,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }

  // ───────────────────────────── STYLE 1 ────────────────────────────────
  // appleRings — 3 concentric Activity rings (P outer, C mid, F inner),
  // goal-relative arcs when goals exist, total calories in the center.

  Widget _appleRings() {
    final hasGoals = nutrition.hasGoals;
    // An unknown macro (null) with goals draws an empty (0-progress) ring —
    // no fill, which honestly reads as "no data", not a filled/partial arc.
    final rings = <MacroRing>[
      MacroRing(
        hasGoals ? (_progress(_proteinG ?? 0, nutrition.proteinGoal) ?? 1.0) : 1.0,
        _pColor,
      ),
      MacroRing(
        hasGoals ? (_progress(_carbsG ?? 0, nutrition.carbsGoal) ?? 1.0) : 1.0,
        _cColor,
      ),
      MacroRing(
        hasGoals ? (_progress(_fatG ?? 0, nutrition.fatGoal) ?? 1.0) : 1.0,
        _fColor,
      ),
    ];
    if (showFiber) {
      rings.add(MacroRing(
        hasGoals ? (_progress(_fiberG ?? 0, null) ?? 1.0) : 1.0,
        _fiberColor,
      ));
    }
    final stroke = (showFiber ? 16.0 : 19.0) * scale;
    return _SquareViz(
      fallbackExtent: 300 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: RingsPainter(
              rings: rings,
              strokeWidth: stroke,
              gap: 4.0 * scale,
              trackColor: textColor.withValues(alpha: 0.08),
            ),
            child: const SizedBox.expand(),
          ),
          _centerStack(
            big: _isEmpty ? '—' : '$_calories',
            small: 'kcal',
            bigSize: 46,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── STYLE 2 ────────────────────────────────
  // calorieRing — one bold calorie ring (vs goal if any) + P/C/F chips.

  Widget _calorieRing() {
    final calProgress = _progress(_calories.toDouble(),
            nutrition.calorieGoal?.toDouble()) ??
        1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150 * scale,
          height: 150 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: RingsPainter(
                  rings: [MacroRing(calProgress, accentColor)],
                  strokeWidth: 16 * scale,
                  trackColor: textColor.withValues(alpha: 0.10),
                ),
                child: const SizedBox.expand(),
              ),
              _centerStack(
                big: _isEmpty ? '—' : '$_calories',
                small: nutrition.calorieGoal != null
                    ? 'of ${nutrition.calorieGoal}'
                    : 'kcal',
                bigSize: 40,
              ),
            ],
          ),
        ),
        SizedBox(height: 14 * scale),
        _macroChipRow(),
      ],
    );
  }

  /// A row of three small `P 32g` chips in macro colors.
  Widget _macroChipRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _miniChip('P', _macroLabel(_proteinG), _pColor),
        SizedBox(width: 8 * scale),
        _miniChip('C', _macroLabel(_carbsG), _cColor),
        SizedBox(width: 8 * scale),
        _miniChip('F', _macroLabel(_fatG), _fColor),
        if (showFiber) ...[
          SizedBox(width: 8 * scale),
          _miniChip('Fb', _macroLabel(_fiberG), _fiberColor),
        ],
      ],
    );
  }

  /// [value] is the fully-formatted gram label ("32g" or "—"); this builder
  /// never appends its own unit, so an unknown macro shows "—" not "—g".
  Widget _miniChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ]),
      ),
    );
  }

  // ───────────────────────────── STYLE 3 ────────────────────────────────
  // donutTrio — 3 separate donuts, gram value in each center, label below.

  Widget _donutTrio() {
    final items = <_MacroDatum>[
      _MacroDatum('Protein', 'P', _proteinG, _pColor, nutrition.proteinGoal),
      _MacroDatum('Carbs', 'C', _carbsG, _cColor, nutrition.carbsGoal),
      _MacroDatum('Fat', 'F', _fatG, _fColor, nutrition.fatGoal),
      if (showFiber) _MacroDatum('Fiber', 'Fb', _fiberG, _fiberColor, null),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 14 * scale),
          _singleDonut(items[i]),
        ],
      ],
    );
  }

  Widget _singleDonut(_MacroDatum d) {
    // Unknown macro (null) → 0 progress (empty ring) and "—" in the center.
    final progress = _progress(d.grams ?? 0, d.goal) ?? 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 78 * scale,
          height: 78 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: RingsPainter(
                  rings: [MacroRing(progress, d.color)],
                  strokeWidth: 10 * scale,
                  trackColor: d.color.withValues(alpha: 0.16),
                ),
                child: const SizedBox.expand(),
              ),
              _text(_macroValue(d.grams), size: 21, weight: FontWeight.w800),
            ],
          ),
        ),
        SizedBox(height: 6 * scale),
        _text(
          d.label.toUpperCase(),
          size: 10,
          weight: FontWeight.w700,
          color: d.color,
          letterSpacing: 0.8,
        ),
      ],
    );
  }

  // ───────────────────────────── STYLE 4 ────────────────────────────────
  // macroPie — one donut split into P/C/F wedges by CALORIE share.

  Widget _macroPie() {
    final wedges = <MacroWedge>[
      MacroWedge(_pKcal, _pColor),
      MacroWedge(_cKcal, _cColor),
      MacroWedge(_fKcal, _fColor),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150 * scale,
          height: 150 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: MacroPiePainter(
                  wedges: wedges,
                  thicknessFraction: 0.34,
                  emptyColor: textColor.withValues(alpha: 0.10),
                ),
                child: const SizedBox.expand(),
              ),
              _centerStack(
                big: _isEmpty ? '—' : '$_calories',
                small: 'kcal',
                bigSize: 34,
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        _pieLegend(),
      ],
    );
  }

  /// A horizontal `• P` `• C` `• F` legend with a colored dot per macro.
  Widget _pieLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot('Protein', _pColor),
        SizedBox(width: 12 * scale),
        _legendDot('Carbs', _cColor),
        SizedBox(width: 12 * scale),
        _legendDot('Fat', _fColor),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 5 * scale),
        _text(label, size: 11, weight: FontWeight.w600, color: _muted),
      ],
    );
  }

  // ───────────────────────────── STYLE 5 ────────────────────────────────
  // plate — a circular "plate" (subtle rim) split into the same 3 wedges.

  Widget _plate() {
    final wedges = <MacroWedge>[
      MacroWedge(_pKcal, _pColor),
      MacroWedge(_cKcal, _cColor),
      MacroWedge(_fKcal, _fColor),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 152 * scale,
          height: 152 * scale,
          child: CustomPaint(
            painter: PlatePainter(
              wedges: wedges,
              rimColor: textColor.withValues(alpha: 0.34),
              emptyColor: textColor.withValues(alpha: 0.10),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        SizedBox(height: 12 * scale),
        _pieLegend(),
      ],
    );
  }

  // ───────────────────────────── STYLE 6 ────────────────────────────────
  // gauge — a semicircular speedometer for calories vs goal.

  Widget _gauge() {
    final goal = nutrition.calorieGoal;
    final progress = (goal != null && goal > 0)
        ? (_calories / goal).clamp(0.0, 1.0)
        : (_isEmpty ? 0.0 : 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 184 * scale,
          height: 104 * scale,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                painter: GaugePainter(
                  progress: progress,
                  fillColor: accentColor,
                  trackColor: textColor.withValues(alpha: 0.12),
                  strokeWidth: 17 * scale,
                ),
                child: const SizedBox.expand(),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4 * scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _text(
                      _isEmpty ? '—' : '$_calories',
                      size: 38,
                      weight: FontWeight.w800,
                    ),
                    _text(
                      goal != null ? 'of $goal kcal' : 'kcal',
                      size: 12,
                      weight: FontWeight.w600,
                      color: _muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10 * scale),
        _macroChipRow(),
      ],
    );
  }

  // ───────────────────────────── STYLE 7 ────────────────────────────────
  // stackedBar — one rounded horizontal bar, 3 segments P|C|F by calorie
  // share, gram labels beneath.

  Widget _stackedBar() {
    final segs = <BarSegment>[
      BarSegment(_pKcal, _pColor),
      BarSegment(_cKcal, _cColor),
      BarSegment(_fKcal, _fColor),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 26 * scale,
          child: CustomPaint(
            painter: StackedBarPainter(
              segments: segs,
              trackColor: textColor.withValues(alpha: 0.12),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        SizedBox(height: 10 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _barLabel('P', _macroLabel(_proteinG), _pColor),
            _barLabel('C', _macroLabel(_carbsG), _cColor),
            _barLabel('F', _macroLabel(_fatG), _fColor),
          ],
        ),
      ],
    );
  }

  /// [value] is the fully-formatted gram label ("40g" or "—").
  Widget _barLabel(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 5 * scale),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ───────────────────────────── STYLE 8 ────────────────────────────────
  // progressBars — 3 stacked rows: dot + label + linear bar (vs goal) +
  // `Xg / Yg` (absolute `Xg` when no goal).

  Widget _progressBars() {
    final rows = <_MacroDatum>[
      _MacroDatum('Protein', 'P', _proteinG, _pColor, nutrition.proteinGoal),
      _MacroDatum('Carbs', 'C', _carbsG, _cColor, nutrition.carbsGoal),
      _MacroDatum('Fat', 'F', _fatG, _fColor, nutrition.fatGoal),
      if (showFiber) _MacroDatum('Fiber', 'Fb', _fiberG, _fiberColor, null),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: 12 * scale),
          _progressRow(rows[i]),
        ],
      ],
    );
  }

  Widget _progressRow(_MacroDatum d) {
    final hasGoal = d.goal != null && d.goal! > 0;
    // Unknown macro (null) → no fill and a "—" value (or "— / Yg" against a
    // goal), never a fabricated "0g".
    final fraction =
        hasGoal ? ((d.grams ?? 0) / d.goal!).clamp(0.0, 1.0) : 1.0;
    final valueText = hasGoal
        ? '${_macroLabel(d.grams)} / ${_g(d.goal!)}g'
        : _macroLabel(d.grams);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(shape: BoxShape.circle, color: d.color),
            ),
            SizedBox(width: 6 * scale),
            Text(
              d.label,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const Spacer(),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 11.5 * scale,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8 * scale,
            child: CustomPaint(
              painter: StackedBarPainter(
                segments: fraction <= 0
                    ? const []
                    // The single colored segment + an invisible spacer so the
                    // bar fills exactly `fraction` of the rounded track.
                    : [
                        BarSegment(fraction, d.color),
                        if (fraction < 1)
                          BarSegment(1 - fraction, Colors.transparent),
                      ],
                trackColor: textColor.withValues(alpha: 0.12),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────── STYLE 9 ────────────────────────────────
  // columnChart — 3 vertical bars, heights ∝ grams, value on top.

  Widget _columnChart() {
    final cols = <_MacroDatum>[
      _MacroDatum('Protein', 'P', _proteinG, _pColor, null),
      _MacroDatum('Carbs', 'C', _carbsG, _cColor, null),
      _MacroDatum('Fat', 'F', _fatG, _fColor, null),
    ];
    return SizedBox(
      width: 168 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Value labels above the bars.
          Row(
            children: [
              for (final d in cols)
                Expanded(
                  child: _text(
                    _macroLabel(d.grams),
                    size: 13,
                    weight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          SizedBox(height: 5 * scale),
          SizedBox(
            height: 96 * scale,
            child: CustomPaint(
              painter: ColumnChartPainter(
                // Unknown macro (null) → 0 height: the column is not drawn
                // (excluded from the chart), never a phantom 0-gram bar.
                columns: [
                  for (final d in cols) ChartColumn(d.grams ?? 0, d.color)
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: 5 * scale),
          // Macro labels below the baseline.
          Row(
            children: [
              for (final d in cols)
                Expanded(
                  child: _text(
                    d.label.toUpperCase(),
                    size: 10,
                    weight: FontWeight.w700,
                    color: d.color,
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── STYLE 10 ────────────────────────────────
  // numbers — a giant calorie figure, then a `P 32g · C 40g · F 12g` row.

  Widget _numbers() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _text(
          _isEmpty ? '—' : '$_calories',
          size: 84,
          weight: FontWeight.w900,
          height: 0.95,
        ),
        SizedBox(height: 2 * scale),
        _text(
          'CALORIES',
          size: 13,
          weight: FontWeight.w700,
          color: _muted,
          letterSpacing: 2.4,
        ),
        SizedBox(height: 12 * scale),
        // Macro row in macro colors, dot-separated.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8 * scale,
          children: [
            _numberMacro('P', _macroLabel(_proteinG), _pColor),
            _dotSep(),
            _numberMacro('C', _macroLabel(_carbsG), _cColor),
            _dotSep(),
            _numberMacro('F', _macroLabel(_fatG), _fColor),
            if (showFiber) ...[
              _dotSep(),
              _numberMacro('Fb', _macroLabel(_fiberG), _fiberColor),
            ],
          ],
        ),
      ],
    );
  }

  /// [value] is the fully-formatted gram label ("32g" or "—").
  Widget _numberMacro(String label, String value, Color color) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$label ',
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        TextSpan(
          text: value,
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ]),
    );
  }

  Widget _dotSep() => Text(
        '·',
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w900,
          color: _faint,
        ),
      );

  // ──────────────────────────── STYLE 11 ────────────────────────────────
  // pills — 3 stadium pills `P 32g` `C 40g` `F 12g` in macro colors.

  Widget _pills() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10 * scale,
      runSpacing: 10 * scale,
      children: [
        _bigPill('Protein', _macroLabel(_proteinG), _pColor),
        _bigPill('Carbs', _macroLabel(_carbsG), _cColor),
        _bigPill('Fat', _macroLabel(_fatG), _fColor),
        if (showFiber) _bigPill('Fiber', _macroLabel(_fiberG), _fiberColor),
      ],
    );
  }

  /// [value] is the fully-formatted gram label ("32g" or "—").
  Widget _bigPill(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ]),
      ),
    );
  }

  // ──────────────────────────── STYLE 12 ────────────────────────────────
  // coin — a circular medallion: big calorie number centered, a thin
  // tri-color P/C/F ring as the rim. The most sticker-like style.

  Widget _coin() {
    final wedges = <MacroWedge>[
      MacroWedge(_pKcal, _pColor),
      MacroWedge(_cKcal, _cColor),
      MacroWedge(_fKcal, _fColor),
    ];
    final size = 156.0 * scale;
    final showScore = healthScore != null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Medallion body.
          Container(
            margin: EdgeInsets.all(11 * scale),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(accentColor, Colors.black, 0.55)!,
                  Color.lerp(accentColor, Colors.black, 0.78)!,
                ],
              ),
              border: Border.all(
                color: textColor.withValues(alpha: 0.14),
                width: 1.2,
              ),
            ),
          ),
          // Tri-color rim ring.
          CustomPaint(
            size: Size(size, size),
            painter: MacroPiePainter(
              wedges: wedges,
              thicknessFraction: 0.085,
              wedgeGap: 0.06,
              emptyColor: textColor.withValues(alpha: 0.14),
            ),
          ),
          // Center figure.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(
                showScore
                    ? '$healthScore'
                    : (_isEmpty ? '—' : '$_calories'),
                size: showScore ? 52 : 40,
                weight: FontWeight.w900,
                height: 0.95,
              ),
              _text(
                showScore ? 'HEALTH SCORE' : 'CALORIES',
                size: 9,
                weight: FontWeight.w700,
                color: _muted,
                letterSpacing: 1.8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── STYLE 13 ────────────────────────────────
  // waffle — a 10×10 rounded-square grid; cells colored P/C/F by calorie
  // proportion, remaining cells faint.

  Widget _waffle() {
    final categories = <MacroWedge>[
      MacroWedge(_pKcal, _pColor),
      MacroWedge(_cKcal, _cColor),
      MacroWedge(_fKcal, _fColor),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150 * scale,
          height: 150 * scale,
          child: CustomPaint(
            painter: WafflePainter(
              categories: categories,
              emptyColor: textColor.withValues(alpha: 0.10),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        SizedBox(height: 12 * scale),
        _pieLegend(),
      ],
    );
  }

  // ──────────────────────────── STYLE 14 ────────────────────────────────
  // label — a compact parody "Nutrition Facts" mini-panel: bold title,
  // thick rules, calorie + macro rows.

  Widget _label() {
    final rule = textColor.withValues(alpha: 0.9);
    return Container(
      width: 220 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: rule, width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nutrition Facts',
            style: TextStyle(
              fontSize: 21 * scale,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.05,
            ),
          ),
          SizedBox(height: 4 * scale),
          _labelRule(rule, 7 * scale),
          SizedBox(height: 5 * scale),
          // Calories row — emphasized.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                _isEmpty ? '—' : '$_calories',
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          _labelRule(rule, 3.5 * scale),
          SizedBox(height: 5 * scale),
          _labelRow('Total Fat', _macroLabel(_fatG), _fColor),
          _labelThinRule(rule),
          _labelRow('Total Carbohydrate', _macroLabel(_carbsG), _cColor),
          if ((nutrition.fiberG ?? 0) > 0 || showFiber) ...[
            _labelThinRule(rule),
            _labelRow('  Dietary Fiber', _macroLabel(_fiberG), _fiberColor,
                indent: true),
          ],
          _labelThinRule(rule),
          _labelRow('Protein', _macroLabel(_proteinG), _pColor),
        ],
      ),
    );
  }

  Widget _labelRule(Color color, double thickness) =>
      Container(height: thickness, color: color);

  Widget _labelThinRule(Color color) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * scale),
        child: Container(
          height: 1,
          color: color.withValues(alpha: 0.55),
        ),
      );

  Widget _labelRow(String name, String value, Color accent,
      {bool indent = false}) {
    return Row(
      children: [
        Container(
          width: 7 * scale,
          height: 7 * scale,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
        SizedBox(width: 7 * scale),
        Expanded(
          child: Text(
            name.trim(),
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: indent ? FontWeight.w500 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ─── Shared layout primitives ──────────────────────────────────────────

  /// A stacked big-number + small-caption block, used in every ring/donut
  /// center. When a [healthScore] is set the calorie center may show it
  /// instead (handled per-style).
  Widget _centerStack({
    required String big,
    required String small,
    required double bigSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _text(big, size: bigSize, weight: FontWeight.w900, height: 0.95),
        SizedBox(height: 1 * scale),
        _text(
          small,
          size: 11,
          weight: FontWeight.w600,
          color: _muted,
          letterSpacing: 0.6,
        ),
      ],
    );
  }
}

/// Wraps a child in a 1:1 box so ring/pie painters get a square to paint in
/// regardless of the parent's aspect.
///
/// `AspectRatio` *asserts* when handed unbounded constraints on BOTH axes
/// (it has no side to derive the square from). That happens whenever a
/// MacroViz ring/pie style is dropped into a fully-unconstrained parent —
/// e.g. a horizontally-scrolling format strip, or a `Positioned` with no
/// width/height. To stay crash-proof on every screen size and every host,
/// fall back to a fixed square ([fallbackExtent]) in that case; otherwise
/// behave exactly like a plain `AspectRatio`.
class _SquareViz extends StatelessWidget {
  final Widget child;

  /// Edge length used ONLY when the parent gives unbounded width AND height.
  /// Callers pass their `scale`-adjusted value so the fallback still looks
  /// proportionate.
  final double fallbackExtent;

  const _SquareViz({required this.child, this.fallbackExtent = 300});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
          return SizedBox.square(dimension: fallbackExtent, child: child);
        }
        return AspectRatio(aspectRatio: 1, child: child);
      },
    );
  }
}

/// Internal per-macro bundle so the style builders don't repeat 5-tuples.
/// [grams] is nullable: `null` = genuinely unknown, rendered "—" (never "0g")
/// and excluded from bar/column geometry.
@immutable
class _MacroDatum {
  final String label;
  final String short;
  final double? grams;
  final Color color;
  final double? goal;

  const _MacroDatum(this.label, this.short, this.grams, this.color, this.goal);
}
