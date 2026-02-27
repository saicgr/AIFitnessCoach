import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class RpeCard extends ConsumerWidget {
  final BeastThemeData theme;

  const RpeCard({super.key, required this.theme});

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
                    Text('RPE Auto-Regulation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Automatically adjust based on RPE feedback', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              Switch(
                value: config.rpeAutoRegEnabled,
                activeColor: AppColors.orange,
                onChanged: (v) {
                  HapticService.selection();
                  notifier.updateRpeAutoReg(v);
                },
              ),
            ],
          ),
          if (config.rpeAutoRegEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 80, child: Text('Sensitivity', style: TextStyle(fontSize: 12, color: theme.textPrimary))),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.orange,
                      inactiveTrackColor: AppColors.orange.withValues(alpha: 0.15),
                      thumbColor: AppColors.orange,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: config.rpeSensitivity,
                      min: 0.5, max: 2.0, divisions: 15,
                      onChanged: (v) => notifier.updateRpeSensitivity(v),
                    ),
                  ),
                ),
                SizedBox(width: 40, child: Text(config.rpeSensitivity.toStringAsFixed(1),
                    style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            Text('RPE Prompt Frequency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kRpePromptModes.entries.map((e) {
                final isSelected = config.rpePromptMode == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  selectedColor: AppColors.orange.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.orange : theme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: isSelected ? AppColors.orange.withValues(alpha: 0.5) : theme.cardBorder),
                  onSelected: (_) {
                    HapticService.selection();
                    notifier.updateRpePromptMode(e.key);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
