part of 'editable_fitness_card.dart';

/// Methods extracted from EditableFitnessCardState
extension _EditableFitnessCardStateExt on EditableFitnessCardState {

  /// Compact 2x4 grid view for fitness settings
  Widget _buildGridView({
    required GymProfile? activeGymProfile,
    required bool isDark,
    required Color elevated,
    required Color textMuted,
  }) {
    final gymName = activeGymProfile?.name ?? 'No gym';
    final gymColor = activeGymProfile?.profileColor ?? Colors.grey;
    final gymIcon = _getGymIconData(activeGymProfile?.icon ?? 'fitness_center');
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Format workout days for compact display
    final daysDisplay = _selectedDays.isEmpty
        ? 'Not set'
        : _selectedDays.map((d) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d]).join(',');

    final injuriesDisplay = _selectedInjuries.isEmpty
        ? 'None'
        : _selectedInjuries.length == 1
            ? _selectedInjuries.first
            : '${_selectedInjuries.length} areas';

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: [
        _FitnessTile(
          icon: gymIcon,
          iconColor: gymColor,
          label: 'Gym',
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
          label: 'Goal',
          value: _selectedGoal,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Fitness Goal',
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
          label: 'Level',
          value: _selectedLevel,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Fitness Level',
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
          label: 'Duration',
          value: _formatDurationDisplay(),
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Workout Duration',
            icon: Icons.timer_outlined,
            iconColor: AppColors.cyan,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildDurationRangeSelector(AppColors.cyan),
          ),
        ),
        _FitnessTile(
          icon: Icons.whatshot_outlined,
          iconColor: AppColors.orange,
          label: 'Warmup',
          value: '$_selectedWarmupDuration min',
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Warmup Duration',
            icon: Icons.whatshot_outlined,
            iconColor: AppColors.orange,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildWarmupSelector(AppColors.orange, cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.self_improvement_outlined,
          iconColor: AppColors.purple,
          label: 'Stretch',
          value: '$_selectedStretchDuration min',
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Stretch Duration',
            icon: Icons.self_improvement_outlined,
            iconColor: AppColors.purple,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildStretchSelector(AppColors.purple, cardBorder, textSecondary),
          ),
        ),
        _FitnessTile(
          icon: Icons.calendar_today,
          iconColor: AppColors.yellow,
          label: 'Days',
          value: daysDisplay,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Workout Days',
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
          label: 'Injuries',
          value: injuriesDisplay,
          backgroundColor: elevated,
          textMutedColor: textMuted,
          onTap: () => _showFieldEditor(
            title: 'Active Injuries',
            icon: Icons.healing,
            iconColor: AppColors.error,
            isDark: isDark,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
            builder: () => _buildInjurySelector(cardBorder, textSecondary),
          ),
        ),
      ],
    );
  }

}
