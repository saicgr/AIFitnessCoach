import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';
import 'shared/tappable_cell.dart';
import 'shared/slider_dialog.dart';

class DifficultyCard extends ConsumerWidget {
  final BeastThemeData theme;

  const DifficultyCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(beastModeConfigProvider);
    final notifier = ref.read(beastModeConfigProvider.notifier);

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
                    Text('Difficulty Multipliers',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Tap any cell to edit scaling factors',
                        style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  notifier.resetAllDifficultyMultipliers();
                  AppSnackBar.info(context, 'Difficulty multipliers reset');
                },
                child: Text('Reset All',
                    style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Header
          Row(
            children: [
              Expanded(flex: 12, child: Text('Tier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 10, child: Text('Volume', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 10, child: Text('Rest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 10, child: Text('RPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted))),
            ],
          ),
          const SizedBox(height: 8),
          ...config.difficultyMultipliers.entries.map((entry) {
            final tier = entry.key;
            final values = entry.value;
            final color = kTierColors[tier] ?? theme.textPrimary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(flex: 12, child: Text(tier, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
                  Expanded(
                    flex: 10,
                    child: TappableCell(
                      text: '${values['volume']!.toStringAsFixed(2)}x',
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$tier - Volume',
                        value: values['volume']!,
                        min: 0.50, max: 1.50, step: 0.05,
                        format: (v) => '${v.toStringAsFixed(2)}x',
                        onChanged: (v) => notifier.updateDifficultyMultiplier(tier, 'volume', v),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: TappableCell(
                      text: '${values['rest']!.toStringAsFixed(2)}x',
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$tier - Rest',
                        value: values['rest']!,
                        min: 0.50, max: 1.50, step: 0.05,
                        format: (v) => '${v.toStringAsFixed(2)}x',
                        onChanged: (v) => notifier.updateDifficultyMultiplier(tier, 'rest', v),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: TappableCell(
                      text: values['rpe']!.toStringAsFixed(1),
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$tier - RPE',
                        value: values['rpe']!,
                        min: 1.0, max: 10.0, step: 0.5,
                        format: (v) => v.toStringAsFixed(1),
                        onChanged: (v) => notifier.updateDifficultyMultiplier(tier, 'rpe', v),
                      ),
                    ),
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
