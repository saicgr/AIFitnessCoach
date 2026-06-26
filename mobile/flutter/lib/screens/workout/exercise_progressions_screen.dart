import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/exercise_progressions_repository.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
/// Exercise Progressions — surfaces the leverage-based progression-chain
/// engine (backend `exercise_progressions.py`).
///
/// Shows:
///  1. "Ready to advance" callouts — exercises the user has mastered and can
///     progress to a harder variant on (with an inline Advance action).
///  2. The user's tracked progression chains, each with its current mastery
///     level and the ordered ladder of variants.
///
/// Loading / error / empty states are all handled explicitly. No mock data,
/// no silent fallbacks — errors surface a retry-able error state.
class ExerciseProgressionsScreen extends ConsumerStatefulWidget {
  const ExerciseProgressionsScreen({super.key});

  @override
  ConsumerState<ExerciseProgressionsScreen> createState() =>
      _ExerciseProgressionsScreenState();
}

class _ExerciseProgressionsScreenState
    extends ConsumerState<ExerciseProgressionsScreen> {
  Future<_ProgressionData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProgressionData> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      throw Exception('You need to be signed in to view progressions.');
    }
    final repo = ref.read(exerciseProgressionsRepositoryProvider);
    // Parallel fetch — mastery + suggestions are independent.
    final results = await Future.wait([
      repo.getUserMastery(userId),
      repo.getSuggestions(userId),
    ]);
    return _ProgressionData(
      mastery: results[0] as List<ExerciseMasteryWithChain>,
      suggestions: results[1] as List<ProgressionSuggestionItem>,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  Future<void> _refresh() async {
    final fresh = _load();
    setState(() => _future = fresh);
    await fresh;
  }

  /// Confirm + POST the progression. On success, reload the screen so the
  /// advanced exercise drops out of the "ready" list.
  Future<void> _advance(ProgressionSuggestionItem s) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).exerciseProgressionsAdvanceProgression),
        content: Text(
          'You will move from ${s.exerciseName} to ${s.suggestedExercise}. '
          'Your mastery streak resets so you can build it on the harder variant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).exerciseProgressionsNotYet),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).exerciseProgressionsAdvance),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return;

    HapticFeedback.mediumImpact();
    try {
      final resp = await ref
          .read(exerciseProgressionsRepositoryProvider)
          .acceptProgression(
            userId: userId,
            currentExercise: s.exerciseName,
            newExercise: s.suggestedExercise,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.message),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      _retry();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not advance: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final background = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: background,
      appBar: PillAppBar(title: AppLocalizations.of(context).exerciseProgressionsProgressions),
      body: FutureBuilder<_ProgressionData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingState(accent: accent);
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: _humanError(snapshot.error),
              accent: accent,
              onRetry: _retry,
            );
          }
          final data = snapshot.data ?? const _ProgressionData(
            mastery: [],
            suggestions: [],
          );
          if (data.mastery.isEmpty && data.suggestions.isEmpty) {
            return _EmptyState(accent: accent, onRefresh: _retry);
          }
          return RefreshIndicator(
            color: accent,
            onRefresh: _refresh,
            child: _Content(
              data: data,
              isDark: isDark,
              accent: accent,
              onAdvance: _advance,
            ),
          );
        },
      ),
    );
  }

  String _humanError(Object? error) {
    final raw = error.toString();
    if (raw.contains('signed in')) {
      return 'You need to be signed in to view your progressions.';
    }
    return 'We could not load your progressions. Check your connection and try again.';
  }
}

// ===========================================================================
// Data holder
// ===========================================================================

class _ProgressionData {
  final List<ExerciseMasteryWithChain> mastery;
  final List<ProgressionSuggestionItem> suggestions;

  const _ProgressionData({required this.mastery, required this.suggestions});
}

// ===========================================================================
// Content
// ===========================================================================

class _Content extends StatelessWidget {
  final _ProgressionData data;
  final bool isDark;
  final Color accent;
  final ValueChanged<ProgressionSuggestionItem> onAdvance;

  const _Content({
    required this.data,
    required this.isDark,
    required this.accent,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    // Tracked chains first, then loose (non-chain) exercises.
    final tracked = data.mastery.where((m) => m.isInChain).toList()
      ..sort((a, b) {
        // Ready-to-advance bubble to the top, then by last performed.
        if (a.readyForProgression != b.readyForProgression) {
          return a.readyForProgression ? -1 : 1;
        }
        final ad = a.lastPerformedAt;
        final bd = b.lastPerformedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    final loose = data.mastery.where((m) => !m.isInChain).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _Intro(isDark: isDark, accent: accent),
        const SizedBox(height: 20),

        // ── Hold-time progress (Dr-Yaad audit #11) ── self-hides when the
        // user has no timed-skill history (<2 sessions of a hold movement).
        _HoldTimeChart(mastery: data.mastery, isDark: isDark, accent: accent),

        // ── Ready to advance ──
        if (data.suggestions.isNotEmpty) ...[
          _SectionLabel(
            label: AppLocalizations.of(context).exerciseProgressionsReadyToAdvance,
            count: data.suggestions.length,
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: 10),
          ...data.suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReadyCard(
                suggestion: s,
                isDark: isDark,
                accent: accent,
                onAdvance: () => onAdvance(s),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Tracked chains ──
        if (tracked.isNotEmpty) ...[
          _SectionLabel(
            label: AppLocalizations.of(context).exerciseProgressionsYourProgressionChains,
            count: tracked.length,
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: 10),
          ...tracked.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChainCard(mastery: m, isDark: isDark, accent: accent),
            ),
          ),
        ],

        // ── Loose exercises (tracked but not in a chain) ──
        if (loose.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SectionLabel(
            label: AppLocalizations.of(context).exerciseProgressionsOtherTrackedExercises,
            count: loose.length,
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: 10),
          ...loose.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LooseCard(mastery: m, isDark: isDark, accent: accent),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Hold-time progress chart (Dr-Yaad audit #11)
// ===========================================================================

/// A small line chart of best-hold seconds over recent sessions for the user's
/// most relevant timed skill, with a dashed goal line at the next unlock
/// target. Picks the skill itself (most-recently-performed hold movement),
/// fetches its history, and self-hides when there is <2 sessions of data.
class _HoldTimeChart extends ConsumerStatefulWidget {
  final List<ExerciseMasteryWithChain> mastery;
  final bool isDark;
  final Color accent;

  const _HoldTimeChart({
    required this.mastery,
    required this.isDark,
    required this.accent,
  });

  @override
  ConsumerState<_HoldTimeChart> createState() => _HoldTimeChartState();
}

class _HoldTimeChartState extends ConsumerState<_HoldTimeChart> {
  // Movement names that are held for time — the calisthenics "skill" bucket.
  static const _holdNeedles = [
    'hold', 'plank', 'l-sit', 'lsit', 'l sit', 'lever', 'planche', 'handstand',
    'hang', 'hollow', 'bridge', 'wall sit', 'tuck', 'flag', 'iso',
  ];

  Future<HoldHistory?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  String? _pickTimedSkill() {
    final candidates = widget.mastery.where((m) {
      final n = m.exerciseName.toLowerCase();
      return _holdNeedles.any((needle) => n.contains(needle));
    }).toList()
      ..sort((a, b) {
        final ad = a.lastPerformedAt, bd = b.lastPerformedAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    return candidates.isEmpty ? null : candidates.first.exerciseName;
  }

  Future<HoldHistory?> _load() async {
    final name = _pickTimedSkill();
    if (name == null) return null;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) return null;
    try {
      return await ref
          .read(exerciseProgressionsRepositoryProvider)
          .getHoldHistory(userId, name);
    } catch (_) {
      // A failed secondary chart must never break the screen — hide silently.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HoldHistory?>(
      future: _future,
      builder: (context, snapshot) {
        final h = snapshot.data;
        if (h == null || !h.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildCard(context, h),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, HoldHistory h) {
    final cardColor =
        widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final border = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final spots = <FlSpot>[
      for (int i = 0; i < h.points.length; i++)
        FlSpot(i.toDouble(), h.points[i].bestHoldSeconds.toDouble()),
    ];
    final maxData = h.points
        .map((p) => p.bestHoldSeconds)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY =
        ((h.targetHoldSeconds ?? 0) > maxData ? h.targetHoldSeconds! : maxData)
            .toDouble();
    final current = h.currentBestHoldSeconds ?? h.points.last.bestHoldSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: widget.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hold-time progress · ${h.exerciseName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            h.targetHoldSeconds != null
                ? 'Now ${current}s · next unlock at ${h.targetHoldSeconds}s'
                : 'Now ${current}s · longest holds per session',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY <= 0 ? 10 : maxY) / 2,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: border.withOpacity(0.5), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toInt()}s',
                        style: TextStyle(fontSize: 9, color: muted),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: h.targetHoldSeconds != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: h.targetHoldSeconds!.toDouble(),
                          color: widget.accent.withOpacity(0.7),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                        ),
                      ])
                    : const ExtraLinesData(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: widget.accent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: widget.accent.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Intro banner
// ===========================================================================

class _Intro extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _Intro({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.28 : 0.18),
            accent.withValues(alpha: isDark ? 0.10 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.stairs_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).exerciseProgressionsEarnTheHarderVariant,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When an exercise gets easy, the next step is a tougher '
                  'variant, not just more reps. Rate sessions to climb the ladder.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Section label
// ===========================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;
  final Color accent;

  const _SectionLabel({
    required this.label,
    required this.count,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color:
                isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Ready-to-advance card
// ===========================================================================

class _ReadyCard extends StatelessWidget {
  final ProgressionSuggestionItem suggestion;
  final bool isDark;
  final Color accent;
  final VoidCallback onAdvance;

  const _ReadyCard({
    required this.suggestion,
    required this.isDark,
    required this.accent,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final confidencePct = (suggestion.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.green.withValues(alpha: isDark ? 0.22 : 0.14),
            AppColors.green.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  suggestion.chainName.isEmpty
                      ? AppLocalizations.of(context).exerciseProgressionsReadyToProgress
                      : suggestion.chainName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.green,
                  ),
                ),
              ),
              Text(
                '$confidencePct% confident',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Exercise transition row — current -> suggested. Wrap so it never
          // overflows on a narrow device (iPhone SE).
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _ExercisePill(
                label: suggestion.exerciseName,
                difficultyLevel: suggestion.currentDifficultyLevel,
                isDark: isDark,
                highlighted: false,
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: textSecondary),
              _ExercisePill(
                label: suggestion.suggestedExercise,
                difficultyLevel: suggestion.suggestedDifficultyLevel,
                isDark: isDark,
                highlighted: true,
                accent: AppColors.green,
              ),
            ],
          ),
          if (suggestion.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              suggestion.reason,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdvance,
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: Text('Advance to ${suggestion.suggestedExercise}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  final String label;

  /// 1-10 integer difficulty level (backend `difficulty_level`).
  final int difficultyLevel;
  final bool isDark;
  final bool highlighted;
  final Color? accent;

  const _ExercisePill({
    required this.label,
    required this.difficultyLevel,
    required this.isDark,
    required this.highlighted,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final base = accent ??
        (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? base.withValues(alpha: 0.2)
            : (isDark ? AppColors.elevated : AppColorsLight.elevated),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? base.withValues(alpha: 0.5)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: highlighted
                  ? base
                  : (isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary),
            ),
          ),
          Text(
            'Difficulty $difficultyLevel/10',
            style: TextStyle(
              fontSize: 10,
              color:
                  isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Chain card — a tracked exercise that belongs to a progression chain.
// ===========================================================================

class _ChainCard extends StatelessWidget {
  final ExerciseMasteryWithChain mastery;
  final bool isDark;
  final Color accent;

  const _ChainCard({
    required this.mastery,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final statusColor = _statusColor(mastery.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
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
                      mastery.exerciseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if ((mastery.chainName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${mastery.chainName} chain',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(
                label: mastery.status.label,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mastery progress toward the next variant: 2 consecutive "too
          // easy" sessions unlocks progression (backend rule).
          _MasteryBar(
            consecutiveEasy: mastery.consecutiveEasySessions,
            ready: mastery.readyForProgression,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _Stat(
                icon: Icons.repeat_rounded,
                label: AppLocalizations.of(context).syncedWorkoutsHistorySessions,
                value: '${mastery.totalSessions}',
                isDark: isDark,
              ),
              _Stat(
                icon: Icons.fitness_center_rounded,
                label: AppLocalizations.of(context).exerciseProgressionsBestReps,
                value: '${mastery.currentMaxReps}',
                isDark: isDark,
              ),
              if (mastery.currentMaxWeight != null)
                _Stat(
                  icon: Icons.scale_rounded,
                  label: AppLocalizations.of(context).exerciseProgressionsBestLoad,
                  value: '${mastery.currentMaxWeight!.toStringAsFixed(1)} kg',
                  isDark: isDark,
                ),
            ],
          ),
          if (mastery.readyForProgression &&
              (mastery.nextStep != null ||
                  (mastery.suggestedNextVariant ?? '').isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_circle_up_rounded,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Next up: '
                      '${mastery.nextStep?.name ?? mastery.suggestedNextVariant}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!mastery.readyForProgression) ...[
            const SizedBox(height: 10),
            Text(
              mastery.consecutiveEasySessions >= 1
                  ? AppLocalizations.of(context).exerciseProgressionsOneMoreTooEasy
                  : 'Keep logging sessions and rate the difficulty to climb.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(ProgressionMasteryStatus status) {
    switch (status) {
      case ProgressionMasteryStatus.learning:
        return AppColors.waterBlue;
      case ProgressionMasteryStatus.proficient:
        return AppColors.cyan;
      case ProgressionMasteryStatus.mastered:
        return AppColors.green;
      case ProgressionMasteryStatus.progressed:
        return AppColors.purple;
    }
  }
}

// ===========================================================================
// Loose card — a tracked exercise NOT part of a chain.
// ===========================================================================

class _LooseCard extends StatelessWidget {
  final ExerciseMasteryWithChain mastery;
  final bool isDark;
  final Color accent;

  const _LooseCard({
    required this.mastery,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.show_chart_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mastery.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mastery.totalSessions} sessions · best '
                  '${mastery.currentMaxReps} reps',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          _StatusChip(
            label: mastery.status.label,
            color: _ChainCard._statusColor(mastery.status),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Small reusable widgets
// ===========================================================================

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  final int consecutiveEasy;
  final bool ready;
  final Color accent;
  final bool isDark;

  /// 2 consecutive "too easy" sessions = progression unlocked (backend rule).
  static const int _target = 2;

  const _MasteryBar({
    required this.consecutiveEasy,
    required this.ready,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ready
        ? 1.0
        : (consecutiveEasy / _target).clamp(0.0, 1.0);
    final barColor = ready ? AppColors.green : accent;
    final track =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              ready ? AppLocalizations.of(context).exerciseProgressionsReadyToAdvance2 : AppLocalizations.of(context).exerciseProgressionsMasteryProgress,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: ready
                    ? AppColors.green
                    : (isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary),
              ),
            ),
            const Spacer(),
            Text(
              ready ? AppLocalizations.of(context).exerciseProgressionsUnlocked : '$consecutiveEasy / $_target easy sessions',
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 5),
        Text(
          '$value ',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }
}

// ===========================================================================
// Loading / error / empty states
// ===========================================================================

class _LoadingState extends StatelessWidget {
  final Color accent;
  const _LoadingState({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).exerciseProgressionsLoadingYourProgressions),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).workoutReviewTryAgain),
              style: FilledButton.styleFrom(backgroundColor: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accent;
  final VoidCallback onRefresh;

  const _EmptyState({required this.accent, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stairs_rounded, size: 36, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context).exerciseProgressionsNoProgressionsYet,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log workouts with progression-chain exercises (push-ups, '
              'rows, squats) and rate how hard they felt. We will track your '
              'mastery and tell you when to step up to a harder variant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).timelineRefresh),
              style: OutlinedButton.styleFrom(foregroundColor: accent),
            ),
          ],
        ),
      ),
    );
  }
}
