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

class MoodCard extends ConsumerWidget {
  final BeastThemeData theme;

  const MoodCard({super.key, required this.theme});

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
                    Text('Mood Multipliers',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Tap cells to tune mood-based adjustments',
                        style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  notifier.resetAllMoodMultipliers();
                  AppSnackBar.info(context, 'Mood multipliers reset');
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
              Expanded(flex: 13, child: Text('Mood', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 9, child: Text('Int.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 9, child: Text('Vol.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 9, child: Text('Rest', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textMuted))),
              Expanded(flex: 13, child: Text('Bias', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textMuted))),
            ],
          ),
          const SizedBox(height: 8),
          ...config.moodMultipliers.entries.map((entry) {
            final mood = entry.key;
            final values = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(flex: 13, child: Text(mood, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textPrimary))),
                  Expanded(
                    flex: 9,
                    child: TappableCell(
                      text: '${(values['intensity'] as double).toStringAsFixed(2)}x',
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$mood - Intensity',
                        value: values['intensity'] as double,
                        min: 0.50, max: 1.30, step: 0.05,
                        format: (v) => '${v.toStringAsFixed(2)}x',
                        onChanged: (v) => notifier.updateMoodMultiplier(mood, 'intensity', v),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: TappableCell(
                      text: '${(values['volume'] as double).toStringAsFixed(2)}x',
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$mood - Volume',
                        value: values['volume'] as double,
                        min: 0.50, max: 1.30, step: 0.05,
                        format: (v) => '${v.toStringAsFixed(2)}x',
                        onChanged: (v) => notifier.updateMoodMultiplier(mood, 'volume', v),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: TappableCell(
                      text: '${(values['rest'] as double).toStringAsFixed(2)}x',
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onTap: () => showSliderDialog(
                        context: context,
                        title: '$mood - Rest',
                        value: values['rest'] as double,
                        min: 0.50, max: 1.50, step: 0.05,
                        format: (v) => '${v.toStringAsFixed(2)}x',
                        onChanged: (v) => notifier.updateMoodMultiplier(mood, 'rest', v),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 13,
                    child: TappableBiasCell(
                      current: values['bias'] as String,
                      textColor: theme.textPrimary,
                      isDark: theme.isDark,
                      onSelected: (selected) => notifier.updateMoodMultiplier(mood, 'bias', selected),
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
