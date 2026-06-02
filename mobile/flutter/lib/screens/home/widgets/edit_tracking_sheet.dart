import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
// =============================================================================
// Tracking pills visibility state + provider
// =============================================================================

class TrackingPillsState {
  final bool showGoals;
  final bool showCalories;
  final bool showWater;
  final bool showNutrition; // merged calories + water pill
  final bool showBurned;
  final bool showSteps;
  final bool showSleep;
  final bool showStreak;
  final bool showHabits;
  final bool showCardioLoad; // Gap 3 — training-load (ACWR) state pill
  final bool isLoaded;

  const TrackingPillsState({
    this.showGoals = true,
    this.showCalories = true,
    this.showWater = true,
    this.showNutrition = true,
    this.showBurned = true,
    this.showSteps = false,
    this.showSleep = false,
    this.showStreak = false,
    this.showHabits = false,
    this.showCardioLoad = false,
    this.isLoaded = false,
  });

  TrackingPillsState copyWith({
    bool? showGoals,
    bool? showCalories,
    bool? showWater,
    bool? showNutrition,
    bool? showBurned,
    bool? showSteps,
    bool? showSleep,
    bool? showStreak,
    bool? showHabits,
    bool? showCardioLoad,
    bool? isLoaded,
  }) {
    return TrackingPillsState(
      showGoals: showGoals ?? this.showGoals,
      showCalories: showCalories ?? this.showCalories,
      showWater: showWater ?? this.showWater,
      showNutrition: showNutrition ?? this.showNutrition,
      showBurned: showBurned ?? this.showBurned,
      showSteps: showSteps ?? this.showSteps,
      showSleep: showSleep ?? this.showSleep,
      showStreak: showStreak ?? this.showStreak,
      showHabits: showHabits ?? this.showHabits,
      showCardioLoad: showCardioLoad ?? this.showCardioLoad,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  int get visibleCount =>
      (showGoals ? 1 : 0) +
      (showNutrition ? 1 : 0) +
      (showBurned ? 1 : 0) +
      (showSteps ? 1 : 0) +
      (showSleep ? 1 : 0) +
      (showStreak ? 1 : 0) +
      (showHabits ? 1 : 0) +
      (showCardioLoad ? 1 : 0);
}

class TrackingPillsNotifier extends StateNotifier<TrackingPillsState> {
  TrackingPillsNotifier() : super(const TrackingPillsState()) {
    _load();
  }

  static const _prefix = 'tracking_pill_';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TrackingPillsState(
      showGoals: prefs.getBool('${_prefix}goals') ?? true,
      showCalories: prefs.getBool('${_prefix}calories') ?? true,
      showWater: prefs.getBool('${_prefix}water') ?? true,
      showNutrition: prefs.getBool('${_prefix}nutrition') ?? true,
      showBurned: prefs.getBool('${_prefix}burned') ?? true,
      showSteps: prefs.getBool('${_prefix}steps') ?? false,
      showSleep: prefs.getBool('${_prefix}sleep') ?? false,
      showStreak: prefs.getBool('${_prefix}streak') ?? true,
      showHabits: prefs.getBool('${_prefix}habits') ?? false,
      showCardioLoad: prefs.getBool('${_prefix}cardio_load') ?? false,
      isLoaded: true,
    );
  }

  Future<void> toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
    switch (key) {
      case 'goals':
        state = state.copyWith(showGoals: value);
        break;
      case 'calories':
        state = state.copyWith(showCalories: value);
        break;
      case 'water':
        state = state.copyWith(showWater: value);
        break;
      case 'nutrition':
        state = state.copyWith(showNutrition: value);
        break;
      case 'burned':
        state = state.copyWith(showBurned: value);
        break;
      case 'steps':
        state = state.copyWith(showSteps: value);
        break;
      case 'sleep':
        state = state.copyWith(showSleep: value);
        break;
      case 'streak':
        state = state.copyWith(showStreak: value);
        break;
      case 'habits':
        state = state.copyWith(showHabits: value);
        break;
      case 'cardio_load':
        state = state.copyWith(showCardioLoad: value);
        break;
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['goals', 'calories', 'water', 'nutrition', 'burned', 'steps', 'sleep', 'streak', 'habits', 'cardio_load']) {
      await prefs.remove('$_prefix$key');
    }
    state = const TrackingPillsState(isLoaded: true);
  }
}

final trackingPillsProvider =
    StateNotifierProvider<TrackingPillsNotifier, TrackingPillsState>(
  (ref) => TrackingPillsNotifier(),
);

// =============================================================================
// Edit Tracking Sheet
// =============================================================================

class EditTrackingSheet extends ConsumerWidget {
  const EditTrackingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillsState = ref.watch(trackingPillsProvider);
    final notifier = ref.read(trackingPillsProvider.notifier);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final pills = [
      _PillOption(
        key: 'goals',
        title: AppLocalizations.of(context).nutritionGoalsCardDailyGoals,
        subtitle: AppLocalizations.of(context).editTrackingLoginWeightMealWorkout,
        icon: Icons.flag_outlined,
        color: const Color(0xFF22C55E),
        enabled: pillsState.showGoals,
      ),
      _PillOption(
        key: 'nutrition',
        title: AppLocalizations.of(context).editTrackingNutritionHydration,
        subtitle: AppLocalizations.of(context).editTrackingCaloriesPCF,
        icon: Icons.restaurant_outlined,
        color: AppColors.orange,
        enabled: pillsState.showNutrition,
      ),
      _PillOption(
        key: 'burned',
        title: AppLocalizations.of(context).metricsDashboardCaloriesBurned,
        subtitle: AppLocalizations.of(context).editTrackingFromConnectedHealthDevices,
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF6B35),
        enabled: pillsState.showBurned,
      ),
      _PillOption(
        key: 'steps',
        title: AppLocalizations.of(context).syncedWorkoutDetailSteps,
        subtitle: AppLocalizations.of(context).editTrackingDailyStepCountFrom,
        icon: Icons.directions_walk,
        color: const Color(0xFF8B5CF6),
        enabled: pillsState.showSteps,
      ),
      _PillOption(
        key: 'sleep',
        title: AppLocalizations.of(context).sleepDetailSleep,
        subtitle: AppLocalizations.of(context).editTrackingLastNightSSleep,
        icon: Icons.bedtime_outlined,
        color: const Color(0xFF6366F1),
        enabled: pillsState.showSleep,
      ),
      _PillOption(
        key: 'streak',
        title: AppLocalizations.of(context).editTrackingWorkoutStreak,
        subtitle: AppLocalizations.of(context).editTrackingConsecutiveWorkoutDays,
        icon: Icons.bolt_outlined,
        color: const Color(0xFFF59E0B),
        enabled: pillsState.showStreak,
      ),
      _PillOption(
        key: 'habits',
        title: AppLocalizations.of(context).habitsTileCardHabits,
        subtitle: AppLocalizations.of(context).editTrackingDailyHabitCompletionProgres,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10B981),
        enabled: pillsState.showHabits,
      ),
      // Gap 3 — cardio training-load (ACWR) state. Plain strings (no ARB key)
      // to avoid multi-locale churn for a new optional pill; no apostrophes
      // (Android strings.xml aapt2 trap).
      _PillOption(
        key: 'cardio_load',
        title: 'Cardio load',
        subtitle: 'Training load and recovery balance',
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFFEF4444),
        enabled: pillsState.showCardioLoad,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).editTrackingEditTracking,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  notifier.resetToDefaults();
                },
                child: Text(
                  AppLocalizations.of(context).trophyFilterReset,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).editTrackingChooseWhichStatsTo,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),

          // Pill toggles (scrollable when content exceeds available space)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < pills.length; i++) ...[
                    _buildPillToggle(
                      context,
                      pills[i],
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      isLastEnabled: pillsState.visibleCount <= 1 && pills[i].enabled,
                      onChanged: (value) {
                        HapticService.light();
                        notifier.toggle(pills[i].key, value);
                      },
                    ),
                    if (i < pills.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).editTrackingAtLeastOneStat,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillToggle(
    BuildContext context,
    _PillOption pill, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required bool isLastEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pill.color.withValues(alpha: pill.enabled ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pill.icon,
              size: 20,
              color: pill.enabled ? pill.color : textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pill.enabled ? textPrimary : textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pill.subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: pill.enabled,
            onChanged: isLastEnabled ? null : onChanged,
            activeTrackColor: AppColors.cyan,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PillOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;

  const _PillOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}

/// Helper to show the edit tracking sheet
void showEditTrackingSheet(BuildContext context) {
  showGlassSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => const GlassSheet(
      child: EditTrackingSheet(),
    ),
  );
}
