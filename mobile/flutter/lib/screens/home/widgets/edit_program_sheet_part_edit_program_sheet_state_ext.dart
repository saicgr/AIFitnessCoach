part of 'edit_program_sheet.dart';

/// Methods extracted from _EditProgramSheetState
extension __EditProgramSheetStateExt on _EditProgramSheetState {

  Widget _buildTrainingProgramStep(SheetColors colors) {
    final aiDecideSelected =
        _selectedProgramId == null || _selectedProgramId == 'ai_decide';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info text
          Text(
            AppLocalizations.of(context)!.editProgramSheetChooseATrainingSplit,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          // ── "AI Decides" — the coach chooses the split ──
          // First-class card, visually distinct from the named presets so the
          // user understands "let the coach pick" vs "use this template".
          GestureDetector(
            onTap: _isUpdating
                ? null
                : () => setState(() => _selectedProgramId = 'ai_decide'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: aiDecideSelected
                    ? colors.cyan.withOpacity(0.15)
                    : colors.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: aiDecideSelected
                      ? colors.cyan
                      : colors.cardBorder.withOpacity(0.3),
                  width: aiDecideSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.auto_awesome, color: colors.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Decides',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: aiDecideSelected
                                ? colors.cyan
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Let your coach choose the best split for your days & goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (aiDecideSelected)
                    Icon(Icons.check_circle, color: colors.cyan, size: 22),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── "AI-Powered" template section ──
          // Distinct from "AI Decides": these are named, AI-built templates the
          // user explicitly opts into.
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: colors.purple),
              const SizedBox(width: 6),
              Text(
                'AI-Powered splits',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                          // Tapping a selected preset reverts to "AI Decides"
                          // (the explicit let-the-coach-choose default).
                          setState(() => _selectedProgramId =
                              isSelected ? 'ai_decide' : program.id);
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

  // ── Per-day overrides step ─────────────────────────────────────────────
  // The override mutation helpers (_setOverrideFocus / _clearOverride / …)
  // live in the State class file where setState is valid.

  Widget _buildPerDayStep(SheetColors colors) {
    const weekdayFull = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const weekdaySingle = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final trainingDays = _selectedDays.toList()..sort();
    // Keep the editing pointer valid.
    final editingDay = (_editingDay != null &&
            trainingDays.contains(_editingDay))
        ? _editingDay!
        : (trainingDays.isNotEmpty ? trainingDays.first : -1);

    final gymProfiles =
        ref.watch(gymProfilesProvider).valueOrNull ?? const <GymProfile>[];

    if (trainingDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Pick training days first to customize each day.',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final override = _dayOverrides[editingDay];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Customize each training day — or leave it on AI decide.',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Day picker — only training days are selectable.
          Row(
            children: [
              for (final d in trainingDays) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _editingDay = d);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            d == editingDay ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: d == editingDay
                              ? accent
                              : colors.textMuted.withOpacity(0.35),
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            weekdaySingle[d],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: d == editingDay
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                          ),
                          if (_dayOverrides.containsKey(d) &&
                              d != editingDay)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (d != trainingDays.last) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 16),

          Text(
            weekdayFull[editingDay],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Shared control stack (focus / duration / intensity / gym).
          PerDayControls(
            focus: override?.focus,
            durationMin: override?.durationMin,
            intensity: override?.intensity,
            gymProfileId: override?.gymProfileId,
            accent: accent,
            textPrimary: colors.textPrimary,
            textMuted: colors.textMuted,
            gymProfiles: gymProfiles,
            onFocusChanged: (f) => _setOverrideFocus(editingDay, f),
            onAiDecide: () => _clearOverride(editingDay),
            onDurationChanged: (d) => _setOverrideDuration(editingDay, d),
            onIntensityChanged: (i) => _setOverrideIntensity(editingDay, i),
            onGymChanged: (g) => _setOverrideGym(editingDay, g),
          ),
        ],
      ),
    );
  }

  // ── Workout Type step (Strength / Cardio / Mixed) ──────────────────────

  Widget _buildWorkoutTypeStep(SheetColors colors) {
    const options = <({String value, String label, String desc, IconData icon})>[
      (
        value: 'strength',
        label: 'Strength',
        desc: 'Build muscle & lift heavier',
        icon: Icons.fitness_center_rounded,
      ),
      (
        value: 'cardio',
        label: 'Cardio',
        desc: 'Conditioning & endurance',
        icon: Icons.favorite_rounded,
      ),
      (
        value: 'mixed',
        label: 'Mixed',
        desc: 'A balance of both',
        icon: Icons.shuffle_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How do you want to train?',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final opt in options) ...[
            GestureDetector(
              onTap: _isUpdating
                  ? null
                  : () => setState(() => _selectedWorkoutType = opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _selectedWorkoutType == opt.value
                      ? colors.purple.withOpacity(0.15)
                      : colors.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedWorkoutType == opt.value
                        ? colors.purple
                        : colors.cardBorder.withOpacity(0.3),
                    width: _selectedWorkoutType == opt.value ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(opt.icon, color: colors.purple, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _selectedWorkoutType == opt.value
                                  ? colors.purple
                                  : colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedWorkoutType == opt.value)
                      Icon(Icons.check_circle,
                          color: colors.purple, size: 22),
                  ],
                ),
              ),
            ),
          ],
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
                    AppLocalizations.of(context)!.editProgramSheetThisStepIsOptional,
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
                  AppLocalizations.of(context)!.editProgramSheetSummary,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  colors,
                  AppLocalizations.of(context)!.editProgramSheetDays,
                  _selectedDays.map((i) => dayNames[i]).join(', '),
                ),
                _buildSummaryRow(
                  colors,
                  AppLocalizations.of(context)!.editProgramSheetDifficulty,
                  _selectedDifficulty[0].toUpperCase() +
                      _selectedDifficulty.substring(1),
                ),
                _buildSummaryRow(
                  colors,
                  AppLocalizations.of(context)!.editProgramSheetDuration,
                  _selectedDurationMin.round() == _selectedDurationMax.round()
                      ? '${_selectedDurationMin.round()} minutes'
                      : '${_selectedDurationMin.round()}-${_selectedDurationMax.round()} minutes',
                ),
                // Program duration removed from summary - using automatic regeneration
                if (_selectedProgramId != null)
                  _buildSummaryRow(
                    colors,
                    AppLocalizations.of(context)!.editProgramSheetProgram,
                    _selectedProgramId == 'custom' && _customProgramDescription.isNotEmpty
                        ? AppLocalizations.of(context)!.editProgramSheetCustomValue(_customProgramDescription)
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
                    AppLocalizations.of(context)!.editProgramSheetEquipmentLabel,
                    _selectedEquipment.join(', '),
                  ),
                if (_selectedFocusAreas.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    AppLocalizations.of(context)!.editProgramSheetFocus,
                    _selectedFocusAreas.join(', '),
                  ),
                if (_selectedInjuries.isNotEmpty)
                  _buildSummaryRow(
                    colors,
                    AppLocalizations.of(context)!.editProgramSheetInjuries,
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
