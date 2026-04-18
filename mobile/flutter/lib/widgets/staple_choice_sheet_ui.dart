part of 'staple_choice_sheet.dart';

/// UI builder methods extracted from _StapleChoiceSheetState
extension _StapleChoiceSheetStateUI on _StapleChoiceSheetState {

  Widget _buildProfileChip({
    required String label,
    required bool isSelected,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }


  Widget _buildCardioSection(
    Color textPrimary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    final type = _cardioType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cardio Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCardioField(
              label: 'Duration',
              controller: _durationController,
              suffix: 'min',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            if (type == 'treadmill' || type == 'walking' || type == 'running') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Speed',
                controller: _speedController,
                suffix: 'mph',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Incline',
                controller: _inclineController,
                suffix: '%',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Distance',
                controller: _distanceController,
                suffix: 'mi',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'swimming') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Distance',
                controller: _distanceController,
                suffix: 'mi',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'bike') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'RPM',
                controller: _rpmController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Resistance',
                controller: _resistanceController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'rower') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Stroke Rate',
                controller: _strokeRateController,
                suffix: 'spm',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
            if (type == 'elliptical') ...[
              const SizedBox(height: 8),
              _buildCardioField(
                label: 'Resistance',
                controller: _resistanceController,
                suffix: '',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildCardioField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixText: suffix,
              suffixStyle: TextStyle(fontSize: 12, color: textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: textMuted.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: textMuted.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.cyan),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? textPrimary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWorkoutExerciseList(Color textPrimary, Color textMuted) {
    final todayWorkout = ref.watch(todayWorkoutProvider);
    return todayWorkout.when(
      data: (response) {
        final workout = response?.todayWorkout ?? response?.nextWorkout;
        if (workout == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No workout available',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          );
        }
        final exercises = workout.exercises;
        if (exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No exercises in workout',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          );
        }
        return Column(
          children: exercises.map((ex) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fitness_center, size: 18, color: textMuted),
              title: Text(
                ex.name,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              subtitle: ex.muscleGroup != null
                  ? Text(
                      ex.muscleGroup!,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    )
                  : null,
              dense: true,
              onTap: () {
                HapticService.light();
                Navigator.pop(
                  context,
                  _makeResult(addToday: true, swapExerciseId: ex.name),
                );
              },
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Could not load workout',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      ),
    );
  }

}
