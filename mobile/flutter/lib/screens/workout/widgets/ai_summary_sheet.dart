import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/simple_markdown_text.dart';

/// The request payload for the detailed AI summary. Mirrors EXACTLY the body
/// `WorkoutAiRecapCard._generate()` POSTs to `/feedback/recap`, so the backend
/// can ground the longer breakdown in the same numbers as the short recap.
///
/// Built once by the host (the completed screen) and handed to the sheet, so
/// the sheet itself stays presentation-only.
class AiSummaryRequest {
  final String workoutId;
  final String? workoutLogId;
  final String workoutName;
  final String workoutType;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> plannedExercises;
  final int totalTimeSeconds;
  final int totalRestSeconds;
  final double avgRestSeconds;
  final int caloriesBurned;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;
  final List<Map<String, dynamic>> earnedPRs;
  final List<String> loggedNotes;
  final int? totalWorkoutsCompleted;

  const AiSummaryRequest({
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
  });

  /// The POST body for `/feedback/recap/detailed`. Identical shape to the
  /// short recap's body so the backend reuses its grounding logic.
  Map<String, dynamic> toBody(String userId) => <String, dynamic>{
    'user_id': userId,
    'workout_id': workoutId,
    'workout_log_id': workoutLogId,
    'workout_name': workoutName,
    'workout_type': workoutType,
    'exercises': exercises,
    'planned_exercises': plannedExercises,
    'total_time_seconds': totalTimeSeconds,
    'total_rest_seconds': totalRestSeconds,
    'avg_rest_seconds': avgRestSeconds,
    'calories_burned': caloriesBurned,
    'total_sets': totalSets,
    'total_reps': totalReps,
    'total_volume_kg': totalVolumeKg,
    if (earnedPRs.isNotEmpty) 'earned_prs': earnedPRs,
    if (loggedNotes.isNotEmpty) 'logged_notes': loggedNotes,
    if (totalWorkoutsCompleted != null)
      'total_workouts_completed': totalWorkoutsCompleted,
  };
}

/// Opens the detailed AI summary sheet for a completed workout.
Future<void> showAiSummarySheet(
  BuildContext context, {
  required AiSummaryRequest request,
}) {
  return showGlassSheet(
    context: context,
    builder: (_) => AiSummarySheet(request: request),
  );
}

/// A GlassSheet that fetches and renders the strict, honest, detailed AI
/// breakdown of a finished workout (Strengths / Weaknesses / What to improve /
/// What to do next). Lifecycle, per feedback_instant_feel_ai_generation:
///
///   1. On open → try GET `/feedback/recap/detailed/{workout_id}` for an
///      instantly-reopenable cached summary.
///   2. If absent → POST `/feedback/recap/detailed` to generate + persist,
///      keeping an optimistic skeleton up until it resolves.
///   3. Honest error state with retry if it truly fails — never a blank sheet.
class AiSummarySheet extends ConsumerStatefulWidget {
  final AiSummaryRequest request;

  const AiSummarySheet({super.key, required this.request});

  @override
  ConsumerState<AiSummarySheet> createState() => _AiSummarySheetState();
}

enum _SummaryStatus { loading, generating, ready, error }

class _AiSummarySheetState extends ConsumerState<AiSummarySheet> {
  _SummaryStatus _status = _SummaryStatus.loading;
  String? _markdown;
  bool _isFallback = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    final workoutId = widget.request.workoutId;

    // 1) Cached detailed summary (instant reopen).
    if (workoutId.isNotEmpty) {
      try {
        final res = await api.get('/feedback/recap/detailed/$workoutId');
        if (!mounted) return;
        final data = res.data;
        if (res.statusCode == 200 &&
            data is Map<String, dynamic> &&
            (data['summary_markdown'] as String?)?.trim().isNotEmpty == true) {
          setState(() {
            _markdown = (data['summary_markdown'] as String).trim();
            _isFallback = data['is_fallback'] == true;
            _status = _SummaryStatus.ready;
          });
          return;
        }
      } catch (_) {
        // Missing cached summary is the normal first-open path — fall through.
      }
    }

    if (!mounted) return;
    setState(() => _status = _SummaryStatus.generating);
    await _generate();
  }

  Future<void> _generate() async {
    final api = ref.read(apiClientProvider);
    try {
      final userId = await api.getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _status = _SummaryStatus.error;
            _error = 'Not signed in';
          });
        }
        return;
      }

      final res = await api.post(
        '/feedback/recap/detailed',
        data: widget.request.toBody(userId),
        options: Options(
          // Detailed AI generation can take longer than the short recap.
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      if (!mounted) return;
      final data = res.data;
      if (res.statusCode == 200 &&
          data is Map<String, dynamic> &&
          (data['summary_markdown'] as String?)?.trim().isNotEmpty == true) {
        setState(() {
          _markdown = (data['summary_markdown'] as String).trim();
          _isFallback = data['is_fallback'] == true;
          _status = _SummaryStatus.ready;
          _error = null;
        });
      } else {
        setState(() {
          _status = _SummaryStatus.error;
          _error = 'Could not build your summary';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _SummaryStatus.error;
        _error = 'Could not build your summary';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, AppColors.purple],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.request.workoutName,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 18),
            _buildBody(isDark, accent, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color accent, Color textSecondary) {
    switch (_status) {
      case _SummaryStatus.loading:
      case _SummaryStatus.generating:
        return _SummarySkeleton(
          isDark: isDark,
          generating: _status == _SummaryStatus.generating,
          accent: accent,
        );
      case _SummaryStatus.error:
        return _SummaryError(
          message: _error ?? 'Could not build your summary',
          textSecondary: textSecondary,
          accent: accent,
          onRetry: () {
            setState(() => _status = _SummaryStatus.generating);
            _generate();
          },
        );
      case _SummaryStatus.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SimpleMarkdownText(
              _markdown ?? '',
            ).animate().fadeIn(duration: 240.ms),
            if (_isFallback) ...[
              const SizedBox(height: 14),
              Text(
                'Built from your logged numbers — full coach analysis will be '
                'ready next time.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ],
          ],
        );
    }
  }
}

class _SummarySkeleton extends StatelessWidget {
  final bool isDark;
  final bool generating;
  final Color accent;
  const _SummarySkeleton({
    required this.isDark,
    required this.generating,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final base = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    final shimmer =
        Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bar(0.4, 15),
                bar(1.0, 11),
                bar(0.95, 11),
                bar(0.7, 11),
                const SizedBox(height: 10),
                bar(0.45, 15),
                bar(1.0, 11),
                bar(0.9, 11),
                bar(0.6, 11),
                const SizedBox(height: 10),
                bar(0.5, 15),
                bar(0.95, 11),
                bar(0.8, 11),
              ],
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1100.ms,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        shimmer,
        if (generating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Analyzing your session…',
                style: TextStyle(
                  fontSize: 12.5,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final Color textSecondary;
  final Color accent;
  final VoidCallback onRetry;
  const _SummaryError({
    required this.message,
    required this.textSecondary,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}
