import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Fasting Timer Card - Shows active fast progress or start prompt
class FastingTimerCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const FastingTimerCard({
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

    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;

    // For active fasts, watch the timer providers for real-time updates
    final progress = hasFast ? ref.watch(fastingProgressProvider) : 0.0;
    final zone = hasFast ? ref.watch(computedFastingZoneProvider) : null;
    final elapsedMinutes = hasFast ? ref.watch(fastingElapsedMinutesProvider) : 0;

    final elapsedHours = elapsedMinutes ~/ 60;
    final elapsedMins = elapsedMinutes % 60;
    final elapsedText = '${elapsedHours}h ${elapsedMins}m';

    final zoneColor = zone?.color ?? accentColor;

    if (size == TileSize.compact) {
      return _buildCompact(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        hasFast: hasFast,
        elapsedText: elapsedText,
        zoneColor: zoneColor,
        progress: progress,
      );
    }

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/fasting');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFast
                ? zoneColor.withValues(alpha: 0.4)
                : cardBorder,
          ),
        ),
        child: hasFast
            ? _buildActiveFast(
                context,
                textColor: textColor,
                textMuted: textMuted,
                accentColor: accentColor,
                activeFast: activeFast!,
                progress: progress,
                zone: zone!,
                zoneColor: zoneColor,
                elapsedText: elapsedText,
              )
            : _buildNoFast(
                context,
                textColor: textColor,
                textMuted: textMuted,
                accentColor: accentColor,
              ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required bool hasFast,
    required String elapsedText,
    required Color zoneColor,
    required double progress,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/fasting');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFast
                ? zoneColor.withValues(alpha: 0.4)
                : textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFast) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 2,
                  backgroundColor: textMuted.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                elapsedText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: zoneColor,
                ),
              ),
            ] else ...[
              Icon(Icons.timer_outlined, color: textMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                'Fast',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFast(
    BuildContext context, {
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
    required dynamic activeFast,
    required double progress,
    required dynamic zone,
    required Color zoneColor,
    required String elapsedText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.timer, color: zoneColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Fasting',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const Spacer(),
            // Zone badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: zoneColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                zone.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: zoneColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Circular progress + elapsed time
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: textMuted.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elapsedText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    activeFast.protocol,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoFast(
    BuildContext context, {
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              'Fasting',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Not fasting',
          style: TextStyle(
            fontSize: 16,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            HapticService.light();
            context.push('/fasting');
          },
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Start'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
