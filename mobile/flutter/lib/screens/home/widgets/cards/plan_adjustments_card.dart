/// Consolidated "Plan & adjustments" home card (home-card sprawl cleanup #13).
///
/// Merges the four previously-separate coaching adjustment cards into ONE
/// card that lists only the *currently-active* adjustments, each as a row with
/// its own CTA:
///
///   • [DeloadRecommendationCard]   → "Plan deload week"
///   • [SmartRescheduleBanner]      → "Reschedule"  (missed-window reschedule)
///   • [DayOfWeekSkipCard]          → "Reschedule"  (weekday-skip pattern)
///   • [StrainRecoveryMismatchCard] → "Switch to active recovery"
///
/// Each source card's gate / data source is preserved verbatim — this regroups
/// presentation only. The card self-collapses to [SizedBox.shrink] unless at
/// least one adjustment is active, so the self-hiding "Plan & adjustments"
/// section header still works.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/deload_status_provider.dart';
// home_signals_providers → proposedRescheduleSlotProvider; scheduling_provider
// → recentMissedWorkoutProvider. Both needed for the reschedule row.
import '../../../../data/providers/home_signals_providers.dart';
import '../../../../data/providers/scheduling_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../services/mesocycle_planner.dart';
import 'day_of_week_skip_card.dart' show dayOfWeekSkipSignalProvider;
import 'strain_recovery_mismatch_card.dart'
    show strainRecoveryMismatchProvider;

class PlanAdjustmentsCard extends ConsumerStatefulWidget {
  const PlanAdjustmentsCard({super.key});

  @override
  ConsumerState<PlanAdjustmentsCard> createState() =>
      _PlanAdjustmentsCardState();
}

class _PlanAdjustmentsCardState extends ConsumerState<PlanAdjustmentsCard> {
  /// Collapsed by default (user feedback): the card opens to just its header
  /// row (the "N plan adjustments" summary) and expands on tap. The flag lives
  /// on the State so it survives the frequent provider-watch rebuilds — a
  /// ConsumerState is not recreated when a watched provider changes.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    // Build the active-adjustment rows, in priority order. Each row block
    // mirrors the gate of the card it replaces; an inactive adjustment
    // contributes nothing to the list.
    final rows = <Widget>[];

    // ── 1. Deload recommendation ──
    final deloadStatus = ref.watch(deloadStatusProvider).valueOrNull;
    final showDeload = deloadStatus != null && deloadStatus.shouldShow;
    if (showDeload) {
      rows.add(_DeloadRow(reason: deloadStatus.reason.trim()));
    }

    // ── 2. Smart reschedule (missed window) ──
    final missed = _safe(() => ref.watch(recentMissedWorkoutProvider));
    String? rescheduleHeadline;
    String? rescheduleBody;
    String? rescheduleSlot;
    if (missed != null && missed.canReschedule) {
      rescheduleHeadline = '${missed.dayPossessive} ${missed.name} is open';
      rescheduleBody =
          'Missed ${missed.missedDescription.toLowerCase()} — reschedule without breaking the plan?';
      final slot = _safe(
          () => ref.watch(proposedRescheduleSlotProvider(missed.id)).valueOrNull);
      if (slot != null && slot.hasDate) {
        rescheduleSlot = _formatSlotLabel(slot.proposedDate!);
      }
      rows.add(_RescheduleRow(
        headline: rescheduleHeadline,
        body: rescheduleBody,
        slotLabel: rescheduleSlot,
      ));
    }

    // ── 3. Day-of-week skip pattern ──
    final skip = _safe(() => ref.watch(dayOfWeekSkipSignalProvider));
    if (skip != null && skip.weeksSkipped >= 2) {
      rows.add(_SkipRow(
        weekday: skip.weekdayName,
        weeks: skip.weeksSkipped,
        alternative: skip.suggestedAlternative,
      ));
    }

    // ── 4. Strain vs recovery mismatch ──
    final mismatch = _safe(() => ref.watch(strainRecoveryMismatchProvider));
    if (mismatch != null &&
        mismatch.consecutiveDays >= 3 &&
        mismatch.gap >= 20) {
      rows.add(_StrainRow(days: mismatch.consecutiveDays, gap: mismatch.gap));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    // Interleave dividers between adjustment rows.
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Divider(height: 22, thickness: 1, color: c.cardBorder));
      }
      children.add(rows[i]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header — tap anywhere toggles expand/collapse. The chevron
            // signals the card is collapsible; collapsed is the default.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rows.length == 1
                          ? 'Plan adjustment'
                          : '${rows.length} plan adjustments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: c.textMuted,
                      semanticLabel: _expanded ? 'Collapse' : 'Expand',
                    ),
                  ),
                ],
              ),
            ),
            // Body — revealed only when expanded.
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "2026-05-29" → "Fri May 29". (Mirrors SmartRescheduleBanner.)
  static String _formatSlotLabel(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = days[(d.weekday - 1).clamp(0, 6)];
    final monthName = months[(d.month - 1).clamp(0, 11)];
    return '$dayName $monthName ${d.day}';
  }
}

/// Defensive provider read — a provider can throw before its dependencies
/// resolve. Mirrors the try/catch each source card used.
T? _safe<T>(T? Function() fn) {
  try {
    return fn();
  } catch (_) {
    return null;
  }
}

// ── Row scaffolding ─────────────────────────────────────────────────────────

/// A single adjustment row: icon + title + supporting copy + a trailing CTA.
/// The CTA wraps below the copy so the row never overflows on iPhone SE.
class _AdjustmentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget cta;
  const _AdjustmentRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: cta),
      ],
    );
  }
}

/// Filled / outlined pill CTA shared across the adjustment rows.
class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Widget? leading;
  const _CtaButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentContrast,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: child,
    );
  }
}

// ── Individual adjustment rows ──────────────────────────────────────────────

/// Deload row — preserves the "Plan deload week" action (forceDeload + dismiss
/// + route to progression settings) and its in-flight double-tap guard.
class _DeloadRow extends ConsumerStatefulWidget {
  final String reason;
  const _DeloadRow({required this.reason});

  @override
  ConsumerState<_DeloadRow> createState() => _DeloadRowState();
}

class _DeloadRowState extends ConsumerState<_DeloadRow> {
  bool _planning = false;

  Future<void> _onPlanDeload() async {
    if (_planning) return;
    setState(() => _planning = true);
    HapticService.medium();
    try {
      await MesocyclePlanner.forceDeload();
    } catch (e) {
      debugPrint('❌ [Deload] forceDeload failed: $e');
    }
    if (!mounted) return;
    setState(() => _planning = false);
    await dismissDeloadCard(ref);
    if (!mounted) return;
    context.push('/settings/progression-pace');
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return _AdjustmentRow(
      icon: Icons.self_improvement_rounded,
      title: 'Time for a deload week',
      body: widget.reason.isEmpty
          ? 'Your recent training load suggests a recovery week.'
          : widget.reason,
      cta: _planning
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
              ),
            )
          : _CtaButton(
              label: 'Plan deload week',
              filled: true,
              onPressed: _onPlanDeload,
            ),
    );
  }
}

/// Missed-window reschedule row — from [SmartRescheduleBanner].
class _RescheduleRow extends StatelessWidget {
  final String headline;
  final String body;
  final String? slotLabel;
  const _RescheduleRow({
    required this.headline,
    required this.body,
    this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return _AdjustmentRow(
      icon: Icons.schedule,
      title: headline,
      body: body,
      cta: _CtaButton(
        label: 'Reschedule',
        filled: true,
        leading: slotLabel == null
            ? null
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accentContrast.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  slotLabel!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: c.accentContrast,
                  ),
                ),
              ),
        onPressed: () {
          HapticService.light();
          context.push('/schedule?action=reschedule');
        },
      ),
    );
  }
}

/// Weekday-skip pattern row — from [DayOfWeekSkipCard].
class _SkipRow extends StatelessWidget {
  final String weekday;
  final int weeks;
  final String alternative;
  const _SkipRow({
    required this.weekday,
    required this.weeks,
    required this.alternative,
  });

  @override
  Widget build(BuildContext context) {
    return _AdjustmentRow(
      icon: Icons.event_busy_rounded,
      title: '${weekday}s keep getting skipped',
      body:
          "You've missed your $weekday workout $weeks weeks in a row. Want to shift it to $alternative?",
      cta: _CtaButton(
        label: 'Reschedule',
        onPressed: () {
          HapticService.light();
          context.push('/workout/schedule');
        },
      ),
    );
  }
}

/// Strain vs recovery mismatch row — from [StrainRecoveryMismatchCard].
class _StrainRow extends StatelessWidget {
  final int days;
  final int gap;
  const _StrainRow({required this.days, required this.gap});

  @override
  Widget build(BuildContext context) {
    return _AdjustmentRow(
      icon: Icons.bolt_rounded,
      title: 'Strain is outrunning recovery',
      body:
          'For $days days running, your load has been high while recovery markers are low (gap: $gap pts). A lighter session today protects next week.',
      cta: _CtaButton(
        label: 'Switch to active recovery',
        filled: true,
        onPressed: () {
          HapticService.medium();
          context.push('/workout/active-recovery');
        },
      ),
    );
  }
}
