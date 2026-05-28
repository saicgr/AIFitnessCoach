/// F3.79 — Injury workaround banner.
///
/// When the user has logged an active injury/limitation in their profile,
/// surface a compact banner reminding them today's session has been
/// auto-adjusted, with a tap target to view the substitutions or modify.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class InjuryWorkaroundSignal {
  final String injuryLabel; // e.g. "right knee"
  final int substitutionsApplied;
  const InjuryWorkaroundSignal({
    required this.injuryLabel,
    required this.substitutionsApplied,
  });
}

// TODO(backend): GET /api/v1/insights/today-injury-workaround — needs to
// join active injuries (no Riverpod provider for active injuries exists yet
// — only the /injuries CRUD screens) against today's planned workout to
// count substitutions applied. Banner stays dark until that endpoint lands.
final injuryWorkaroundSignalProvider =
    Provider.autoDispose<InjuryWorkaroundSignal?>((ref) => null);

class InjuryWorkaroundBanner extends ConsumerWidget {
  const InjuryWorkaroundBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    InjuryWorkaroundSignal? signal;
    try {
      signal = ref.watch(injuryWorkaroundSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.substitutionsApplied <= 0) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.healing_rounded, size: 18, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjusted around your ${signal.injuryLabel}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${signal.substitutionsApplied} exercise${signal.substitutionsApplied == 1 ? '' : 's'} swapped for safer alternatives.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/workout/today');
            },
            child: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
