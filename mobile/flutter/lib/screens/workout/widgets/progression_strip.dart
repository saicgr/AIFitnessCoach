/// Progression Strip
///
/// Compact horizontal row showing the user's last 3 working sessions for
/// the current exercise plus today's target. Renders above the set tracking
/// table on the active-workout screen.
///
/// Design intent: Hevy/Strong show a single "previous session" column inside
/// the set row. We show three prior sessions + the target + trend arrows so
/// the user can see the *trajectory* at a glance, not just yesterday's number.
///
/// Examples:
///   3+ sessions:  [135×8]  [135×8]→[140×7]   →  [Target 140×8]
///   Bodyweight:   [12 reps] [15 reps] [18 reps] → [Target 20 reps]
///   Timed hold:   [45s]    [50s]    [60s]    →  [Target 60s]
///   1st session:  (empty state — hides strip; insight engine handles "first-time" copy)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/pre_set_insight_engine.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/weight_utils.dart';

/// Trend direction between two consecutive sessions.
enum _Trend {
  up,      // weight up, or same weight + reps up
  flat,    // same weight + same reps (plateau)
  down,    // weight down, or same weight + reps down
  first,   // no prior session to compare against
}

/// A compact summary of a past session, derived from SessionSummary.
/// The strip displays the "best" working set — top working set by weight×reps.
/// This mirrors how competitors summarize a session at a glance.
class _SessionPillData {
  final String label;   // e.g. "135×8", "12 reps", "45s"
  final _Trend trend;   // trend vs the session AFTER this one (newer-facing)
  final DateTime? date; // optional for detail sheet

  const _SessionPillData({
    required this.label,
    required this.trend,
    this.date,
  });
}

class ProgressionStrip extends StatelessWidget {
  /// Newest-first list of prior sessions (from ExerciseHistoryBatchService).
  /// Only the first 3 are rendered.
  final List<SessionSummary> sessions;

  /// Today's target weight in kg (server-computed). Null for bodyweight/timed.
  final double? targetWeightKg;

  /// Today's target reps, can be a range like "8-10".
  final String? targetReps;

  /// Today's target hold/duration in seconds (planks, cardio). When set,
  /// pills render as seconds instead of weight×reps.
  final int? targetDurationSeconds;

  /// User's weight-unit preference — we always store kg internally; this
  /// flag flips display to lbs. Per feedback_weight_units.md the default
  /// for workouts in this app is lbs, not kg.
  final bool useKg;

  /// True for bodyweight exercises — hide weight, show reps only.
  final bool isBodyweight;

  /// True for timed exercises (planks, wall sits, cardio) — render durations.
  final bool isTimed;

  /// Tap handler for the target pill. Use to open inline edit per
  /// feedback_inline_editing.md (pill morphs into input, saves on ✓).
  final VoidCallback? onTargetTap;

  /// Tap handler for a prior-session pill. Use to open a detail sheet with
  /// full per-set breakdown for that day. Null → pills are non-interactive.
  final void Function(SessionSummary session)? onSessionTap;

  const ProgressionStrip({
    super.key,
    required this.sessions,
    required this.useKg,
    this.targetWeightKg,
    this.targetReps,
    this.targetDurationSeconds,
    this.isBodyweight = false,
    this.isTimed = false,
    this.onTargetTap,
    this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Empty-state: no prior sessions → don't render. The existing pre-set
    // coaching banner will surface "first time? we'll learn your baseline."
    // copy via PreSetInsightEngine — duplicating that here would be noise.
    if (sessions.isEmpty) return const SizedBox.shrink();

    // Take the newest 3 sessions (service returns newest-first).
    final prior = sessions.take(3).toList();

    // Build pills newest-first; trends are computed as (this vs next-older).
    // Iteration order keeps the "newest on the right" reading pattern that
    // matches the "[old] → [new] → [TARGET]" left-to-right story.
    final pillsOldestFirst = <_SessionPillData>[];
    for (int i = prior.length - 1; i >= 0; i--) {
      final current = prior[i];
      final older = i + 1 < prior.length ? prior[i + 1] : null;
      pillsOldestFirst.add(_pillFromSession(current, older));
    }

    // AccentColorScope.of returns the enum; resolve to the theme-appropriate
    // Color via getColor(isDark). Active-workout screen is always dark, but
    // route through Theme.of so we don't hard-code.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AccentColorScope.of(context).getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Session history pills, oldest on the left
          for (int i = 0; i < pillsOldestFirst.length; i++) ...[
            _sessionPill(
              context,
              data: pillsOldestFirst[i],
              originalSession: prior[prior.length - 1 - i],
            ),
            if (i < pillsOldestFirst.length - 1) const _PillGap(),
          ],
          // Arrow separator between history and target
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          // Target pill — bold, accent color, taller
          _targetPill(context, accentColor),
        ],
      ),
    );
  }

  // ── Pill builders ──────────────────────────────────────────────────────

  Widget _sessionPill(
    BuildContext context, {
    required _SessionPillData data,
    required SessionSummary originalSession,
  }) {
    final trendIcon = _trendIcon(data.trend);
    final trendColor = _trendColor(data.trend);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trendIcon != null) ...[
            Icon(trendIcon, size: 11, color: trendColor),
            const SizedBox(width: 3),
          ],
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    if (onSessionTap == null) return pill;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSessionTap!(originalSession);
      },
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }

  Widget _targetPill(BuildContext context, Color accentColor) {
    final label = _targetLabel();
    if (label == null) return const SizedBox.shrink();

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Target ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 1.0,
              height: 1.0,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          if (onTargetTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.edit_rounded,
              size: 11,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );

    if (onTargetTap == null) return pill;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTargetTap!();
      },
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }

  // ── Labels ─────────────────────────────────────────────────────────────

  String? _targetLabel() {
    if (isTimed && targetDurationSeconds != null) {
      return '${targetDurationSeconds}s';
    }
    if (targetReps == null || targetReps!.isEmpty) return null;

    if (isBodyweight) {
      return '$targetReps reps';
    }
    if (targetWeightKg == null) {
      return '$targetReps reps';
    }
    // Show whole-number weights without ".0" trailing — matches set table
    // formatting and avoids pill-width churn during inline edits.
    return '${WeightUtils.formatWeightFromKg(targetWeightKg!, useKg: useKg)}×$targetReps';
  }

  _SessionPillData _pillFromSession(
    SessionSummary session,
    SessionSummary? older,
  ) {
    // Pick the top working set (highest weight × reps product). For bodyweight
    // or timed, top = most reps / longest hold. This collapses a multi-set
    // session into the one the user should remember.
    final best = _pickBestSet(session);
    final olderBest = older != null ? _pickBestSet(older) : null;

    final label = _setLabel(best);
    final trend = _computeTrend(best, olderBest);

    DateTime? date;
    try {
      date = DateTime.tryParse(session.dateIso);
    } catch (_) {
      date = null;
    }

    return _SessionPillData(label: label, trend: trend, date: date);
  }

  SetSummary? _pickBestSet(SessionSummary session) {
    if (session.workingSets.isEmpty) return null;
    SetSummary best = session.workingSets.first;
    double bestScore = _score(best);
    for (final s in session.workingSets.skip(1)) {
      final sc = _score(s);
      if (sc > bestScore) {
        best = s;
        bestScore = sc;
      }
    }
    return best;
  }

  double _score(SetSummary s) {
    if (isTimed) return s.reps.toDouble(); // SessionSummary reps = seconds for timed
    if (isBodyweight) return s.reps.toDouble();
    return s.weightKg * s.reps;
  }

  String _setLabel(SetSummary? s) {
    if (s == null) return '—';
    if (isTimed) return '${s.reps}s';
    if (isBodyweight) return '${s.reps} reps';
    return '${WeightUtils.formatWeightFromKg(s.weightKg, useKg: useKg)}×${s.reps}';
  }

  _Trend _computeTrend(SetSummary? current, SetSummary? older) {
    if (current == null) return _Trend.first;
    if (older == null) return _Trend.first;

    if (isTimed || isBodyweight) {
      // Compare reps/seconds directly.
      if (current.reps > older.reps) return _Trend.up;
      if (current.reps < older.reps) return _Trend.down;
      return _Trend.flat;
    }

    // Weight takes priority over reps. Going 140×6 after 135×8 is still an
    // upward trend in load even if volume dipped — matches how lifters read
    // progress (weight on the bar first).
    if (current.weightKg > older.weightKg) return _Trend.up;
    if (current.weightKg < older.weightKg) return _Trend.down;
    if (current.reps > older.reps) return _Trend.up;
    if (current.reps < older.reps) return _Trend.down;
    return _Trend.flat;
  }

  IconData? _trendIcon(_Trend t) {
    switch (t) {
      case _Trend.up:    return Icons.arrow_upward_rounded;
      case _Trend.down:  return Icons.arrow_downward_rounded;
      case _Trend.flat:  return Icons.remove_rounded;
      case _Trend.first: return null;
    }
  }

  Color _trendColor(_Trend t) {
    switch (t) {
      case _Trend.up:    return const Color(0xFF10B981); // green
      case _Trend.down:  return const Color(0xFFF59E0B); // amber
      case _Trend.flat:  return Colors.white.withValues(alpha: 0.4);
      case _Trend.first: return Colors.transparent;
    }
  }
}

class _PillGap extends StatelessWidget {
  const _PillGap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.25),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
