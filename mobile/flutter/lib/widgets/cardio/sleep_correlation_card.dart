import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/sleep_correlation_repository.dart';

import '../../l10n/generated/app_localizations.dart';
/// Thin wrapper that fetches `/cardio-correlation/sleep-pace` and renders
/// the AI insight card. Silently absent when:
///   • the backend returns 204 (n < 20 paired sessions)
///   • the response payload is null
///   • the fetch errors
///
/// Reuses the styling pattern from `_Card` in `pillar_detail_screen.dart`
/// (20px BR, surface fill, 1px border) without importing the private
/// widget — re-implements the same visual treatment.
class SleepCorrelationCard extends ConsumerWidget {
  const SleepCorrelationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sleepPaceCorrelationProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (corr) {
        if (corr == null || corr.copy.isEmpty) return const SizedBox.shrink();
        return _CardChrome(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      size: 16,
                      color: AccentColorScope.of(context).getColor(
                          Theme.of(context).brightness == Brightness.dark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).sleepCorrelationCardSleepPace,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  corr.copy,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${corr.n} paired sessions · r=${corr.r.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardChrome extends StatelessWidget {
  final Widget child;
  const _CardChrome({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
