import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/accessibility/accessibility_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class FontScaleCard extends ConsumerWidget {
  final BeastThemeData theme;
  const FontScaleCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilitySettings = ref.watch(accessibilityProvider);
    final scale = accessibilitySettings.fontScale;

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
                    Text('Font Scale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Precise font scaling control', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${scale.toStringAsFixed(2)}x',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: scale,
              min: 0.85,
              max: 1.5,
              divisions: 13,
              onChanged: (value) {
                ref.read(accessibilityProvider.notifier).setFontScale(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0.85x', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('1.0x', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('1.5x', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
