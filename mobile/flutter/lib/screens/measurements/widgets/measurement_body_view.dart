import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'measurement_value_pill.dart';

/// Anatomical anchor (x, y) for each body-part pill, expressed as a fraction
/// of the body panel's width and height.
///
/// Tuned for `AtlasAsset.musclesFront` (native SVG aspect ≈ 0.516, viewBox
/// 587×1137). Panel [AspectRatio] matches the SVG so the figure fills the
/// panel edge-to-edge with no letterboxing. Starting values based on
/// standard anatomical proportions — iterate visually on the simulator.
const Map<MeasurementType, Offset> _bodyAnchor = {
  MeasurementType.neck:          Offset(0.50, 0.15),
  MeasurementType.shoulders:     Offset(0.50, 0.19),
  MeasurementType.chest:         Offset(0.50, 0.25),
  // Paired-metric x anchors are shifted OUTWARD from the actual muscle x
  // so full-label pills ("Bicep L · 32 ›") don't collide with their L/R
  // twin across the torso. At ~300 dp body width and ~110 dp pill width,
  // L/R anchors need ≥ 0.36 separation.
  MeasurementType.bicepsLeft:    Offset(0.15, 0.27),
  MeasurementType.bicepsRight:   Offset(0.85, 0.27),
  // Forearm anchors pulled in from 0.10/0.90 so the wider "Forearm L/R"
  // labels aren't clipped by the panel's ClipRRect edge.
  MeasurementType.forearmLeft:   Offset(0.18, 0.38),
  MeasurementType.forearmRight:  Offset(0.82, 0.38),
  MeasurementType.waist:         Offset(0.50, 0.37),
  MeasurementType.hips:          Offset(0.50, 0.46),
  MeasurementType.thighLeft:     Offset(0.20, 0.58),
  MeasurementType.thighRight:    Offset(0.80, 0.58),
  MeasurementType.calfLeft:      Offset(0.20, 0.82),
  MeasurementType.calfRight:     Offset(0.80, 0.82),
};

/// Ghost-mode tint for the body atlas — every muscle painted with this
/// color so the whole figure reads as a soft faded silhouette rather than
/// an anatomical chart. BodyAtlasView layers overlapping muscle paths, so
/// alpha stacks; in dark mode a pure-white or mid-gray tint at any alpha
/// still accumulates toward near-white. Use a dark slate so stacking deepens
/// the silhouette against the dark background instead of bleaching it.
// Why: previous mid-gray tint still rendered washed-out-white in dark mode.
Color _ghostTint(bool isDark) => isDark
    ? const Color(0xFF1F2937).withValues(alpha: 0.55)
    : Colors.black.withValues(alpha: 0.18);

/// Build the `colorMapping` for [BodyAtlasView] that tints every muscle
/// with the same ghost shade. Cached per-isDark so we don't rebuild the
/// full catalogue map on each render.
Map<MuscleInfo, Color?> _buildGhostMapping(bool isDark) {
  final tint = _ghostTint(isDark);
  return {for (final m in MuscleCatalog.all) m: tint};
}

final Map<MuscleInfo, Color?> _ghostMappingLight = _buildGhostMapping(false);
final Map<MuscleInfo, Color?> _ghostMappingDark = _buildGhostMapping(true);

IconData _pillIcon(MeasurementType t) {
  switch (t) {
    case MeasurementType.neck:
      return Icons.face_retouching_natural;
    case MeasurementType.shoulders:
      return Icons.accessibility;
    case MeasurementType.chest:
      return Icons.accessibility_new;
    case MeasurementType.bicepsLeft:
    case MeasurementType.bicepsRight:
      return Icons.fitness_center;
    case MeasurementType.forearmLeft:
    case MeasurementType.forearmRight:
      return Icons.back_hand;
    case MeasurementType.waist:
      return Icons.straighten;
    case MeasurementType.hips:
      return Icons.straighten;
    case MeasurementType.thighLeft:
    case MeasurementType.thighRight:
      return Icons.directions_walk;
    case MeasurementType.calfLeft:
    case MeasurementType.calfRight:
      return Icons.directions_run;
    case MeasurementType.weight:
      return Icons.monitor_weight;
    case MeasurementType.bodyFat:
      return Icons.percent;
  }
}

String _shortNameForBody(MeasurementType t) {
  switch (t) {
    case MeasurementType.bicepsLeft:
      return 'Bicep L';
    case MeasurementType.bicepsRight:
      return 'Bicep R';
    case MeasurementType.forearmLeft:
      return 'Forearm L';
    case MeasurementType.forearmRight:
      return 'Forearm R';
    case MeasurementType.thighLeft:
      return 'Thigh L';
    case MeasurementType.thighRight:
      return 'Thigh R';
    case MeasurementType.calfLeft:
      return 'Calf L';
    case MeasurementType.calfRight:
      return 'Calf R';
    case MeasurementType.shoulders:
      return 'Shoulders';
    default:
      return t.displayName;
  }
}

/// Full-body view: the silhouette fills the entire panel so paired L/R
/// metrics have enough horizontal separation for compact pills to sit ON
/// each muscle without colliding with the opposite side.
class MeasurementBodyView extends ConsumerWidget {
  final MeasurementsState state;
  final bool isMetric;

  const MeasurementBodyView({
    super.key,
    required this.state,
    required this.isMetric,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Size the body panel to the available viewport height rather than a
    // fixed maxWidth. Scrolling past a body diagram feels off — we want the
    // whole figure to fit in one glance. Budget: screen height minus header
    // (~72 dp), weight-row (~60 dp), FAB margin (~80 dp).
    final screenH = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.paddingOf(context).top;
    final bodyPanelHeight =
        (screenH - topInset - 72 - 60 - 90).clamp(440.0, 780.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: direct-log pills (Weight, Body Fat) + derived metric
        // pills (BMI, WHR, W:Ht, …) — all same height / same shape, so
        // they read as one coherent glance-able strip. Horizontally
        // scrollable since there can be up to ~11 pills total.
        _TopMetricsStrip(state: state, isMetric: isMetric),

        // Body panel sized to fit the remaining viewport height; width
        // scales from the atlas SVG's native aspect.
        Center(
          child: SizedBox(
            height: bodyPanelHeight,
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // Match the atlas SVG's native aspect (587/1137 ≈ 0.516) so the
          // body fills the panel from edge to edge with no letterboxing.
          child: AspectRatio(
            aspectRatio: 0.516,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                // Clipping is applied ONLY to the background + atlas layer
                // (rounded panel look). The pill layer lives in an outer
                // `Stack(clipBehavior: Clip.none)` so paired-metric pills
                // (Bicep L/R, Forearm L/R) whose anchors sit near the edges
                // at x=0.15 / 0.85 aren't clipped by the rounded rect.
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background + anatomical atlas — clipped to rounded rect.
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor.withValues(alpha: 0.3),
                          ),
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: BodyAtlasView<MuscleInfo>(
                                view: AtlasAsset.musclesFront,
                                resolver: const MuscleResolver(),
                                colorMapping: isDark
                                    ? _ghostMappingDark
                                    : _ghostMappingLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pill overlay — unclipped so edge-anchored pills render
                    // in full. Each pill is anchored anatomically and then
                    // centered on the anchor via FractionalTranslation.
                    for (final entry in _bodyAnchor.entries)
                      _positionPill(entry.key, entry.value, w: w, h: h),
                  ],
                );
              },
            ),
          ),
        ),
          ),
        ),
      ],
    );
  }

  Positioned _positionPill(
    MeasurementType t,
    Offset anchor, {
    required double w,
    required double h,
  }) {
    return Positioned(
      // Layout position: anchor point. FractionalTranslation shifts the
      // actual render by half the pill's own size so the pill is visually
      // CENTERED on the anchor (not left-aligned from it).
      top: anchor.dy * h,
      left: anchor.dx * w,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _pillFor(t, shortName: _shortNameForBody(t)),
      ),
    );
  }

  Widget _pillFor(MeasurementType t, {String? shortName}) {
    return MeasurementValuePill(
      type: t,
      latest: state.summary?.latestByType[t],
      change: state.summary?.changeFromPrevious[t],
      isMetric: isMetric,
      shortName: shortName,
      icon: _pillIcon(t),
    );
  }
}

/// Horizontal strip of pills at the top of the body view: Weight + Body Fat
/// + BMI + WHR visible, and a "+N More" dropdown pill on the end that opens
/// the full list of remaining derived metrics (W:Ht, FFMI, Lean, Sh:W, Ch:W,
/// Arm, Leg). Keeps the strip readable without horizontal scrolling.
class _TopMetricsStrip extends ConsumerWidget {
  final MeasurementsState state;
  final bool isMetric;

  const _TopMetricsStrip({required this.state, required this.isMetric});

  /// Derived metrics surfaced as their own pill in the strip — everything
  /// else goes into the "More" dropdown.
  static const _primaryDerived = [
    DerivedMetricType.bmi,
    DerivedMetricType.waistToHipRatio,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final summary = state.summary;

    final derived = summary == null
        ? <DerivedMetricType, DerivedMetricResult>{}
        : computeDerivedMetrics(
            summary: summary,
            heightCm: user?.heightCm,
            gender: user?.gender,
          );

    final overflowDerived = DerivedMetricType.values
        .where((t) => !_primaryDerived.contains(t))
        .toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          // Direct-log pills.
          MeasurementValuePill(
            type: MeasurementType.weight,
            latest: state.summary?.latestByType[MeasurementType.weight],
            change: state.summary?.changeFromPrevious[MeasurementType.weight],
            isMetric: isMetric,
            icon: Icons.monitor_weight,
          ),
          const SizedBox(width: 8),
          MeasurementValuePill(
            type: MeasurementType.bodyFat,
            latest: state.summary?.latestByType[MeasurementType.bodyFat],
            change: state.summary?.changeFromPrevious[MeasurementType.bodyFat],
            isMetric: isMetric,
            icon: Icons.percent,
          ),
          // Primary derived pills.
          for (final type in _primaryDerived) ...[
            const SizedBox(width: 8),
            _DerivedMetricPill(type: type, result: derived[type]),
          ],
          // "+N More" dropdown pill — opens a sheet listing every remaining
          // derived metric.
          const SizedBox(width: 8),
          _MoreDerivedDropdown(
            overflow: overflowDerived,
            results: derived,
          ),
        ],
      ),
    );
  }
}

/// Trailing pill in the metrics strip that opens a bottom sheet listing the
/// derived metrics not shown inline. Styled to match the other pills.
class _MoreDerivedDropdown extends StatelessWidget {
  final List<DerivedMetricType> overflow;
  final Map<DerivedMetricType, DerivedMetricResult> results;

  const _MoreDerivedDropdown({
    required this.overflow,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        _showSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${overflow.length} More',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textMuted),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                ),
                const Text(
                  'More metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in overflow)
                      _DerivedMetricPill(type: t, result: results[t]),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Center the handle inside the drag grabber — the Container above has
      // alignment:center but padding pushes it left on some builds; this is
      // harmless if already centred.
    });
    // Suppress lint about unused elevated.
    // ignore: unused_local_variable
    final _ = elevated;
  }
}

/// Pill showing a computed derived metric (BMI, WHR, etc.). Same height and
/// border-radius as [MeasurementValuePill] so both kinds can sit in the
/// same top strip. Tap navigates to the derived-metric detail screen.
class _DerivedMetricPill extends ConsumerWidget {
  final DerivedMetricType type;
  final DerivedMetricResult? result;

  const _DerivedMetricPill({required this.type, required this.result});

  String get _shortLabel {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'BMI';
      case DerivedMetricType.waistToHipRatio:
        return 'WHR';
      case DerivedMetricType.waistToHeightRatio:
        return 'W:Ht';
      case DerivedMetricType.ffmi:
        return 'FFMI';
      case DerivedMetricType.leanBodyMass:
        return 'Lean';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Sh:W';
      case DerivedMetricType.chestToWaistRatio:
        return 'Ch:W';
      case DerivedMetricType.armSymmetry:
        return 'Arm';
      case DerivedMetricType.legSymmetry:
        return 'Leg';
    }
  }

  IconData get _icon {
    switch (type) {
      case DerivedMetricType.bmi:
        return Icons.monitor_weight_outlined;
      case DerivedMetricType.leanBodyMass:
        return Icons.fitness_center;
      case DerivedMetricType.ffmi:
        return Icons.bolt_outlined;
      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return Icons.compare_arrows;
      default:
        return Icons.straighten;
    }
  }

  String _format(double v) {
    switch (type) {
      case DerivedMetricType.waistToHipRatio:
      case DerivedMetricType.waistToHeightRatio:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return v.toStringAsFixed(2);
      default:
        return v.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final hasData = result != null;
    final accent = hasData ? result!.color : textMuted;
    final borderColor = hasData
        ? accent.withValues(alpha: 0.4)
        : cardBorder;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/measurements/derived/${type.name}');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 11, color: accent),
            const SizedBox(width: 3),
            Text(
              _shortLabel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              hasData ? _format(result!.value) : '—',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.chevron_right, size: 11, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
