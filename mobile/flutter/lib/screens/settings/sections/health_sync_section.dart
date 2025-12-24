import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/health_service.dart';
import '../widgets/section_header.dart';

/// Health sync preferences model.
class HealthSyncPreferences {
  final bool syncSteps;
  final bool syncCalories;
  final bool syncWeight;
  final bool syncBodyFat;
  final bool syncHeartRate;
  final bool syncSleep;

  const HealthSyncPreferences({
    this.syncSteps = true,
    this.syncCalories = true,
    this.syncWeight = true,
    this.syncBodyFat = true,
    this.syncHeartRate = true,
    this.syncSleep = false,
  });

  HealthSyncPreferences copyWith({
    bool? syncSteps,
    bool? syncCalories,
    bool? syncWeight,
    bool? syncBodyFat,
    bool? syncHeartRate,
    bool? syncSleep,
  }) {
    return HealthSyncPreferences(
      syncSteps: syncSteps ?? this.syncSteps,
      syncCalories: syncCalories ?? this.syncCalories,
      syncWeight: syncWeight ?? this.syncWeight,
      syncBodyFat: syncBodyFat ?? this.syncBodyFat,
      syncHeartRate: syncHeartRate ?? this.syncHeartRate,
      syncSleep: syncSleep ?? this.syncSleep,
    );
  }
}

/// Health sync preferences provider.
final healthSyncPreferencesProvider =
    StateNotifierProvider<HealthSyncPreferencesNotifier, HealthSyncPreferences>((ref) {
  return HealthSyncPreferencesNotifier();
});

/// Health sync preferences state notifier.
class HealthSyncPreferencesNotifier extends StateNotifier<HealthSyncPreferences> {
  HealthSyncPreferencesNotifier() : super(const HealthSyncPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = HealthSyncPreferences(
      syncSteps: prefs.getBool('health_sync_steps') ?? true,
      syncCalories: prefs.getBool('health_sync_calories') ?? true,
      syncWeight: prefs.getBool('health_sync_weight') ?? true,
      syncBodyFat: prefs.getBool('health_sync_body_fat') ?? true,
      syncHeartRate: prefs.getBool('health_sync_heart_rate') ?? true,
      syncSleep: prefs.getBool('health_sync_sleep') ?? false,
    );
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_sync_steps', state.syncSteps);
    await prefs.setBool('health_sync_calories', state.syncCalories);
    await prefs.setBool('health_sync_weight', state.syncWeight);
    await prefs.setBool('health_sync_body_fat', state.syncBodyFat);
    await prefs.setBool('health_sync_heart_rate', state.syncHeartRate);
    await prefs.setBool('health_sync_sleep', state.syncSleep);
  }

  void setSyncSteps(bool value) {
    state = state.copyWith(syncSteps: value);
    _savePreferences();
  }

  void setSyncCalories(bool value) {
    state = state.copyWith(syncCalories: value);
    _savePreferences();
  }

  void setSyncWeight(bool value) {
    state = state.copyWith(syncWeight: value);
    _savePreferences();
  }

  void setSyncBodyFat(bool value) {
    state = state.copyWith(syncBodyFat: value);
    _savePreferences();
  }

  void setSyncHeartRate(bool value) {
    state = state.copyWith(syncHeartRate: value);
    _savePreferences();
  }

  void setSyncSleep(bool value) {
    state = state.copyWith(syncSleep: value);
    _savePreferences();
  }
}

/// The health sync section for connecting to Health Connect/Apple Health.
class HealthSyncSection extends StatelessWidget {
  const HealthSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'HEALTH SYNC'),
        SizedBox(height: 12),
        _HealthConnectSettingsCard(),
      ],
    );
  }
}

class _HealthConnectSettingsCard extends ConsumerStatefulWidget {
  const _HealthConnectSettingsCard();

  @override
  ConsumerState<_HealthConnectSettingsCard> createState() => _HealthConnectSettingsCardState();
}

class _HealthConnectSettingsCardState extends ConsumerState<_HealthConnectSettingsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final syncState = ref.watch(healthSyncProvider);
    final healthName = Platform.isAndroid ? 'Health Connect' : 'Apple Health';
    final healthIcon = Platform.isAndroid ? Icons.watch : Icons.favorite;

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Main toggle row
          InkWell(
            onTap: () {
              if (syncState.isConnected) {
                setState(() => _isExpanded = !_isExpanded);
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: syncState.isConnected
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      healthIcon,
                      color: syncState.isConnected ? AppColors.success : AppColors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          healthName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              syncState.isConnected ? 'Connected' : 'Not connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: syncState.isConnected ? AppColors.success : textMuted,
                              ),
                            ),
                            if (syncState.isConnected && syncState.lastSyncTime != null) ...[
                              Text(
                                ' - Last sync: ${_formatLastSync(syncState.lastSyncTime!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                            if (syncState.isConnected) ...[
                              const SizedBox(width: 4),
                              Icon(
                                _isExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 16,
                                color: textMuted,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (syncState.isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cyan,
                      ),
                    )
                  else
                    Switch(
                      value: syncState.isConnected,
                      onChanged: (value) async {
                        if (value) {
                          await _connect();
                        } else {
                          await _disconnect();
                        }
                      },
                      activeColor: AppColors.success,
                    ),
                ],
              ),
            ),
          ),

          // Expandable sync preferences section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSyncPreferences(isDark, textPrimary, textSecondary, textMuted, cardBorder),
            crossFadeState:
                _isExpanded && syncState.isConnected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          // Error message if any
          if (syncState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Text(
                syncState.error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncPreferences(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardBorder,
  ) {
    final syncPrefs = ref.watch(healthSyncPreferencesProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: cardBorder),
          const SizedBox(height: 8),
          Text(
            'Data to sync',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Activity data toggles
          _buildSyncToggle(
            icon: Icons.directions_walk,
            label: 'Steps & Distance',
            isEnabled: syncPrefs.syncSteps,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncSteps(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.local_fire_department,
            label: 'Calories Burned',
            isEnabled: syncPrefs.syncCalories,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncCalories(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            isEnabled: syncPrefs.syncWeight,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncWeight(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.percent,
            label: 'Body Fat',
            isEnabled: syncPrefs.syncBodyFat,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncBodyFat(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.favorite_outline,
            label: 'Heart Rate',
            isEnabled: syncPrefs.syncHeartRate,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncHeartRate(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.bedtime_outlined,
            label: 'Sleep',
            isEnabled: syncPrefs.syncSleep,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncSleep(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),

          const SizedBox(height: 12),

          // Sync now button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _syncNow(),
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Sync Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: BorderSide(color: AppColors.cyan.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncToggle({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isEnabled ? AppColors.cyan : textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isEnabled ? textSecondary : textMuted,
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: AppColors.cyan,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _connect() async {
    final notifier = ref.read(healthSyncProvider.notifier);

    // Check availability first
    final available = await notifier.checkAvailability();
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isAndroid
                ? 'Health Connect is not available. Please install it from the Play Store.'
                : 'Apple Health is not available on this device.',
          ),
          backgroundColor: AppColors.error,
          action: Platform.isAndroid
              ? SnackBarAction(
                  label: 'Install',
                  textColor: Colors.white,
                  onPressed: () {
                    // Open Play Store for Health Connect
                  },
                )
              : null,
        ),
      );
      return;
    }

    final connected = await notifier.connect();
    if (connected && mounted) {
      setState(() => _isExpanded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${Platform.isAndroid ? "Health Connect" : "Apple Health"}'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh daily activity after connecting
      ref.read(dailyActivityProvider.notifier).loadTodayActivity();
    } else if (mounted) {
      // Show helpful message about granting permissions manually
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Open Health Connect and grant permissions for AI Fitness Coach'),
          backgroundColor: AppColors.orange,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openHealthConnect(),
          ),
        ),
      );
    }
  }

  void _openHealthConnect() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          title: Text(
            'Grant Permissions',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          content: Text(
            '1. Open Health Connect app\n'
            '2. Go to "App permissions"\n'
            '3. Find "AI Fitness Coach"\n'
            '4. Enable all permissions\n'
            '5. Return here and try again',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppColors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnect() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          title: Text(
            'Disconnect ${Platform.isAndroid ? "Health Connect" : "Apple Health"}?',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          content: Text(
            'Your health data will no longer sync with the app. You can reconnect at any time.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Disconnect',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(healthSyncProvider.notifier).disconnect();
      if (mounted) {
        setState(() => _isExpanded = false);
      }
    }
  }

  Future<void> _syncNow() async {
    final notifier = ref.read(healthSyncProvider.notifier);
    final data = await notifier.syncMeasurements(days: 7);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced ${data.length} health data points'),
          backgroundColor: data.isNotEmpty ? AppColors.success : AppColors.textMuted,
        ),
      );
    }

    // Also refresh daily activity
    ref.read(dailyActivityProvider.notifier).refresh();
  }
}
