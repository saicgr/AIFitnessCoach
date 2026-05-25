part of 'editable_fitness_card.dart';

/// Display-only title-case: backend may persist enums lowercase (e.g.
/// 'advanced'), but the profile card should read 'Advanced'. Never mutate the
/// source value — apply at the Text widget boundary only.
String _displayTitleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

/// Methods extracted from EditableFitnessCardState
extension _EditableFitnessCardStateExt on EditableFitnessCardState {

  /// Compact 2x4 grid view for fitness settings
  Widget _buildGridView({
    required GymProfile? activeGymProfile,
    required bool isDark,
    required Color elevated,
    required Color textMuted,
  }) {
    final l10n = AppLocalizations.of(context);
    final gymName = activeGymProfile?.name ?? l10n.editableFitnessCardNoGym;
    final gymColor = activeGymProfile?.profileColor ?? Colors.grey;
    final gymIcon = _getGymIconData(activeGymProfile?.icon ?? 'fitness_center');
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Format workout days for compact display
    final daysDisplay = _selectedDays.isEmpty
        ? l10n.editableFitnessCardNotSet
        : _selectedDays.map((d) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d]).join(',');

    final injuriesDisplay = _selectedInjuries.isEmpty
        ? l10n.editableFitnessCardNone
        : _selectedInjuries.length == 1
            ? _selectedInjuries.first
            : l10n.editableFitnessCardNAreas(_selectedInjuries.length);

    return GridView.count(
      // 4 columns × 2 rows = 8 tiles. Warmup + Stretch were merged into a
      // single "Prep" tile showing both durations. Tapping it opens a sheet
      // with both sliders. Edit mode (inline list) keeps them as separate
      // rows since each is adjusted independently.
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.88,
      children: [
        _FitnessTile(
          icon: gymIcon,
          iconColor: gymColor,
          label: l10n.editableFitnessCardGym,
          value: gymName,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () {
            HapticFeedback.lightImpact();
            showGlassSheet(
              context: context,
              builder: (context) => const ManageGymProfilesSheet(),
            );
          },
          showChevron: true,
        ),
        _FitnessTile(
          icon: Icons.flag,
          iconColor: AppColors.green,
          label: l10n.editableFitnessCardGoal,
          value: _displayTitleCase(_selectedGoal),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardFitnessGoal,
            icon: Icons.flag,
            iconColor: AppColors.green,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildGoalSelector(AppColors.green, cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.signal_cellular_alt,
          iconColor: AppColors.info,
          label: l10n.editableFitnessCardLevel,
          value: _displayTitleCase(_selectedLevel),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardFitnessLevel,
            icon: Icons.signal_cellular_alt,
            iconColor: AppColors.info,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildLevelSelector(AppColors.info, cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.timer_outlined,
          iconColor: AppColors.cyan,
          label: l10n.editableFitnessCardDuration,
          value: _formatDurationDisplay(),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardWorkoutDuration,
            icon: Icons.timer_outlined,
            iconColor: AppColors.cyan,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildDurationRangeSelector(AppColors.cyan),
          ),
        ),
        _FitnessTile(
          icon: Icons.self_improvement_outlined,
          iconColor: AppColors.orange,
          label: l10n.editableFitnessCardPrep,
          value: AppLocalizations.of(context)!.editableFitnessCardPartEditableFitnessCardStateExtMin(_selectedWarmupDuration, _selectedStretchDuration),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardWarmupStretch,
            icon: Icons.self_improvement_outlined,
            iconColor: AppColors.orange,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.whatshot_outlined,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Text(
                      l10n.editableFitnessCardWarmup,
                      style: TextStyle(
                        fontSize: 13, color: textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWarmupSelector(AppColors.orange, cardBorder, textSecondary),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.self_improvement_outlined,
                        size: 16, color: AppColors.purple),
                    const SizedBox(width: 6),
                    Text(
                      l10n.editableFitnessCardStretch,
                      style: TextStyle(
                        fontSize: 13, color: textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStretchSelector(AppColors.purple, cardBorder, textSecondary),
              ],
            ),
          ),
        ),
        _FitnessTile(
          icon: Icons.calendar_today,
          iconColor: AppColors.yellow,
          label: l10n.editableFitnessCardDays,
          value: daysDisplay,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardWorkoutDays,
            icon: Icons.calendar_today,
            iconColor: AppColors.yellow,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildDaysSelector(AppColors.yellow, cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.healing,
          iconColor: AppColors.error,
          label: l10n.editableFitnessCardInjuries,
          value: injuriesDisplay,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardActiveInjuries,
            icon: Icons.healing,
            iconColor: AppColors.error,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildInjurySelector(cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.directions_walk,
          iconColor: AppColors.green,
          label: l10n.editableFitnessCardSteps,
          value: _shortStepLabel(_selectedStepGoal),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: l10n.editableFitnessCardDailyStepsGoal,
            icon: Icons.directions_walk,
            iconColor: AppColors.green,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () =>
                _buildStepGoalSelector(AppColors.green, cardBorder, textSecondary),
          ),
        ),
      ],
    );
  }

}
