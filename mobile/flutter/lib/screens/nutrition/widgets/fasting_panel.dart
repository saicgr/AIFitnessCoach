import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/line_icon.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Fasting section for the Nutrition → Fuel tab.
///
/// Fasting is an eating-window behaviour, so it belongs alongside the
/// nutrient/water views. This is a summary + entry surface: it shows the
/// live fast (or a start CTA) and routes into the full `/fasting` tracker
/// for start/end/manage flows.
class FastingPanel extends ConsumerWidget {
  const FastingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    // Re-build every tick so the elapsed timer stays live.
    ref.watch(fastingTimerProvider);
    final fasting = ref.watch(fastingProvider);
    final fast = fasting.activeFast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.cardBorder),
          ),
          child: fast == null
              ? _idle(context, c)
              : _active(context, c, fast, ref),
        ),
      ],
    );
  }

  Widget _idle(BuildContext context, ThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LineIcon('fasting', color: c.accent, size: 22),
            const SizedBox(width: 9),
            Text(AppLocalizations.of(context).nutritionFastingIntermittentFasting,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Track your eating window. Start a fast and Zealova will show your '
          'fed → fat-burn → ketosis zones in real time.',
          style: TextStyle(
              fontSize: 13, height: 1.45, color: c.textSecondary),
        ),
        const SizedBox(height: 16),
        _primaryButton(context, c, 'Start a fast'),
      ],
    );
  }

  Widget _active(
      BuildContext context, ThemeColors c, dynamic fast, WidgetRef ref) {
    final zone = fast.currentZone;
    final progress = (fast.progress as num).toDouble().clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LineIcon('fasting', color: c.accent, size: 22),
            const SizedBox(width: 9),
            Text(AppLocalizations.of(context).unifiedHomeWidgetsFasting,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: c.textMuted)),
            const Spacer(),
            Text(fast.protocolType?.toString() ?? '',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          fast.elapsedTimeString?.toString() ?? '--:--',
          style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: c.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          '${fast.remainingTimeString} left'
          '${zone != null ? '  ·  ${zone.displayName}' : ''}',
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: c.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(c.accent),
          ),
        ),
        const SizedBox(height: 16),
        _primaryButton(context, c, 'Open fasting tracker'),
      ],
    );
  }

  Widget _primaryButton(BuildContext context, ThemeColors c, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          HapticService.medium();
          context.push('/fasting');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentContrast,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
