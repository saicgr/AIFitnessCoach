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
import '../../../data/providers/pillar_history_provider.dart';
import '../../../data/providers/today_score_provider.dart';
import '../../../services/score_history_service.dart';
import 'customize_rings_sheet.dart';
import 'g1_ring_painter.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;
import 'ring_catalog.dart';
import 'score_colors.dart';
import 'today_score_detail_sheet.dart';
import 'today_score_setup_card.dart';
import '../../../widgets/health_connect_sheet.dart';
import '../../../data/services/health_service.dart' show healthSyncProvider;
import '../../../core/animations/celebration_animations.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
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
      // Celebrate any pillar that just crossed into "complete" (< 1.0 → 1.0).
      // Once-per-pillar-per-day so an animation doesn't re-fire on rebuild.
      if (prev != null) {
        for (final kind in ContributorKind.values) {
          final prevC = prev.contributor(kind);
          final nextC = next.contributor(kind);
          if (!nextC.applicable) continue;
          final crossedToComplete =
              prevC.completion < 1.0 && nextC.completion >= 1.0;
          if (crossedToComplete) {
            _maybeCelebrateRing(context, ref, kind);
          }
        }
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
            // Brand-new + low-data users (0-1 pillar applicable) see a
            // productive 4-step checklist instead of a row of empty rings.
            // Once ≥2 pillars apply, the ring row takes over — the rings
            // alone tell a coherent story past that point.
            if (score.isSetupState || score.applicableContributors.length <= 1)
              const TodayScoreSetupCard()
            else ...[
              // Surface 1.4 — single combined Connect prompt above the row
              // when Health is disconnected. Replaces the per-ring `_ConnectChip`
              // stack (Sleep / HRV / Recovery / HeartRate would otherwise
              // each show one).
              const _CombinedHealthConnectPrompt(),
              _RingRow(score: score, visibleRings: visibleRings),
            ],
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
    // history + composite-delta no longer surfaced in the header — momentum
    // moved to per-ring chips (item 5 of v2 polish plan). Side-effect record
    // still fires via the ref.listen on TodayScoreCard at the parent level.
    final syncState = ref.watch(healthSyncProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 4),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context).todayScoreCardToday,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: c.textPrimary,
            ),
          ),
          // Removed composite score number from the header — users couldn't
          // decode "Today 10" (the weighted average is opaque), and the rings
          // themselves communicate completion. Momentum lives on the rings
          // now (per-pillar delta chips, item 5 of the v2 polish plan).
          // _MomentumBadge against the composite is gone with the number.
          const Spacer(),
          // Last-sync indicator — only shown when health is connected AND we
          // have a timestamp. Tap → showHealthConnectSheet to manage sync.
          if (syncState.isConnected && syncState.lastSyncTime != null) ...[
            _LastSyncChip(
              lastSync: syncState.lastSyncTime!,
              syncing: syncState.isSyncing,
            ),
            const SizedBox(width: 8),
          ],
          _CustomizePill(),
        ],
      ),
    );
  }
}

// _MomentumBadge removed — per-ring momentum chips replace the composite
// delta. See item 5 of the v2 polish plan + the new per-pillar _DeltaChip
// implementation in _RingCell.

/// Tiny "Synced 3m ago" chip next to the Edit pill — only renders when
/// Health is connected AND we have a real timestamp. Tap → opens the
/// existing Health Connect sheet so users can manage sync from one place.
class _LastSyncChip extends ConsumerWidget {
  final DateTime lastSync;
  final bool syncing;
  const _LastSyncChip({required this.lastSync, required this.syncing});

  String _humanize(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final label = syncing ? 'Syncing…' : 'Synced ${_humanize(lastSync)}';
    return GestureDetector(
      onTap: () => showHealthConnectSheet(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
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
              AppLocalizations.of(context).commonEdit,
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
    // Sleep-ring parity (plan Option A): when the user has not connected
    // Apple Health / Health Connect, every health-data-driven ring would
    // render its own `_ConnectChip` — Sleep, HRV, Recovery, HeartRate all
    // at once. That stacks 1–4 Connect chips on top of the single combined
    // Connect prompt the `HomeMetricTrio` below already shows. Hide the
    // health rings here so there's one connect call-to-action on the
    // home surface, not five.
    final healthConnected = ref.watch(healthSyncProvider).isConnected;
    final List<RingKind> rings = healthConnected
        ? visibleRings
        : visibleRings
            .where((k) => !_healthRingKinds.contains(k))
            .toList(growable: false);

    return SizedBox(
      height: _rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: rings.length + 1, // +1 for the Customize cell
        itemBuilder: (context, index) {
          if (index == rings.length) {
            return _CustomizeCell(width: _cellWidth, ringSize: _ringSize);
          }
          final kind = rings[index];
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

// ──────────────────────────────────────────────────────────────────────
//  Ring-100% celebration — fires once per pillar per day when a ring
//  transitions from < 1.0 to ≥ 1.0 completion. Confetti overlay +
//  HapticService.success(). Guard set is in-memory (cleared on app
//  restart, which is fine — the user wouldn't want a re-celebration
//  on cold start anyway).
// ──────────────────────────────────────────────────────────────────────

final Set<String> _celebratedThisSession = <String>{};

void _maybeCelebrateRing(BuildContext context, WidgetRef ref,
    ContributorKind kind) {
  final today = DateTime.now();
  final key = '${today.year}-${today.month}-${today.day}|${kind.name}';
  if (_celebratedThisSession.contains(key)) return;
  _celebratedThisSession.add(key);

  // Haptic first — Apple guidance recommends haptic precede the visual
  // by ~16ms so the sensory feedback feels in-sync.
  HapticService.success();

  // Confetti via an Overlay insert. Auto-removes on completion.
  final overlayState = Overlay.maybeOf(context);
  if (overlayState == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ConfettiOverlay(
          particleCount: 60,
          duration: const Duration(milliseconds: 2200),
          onComplete: () {
            entry.remove();
          },
        ),
      ),
    );
  });
  overlayState.insert(entry);
}

/// Health rings whose unavailable state means "no Health Connect / no
/// wearable data" — these get an inline `Connect` chip instead of bare `—`
/// so the user has a one-tap path to fix it.
const _healthRingKinds = <RingKind>{
  RingKind.sleep,
  RingKind.hrv,
  RingKind.recovery,
  RingKind.heartRate,
};

/// Single ring cell — G1 painter + label + percentage (or Connect chip when
/// the ring is a health ring with no data).
class _RingCell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final isUnavailable = data.applicable == false;
    final progress = data.completion.clamp(0.0, 1.0);
    final bool showConnectChip =
        isUnavailable && _healthRingKinds.contains(spec.kind);
    // Show just the integer score, no '%' suffix (Oura/Whoop convention —
    // reads as "Train 67" not "Train 67 percent done"). When unavailable,
    // health rings show a Connect chip in place of '—' (see _ConnectChip
    // below); other unavailable rings keep the dash.
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
                    if (showConnectChip)
                      _ConnectChip(
                        accent: spec.color,
                        onTap: () => showHealthConnectSheet(context, ref),
                      )
                    else
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
              spec.kind.localizedLabel(context).toUpperCase(),
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
            if (!isUnavailable) _PillarDeltaChip(ringKind: spec.kind, current: progress),
          ],
        ),
      ),
    );
  }
}

/// Tiny momentum chip rendered under a ring label showing today's delta vs
/// yesterday's same-pillar completion (e.g. `▲5` green, `▼3` orange).
///
/// Only renders for the four core pillars (Train / Nourish / Move / Sleep)
/// — optional rings (HRV, Cycle, Weight, Hydration, etc.) don't have a
/// `PillarKind` mapping, so they get nothing. Renders nothing when delta is
/// zero so the row stays clean on neutral days.
class _PillarDeltaChip extends ConsumerWidget {
  final RingKind ringKind;
  final double current; // 0..1 current completion

  const _PillarDeltaChip({required this.ringKind, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pillar = _ringToPillar(ringKind);
    if (pillar == null) return const SizedBox.shrink();

    final historyAsync = ref.watch(
      pillarHistoryProvider(PillarHistoryKey(kind: pillar, days: 2)),
    );
    final history = historyAsync.maybeWhen(
      data: (h) => h,
      orElse: () => const <PillarDayScore>[],
    );
    if (history.isEmpty) return const SizedBox.shrink();

    // Find yesterday's entry; skip if pillar didn't apply yesterday.
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    PillarDayScore? prev;
    for (final p in history) {
      if (p.date.year == yesterday.year &&
          p.date.month == yesterday.month &&
          p.date.day == yesterday.day) {
        prev = p;
        break;
      }
    }
    if (prev == null) return const SizedBox.shrink();

    final delta = (current * 100).round() - (prev.completion * 100).round();
    if (delta == 0) return const SizedBox.shrink();

    final isUp = delta > 0;
    final color = isUp ? const Color(0xFF3FA66B) : const Color(0xFFEC8B2C);
    final label = isUp ? '▲${delta.abs()}' : '▼${delta.abs()}';

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static PillarKind? _ringToPillar(RingKind k) {
    switch (k) {
      case RingKind.train:
        return PillarKind.train;
      case RingKind.nourish:
        return PillarKind.nourish;
      case RingKind.move:
        return PillarKind.move;
      case RingKind.sleep:
        return PillarKind.sleep;
      default:
        return null;
    }
  }
}

/// Combined Connect prompt rendered above the ring row when Health is
/// not connected (Surface 1.4). One row-level CTA replaces the per-ring
/// Connect chips that used to stack on Sleep / HRV / Recovery / HeartRate
/// simultaneously. Self-hides when Health is connected.
class _CombinedHealthConnectPrompt extends ConsumerWidget {
  const _CombinedHealthConnectPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(healthSyncProvider).isConnected;
    if (connected) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: () => showHealthConnectSheet(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: c.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite_border_rounded, size: 14, color: c.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connect Apple Health / Health Connect',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline Connect chip — rendered IN PLACE OF the `—` for unavailable
/// health rings (Sleep/HRV/Recovery/HeartRate) so the user has a one-tap
/// path to fix the empty state instead of staring at a dash that looks
/// like a UI bug.
class _ConnectChip extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _ConnectChip({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.32), width: 0.6),
        ),
        child: Text(
          AppLocalizations.of(context).unifiedHomeWidgetsConnect,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: accent,
            letterSpacing: 0.2,
          ),
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
              AppLocalizations.of(context).todayScoreCardCustomize,
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

// _SetupState removed — replaced by TodayScoreSetupCard (4-step checklist).

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
    case RingKind.sleepLatency:
    case RingKind.wakeConsistency:
    case RingKind.bedtimeWindow:
    case RingKind.vo2max:
      // Optional rings — not wired into the today-score ring. Render as "not
      // applicable" so the ring shape still appears (encouraging connection /
      // setup) without faking data.
      return const _RingData(completion: 0, applicable: false);
  }
}

// Suppress unused-import warnings — we import score_colors for sleep tier
// helpers that future PillarDetailScreen integrations will use.
// ignore: unused_element
void _keepScoreColors() {
  tierFor(0);
}
