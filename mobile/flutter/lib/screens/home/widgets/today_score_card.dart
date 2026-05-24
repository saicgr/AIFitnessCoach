/// Today Score card — horizontally scrollable G1 ring row.
///
/// Redesigned (2026-05-22) from a single composite ring + legend to a row of
/// G1 open-arc gradient rings, one per visible pillar, with a pinned
/// Customize cell at the right end (Oura-style). The four core pillars
/// (Train / Nourish / Move / Sleep) are always present and cannot be hidden;
/// optional rings (Cycle, Heart rate, HRV, Stress, Hydration, Weight,
/// Recovery) live further right and can be added via the Customize sheet.
///
/// Each ring is tappable to its pillar detail surface:
///   * Train / Nourish / Move → `/pillar/<kind>` (new PillarDetailScreen)
///   * Sleep                 → `/sleep-detail` (existing screen)
///
/// The coach line that used to live in this card's footer has been promoted
/// to a separate `CoachHeroCard` sitting above this card (see plan §4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_score.dart';
import '../../../data/providers/today_score_provider.dart';
import '../../../services/score_history_service.dart';
import 'customize_rings_sheet.dart';
import 'g1_ring_painter.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;
import 'ring_catalog.dart';
import 'score_colors.dart';
import 'today_score_detail_sheet.dart';

class TodayScoreCard extends ConsumerWidget {
  const TodayScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final score = ref.watch(todayScoreProvider);
    final visibleRings = ref.watch(ringVisibilityProvider);

    // Record into local history whenever the score changes (powers momentum
    // + trend). `ref.listen` is dispose-safe; it fires as the underlying
    // workout / nutrition / health providers resolve.
    ref.listen<TodayScore>(todayScoreProvider, (prev, next) {
      if (prev?.score != next.score) {
        ref.read(scoreHistoryProvider.notifier).record(next.score);
      }
    });

    return Padding(
      padding: kHomeHPad,
      child: Container(
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(score: score),
            if (score.isSetupState)
              _SetupState(c: c)
            else
              _RingRow(score: score, visibleRings: visibleRings),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  Header — "Today" eyebrow + momentum badge + Customize pencil
// ──────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final TodayScore score;
  const _Header({required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final history = ref.watch(scoreHistoryProvider);
    final delta = history.todayDelta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      child: Row(
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: c.textPrimary,
            ),
          ),
          if (!score.isSetupState) ...[
            const SizedBox(width: 8),
            Text(
              '${score.score}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
              ),
            ),
          ],
          if (delta != 0 && !score.isSetupState) ...[
            const SizedBox(width: 8),
            _MomentumBadge(delta: delta),
          ],
          const Spacer(),
          _CustomizePill(),
        ],
      ),
    );
  }
}

class _MomentumBadge extends StatelessWidget {
  final int delta;
  const _MomentumBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? const Color(0xFF2C8A54) : const Color(0xFFC26A4A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${up ? '▲' : '▼'} ${delta.abs()}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _CustomizePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        // Two entry points: this pill opens the wider home-customization sheet
        // (sliver order); the ring "Customize" cell opens the ring-specific
        // sheet. Keeping the legacy route for parity.
        try {
          context.push('/settings/homescreen');
        } catch (_) {}
      },
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
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  Ring row — horizontally scrollable G1 rings + Customize cell
// ──────────────────────────────────────────────────────────────────────

class _RingRow extends ConsumerWidget {
  final TodayScore score;
  final List<RingKind> visibleRings;
  const _RingRow({required this.score, required this.visibleRings});

  static const double _ringSize = 84;
  static const double _cellWidth = 92;
  static const double _rowHeight = 158;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: _rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: visibleRings.length + 1, // +1 for the Customize cell
        itemBuilder: (context, index) {
          if (index == visibleRings.length) {
            return _CustomizeCell(width: _cellWidth, ringSize: _ringSize);
          }
          final kind = visibleRings[index];
          final spec = kRingCatalog[kind]!;
          final data = _resolveRingData(score, kind);
          return _RingCell(
            width: _cellWidth,
            ringSize: _ringSize,
            spec: spec,
            data: data,
            onTap: () => _navigateForKind(context, kind),
          );
        },
      ),
    );
  }

  void _navigateForKind(BuildContext context, RingKind kind) {
    try {
      switch (kind) {
        case RingKind.train:
          context.push('/pillar/train');
          break;
        case RingKind.nourish:
          context.push('/pillar/nourish');
          break;
        case RingKind.move:
          context.push('/pillar/move');
          break;
        case RingKind.sleep:
          context.push('/sleep-detail');
          break;
        default:
          // Optional rings — no detail screen for v1. Open the day overview
          // sheet so users still get a context tap-target.
          showTodayScoreDetailSheet(context);
      }
    } catch (_) {
      showTodayScoreDetailSheet(context);
    }
  }
}

/// Single ring cell — G1 painter + label + percentage.
class _RingCell extends StatelessWidget {
  final double width;
  final double ringSize;
  final RingSpec spec;
  final _RingData data;
  final VoidCallback onTap;

  const _RingCell({
    required this.width,
    required this.ringSize,
    required this.spec,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final isUnavailable = data.applicable == false;
    final progress = data.completion.clamp(0.0, 1.0);
    // Show just the integer score, no '%' suffix (Oura/Whoop convention —
    // reads as "Train 67" not "Train 67 percent done").
    final pctText = isUnavailable ? '—' : '${(progress * 100).round()}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CustomPaint(
                    painter: G1RingPainter(
                      progress: progress,
                      color: spec.color,
                      trackColor: c.cardBorder,
                      // Goal-tick removed — it was always at 100% (= the end
                      // of the arc), so it duplicated the progress arc's
                      // rounded cap without adding meaning. If we later want
                      // to mark yesterday's score or a stretch goal, this
                      // is where it'd be wired back in.
                      goalTickAt: null,
                      isZero: !isUnavailable && progress == 0,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pctText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isUnavailable ? c.textMuted : c.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spec.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isUnavailable ? c.textMuted : spec.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Customize" cell pinned at the end of the ring row.
class _CustomizeCell extends StatelessWidget {
  final double width;
  final double ringSize;
  const _CustomizeCell({required this.width, required this.ringSize});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () => showCustomizeRingsSheet(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 24,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CUSTOMIZE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: c.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  Setup state
// ──────────────────────────────────────────────────────────────────────

class _SetupState extends StatelessWidget {
  final ThemeColors c;
  const _SetupState({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
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

// ──────────────────────────────────────────────────────────────────────
//  Ring data resolution — maps a RingKind to its current score completion
// ──────────────────────────────────────────────────────────────────────

class _RingData {
  /// 0..1. Meaningless when [applicable] is false.
  final double completion;

  /// Whether this ring has real data today. False → "—" + greyed visual.
  final bool applicable;

  const _RingData({required this.completion, required this.applicable});
}

_RingData _resolveRingData(TodayScore score, RingKind kind) {
  switch (kind) {
    case RingKind.train:
      final c = score.contributor(ContributorKind.train);
      return _RingData(completion: c.completion, applicable: c.applicable);
    case RingKind.nourish:
      final c = score.contributor(ContributorKind.fuel);
      return _RingData(completion: c.completion, applicable: c.applicable);
    case RingKind.move:
      final c = score.contributor(ContributorKind.move);
      return _RingData(completion: c.completion, applicable: c.applicable);
    case RingKind.sleep:
      final c = score.contributor(ContributorKind.sleep);
      return _RingData(completion: c.completion, applicable: c.applicable);
    case RingKind.cycle:
    case RingKind.heartRate:
    case RingKind.hrv:
    case RingKind.stress:
    case RingKind.hydration:
    case RingKind.weight:
    case RingKind.recovery:
      // Optional rings — not wired in v1. Render as "not applicable" so the
      // ring shape still appears (encouraging connection / setup) without
      // faking data.
      return const _RingData(completion: 0, applicable: false);
  }
}

// Suppress unused-import warnings — we import score_colors for sleep tier
// helpers that future PillarDetailScreen integrations will use.
// ignore: unused_element
void _keepScoreColors() {
  tierFor(0);
}
