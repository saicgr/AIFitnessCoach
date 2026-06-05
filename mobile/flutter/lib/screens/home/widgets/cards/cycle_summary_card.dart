/// Consolidated "Your Cycle" home card (home-card sprawl cleanup #12).
///
/// Merges the four previously-separate cycle tiles that lived under the
/// "Your cycle" section of [ExtendedHomeCardsStack] into ONE expandable card:
///
///   • [CyclePhaseChip]        → current phase + cycle day header
///   • [PeriodPredictionTile]  → next-period countdown / late-by + confidence
///   • [PmsPrepCard]           → PMS-prep guidance, shown only inside the
///                               1-5 day pre-period luteal window
///   • [PeriodSymptomLogTile]  → "Log today's symptoms" affordance while in
///                               the menstrual phase
///
/// plus the Log period / View cycle action row. The content/logic of each
/// source tile is preserved verbatim — this is a presentation regroup, not a
/// behaviour change. The card self-collapses to [SizedBox.shrink] whenever the
/// user doesn't track menstrual cycles or predictions are unavailable, exactly
/// like the tiles it replaces, so the self-hiding section header still works.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/services/haptic_service.dart';

class CycleSummaryCard extends ConsumerStatefulWidget {
  const CycleSummaryCard({super.key});

  @override
  ConsumerState<CycleSummaryCard> createState() => _CycleSummaryCardState();
}

class _CycleSummaryCardState extends ConsumerState<CycleSummaryCard> {
  // Minimized by default — the card opens to just the phase header + next-period
  // line (the glanceable essentials). PMS-prep tips, the in-period symptom log
  // and the Log period / View cycle actions tuck behind the chevron so the card
  // stays compact on Home until the user taps to expand.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    // Gate 1 — user must track menstrual cycles. Same defensive read the
    // source tiles used (provider can throw before the profile loads).
    bool tracks = false;
    try {
      tracks = ref.watch(hasHormonalTrackingProvider);
    } catch (_) {}
    if (!tracks) return const SizedBox.shrink();

    // Gate 2 — a usable prediction must exist.
    CyclePrediction? pred;
    try {
      pred = ref.watch(cyclePredictionProvider).valueOrNull;
    } catch (_) {}
    if (pred == null || !pred.predictionsAvailable) {
      return const SizedBox.shrink();
    }

    final phase = pred.currentPhase;
    final day = pred.currentCycleDay;
    // Without a phase AND day we have nothing meaningful to show — collapse
    // rather than render a hollow header (matches CyclePhaseChip's gate).
    if (phase == null || day == null) return const SizedBox.shrink();

    final inPeriod =
        pred.inPeriod || pred.currentPhase == CyclePhase.menstrual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header: phase emoji + phase label + day-of-cycle + chevron ──
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.light();
                setState(() => _expanded = !_expanded);
              },
              child: Row(
                children: [
                  Expanded(child: _PhaseHeader(phase: phase, day: day)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0.0,
                    child: Icon(Icons.expand_more,
                        size: 22, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Next-period countdown / late-by, with confidence pill ──
            // (always visible — the key glanceable line) ──
            _PredictionRow(pred: pred),
            // ── Everything else collapses behind the chevron ──
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expanded ? 1.0 : 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── PMS-prep guidance — only in the 1-5 day luteal window ──
                      ..._buildPmsPrep(context, pred),
                      // ── In-period symptom-log affordance ──
                      if (inPeriod) ...[
                        const SizedBox(height: 12),
                        _SymptomLogRow(),
                      ],
                      const SizedBox(height: 14),
                      // ── Action row: Log period / View cycle ──
                      _ActionRow(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reproduces [PmsPrepCard]'s gate: 1-5 days out, luteal phase only.
  List<Widget> _buildPmsPrep(BuildContext context, CyclePrediction pred) {
    final days = pred.daysUntilNextPeriod;
    if (days == null || days < 1 || days > 5) return const [];
    if (pred.currentPhase != null &&
        pred.currentPhase != CyclePhase.luteal) {
      return const [];
    }
    final c = ThemeColors.of(context);
    return [
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardBorder.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'PMS prep · $days day${days == 1 ? '' : 's'} out',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _Tip(
                text: 'Lean toward lighter sessions and longer cooldowns.'),
            const SizedBox(height: 4),
            const _Tip(text: 'Iron-rich meals + magnesium support cramps.'),
            const SizedBox(height: 4),
            const _Tip(text: 'Sleep target +30 min for the next few nights.'),
          ],
        ),
      ),
    ];
  }
}

/// Phase emoji + phase label + "Day N of cycle" — from [CyclePhaseChip].
class _PhaseHeader extends StatelessWidget {
  final CyclePhase phase;
  final int day;
  const _PhaseHeader({required this.phase, required this.day});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      children: [
        Text(_phaseEmoji(phase), style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _phaseLabel(phase),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                'Day $day of cycle',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _phaseLabel(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:
        return 'Menstrual phase';
      case CyclePhase.follicular:
        return 'Follicular phase';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal phase';
    }
  }

  String _phaseEmoji(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:
        return '🩸';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '🌸';
      case CyclePhase.luteal:
        return '🌙';
    }
  }
}

/// Next-period countdown / late-by line + confidence pill — from
/// [PeriodPredictionTile]. Collapses (shows nothing) when the prediction has
/// neither a late-by nor a days-until value.
class _PredictionRow extends StatelessWidget {
  final CyclePrediction pred;
  const _PredictionRow({required this.pred});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final daysUntil = pred.daysUntilNextPeriod;
    final lateBy = pred.periodLateBy;
    final nextDate = pred.nextPeriodDate;

    String headline;
    String sub;
    if (lateBy != null && lateBy > 0) {
      headline = 'Period · $lateBy day${lateBy == 1 ? '' : 's'} late';
      sub = 'Log a period or update tracking.';
    } else if (daysUntil != null && nextDate != null) {
      if (daysUntil == 0) {
        headline = 'Period expected today';
      } else if (daysUntil == 1) {
        headline = 'Period in 1 day';
      } else {
        headline = 'Period in $daysUntil days';
      }
      sub = 'Estimated start ${_fmtDate(nextDate)}.';
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('🩸', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                headline,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _ConfidencePill(confidence: pred.confidence),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: TextStyle(fontSize: 11.5, color: c.textSecondary),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _ConfidencePill extends StatelessWidget {
  final String confidence;
  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.cardBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        confidence,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// PMS-prep bullet — from [PmsPrepCard]'s `_Tip`.
class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// In-period "Log today's symptoms" affordance — from [PeriodSymptomLogTile].
/// Routes to the cycle screen's log tab.
class _SymptomLogRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/cycle?tab=log');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardBorder.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🩸', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Log today's symptoms",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Flow, cramps, mood — a few taps.',
                    style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Log period / View cycle actions. The whole card already opens `/cycle`
/// implicitly via these, mirroring the source tiles' tap targets.
class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticService.light();
              context.push('/cycle?tab=log');
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Log period',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticService.light();
              context.push('/cycle');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.accentContrast,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View cycle',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
