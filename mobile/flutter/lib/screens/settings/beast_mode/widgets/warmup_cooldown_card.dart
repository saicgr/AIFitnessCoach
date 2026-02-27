import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/warmup_duration_provider.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

/// Beast Mode card with continuous sliders for precise warmup & cooldown control.
class WarmupCooldownCard extends ConsumerWidget {
  final BeastThemeData theme;
  const WarmupCooldownCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warmupState = ref.watch(warmupDurationProvider);

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Warmup & Cooldown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 4),
          Text('Precise duration control (1-15 min)', style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 16),

          // Warmup slider
          _sectionLabel('Warmup Duration', '${warmupState.warmupDurationMinutes} min'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: warmupState.warmupDurationMinutes.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              onChanged: warmupState.isLoading
                  ? null
                  : (value) {
                      HapticFeedback.selectionClick();
                    },
              onChangeEnd: warmupState.isLoading
                  ? null
                  : (value) async {
                      HapticFeedback.lightImpact();
                      await ref
                          .read(warmupDurationProvider.notifier)
                          .setWarmupDuration(value.round());
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('8 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('15 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cooldown slider
          _sectionLabel('Cooldown Duration', '${warmupState.stretchDurationMinutes} min'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.cyan,
              inactiveTrackColor: AppColors.cyan.withValues(alpha: 0.2),
              thumbColor: AppColors.cyan,
              overlayColor: AppColors.cyan.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: warmupState.stretchDurationMinutes.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              onChanged: warmupState.isLoading
                  ? null
                  : (value) {
                      HapticFeedback.selectionClick();
                    },
              onChangeEnd: warmupState.isLoading
                  ? null
                  : (value) async {
                      HapticFeedback.lightImpact();
                      await ref
                          .read(warmupDurationProvider.notifier)
                          .setStretchDuration(value.round());
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('8 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('15 min', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
        ),
      ],
    );
  }
}
