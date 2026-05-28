/// F3.68 — Missing-data chip.
///
/// Tells the user which signal is missing (weight, sleep, HR data, etc.) so
/// the home insights have something to chew on. Tap routes to the matching
/// settings/integration page.
///
/// Wired to `GET /api/v1/home/data-gaps` via [dataGapsProvider]: when no
/// explicit `missingLabel` is passed, the chip self-derives the most
/// important gap (priority: activity → sleep → heart_rate → weight) and
/// self-collapses if the backend reports no gaps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/data_gaps_provider.dart';
import '../../../../data/services/haptic_service.dart';

class MissingDataChip extends ConsumerWidget {
  final bool show;

  /// When supplied by a caller (e.g. the home-card ranker), takes priority
  /// over the backend-derived gap. When null, the chip falls through to
  /// `dataGapsProvider` and self-collapses if the backend reports no gaps.
  final String? missingLabel;
  final String? deepLink;

  const MissingDataChip({
    super.key,
    this.show = true,
    this.missingLabel,
    this.deepLink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Caller-provided label always wins. Otherwise, derive from the backend.
    String? label = missingLabel;
    String? route = deepLink;

    if (label == null) {
      final gapsAsync = ref.watch(dataGapsProvider);
      final result = gapsAsync.valueOrNull;
      final primary = result?.primary;
      if (primary == null) {
        // No data yet OR backend reports no gaps → collapse.
        return const SizedBox.shrink();
      }
      label = primary.displayLabel;
      route ??= primary.deepLink;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push(route ?? '/settings?tab=integrations');
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: c.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
