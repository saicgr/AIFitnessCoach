import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_score.dart';
import '../../../data/providers/today_score_provider.dart';
import '../../../services/score_coach_line.dart';
import '../../../services/score_history_service.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;
import 'score_colors.dart';
import 'segmented_score_ring.dart';
import 'today_score_detail_sheet.dart';

/// The Today Score home section — a segmented Train / Fuel / Move ring with
/// the tinted track, a side legend, a momentum badge and a one-line coach
/// nudge. Tapping it opens the score breakdown sheet.
///
/// Reads [todayScoreProvider] (live) and records each score into
/// [scoreHistoryProvider] for momentum + history.
class TodayScoreCard extends ConsumerWidget {
  const TodayScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final score = ref.watch(todayScoreProvider);
    final history = ref.watch(scoreHistoryProvider);

    // Record into local history whenever the score changes (powers momentum
    // + the trend). `ref.listen` is dispose-safe; it fires as the underlying
    // workout / nutrition / health providers resolve.
    ref.listen<TodayScore>(todayScoreProvider, (prev, next) {
      if (prev?.score != next.score) {
        ref.read(scoreHistoryProvider.notifier).record(next.score);
      }
    });

    return Padding(
      padding: kHomeHPad,
      child: GestureDetector(
        onTap: () => showTodayScoreDetailSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, c, history.todayDelta),
              if (score.isSetupState)
                _setupState(c)
              else ...[
                _body(c, score),
                _coachFooter(c, score),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---------------------------------------------------------------

  Widget _header(BuildContext context, ThemeColors c, int delta) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 13, 2),
      child: Row(
        children: [
          Text(
            'TODAY SCORE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: c.textMuted,
            ),
          ),
          if (delta != 0) ...[
            const SizedBox(width: 8),
            _momentumBadge(delta),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/settings/homescreen'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: c.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
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

  Widget _momentumBadge(int delta) {
    final up = delta > 0;
    final color = up ? const Color(0xFF2C8A54) : const Color(0xFFC26A4A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${up ? '▲' : '▼'} ${delta.abs()} today',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // --- Body: ring + legend --------------------------------------------------

  Widget _body(ThemeColors c, TodayScore score) {
    final segments = score.applicableContributors
        .map((cc) => ScoreRingSegment(
              weight: cc.effectiveWeight,
              completion: cc.completion,
              color: colorForContributor(cc.kind),
              trackColor:
                  colorForContributor(cc.kind).withValues(alpha: 0.16),
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SegmentedScoreRing(
            size: 132,
            strokeWidth: 17,
            segments: segments,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: c.textMuted,
                  ),
                ),
                Text(
                  '${score.score}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    letterSpacing: -2,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < score.contributors.length; i++) ...[
                  _legendRow(c, score.contributors[i]),
                  if (i < score.contributors.length - 1)
                    Divider(height: 1, color: c.cardBorder),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(ThemeColors c, ScoreContributor cc) {
    final dotColor =
        cc.applicable ? colorForContributor(cc.kind) : c.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cc.kind.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cc.applicable ? c.textPrimary : c.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  cc.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: c.textMuted),
        ],
      ),
    );
  }

  // --- Coach footer ---------------------------------------------------------

  Widget _coachFooter(ThemeColors c, TodayScore score) {
    final line = coachLineFor(score);
    if (line == null) return const SizedBox(height: 14);
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 14, 13),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach avatar — makes the nudge unmistakably "from your coach".
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [c.accent, c.accent.withValues(alpha: 0.68)],
              ),
            ),
            child: const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR COACH',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Setup state ----------------------------------------------------------

  Widget _setupState(ThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flag_outlined, size: 20, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finish setup to unlock your score',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add a workout plan, set nutrition targets, or connect '
                  'Health to start scoring your day.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: c.textSecondary,
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
