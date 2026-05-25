import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/app_dialog.dart';
import '../widgets/section_header.dart';
import '../../../widgets/glass_sheet.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../ai_settings/ai_settings_screen.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Health sync preferences model.
class HealthSyncPreferences {
  final bool syncSteps;
  final bool syncCalories;
  final bool syncWeight;
  final bool syncBodyFat;
  final bool syncHeartRate;
  final bool syncSleep;
  final bool syncWorkoutsToHealth;
  final bool syncMealsToHealth;
  final bool syncHydrationToHealth;

  const HealthSyncPreferences({
    this.syncSteps = true,
    this.syncCalories = true,
    this.syncWeight = true,
    this.syncBodyFat = true,
    this.syncHeartRate = true,
    this.syncSleep = false,
    this.syncWorkoutsToHealth = true,
    this.syncMealsToHealth = true,
    this.syncHydrationToHealth = true,
  });

  HealthSyncPreferences copyWith({
    bool? syncSteps,
    bool? syncCalories,
    bool? syncWeight,
    bool? syncBodyFat,
    bool? syncHeartRate,
    bool? syncSleep,
    bool? syncWorkoutsToHealth,
    bool? syncMealsToHealth,
    bool? syncHydrationToHealth,
  }) {
    return HealthSyncPreferences(
      syncSteps: syncSteps ?? this.syncSteps,
      syncCalories: syncCalories ?? this.syncCalories,
      syncWeight: syncWeight ?? this.syncWeight,
      syncBodyFat: syncBodyFat ?? this.syncBodyFat,
      syncHeartRate: syncHeartRate ?? this.syncHeartRate,
      syncSleep: syncSleep ?? this.syncSleep,
      syncWorkoutsToHealth: syncWorkoutsToHealth ?? this.syncWorkoutsToHealth,
      syncMealsToHealth: syncMealsToHealth ?? this.syncMealsToHealth,
      syncHydrationToHealth: syncHydrationToHealth ?? this.syncHydrationToHealth,
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
      syncWorkoutsToHealth: prefs.getBool('health_sync_workouts_write') ?? true,
      syncMealsToHealth: prefs.getBool('health_sync_meals_write') ?? true,
      syncHydrationToHealth: prefs.getBool('health_sync_hydration_write') ?? true,
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
    await prefs.setBool('health_sync_workouts_write', state.syncWorkoutsToHealth);
    await prefs.setBool('health_sync_meals_write', state.syncMealsToHealth);
    await prefs.setBool('health_sync_hydration_write', state.syncHydrationToHealth);
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

  void setSyncWorkoutsToHealth(bool value) {
    state = state.copyWith(syncWorkoutsToHealth: value);
    _savePreferences();
  }

  void setSyncMealsToHealth(bool value) {
    state = state.copyWith(syncMealsToHealth: value);
    _savePreferences();
  }

  void setSyncHydrationToHealth(bool value) {
    state = state.copyWith(syncHydrationToHealth: value);
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
      children: [
        SectionHeader(title: AppLocalizations.of(context).healthSyncHealthSync),
        const SizedBox(height: 12),
        const _HealthConnectSettingsCard(),
        // Samsung Health help for Android users
        if (Platform.isAndroid) ...[
          const SizedBox(height: 8),
          const _SamsungHealthHelpRow(),
        ],
      ],
    );
  }
}

/// Helper row for Samsung Health users
class _SamsungHealthHelpRow extends ConsumerWidget {
  const _SamsungHealthHelpRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 14,
            color: textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).healthSyncUsingSamsungHealth,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showSamsungHealthSetup(context, isDark),
            child: Text(
              AppLocalizations.of(context).healthSyncSetupGuide,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSamsungHealthSetup(BuildContext context, bool isDark) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context) {
        return GlassSheet(
          showHandle: false,
          child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1428A0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.watch,
                          color: Color(0xFF1428A0),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).healthSyncConnectSamsungHealth,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Samsung Health data syncs to ${Branding.appName} through Health Connect. Follow these steps:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSetupStep(
                    isDark: isDark,
                    number: '1',
                    title: AppLocalizations.of(context).healthSyncOpenSamsungHealth,
                    subtitle: AppLocalizations.of(context).healthSyncGoToSettingsGear,
                  ),
                  _buildSetupStep(
                    isDark: isDark,
                    number: '2',
                    title: AppLocalizations.of(context).healthSyncFindHealthConnect,
                    subtitle: AppLocalizations.of(context).healthSyncScrollDownAndTap,
                  ),
                  _buildSetupStep(
                    isDark: isDark,
                    number: '3',
                    title: AppLocalizations.of(context).healthSyncEnableSync,
                    subtitle: AppLocalizations.of(context).healthSyncTurnOnSyncWith,
                  ),
                  _buildSetupStep(
                    isDark: isDark,
                    number: '4',
                    title: AppLocalizations.of(context).healthSyncSelectDataTypes,
                    subtitle: AppLocalizations.of(context).healthSyncEnableAllDataYou,
                  ),
                  _buildSetupStep(
                    isDark: isDark,
                    number: '5',
                    title: 'Connect ${Branding.appName}',
                    subtitle: AppLocalizations.of(context).healthSyncReturnHereAndToggle,
                    isLast: true,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your Samsung Health data will automatically appear in ${Branding.appName} after setup.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            // Try to open Samsung Health
                            final uri = Uri.parse('samsunghealth://');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(AppLocalizations.of(context).healthSyncOpenSamsungHealth),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1428A0),
                            side: const BorderSide(color: Color(0xFF1428A0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(AppLocalizations.of(context).weightIncrementsGotIt),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
      },
    );
  }

  Widget _buildSetupStep({
    required bool isDark,
    required String number,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                              syncState.isConnected ? AppLocalizations.of(context).healthSyncConnected : AppLocalizations.of(context).healthSyncNotConnected,
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
                      activeThumbColor: AppColors.success,
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
          _buildConsentCard(isDark, textPrimary, textMuted),
          const SizedBox(height: 8),
          Divider(color: cardBorder),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).healthSyncDataToSync,
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
            label: AppLocalizations.of(context).healthSyncStepsDistance,
            isEnabled: syncPrefs.syncSteps,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncSteps(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.local_fire_department,
            label: AppLocalizations.of(context).metricsDashboardCaloriesBurned,
            isEnabled: syncPrefs.syncCalories,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncCalories(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.monitor_weight_outlined,
            label: AppLocalizations.of(context).workoutSummaryAdvancedWeight,
            isEnabled: syncPrefs.syncWeight,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncWeight(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.percent,
            label: AppLocalizations.of(context).shareBodyAnalyzerBodyFat,
            isEnabled: syncPrefs.syncBodyFat,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncBodyFat(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.favorite_outline,
            label: AppLocalizations.of(context).workoutSummaryGeneralHeartRate,
            isEnabled: syncPrefs.syncHeartRate,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncHeartRate(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.bedtime_outlined,
            label: AppLocalizations.of(context).sleepDetailSleep,
            isEnabled: syncPrefs.syncSleep,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncSleep(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),

          const SizedBox(height: 12),
          Divider(color: cardBorder),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).healthSyncWriteToHealthApp,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildSyncToggle(
            icon: Icons.fitness_center,
            label: AppLocalizations.of(context).workoutListTitle,
            isEnabled: syncPrefs.syncWorkoutsToHealth,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncWorkoutsToHealth(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.restaurant,
            label: AppLocalizations.of(context).healthSyncMealsNutrition,
            isEnabled: syncPrefs.syncMealsToHealth,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncMealsToHealth(v),
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          _buildSyncToggle(
            icon: Icons.water_drop_outlined,
            label: AppLocalizations.of(context).workoutSummaryAdvancedHydration,
            isEnabled: syncPrefs.syncHydrationToHealth,
            onChanged: (v) => ref.read(healthSyncPreferencesProvider.notifier).setSyncHydrationToHealth(v),
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
              label: Text(AppLocalizations.of(context).syncStatusSyncNow),
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
            activeThumbColor: AppColors.cyan,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  /// GDPR Art. 9 explicit opt-in for storing health data on Zealova's
  /// servers. Without it the backend rejects every activity sync (403),
  /// so the AI coach, the sleep/health history screens and the proactive
  /// insights all stay empty. Surfaced here — right where users connect
  /// their wearable — because the canonical toggle buried in AI Settings
  /// was too easy to miss.
  Widget _buildConsentCard(bool isDark, Color textPrimary, Color textMuted) {
    final consent =
        ref.watch(aiSettingsProvider.select((s) => s.healthDataConsent));
    final accent = consent ? AppColors.success : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                consent
                    ? Icons.verified_user_rounded
                    : Icons.cloud_off_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  consent
                      ? AppLocalizations.of(context).healthSyncAiHealthCoachingIs
                      : 'Turn on AI health coaching',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Switch(
                value: consent,
                onChanged: (v) => ref
                    .read(aiSettingsProvider.notifier)
                    .updateHealthDataConsent(v),
                activeThumbColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            consent
                ? 'Zealova securely stores your Health data so your AI coach '
                    'can give recovery-aware workouts, sleep coaching and '
                    'proactive insights. Turn this off anytime.'
                : 'Connecting alone only shows data on this device. Allow '
                    'Zealova to securely store it so your AI coach, sleep '
                    'history and proactive insights can use it. Off by '
                    'default — entirely your choice.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Post-connection Art. 9 opt-in prompt. Connecting Health only surfaces
  /// data on-device; storing it server-side (so the AI coach / history /
  /// insights can use it) is a separate, explicit choice.
  Future<void> _promptHealthDataConsent() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(
          AppLocalizations.of(context).healthSyncEnableAiHealthCoaching,
          style: TextStyle(
            color:
                isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          'Your health data is now connected and shows on this device.\n\n'
          'To let your AI coach use it for recovery-aware workouts, sleep '
          'coaching and proactive insights, Zealova needs to securely store '
          'it on our servers. This is a separate, explicit choice — you can '
          'turn it off anytime in Settings.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondary
                : AppColorsLight.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).proposedChangeCardNotNow,
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(AppLocalizations.of(context).healthSyncEnable),
          ),
        ],
      ),
    );
    if (enable == true) {
      ref.read(aiSettingsProvider.notifier).updateHealthDataConsent(true);
    }
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
                ? AppLocalizations.of(context).healthSyncHealthConnectIsNot
                : 'Apple Health is not available on this device.',
          ),
          backgroundColor: AppColors.error,
          action: Platform.isAndroid
              ? SnackBarAction(
                  label: AppLocalizations.of(context).healthSyncInstall,
                  textColor: Colors.white,
                  onPressed: () {
                    launchUrl(
                      Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata'),
                      mode: LaunchMode.externalApplication,
                    );
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
      // Connecting only surfaces data on-device. Prompt the separate
      // Art. 9 opt-in to also store it server-side so the AI coach,
      // history and insights can use it — unless already granted.
      if (mounted && !ref.read(aiSettingsProvider).healthDataConsent) {
        await _promptHealthDataConsent();
      }
    } else if (mounted) {
      // Show helpful message about granting permissions manually
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Open Health Connect and grant permissions for ${Branding.appName}'),
          backgroundColor: AppColors.orange,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: AppLocalizations.of(context).recipesOpen,
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
            AppLocalizations.of(context).healthSyncGrantPermissions,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          content: Text(
            '1. Open Health Connect app\n'
            '2. Go to "App permissions"\n'
            '3. Find "${Branding.appName}"\n'
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
              child: Text(AppLocalizations.of(context).healthSyncOk, style: TextStyle(color: AppColors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnect() async {
    final confirm = await AppDialog.destructive(
      context,
      title: 'Disconnect ${Platform.isAndroid ? "Health Connect" : "Apple Health"}?',
      message: 'Your health data will no longer sync with the app. You can reconnect at any time.',
      confirmText: 'Disconnect',
      icon: Icons.link_off_rounded,
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
