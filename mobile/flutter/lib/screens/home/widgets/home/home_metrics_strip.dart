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
import '../../../../data/models/metric_value.dart';
import '../../../../data/providers/metric_value_provider.dart';
import '../../../../data/providers/today_score_provider.dart';
import '../../../../data/services/haptic_service.dart';
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
              ),
              _divider(c),
              _cell(
                context, c,
                value: _metricHeadline(sleep),
                label: 'Sleep',
                route: '/health/sleep',
              ),
              _divider(c),
              _cell(
                context, c,
                value: ready.isEmpty ? '—' : ready.headline,
                valueSuffix: ready.isEmpty ? null : '%',
                label: 'Ready',
                accent: true,
                route: '/health/combined',
              ),
              _divider(c),
              _cell(
                context, c,
                value: '${score.score}',
                label: 'Score',
                route: '/health/combined',
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
