import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/background_sync_service.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
class HealthDevicesPage extends ConsumerWidget {
  const HealthDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(title: AppLocalizations.of(context).settingsHealthDevices),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              HealthSyncSection(),
              SizedBox(height: 16),
              // Auto-import workouts logged in Apple Health / Health Connect by
              // other apps (Strava, Peloton, etc.) into your Zealova history.
              _AutoImportWorkoutsCard(),
              SizedBox(height: 16),
              // BLE heart-rate monitor support is disabled for now. The
              // service + section are kept in the tree for easy re-enable;
              // Android "Nearby Devices" prompts stay suppressed as long as
              // nothing constructs FlutterReactiveBle.
              // BleHeartRateSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle for auto-importing externally-logged workouts (from Apple Health /
/// Health Connect) into the user's Zealova workout history. Backed by
/// [BackgroundSyncService]'s SharedPreferences-persisted flag, which the
/// periodic background sync task reads on each firing.
class _AutoImportWorkoutsCard extends StatefulWidget {
  const _AutoImportWorkoutsCard();

  @override
  State<_AutoImportWorkoutsCard> createState() =>
      _AutoImportWorkoutsCardState();
}

class _AutoImportWorkoutsCardState extends State<_AutoImportWorkoutsCard> {
  bool? _enabled; // null until the SharedPreferences read resolves.

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value =
        await BackgroundSyncService.isAutoImportExternalWorkoutsEnabled();
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _set(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _enabled = value); // Optimistic.
    await BackgroundSyncService.setAutoImportExternalWorkouts(value);
    // Turning it on → kick an immediate import so the user doesn't wait for
    // the next periodic tick.
    if (value) {
      await BackgroundSyncService.triggerExternalWorkoutSyncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final enabled = _enabled ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.sync_rounded, size: 18, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-import workouts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull workouts logged by other apps in Apple Health / '
                  'Health Connect into your Zealova history automatically.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_enabled == null)
            const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch.adaptive(
              value: enabled,
              onChanged: _set,
              activeTrackColor: c.accent.withValues(alpha: 0.5),
              activeThumbColor: c.accent,
            ),
        ],
      ),
    );
  }
}
