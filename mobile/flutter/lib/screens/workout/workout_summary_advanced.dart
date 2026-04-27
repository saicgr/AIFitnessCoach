import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';

class WorkoutSummaryAdvanced extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final double topPadding;

  const WorkoutSummaryAdvanced({
    super.key,
    this.data,
    this.metadata,
    this.topPadding = 0,
  });

  // ── helpers ──────────────────────────────────────────────────────

  bool get _hasMetadata => metadata != null && metadata!.isNotEmpty;

  // ── build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasSetLogs = data != null && data!.setLogs.isNotEmpty;

    // If no metadata, no comparison, and no set logs, show info banner
    if (!_hasMetadata && data?.performanceComparison == null && !hasSetLogs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _InfoBanner(isDark: isDark),
        ),
      );
    }

    // ── Magazine layout: hero sections first, dense "Details" collapsed ──
    final heroSections = <Widget>[];
    int delay = 0;

    // 1. Coach narrative hero card (punchy one-liner).
    heroSections.add(
      _CoachHeroCard(
        heroNarrative: data?.heroNarrative,
        coachSummary: data?.coachSummary,
        isDark: isDark,
      ).animate().fadeIn(
          duration: 400.ms, delay: Duration(milliseconds: delay)),
    );
    delay += 80;

    // 2. KPI tiles (Volume · TOP 1RM · PRs · Avg RIR) — 2×2 grid.
    heroSections.add(
      _KpiTileRow(
        tiles: _buildKpiTiles(
          data: data,
          metadata: metadata,
          isDark: isDark,
        ),
        isDark: isDark,
      ).animate().fadeIn(
          duration: 400.ms, delay: Duration(milliseconds: delay)),
    );
    delay += 80;

    // 3. Session Score concentric rings (replaces the 3-donut row).
    // Rings map: outer = plan adherence, middle = intensity coverage,
    // inner = rest compliance. Center shows the composite score.
    heroSections.add(
      _SessionScoreRings(
        data: data,
        metadata: metadata,
        isDark: isDark,
      ).animate().fadeIn(
          duration: 400.ms, delay: Duration(milliseconds: delay)),
    );
    delay += 80;

    // 4. Session timeline + muscle heatmap (side-by-side card).
    if (_hasMetadata) {
      heroSections.add(
        _SessionTimelineAndHeatmap(
          data: data,
          metadata: metadata,
          isDark: isDark,
        ).animate().fadeIn(
            duration: 400.ms, delay: Duration(milliseconds: delay)),
      );
      delay += 80;
    }

    // 5. Per-Exercise Pyramid Deep Dive.
    if (_hasMetadata) {
      final setsJson = _castList(metadata!['sets_json'])
          .where((s) {
            final name = s['exercise_name'] as String?;
            return name != null && name.isNotEmpty && name != 'Unknown';
          })
          .toList();
      if (setsJson.isNotEmpty) {
        heroSections.add(
          _PyramidDeepDiveSection(
            setsJson: setsJson,
            isDark: isDark,
          ).animate().fadeIn(
              duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }
    }

    // ── Everything else tucked under "More details" ─────────────────────
    final detailSections = <Widget>[];
    if (data?.performanceComparison != null &&
        data!.performanceComparison!.workoutComparison.hasPrevious) {
      detailSections.add(
        _PerformanceComparisonSection(
          comparison: data!.performanceComparison!,
          isDark: isDark,
        ),
      );
    }
    if (_hasMetadata) {
      final meta = metadata!;
      final supersets = _castList(meta['supersets']);
      if (supersets.isNotEmpty) {
        detailSections
            .add(_SupersetDetailsSection(supersets: supersets, isDark: isDark));
      }
      final exerciseOrder = _castList(meta['exercise_order']);
      if (exerciseOrder.isNotEmpty) {
        detailSections.add(
            _ExerciseOrderSection(exercises: exerciseOrder, isDark: isDark));
      }
      final quitEarly = meta['quit_early'] as bool? ??
          (data?.completionMethod == 'quit_early');
      if (quitEarly) {
        detailSections
            .add(_WorkoutExitStatsSection(metadata: meta, isDark: isDark));
      }
      final warmupExercises = _castList(meta['warmup_exercises']);
      final stretchExercises = _castList(meta['stretch_exercises']);
      final warmupStatus = meta['warmup_status'] as String?;
      final stretchStatus = meta['stretch_status'] as String?;
      if (warmupExercises.isNotEmpty ||
          stretchExercises.isNotEmpty ||
          warmupStatus != null ||
          stretchStatus != null) {
        detailSections.add(_WarmupStretchSection(
          warmupExercises: warmupExercises,
          stretchExercises: stretchExercises,
          warmupStatus: warmupStatus,
          stretchStatus: stretchStatus,
          isDark: isDark,
        ));
      }
      final restIntervals = _castList(meta['rest_intervals']);
      if (restIntervals.isNotEmpty) {
        detailSections.add(
            _RestAnalysisSection(intervals: restIntervals, isDark: isDark));
      }
      final drinkEvents = _castList(meta['drink_events']);
      final drinkIntake = meta['drink_intake_ml'] as int?;
      if (drinkEvents.isNotEmpty || (drinkIntake != null && drinkIntake > 0)) {
        detailSections.add(_HydrationSection(
          drinkEvents: drinkEvents,
          totalMl: drinkIntake ?? 0,
          isDark: isDark,
        ));
      }
      final aiInteractions = meta['ai_interactions'] as Map<String, dynamic>?;
      if (aiInteractions != null && aiInteractions.isNotEmpty) {
        detailSections.add(
            _AIInteractionsSection(interactions: aiInteractions, isDark: isDark));
      }
      final feedback = meta['subjective_feedback'] as Map<String, dynamic>?;
      if (feedback != null && feedback.isNotEmpty) {
        detailSections.add(
            _SubjectiveFeedbackSection(feedback: feedback, isDark: isDark));
      }
      final incrementSettings =
          meta['increment_settings'] as Map<String, dynamic>?;
      if (incrementSettings != null && incrementSettings.isNotEmpty) {
        detailSections.add(
            _SettingsUsedSection(settings: incrementSettings, isDark: isDark));
      }
    }
    if (hasSetLogs) {
      final logs = data!.setLogs;
      final workingSets = logs.where((l) => l.setType == 'working').toList();
      if (workingSets.isNotEmpty) {
        detailSections.add(
            _VolumeBreakdownSection(setLogs: workingSets, isDark: isDark));
      }
      final logsWithRpe = workingSets.where((l) => l.rpe != null).toList();
      final logsWithRir = workingSets.where((l) => l.rir != null).toList();
      if (logsWithRpe.isNotEmpty || logsWithRir.isNotEmpty) {
        detailSections.add(
            _IntensityAnalysisSection(setLogs: workingSets, isDark: isDark));
      }
      if (workingSets.any((l) => l.weightKg > 0 && l.repsCompleted > 0)) {
        detailSections.add(
            _Estimated1RMSection(setLogs: workingSets, isDark: isDark));
      }
      if (logs.length > 1) {
        detailSections.add(
            _SetTypeDistributionSection(setLogs: logs, isDark: isDark));
      }
    }

    if (heroSections.isEmpty && detailSections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _InfoBanner(isDark: isDark),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topPadding + 56, 16, 8),
      child: Column(
        children: [
          for (int i = 0; i < heroSections.length; i++) ...[
            heroSections[i],
            if (i < heroSections.length - 1) const SizedBox(height: 12),
          ],
          if (detailSections.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CollapsibleDetails(
              sections: detailSections,
              isDark: isDark,
            ).animate().fadeIn(
                duration: 400.ms, delay: Duration(milliseconds: delay)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _castList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared section card wrapper
// ═══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 15, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 1. Performance Comparison
// ═══════════════════════════════════════════════════════════════════

class _PerformanceComparisonSection extends StatelessWidget {
  final PerformanceComparisonInfo comparison;
  final bool isDark;

  const _PerformanceComparisonSection({
    required this.comparison,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final wc = comparison.workoutComparison;
    final days = wc.previousPerformedAt != null
        ? DateTime.now().difference(wc.previousPerformedAt!).inDays
        : 0;

    return _SectionCard(
      isDark: isDark,
      icon: Icons.compare_arrows,
      title: 'Performance Comparison',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wc.hasPrevious && days > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'vs $days days ago',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),

          // Stat rows
          if (wc.hasPrevious) ...[
            _ComparisonRow(
              label: 'Volume',
              current: '${(wc.currentTotalVolumeKg * 2.20462).toStringAsFixed(0)} lb',
              previous: wc.previousTotalVolumeKg != null
                  ? '${(wc.previousTotalVolumeKg! * 2.20462).toStringAsFixed(0)} lb'
                  : '-',
              diffPercent: wc.volumeDiffPercent,
              isDark: isDark,
            ),
            _ComparisonRow(
              label: 'Duration',
              current: _fmtDuration(wc.currentDurationSeconds),
              previous: wc.previousDurationSeconds != null
                  ? _fmtDuration(wc.previousDurationSeconds!)
                  : '-',
              diffPercent: wc.durationDiffPercent,
              isDark: isDark,
            ),
            _ComparisonRow(
              label: 'Sets',
              current: '${wc.currentTotalSets}',
              previous: wc.previousTotalSets != null ? '${wc.previousTotalSets}' : '-',
              diffPercent: null,
              isDark: isDark,
            ),
            _ComparisonRow(
              label: 'Reps',
              current: '${wc.currentTotalReps}',
              previous: wc.previousTotalReps != null ? '${wc.previousTotalReps}' : '-',
              diffPercent: null,
              isDark: isDark,
            ),
          ],

          if (comparison.exerciseComparisons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Per Exercise',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: comparison.exerciseComparisons.map((e) {
                final color = _statusColor(e.status);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(e.status), size: 13, color: color),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          e.exerciseName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (e.formattedPercentDiff.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          e.formattedPercentDiff,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'improved':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'improved':
        return Icons.trending_up;
      case 'declined':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String current;
  final String previous;
  final double? diffPercent;
  final bool isDark;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.diffPercent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = diffPercent != null && diffPercent! > 0;
    final isNegative = diffPercent != null && diffPercent! < 0;
    final diffColor = isPositive
        ? AppColors.success
        : isNegative
            ? AppColors.error
            : (isDark ? AppColors.textMuted : AppColorsLight.textMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              current,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
          ),
          Icon(Icons.arrow_back, size: 10, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
          const SizedBox(width: 4),
          SizedBox(
            width: 64,
            child: Text(
              previous,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          if (diffPercent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${diffPercent! >= 0 ? '+' : ''}${diffPercent!.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: diffColor),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 2. Warmup & Stretch
// ═══════════════════════════════════════════════════════════════════

class _WarmupStretchSection extends StatelessWidget {
  final List<Map<String, dynamic>> warmupExercises;
  final List<Map<String, dynamic>> stretchExercises;
  final String? warmupStatus;
  final String? stretchStatus;
  final bool isDark;

  const _WarmupStretchSection({
    required this.warmupExercises,
    required this.stretchExercises,
    this.warmupStatus,
    this.stretchStatus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.accessibility_new,
      title: 'Warmup & Stretching',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warmup sub-section
          if (warmupStatus != null || warmupExercises.isNotEmpty) ...[
            _SubHeader(label: 'Warmup', status: warmupStatus, isDark: isDark),
            ...warmupExercises.map((e) => _ExerciseTile(exercise: e, isDark: isDark)),
            if (stretchExercises.isNotEmpty || stretchStatus != null) const SizedBox(height: 10),
          ],

          // Stretch sub-section
          if (stretchStatus != null || stretchExercises.isNotEmpty) ...[
            _SubHeader(label: 'Stretching', status: stretchStatus, isDark: isDark),
            ...stretchExercises.map((e) => _ExerciseTile(exercise: e, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String label;
  final String? status;
  final bool isDark;

  const _SubHeader({required this.label, this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            _StatusBadge(status: status!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    final color = isCompleted ? AppColors.success : AppColors.warning;
    final label = isCompleted ? 'Completed' : 'Skipped';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final bool isDark;

  const _ExerciseTile({required this.exercise, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = exercise['name'] as String? ?? 'Exercise';
    final duration = exercise['duration_seconds'] as int?;
    final equipment = exercise['equipment'] as String?;
    final speed = exercise['speed_mph'] as num?;
    final incline = exercise['incline_percent'] as num?;
    final rpm = exercise['rpm'] as num?;

    final params = <String>[];
    if (speed != null) params.add('${speed}mph');
    if (incline != null) params.add('$incline% incline');
    if (rpm != null) params.add('${rpm}rpm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
          ),
          if (params.isNotEmpty)
            Text(
              params.join(' / '),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          if (equipment != null && equipment.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                equipment,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
          ],
          if (duration != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatExerciseDuration(duration),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatExerciseDuration(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '$m:00';
    }
    return '${seconds}s';
  }
}

// ═══════════════════════════════════════════════════════════════════
// 3. Rest Analysis
// ═══════════════════════════════════════════════════════════════════

class _RestAnalysisSection extends StatelessWidget {
  final List<Map<String, dynamic>> intervals;
  final bool isDark;

  const _RestAnalysisSection({required this.intervals, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Compute aggregates
    final totalRest = intervals.fold<int>(
      0,
      (sum, e) => sum + ((e['rest_seconds'] as num?)?.toInt() ?? 0),
    );

    final betweenSets = intervals.where((e) => e['rest_type'] == 'between_sets').toList();
    final betweenExercises = intervals.where((e) => e['rest_type'] == 'between_exercises').toList();

    int avgOf(List<Map<String, dynamic>> list) {
      if (list.isEmpty) return 0;
      final total = list.fold<int>(0, (s, e) => s + ((e['rest_seconds'] as num?)?.toInt() ?? 0));
      return (total / list.length).round();
    }

    return _SectionCard(
      isDark: isDark,
      icon: Icons.timer_outlined,
      title: 'Rest Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              _MiniStat(label: 'Total Rest', value: _fmtRest(totalRest), isDark: isDark),
              const SizedBox(width: 16),
              if (betweenSets.isNotEmpty)
                _MiniStat(label: 'Avg (Sets)', value: _fmtRest(avgOf(betweenSets)), isDark: isDark),
              if (betweenExercises.isNotEmpty) ...[
                const SizedBox(width: 16),
                _MiniStat(label: 'Avg (Exercises)', value: _fmtRest(avgOf(betweenExercises)), isDark: isDark),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Individual intervals
          ...intervals.map((e) {
            final name = e['exercise_name'] as String? ?? 'Rest';
            final actual = (e['rest_seconds'] as num?)?.toInt() ?? 0;
            final prescribed = (e['prescribed_rest_seconds'] as num?)?.toInt();
            // Color coding: green if within 10% of prescribed, orange if over
            final Color restColor;
            if (prescribed != null && prescribed > 0) {
              final diff = (actual - prescribed).abs() / prescribed;
              if (diff <= 0.10) {
                restColor = AppColors.success; // within 10%
              } else if (actual > prescribed) {
                restColor = AppColors.warning; // over prescribed
              } else {
                restColor = AppColors.success; // under prescribed
              }
            } else {
              restColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _fmtRest(actual),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: restColor,
                    ),
                  ),
                  if (prescribed != null) ...[
                    Text(
                      ' / ${_fmtRest(prescribed)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmtRest(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
    return '${seconds}s';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 4. Hydration
// ═══════════════════════════════════════════════════════════════════

class _HydrationSection extends StatelessWidget {
  final List<Map<String, dynamic>> drinkEvents;
  final int totalMl;
  final bool isDark;

  const _HydrationSection({
    required this.drinkEvents,
    required this.totalMl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalOz = (totalMl / 29.5735).toStringAsFixed(0);

    return _SectionCard(
      isDark: isDark,
      icon: Icons.water_drop_outlined,
      title: 'Hydration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${totalMl}ml ($totalOz oz)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.waterBlue,
            ),
          ),
          if (drinkEvents.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...drinkEvents.map((e) {
              final amount = (e['amount_ml'] as num?)?.toInt() ?? 0;
              final type = e['drink_type'] as String? ?? 'water';
              final exName = e['exercise_name'] as String?;
              final afterSet = e['after_set'] as int?;
              final loggedAt = e['logged_at'] as String?;

              final description = StringBuffer('${amount}ml');
              if (exName != null) {
                description.write(' \u2014 after $exName');
                if (afterSet != null) description.write(' set $afterSet');
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\uD83D\uDCA7 ', style: TextStyle(fontSize: 12)),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _drinkTypeColor(type).withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _drinkTypeLabel(type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _drinkTypeColor(type),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        description.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                    if (loggedAt != null)
                      Text(
                        _formatTime(loggedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _drinkTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'water':
        return AppColors.waterBlue;
      case 'electrolyte':
      case 'electrolytes':
        return AppColors.warning;
      case 'protein':
      case 'protein_shake':
        return AppColors.success;
      case 'bcaa':
      case 'pre_workout':
        return AppColors.error;
      default:
        return AppColors.waterBlue;
    }
  }

  String _drinkTypeLabel(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hour12:$m $period';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// 5. AI Interactions
// ═══════════════════════════════════════════════════════════════════

class _AIInteractionsSection extends StatelessWidget {
  final Map<String, dynamic> interactions;
  final bool isDark;

  const _AIInteractionsSection({required this.interactions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = <_AIStatItem>[];

    void addIfPresent(String key, String label, IconData icon, {String? suffix}) {
      final val = interactions[key];
      if (val != null && val != 0) {
        items.add(_AIStatItem(label: label, value: '$val${suffix ?? ''}', icon: icon));
      }
    }

    // Weight suggestions: show accepted/total
    final sugShown = interactions['weight_suggestions_shown'];
    final sugAccepted = interactions['weight_suggestions_accepted'];
    if (sugShown != null && sugShown != 0) {
      items.add(_AIStatItem(
        label: 'Weight Suggestions',
        value: '${sugAccepted ?? 0}/$sugShown accepted',
        icon: Icons.fitness_center,
      ));
    }

    addIfPresent('coach_opened', 'Coach Opened', Icons.chat_bubble_outline);
    addIfPresent('chat_messages_sent', 'Messages Sent', Icons.send_outlined);
    addIfPresent('coach_tips_shown', 'Coach Tips', Icons.lightbulb_outline);
    addIfPresent('coach_tips_dismissed', 'Tips Dismissed', Icons.close);
    addIfPresent('fatigue_alerts_triggered', 'Fatigue Alerts', Icons.warning_amber_outlined);
    addIfPresent('rest_suggestions_shown', 'Rest Suggestions', Icons.timer_outlined);
    addIfPresent('exercise_info_opened', 'Info Opened', Icons.info_outline);
    addIfPresent('video_views', 'Videos Watched', Icons.play_circle_outline);
    addIfPresent('breathing_guide_opened', 'Breathing Guide', Icons.air);
    addIfPresent('exercise_swaps_requested', 'Exercise Swaps', Icons.swap_horiz);

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      isDark: isDark,
      icon: Icons.smart_toy_outlined,
      title: 'AI Interactions',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.8,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.glassSurface
                  : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AIStatItem {
  final String label;
  final String value;
  final IconData icon;
  const _AIStatItem({required this.label, required this.value, required this.icon});
}

// ═══════════════════════════════════════════════════════════════════
// 6. Subjective Feedback
// ═══════════════════════════════════════════════════════════════════

class _SubjectiveFeedbackSection extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final bool isDark;

  const _SubjectiveFeedbackSection({required this.feedback, required this.isDark});

  static const _moodEmojis = ['', '\uD83D\uDE29', '\uD83D\uDE1F', '\uD83D\uDE10', '\uD83D\uDE42', '\uD83D\uDE01'];
  static const _energyEmojis = ['', '\uD83E\uDEAB', '\uD83D\uDD0B', '\u26A1', '\uD83D\uDD25', '\uD83D\uDCA5'];

  @override
  Widget build(BuildContext context) {
    final mood = feedback['mood_after'] as int?;
    final energy = feedback['energy_after'] as int?;
    final confidence = feedback['confidence_level'] as int?;
    final stronger = feedback['feeling_stronger'] as bool?;

    return _SectionCard(
      isDark: isDark,
      icon: Icons.sentiment_satisfied_alt,
      title: 'How You Felt',
      child: Column(
        children: [
          if (mood != null)
            _FeedbackRow(
              label: 'Mood',
              display: '${_safeEmoji(_moodEmojis, mood)} $mood/5',
              isDark: isDark,
            ),
          if (energy != null)
            _FeedbackRow(
              label: 'Energy',
              display: '${_safeEmoji(_energyEmojis, energy)} $energy/5',
              isDark: isDark,
            ),
          if (confidence != null)
            _FeedbackRow(
              label: 'Confidence',
              display: '$confidence/5',
              isDark: isDark,
            ),
          if (stronger != null)
            _FeedbackRow(
              label: 'Feeling Stronger',
              display: stronger ? 'Yes \u2705' : 'No',
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  String _safeEmoji(List<String> emojis, int index) {
    if (index >= 0 && index < emojis.length) return emojis[index];
    return '';
  }
}

class _FeedbackRow extends StatelessWidget {
  final String label;
  final String display;
  final bool isDark;

  const _FeedbackRow({required this.label, required this.display, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          Text(
            display,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 7. Settings Used
// ═══════════════════════════════════════════════════════════════════

class _SettingsUsedSection extends StatelessWidget {
  final Map<String, dynamic> settings;
  final bool isDark;

  const _SettingsUsedSection({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final unit = settings['unit'] as String? ?? 'lbs';

    final entries = <MapEntry<String, String>>[];
    entries.add(MapEntry('Weight Unit', unit));

    for (final key in ['dumbbell', 'barbell', 'machine', 'kettlebell', 'cable']) {
      final val = settings[key];
      if (val != null) {
        entries.add(MapEntry(
          '${key[0].toUpperCase()}${key.substring(1)} Increment',
          '$val $unit',
        ));
      }
    }

    return _SectionCard(
      isDark: isDark,
      icon: Icons.settings_outlined,
      title: 'Settings Used',
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 8. Per-Exercise Deep Dive
// ═══════════════════════════════════════════════════════════════════

class _PerExerciseDeepDiveSection extends StatelessWidget {
  final List<Map<String, dynamic>> setsJson;
  final List<Map<String, dynamic>> drinkEvents;
  final bool isDark;

  const _PerExerciseDeepDiveSection({
    required this.setsJson,
    required this.drinkEvents,
    required this.isDark,
  });

  static const _progressionModelNames = {
    'pyramidUp': 'Pyramid Up',
    'straightSets': 'Straight Sets',
    'reversePyramid': 'Reverse Pyramid',
    'dropSets': 'Drop Sets',
    'topSetBackOff': 'Top Set Back Off',
    'restPause': 'Rest Pause',
    'myoReps': 'Myo Reps',
  };

  @override
  Widget build(BuildContext context) {
    // Group sets by exercise name (case insensitive). Drop "Complete workout
    // now" zero-stamped placeholder rows so the deep-dive bars don't render
    // as empty "—" lines when the actual workout had logged sets elsewhere
    // — keeps a row only if the set was real (is_completed != false), or if
    // ANY meaningful field (reps / weight / rir / rpe / duration) is set.
    final grouped = <String, List<Map<String, dynamic>>>{};
    final originalNames = <String, String>{}; // lowercase -> original
    bool isRealSet(Map<String, dynamic> s) {
      if (s['is_completed'] == false) return false;
      final reps = (s['reps'] as num?)?.toInt() ?? 0;
      final weight = (s['weight_kg'] as num?)?.toDouble() ??
          (s['weight'] as num?)?.toDouble() ??
          0;
      if (reps > 0 || weight > 0) return true;
      // Allow non-zero RIR/RPE/duration to count too (logged effort even if
      // reps/weight ended up zero for some reason).
      if (s['rir'] != null || s['rpe'] != null) return true;
      final dur = (s['duration_seconds'] as num?)?.toInt() ?? 0;
      return dur > 0;
    }
    for (final s in setsJson) {
      if (!isRealSet(s)) continue;
      final name = s['exercise_name'] as String? ?? 'Unknown';
      final key = name.toLowerCase();
      originalNames.putIfAbsent(key, () => name);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    if (grouped.isEmpty) {
      final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
      return _SectionCard(
        isDark: isDark,
        icon: Icons.fitness_center,
        title: 'Per-Exercise Deep Dive',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              'No completed sets logged for this workout.',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ),
        ),
      );
    }

    return _SectionCard(
      isDark: isDark,
      icon: Icons.fitness_center,
      title: 'Per-Exercise Deep Dive',
      child: Column(
        children: grouped.entries.map((entry) {
          final exerciseName = originalNames[entry.key]!;
          final sets = entry.value;
          final progressionModel = sets.first['progression_model'] as String?;
          final barType = sets.first['bar_type'] as String?;

          // Filter drink events for this exercise
          final exerciseDrinks = drinkEvents.where((d) {
            final dn = d['exercise_name'] as String?;
            return dn != null && dn.toLowerCase() == entry.key;
          }).toList();

          // Calculate 1RM from best set (Epley formula).
          //
          // Field-name contract must match `buildSetsJson()` in
          // mobile/flutter/lib/screens/workout/mixins/set_logging_mixin.dart —
          // the canonical key is `weight_kg`; bare `weight` is a legacy
          // fallback for any pre-rename rows.
          double? best1RM;
          for (final s in sets) {
            final w = (s['weight_kg'] as num?)?.toDouble() ??
                (s['weight'] as num?)?.toDouble();
            final r = (s['reps'] as num?)?.toInt();
            if (w != null && w > 0 && r != null && r > 0) {
              final lbWeight = w * 2.20462;
              final estimate = r == 1 ? lbWeight : lbWeight * (1 + r / 30.0);
              if (best1RM == null || estimate > best1RM) best1RM = estimate;
            }
          }

          return _ExerciseDeepDiveCard(
            exerciseName: exerciseName,
            sets: sets,
            progressionModel: progressionModel,
            barType: barType,
            drinks: exerciseDrinks,
            best1RM: best1RM,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class _ExerciseDeepDiveCard extends StatefulWidget {
  final String exerciseName;
  final List<Map<String, dynamic>> sets;
  final String? progressionModel;
  final String? barType;
  final List<Map<String, dynamic>> drinks;
  final double? best1RM;
  final bool isDark;

  const _ExerciseDeepDiveCard({
    required this.exerciseName,
    required this.sets,
    this.progressionModel,
    this.barType,
    required this.drinks,
    this.best1RM,
    required this.isDark,
  });

  @override
  State<_ExerciseDeepDiveCard> createState() => _ExerciseDeepDiveCardState();
}

class _ExerciseDeepDiveCardState extends State<_ExerciseDeepDiveCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final modelName = _PerExerciseDeepDiveSection
        ._progressionModelNames[widget.progressionModel];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tappable)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                  if (modelName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.accent : AppColorsLight.accent)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColorsLight.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.barType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColorsLight.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatBarType(widget.barType!),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColorsLight.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColorsLight.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Set table
                  _buildSetTable(),

                  // Timing rows
                  const SizedBox(height: 10),
                  Text(
                    'TIMING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.sets.map(_buildTimingRow),

                  // Drink events
                  if (widget.drinks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'HYDRATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.drinks.map((d) {
                      final amount = (d['amount_ml'] as num?)?.toInt() ?? 0;
                      final type = d['drink_type'] as String? ?? 'water';
                      final afterSet = d['after_set'] as int?;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '\u{1F4A7} ${amount}ml $type${afterSet != null ? ' after set $afterSet' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColorsLight.textSecondary,
                          ),
                        ),
                      );
                    }),
                  ],

                  // 1RM estimate
                  if (widget.best1RM != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text(
                            'Est. 1RM: ${widget.best1RM!.toStringAsFixed(0)} lb',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColorsLight.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetTable() {
    final isDark = widget.isDark;
    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
    );
    final subtleStyle = TextStyle(
      fontSize: 10,
      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        horizontalMargin: 0,
        headingRowHeight: 28,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 48,
        columns: [
          DataColumn(label: Text('Set', style: headerStyle)),
          DataColumn(label: Text('Prev', style: headerStyle)),
          DataColumn(label: Text('Target', style: headerStyle)),
          DataColumn(label: Text('Weight', style: headerStyle)),
          DataColumn(label: Text('Reps', style: headerStyle)),
          DataColumn(label: Text('RIR', style: headerStyle)),
          DataColumn(label: Text('RPE', style: headerStyle)),
        ],
        rows: widget.sets.map((s) {
          final setNum = s['set_number'] as int? ?? 0;
          final prevW = (s['previous_weight_kg'] as num?)?.toDouble();
          final prevR = (s['previous_reps'] as num?)?.toInt();
          final targetW = (s['target_weight_kg'] as num?)?.toDouble();
          final targetR = (s['target_reps'] as num?)?.toInt();
          // `weight_kg` is the canonical key (written by buildSetsJson);
          // `weight` is accepted as a legacy fallback for older rows.
          final weight = (s['weight_kg'] as num?)?.toDouble() ??
              (s['weight'] as num?)?.toDouble();
          final reps = (s['reps'] as num?)?.toInt();
          final rir = (s['rir'] as num?)?.toInt();
          final rpe = (s['rpe'] as num?)?.toInt();
          final aiSource = s['ai_input_source'] as String?;

          final prevStr = prevW != null && prevR != null
              ? '${(prevW * 2.20462).toStringAsFixed(0)}x$prevR'
              : '-';
          final targetStr = targetW != null && targetR != null
              ? '${(targetW * 2.20462).toStringAsFixed(0)}x$targetR'
              : '-';
          final weightStr = weight != null
              ? '${(weight * 2.20462).toStringAsFixed(0)} lb'
              : '-';

          return DataRow(cells: [
            DataCell(Text('$setNum', style: cellStyle)),
            DataCell(Text(prevStr, style: cellStyle)),
            DataCell(Text(targetStr, style: cellStyle)),
            DataCell(Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weightStr, style: cellStyle),
                if (aiSource != null)
                  Text('AI: $aiSource', style: subtleStyle),
              ],
            )),
            DataCell(Text('${reps ?? '-'}', style: cellStyle)),
            DataCell(Text('${rir ?? '-'}', style: cellStyle)),
            DataCell(Text('${rpe ?? '-'}', style: cellStyle)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTimingRow(Map<String, dynamic> s) {
    final isDark = widget.isDark;
    final setNum = s['set_number'] as int? ?? 0;
    final duration = (s['duration_seconds'] as num?)?.toInt();
    final rest = (s['rest_duration_seconds'] as num?)?.toInt();

    final parts = <String>[];
    if (duration != null) parts.add('${duration}s');
    if (rest != null) parts.add('rested ${_fmtTime(rest)}');

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        'set $setNum: ${parts.join(' \u00B7 ')}',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
        ),
      ),
    );
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')}';
    return '${seconds}s';
  }

  String _formatBarType(String barType) {
    return barType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}

// ═══════════════════════════════════════════════════════════════════
// 9. Superset Details
// ═══════════════════════════════════════════════════════════════════

class _SupersetDetailsSection extends StatelessWidget {
  final List<Map<String, dynamic>> supersets;
  final bool isDark;

  const _SupersetDetailsSection({
    required this.supersets,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.link,
      title: 'Superset Details',
      child: Column(
        children: supersets.map((ss) {
          final groupId = ss['group_id'] ?? '';
          final exercises =
              (ss['exercises'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Superset $groupId',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                ...exercises.map((ex) {
                  final name = ex['name'] as String? ?? 'Exercise';
                  final muscle = ex['muscle_group'] as String?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColorsLight.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColorsLight.textPrimary,
                            ),
                          ),
                        ),
                        if (muscle != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardBorder
                                  : AppColorsLight.cardBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              muscle,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColorsLight.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 10. Exercise Order & Time
// ═══════════════════════════════════════════════════════════════════

class _ExerciseOrderSection extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final bool isDark;

  const _ExerciseOrderSection({
    required this.exercises,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.format_list_numbered,
      title: 'Exercise Order & Time',
      child: Column(
        children: exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final ex = entry.value;
          final name = ex['exercise_name'] as String? ?? 'Exercise';
          final timeSpent = (ex['time_spent_seconds'] as num?)?.toInt();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.accent : AppColorsLight.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                ),
                if (timeSpent != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.glassSurface
                          : AppColorsLight.glassSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColorsLight.cardBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _fmtDuration(timeSpent),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════════
// 11. Workout Exit Stats (quit early)
// ═══════════════════════════════════════════════════════════════════

class _WorkoutExitStatsSection extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isDark;

  const _WorkoutExitStatsSection({
    required this.metadata,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final exitReason = metadata['exit_reason'] as String? ?? 'Unknown';
    final progressPct = (metadata['progress_percentage'] as num?)?.toDouble();
    final exercisesCompleted =
        (metadata['exercises_completed'] as num?)?.toInt();
    final timeSpent = (metadata['time_spent'] as num?)?.toInt() ??
        (metadata['time_spent_seconds'] as num?)?.toInt();

    return _SectionCard(
      isDark: isDark,
      icon: Icons.exit_to_app,
      title: 'Workout Ended Early',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exit reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatExitReason(exitReason),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              if (progressPct != null)
                _MiniStat(
                  label: 'Progress',
                  value: '${progressPct.toStringAsFixed(0)}%',
                  isDark: isDark,
                ),
              if (progressPct != null && exercisesCompleted != null)
                const SizedBox(width: 20),
              if (exercisesCompleted != null)
                _MiniStat(
                  label: 'Exercises Done',
                  value: '$exercisesCompleted',
                  isDark: isDark,
                ),
              if (timeSpent != null) ...[
                const SizedBox(width: 20),
                _MiniStat(
                  label: 'Time Spent',
                  value: _fmtDuration(timeSpent),
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatExitReason(String reason) {
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════════
// A. Volume Breakdown (from setLogs)
// ═══════════════════════════════════════════════════════════════════

class _VolumeBreakdownSection extends StatelessWidget {
  final List<SetLogInfo> setLogs;
  final bool isDark;

  const _VolumeBreakdownSection({
    required this.setLogs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group by exercise, calculate total volume (weight_kg * reps) in lbs
    final volumes = <String, double>{};
    final setsByExercise = <String, int>{};
    for (final s in setLogs) {
      if (s.exerciseName.isEmpty) continue;
      final volLb = s.weightKg * 2.20462 * s.repsCompleted;
      volumes[s.exerciseName] = (volumes[s.exerciseName] ?? 0) + volLb;
      setsByExercise[s.exerciseName] = (setsByExercise[s.exerciseName] ?? 0) + 1;
    }
    if (volumes.isEmpty) return const SizedBox.shrink();

    // Sort by volume descending
    final sorted = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVol = sorted.first.value;
    final totalVol = sorted.fold<double>(0, (sum, e) => sum + e.value);

    return _SectionCard(
      isDark: isDark,
      icon: Icons.bar_chart_rounded,
      title: 'Volume Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total volume header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Volume: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                Text(
                  '${totalVol.toStringAsFixed(0)} lb',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          // Per-exercise bars
          ...sorted.map((entry) {
            final pct = maxVol > 0 ? entry.value / maxVol : 0.0;
            final sets = setsByExercise[entry.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)} lb  ($sets sets)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.cardBorder
                          : AppColorsLight.cardBorder,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.orange.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// B. Intensity Analysis (RPE / RIR from setLogs)
// ═══════════════════════════════════════════════════════════════════

class _IntensityAnalysisSection extends StatelessWidget {
  final List<SetLogInfo> setLogs;
  final bool isDark;

  const _IntensityAnalysisSection({
    required this.setLogs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final withRpe = setLogs.where((l) => l.rpe != null).toList();
    final withRir = setLogs.where((l) => l.rir != null).toList();

    final avgRpe = withRpe.isNotEmpty
        ? withRpe.map((l) => l.rpe!).reduce((a, b) => a + b) / withRpe.length
        : null;
    final maxRpe = withRpe.isNotEmpty
        ? withRpe.map((l) => l.rpe!).reduce(math.max)
        : null;
    final avgRir = withRir.isNotEmpty
        ? withRir.map((l) => l.rir!.toDouble()).reduce((a, b) => a + b) / withRir.length
        : null;

    // RPE distribution buckets: Easy (<6), Moderate (6-7), Hard (8-9), Max (10)
    final rpeBuckets = <String, int>{'Easy (<6)': 0, 'Moderate (6-7)': 0, 'Hard (8-9)': 0, 'Max (10)': 0};
    for (final l in withRpe) {
      final r = l.rpe!;
      if (r < 6) {
        rpeBuckets['Easy (<6)'] = rpeBuckets['Easy (<6)']! + 1;
      } else if (r < 8) {
        rpeBuckets['Moderate (6-7)'] = rpeBuckets['Moderate (6-7)']! + 1;
      } else if (r < 10) {
        rpeBuckets['Hard (8-9)'] = rpeBuckets['Hard (8-9)']! + 1;
      } else {
        rpeBuckets['Max (10)'] = rpeBuckets['Max (10)']! + 1;
      }
    }

    // Color for RPE level
    Color rpeColor(double rpe) {
      if (rpe < 6) return AppColors.success;
      if (rpe < 8) return AppColors.orange;
      if (rpe < 10) return AppColors.error.withValues(alpha: 0.8);
      return AppColors.error;
    }

    // RPE intensity label
    String rpeLabel(double rpe) {
      if (rpe < 6) return 'Easy';
      if (rpe < 7) return 'Moderate';
      if (rpe < 8.5) return 'Hard';
      if (rpe < 10) return 'Very Hard';
      return 'Maximal';
    }

    return _SectionCard(
      isDark: isDark,
      icon: Icons.speed_rounded,
      title: 'Intensity Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats row
          Row(
            children: [
              if (avgRpe != null)
                Expanded(
                  child: _IntensityStat(
                    label: 'Avg RPE',
                    value: avgRpe.toStringAsFixed(1),
                    subLabel: rpeLabel(avgRpe),
                    color: rpeColor(avgRpe),
                    isDark: isDark,
                  ),
                ),
              if (maxRpe != null)
                Expanded(
                  child: _IntensityStat(
                    label: 'Peak RPE',
                    value: maxRpe.toStringAsFixed(1),
                    subLabel: rpeLabel(maxRpe),
                    color: rpeColor(maxRpe),
                    isDark: isDark,
                  ),
                ),
              if (avgRir != null)
                Expanded(
                  child: _IntensityStat(
                    label: 'Avg RIR',
                    value: avgRir.toStringAsFixed(1),
                    subLabel: '${avgRir.toStringAsFixed(0)} reps left',
                    color: avgRir <= 1 ? AppColors.error : avgRir <= 2 ? AppColors.orange : AppColors.success,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
          // RPE distribution
          if (withRpe.length >= 3) ...[
            const SizedBox(height: 14),
            Text(
              'RPE Distribution',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: rpeBuckets.entries.where((e) => e.value > 0).map((e) {
                final bucketColors = {
                  'Easy (<6)': AppColors.success,
                  'Moderate (6-7)': AppColors.orange,
                  'Hard (8-9)': AppColors.error.withValues(alpha: 0.8),
                  'Max (10)': AppColors.error,
                };
                final color = bucketColors[e.key] ?? AppColors.textMuted;
                return Expanded(
                  flex: e.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              '${e.value}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          e.key.replaceAll(RegExp(r'\s*\(.*\)'), ''),
                          style: TextStyle(fontSize: 9, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _IntensityStat extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color color;
  final bool isDark;

  const _IntensityStat({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// C. Estimated 1RM (from setLogs, Epley formula)
// ═══════════════════════════════════════════════════════════════════

class _Estimated1RMSection extends StatelessWidget {
  final List<SetLogInfo> setLogs;
  final bool isDark;

  const _Estimated1RMSection({
    required this.setLogs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate best estimated 1RM per exercise (Epley formula)
    final best1RMs = <String, double>{};
    final bestSets = <String, SetLogInfo>{};
    for (final s in setLogs) {
      if (s.exerciseName.isEmpty || s.weightKg <= 0 || s.repsCompleted <= 0) continue;
      final lbWeight = s.weightKg * 2.20462;
      final estimate = s.repsCompleted == 1
          ? lbWeight
          : lbWeight * (1 + s.repsCompleted / 30.0);
      if (!best1RMs.containsKey(s.exerciseName) || estimate > best1RMs[s.exerciseName]!) {
        best1RMs[s.exerciseName] = estimate;
        bestSets[s.exerciseName] = s;
      }
    }
    if (best1RMs.isEmpty) return const SizedBox.shrink();

    final sorted = best1RMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _SectionCard(
      isDark: isDark,
      icon: Icons.emoji_events_rounded,
      title: 'Estimated 1RM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Based on Epley formula from your best sets',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          ...sorted.map((entry) {
            final set = bestSets[entry.key]!;
            final weightLb = set.weightKg * 2.20462;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best set: ${weightLb.toStringAsFixed(1)} lb x ${set.repsCompleted}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value.toStringAsFixed(0)} lb',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// D. Set Type Distribution (from setLogs)
// ═══════════════════════════════════════════════════════════════════

class _SetTypeDistributionSection extends StatelessWidget {
  final List<SetLogInfo> setLogs;
  final bool isDark;

  const _SetTypeDistributionSection({
    required this.setLogs,
    required this.isDark,
  });

  static const _typeLabels = {
    'working': 'Working',
    'warmup': 'Warm-up',
    'drop': 'Drop Set',
    'failure': 'Failure',
    'backoff': 'Back-off',
    'rest_pause': 'Rest-Pause',
    'myo_rep': 'Myo-Rep',
  };

  static const _typeColors = {
    'working': AppColors.orange,
    'warmup': AppColors.success,
    'drop': Color(0xFF8E44AD),
    'failure': AppColors.error,
    'backoff': Color(0xFF3498DB),
    'rest_pause': Color(0xFFE67E22),
    'myo_rep': Color(0xFF1ABC9C),
  };

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in setLogs) {
      final type = s.setType.isNotEmpty ? s.setType : 'working';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final total = setLogs.length;

    // Sort: working first, then by count descending
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        if (a.key == 'working') return -1;
        if (b.key == 'working') return 1;
        return b.value.compareTo(a.value);
      });

    return _SectionCard(
      isDark: isDark,
      icon: Icons.donut_small_rounded,
      title: 'Set Type Distribution',
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 20,
              child: Row(
                children: sorted.map((e) {
                  final color = _typeColors[e.key] ?? AppColors.textMuted;
                  return Expanded(
                    flex: e.value,
                    child: Container(
                      color: color.withValues(alpha: isDark ? 0.6 : 0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: sorted.map((e) {
              final color = _typeColors[e.key] ?? AppColors.textMuted;
              final label = _typeLabels[e.key] ?? e.key;
              final pct = (e.value / total * 100).toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$label: ${e.value} ($pct%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 12. Info Banner (no metadata)
// ═══════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  final bool isDark;

  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 22,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Detailed tracking data is not available for this workout.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAGAZINE LAYOUT — hero widgets for the redesigned Advanced tab
//
// Composition (top to bottom):
//   1. _CoachHeroCard        — punchy AI-generated one-liner
//   2. _KpiTileRow            — 4 big-number tiles with ↑/↓ deltas vs last
//   3. _IntensityDonutRow    — 3 donuts: Rest · RIR distribution · Plan adherence
//   4. _SessionTimelineAndHeatmap — gantt of exercises side-by-side with a
//                                   muscle body heatmap (flutter_body_atlas)
//   5. _PyramidDeepDive      — per-exercise card with literal shape
//                              matching the progression model
//   6. _CollapsibleDetails   — disclosure wrapping the older dense sections
// ═══════════════════════════════════════════════════════════════════════════════

/// Hero card — a single short narrative from the AI coach, anchored to real
/// session deltas. Falls back to the first sentence of [coachSummary] when
/// [heroNarrative] isn't available (old workouts, Gemini outage).
class _CoachHeroCard extends StatelessWidget {
  final String? heroNarrative;
  final String? coachSummary;
  final bool isDark;

  const _CoachHeroCard({
    required this.heroNarrative,
    required this.coachSummary,
    required this.isDark,
  });

  /// Extract the first sentence from long-form coach copy as a fallback
  /// headline. Trims quotes and limits to 140 chars for safety.
  static String? _firstSentence(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var text = raw.trim().replaceAll(RegExp(r'^["\u201C]+|["\u201D]+$'), '');
    // Strip any leading JSON-ish coach-review key so we always start at prose.
    final jsonMatch = RegExp(r'"summary"\s*:\s*"([^"]+)"').firstMatch(text);
    if (jsonMatch != null) text = jsonMatch.group(1)!;
    final m = RegExp(r'^(.+?[.!?])\s').firstMatch(text);
    final sentence = (m?.group(1) ?? text).trim();
    return sentence.length > 140 ? '${sentence.substring(0, 137)}…' : sentence;
  }

  @override
  Widget build(BuildContext context) {
    final narrative = (heroNarrative != null && heroNarrative!.trim().isNotEmpty)
        ? heroNarrative!.trim()
        : _firstSentence(coachSummary);
    if (narrative == null) return const SizedBox.shrink();

    final accent = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.22 : 0.14),
                cyan.withValues(alpha: isDark ? 0.18 : 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.14),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, cyan],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      narrative,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Darken a color by mixing with black (fallback replacement for the
/// now-deprecated Color.withOpacity on white-ish accent colors in light mode).
Color _darkenColor(Color c, [double amount = 0.25]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

// ────────────────────────────────────────────────────────────────────────────
// 2. KPI TILE ROW — 4 big numbers with ↑/↓ deltas vs last session
// ────────────────────────────────────────────────────────────────────────────

/// Values needed to render a single KPI tile. Deltas are optional — absent
/// when there is no previous session to compare against.
class _KpiTileData {
  final String label;
  final String value;        // pre-formatted big number
  final String? unit;        // suffix (e.g. 'lb', 'sets')
  final double? deltaSigned; // +ve = improvement for this metric
  final String? deltaLabel;  // pre-formatted delta string, e.g. '+1.2k'
  final IconData icon;
  final Color accent;
  /// Human-friendly copy shown when [value] is a zero/null placeholder.
  /// e.g. "First session — log another to see growth".
  final String? zeroStateCopy;
  /// Optional historical series for an inline sparkline. When only the
  /// current + previous values are known (the common case today), pass
  /// `[previous, current]` — the painter renders a two-point chart.
  final List<double>? trendSeries;

  const _KpiTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.unit,
    this.deltaSigned,
    this.deltaLabel,
    this.zeroStateCopy,
    this.trendSeries,
  });
}

class _KpiTileRow extends StatelessWidget {
  final List<_KpiTileData> tiles;
  final bool isDark;

  const _KpiTileRow({required this.tiles, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 4+ tiles wrap into 2-per-row so each tile keeps enough width for
    // the value + unit + delta-chip without clipping. 3 or fewer stay
    // on one row to preserve the existing visual cadence.
    if (tiles.length <= 3) {
      return Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            Expanded(child: _KpiTileCard(data: tiles[i], isDark: isDark)),
            if (i < tiles.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      final rowTiles = tiles.sublist(i, math.min(i + 2, tiles.length));
      rows.add(
        Row(
          children: [
            Expanded(
              child: _KpiTileCard(data: rowTiles[0], isDark: isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: rowTiles.length > 1
                  ? _KpiTileCard(data: rowTiles[1], isDark: isDark)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < tiles.length) {
        rows.add(const SizedBox(height: 10));
      }
    }
    return Column(children: rows);
  }
}

class _KpiTileCard extends StatelessWidget {
  final _KpiTileData data;
  final bool isDark;

  const _KpiTileCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final deltaColor = data.deltaSigned == null
        ? textMuted
        : (data.deltaSigned! >= 0
            ? (isDark ? AppColors.success : AppColorsLight.success)
            : (isDark ? AppColors.error : AppColorsLight.error));
    final deltaArrow = data.deltaSigned == null
        ? null
        : (data.deltaSigned! >= 0
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: icon above label so the label gets the full tile
          // width (previously icon+gap ate ~20px, clipping labels like
          // "VOLUME" → "VOL..." on narrow tiles). Label can now wrap
          // to a second line when needed for full legibility.
          Icon(data.icon, size: 15, color: data.accent),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.6,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: data.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.0,
                    ),
                  ),
                  if (data.unit != null)
                    TextSpan(
                      text: ' ${data.unit}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Delta CHIP — pill background so it reads as a "stamp" on
          // the tile, not raw text. Falls back to a narrative zero-state
          // copy when no comparison is available.
          if (data.deltaLabel != null)
            _DeltaChip(
              icon: deltaArrow ?? Icons.remove_rounded,
              label: data.deltaLabel!,
              color: deltaColor,
            )
          else
            Text(
              data.zeroStateCopy ?? '—',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: textMuted,
                height: 1.25,
                fontStyle: data.zeroStateCopy == null
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          // Inline 2-point sparkline showing current vs previous. The
          // tile architecture is also ready for a full historical
          // series — pass `trendSeries` to render multi-point once a
          // weekly-trend endpoint exists.
          if (data.trendSeries != null && data.trendSeries!.length >= 2) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 22,
              child: CustomPaint(
                painter: _KpiSparklinePainter(
                  series: data.trendSeries!,
                  color: data.accent,
                  trackColor: textMuted.withValues(alpha: 0.25),
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill-shaped delta indicator with icon + text.
class _DeltaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DeltaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal sparkline painter — straight polyline over a faint track.
/// Works with any number of points ≥ 2. Current-value dot at the right.
class _KpiSparklinePainter extends CustomPainter {
  final List<double> series;
  final Color color;
  final Color trackColor;

  _KpiSparklinePainter({
    required this.series,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Filter out NaN / Infinity before reduce — a single non-finite value
    // turns `reduce(max)` into infinity which then poisons xAt/yAt and
    // explodes downstream `Offset` math with "Infinity or NaN toInt".
    final clean = series.where((v) => v.isFinite).toList(growable: false);
    if (clean.length < 2) return;
    if (!size.width.isFinite || !size.height.isFinite ||
        size.width <= 0 || size.height <= 0) {
      return;
    }
    final minV = clean.reduce((a, b) => a < b ? a : b);
    final maxV = clean.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;
    double xAt(int i) => (i / (clean.length - 1)) * size.width;
    double yAt(double v) =>
        size.height - ((v - minV) / range) * size.height;

    // Faint horizontal baseline
    final linePaint = Paint()
      ..color = trackColor
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Polyline
    final path = Path()..moveTo(xAt(0), yAt(clean[0]));
    for (var i = 1; i < clean.length; i++) {
      path.lineTo(xAt(i), yAt(clean[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Current-value dot on the right
    canvas.drawCircle(
      Offset(xAt(clean.length - 1), yAt(clean.last)),
      2.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_KpiSparklinePainter old) =>
      old.series != series ||
      old.color != color ||
      old.trackColor != trackColor;
}

/// Build the KPI tiles from the session summary. All tiles are always
/// rendered (never hidden) so the row's visual weight stays consistent —
/// missing data becomes an em-dash rather than an absent tile.
///
/// Volume + TOP 1RM are computed client-side from set logs as a fallback
/// when the backend `workout_performance_summary` aggregate is missing or
/// zero (older workouts whose summary row was never written). Per-set
/// rows from `performance_logs` are the source of truth for "what the
/// user actually lifted" — the aggregates are derived from them.
List<_KpiTileData> _buildKpiTiles({
  required WorkoutSummaryResponse? data,
  required Map<String, dynamic>? metadata,
  required bool isDark,
}) {
  final accent = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
  final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
  final orange = isDark ? AppColors.orange : AppColorsLight.orange;
  final success = isDark ? AppColors.success : AppColorsLight.success;

  String formatPounds(double v) {
    if (v.abs() >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(2)}k';
    return v.toStringAsFixed(0);
  }

  // ── Aggregate per-set data (volume + best Epley 1RM) ──────────────
  // Walk performance_logs first; fall back to metadata['sets_json'] if
  // logs are empty. Skip incomplete sets and bodyweight-only sets (no
  // weight) so we don't pollute the lift metrics.
  double computedVolKg = 0;
  double computedBest1RmKg = 0;
  int countedSets = 0;
  String? best1RmExerciseName;
  int best1RmReps = 0;
  double best1RmWeightKg = 0;

  for (final sl in (data?.setLogs ?? const [])) {
    final isCompleted = sl.isCompleted ?? (sl.repsCompleted > 0);
    if (!isCompleted) continue;
    if (sl.repsCompleted <= 0 || sl.weightKg <= 0) continue;
    countedSets++;
    computedVolKg += sl.weightKg * sl.repsCompleted;
    // Epley: 1RM = w × (1 + reps / 30). Industry-standard for ≤10 reps;
    // accuracy degrades on high-rep sets but we still surface the highest
    // implied 1RM so the user sees their heaviest lift in 1RM units.
    final oneRm = sl.weightKg * (1 + sl.repsCompleted / 30.0);
    if (oneRm > computedBest1RmKg) {
      computedBest1RmKg = oneRm;
      best1RmExerciseName = sl.exerciseName;
      best1RmReps = sl.repsCompleted;
      best1RmWeightKg = sl.weightKg;
    }
  }

  if (countedSets == 0 && metadata != null) {
    final setsJson = (metadata['sets_json'] is List)
        ? metadata['sets_json'] as List
        : const [];
    for (final s in setsJson) {
      if (s is! Map) continue;
      final reps = (s['reps_completed'] as num?)?.toInt() ?? 0;
      final weight = (s['weight_kg'] as num?)?.toDouble() ?? 0;
      final completedRaw = s['is_completed'];
      final isCompleted =
          completedRaw is bool ? completedRaw : reps > 0;
      if (!isCompleted || reps <= 0 || weight <= 0) continue;
      countedSets++;
      computedVolKg += weight * reps;
      final oneRm = weight * (1 + reps / 30.0);
      if (oneRm > computedBest1RmKg) {
        computedBest1RmKg = oneRm;
        best1RmExerciseName = (s['exercise_name'] as String?)?.trim();
        best1RmReps = reps;
        best1RmWeightKg = weight;
      }
    }
  }

  // ── Volume tile ───────────────────────────────────────────────────
  final wc = data?.performanceComparison?.workoutComparison;
  final backendVolKg = wc?.currentTotalVolumeKg;
  // Prefer backend aggregate when present and non-zero; otherwise use
  // the client-computed fallback so older workouts (no summary row)
  // still surface real numbers.
  final effectiveVolKg = (backendVolKg != null && backendVolKg > 0)
      ? backendVolKg
      : (computedVolKg > 0 ? computedVolKg : null);
  final volLb = effectiveVolKg != null ? effectiveVolKg * 2.20462 : null;
  final volDeltaKg = wc?.volumeDiffKg;
  final volDeltaLb = volDeltaKg != null ? volDeltaKg * 2.20462 : null;
  final prevVolKg = wc?.previousTotalVolumeKg;
  final prevVolLb = prevVolKg != null ? prevVolKg * 2.20462 : null;
  final volTile = _KpiTileData(
    label: 'VOLUME',
    value: volLb != null ? formatPounds(volLb) : '0',
    unit: volLb != null ? 'lb' : null,
    icon: Icons.bolt_rounded,
    accent: accent,
    deltaSigned: volDeltaLb,
    deltaLabel: volDeltaLb != null
        ? '${volDeltaLb >= 0 ? '+' : '−'}${formatPounds(volDeltaLb.abs())} lb vs last'
        : null,
    zeroStateCopy: volLb == null
        ? 'No weighted sets logged'
        : (prevVolLb == null
            ? 'First session — log another to see growth'
            : null),
    trendSeries: (prevVolLb != null && volLb != null)
        ? [prevVolLb, volLb]
        : null,
  );

  // ── TOP 1RM tile (Epley estimate from heaviest working set) ───────
  // Surfaces the heaviest implied 1RM in the session so the user sees
  // their peak lift in 1RM terms even if no all-time PR was set.
  final top1RmLb = computedBest1RmKg > 0
      ? computedBest1RmKg * 2.20462
      : null;
  final lift1RmTile = _KpiTileData(
    label: 'TOP 1RM',
    value: top1RmLb != null ? formatPounds(top1RmLb) : '—',
    unit: top1RmLb != null ? 'lb' : null,
    icon: Icons.fitness_center_rounded,
    accent: success,
    deltaSigned: null,
    deltaLabel: top1RmLb != null && best1RmExerciseName != null
        ? '${best1RmExerciseName!} · ${formatPounds(best1RmWeightKg * 2.20462)}×$best1RmReps'
        : null,
    zeroStateCopy: top1RmLb == null
        ? 'Log weight + reps to estimate 1RM'
        : null,
  );

  // ── PRs hit tile ──────────────────────────────────────────────────
  // Sourced from the `personal_records` table indexed by workout_id.
  // Backend writes these at completion time when a working set beats
  // the user's prior best 1RM for the same exercise. A genuine 0 here
  // means no all-time PR was beaten this session — that's correct for
  // accessory/maintenance sessions.
  final prs = data?.personalRecords ?? const [];
  final prTile = _KpiTileData(
    label: 'PRs HIT',
    value: '${prs.length}',
    icon: Icons.emoji_events_rounded,
    accent: prs.isEmpty
        ? (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        : orange,
    deltaSigned: prs.isEmpty ? null : prs.length.toDouble(),
    deltaLabel: prs.isEmpty ? null : '${prs.length} new this session',
    zeroStateCopy: prs.isEmpty
        ? 'No new records today — grind builds them'
        : null,
  );

  // Avg RIR across working sets. Prefer performance_logs (backend), fall
  // back to sets_json in metadata.
  final rirValues = <int>[];
  final perfLogs = data?.setLogs ?? const [];
  for (final sl in perfLogs) {
    if (sl.setType == 'working' && sl.rir != null) rirValues.add(sl.rir!);
  }
  if (rirValues.isEmpty && metadata != null) {
    final setsJson = (metadata['sets_json'] is List)
        ? metadata['sets_json'] as List
        : const [];
    for (final s in setsJson) {
      if (s is Map<String, dynamic>) {
        final rir = s['rir'];
        if (rir is int) rirValues.add(rir);
        if (rir is num) rirValues.add(rir.toInt());
      }
    }
  }
  final avgRir = rirValues.isEmpty
      ? null
      : rirValues.fold<int>(0, (a, b) => a + b) / rirValues.length;
  // Lower RIR = higher intensity; display is neutral (no ↑/↓ vs last since
  // we don't track RIR history cross-session yet).
  final rirTile = _KpiTileData(
    label: avgRir == null ? 'AVG EFFORT' : 'AVG EFFORT',
    value: avgRir != null
        ? (10 - avgRir).clamp(1, 10).toStringAsFixed(1)
        : '—',
    unit: avgRir != null ? 'RPE' : null,
    icon: Icons.fitness_center_rounded,
    accent: cyan,
    deltaSigned: null,
    deltaLabel: avgRir == null
        ? null
        : avgRir <= 1.5
            ? 'mostly hard'
            : avgRir <= 3
                ? 'mostly moderate'
                : 'mostly easy',
    zeroStateCopy: avgRir == null
        ? 'Tap effort on each set to see intensity'
        : null,
  );

  // REST EFFICIENCY intentionally omitted from the KPI row — the same
  // rest-quality signal is now rendered via the REST COMPLIANCE ring
  // in the Session Score widget below, so the tile was a redundant
  // second representation of the same concept. The computation logic
  // still lives further down in _buildSessionScoreData().

  return [volTile, lift1RmTile, prTile, rirTile];
}

// Small helper used by the Session Score to compute rest-efficiency
// stats from metadata. Duplicated from the original Rest Efficiency
// tile so the concentric rings can show the same on-target percentage.
({int onTarget, int total, int tooShort, int tooLong}) _computeRestStats(
  Map<String, dynamic>? metadata,
) {
  int onTarget = 0;
  int tooShort = 0;
  int tooLong = 0;
  int total = 0;
  if (metadata != null) {
    final intervals = (metadata['rest_intervals'] is List)
        ? metadata['rest_intervals'] as List
        : const [];
    for (final ri in intervals) {
      if (ri is Map<String, dynamic>) {
        final actual = (ri['rest_seconds'] as num?)?.toDouble();
        final prescribed =
            (ri['prescribed_rest_seconds'] as num?)?.toDouble();
        if (actual == null || prescribed == null || prescribed <= 0) continue;
        total++;
        final delta = (actual - prescribed) / prescribed;
        if (delta.abs() <= 0.15) {
          onTarget++;
        } else if (delta < 0) {
          tooShort++;
        } else {
          tooLong++;
        }
      }
    }
  }
  return (
    onTarget: onTarget,
    total: total,
    tooShort: tooShort,
    tooLong: tooLong
  );
}

// ────────────────────────────────────────────────────────────────────────────
// 3. INTENSITY DONUT ROW — Rest · RIR distribution · Plan adherence
// ────────────────────────────────────────────────────────────────────────────

/// A single ring painted as a stack of coloured arcs (Whoop-style). Every
/// segment is given as (value, color). Values need not sum to 1 — they are
/// proportionally normalised. A transparent "missing" segment fills the
/// rest of the circumference.
class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final Color trackColor;
  final double strokeWidth;

  _DonutPainter({
    required this.segments,
    required this.trackColor,
    // Kept as an optional override even though every current call site uses
    // the default — future smaller donut placements (in collapsed detail
    // rows) may want a thinner ring without changing the painter surface.
    // ignore: unused_element_parameter
    this.strokeWidth = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    // Segments
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * 0.999;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = seg.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class _DonutSegment {
  final double value;
  final Color color;
  const _DonutSegment(this.value, this.color);
}

/// Card wrapping a single donut with a center label and a bottom caption.
class _DonutCard extends StatelessWidget {
  final String title;
  final String centerBig;    // big number inside the ring
  final String? centerSmall; // unit / smaller text under the big number
  final String? caption;     // line under the ring (e.g. '11 / 12 on-target')
  final List<_DonutSegment> segments;
  final bool isDark;

  const _DonutCard({
    required this.title,
    required this.centerBig,
    required this.segments,
    required this.isDark,
    this.centerSmall,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Let the title wrap to 2 lines so longer labels like
          // "REST COMPLIANCE" and "PLAN ADHERENCE" aren't clipped to
          // "REST COMPLI..." on narrow 3-column donut rows.
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.8,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _DonutPainter(
                    segments: segments,
                    trackColor: track,
                  ),
                  size: const Size.square(90),
                ),
                Padding(
                  // Keep the center content inside the ring so longer
                  // labels like "MODERATE" scale down instead of
                  // pushing past the donut stroke.
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerBig,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ),
                      if (centerSmall != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          centerSmall!,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              style: TextStyle(
                fontSize: 10.5,
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Apple-Fitness-style concentric rings showing the whole session's
/// "health" at a glance. Three rings from outer to inner:
///   1. Plan adherence   (purple)  — % of planned exercises completed
///   2. Intensity cover  (orange)  — % of working sets tagged with an
///                                    effort level (non-null RIR)
///   3. Rest compliance  (teal)    — % of rest intervals within ±15%
///                                    of prescribed
///
/// Center shows a composite Session Score (0-100) plus a legend below.
/// Replaces the old triple-donut row — consolidates the rest-compliance
/// + rest-efficiency double-dipping and gives a single glanceable visual.
class _SessionScoreRings extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final bool isDark;

  const _SessionScoreRings({
    required this.data,
    required this.metadata,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final teal = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    // ── Plan adherence ─────────────────────────────────────
    final skippedIndices = (metadata?['skipped_exercise_indices'] is List)
        ? (metadata!['skipped_exercise_indices'] as List).length
        : 0;
    final exerciseOrder = (metadata?['exercise_order'] is List)
        ? metadata!['exercise_order'] as List
        : const [];
    final totalPlanned = exerciseOrder.length;
    final completedCount = totalPlanned - skippedIndices;
    final adherence =
        totalPlanned == 0 ? null : completedCount / totalPlanned;

    // ── Intensity coverage ─────────────────────────────────
    // What fraction of working sets actually have an RIR value? A
    // fully-logged session = 100%. Silent defaults / skipped prompts
    // drag this down.
    final perfLogs = data?.setLogs ?? const [];
    int working = 0;
    int rirLogged = 0;
    for (final sl in perfLogs) {
      if (sl.setType == 'working') {
        working++;
        if (sl.rir != null) rirLogged++;
      }
    }
    // Stash the property in a local so Dart's null-flow-analysis can
    // promote past the second `metadata[...]` access — instance fields
    // can change between reads, so the compiler won't promote them.
    final meta = metadata;
    if (working == 0 && meta != null) {
      final setsJson = (meta['sets_json'] is List)
          ? meta['sets_json'] as List
          : const [];
      for (final s in setsJson) {
        if (s is Map<String, dynamic>) {
          working++;
          if (s['rir'] is num) rirLogged++;
        }
      }
    }
    final intensityCoverage = working == 0 ? null : rirLogged / working;

    // ── Rest compliance ────────────────────────────────────
    final restStats = _computeRestStats(metadata);
    final rest = restStats.total == 0
        ? null
        : restStats.onTarget / restStats.total;

    // ── Composite Session Score (0-100) ────────────────────
    // Weighted mean of the 3 available metrics. Missing metrics drop
    // out rather than scoring 0.
    final parts = <(double, double)>[]; // (value, weight)
    if (adherence != null) parts.add((adherence, 0.4));
    if (intensityCoverage != null) parts.add((intensityCoverage, 0.3));
    if (rest != null) parts.add((rest, 0.3));
    double? score;
    if (parts.isNotEmpty) {
      final totalWeight = parts.fold<double>(0, (a, p) => a + p.$2);
      final weighted = parts.fold<double>(0, (a, p) => a + p.$1 * p.$2);
      score = (weighted / totalWeight) * 100;
    }

    final scoreColor = score == null
        ? textMuted
        : score >= 85
            ? AppColors.success
            : score >= 65
                ? orange
                : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'SESSION SCORE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Rings visualization
              SizedBox(
                width: 148,
                height: 148,
                child: CustomPaint(
                  painter: _SessionRingsPainter(
                    adherence: adherence,
                    intensity: intensityCoverage,
                    rest: rest,
                    adherenceColor: purple,
                    intensityColor: orange,
                    restColor: teal,
                    trackColor: track,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              score == null
                                  ? '—'
                                  : score.round().toString(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: scoreColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'out of 100',
                              style: TextStyle(
                                fontSize: 9,
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend — 3 mini rows, one per ring
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RingLegendRow(
                      color: purple,
                      label: 'Plan',
                      valueLabel: adherence == null
                          ? 'No plan data'
                          : '${(adherence * 100).round()}% · '
                              '$completedCount / $totalPlanned exercises',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _RingLegendRow(
                      color: orange,
                      label: 'Effort',
                      valueLabel: intensityCoverage == null
                          ? 'No working sets'
                          : intensityCoverage >= 0.999
                              ? 'Every set rated'
                              : '${(intensityCoverage * 100).round()}% · '
                                  '$rirLogged / $working sets rated',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _RingLegendRow(
                      color: teal,
                      label: 'Rest',
                      valueLabel: rest == null
                          ? 'No rest data'
                          : '${(rest * 100).round()}% on target · '
                              '${restStats.tooShort} short · '
                              '${restStats.tooLong} long',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String valueLabel;
  final Color textPrimary;
  final Color textSecondary;

  const _RingLegendRow({
    required this.color,
    required this.label,
    required this.valueLabel,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionRingsPainter extends CustomPainter {
  final double? adherence;
  final double? intensity;
  final double? rest;
  final Color adherenceColor;
  final Color intensityColor;
  final Color restColor;
  final Color trackColor;

  _SessionRingsPainter({
    required this.adherence,
    required this.intensity,
    required this.rest,
    required this.adherenceColor,
    required this.intensityColor,
    required this.restColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 10.0;
    const gap = 4.0;
    final outerR = size.shortestSide / 2 - stroke / 2;
    final middleR = outerR - stroke - gap;
    final innerR = middleR - stroke - gap;

    void paintRing(double radius, double? value, Color color) {
      if (radius <= 0) return;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawCircle(center, radius, trackPaint);
      if (value == null || value <= 0) return;
      final sweep = (value.clamp(0.0, 1.0)) * 2 * math.pi * 0.999;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
    }

    paintRing(outerR, adherence, adherenceColor);
    paintRing(middleR, intensity, intensityColor);
    paintRing(innerR, rest, restColor);
  }

  @override
  bool shouldRepaint(_SessionRingsPainter old) =>
      old.adherence != adherence ||
      old.intensity != intensity ||
      old.rest != rest ||
      old.adherenceColor != adherenceColor ||
      old.intensityColor != intensityColor ||
      old.restColor != restColor ||
      old.trackColor != trackColor;
}

/// Three donuts side by side. Each row is self-contained; computations
/// tolerate missing or old data by falling back to an "—" display.
class _IntensityDonutRow extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final bool isDark;

  const _IntensityDonutRow({
    required this.data,
    required this.metadata,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final warning = isDark ? AppColors.warning : AppColorsLight.warning;
    final error = isDark ? AppColors.error : AppColorsLight.error;
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // ── Rest Compliance ──
    int restTotal = 0;
    int onTarget = 0;
    int tooShort = 0;
    int tooLong = 0;
    final intervals = (metadata?['rest_intervals'] is List)
        ? metadata!['rest_intervals'] as List
        : const [];
    for (final ri in intervals) {
      if (ri is Map<String, dynamic>) {
        final actual = (ri['rest_seconds'] as num?)?.toDouble();
        final prescribed = (ri['prescribed_rest_seconds'] as num?)?.toDouble();
        if (actual == null || prescribed == null || prescribed <= 0) continue;
        restTotal++;
        final delta = (actual - prescribed) / prescribed;
        if (delta.abs() <= 0.15) {
          onTarget++;
        } else if (delta < 0) {
          tooShort++;
        } else {
          tooLong++;
        }
      }
    }
    final restPct = restTotal == 0 ? null : (100 * onTarget / restTotal);
    final restDonut = _DonutCard(
      title: 'REST COMPLIANCE',
      centerBig: restPct == null ? '—' : '${restPct.toStringAsFixed(0)}%',
      centerSmall: restPct == null ? null : 'on target',
      segments: restTotal == 0
          ? [_DonutSegment(1, muted.withValues(alpha: 0.2))]
          : [
              _DonutSegment(onTarget.toDouble(), success),
              _DonutSegment(tooShort.toDouble(), warning),
              _DonutSegment(tooLong.toDouble(), error),
            ],
      caption: restTotal == 0
          ? 'No rest data'
          : '$onTarget on · $tooShort short · $tooLong long',
      isDark: isDark,
    );

    // ── RIR Distribution ── group working sets into 0-1 / 2-3 / 4+ buckets.
    int hard = 0;
    int moderate = 0;
    int easy = 0;
    final perf = data?.setLogs ?? const [];
    for (final sl in perf) {
      if (sl.setType != 'working' || sl.rir == null) continue;
      final r = sl.rir!;
      if (r <= 1) {
        hard++;
      } else if (r <= 3) {
        moderate++;
      } else {
        easy++;
      }
    }
    // Metadata fallback (if perf logs empty)
    if (hard + moderate + easy == 0) {
      final setsJson = (metadata?['sets_json'] is List)
          ? metadata!['sets_json'] as List
          : const [];
      for (final s in setsJson) {
        if (s is Map<String, dynamic>) {
          final r = (s['rir'] as num?)?.toInt();
          if (r == null) continue;
          if (r <= 1) {
            hard++;
          } else if (r <= 3) {
            moderate++;
          } else {
            easy++;
          }
        }
      }
    }
    final rirTotal = hard + moderate + easy;
    // Center label describes the workout's dominant RIR bucket — users
    // reported "MOD" as cryptic, so render the full word when it fits.
    // Shortened "HARD" / "EASY" stay since they're already full words.
    String rirLabel;
    if (rirTotal == 0) {
      rirLabel = '—';
    } else if (hard >= moderate && hard >= easy) {
      rirLabel = 'HARD';
    } else if (moderate >= easy) {
      rirLabel = 'MODERATE';
    } else {
      rirLabel = 'EASY';
    }
    final rirDonut = _DonutCard(
      title: 'INTENSITY',
      centerBig: rirLabel,
      centerSmall: rirTotal == 0 ? null : '$rirTotal sets',
      segments: rirTotal == 0
          ? [_DonutSegment(1, muted.withValues(alpha: 0.2))]
          : [
              _DonutSegment(hard.toDouble(), error),
              _DonutSegment(moderate.toDouble(), warning),
              _DonutSegment(easy.toDouble(), success),
            ],
      caption: rirTotal == 0
          ? 'No RIR logged'
          : '$hard hard · $moderate mod · $easy easy',
      isDark: isDark,
    );

    // ── Plan Adherence ── completed / modified / skipped
    final skippedIndices = (metadata?['skipped_exercise_indices'] is List)
        ? (metadata!['skipped_exercise_indices'] as List).length
        : 0;
    final exerciseOrder = (metadata?['exercise_order'] is List)
        ? metadata!['exercise_order'] as List
        : const [];
    final totalPlanned = exerciseOrder.length;
    final completedCount = totalPlanned - skippedIndices;
    final adherencePct = totalPlanned == 0
        ? null
        : (100 * completedCount / totalPlanned).clamp(0.0, 100.0);
    final planDonut = _DonutCard(
      title: 'PLAN ADHERENCE',
      centerBig:
          adherencePct == null ? '—' : '${adherencePct.toStringAsFixed(0)}%',
      centerSmall: totalPlanned == 0
          ? null
          : '$completedCount / $totalPlanned',
      segments: totalPlanned == 0
          ? [_DonutSegment(1, muted.withValues(alpha: 0.2))]
          : [
              _DonutSegment(completedCount.toDouble(), purple),
              _DonutSegment(skippedIndices.toDouble(), muted),
            ],
      caption: totalPlanned == 0
          ? 'No plan data'
          : skippedIndices == 0
              ? 'All exercises completed'
              : '$skippedIndices skipped',
      isDark: isDark,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: restDonut),
        const SizedBox(width: 10),
        Expanded(child: rirDonut),
        const SizedBox(width: 10),
        Expanded(child: planDonut),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 4. SESSION TIMELINE + MUSCLE HEATMAP (side by side)
// ────────────────────────────────────────────────────────────────────────────

/// Vertical gantt-style timeline. Each exercise is a block whose height is
/// proportional to the time spent on that exercise (from
/// `exercise_order[*].time_spent_seconds`). Rests between exercises render
/// as thinner spacer blocks sized to the between-exercise rest seconds in
/// `rest_intervals` (so skipped rests shrink to nothing and long pauses
/// stand out visually).
class _SessionTimeline extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isDark;

  const _SessionTimeline({required this.metadata, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final exerciseOrder = (metadata['exercise_order'] is List)
        ? metadata['exercise_order'] as List
        : const [];
    final restIntervals = (metadata['rest_intervals'] is List)
        ? metadata['rest_intervals'] as List
        : const [];
    if (exerciseOrder.isEmpty) return const SizedBox.shrink();

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final restColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    // Build a map of between-exercise rest seconds keyed by the destination
    // exercise's index (rest AFTER exercise i-1 arrives at exercise i).
    final Map<int, int> betweenRestByDestIndex = {};
    int? lastExerciseIndex;
    for (final ri in restIntervals) {
      if (ri is Map<String, dynamic>) {
        final type = ri['rest_type'] as String?;
        final actual = (ri['rest_seconds'] as num?)?.toInt() ?? 0;
        final exId = ri['exercise_id'];
        int? exIdx;
        // Try to locate the destination exercise by id. Fall back to the
        // position in exercise_order where the id first appears.
        for (int i = 0; i < exerciseOrder.length; i++) {
          final eo = exerciseOrder[i];
          if (eo is Map<String, dynamic> && eo['exercise_id'] == exId) {
            exIdx = i;
            break;
          }
        }
        if (type == 'between_exercises' && exIdx != null && exIdx != lastExerciseIndex) {
          betweenRestByDestIndex[exIdx] =
              (betweenRestByDestIndex[exIdx] ?? 0) + actual;
          lastExerciseIndex = exIdx;
        }
      }
    }

    // Compute scale: total seconds to render.
    int totalSeconds = 0;
    for (final eo in exerciseOrder) {
      if (eo is Map<String, dynamic>) {
        totalSeconds += (eo['time_spent_seconds'] as num?)?.toInt() ?? 0;
      }
    }
    totalSeconds += betweenRestByDestIndex.values.fold<int>(0, (a, b) => a + b);
    if (totalSeconds <= 0) totalSeconds = 1; // avoid div/0

    // Target vertical budget ~320 dp so a 5-exercise session is compact.
    const maxHeight = 320.0;
    const minBlockHeight = 22.0;
    const minRestHeight = 6.0;
    double secondsToHeight(int secs) {
      if (secs <= 0) return 0;
      return (secs / totalSeconds) * maxHeight;
    }

    final children = <Widget>[];
    for (int i = 0; i < exerciseOrder.length; i++) {
      final eo = exerciseOrder[i];
      if (eo is! Map<String, dynamic>) continue;

      final restBefore = betweenRestByDestIndex[i] ?? 0;
      if (i > 0 && restBefore > 0) {
        final h = secondsToHeight(restBefore).clamp(minRestHeight, 60.0);
        children.add(Row(
          children: [
            const SizedBox(width: 52),
            Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: restColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'rest ${_formatDuration(restBefore)}',
              style: TextStyle(
                fontSize: 10.5,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ));
      }

      final secs = (eo['time_spent_seconds'] as num?)?.toInt() ?? 0;
      final blockHeight = secondsToHeight(secs).clamp(minBlockHeight, 120.0);
      final name = (eo['exercise_name'] as String?) ?? 'Exercise ${i + 1}';
      // NOTE: using CrossAxisAlignment.center (not stretch). The Row sits
      // inside an unbounded-height scroll view; stretch asks children
      // to fill infinite height → "BoxConstraints forces an infinite
      // height". The numbered badge self-centers via Center(), and the
      // timeline block sets its own [blockHeight] — nothing needs to
      // stretch vertically.
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            // Use a MIN-height constraint instead of a fixed height so
            // the block is at least `blockHeight` tall (preserving the
            // time-proportional visual) but can grow if the exercise
            // name wraps or the duration label pushes past the floor.
            // The previous fixed height caused the 5-10 px bottom
            // overflows when a short-rest exercise couldn't fit its
            // label text.
            child: Container(
              constraints: BoxConstraints(minHeight: blockHeight),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (blockHeight > 40) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(secs),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timeline_rounded, size: 14, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'SESSION TIMELINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  static String _formatDuration(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

/// Muscle heatmap rendered with the shared [BodyAtlasView] (same asset as
/// the Measurements screen). Each muscle is tinted from cool→warm based on
/// its share of the session's total training volume, with muscles that
/// received no work faded to a low-alpha grey so the whole silhouette still
/// reads as a body rather than a scatter of colored dots.
class _MuscleHeatmap extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final bool isDark;

  const _MuscleHeatmap({
    required this.data,
    required this.metadata,
    required this.isDark,
  });

  /// Per-muscle volume in kg·reps, keyed by lowercased muscle token (e.g.
  /// 'latissimus dorsi', 'chest', 'triceps brachii').
  Map<String, double> _computeVolumePerMuscleToken() {
    final Map<String, double> volumeByExercise = {};
    final setsJson = (metadata?['sets_json'] is List)
        ? metadata!['sets_json'] as List
        : const [];
    for (final s in setsJson) {
      if (s is! Map<String, dynamic>) continue;
      if (s['is_completed'] == false) continue;
      final name = (s['exercise_name'] as String?)?.trim().toLowerCase();
      if (name == null || name.isEmpty) continue;
      final weightKg = (s['weight_kg'] as num?)?.toDouble() ??
          (s['weight'] as num?)?.toDouble() ??
          0;
      final reps = (s['reps'] as num?)?.toInt() ?? 0;
      // Bodyweight sets have weightKg == 0 but still represent real volume
      // (reps × bodyweight). Keep them in the volume calc using a 1.0 unit
      // so the muscle map at least lights up when the user does a fully
      // bodyweight session — otherwise "Muscles Hit" reads "No volume yet"
      // even though the user trained their quads/glutes/hamstrings.
      if (reps <= 0) continue;
      final effectiveLoad = weightKg > 0 ? weightKg : 1.0;
      volumeByExercise[name] = (volumeByExercise[name] ?? 0) + effectiveLoad * reps;
    }
    // Fallback for pre-fix logs with `weight_lbs` only (not currently written
    // by buildSetsJson but safer to tolerate).
    if (volumeByExercise.isEmpty) {
      for (final sl in data?.setLogs ?? const []) {
        if (sl.setType != 'working' || sl.exerciseName.isEmpty) continue;
        final key = sl.exerciseName.toLowerCase();
        volumeByExercise[key] =
            (volumeByExercise[key] ?? 0) + sl.weightKg * sl.repsCompleted;
      }
    }

    // Map exercise_name → primary_muscle label from the plan, then extract
    // parenthesized muscle tokens (same parsing as the swap-similarity fix).
    // The backend sends `exercises_json` as a JSON STRING (not a List),
    // so decode it here if needed — otherwise the `is List` check silently
    // fell through to an empty plan and the Muscles-Hit atlas never
    // rendered.
    final rawExercisesJson = data?.workout['exercises_json'];
    List plan = const [];
    if (rawExercisesJson is List) {
      plan = rawExercisesJson;
    } else if (rawExercisesJson is String && rawExercisesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExercisesJson);
        if (decoded is List) plan = decoded;
      } catch (_) {
        // fall through with empty plan
      }
    }
    final Map<String, double> byToken = {};
    for (final entry in volumeByExercise.entries) {
      final exerciseName = entry.key;
      final vol = entry.value;
      String? muscleLabel;
      for (final ex in plan) {
        if (ex is Map<String, dynamic>) {
          final planName = (ex['name'] as String?)?.trim().toLowerCase();
          if (planName == exerciseName) {
            // Accept any of the three fields the backend might send —
            // `primary_muscle` (detailed), `muscle_group` (category),
            // or `body_part` (the field actually populated in
            // exercises_json on the workouts endpoint). Without the
            // body_part fallback the Muscles-Hit section rendered
            // "No volume data yet" even for completed workouts.
            muscleLabel = (ex['primary_muscle'] as String?) ??
                (ex['muscle_group'] as String?) ??
                (ex['body_part'] as String?);
            break;
          }
        }
      }
      if (muscleLabel == null || muscleLabel.trim().isEmpty) continue;
      final tokens = _extractMuscleTokens(muscleLabel);
      if (tokens.isEmpty) continue;
      // Split volume evenly across the primary muscle's listed anatomy.
      final share = vol / tokens.length;
      for (final t in tokens) {
        byToken[t] = (byToken[t] ?? 0) + share;
      }
    }
    return byToken;
  }

  /// Parse muscle descriptor label into anatomical tokens. Mirrors the
  /// server-side helper in focus_validation_utils.py so the behavior is
  /// consistent across client + server (e.g. "back (latissimus dorsi,
  /// teres major)" → {'back', 'latissimus dorsi', 'teres major'}).
  static Set<String> _extractMuscleTokens(String label) {
    final text = label.trim().toLowerCase();
    if (text.isEmpty) return {};
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    if (match == null) return {text};
    final region = text.substring(0, match.start).trim();
    final inner = match.group(1) ?? '';
    final tokens = <String>{};
    for (final t in inner.split(',')) {
      final tt = t.trim();
      if (tt.isNotEmpty) tokens.add(tt);
    }
    if (region.isNotEmpty) tokens.add(region);
    return tokens;
  }

  /// Build the `colorMapping` expected by [BodyAtlasView]. Uses loose
  /// substring matching between MuscleInfo names and our lowercased volume
  /// tokens — sufficient for the common muscles (chest, lats, triceps,
  /// etc.) without requiring an exhaustive anatomical lookup table.
  Map<MuscleInfo, Color?> _buildColorMapping(
    Map<String, double> volumeByToken,
    bool isDark,
  ) {
    if (volumeByToken.isEmpty) return const {};
    final maxVol = volumeByToken.values.fold<double>(0, math.max);
    if (maxVol <= 0) return const {};

    final cool = isDark
        ? const Color(0xFF4FC3F7) // cyan
        : const Color(0xFF0288D1);
    final hot = isDark
        ? const Color(0xFFFF7043) // orange
        : const Color(0xFFD84315);
    final idleTint = isDark
        ? const Color(0xFF6B7280).withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.12);

    Color shadeFor(double share) {
      // share in [0,1] — lerp cool→hot
      final t = share.clamp(0.0, 1.0);
      return Color.lerp(cool, hot, t)!
          .withValues(alpha: (0.45 + 0.5 * t).clamp(0.0, 1.0));
    }

    // For each MuscleInfo, check if any volume-token substring-matches its
    // name (case-insensitive both ways), then shade by the accumulated share.
    final Map<MuscleInfo, Color?> mapping = {};
    for (final m in MuscleCatalog.all) {
      final muscleName = m.displayName.toLowerCase();
      double share = 0;
      volumeByToken.forEach((token, vol) {
        if (muscleName.contains(token) || token.contains(muscleName)) {
          share += vol / maxVol;
        }
      });
      mapping[m] = share > 0 ? shadeFor(share.clamp(0, 1)) : idleTint;
    }
    return mapping;
  }

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final volumes = _computeVolumePerMuscleToken();
    final mapping = _buildColorMapping(volumes, isDark);

    if (mapping.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'MUSCLES HIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No volume data yet',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ),
        ],
      );
    }

    // Top 3 muscles by volume (for the caption under the body).
    final sortedTokens = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedTokens.fold<double>(0, (a, e) => a + e.value);
    final topLabels = sortedTokens.take(3).map((e) {
      final pct = total > 0 ? (100 * e.value / total).round() : 0;
      return '${_capitalise(e.key)} $pct%';
    }).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new_rounded, size: 14, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'MUSCLES HIT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 0.516, // SVG native aspect
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: BodyAtlasView<MuscleInfo>(
                view: AtlasAsset.musclesFront,
                resolver: const MuscleResolver(),
                colorMapping: mapping,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          topLabels,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ────────────────────────────────────────────────────────────────────────────
// 5. PYRAMID DEEP DIVE — per-exercise card whose bar shape reads the
//    progression model literally (🔺 Pyramid Up, ▬ Straight, 🔻 Reverse,
//    ⬇ Drop, ▲▬ Top Set + Back-off, etc.). Nobody else in the strength
//    tracker space renders the progression model as a visual shape.
// ────────────────────────────────────────────────────────────────────────────

class _PyramidDeepDiveSection extends StatelessWidget {
  final List<Map<String, dynamic>> setsJson;
  final bool isDark;

  const _PyramidDeepDiveSection({
    required this.setsJson,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (setsJson.isEmpty) return const SizedBox.shrink();
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Group sets by exercise_name (preserve first-seen order).
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final s in setsJson) {
      final name = (s['exercise_name'] as String?)?.trim();
      if (name == null || name.isEmpty || name == 'Unknown') continue;
      grouped.putIfAbsent(name, () => []).add(s);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'PER-EXERCISE DEEP DIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in grouped.entries) ...[
            _PyramidExerciseCard(
              exerciseName: entry.key,
              sets: entry.value,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PyramidExerciseCard extends StatefulWidget {
  final String exerciseName;
  final List<Map<String, dynamic>> sets;
  final bool isDark;

  const _PyramidExerciseCard({
    required this.exerciseName,
    required this.sets,
    required this.isDark,
  });

  @override
  State<_PyramidExerciseCard> createState() => _PyramidExerciseCardState();
}

class _PyramidExerciseCardState extends State<_PyramidExerciseCard> {
  bool _expanded = false;

  /// Canonicalise the progression_model string into a known shape key.
  String get _modelKey {
    final raw = widget.sets
        .map((s) => s['progression_model'] as String?)
        .firstWhere((x) => x != null && x.isNotEmpty, orElse: () => null);
    return (raw ?? 'straightSets').toString();
  }

  String get _modelLabel {
    switch (_modelKey) {
      case 'pyramidUp':
        return 'Pyramid Up';
      case 'reversePyramid':
        return 'Reverse Pyramid';
      case 'straightSets':
        return 'Straight Sets';
      case 'dropSets':
        return 'Drop Sets';
      case 'topSetBackOff':
        return 'Top Set + Back-off';
      case 'restPause':
        return 'Rest-Pause';
      case 'myoReps':
        return 'Myo-Reps';
      case 'endurance':
        return 'Endurance';
      default:
        return _modelKey;
    }
  }

  IconData get _modelIcon {
    switch (_modelKey) {
      case 'pyramidUp':
        return Icons.trending_up_rounded;
      case 'reversePyramid':
        return Icons.trending_down_rounded;
      case 'dropSets':
        return Icons.stairs_rounded;
      case 'topSetBackOff':
        return Icons.push_pin_rounded;
      case 'restPause':
        return Icons.pause_circle_outline_rounded;
      case 'myoReps':
        return Icons.bolt_rounded;
      case 'endurance':
        return Icons.timer_outlined;
      case 'straightSets':
      default:
        return Icons.horizontal_rule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark
        ? AppColors.purple
        : _darkenColor(AppColors.purple);
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = widget.isDark
        ? AppColors.textMuted
        : AppColorsLight.textMuted;
    final surface = widget.isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);

    // Sort sets by set_number for the shape rendering.
    final sorted = [...widget.sets]..sort((a, b) =>
        ((a['set_number'] as num?)?.toInt() ?? 0)
            .compareTo((b['set_number'] as num?)?.toInt() ?? 0));

    // Determine the weight range for bar scaling.
    double maxWeight = 0;
    for (final s in sorted) {
      final w = (s['weight_kg'] as num?)?.toDouble() ??
          (s['weight'] as num?)?.toDouble() ??
          0;
      if (w > maxWeight) maxWeight = w;
    }
    if (maxWeight <= 0) maxWeight = 1;

    // 1RM estimate (Epley) in lbs from the best set.
    double best1RM = 0;
    for (final s in sorted) {
      final w = (s['weight_kg'] as num?)?.toDouble() ??
          (s['weight'] as num?)?.toDouble() ??
          0;
      final r = (s['reps'] as num?)?.toInt() ?? 0;
      if (w > 0 && r > 0) {
        final lb = w * 2.20462;
        final est = r == 1 ? lb : lb * (1 + r / 30.0);
        if (est > best1RM) best1RM = est;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exerciseName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(_modelIcon, size: 11, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          _modelLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        if (best1RM > 0) ...[
                          Text(' · ',
                              style: TextStyle(fontSize: 11, color: textMuted)),
                          Text(
                            'est. 1RM ${best1RM.toStringAsFixed(0)} lb',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Shape: stacked bars per set, sorted top→bottom to visually match
          // the progression. For Pyramid Up the heaviest set is the LAST one,
          // so we render bottom→top (so the top bar is the lightest,
          // producing an actual pyramid silhouette).
          _PyramidShapeBars(
            sets: sorted,
            maxWeight: maxWeight,
            modelKey: _modelKey,
            isDark: widget.isDark,
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            _PyramidSetTable(sets: sorted, isDark: widget.isDark),
          ],
        ],
      ),
    );
  }
}

/// Renders per-set bars whose widths are proportional to weight (Pyramid Up
/// naturally looks like a triangle, Reverse Pyramid like an inverted one,
/// Straight Sets like flat slabs). Thin labels on each bar: weight × reps · RIR.
class _PyramidShapeBars extends StatelessWidget {
  final List<Map<String, dynamic>> sets;
  final double maxWeight;
  final String modelKey;
  final bool isDark;

  const _PyramidShapeBars({
    required this.sets,
    required this.maxWeight,
    required this.modelKey,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Row order:
    //   Pyramid Up: heaviest last → render in natural order so the BOTTOM
    //     of the stack is the heaviest (biggest bar). That gives the
    //     classic ▲ silhouette.
    //   Reverse Pyramid: heaviest first → render natural order so the TOP
    //     is heaviest (inverted ▼).
    //   Drop Sets: same rendering; natural order (heavy first, thin drops).
    //   Straight Sets: flat.
    final ordered = modelKey == 'pyramidUp'
        ? sets.reversed.toList() // widest bar at bottom → render top first
        : [...sets];

    Widget buildBar(Map<String, dynamic> s) {
      final weightKg = (s['weight_kg'] as num?)?.toDouble() ??
          (s['weight'] as num?)?.toDouble() ??
          0;
      final reps = (s['reps'] as num?)?.toInt() ?? 0;
      final rir = (s['rir'] as num?)?.toInt();
      final setNum = (s['set_number'] as num?)?.toInt() ?? 0;
      final widthFrac =
          (weightKg / maxWeight).clamp(0.08, 1.0); // always visible
      final lb = weightKg * 2.20462;
      final label = weightKg > 0 && reps > 0
          ? '${lb.toStringAsFixed(0)} lb × $reps'
          : reps > 0
              ? 'BW × $reps'
              : '—';
      // AMRAP / failure rendered slightly different
      final amrap = s['is_amrap'] == true;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '$setNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth * widthFrac;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: w.clamp(40.0, c.maxWidth),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.32),
                          accent.withValues(alpha: 0.18),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.55),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (amrap) ...[
                          const SizedBox(width: 4),
                          Text(
                            'AMRAP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: cyan,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                rir == null ? '—' : 'RIR $rir',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final s in ordered) buildBar(s),
      ],
    );
  }
}

/// Dense-detail disclosure: classic columnar table (Set / Prev / Target /
/// Weight / Reps / RIR / RPE) used when the user taps to expand a card.
class _PyramidSetTable extends StatelessWidget {
  final List<Map<String, dynamic>> sets;
  final bool isDark;

  const _PyramidSetTable({required this.sets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
      letterSpacing: 0.4,
    );
    final cellStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
    );
    String lb(double? kg) =>
        kg == null || kg <= 0 ? '—' : (kg * 2.20462).toStringAsFixed(0);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        dataRowMinHeight: 26,
        dataRowMaxHeight: 32,
        headingRowHeight: 26,
        columns: [
          DataColumn(label: Text('Set', style: headerStyle)),
          DataColumn(label: Text('Prev', style: headerStyle)),
          DataColumn(label: Text('Target', style: headerStyle)),
          DataColumn(label: Text('Weight', style: headerStyle)),
          DataColumn(label: Text('Reps', style: headerStyle)),
          DataColumn(label: Text('RIR', style: headerStyle)),
          DataColumn(label: Text('RPE', style: headerStyle)),
        ],
        rows: [
          for (final s in sets)
            DataRow(cells: [
              DataCell(Text('${(s['set_number'] as num?)?.toInt() ?? 0}',
                  style: cellStyle)),
              DataCell(Text(
                  (() {
                    final w = (s['previous_weight_kg'] as num?)?.toDouble();
                    final r = (s['previous_reps'] as num?)?.toInt();
                    return w != null && r != null
                        ? '${lb(w)}×$r'
                        : '—';
                  })(),
                  style: cellStyle)),
              DataCell(Text(
                  (() {
                    final w = (s['target_weight_kg'] as num?)?.toDouble();
                    final r = (s['target_reps'] as num?)?.toInt();
                    return w != null && r != null
                        ? '${lb(w)}×$r'
                        : '—';
                  })(),
                  style: cellStyle)),
              DataCell(Text(
                  lb((s['weight_kg'] as num?)?.toDouble() ??
                      (s['weight'] as num?)?.toDouble()),
                  style: cellStyle)),
              DataCell(Text('${(s['reps'] as num?)?.toInt() ?? 0}',
                  style: cellStyle)),
              DataCell(Text(
                  (s['rir'] as num?) != null ? '${s['rir']}' : '—',
                  style: cellStyle)),
              DataCell(Text(
                  (s['rpe'] as num?) != null
                      ? (s['rpe'] as num).toStringAsFixed(1)
                      : '—',
                  style: cellStyle)),
            ]),
        ],
      ),
    );
  }
}

/// Timeline + heatmap arranged side-by-side in a single card.
class _SessionTimelineAndHeatmap extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final bool isDark;

  const _SessionTimelineAndHeatmap({
    required this.data,
    required this.metadata,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (metadata == null) return const SizedBox.shrink();
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _MuscleHeatmap(
              data: data,
              metadata: metadata,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 6,
            child: _SessionTimeline(
              metadata: metadata!,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 6. COLLAPSIBLE "MORE DETAILS" — all the historical dense sections tucked
//    behind a single disclosure so the redesigned hero area stays tidy.
// ────────────────────────────────────────────────────────────────────────────

class _CollapsibleDetails extends StatefulWidget {
  final List<Widget> sections;
  final bool isDark;

  const _CollapsibleDetails({required this.sections, required this.isDark});

  @override
  State<_CollapsibleDetails> createState() => _CollapsibleDetailsState();
}

class _CollapsibleDetailsState extends State<_CollapsibleDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _expanded ? 'Hide details' : 'More details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.sections.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < widget.sections.length; i++) ...[
                    widget.sections[i],
                    if (i < widget.sections.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

