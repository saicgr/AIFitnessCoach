import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/background_sync_service.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/design_system/zealova.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Whether the "auto-import workouts" toggle can actually do anything.
/// Requires BOTH the stored preference AND a real platform health-store
/// connection — a stored `true` from before the user disconnected Apple
/// Health / Health Connect must not render as a live, firing setting
/// (E2E settings row 86, same pattern as the Cycle reminders fix).
bool autoImportActiveNow({
  required bool isConnected,
  required bool storedEnabled,
}) =>
    isConnected && storedEnabled;

class HealthDevicesPage extends ConsumerWidget {
  const HealthDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = ThemeColors.of(context).background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).settingsHealthDevices),
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
class _AutoImportWorkoutsCard extends ConsumerStatefulWidget {
  const _AutoImportWorkoutsCard();

  @override
  ConsumerState<_AutoImportWorkoutsCard> createState() =>
      _AutoImportWorkoutsCardState();
}

class _AutoImportWorkoutsCardState
    extends ConsumerState<_AutoImportWorkoutsCard> {
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
    // Nothing to import if the platform health store was never connected —
    // an ON-looking toggle here would be a setting that cannot possibly
    // fire (E2E row 86, same pattern as the Cycle reminders fix).
    final isConnected = ref.watch(healthSyncProvider).isConnected;
    final enabled = autoImportActiveNow(
      isConnected: isConnected,
      storedEnabled: _enabled ?? true,
    );

    return ZealovaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
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
                    isConnected
                        ? 'Pull workouts logged by other apps in '
                            '${Platform.isAndroid ? 'Health Connect' : 'Apple Health'} '
                            'into your Zealova history automatically.'
                        : 'Connect ${Platform.isAndroid ? 'Health Connect' : 'Apple Health'} '
                            'above to enable auto-import.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
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
            ZealovaToggle(
              value: enabled,
              onChanged: isConnected ? _set : null,
            ),
        ],
      ),
    );
  }
}
