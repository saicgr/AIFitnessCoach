part of 'edit_program_sheet.dart';

/// Methods extracted from _EditProgramSheetState
extension __EditProgramSheetStateExt on _EditProgramSheetState {

  Widget _buildTrainingProgramStep(SheetColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info text
          Text(
            'Choose a training split that fits your schedule and goals',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Training Programs Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: defaultTrainingPrograms.length,
            itemBuilder: (context, index) {
              final program = defaultTrainingPrograms[index];
              final isSelected = _selectedProgramId == program.id;
              final isCustom = program.id == 'custom';
              final hasCustomDescription = _customProgramDescription.isNotEmpty;

              // For custom, show the description if set
              String displayDescription = program.description;
              if (isCustom && hasCustomDescription) {
                displayDescription = _customProgramDescription;
              }

              return GestureDetector(
                onTap: _isUpdating
                    ? null
                    : () {
                        if (isCustom) {
                          _showCustomProgramSheet(colors);
                        } else {
                          setState(() => _selectedProgramId =
                              isSelected ? null : program.id);
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.purple.withOpacity(0.15)
                        : colors.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colors.purple
                          : colors.cardBorder.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            program.icon,
                            size: 20,
                            color: isSelected
                                ? colors.purple
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              program.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.purple
                                    : colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          displayDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: isCustom && hasCustomDescription && isSelected
                                ? colors.purple.withOpacity(0.8)
                                : colors.textMuted,
                            height: 1.3,
                            fontStyle: isCustom && hasCustomDescription
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        program.daysPerWeek,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? colors.purple
                              : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildHealthStep(SheetColors colors) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This step is optional. You can skip it if you have no injuries to report.',
                    style: TextStyle(fontSize: 13, color: colors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InjuriesSelector(
            selectedInjuries: _selectedInjuries,
            onSelectionChanged: (injuries) =>
                setState(() => _selectedInjuries
                  ..clear()
                  ..addAll(injuries)),
            customInjury: _customInjury,
            showCustomInput: _showInjuryInput,
            onToggleCustomInput: () =>
                setState(() => _showInjuryInput = !_showInjuryInput),
            onCustomInjurySaved: (value) {
              setState(() {
                _customInjury = value;
                if (value.isNotEmpty) {
                  _selectedInjuries.add(value);
                }
                _showInjuryInput = false;
              });
            },
            customInputController: _injuryController,
            disabled: _isUpdating,
          ),
          const SizedBox(height: 32),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.glassSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  colors,
                  'Days',
                  _selectedDays.map((i) => dayNames[i]).join(', '),
                ),
                _buildSummaryRow(
                  colors,
                  'Difficulty',
                  _selectedDifficulty[0].toUpperCase() +
                      _selectedDifficulty.substring(1),
                ),
                _buildSummaryRow(
                  colors,
                  'Duration',
                  _selectedDurationMin.round() == _selectedDurationMax.round()
                      ? '${_selectedDurationMin.round()} minutes'
                      : '${_selectedDurationMin.round()}-${_selectedDurationMax.round()} minutes',
                ),
                // Program duration removed from summary - using automatic regeneration
                if (_selectedProgramId != null)
                  _buildSummaryRow(
                    colors,
                    'Program',
                    _selectedProgramId == 'custom' && _customProgramDescription.isNotEmpty
                        ? 'Custom: $_customProgramDescription'
                        : defaultTrainingPrograms
                            .firstWhere(
                              (p) => p.id == _selectedProgramId,
                              orElse: () => defaultTrainingPrograms.first,
                            )
                            .name,
                  ),
                if (_selectedEquipment.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Equipment',
                    _selectedEquipment.join(', '),
                  ),
                if (_selectedFocusAreas.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Focus',
                    _selectedFocusAreas.join(', '),
                  ),
                if (_selectedInjuries.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    'Injuries',
                    _selectedInjuries.join(', '),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
