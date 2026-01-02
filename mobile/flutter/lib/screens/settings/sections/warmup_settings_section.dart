import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../widgets/section_header.dart';

/// The warmup and stretch settings section for configuring durations.
///
/// Allows users to customize:
/// - Warmup duration (1-15 minutes)
/// - Cool-down stretch duration (1-15 minutes)
class WarmupSettingsSection extends StatelessWidget {
  const WarmupSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'WARMUP & COOLDOWN'),
        SizedBox(height: 12),
        _WarmupSettingsCard(),
      ],
    );
  }
}

class _WarmupSettingsCard extends ConsumerWidget {
  const _WarmupSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warmupState = ref.watch(warmupDurationProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Warmup duration slider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.whatshot,
                      color: orange,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Warmup Duration',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${warmupState.warmupDurationMinutes} min',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'How long to warm up before workouts',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: orange,
                    inactiveTrackColor: orange.withValues(alpha: 0.2),
                    thumbColor: orange,
                    overlayColor: orange.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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
                      Text('1 min', style: TextStyle(fontSize: 11, color: textMuted)),
                      Text('15 min', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

          // Stretch duration slider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      color: cyan,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cooldown Stretch Duration',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${warmupState.stretchDurationMinutes} min',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'How long to stretch after workouts',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: cyan,
                    inactiveTrackColor: cyan.withValues(alpha: 0.2),
                    thumbColor: cyan,
                    overlayColor: cyan.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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
                      Text('1 min', style: TextStyle(fontSize: 11, color: textMuted)),
                      Text('15 min', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder),

          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for effective warm-ups:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  context,
                  'Quick sessions: 3-5 min for light days',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildTipItem(
                  context,
                  'Standard: 5-7 min for most workouts',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildTipItem(
                  context,
                  'Heavy lifting: 10-15 min for intense sessions',
                  textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
