/// Glassmorphic "Customize metrics" sheet — opened from the home metric deck's
/// tune (✎) button. Replaces the old opaque, near-full-screen customize-rings
/// sheet that overlapped the floating nav + AI button and showed no per-metric
/// numbers or graphs (issue 4). Built on the app-standard [GlassSheet], so it
/// sits as a true bottom sheet (its modal barrier covers the nav/FAB) and every
/// row carries a live mini-graph + current number via the shared
/// [MetricsSettingsBody].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../home_my_space_screen.dart' show MetricsSettingsBody;
import '../ring_catalog.dart';

/// Show the glassmorphic metric-customization sheet.
Future<void> showMetricSettingsSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context: context,
    builder: (ctx) => const GlassSheet(child: _MetricSettingsContent()),
  );
}

class _MetricSettingsContent extends ConsumerWidget {
  const _MetricSettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Customize metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  ref.read(ringVisibilityProvider.notifier).resetToDefault();
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag to reorder. Tap the gear to change a metric’s chart, colour '
            'and date range.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          const MetricsSettingsBody(compact: true),
        ],
      ),
    );
  }
}
