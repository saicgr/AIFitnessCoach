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
          // Warmup enabled toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: textPrimary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Warmup Phase',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show warmup screen before workouts',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: warmupState.warmupEnabled,
                  onChanged: warmupState.isLoading
                      ? null
                      : (value) {
                          HapticFeedback.lightImpact();
                          ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                        },
                  activeColor: orange,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

          // Warmup duration presets (only shown when enabled)
          if (warmupState.warmupEnabled)
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'How long to warm up before workouts',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip(context, ref, 'Quick', 3, warmupState.warmupDurationMinutes, orange, isWarmup: true),
                    _buildPresetChip(context, ref, 'Standard', 5, warmupState.warmupDurationMinutes, orange, isWarmup: true),
                    _buildPresetChip(context, ref, 'Extended', 10, warmupState.warmupDurationMinutes, orange, isWarmup: true),
                    _buildPresetChip(context, ref, 'Max', 15, warmupState.warmupDurationMinutes, orange, isWarmup: true),
                  ],
                ),
              ],
            ),
          ),

          if (warmupState.warmupEnabled)
            Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

          // Stretch enabled toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.self_improvement,
                  color: textPrimary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Cooldown Stretch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show stretch screen after workouts',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: warmupState.stretchEnabled,
                  onChanged: warmupState.isLoading
                      ? null
                      : (value) {
                          HapticFeedback.lightImpact();
                          ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                        },
                  activeColor: cyan,
                ),
              ],
            ),
          ),

          if (warmupState.stretchEnabled)
            Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

          // Stretch duration presets (only shown when enabled)
          if (warmupState.stretchEnabled)
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'How long to stretch after workouts',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip(context, ref, 'Quick', 3, warmupState.stretchDurationMinutes, cyan, isWarmup: false),
                    _buildPresetChip(context, ref, 'Standard', 5, warmupState.stretchDurationMinutes, cyan, isWarmup: false),
                    _buildPresetChip(context, ref, 'Extended', 10, warmupState.stretchDurationMinutes, cyan, isWarmup: false),
                    _buildPresetChip(context, ref, 'Max', 15, warmupState.stretchDurationMinutes, cyan, isWarmup: false),
                  ],
                ),
              ],
            ),
          ),

          if (warmupState.warmupEnabled || warmupState.stretchEnabled)
            Divider(height: 1, color: cardBorder),

          // Info section (only show if warmup or stretch is enabled)
          if (warmupState.warmupEnabled || warmupState.stretchEnabled)
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

  Widget _buildPresetChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    int minutes,
    int currentMinutes,
    Color accentColor, {
    required bool isWarmup,
  }) {
    final isSelected = currentMinutes == minutes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ChoiceChip(
      label: Text(
        '$label ($minutes min)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? accentColor : textMuted,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.lightImpact();
        if (isWarmup) {
          ref.read(warmupDurationProvider.notifier).setWarmupDuration(minutes);
        } else {
          ref.read(warmupDurationProvider.notifier).setStretchDuration(minutes);
        }
      },
      selectedColor: accentColor.withValues(alpha: 0.15),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      checkmarkColor: accentColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? accentColor.withValues(alpha: 0.3) : Colors.transparent,
        ),
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
