import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/weight_increments_sheet.dart';
import '../widgets/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Sub-page for Workout Settings + Exercise Preferences.
class WorkoutSettingsPage extends ConsumerStatefulWidget {
  const WorkoutSettingsPage({super.key});

  @override
  ConsumerState<WorkoutSettingsPage> createState() => _WorkoutSettingsPageState();
}

class _WorkoutSettingsPageState extends ConsumerState<WorkoutSettingsPage> {
  static const _kSkipWarningKey = 'skip_incomplete_warning_dismissed';
  bool _skipWarningDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadSkipWarningPref();
  }

  Future<void> _loadSkipWarningPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _skipWarningDismissed = prefs.getBool(_kSkipWarningKey) ?? false);
  }

  Future<void> _toggleSkipWarning(bool showWarning) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSkipWarningKey, !showWarning);
    if (!mounted) return;
    setState(() => _skipWarningDismissed = !showWarning);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).workoutSettingsWorkoutSettings,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Program ──
              SectionHeader(
                title: AppLocalizations.of(context).workoutSettingsProgram,
                subtitle: AppLocalizations.of(context).workoutSettingsWhatYouTrainAnd,
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.fitness_center,
                    title: AppLocalizations.of(context).workoutSettingsWorkoutType,
                    subtitle: AppLocalizations.of(context).workoutSettingsStrengthCardioOrMixed,
                    isWorkoutTypeSelector: true,
                    iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  SettingItemData(
                    icon: Icons.view_week,
                    title: AppLocalizations.of(context).workoutSettingsTrainingSplit,
                    subtitle: AppLocalizations.of(context).workoutSettingsPushPullLegsFull,
                    isTrainingSplitSelector: true,
                    iconColor: isDark ? AppColors.waterBlue : AppColorsLight.waterBlue,
                  ),
                  SettingItemData(
                    icon: Icons.calendar_month,
                    title: AppLocalizations.of(context).workoutSettingsWorkoutDays,
                    subtitle: AppLocalizations.of(context).workoutSettingsWhichDaysYouTrain,
                    isWorkoutDaysSelector: true,
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  // Per-day customization — assign focus + duration + intensity
                  // to each training day so the AI plan generator respects per-day
                  // preferences. Added 2026-05-27.
                  SettingItemData(
                    icon: Icons.tune_rounded,
                    title: 'Per-day customization',
                    subtitle: 'Focus, duration, intensity per training day',
                    isPerDayOverridesSelector: true,
                    iconColor: isDark ? AppColors.macroProtein : AppColorsLight.macroProtein,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Progression & Load ──
              SectionHeader(
                title: AppLocalizations.of(context).workoutSettingsProgressionLoad,
                subtitle: AppLocalizations.of(context).workoutSettingsHowHeavyAndHow,
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.speed,
                    title: AppLocalizations.of(context).workoutSettingsMy1rms,
                    subtitle: AppLocalizations.of(context).workoutSettingsViewAndEditYour,
                    isMyOneRMsScreen: true,
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.percent,
                    title: AppLocalizations.of(context).workoutSettingsTrainingIntensity,
                    subtitle: AppLocalizations.of(context).workoutSettingsWorkAtAPercentage,
                    isTrainingIntensitySelector: true,
                    iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  SettingItemData(
                    icon: Icons.trending_up,
                    title: AppLocalizations.of(context).workoutSettingsProgressionPace,
                    subtitle: AppLocalizations.of(context).workoutSettingsHowFastToIncrease,
                    isProgressionPaceSelector: true,
                    iconColor: isDark ? AppColors.green : AppColorsLight.green,
                  ),
                  SettingItemData(
                    icon: Icons.tune,
                    title: AppLocalizations.of(context).workoutSettingsWeeklyVariety,
                    subtitle: AppLocalizations.of(context).workoutSettingsHowMuchExercisesChange,
                    isVariationSlider: true,
                    iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  SettingItemData(
                    icon: Icons.replay_circle_filled_outlined,
                    title: AppLocalizations.of(context).workoutSettingsProgressionDeload,
                    subtitle: AppLocalizations.of(context).workoutSettingsAutoDeloadDeloadFrequency,
                    onTap: () =>
                        GoRouter.of(context).push('/settings/progression-pace'),
                    iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Live Coaching ──
              SectionHeader(
                title: AppLocalizations.of(context).workoutSettingsLiveCoaching,
                subtitle: AppLocalizations.of(context).workoutSettingsWhatHappensDuringA,
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.monitor_heart_outlined,
                    title: AppLocalizations.of(context).workoutSettingsFatigueDetection,
                    subtitle: ref.watch(fatigueAlertsEnabledProvider)
                        ? 'ON — Alerts when performance drops'
                        : 'OFF — No fatigue alerts',
                    onTap: () {
                      ref.read(fatigueAlertsEnabledProvider.notifier).toggle();
                    },
                    trailing: ZealovaToggle(
                      value: ref.watch(fatigueAlertsEnabledProvider),
                      onChanged: (val) {
                        ref.read(fatigueAlertsEnabledProvider.notifier).setEnabled(val);
                      },
                    ),
                    iconColor: ThemeColors.of(context).accent,
                  ),
                  SettingItemData(
                    icon: Icons.auto_awesome_outlined,
                    title: AppLocalizations.of(context).workoutSettingsPreSetInsights,
                    subtitle: ref.watch(preSetInsightEnabledProvider)
                        ? 'ON — Data-grounded tip above Set 1'
                        : 'OFF — No pre-set banner',
                    onTap: () {
                      ref.read(preSetInsightEnabledProvider.notifier).toggle();
                    },
                    trailing: ZealovaToggle(
                      value: ref.watch(preSetInsightEnabledProvider),
                      onChanged: (val) {
                        ref
                            .read(preSetInsightEnabledProvider.notifier)
                            .setEnabled(val);
                      },
                    ),
                    iconColor: ThemeColors.of(context).accent,
                  ),
                  SettingItemData(
                    icon: Icons.checklist_rounded,
                    title: AppLocalizations.of(context).workoutSettingsIncompleteExerciseWarning,
                    subtitle: !_skipWarningDismissed
                        ? 'ON — Warns before finishing with unlogged sets'
                        : 'OFF — No warning on incomplete logs',
                    onTap: () => _toggleSkipWarning(_skipWarningDismissed),
                    trailing: ZealovaToggle(
                      value: !_skipWarningDismissed,
                      onChanged: _toggleSkipWarning,
                    ),
                    iconColor: ThemeColors.of(context).accent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Units & Tracking ──
              SectionHeader(
                title: AppLocalizations.of(context).workoutSettingsUnitsTracking,
                subtitle: AppLocalizations.of(context).workoutSettingsHowWeightsAreDisplayed,
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.swap_horiz,
                    title: AppLocalizations.of(context).workoutSettingsWorkoutWeightUnit,
                    subtitle: ref.watch(workoutWeightUnitProvider) == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                    onTap: () => _showWorkoutWeightUnitSelector(context, ref),
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.tune,
                    title: AppLocalizations.of(context).workoutSettingsWeightIncrements,
                    subtitle: AppLocalizations.of(context)!.workoutSettingsPageStepSizeTapTo(ref.watch(weightIncrementsProvider).unit.toUpperCase()),
                    onTap: () => showWeightIncrementsSheet(context),
                    iconColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                  SettingItemData(
                    icon: Icons.show_chart,
                    title: AppLocalizations.of(context).workoutSettingsProgressCharts,
                    subtitle: AppLocalizations.of(context).workoutSettingsVisualizeStrengthVolumeOv,
                    isProgressChartsScreen: true,
                    iconColor: isDark ? AppColors.green : AppColorsLight.green,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Exercise Preferences ──
              SectionHeader(
                title: AppLocalizations.of(context).workoutSettingsExercisePreferences,
                subtitle: AppLocalizations.of(context).workoutSettingsCustomizeWhichExercisesAppe,
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.fitness_center,
                    title: AppLocalizations.of(context).workoutSettingsMyExercises,
                    subtitle: AppLocalizations.of(context).workoutSettingsFavoritesAvoidedAndQueue,
                    onTap: () =>
                        GoRouter.of(context).push('/settings/my-exercises'),
                    iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  SettingItemData(
                    icon: Icons.history,
                    title: AppLocalizations.of(context).workoutSettingsImportWorkoutHistory,
                    subtitle: AppLocalizations.of(context).workoutSettingsAddPastWorkoutsFor,
                    isWorkoutHistoryImport: true,
                    iconColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }

  void _showWorkoutWeightUnitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUnit = ref.read(workoutWeightUnitProvider);
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).workoutSettingsWorkoutWeightUnit,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).workoutSettingsUnitForLoggingExercise,
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
              const SizedBox(height: 16),
              ...[
                {'unit': 'kg', 'label': 'Kilograms (kg)', 'desc': 'Metric system'},
                {'unit': 'lbs', 'label': 'Pounds (lbs)', 'desc': 'Imperial system'},
              ].map((opt) {
                final isSelected = currentUnit == opt['unit'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    Icons.fitness_center,
                    color: isSelected ? accent : textMuted,
                  ),
                  title: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(opt['desc']!, style: TextStyle(fontSize: 12, color: textMuted)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: accent) : null,
                  selected: isSelected,
                  selectedTileColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    try {
                      await ref.read(authStateProvider.notifier).updateUserProfile({
                        'workout_weight_unit': opt['unit'],
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Workout weight unit → ${opt['label']}'),
                            backgroundColor: AppColors.cyan,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
