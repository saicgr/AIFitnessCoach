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
                  'Choose Timezone',
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
                'Progression Pace',
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
                'How fast should we increase your weights?',
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
                'Workout Type',
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
                'What type of workouts do you prefer?',
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

    final categories = [
      ('Classic Splits', aiSplitPresets.where((p) => p.category == 'classic').toList()),
      ('AI-Powered', aiSplitPresets.where((p) => p.category == 'ai_powered').toList()),
      ('Specialty', aiSplitPresets.where((p) => p.category == 'specialty').toList()),
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
                  'Training Split',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how to structure your weekly workouts',
                  style: TextStyle(fontSize: 14, color: textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final (title, presets) in categories) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 4),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: presets.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final preset = presets[index];
                              return SizedBox(
                                width: 160,
                                child: CompactSplitCard(
                                  preset: preset,
                                  onTap: () {
                                    Navigator.pop(context); // Close split selector
                                    showGlassSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      builder: (ctx) => AISplitPresetDetailSheet(preset: preset),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
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
                'Exercise Consistency',
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
                'How should the AI select exercises for your workouts?',
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
                Text('Training Intensity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColorsLight.textPrimary)),
                const SizedBox(height: 8),
                Text('How hard should your workouts be?', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
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
                'Weight Units',
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
                'Body weight and workout weight can use different units',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // Body Weight Unit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'BODY WEIGHT',
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
                'For weighing yourself, BMI, body measurements',
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
                'WORKOUT WEIGHT',
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
                'For logging lifts, sets, exercise weights',
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
                child: Text('Accent Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColorsLight.textPrimary)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Choose an accent color for buttons and highlights', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
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
