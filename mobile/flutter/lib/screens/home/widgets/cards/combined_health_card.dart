import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/recovery_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Compact entry-point card into the Combined Health hub (`/health/combined`).
///
/// Self-hiding sibling card (the `DeloadRecommendationCard` pattern — no new
/// home `TileType`, `build_runner` is forbidden): it collapses to
/// [SizedBox.shrink] whenever there is nothing to surface, so it is safe to
/// place unconditionally:
///   • Health Connect / HealthKit not connected → hidden (the steps tile
///     owns the connect CTA, so this card never duplicates it);
///   • connected but the recovery score has no inputs yet → still shown as
///     a plain "Health" entry point (the hub itself has honest empty
///     sections), so the user can always reach their history.
///
/// Placed after `LastNightSleepCard` on You > Overview and stacked above
/// `TodaysHealthCard` in `tile_factory.dart`'s `stepsCounter` case.
class CombinedHealthCard extends ConsumerWidget {
  const CombinedHealthCard({super.key});

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
    // Not connected → hide; the steps tile already shows the connect CTA.
    if (!sync.isConnected) return const SizedBox.shrink();

    final recoveryAsync = ref.watch(recoveryProvider);
    final recovery = recoveryAsync.valueOrNull;

    // Caption adapts to whatever data exists — never fabricated.
    final String caption;
    final Color accent;
    if (recovery != null) {
      caption = '${recovery.label} recovery'
          '${recovery.restingHR != null ? ' · resting HR ${recovery.restingHR}' : ''}';
      accent = recovery.score >= 80
          ? AppColors.success
          : recovery.score >= 60
              ? AppColors.teal
              : recovery.score >= 40
                  ? AppColors.warning
                  : AppColors.error;
    } else {
      caption = 'Steps, heart rate, sleep and recovery';
      accent = AppColors.teal;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          context.push('/health/combined');
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.monitor_heart_rounded,
                    color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).combinedHealthCardHealthOverview,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: TextStyle(fontSize: 12, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (recovery != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Text(
                    '${recovery.score}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
