/// Signature V2 — the glanceable metrics strip that sits directly under the
/// home masthead. Four equal hairline-divided cells (STEPS · SLEEP · READY ·
/// SCORE) so the day's key numbers are visible without scrolling; the full
/// metric deck (segmented ring + tiles + trends) still lives below the fold.
///
/// Each cell reads the app's existing live providers — no new data sources:
///   * Steps  → metricValueProvider(RingKind.move)
///   * Sleep  → metricValueProvider(RingKind.sleep)
///   * Ready  → metricValueProvider(RingKind.recovery)   (the accent cell)
///   * Score  → todayScoreProvider (the client-side execution score)
///
/// Cells are tappable, routing to the relevant health detail. Missing routes
/// are caught and become a no-op so the strip never crashes navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../../data/models/metric_value.dart';
import '../../../../data/providers/metric_value_provider.dart';
import '../../../../data/providers/recovery_provider.dart';
import '../../../../data/providers/sleep_score_provider.dart';
import '../../../../data/providers/today_score_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart'
    show dailyActivityProvider, healthSyncProvider;
import '../ring_catalog.dart';
import 'unified_home_widgets.dart' show kHomeHPad;

class HomeMetricsStrip extends ConsumerWidget {
  const HomeMetricsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    final steps = ref.watch(metricValueProvider(RingKind.move));
    final sleep = ref.watch(metricValueProvider(RingKind.sleep));
    final ready = ref.watch(metricValueProvider(RingKind.recovery));
    final score = ref.watch(todayScoreProvider);

    // Per-cell "first load" signal — true only while the cell's underlying
    // source is still fetching AND has produced no value yet. This shows a
    // subtle shimmer on a fresh sign-in (so the strip reads as loading rather
    // than four broken "—" dashes), but NEVER sticks: once a source resolves to
    // "no data", isLoading flips false and the cell falls back to a dash. The
    // `&& isEmpty` guard means an already-populated cell never shimmers on a
    // background refresh.
    final activity = ref.watch(dailyActivityProvider);
    final sleepAsync = ref.watch(sleepScoreProvider);
    final recoveryAsync = ref.watch(recoveryProvider);
    final workoutAsync = ref.watch(todayWorkoutProvider);

    final stepsLoading = steps.isEmpty && activity.isLoading;
    final sleepLoading =
        sleep.isEmpty && sleepAsync.isLoading && !sleepAsync.hasValue;
    final readyLoading =
        ready.isEmpty && recoveryAsync.isLoading && !recoveryAsync.hasValue;
    // The Today Score always computes (never empty), but its dominant input is
    // the workout plan — shimmer the cell until that first resolves so a fresh
    // sign-in doesn't flash a transient "0" before the real score lands.
    final scoreLoading = workoutAsync.isLoading && !workoutAsync.hasValue;

    // Health never connected AND every health cell resolved to "no data":
    // four dead "—" cells at the top of Home read as "the app is broken".
    // Repurpose the strip as a single Connect Health CTA instead (mirrors
    // todays_health_card's not-connected treatment). The `!loading` guards
    // keep the CTA from flashing during the brief pre-resolve window on a
    // connected account's cold start; any single populated cell (e.g. a
    // manually-logged sleep) restores the normal 4-cell strip.
    final sync = ref.watch(healthSyncProvider);
    final showConnectCta = !sync.isConnected &&
        steps.isEmpty &&
        sleep.isEmpty &&
        ready.isEmpty &&
        !stepsLoading &&
        !sleepLoading &&
        !readyLoading;
    if (showConnectCta) {
      return Padding(
        padding: kHomeHPad,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticService.light();
            ref.read(healthSyncProvider.notifier).connect();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, size: 14, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connect Health to see steps, sleep & readiness',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.lbl(10, color: c.textMuted, letterSpacing: 0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'CONNECT',
                  style: ZType.lbl(9, color: c.accent, letterSpacing: 1.3),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: kHomeHPad,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cell(
                context, c,
                value: _metricHeadline(steps),
                label: 'Steps',
                route: '/health/combined',
                loading: stepsLoading,
              ),
              _divider(c),
              _cell(
                context, c,
                value: _metricHeadline(sleep),
                label: 'Sleep',
                route: '/health/sleep',
                loading: sleepLoading,
              ),
              _divider(c),
              _cell(
                context, c,
                value: ready.isEmpty ? '—' : ready.headline,
                valueSuffix: ready.isEmpty ? null : '%',
                label: 'Ready',
                accent: true,
                route: '/health/combined',
                loading: readyLoading,
              ),
              _divider(c),
              _cell(
                context, c,
                value: '${score.score}',
                label: 'Score',
                route: '/health/combined',
                loading: scoreLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metricHeadline(MetricValue m) => m.isEmpty ? '—' : m.headline;

  Widget _divider(ThemeColors c) =>
      VerticalDivider(width: 1, thickness: 1, color: c.cardBorder);

  Widget _cell(
    BuildContext context,
    ThemeColors c, {
    required String value,
    String? valueSuffix,
    required String label,
    bool accent = false,
    required String route,
    bool loading = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticService.light();
          try {
            context.push(route);
          } catch (_) {
            // Route not registered in this build flavor — no-op.
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                // Sized to roughly match the 16pt value line so the
                // shimmer→value swap doesn't reflow the strip height.
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: SkeletonBox(width: 28, height: 14, radius: 6),
                )
              else
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: value,
                    style: ZType.disp(
                      16,
                      color: accent ? c.accent : c.textPrimary,
                    ),
                    children: valueSuffix == null
                        ? null
                        : [
                            TextSpan(
                              text: valueSuffix,
                              style: ZType.disp(9, color: c.textMuted),
                            ),
                          ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: ZType.lbl(8, color: c.textMuted, letterSpacing: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
