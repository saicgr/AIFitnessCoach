import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/muscle_analytics_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Muscle Heatmap Card - Shows top trained muscles as colored chips
class MuscleHeatmapCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const MuscleHeatmapCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final topMusclesAsync = ref.watch(topTrainedMusclesProvider);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/stats/muscle-analytics');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: topMusclesAsync.when(
          data: (muscles) => muscles.isEmpty
              ? _buildEmpty(textMuted: textMuted, accentColor: accentColor)
              : _buildContent(
                  muscles,
                  textColor: textColor,
                  textMuted: textMuted,
                  accentColor: accentColor,
                ),
          loading: () => _buildLoading(textMuted: textMuted, accentColor: accentColor),
          error: (error, _) => _buildError(
            ref,
            textMuted: textMuted,
            accentColor: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<dynamic> muscles, {
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
  }) {
    // Take top 6
    final topMuscles = muscles.take(6).toList();
    // Find max intensity for normalization
    final maxIntensity = topMuscles.isNotEmpty
        ? topMuscles.map((m) => m.intensity as double).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.accessibility_new, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
        const SizedBox(height: 12),

        // Muscle chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: topMuscles.map((muscle) {
            final intensity = (muscle.intensity as double);
            // Normalize to 0.3-1.0 range for opacity
            final normalized = maxIntensity > 0
                ? (intensity / maxIntensity * 0.7 + 0.3).clamp(0.3, 1.0)
                : 0.5;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: normalized * 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: normalized * 0.4),
                ),
              ),
              child: Text(
                muscle.formattedMuscleName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withValues(alpha: normalized),
                ),
              ),
            );
          }).toList(),
        ),

        // Summary
        if (topMuscles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Most trained: ${topMuscles.first.formattedMuscleName}',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty({
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Complete workouts to see muscle data',
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading({
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Shimmer placeholder chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(4, (_) => Container(
            width: 70,
            height: 28,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildError(
    WidgetRef ref, {
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.error_outline, color: textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              "Couldn't load",
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.invalidate(muscleHeatmapProvider),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
