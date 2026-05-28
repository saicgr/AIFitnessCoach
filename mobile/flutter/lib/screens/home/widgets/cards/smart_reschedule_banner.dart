/// F3.72 — Smart reschedule banner.
///
/// Surfaces when the user has missed today's window or has a calendar
/// conflict, offering a one-tap reschedule. Pure presentation; the upstream
/// signal (conflict, low readiness, missed window) is owned by the ranker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';
import '../../../../data/providers/scheduling_provider.dart';
import '../../../../data/services/haptic_service.dart';

class SmartRescheduleBanner extends ConsumerWidget {
  final bool show;
  final String? headline;
  final String? body;
  final String? proposedSlotLabel;

  const SmartRescheduleBanner({
    super.key,
    this.show = true,
    this.headline,
    this.body,
    this.proposedSlotLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Derive copy from the most recent missed workout (live). When there's
    // nothing missed, the banner self-collapses.
    String resolvedHeadline = headline ?? '';
    String resolvedBody = body ?? '';
    String? resolvedSlot = proposedSlotLabel;
    if (headline == null || body == null) {
      final missed = ref.watch(recentMissedWorkoutProvider);
      if (missed == null) return const SizedBox.shrink();
      if (!missed.canReschedule) return const SizedBox.shrink();
      resolvedHeadline = headline ?? '${missed.dayPossessive} ${missed.name} is open';
      resolvedBody = body ??
          'Missed ${missed.missedDescription.toLowerCase()} — reschedule without breaking the plan?';
      // Live proposed slot from `GET /api/v1/workouts/proposed-reschedule-slot`.
      // We only render the chip if the backend returns a real date — no
      // fabricated copy when the next 7 days are full.
      final slot =
          ref.watch(proposedRescheduleSlotProvider(missed.id)).valueOrNull;
      if (slot != null && slot.hasDate) {
        resolvedSlot = _formatSlotLabel(slot.proposedDate!);
      } else {
        resolvedSlot = proposedSlotLabel;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resolvedHeadline,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              resolvedBody,
              style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (resolvedSlot != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      resolvedSlot,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: c.accent),
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                TextButton(
                  onPressed: () {
                    HapticService.light();
                    context.push('/schedule?action=reschedule');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.accentContrast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "2026-05-29" → "Fri May 29".
  String _formatSlotLabel(String iso) {
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
