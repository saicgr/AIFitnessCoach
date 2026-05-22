import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_score.dart';
import '../../../data/providers/today_score_provider.dart';
import '../../../services/score_history_service.dart';
import 'score_colors.dart';
import 'segmented_score_ring.dart';

/// Open the Today Score breakdown as a modal bottom sheet.
void showTodayScoreDetailSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TodayScoreDetailSheet(),
  );
}

/// The score breakdown — the ring, momentum, and every contributor explained
/// in plain language (including why one may not be counted today).
class _TodayScoreDetailSheet extends ConsumerWidget {
  const _TodayScoreDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final score = ref.watch(todayScoreProvider);
    final history = ref.watch(scoreHistoryProvider);

    final segments = score.applicableContributors
        .map((cc) => ScoreRingSegment(
              weight: cc.effectiveWeight,
              completion: cc.completion,
              color: colorForContributor(cc.kind),
              trackColor:
                  colorForContributor(cc.kind).withValues(alpha: 0.16),
            ))
        .toList();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Today Score',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              if (score.isSetupState)
                _setup(c)
              else ...[
                Center(
                  child: SegmentedScoreRing(
                    size: 156,
                    strokeWidth: 19,
                    segments: segments,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w800,
                            height: 0.95,
                            letterSpacing: -2,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          score.stateLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: c.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _momentumLine(c, history)),
                const SizedBox(height: 18),
                for (final cc in score.contributors) _contributorTile(c, cc),
                const SizedBox(height: 14),
                _howItWorks(c, score),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _momentumLine(ThemeColors c, ScoreHistory history) {
    final delta = history.todayDelta;
    final avg = history.recentAverage();
    final String momentum;
    if (delta > 0) {
      momentum = '▲ Up $delta since this morning';
    } else if (delta < 0) {
      momentum = '▼ Down ${-delta} since this morning';
    } else {
      momentum = 'Steady since this morning';
    }
    return Text(
      avg != null ? '$momentum  ·  7-day average $avg' : momentum,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: delta > 0 ? const Color(0xFF2C8A54) : c.textSecondary,
      ),
    );
  }

  Widget _contributorTile(ThemeColors c, ScoreContributor cc) {
    final color = colorForContributor(cc.kind);
    final weightPct = (cc.effectiveWeight * 100).round();
    final earned = cc.points.round();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cc.applicable ? color : c.textMuted,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cc.kind.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cc.applicable ? c.textPrimary : c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cc.statusText,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            cc.applicable ? '$earned / $weightPct pts' : 'Not counted',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: cc.applicable ? c.textPrimary : c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks(ThemeColors c, TodayScore score) {
    final inactive = score.contributors.where((cc) => !cc.applicable).toList();
    final String body;
    if (inactive.isEmpty) {
      body = 'Train, Fuel and Move each carry a share of 100 points. '
          'Your score is how much of today you have done.';
    } else {
      final names = inactive.map((cc) => cc.kind.label).join(' and ');
      body = '$names ${inactive.length == 1 ? "isn't" : "aren't"} counted '
          'today, so the rest share the full 100 points. Your score always '
          'reflects only what actually applies today.';
    }
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: c.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setup(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Text(
        'Add a workout plan, set nutrition targets, or connect Health to '
        'start scoring your day. Your score builds from what you do — not '
        'from a sensor.',
        style: TextStyle(fontSize: 12.5, height: 1.45, color: c.textSecondary),
      ),
    );
  }
}
