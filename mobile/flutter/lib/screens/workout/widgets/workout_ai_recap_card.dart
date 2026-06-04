import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/lottie_animations.dart';

/// Persisted post-workout AI recap card (Task B8 — deeper than Gravl's summary).
///
/// Renders a structured, AI-generated recap of the just-finished workout:
///   - total volume vs the last comparable session
///   - PRs hit this session
///   - "what stood out" (weak point progressed, consistency, strong lift)
///   - ONE concrete coaching cue for next time
///   - an optional reference to logged notes (multi-modal-ready)
///
/// Lifecycle (instant-feel, never a blank spinner — see
/// feedback_instant_feel_ai_generation):
///   1. Mount → optimistic SKELETON paints immediately.
///   2. GET `/feedback/recap/{workout_id}` — if a persisted recap exists, show it.
///   3. Otherwise POST `/feedback/recap` to generate + persist (idempotent),
///      keeping the skeleton up with a "crafting your recap" shimmer until it
///      resolves, then cross-fade into the rendered recap.
///
/// Fully self-contained: it owns its own fetch/generate/render state. The host
/// screen only needs to construct it with the completed-workout payload.
class WorkoutAiRecapCard extends ConsumerStatefulWidget {
  /// The plan/session id the recap is keyed by (matches `workout_id` server-side).
  final String workoutId;

  /// The specific completion this recap is generated from (optional but preferred).
  final String? workoutLogId;

  final String workoutName;
  final String workoutType;

  /// Completed exercises. Each map: {name, sets, reps, weight_kg, time_seconds}.
  final List<Map<String, dynamic>> exercises;

  /// Originally-planned exercises (for skip/completion context). Same shape.
  final List<Map<String, dynamic>> plannedExercises;

  final int totalTimeSeconds;
  final int totalRestSeconds;
  final double avgRestSeconds;
  final int caloriesBurned;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;

  /// PRs hit this session: [{exercise_name, detail}].
  final List<Map<String, dynamic>> earnedPRs;

  /// Free-text set/workout notes logged this session (multi-modal-ready signal).
  final List<String> loggedNotes;

  final int? totalWorkoutsCompleted;

  /// When true, weights are shown in kg; otherwise converted to lb for display.
  final bool useKg;

  const WorkoutAiRecapCard({
    super.key,
    required this.workoutId,
    this.workoutLogId,
    required this.workoutName,
    this.workoutType = 'strength',
    this.exercises = const [],
    this.plannedExercises = const [],
    this.totalTimeSeconds = 0,
    this.totalRestSeconds = 0,
    this.avgRestSeconds = 0,
    this.caloriesBurned = 0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.totalVolumeKg = 0,
    this.earnedPRs = const [],
    this.loggedNotes = const [],
    this.totalWorkoutsCompleted,
    this.useKg = true,
  });

  @override
  ConsumerState<WorkoutAiRecapCard> createState() => _WorkoutAiRecapCardState();
}

enum _RecapStatus { loading, generating, ready, error }

class _WorkoutAiRecapCardState extends ConsumerState<WorkoutAiRecapCard> {
  _RecapStatus _status = _RecapStatus.loading;
  Map<String, dynamic>? _recap;
  bool _expanded = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kick off the fetch-then-generate flow after first frame so the skeleton
    // paints instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    // 1) Try the persisted recap first (instant, no LLM).
    try {
      final res = await api.get('/feedback/recap/${widget.workoutId}');
      if (!mounted) return;
      final data = res.data;
      if (res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['exists'] == true &&
          data['recap'] is Map) {
        setState(() {
          _recap = Map<String, dynamic>.from(data['recap'] as Map);
          _status = _RecapStatus.ready;
        });
        return;
      }
    } catch (_) {
      // Fall through to generation — a missing recap is the normal first-run path.
    }

    // 2) Generate + persist (idempotent server-side).
    if (!mounted) return;
    setState(() => _status = _RecapStatus.generating);
    await _generate();
  }

  Future<void> _generate({bool force = false}) async {
    final api = ref.read(apiClientProvider);
    try {
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _status = _RecapStatus.error;
            _error = 'Not signed in';
          });
        }
        return;
      }

      final body = <String, dynamic>{
        'user_id': userId,
        'workout_id': widget.workoutId,
        'workout_log_id': widget.workoutLogId,
        'workout_name': widget.workoutName,
        'workout_type': widget.workoutType,
        'exercises': widget.exercises,
        'planned_exercises': widget.plannedExercises,
        'total_time_seconds': widget.totalTimeSeconds,
        'total_rest_seconds': widget.totalRestSeconds,
        'avg_rest_seconds': widget.avgRestSeconds,
        'calories_burned': widget.caloriesBurned,
        'total_sets': widget.totalSets,
        'total_reps': widget.totalReps,
        'total_volume_kg': widget.totalVolumeKg,
        if (widget.earnedPRs.isNotEmpty) 'earned_prs': widget.earnedPRs,
        if (widget.loggedNotes.isNotEmpty) 'logged_notes': widget.loggedNotes,
        if (widget.totalWorkoutsCompleted != null)
          'total_workouts_completed': widget.totalWorkoutsCompleted,
        'force': force,
      };

      final res = await api.post(
        '/feedback/recap',
        data: body,
        options: Options(
          // AI generation can take a few seconds; give it room.
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      if (!mounted) return;
      final data = res.data;
      if (res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['recap'] is Map) {
        setState(() {
          _recap = Map<String, dynamic>.from(data['recap'] as Map);
          _status = _RecapStatus.ready;
          _error = null;
        });
      } else {
        setState(() {
          _status = _RecapStatus.error;
          _error = 'Could not build your recap';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _RecapStatus.error;
        _error = 'Could not build your recap';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassShell(
      isDark: isDark,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: switch (_status) {
          _RecapStatus.loading ||
          _RecapStatus.generating =>
            _RecapSkeleton(isDark: isDark, generating: _status == _RecapStatus.generating),
          _RecapStatus.error => _RecapError(
              isDark: isDark,
              message: _error ?? 'Could not build your recap',
              onRetry: () {
                setState(() => _status = _RecapStatus.generating);
                _generate(force: true);
              },
            ),
          _RecapStatus.ready => _RecapContent(
              recap: _recap ?? const {},
              isDark: isDark,
              useKg: widget.useKg,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0),
        },
      ),
    );
  }
}

// ─── Glass shell ────────────────────────────────────────────────

class _GlassShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassShell({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.purple.withValues(alpha: 0.10),
                      AppColors.orange.withValues(alpha: 0.06),
                    ]
                  : [
                      AppColors.purple.withValues(alpha: 0.06),
                      AppColors.orange.withValues(alpha: 0.04),
                    ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: isDark ? 0.28 : 0.22),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Header (shared) ────────────────────────────────────────────

class _RecapHeader extends StatelessWidget {
  final bool isDark;
  final Widget? trailing;
  const _RecapHeader({required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple, AppColors.orange],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.insights_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Coach Recap',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Loading / generating skeleton (never a blank spinner) ──────

class _RecapSkeleton extends StatelessWidget {
  final bool isDark;
  final bool generating;
  const _RecapSkeleton({required this.isDark, required this.generating});

  @override
  Widget build(BuildContext context) {
    final base = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    final shimmer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(0.85, 16),
        const SizedBox(height: 12),
        bar(1.0, 11),
        const SizedBox(height: 7),
        bar(0.92, 11),
        const SizedBox(height: 7),
        bar(0.7, 11),
        const SizedBox(height: 16),
        bar(0.5, 38),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1100.ms,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RecapHeader(
          isDark: isDark,
          trailing: SizedBox(
            width: 18,
            height: 18,
            child: LottieLoading(size: 18, color: AppColors.purple),
          ),
        ),
        const SizedBox(height: 14),
        shimmer,
        if (generating) ...[
          const SizedBox(height: 12),
          Text(
            'Crafting your recap…',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Error state ────────────────────────────────────────────────

class _RecapError extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;
  const _RecapError({
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RecapHeader(isDark: isDark),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rendered recap ─────────────────────────────────────────────

class _RecapContent extends StatelessWidget {
  final Map<String, dynamic> recap;
  final bool isDark;
  final bool useKg;
  final bool expanded;
  final VoidCallback onToggle;

  const _RecapContent({
    required this.recap,
    required this.isDark,
    required this.useKg,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final headline = (recap['headline'] as String?)?.trim() ?? '';
    final stoodOut = (recap['what_stood_out'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final prs = (recap['prs'] as List?)
            ?.whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        const <Map<String, dynamic>>[];
    final cue = (recap['coaching_cue'] as String?)?.trim() ?? '';
    final notes = (recap['notes_reference'] as String?)?.trim();
    final volume = recap['volume_comparison'] is Map
        ? Map<String, dynamic>.from(recap['volume_comparison'] as Map)
        : const <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RecapHeader(
          isDark: isDark,
          trailing: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 22,
                color: textSecondary,
              ),
            ),
          ),
        ),
        if (headline.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            headline,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: textPrimary,
            ),
          ),
        ],

        // Volume comparison chip (always shown — the headline metric vs Gravl).
        if (volume.isNotEmpty) ...[
          const SizedBox(height: 12),
          _VolumeChip(volume: volume, isDark: isDark, useKg: useKg),
        ],

        if (expanded) ...[
          // PRs.
          if (prs.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...prs.map((pr) => _PrRow(
                  exercise: (pr['exercise_name'] as String?) ?? 'Exercise',
                  detail: (pr['detail'] as String?) ?? '',
                  isDark: isDark,
                )),
          ],

          // What stood out.
          if (stoodOut.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel('What stood out', isDark: isDark),
            const SizedBox(height: 6),
            ...stoodOut.map((s) => _BulletRow(text: s, isDark: isDark)),
          ],

          // Notes reference (multi-modal).
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteRow(text: notes, isDark: isDark),
          ],

          // Coaching cue — the single concrete next step.
          if (cue.isNotEmpty) ...[
            const SizedBox(height: 14),
            _CoachingCue(text: cue, isDark: isDark),
          ],
        ],
      ],
    );
  }
}

// ─── Volume comparison chip ─────────────────────────────────────

class _VolumeChip extends StatelessWidget {
  final Map<String, dynamic> volume;
  final bool isDark;
  final bool useKg;
  const _VolumeChip({
    required this.volume,
    required this.isDark,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final delta = (volume['delta_pct'] as num?)?.toDouble();
    final summary = (volume['summary'] as String?)?.trim() ?? '';
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final bool up = (delta ?? 0) >= 1;
    final bool down = (delta ?? 0) <= -1;
    final Color accent = up
        ? AppColors.green
        : (down ? AppColors.orange : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary));
    final IconData icon = up
        ? Icons.trending_up_rounded
        : (down ? Icons.trending_down_rounded : Icons.trending_flat_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary.isNotEmpty
                  ? summary
                  : 'Total volume logged for this session.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Text(
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PR row ─────────────────────────────────────────────────────

class _PrRow extends StatelessWidget {
  final String exercise;
  final String detail;
  final bool isDark;
  const _PrRow({
    required this.exercise,
    required this.detail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$exercise PR — ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.35,
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

// ─── Section label ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: textSecondary,
      ),
    );
  }
}

// ─── Bullet row ─────────────────────────────────────────────────

class _BulletRow extends StatelessWidget {
  final String text;
  final bool isDark;
  const _BulletRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Note reference row (multi-modal) ───────────────────────────

class _NoteRow extends StatelessWidget {
  final String text;
  final bool isDark;
  const _NoteRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_outlined, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Coaching cue (the single concrete next step) ───────────────

class _CoachingCue extends StatelessWidget {
  final String text;
  final bool isDark;
  const _CoachingCue({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: AppColors.orange),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT TIME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
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
