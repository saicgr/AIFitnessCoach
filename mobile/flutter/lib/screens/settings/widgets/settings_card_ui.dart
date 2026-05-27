part of 'settings_card.dart';

/// Methods extracted from SettingsCard
extension _SettingsCardExt on SettingsCard {

  void _showTimezoneSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTimezone = ref.read(timezoneProvider).timezone;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => GlassSheet(
          showHandle: false,
          child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).settingsCardUiChooseTimezone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: commonTimezones.length,
                  itemBuilder: (context, index) {
                    final tz = commonTimezones[index];
                    final isSelected = tz.id == currentTimezone;
                    return _TimezoneOptionTile(
                      timezone: tz,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(timezoneProvider.notifier).setTimezone(tz.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }


  void _showProgressionPaceSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPace = ref.read(trainingPreferencesProvider).progressionPace;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).workoutSettingsProgressionPace,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiHowFastShouldWe,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...ProgressionPace.values.map((pace) => _ProgressionPaceOptionTile(
                  pace: pace,
                  isSelected: pace == currentPace,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(trainingPreferencesProvider.notifier).setProgressionPace(pace);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }


  void _showWorkoutTypeSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentType = ref.read(trainingPreferencesProvider).workoutType;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).workoutSettingsWorkoutType,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiWhatTypeOfWorkouts,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...WorkoutType.values.map((type) => _WorkoutTypeOptionTile(
                  type: type,
                  isSelected: type == currentType,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(trainingPreferencesProvider.notifier).setWorkoutType(type);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }


  // Split info with required days for schedule mismatch validation
  void _showTrainingSplitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Each section shows the first 4 presets in a 2-column grid + a
    // "View all" tile that opens AllSplitsScreen filtered to that category.
    // Pre-2026-05-27 each section rendered as a horizontal ListView with all
    // 8+ items, forcing the user to swipe to see what's there — UX-hostile.
    const _previewLimit = 4;
    final categories = <({String title, String key, List<AISplitPreset> presets})>[
      (
        title: 'Classic Splits',
        key: 'classic',
        presets: aiSplitPresets.where((p) => p.category == 'classic').toList(),
      ),
      (
        title: 'AI-Powered',
        key: 'ai_powered',
        presets: aiSplitPresets.where((p) => p.category == 'ai_powered').toList(),
      ),
      (
        title: 'Specialty',
        key: 'specialty',
        presets: aiSplitPresets.where((p) => p.category == 'specialty').toList(),
      ),
    ];

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => GlassSheet(
          showHandle: false,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).workoutSettingsTrainingSplit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).settingsCardUiChooseHowToStructure,
                  style: TextStyle(fontSize: 14, color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final cat in categories) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 4),
                          child: Text(
                            cat.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        // 2-column grid of first 4 presets in this category.
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.65,
                          children: [
                            for (final preset in cat.presets.take(_previewLimit))
                              CompactSplitCard(
                                preset: preset,
                                onTap: () {
                                  Navigator.pop(context);
                                  showGlassSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    builder: (ctx) => AISplitPresetDetailSheet(preset: preset),
                                  );
                                },
                              ),
                          ],
                        ),
                        if (cat.presets.length > _previewLimit) ...[
                          const SizedBox(height: 10),
                          _ViewAllSplitsTile(
                            categoryKey: cat.key,
                            categoryLabel: cat.title,
                            remaining: cat.presets.length - _previewLimit,
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => AllSplitsScreen(
                                    initialCategory: cat.key,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showConsistencyModeSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = ref.read(consistencyModeProvider).mode;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).trainingPreferencesExerciseConsistency,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiHowShouldTheAi,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...ConsistencyMode.values.map((mode) => _ConsistencyModeOptionTile(
                  mode: mode,
                  isSelected: mode == currentMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(consistencyModeProvider.notifier).setMode(mode);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }


  void _showTrainingIntensitySelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIntensity = ref.read(trainingIntensityProvider).globalIntensityPercent;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).workoutSettingsTrainingIntensity, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColorsLight.textPrimary)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context).settingsCardUiHowHardShouldYour, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _intensityChip('Light', 60, currentIntensity, context, ref),
                    _intensityChip('Moderate', 70, currentIntensity, context, ref),
                    _intensityChip('Heavy', 80, currentIntensity, context, ref),
                    _intensityChip('Max', 90, currentIntensity, context, ref),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showWeightUnitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyUnit = ref.read(weightUnitProvider);
    final workoutUnit = ref.read(workoutWeightUnitProvider);
    final measurementUnit = ref.read(authStateProvider).user?.preferredMeasurementUnit ?? 'cm';
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;

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
                AppLocalizations.of(context).settingsCardUiUnits,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiWeightWorkoutAndBody,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // Body Weight Unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiBodyWeight,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiForWeighingYourselfBmi,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 16),
                _UnitChip(
                  label: 'kg',
                  isSelected: bodyUnit == 'kg',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateWeightUnit(context, ref, 'kg');
                  },
                ),
                const SizedBox(width: 10),
                _UnitChip(
                  label: 'lbs',
                  isSelected: bodyUnit == 'lbs',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateWeightUnit(context, ref, 'lbs');
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 24),

            // Workout Weight Unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiWorkoutWeight,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiForLoggingLiftsSets,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 16),
                _UnitChip(
                  label: 'kg',
                  isSelected: workoutUnit == 'kg',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateWorkoutWeightUnit(context, ref, 'kg');
                  },
                ),
                const SizedBox(width: 10),
                _UnitChip(
                  label: 'lbs',
                  isSelected: workoutUnit == 'lbs',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateWorkoutWeightUnit(context, ref, 'lbs');
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 24),

            // Body Measurements Unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiBodyMeasurements,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.of(context).settingsCardUiForWaistChestHips,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 16),
                _UnitChip(
                  label: 'cm',
                  isSelected: measurementUnit == 'cm',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateMeasurementUnit(context, ref, 'cm');
                  },
                ),
                const SizedBox(width: 10),
                _UnitChip(
                  label: 'in',
                  isSelected: measurementUnit == 'in',
                  accent: accent,
                  isDark: isDark,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await _updateMeasurementUnit(context, ref, 'in');
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }


  void _showAccentColorPicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAccent = ref.read(accentColorProvider);

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(AppLocalizations.of(context).settingsCardUiAccentColor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColorsLight.textPrimary)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(AppLocalizations.of(context).settingsCardUiChooseAnAccentColor, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AccentColorGrid(
                  currentAccent: currentAccent,
                  onColorSelected: (accent) {
                    ref.read(accentColorProvider.notifier).setAccent(accent);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

}

/// "View all <category>" tile rendered below each training-split section's
/// 2x2 grid when more presets exist beyond the first four. Tap routes to
/// the full-screen AllSplitsScreen pre-filtered to that category.
class _ViewAllSplitsTile extends StatelessWidget {
  const _ViewAllSplitsTile({
    required this.categoryKey,
    required this.categoryLabel,
    required this.remaining,
    required this.isDark,
    required this.onTap,
  });

  final String categoryKey;
  final String categoryLabel;
  final int remaining;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'View all $categoryLabel ($remaining more)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
