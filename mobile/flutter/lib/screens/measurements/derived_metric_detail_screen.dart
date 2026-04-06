import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';


part 'derived_metric_detail_screen_part_derived_metric_type.dart';
part 'derived_metric_detail_screen_part_stat_item.dart';

part 'derived_metric_detail_screen_ui.dart';

part 'derived_metric_detail_screen_ext.dart';
part 'derived_metric_detail_screen_helpers.dart';


/// Detail screen for a derived body metric (BMI, WHR, FFMI, etc.)
/// Shows historical trend chart with health zone lines, stats, and context.
class DerivedMetricDetailScreen extends ConsumerStatefulWidget {
  final String derivedType;

  const DerivedMetricDetailScreen({
    super.key,
    required this.derivedType,
  });

  @override
  ConsumerState<DerivedMetricDetailScreen> createState() =>
      _DerivedMetricDetailScreenState();
}

class _DerivedMetricDetailScreenState
    extends ConsumerState<DerivedMetricDetailScreen> {
  String _selectedPeriod = '30d';
  late DerivedMetricType _type;

  final _periods = [
    {'label': '7D', 'value': '7d', 'days': 7},
    {'label': '30D', 'value': '30d', 'days': 30},
    {'label': '90D', 'value': '90d', 'days': 90},
    {'label': 'All', 'value': 'all', 'days': 365},
  ];

  @override
  void initState() {
    super.initState();
    _type = _parseType(widget.derivedType);
    _loadMeasurements();
  }

  @override
  Widget build(BuildContext context) {
    final measurementsState = ref.watch(measurementsProvider);
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final heightCm = auth.user?.heightCm;
    final gender = auth.user?.gender;

    final history = _computeHistory(
      measurementsState.historyByType,
      _type,
      heightCm,
    );
    final filteredHistory = _filterByPeriod(history);

    final currentValue = measurementsState.summary != null
        ? _computeCurrentValue(
            measurementsState.summary!,
            _type,
            heightCm,
            gender,
          )
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: _loadMeasurements,
              color: cyan,
              child: CustomScrollView(
                slivers: [
                  // Header with title (offset for floating back button)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 12, 16, 8),
                      child: Text(
                        _getDisplayName(_type),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                    ),
                  ),

                  // Current value card
                  SliverToBoxAdapter(
                    child: _buildCurrentValueCard(
                      currentValue: currentValue,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 100.ms),
                  ),

                  // Period selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected =
                              _selectedPeriod == period['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedPeriod = period['value'] as String),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cyan.withOpacity(0.2)
                                      : elevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? cyan : cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    period['label'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected ? cyan : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ),

                  // Trend chart with health zone lines
                  SliverToBoxAdapter(
                    child: _buildChartSection(
                      filteredHistory,
                      gender: gender,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 200.ms),
                  ),

                  // Stats row: Min / Avg / Max
                  SliverToBoxAdapter(
                    child: _buildStatsSection(
                      filteredHistory,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 250.ms),
                  ),

                  // Rate of change
                  SliverToBoxAdapter(
                    child: _buildRateOfChange(
                      filteredHistory,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 300.ms),
                  ),

                  // Health context card
                  if (currentValue != null)
                    SliverToBoxAdapter(
                      child: _buildHealthContextCard(
                        currentValue: currentValue,
                        isDark: isDark,
                        elevated: elevated,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        cyan: cyan,
                      ).animate().fadeIn(delay: 350.ms),
                    ),

                  // Input values card ("Based On")
                  SliverToBoxAdapter(
                    child: _buildInputValuesCard(
                      measurementsState: measurementsState,
                      heightCm: heightCm,
                      isDark: isDark,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      cyan: cyan,
                    ).animate().fadeIn(delay: 400.ms),
                  ),

                  // History header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HISTORY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${filteredHistory.length} entries',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                  ),

                  // History list
                  _buildHistoryList(
                    filteredHistory,
                    isDark: isDark,
                    elevated: elevated,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cyan: cyan,
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Floating back button
            Positioned(
              top: 8,
              left: 8,
              child: GlassBackButton(
                onTap: () {
                  HapticService.light();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // Data Computation Helpers
  // ═════════════════════════════════════════════════════════════════

  /// Compute historical derived metric values from raw measurement data.
  /// Returns entries sorted oldest-first for charting.
  List<({DateTime date, double value})> _computeHistory(
    Map<MeasurementType, List<MeasurementEntry>> historyByType,
    DerivedMetricType type,
    double? heightCm,
  ) {
    final results = <({DateTime date, double value})>[];

    switch (type) {
      case DerivedMetricType.bmi:
        // BMI is stored on weight entries
        final weightEntries = historyByType[MeasurementType.weight] ?? [];
        for (final entry in weightEntries) {
          if (entry.bmi != null) {
            results.add((date: entry.recordedAt, value: entry.bmi!));
          } else if (heightCm != null && heightCm > 0) {
            final heightM = heightCm / 100;
            final weightKg = entry.getValueInUnit(true);
            results.add(
              (date: entry.recordedAt, value: weightKg / (heightM * heightM)),
            );
          }
        }
        break;

      case DerivedMetricType.waistToHipRatio:
        // WHR is stored on waist entries
        final waistEntries = historyByType[MeasurementType.waist] ?? [];
        for (final entry in waistEntries) {
          if (entry.waistToHipRatio != null) {
            results
                .add((date: entry.recordedAt, value: entry.waistToHipRatio!));
          }
        }
        // Also try pairing waist + hips on same date
        if (results.isEmpty) {
          _addPairedHistory(
            results,
            historyByType[MeasurementType.waist] ?? [],
            historyByType[MeasurementType.hips] ?? [],
            (waist, hips) => hips > 0 ? waist / hips : null,
          );
        }
        break;

      case DerivedMetricType.waistToHeightRatio:
        // WHtR is stored on waist entries
        final waistEntries = historyByType[MeasurementType.waist] ?? [];
        for (final entry in waistEntries) {
          if (entry.waistToHeightRatio != null) {
            results.add(
                (date: entry.recordedAt, value: entry.waistToHeightRatio!));
          }
        }
        // Also try computing from waist + height
        if (results.isEmpty && heightCm != null && heightCm > 0) {
          for (final entry in waistEntries) {
            final waistCm = entry.getValueInUnit(true);
            results.add((date: entry.recordedAt, value: waistCm / heightCm));
          }
        }
        break;

      case DerivedMetricType.ffmi:
        if (heightCm == null || heightCm <= 0) break;
        final heightM = heightCm / 100;
        _addPairedHistory(
          results,
          historyByType[MeasurementType.weight] ?? [],
          historyByType[MeasurementType.bodyFat] ?? [],
          (weightKg, bodyFat) {
            if (bodyFat <= 0 || bodyFat >= 100) return null;
            final leanMass = weightKg * (1 - bodyFat / 100);
            return leanMass / (heightM * heightM) + 6.1 * (1.8 - heightM);
          },
        );
        break;

      case DerivedMetricType.leanBodyMass:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.weight] ?? [],
          historyByType[MeasurementType.bodyFat] ?? [],
          (weightKg, bodyFat) {
            if (bodyFat <= 0 || bodyFat >= 100) return null;
            return weightKg * (1 - bodyFat / 100);
          },
        );
        break;

      case DerivedMetricType.shoulderToWaistRatio:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.shoulders] ?? [],
          historyByType[MeasurementType.waist] ?? [],
          (shoulders, waist) => waist > 0 ? shoulders / waist : null,
        );
        break;

      case DerivedMetricType.chestToWaistRatio:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.chest] ?? [],
          historyByType[MeasurementType.waist] ?? [],
          (chest, waist) => waist > 0 ? chest / waist : null,
        );
        break;

      case DerivedMetricType.armSymmetry:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.bicepsLeft] ?? [],
          historyByType[MeasurementType.bicepsRight] ?? [],
          (left, right) {
            if (left <= 0 || right <= 0) return null;
            final larger = left > right ? left : right;
            final smaller = left > right ? right : left;
            return (smaller / larger) * 100; // percentage symmetry
          },
        );
        break;

      case DerivedMetricType.legSymmetry:
        _addPairedHistory(
          results,
          historyByType[MeasurementType.thighLeft] ?? [],
          historyByType[MeasurementType.thighRight] ?? [],
          (left, right) {
            if (left <= 0 || right <= 0) return null;
            final larger = left > right ? left : right;
            final smaller = left > right ? right : left;
            return (smaller / larger) * 100; // percentage symmetry
          },
        );
        break;
    }

    // Sort oldest first for charting
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  /// Helper: pairs two measurement lists by same-day date and computes a value.
  void _addPairedHistory(
    List<({DateTime date, double value})> results,
    List<MeasurementEntry> listA,
    List<MeasurementEntry> listB,
    double? Function(double a, double b) compute,
  ) {
    // Build a map of date (day-only) -> metric value for listB
    final bByDate = <String, MeasurementEntry>{};
    for (final entry in listB) {
      final key = DateFormat('yyyy-MM-dd').format(entry.recordedAt);
      bByDate.putIfAbsent(key, () => entry);
    }

    for (final entryA in listA) {
      final key = DateFormat('yyyy-MM-dd').format(entryA.recordedAt);
      final entryB = bByDate[key];
      if (entryB != null) {
        final valueA = entryA.getValueInUnit(true);
        final valueB = entryB.getValueInUnit(true);
        final computed = compute(valueA, valueB);
        if (computed != null && computed.isFinite) {
          results.add((date: entryA.recordedAt, value: computed));
        }
      }
    }
  }

  /// Compute the current derived metric value from the latest summary data.
  ({double value, String label, Color color, String info})? _computeCurrentValue(
    MeasurementsSummary summary,
    DerivedMetricType type,
    double? heightCm,
    String? gender,
  ) {
    final isMale = gender?.toLowerCase() == 'male';

    switch (type) {
      case DerivedMetricType.bmi:
        final weight = summary.latestByType[MeasurementType.weight];
        if (weight == null || heightCm == null || heightCm <= 0) return null;
        final heightM = heightCm / 100;
        final bmi = weight.getValueInUnit(true) / (heightM * heightM);
        final cat = _getBmiCategory(bmi);
        return (value: bmi, label: cat.label, color: cat.color, info: cat.info);

      case DerivedMetricType.waistToHipRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        final hips = summary.latestByType[MeasurementType.hips];
        if (waist == null || hips == null) return null;
        final waistCm = waist.getValueInUnit(true);
        final hipsCm = hips.getValueInUnit(true);
        if (hipsCm <= 0) return null;
        final whr = waistCm / hipsCm;
        final cat = _getWhrCategory(whr, isMale: isMale);
        return (value: whr, label: cat.label, color: cat.color, info: cat.info);

      case DerivedMetricType.waistToHeightRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        if (waist == null || heightCm == null || heightCm <= 0) return null;
        final whtr = waist.getValueInUnit(true) / heightCm;
        final cat = _getWhtrCategory(whtr);
        return (
          value: whtr,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.ffmi:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight == null ||
            bodyFat == null ||
            heightCm == null ||
            heightCm <= 0) return null;
        final weightKg = weight.getValueInUnit(true);
        final bf = bodyFat.value;
        if (bf <= 0 || bf >= 100) return null;
        final heightM = heightCm / 100;
        final leanMass = weightKg * (1 - bf / 100);
        final ffmi =
            leanMass / (heightM * heightM) + 6.1 * (1.8 - heightM);
        final cat = _getFfmiCategory(ffmi, isMale: isMale);
        return (
          value: ffmi,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.leanBodyMass:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight == null || bodyFat == null) return null;
        final weightKg = weight.getValueInUnit(true);
        final bf = bodyFat.value;
        if (bf <= 0 || bf >= 100) return null;
        final lbm = weightKg * (1 - bf / 100);
        return (
          value: lbm,
          label: 'Lean Mass',
          color: AppColors.success,
          info:
              'Your lean body mass is the total weight minus fat. Higher lean mass generally indicates more muscle.',
        );

      case DerivedMetricType.shoulderToWaistRatio:
        final shoulders = summary.latestByType[MeasurementType.shoulders];
        final waist = summary.latestByType[MeasurementType.waist];
        if (shoulders == null || waist == null) return null;
        final ratio =
            shoulders.getValueInUnit(true) / waist.getValueInUnit(true);
        if (!ratio.isFinite) return null;
        final cat = _getShoulderWaistCategory(ratio, isMale: isMale);
        return (
          value: ratio,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.chestToWaistRatio:
        final chest = summary.latestByType[MeasurementType.chest];
        final waist = summary.latestByType[MeasurementType.waist];
        if (chest == null || waist == null) return null;
        final ratio =
            chest.getValueInUnit(true) / waist.getValueInUnit(true);
        if (!ratio.isFinite) return null;
        final cat = _getChestWaistCategory(ratio);
        return (
          value: ratio,
          label: cat.label,
          color: cat.color,
          info: cat.info
        );

      case DerivedMetricType.armSymmetry:
        final left = summary.latestByType[MeasurementType.bicepsLeft];
        final right = summary.latestByType[MeasurementType.bicepsRight];
        if (left == null || right == null) return null;
        final l = left.getValueInUnit(true);
        final r = right.getValueInUnit(true);
        if (l <= 0 || r <= 0) return null;
        final larger = l > r ? l : r;
        final smaller = l > r ? r : l;
        final symmetry = (smaller / larger) * 100;
        final cat = _getSymmetryCategory(symmetry);
        return (
          value: symmetry,
          label: cat.label,
          color: cat.color,
          info:
              'Arm symmetry compares your left and right bicep measurements. ${cat.info}',
        );

      case DerivedMetricType.legSymmetry:
        final left = summary.latestByType[MeasurementType.thighLeft];
        final right = summary.latestByType[MeasurementType.thighRight];
        if (left == null || right == null) return null;
        final l = left.getValueInUnit(true);
        final r = right.getValueInUnit(true);
        if (l <= 0 || r <= 0) return null;
        final larger = l > r ? l : r;
        final smaller = l > r ? r : l;
        final symmetry = (smaller / larger) * 100;
        final cat = _getSymmetryCategory(symmetry);
        return (
          value: symmetry,
          label: cat.label,
          color: cat.color,
          info:
              'Leg symmetry compares your left and right thigh measurements. ${cat.info}',
        );
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // Category & Threshold Helpers
  // ═════════════════════════════════════════════════════════════════

  ({String label, Color color, String info}) _getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return (
        label: 'Underweight',
        color: AppColors.orange,
        info:
            'A BMI below 18.5 is considered underweight. Consider consulting a healthcare professional about nutrition strategies.',
      );
    } else if (bmi < 25) {
      return (
        label: 'Normal',
        color: AppColors.success,
        info:
            'A BMI between 18.5 and 24.9 is considered a healthy weight range. Keep up the good work!',
      );
    } else if (bmi < 30) {
      return (
        label: 'Overweight',
        color: AppColors.orange,
        info:
            'A BMI between 25 and 29.9 is considered overweight. Note: BMI does not differentiate muscle from fat.',
      );
    } else {
      return (
        label: 'Obese',
        color: AppColors.error,
        info:
            'A BMI of 30 or above is classified as obese. Consider consulting a healthcare professional for guidance.',
      );
    }
  }

  ({String label, Color color, String info}) _getWhrCategory(double whr,
      {bool isMale = true}) {
    if (isMale) {
      if (whr < 0.90) {
        return (
          label: 'Low Risk',
          color: AppColors.success,
          info:
              'A WHR below 0.90 for men indicates low cardiovascular risk. WHO considers this a healthy range.',
        );
      } else if (whr < 1.0) {
        return (
          label: 'Moderate Risk',
          color: AppColors.orange,
          info:
              'A WHR between 0.90 and 1.0 for men indicates moderate health risk. Focus on waist-reducing exercises.',
        );
      } else {
        return (
          label: 'High Risk',
          color: AppColors.error,
          info:
              'A WHR above 1.0 for men indicates increased cardiovascular risk. Consider lifestyle changes.',
        );
      }
    } else {
      if (whr < 0.80) {
        return (
          label: 'Low Risk',
          color: AppColors.success,
          info:
              'A WHR below 0.80 for women indicates low cardiovascular risk. WHO considers this a healthy range.',
        );
      } else if (whr < 0.85) {
        return (
          label: 'Moderate Risk',
          color: AppColors.orange,
          info:
              'A WHR between 0.80 and 0.85 for women indicates moderate health risk. Focus on waist-reducing exercises.',
        );
      } else {
        return (
          label: 'High Risk',
          color: AppColors.error,
          info:
              'A WHR above 0.85 for women indicates increased cardiovascular risk. Consider lifestyle changes.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getWhtrCategory(double whtr) {
    if (whtr < 0.4) {
      return (
        label: 'Underweight',
        color: AppColors.orange,
        info:
            'A WHtR below 0.4 may indicate being underweight. Consider consulting a healthcare professional.',
      );
    } else if (whtr < 0.5) {
      return (
        label: 'Healthy',
        color: AppColors.success,
        info:
            'A WHtR between 0.4 and 0.5 is considered healthy. Your waist is less than half your height.',
      );
    } else if (whtr < 0.6) {
      return (
        label: 'Overweight',
        color: AppColors.orange,
        info:
            'A WHtR between 0.5 and 0.6 indicates increased abdominal fat. Focus on reducing waist circumference.',
      );
    } else {
      return (
        label: 'Obese',
        color: AppColors.error,
        info:
            'A WHtR above 0.6 indicates significant abdominal fat and increased health risk.',
      );
    }
  }

  ({String label, Color color, String info}) _getFfmiCategory(double ffmi,
      {bool isMale = true}) {
    if (isMale) {
      if (ffmi < 18) {
        return (
          label: 'Below Average',
          color: AppColors.orange,
          info:
              'An FFMI below 18 for men is below average. Focus on progressive overload and adequate protein.',
        );
      } else if (ffmi < 20) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'An FFMI of 18-20 for men is average. You have a solid foundation of muscle.',
        );
      } else if (ffmi < 22) {
        return (
          label: 'Above Average',
          color: AppColors.success,
          info:
              'An FFMI of 20-22 for men is above average. You have notably more muscle than most.',
        );
      } else if (ffmi < 25) {
        return (
          label: 'Excellent',
          color: AppColors.info,
          info:
              'An FFMI of 22-25 for men is excellent, near the natural limit. Outstanding muscular development.',
        );
      } else {
        return (
          label: 'Superior',
          color: AppColors.purple,
          info:
              'An FFMI above 25 for men exceeds the typical natural limit (~25). Exceptional muscularity.',
        );
      }
    } else {
      if (ffmi < 14) {
        return (
          label: 'Below Average',
          color: AppColors.orange,
          info:
              'An FFMI below 14 for women is below average. Focus on resistance training and nutrition.',
        );
      } else if (ffmi < 16) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'An FFMI of 14-16 for women is average. You have a solid foundation of muscle.',
        );
      } else if (ffmi < 18) {
        return (
          label: 'Above Average',
          color: AppColors.success,
          info:
              'An FFMI of 16-18 for women is above average. Impressive muscular development.',
        );
      } else if (ffmi < 21) {
        return (
          label: 'Excellent',
          color: AppColors.info,
          info:
              'An FFMI of 18-21 for women is excellent. Outstanding lean mass for your height.',
        );
      } else {
        return (
          label: 'Superior',
          color: AppColors.purple,
          info:
              'An FFMI above 21 for women is exceptional. Elite-level muscularity.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getShoulderWaistCategory(
      double ratio,
      {bool isMale = true}) {
    if (isMale) {
      if (ratio < 1.4) {
        return (
          label: 'Narrow',
          color: AppColors.orange,
          info:
              'A shoulder-to-waist ratio below 1.4 for men indicates a narrow frame. Target shoulder exercises to build width.',
        );
      } else if (ratio < 1.6) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'A shoulder-to-waist ratio of 1.4-1.6 for men is average. Good overall proportions.',
        );
      } else {
        return (
          label: 'V-Taper',
          color: AppColors.info,
          info:
              'A shoulder-to-waist ratio above 1.6 for men indicates a strong V-taper. Excellent aesthetics!',
        );
      }
    } else {
      if (ratio < 1.3) {
        return (
          label: 'Narrow',
          color: AppColors.orange,
          info:
              'A shoulder-to-waist ratio below 1.3 for women indicates narrower shoulders relative to waist.',
        );
      } else if (ratio < 1.5) {
        return (
          label: 'Average',
          color: AppColors.success,
          info:
              'A shoulder-to-waist ratio of 1.3-1.5 for women is average. Well-balanced proportions.',
        );
      } else {
        return (
          label: 'Athletic',
          color: AppColors.info,
          info:
              'A shoulder-to-waist ratio above 1.5 for women indicates athletic build with broader shoulders.',
        );
      }
    }
  }

  ({String label, Color color, String info}) _getChestWaistCategory(
      double ratio) {
    if (ratio < 1.1) {
      return (
        label: 'Narrow',
        color: AppColors.orange,
        info:
            'A chest-to-waist ratio below 1.1 indicates a narrow chest relative to waist. Focus on chest and back exercises.',
      );
    } else if (ratio < 1.3) {
      return (
        label: 'Average',
        color: AppColors.success,
        info:
            'A chest-to-waist ratio of 1.1-1.3 is average. Healthy proportions between chest and waist.',
      );
    } else {
      return (
        label: 'Athletic',
        color: AppColors.info,
        info:
            'A chest-to-waist ratio above 1.3 indicates a well-developed chest relative to waist. Great proportions!',
      );
    }
  }

  ({String label, Color color, String info}) _getSymmetryCategory(
      double symmetry) {
    if (symmetry >= 97) {
      return (
        label: 'Excellent',
        color: AppColors.success,
        info:
            'Near-perfect symmetry (97%+). Both sides are very well balanced.',
      );
    } else if (symmetry >= 93) {
      return (
        label: 'Good',
        color: AppColors.success,
        info:
            'Good symmetry (93-97%). Minor difference that is within normal range.',
      );
    } else if (symmetry >= 88) {
      return (
        label: 'Moderate',
        color: AppColors.orange,
        info:
            'Moderate asymmetry (88-93%). Consider adding unilateral exercises to address the imbalance.',
      );
    } else {
      return (
        label: 'Imbalanced',
        color: AppColors.error,
        info:
            'Significant asymmetry (below 88%). Focus on unilateral training for the weaker side.',
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════
}
