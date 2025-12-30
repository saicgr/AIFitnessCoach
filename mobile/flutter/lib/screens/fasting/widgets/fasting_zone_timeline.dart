import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';

/// Horizontal timeline showing upcoming fasting zones
class FastingZoneTimeline extends ConsumerWidget {
  final FastingRecord activeFast;
  final bool isDark;

  const FastingZoneTimeline({
    super.key,
    required this.activeFast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Watch the timer for live updates
    final elapsedSeconds = ref.watch(fastingTimerProvider).value ?? 0;
    final elapsedMinutes = elapsedSeconds ~/ 60;
    final goalMinutes = activeFast.goalDurationMinutes;

    // Filter zones that are relevant for this fast
    final relevantZones = FastingZone.values.where((zone) {
      final zoneStartMinutes = zone.startHour * 60;
      return zoneStartMinutes <= goalMinutes;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasting Zones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal timeline
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: relevantZones.length,
              separatorBuilder: (_, __) => _buildConnector(isDark),
              itemBuilder: (context, index) {
                final zone = relevantZones[index];
                final zoneStartMinutes = zone.startHour * 60;
                final isReached = elapsedMinutes >= zoneStartMinutes;
                final isCurrent = FastingZone.fromElapsedMinutes(elapsedMinutes) == zone;

                return _ZoneChip(
                  zone: zone,
                  isReached: isReached,
                  isCurrent: isCurrent,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isDark) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(top: 25),
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}

class _ZoneChip extends StatelessWidget {
  final FastingZone zone;
  final bool isReached;
  final bool isCurrent;
  final bool isDark;

  const _ZoneChip({
    required this.zone,
    required this.isReached,
    required this.isCurrent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        // Zone indicator circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 50 : 40,
          height: isCurrent ? 50 : 40,
          decoration: BoxDecoration(
            color: isReached
                ? zone.color.withValues(alpha: 0.2)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                    .withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isReached ? zone.color : Colors.transparent,
              width: isCurrent ? 3 : 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: zone.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isReached
                ? Icon(
                    Icons.check,
                    color: zone.color,
                    size: isCurrent ? 24 : 20,
                  )
                : Text(
                    '${zone.startHour}h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Zone name
        SizedBox(
          width: 60,
          child: Text(
            zone.shortName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isReached ? zone.color : textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Extension for short zone names
extension FastingZoneShortName on FastingZone {
  String get shortName {
    switch (this) {
      case FastingZone.fed:
        return 'Fed';
      case FastingZone.postAbsorptive:
        return 'Post-Abs';
      case FastingZone.earlyFasting:
        return 'Early';
      case FastingZone.fatBurning:
        return 'Fat Burn';
      case FastingZone.ketosis:
        return 'Ketosis';
      case FastingZone.deepKetosis:
        return 'Deep Keto';
      case FastingZone.extended:
        return 'Extended';
    }
  }
}
