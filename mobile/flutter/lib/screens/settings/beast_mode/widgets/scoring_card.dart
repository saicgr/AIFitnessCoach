import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class ScoringCard extends ConsumerWidget {
  final BeastThemeData theme;

  const ScoringCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(beastModeConfigProvider);
    final notifier = ref.read(beastModeConfigProvider.notifier);
    final weights = config.scoringWeights;
    final total = weights.values.fold(0.0, (a, b) => a + b);
    final totalPct = (total * 100).round();
    final isWarning = totalPct > 100 || totalPct < 90;

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise Scoring Breakdown',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('6-factor weighted selection algorithm',
                        style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  notifier.resetScoringWeights();
                  AppSnackBar.info(context, 'Scoring weights reset');
                },
                child: Text('Reset',
                    style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 28,
              child: Row(
                children: weights.entries.map((e) {
                  final pct = total > 0 ? (e.value / total * 100).round() : 0;
                  final color = kScoringColors[e.key] ?? Colors.grey;
                  return Expanded(
                    flex: max((e.value * 100).round(), 1),
                    child: Tooltip(
                      message: '${e.key}: $pct%',
                      child: Container(
                        color: color,
                        alignment: Alignment.center,
                        child: pct >= 10
                            ? Text('$pct%',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Total indicator
          Row(
            children: [
              Text('Total: $totalPct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isWarning ? AppColors.error : AppColors.success,
                    fontFamily: 'monospace',
                  )),
              if (isWarning) ...[
                const SizedBox(width: 8),
                Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(totalPct > 100 ? 'Over 100%' : 'Under 90%',
                    style: TextStyle(fontSize: 11, color: AppColors.error)),
              ],
              const Spacer(),
              if (isWarning)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    notifier.normalizeScoringWeights();
                    AppSnackBar.info(context, 'Weights normalized to 100%');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Normalize',
                        style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Sliders per factor
          ...weights.entries.map((e) {
            final color = kScoringColors[e.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  SizedBox(width: 80, child: Text(e.key, style: TextStyle(fontSize: 11, color: theme.textPrimary))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: color,
                        inactiveTrackColor: color.withValues(alpha: 0.15),
                        thumbColor: color,
                        overlayColor: color.withValues(alpha: 0.08),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: e.value.clamp(0.0, 0.50),
                        min: 0.0,
                        max: 0.50,
                        divisions: 50,
                        onChanged: (v) => notifier.updateScoringWeight(e.key, v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('${(e.value * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, color: color, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
