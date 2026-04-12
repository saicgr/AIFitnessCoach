import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    final sections = <Widget>[];
    int delay = 0;

    // 1. Performance comparison (only if there's a previous workout to compare)
    if (data?.performanceComparison != null &&
        data!.performanceComparison!.workoutComparison.hasPrevious) {
      sections.add(
        _PerformanceComparisonSection(
          comparison: data!.performanceComparison!,
          isDark: isDark,
        ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
      );
      delay += 80;
    }

    if (_hasMetadata) {
      final meta = metadata!;

      // 1b. Per-Exercise Deep Dive (skip sets with no real exercise name)
      final setsJson = _castList(meta['sets_json'])
          .where((s) {
            final name = s['exercise_name'] as String?;
            return name != null && name.isNotEmpty && name != 'Unknown';
          })
          .toList();
      if (setsJson.isNotEmpty) {
        sections.add(
          _PerExerciseDeepDiveSection(
            setsJson: setsJson,
            drinkEvents: _castList(meta['drink_events']),
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 1c. Superset Details
      final supersets = _castList(meta['supersets']);
      if (supersets.isNotEmpty) {
        sections.add(
          _SupersetDetailsSection(
            supersets: supersets,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 1d. Exercise Order & Time
      final exerciseOrder = _castList(meta['exercise_order']);
      if (exerciseOrder.isNotEmpty) {
        sections.add(
          _ExerciseOrderSection(
            exercises: exerciseOrder,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 1e. Workout Exit Stats (quit early)
      final quitEarly = meta['quit_early'] as bool? ??
          (data?.completionMethod == 'quit_early');
      if (quitEarly) {
        sections.add(
          _WorkoutExitStatsSection(
            metadata: meta,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 2. Warmup & Stretch
      final warmupExercises = _castList(meta['warmup_exercises']);
      final stretchExercises = _castList(meta['stretch_exercises']);
      final warmupStatus = meta['warmup_status'] as String?;
      final stretchStatus = meta['stretch_status'] as String?;
      if (warmupExercises.isNotEmpty ||
          stretchExercises.isNotEmpty ||
          warmupStatus != null ||
          stretchStatus != null) {
        sections.add(
          _WarmupStretchSection(
            warmupExercises: warmupExercises,
            stretchExercises: stretchExercises,
            warmupStatus: warmupStatus,
            stretchStatus: stretchStatus,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 3. Rest analysis
      final restIntervals = _castList(meta['rest_intervals']);
      if (restIntervals.isNotEmpty) {
        sections.add(
          _RestAnalysisSection(
            intervals: restIntervals,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 4. Hydration
      final drinkEvents = _castList(meta['drink_events']);
      final drinkIntake = meta['drink_intake_ml'] as int?;
      if (drinkEvents.isNotEmpty || (drinkIntake != null && drinkIntake > 0)) {
        sections.add(
          _HydrationSection(
            drinkEvents: drinkEvents,
            totalMl: drinkIntake ?? 0,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 5. AI interactions
      final aiInteractions = meta['ai_interactions'] as Map<String, dynamic>?;
      if (aiInteractions != null && aiInteractions.isNotEmpty) {
        sections.add(
          _AIInteractionsSection(
            interactions: aiInteractions,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 6. Subjective feedback
      final feedback = meta['subjective_feedback'] as Map<String, dynamic>?;
      if (feedback != null && feedback.isNotEmpty) {
        sections.add(
          _SubjectiveFeedbackSection(
            feedback: feedback,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // 7. Increment settings
      final incrementSettings = meta['increment_settings'] as Map<String, dynamic>?;
      if (incrementSettings != null && incrementSettings.isNotEmpty) {
        sections.add(
          _SettingsUsedSection(
            settings: incrementSettings,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }
    }

    // ── Sections derived from setLogs (always available if tracked) ──
    if (hasSetLogs) {
      final logs = data!.setLogs;
      final workingSets = logs.where((l) => l.setType == 'working').toList();

      // Volume Breakdown per exercise
      if (workingSets.isNotEmpty) {
        sections.add(
          _VolumeBreakdownSection(
            setLogs: workingSets,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // Intensity Analysis (RPE / RIR)
      final logsWithRpe = workingSets.where((l) => l.rpe != null).toList();
      final logsWithRir = workingSets.where((l) => l.rir != null).toList();
      if (logsWithRpe.isNotEmpty || logsWithRir.isNotEmpty) {
        sections.add(
          _IntensityAnalysisSection(
            setLogs: workingSets,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // Estimated 1RM per exercise
      if (workingSets.any((l) => l.weightKg > 0 && l.repsCompleted > 0)) {
        sections.add(
          _Estimated1RMSection(
            setLogs: workingSets,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }

      // Set Type Distribution
      if (logs.length > 1) {
        sections.add(
          _SetTypeDistributionSection(
            setLogs: logs,
            isDark: isDark,
          ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay)),
        );
        delay += 80;
      }
    }

    // If we gathered no sections at all, show the info banner
    if (sections.isEmpty) {
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
          ...sections,
          // 9. Bottom padding for floating pill
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
    // Group sets by exercise name (case insensitive)
    final grouped = <String, List<Map<String, dynamic>>>{};
    final originalNames = <String, String>{}; // lowercase -> original
    for (final s in setsJson) {
      final name = s['exercise_name'] as String? ?? 'Unknown';
      final key = name.toLowerCase();
      originalNames.putIfAbsent(key, () => name);
      grouped.putIfAbsent(key, () => []).add(s);
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

          // Calculate 1RM from best set (Epley formula)
          double? best1RM;
          for (final s in sets) {
            final w = (s['weight'] as num?)?.toDouble();
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
          final weight = (s['weight'] as num?)?.toDouble();
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
