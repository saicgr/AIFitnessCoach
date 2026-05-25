import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/manage_gym_profiles_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Dedicated "Managed Gym" section card for the Workouts tab.
///
/// Surfaces the user's active gym profile (name, environment, equipment
/// count) as a standalone section directly below Exercise Preferences,
/// matching the section-card styling used by [ExercisePreferencesCard].
/// Tapping anywhere opens [ManageGymProfilesSheet] so the user can switch
/// or edit profiles.
class ManagedGymCard extends ConsumerWidget {
  /// Optional margin override. Defaults to horizontal 16px.
  final EdgeInsetsGeometry? margin;

  const ManagedGymCard({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final activeProfile = ref.watch(activeGymProfileProvider);
    final profilesAsync = ref.watch(gymProfilesProvider);
    final profileCount = profilesAsync.valueOrNull?.length ?? 0;

    // Active profile drives the accent tint; fall back to the theme accent
    // when no profile exists yet.
    final tint = activeProfile?.profileColor ?? accentColor;

    final String title = activeProfile?.name ?? 'Set up your gym';
    final String subtitle = activeProfile != null
        ? _subtitleFor(activeProfile.workoutEnvironment,
            activeProfile.equipment.length)
        : 'Add equipment so workouts match your space';

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            showGlassSheet(
              context: context,
              builder: (_) => const ManageGymProfilesSheet(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile icon badge
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _iconWidget(activeProfile?.icon, tint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activeProfile != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tint.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                AppLocalizations.of(context).managedGymCardActive,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: tint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profileCount > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$profileCount gym profiles · tap to switch',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders the gym profile icon. Profiles store either an emoji or a
  /// material icon name string — mirror [ManageGymProfilesSheet]'s logic.
  Widget _iconWidget(String? icon, Color tint) {
    if (icon == null || icon.isEmpty) {
      return Icon(Icons.storefront_outlined, color: tint, size: 22);
    }
    if (icon.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return Text(icon, style: const TextStyle(fontSize: 20));
    }
    final iconData = switch (icon) {
      'fitness_center' => Icons.fitness_center_rounded,
      'home' => Icons.home_rounded,
      'business' => Icons.business_rounded,
      'hotel' => Icons.hotel_rounded,
      'park' => Icons.park_rounded,
      'sports_gymnastics' => Icons.sports_gymnastics_rounded,
      'self_improvement' => Icons.self_improvement_rounded,
      'directions_run' => Icons.directions_run_rounded,
      _ => Icons.fitness_center_rounded,
    };
    return Icon(iconData, color: tint, size: 22);
  }

  String _subtitleFor(String environment, int equipmentCount) {
    final env = switch (environment.toLowerCase()) {
      'gym' => 'Full gym',
      'home' => 'Home gym',
      'home_gym' => 'Home gym',
      'outdoor' => 'Outdoor',
      'hotel' => 'Hotel / travel',
      'bodyweight' => 'Bodyweight',
      _ => environment.isEmpty ? 'Gym' : environment,
    };
    if (equipmentCount == 0) {
      return '$env · no equipment added yet';
    }
    return '$env · $equipmentCount equipment item${equipmentCount == 1 ? '' : 's'}';
  }
}
