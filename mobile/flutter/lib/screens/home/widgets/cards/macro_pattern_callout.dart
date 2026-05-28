/// F3.76 — Macro pattern callout.
///
/// Surfaces a multi-day macro trend (e.g. "Protein consistently 25g under
/// goal" or "Carbs spike on weekends") with a one-tap path into nutrition
/// recommendations. Self-collapses without a backing signal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_pattern_providers.dart';
import '../../../../data/services/haptic_service.dart';

enum MacroKind { protein, carbs, fat, fiber }

class MacroPatternSignal {
  final MacroKind macro;
  final String headline; // pre-localised
  final String body;
  final int daysObserved;
  const MacroPatternSignal({
    required this.macro,
    required this.headline,
    required this.body,
    required this.daysObserved,
  });
}

/// Bridges `macroPatternProvider` to the card's local model. Today the
/// backend only emits a low-protein-weekday pattern; if more macros land
/// later (high-carb weekends, low-fiber Mondays) extend the bridge here
/// without touching the card.
final macroPatternSignalProvider =
    Provider.autoDispose<MacroPatternSignal?>((ref) {
  final async = ref.watch(macroPatternProvider);
  final data = async.asData?.value;
  if (data == null || !data.hasPattern) return null;

  final names = data.weekdayNames;
  if (names.isEmpty) return null;

  // Build a human headline: "Protein dips on Mondays" /
  // "Protein dips on Mondays + Wednesdays".
  final dayList = names.length == 1 ? '${names.first}s' : '${names.join('s & ')}s';
  final avg = data.avgProteinG?.toStringAsFixed(0) ?? '?';
  final target = data.targetProteinG.toStringAsFixed(0);

  return MacroPatternSignal(
    macro: MacroKind.protein,
    headline: 'Protein dips on $dayList',
    body:
        'Average $avg g vs your $target g goal on ${names.length == 1 ? names.first : "those days"}. '
        'A higher-protein lunch usually closes the gap.',
    // The backend window is 21 days; the card gates on >= 5.
    daysObserved: 21,
  );
});

class MacroPatternCallout extends ConsumerWidget {
  const MacroPatternCallout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MacroPatternSignal? signal;
    try {
      signal = ref.watch(macroPatternSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.daysObserved < 5) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.insights_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                signal.headline,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            signal.body,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Pattern from the last ${signal.daysObserved} days.',
            style: TextStyle(fontSize: 11.5, color: c.textMuted),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/nutrition');
            },
            child: Text(
              'See suggestions →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
