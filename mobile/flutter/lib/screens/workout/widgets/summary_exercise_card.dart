/// Collapsible per-exercise card for the unified Workout Summary scroll.
///
/// Each exercise is its own card so a long session is a tidy, scannable list
/// instead of one giant table:
///   - Collapsed: name + a one-line recap ("4 sets · top 25 lb · 40 reps").
///   - Tap the row (or the chevron) to expand the full Set / Previous / Target
///     / weight / reps grid (reused from [SummaryExerciseSetsTable]).
///   - A "›" opens the full exercise detail screen (Info / Stats / History /
///     Form-video tabs).
///   - A "✨ AI" button fetches an on-demand, cached per-exercise breakdown that
///     reads prior history, PRs, RIR, rest, pain/injury and form-video context
///     server-side (POST /feedback/exercise-summary).
///
/// Self-contained: owns its own expand + AI fetch state. An optional
/// [expandSignal] lets the host broadcast expand-all / collapse-all.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/simple_markdown_text.dart';
import 'summary_exercise_table.dart';

enum _AiStatus { idle, loading, ready, error }

class SummaryExerciseCard extends ConsumerStatefulWidget {
  final SummaryExerciseData exercise;

  /// The plan/session id (matches `workout_id` server-side).
  final String workoutId;

  /// The specific completion the per-exercise AI is keyed by.
  final String? workoutLogId;

  /// Gym scope for history / PR / form lookups (nullable — server resolves
  /// from the workout log when absent).
  final String? gymProfileId;

  final bool useKg;

  /// Broadcasts an expand-all (`true`) / collapse-all (`false`) request from
  /// the host. `null` is a no-op (initial state).
  final ValueListenable<bool?>? expandSignal;

  const SummaryExerciseCard({
    super.key,
    required this.exercise,
    required this.workoutId,
    required this.workoutLogId,
    this.gymProfileId,
    this.useKg = false,
    this.expandSignal,
  });

  @override
  ConsumerState<SummaryExerciseCard> createState() =>
      _SummaryExerciseCardState();
}

class _SummaryExerciseCardState extends ConsumerState<SummaryExerciseCard> {
  bool _expanded = false;

  _AiStatus _ai = _AiStatus.idle;
  String? _aiMarkdown;
  Map<String, dynamic>? _aiContext;

  @override
  void initState() {
    super.initState();
    widget.expandSignal?.addListener(_onExpandSignal);
  }

  @override
  void dispose() {
    widget.expandSignal?.removeListener(_onExpandSignal);
    super.dispose();
  }

  void _onExpandSignal() {
    final v = widget.expandSignal?.value;
    if (v == null || !mounted) return;
    if (_expanded != v) setState(() => _expanded = v);
  }

  bool get _canRunAi =>
      !widget.exercise.isSkipped &&
      widget.exercise.sets.isNotEmpty &&
      (widget.workoutLogId?.isNotEmpty ?? false);

  // ── Per-exercise AI (GET cache → POST generate) ──────────────────────────
  Future<void> _runAi({bool force = false}) async {
    if (!_canRunAi) return;
    HapticService.selection();
    setState(() {
      _ai = _AiStatus.loading;
      _expanded = true;
    });

    final api = ref.read(apiClientProvider);
    final ex = widget.exercise;
    final logId = widget.workoutLogId!;

    // 1) Cache read (instant, no LLM) unless forcing a refresh.
    if (!force) {
      try {
        final res = await api
            .get('/feedback/exercise-summary/$logId/${Uri.encodeComponent(ex.name)}');
        final data = res.data;
        if (mounted &&
            res.statusCode == 200 &&
            data is Map<String, dynamic> &&
            data['found'] != false &&
            (data['critique_markdown'] is String)) {
          setState(() {
            _aiMarkdown = data['critique_markdown'] as String;
            _aiContext = data['context'] is Map
                ? Map<String, dynamic>.from(data['context'] as Map)
                : null;
            _ai = _AiStatus.ready;
          });
          return;
        }
      } catch (_) {
        // Fall through to generate — a cache miss is the normal first run.
      }
    }

    // 2) Generate + persist.
    try {
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _ai = _AiStatus.error);
        return;
      }
      final sets = ex.sets
          .map((s) => <String, dynamic>{
                'set_number': s.setNumber,
                if (s.actualWeightKg != null) 'weight_kg': s.actualWeightKg,
                if (s.actualReps != null) 'reps': s.actualReps,
                if (s.rir != null) 'rir': s.rir,
                if (s.rpe != null) 'rpe': s.rpe,
              })
          .toList();
      final firstTargeted = ex.sets.firstWhere(
        (s) => s.targetWeightKg != null || s.targetReps != null,
        orElse: () => ex.sets.first,
      );
      final body = <String, dynamic>{
        'user_id': userId,
        'workout_id': widget.workoutId,
        'workout_log_id': logId,
        'exercise_name': ex.name,
        if (ex.libraryId != null) 'exercise_id': ex.libraryId,
        if (widget.gymProfileId != null) 'gym_profile_id': widget.gymProfileId,
        'sets': sets,
        if (firstTargeted.targetWeightKg != null ||
            firstTargeted.targetReps != null)
          'target': {
            if (firstTargeted.targetWeightKg != null)
              'weight_kg': firstTargeted.targetWeightKg,
            if (firstTargeted.targetReps != null)
              'reps': firstTargeted.targetReps,
          },
        'use_kg': widget.useKg,
        'force': force,
      };
      final res = await api.post(
        '/feedback/exercise-summary',
        data: body,
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );
      final data = res.data;
      if (mounted &&
          res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['critique_markdown'] is String) {
        setState(() {
          _aiMarkdown = data['critique_markdown'] as String;
          _aiContext = data['context'] is Map
              ? Map<String, dynamic>.from(data['context'] as Map)
              : null;
          _ai = _AiStatus.ready;
        });
      } else if (mounted) {
        setState(() => _ai = _AiStatus.error);
      }
    } catch (_) {
      if (mounted) setState(() => _ai = _AiStatus.error);
    }
  }

  void _openDetail({int initialTab = 0}) {
    HapticService.selection();
    final ex = widget.exercise;
    context.push('/exercise-detail', extra: <String, dynamic>{
      'exercise': <String, dynamic>{
        'id': ex.libraryId,
        'name': ex.name,
        'sets': ex.sets.length,
        'reps': ex.sets.isNotEmpty ? (ex.sets.first.targetReps ?? 0) : 0,
        if (ex.equipment != null) 'equipment': ex.equipment,
        if (ex.muscleGroup != null) 'muscle_group': ex.muscleGroup,
        if (ex.imageUrl != null) 'image_url': ex.imageUrl,
        if (ex.videoUrl != null) 'video_url': ex.videoUrl,
      },
      'initialTab': initialTab,
    });
  }

  // ── collapsed one-line recap ─────────────────────────────────────────────
  String _collapsedSummary() {
    final ex = widget.exercise;
    if (ex.isSkipped) return 'Skipped';
    final logged = ex.sets.where((s) => (s.actualReps ?? 0) > 0).toList();
    final setCount = logged.isNotEmpty ? logged.length : ex.sets.length;
    final parts = <String>['$setCount ${setCount == 1 ? 'set' : 'sets'}'];

    double topKg = 0;
    int totalReps = 0;
    for (final s in logged) {
      totalReps += s.actualReps ?? 0;
      final w = s.actualWeightKg ?? 0;
      if (w > topKg) topKg = w;
    }
    if (topKg > 0) {
      parts.add(
          'top ${WeightUtils.formatWorkoutWeight(topKg, useKg: widget.useKg)}');
    } else if (logged.isNotEmpty && totalReps > 0 && ex.sets.any((s) => s.isBodyweight)) {
      parts.add('bodyweight');
    }
    if (totalReps > 0) parts.add('$totalReps reps');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final ex = widget.exercise;
    final hasPrs = ex.prs != null && ex.prs!.isNotEmpty;

    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tap to expand/collapse.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasPrs) ...[
                              const Icon(Icons.star,
                                  size: 15, color: Color(0xFFEAB308)),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                ex.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ex.isSkipped ? textMuted : textPrimary,
                                  decoration: ex.isSkipped
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _collapsedSummary(),
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ✨ AI button
                  if (_canRunAi)
                    _IconPill(
                      icon: Icons.auto_awesome,
                      color: accent,
                      tooltip: 'AI breakdown',
                      onTap: _runAi,
                    ),
                  // Detail "›"
                  _IconPill(
                    icon: Icons.chevron_right_rounded,
                    color: textMuted,
                    tooltip: 'Exercise detail',
                    onTap: _openDetail,
                  ),
                  // Expand affordance
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Expanded body — sets grid + AI panel.
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SummaryExerciseSetsTable(exercise: ex, useKg: widget.useKg),
                  if (_ai != _AiStatus.idle)
                    _AiPanel(
                      status: _ai,
                      markdown: _aiMarkdown,
                      aiContext: _aiContext,
                      accent: accent,
                      isDark: isDark,
                      onRetry: () => _runAi(force: true),
                      onOpenForm: () => _openDetail(initialTab: 3),
                    ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconPill({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _AiPanel extends StatelessWidget {
  final _AiStatus status;
  final String? markdown;
  final Map<String, dynamic>? aiContext;
  final Color accent;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onOpenForm;

  const _AiPanel({
    required this.status,
    required this.markdown,
    required this.aiContext,
    required this.accent,
    required this.isDark,
    required this.onRetry,
    required this.onOpenForm,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade500;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                'AI BREAKDOWN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (status == _AiStatus.loading)
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analyzing this lift…',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            )
          else if (status == _AiStatus.error)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Couldn't build the breakdown.",
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else if (status == _AiStatus.ready && markdown != null) ...[
            _contextChips(),
            SimpleMarkdownText(
              markdown!,
              baseFontSize: 13.5,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade800,
            ),
          ],
        ],
      ),
    );
  }

  Widget _contextChips() {
    final ctx = aiContext;
    if (ctx == null) return const SizedBox.shrink();
    final chips = <Widget>[];
    if (ctx['is_pr'] == true) {
      chips.add(_chip('🏆 New PR', const Color(0xFFEAB308)));
    } else if (ctx['is_near_pr'] == true) {
      chips.add(_chip('Near PR', accent));
    }
    final form = (ctx['form_score'] as num?)?.toDouble();
    if (form != null) {
      chips.add(GestureDetector(
        onTap: onOpenForm,
        child: _chip('Form ${form.toStringAsFixed(0)}/10 ›',
            const Color(0xFF22C55E)),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
