/// F3.67 — Scale sync prompt.
///
/// Asks the user to weigh in or re-connect their smart scale when the last
/// reading is stale (default: > 7 days). Pure presentation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/measurements_repository.dart';
import '../../../../data/services/haptic_service.dart';

class ScaleSyncPrompt extends ConsumerWidget {
  final bool show;
  final int? daysSinceLast;

  const ScaleSyncPrompt({
    super.key,
    this.show = true,
    this.daysSinceLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Derive days-since-last-weigh-in from the live measurements summary when
    // caller doesn't override. < 7 days → no prompt (signal isn't stale).
    int resolvedDays = daysSinceLast ?? 0;
    if (daysSinceLast == null) {
      final summary = ref.watch(
          measurementsProvider.select((s) => s.summary));
      final weightEntry = summary?.latestByType[MeasurementType.weight];
      if (weightEntry == null) return const SizedBox.shrink();
      resolvedDays =
          DateTime.now().difference(weightEntry.recordedAt).inDays;
      if (resolvedDays < 7) return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/profile?tab=measurements&action=weigh_in');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.monitor_weight,
                    size: 20, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time for a weigh-in',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last reading was $resolvedDays days ago. A fresh number keeps trends honest.',
                      style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
