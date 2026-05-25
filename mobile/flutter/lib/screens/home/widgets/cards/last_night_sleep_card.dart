import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// "Last Night's Sleep" card matching the GymBeat / FitOn reference: large
/// duration, time window underneath, and a horizontal stage bar split into
/// deep / light / REM / awake bands. Reads from the existing
/// `dailyActivityProvider` (which already pulls SLEEP_DEEP / SLEEP_LIGHT /
/// SLEEP_REM / SLEEP_AWAKE samples). Hidden when no sleep data is available
/// (Health Connect not connected or last night un-tracked).
class LastNightSleepCard extends ConsumerWidget {
  const LastNightSleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final sync = ref.watch(healthSyncProvider);
    if (!sync.isConnected) return const SizedBox.shrink();

    final activity = ref.watch(dailyActivityProvider).today;
    final total = activity?.sleepMinutes;
    if (total == null || total <= 0) return const SizedBox.shrink();

    // Default-zero so the bar still renders even when only `sleepMinutes`
    // is available (HealthKit's coarse summary path).
    final deep = activity?.deepSleepMinutes ?? 0;
    final rem = activity?.remSleepMinutes ?? 0;
    final awake = activity?.awakeSleepMinutes ?? 0;
    // `total` (sleepMinutes) is time ASLEEP — deep + light + REM + any
    // generic un-staged sleep (e.g. a nap a source logged without a
    // breakdown). Show the light band as everything asleep that isn't deep
    // or REM, so the stage bar always spans the full headline total even
    // when one of the night's sessions had no deep/light/REM staging.
    final reportedLight = activity?.lightSleepMinutes ?? 0;
    final residualLight = total - deep - rem;
    int light = residualLight > reportedLight ? residualLight : reportedLight;
    if (light < 0) light = 0;

    final hours = total ~/ 60;
    final minutes = total % 60;
    final fmt = DateFormat('HH:mm');

    // Prefer the real session window from Health Connect / HealthKit. Only
    // when the precise bounds are missing (coarse summary path) do we fall
    // back to walking back `total` minutes from a typical wake-up so the
    // card still shows a believable window.
    final realStart = activity?.sleepStart;
    final realEnd = activity?.sleepEnd;
    final DateTime bedtime;
    final DateTime wake;
    if (realStart != null && realEnd != null) {
      bedtime = realStart;
      wake = realEnd;
    } else {
      final now = DateTime.now();
      wake = DateTime(now.year, now.month, now.day, 8, 18);
      bedtime = wake.subtract(Duration(minutes: total));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        // Tapping the card opens the full Sleep detail screen — date strip,
        // hypnogram, sleep score, debt/regularity, charts, coaching.
        onTap: () {
          HapticService.light();
          context.push('/health/sleep');
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bedtime_rounded,
                          color: AppColors.purple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).lastNightSleepLastNightSSleep,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: textMuted),
                  ],
                ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${hours}h',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.0,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${minutes}m',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.0,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${fmt.format(bedtime)} – ${fmt.format(wake)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _SleepStageBar(
                deep: deep,
                light: light,
                rem: rem,
                awake: awake,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  if (deep > 0)
                    _legendDot(AppColors.purple, '${_fmtDur(deep)} Deep',
                        textMuted),
                  if (light > 0)
                    _legendDot(AppColors.purple.withValues(alpha: 0.5),
                        '${_fmtDur(light)} Light', textMuted),
                  if (rem > 0)
                    _legendDot(AppColors.cyan, '${_fmtDur(rem)} REM',
                        textMuted),
                  if (awake > 0)
                    _legendDot(AppColors.warning, '${_fmtDur(awake)} Awake',
                        textMuted),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _fmtDur(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _SleepStageBar extends StatelessWidget {
  final int deep;
  final int light;
  final int rem;
  final int awake;

  const _SleepStageBar({
    required this.deep,
    required this.light,
    required this.rem,
    required this.awake,
  });

  @override
  Widget build(BuildContext context) {
    final total = deep + light + rem + awake;
    if (total <= 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (deep > 0)
              Expanded(
                flex: deep,
                child: Container(color: AppColors.purple),
              ),
            if (light > 0)
              Expanded(
                flex: light,
                child: Container(
                  color: AppColors.purple.withValues(alpha: 0.5),
                ),
              ),
            if (rem > 0)
              Expanded(flex: rem, child: Container(color: AppColors.cyan)),
            if (awake > 0)
              Expanded(
                  flex: awake, child: Container(color: AppColors.warning)),
          ],
        ),
      ),
    );
  }
}
