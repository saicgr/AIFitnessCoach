import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auto_switch_provider.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/location_permission_provider.dart';
import '../../../data/providers/time_slot_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../widgets/section_header.dart';

/// Location settings section for auto-switch gym profiles
///
/// Allows users to enable/disable location-based and time-based automatic gym profile switching.
class LocationSettingsSection extends StatelessWidget {
  const LocationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'AUTO-SWITCH PROFILES'),
        SizedBox(height: 12),
        _LocationSettingsCard(),
        SizedBox(height: 16),
        _TimeSettingsCard(),
      ],
    );
  }
}

class _LocationSettingsCard extends ConsumerWidget {
  const _LocationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final autoSwitchEnabled = ref.watch(autoSwitchEnabledProvider);
    final autoSwitchProfiles = ref.watch(autoSwitchProfilesProvider);
    final hasBackgroundPermission = ref.watch(hasBackgroundLocationPermissionProvider);
    final profilesState = ref.watch(gymProfilesProvider);

    // Count profiles with locations
    final profilesWithLocation = profilesState.maybeWhen(
      data: (profiles) => profiles.where((p) => p.hasLocation).length,
      orElse: () => 0,
    );

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Auto-switch toggle
          InkWell(
            onTap: () async {
              // Check permission first
              final hasPermission = hasBackgroundPermission.maybeWhen(
                data: (v) => v,
                orElse: () => false,
              );

              if (!hasPermission && !autoSwitchEnabled) {
                // Request permission
                _showPermissionDialog(context, ref);
                return;
              }

              HapticService.light();
              await ref.read(autoSwitchEnabledProvider.notifier).toggle();

              // Start or stop monitoring
              if (!autoSwitchEnabled) {
                ref.read(autoSwitchProvider.notifier).startMonitoring();
              } else {
                ref.read(autoSwitchProvider.notifier).stopMonitoring();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: autoSwitchEnabled
                          ? accentColor.withOpacity(0.15)
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: autoSwitchEnabled ? accentColor : textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-switch gym profiles',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          autoSwitchEnabled
                              ? 'Active for ${autoSwitchProfiles.length} gym(s)'
                              : 'Switch profiles based on your location',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: autoSwitchEnabled,
                    onChanged: (value) async {
                      // Check permission first
                      final hasPermission = hasBackgroundPermission.maybeWhen(
                        data: (v) => v,
                        orElse: () => false,
                      );

                      if (!hasPermission && value) {
                        _showPermissionDialog(context, ref);
                        return;
                      }

                      HapticService.light();
                      await ref.read(autoSwitchEnabledProvider.notifier).setEnabled(value);

                      if (value) {
                        ref.read(autoSwitchProvider.notifier).startMonitoring();
                      } else {
                        ref.read(autoSwitchProvider.notifier).stopMonitoring();
                      }
                    },
                    activeColor: accentColor,
                  ),
                ],
              ),
            ),
          ),

          // Info about profiles with locations
          if (profilesWithLocation > 0) ...[
            Divider(height: 1, color: cardBorder, indent: 62),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$profilesWithLocation gym profile${profilesWithLocation > 1 ? 's' : ''} with location set',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Help text if no profiles have locations
          if (profilesWithLocation == 0) ...[
            Divider(height: 1, color: cardBorder, indent: 62),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add a location to your gym profiles to enable auto-switch. Edit a profile and tap "Add Location".',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Permission status
          hasBackgroundPermission.when(
            data: (hasPermission) {
              if (!hasPermission) {
                return Column(
                  children: [
                    Divider(height: 1, color: cardBorder),
                    InkWell(
                      onTap: () => _showPermissionDialog(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Background location required',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Tap to grant permission',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Permission',
                style: TextStyle(color: textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-switch needs "Always" location access to detect when you arrive at your gym.',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your location is only used locally to check proximity to saved gyms.',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // First request when-in-use, then always
              final notifier = ref.read(locationPermissionNotifierProvider.notifier);
              await notifier.requestWhenInUsePermission();
              await notifier.requestBackgroundPermission();
            },
            child: Text(
              'Grant Permission',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time-based auto-switch settings card
class _TimeSettingsCard extends ConsumerWidget {
  const _TimeSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final timeAutoSwitchEnabled = ref.watch(timeAutoSwitchEnabledProvider);
    final profilesWithTime = ref.watch(profilesWithTimePreferenceProvider);
    final canEnable = ref.watch(canEnableTimeAutoSwitchProvider);

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Time auto-switch toggle
          InkWell(
            onTap: () async {
              HapticService.light();
              await ref.read(timeAutoSwitchEnabledProvider.notifier).toggle();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: timeAutoSwitchEnabled
                          ? accentColor.withOpacity(0.15)
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: timeAutoSwitchEnabled ? accentColor : textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time-based switching',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAutoSwitchEnabled
                              ? 'Active for ${profilesWithTime.length} profile(s)'
                              : 'Switch profiles based on time of day',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: timeAutoSwitchEnabled,
                    onChanged: (value) async {
                      HapticService.light();
                      await ref.read(timeAutoSwitchEnabledProvider.notifier).setEnabled(value);
                    },
                    activeColor: accentColor,
                  ),
                ],
              ),
            ),
          ),

          // Info about profiles with time preferences
          if (profilesWithTime.isNotEmpty) ...[
            Divider(height: 1, color: cardBorder, indent: 62),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${profilesWithTime.length} profile${profilesWithTime.length > 1 ? 's' : ''} with time preference set',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Help text if no profiles have time preferences
          if (!canEnable) ...[
            Divider(height: 1, color: cardBorder, indent: 62),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set a preferred workout time in your gym profiles to enable time-based switching.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
