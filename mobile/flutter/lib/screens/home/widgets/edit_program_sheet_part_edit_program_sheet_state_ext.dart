part of 'edit_program_sheet.dart';

/// Methods extracted from _EditProgramSheetState
extension __EditProgramSheetStateExt on _EditProgramSheetState {

  /// Human label for the currently-selected Vibe / training split.
  String _vibeLabel() {
    if (_selectedProgramId == null || _selectedProgramId == 'ai_decide') {
      return 'AI Decides';
    }
    if (_selectedProgramId == 'custom') {
      return 'Custom';
    }
    return defaultTrainingPrograms
        .firstWhere(
          (p) => p.id == _selectedProgramId,
          orElse: () => defaultTrainingPrograms.first,
        )
        .name;
  }

  /// B1: compact "Vibe" row — label + current selection + "View all ›". The
  /// full AI-Decides + presets grid (formerly inline, a long scroll) now lives
  /// in a separate bottom sheet opened via [_showVibeSheet].
  Widget _buildTrainingProgramStep(SheetColors colors) {
    final isAi =
        _selectedProgramId == null || _selectedProgramId == 'ai_decide';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showVibeSheet(colors),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isAi ? Icons.auto_awesome : Icons.bolt,
              size: 20,
              color: isAi ? colors.cyan : colors.purple,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _vibeLabel(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'View all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.cyan,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.cyan),
          ],
        ),
      ),
    );
  }

  /// B1: the full Vibe picker — AI Decides card + the named-split grid — moved
  /// out of the Schedule tab into its own sheet. Selecting a split (or custom)
  /// updates state and refreshes both the sheet and the compact row.
  Future<void> _showVibeSheet(SheetColors colors) async {
    await showGlassSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              physics: const BouncingScrollPhysics(),
              child: _buildVibeGrid(colors, setSheetState),
            ),
          ),
        ),
      ),
    );
  }

  /// AI Decides card + the named-split grid. [refreshSheet] re-renders the host
  /// sheet so a tap reflects immediately (in addition to the editor's setState).
  Widget _buildVibeGrid(SheetColors colors, void Function(VoidCallback) refreshSheet) {
    final aiDecideSelected =
        _selectedProgramId == null || _selectedProgramId == 'ai_decide';

    void select(String? id) {
      setState(() => _selectedProgramId = id);
      refreshSheet(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Vibe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.editProgramSheetChooseATrainingSplit,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),

        // ── "AI Decides" — the coach chooses the split ──
        GestureDetector(
          onTap: () => select('ai_decide'),
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
                  child: Icon(Icons.auto_awesome, color: colors.cyan, size: 22),
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

            String displayDescription = program.description;
            if (isCustom && hasCustomDescription) {
              displayDescription = _customProgramDescription;
            }

            return GestureDetector(
              onTap: () {
                if (isCustom) {
                  _showCustomProgramSheet(colors);
                  // Reflect any custom-description change when the inner sheet
                  // returns (the editor's setState already fired in onSave).
                  refreshSheet(() {});
                } else {
                  // Tapping a selected preset reverts to "AI Decides".
                  select(isSelected ? 'ai_decide' : program.id);
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
    // 3-letter labels — 'M/T/W/T/F/S/S' was ambiguous (two T's, two S's).
    const weekdaySingle = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              weekdaySingle[d],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: d == editingDay
                                    ? Colors.white
                                    : colors.textPrimary,
                              ),
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

          Row(
            children: [
              Expanded(
                child: Text(
                  weekdayFull[editingDay],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // ── B5: Copy this day's settings to other training days ──
              // Only useful when there's at least one OTHER training day and
              // this day has an explicit override to copy.
              if (trainingDays.length > 1 && override != null)
                TextButton.icon(
                  onPressed: () =>
                      _showCopyDaySheet(colors, editingDay, trainingDays),
                  icon: Icon(Icons.content_copy, size: 16, color: accent),
                  label: Text(
                    'Copy to…',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
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

  /// B5: copy [sourceDay]'s focus/duration/intensity/gym override to one or more
  /// other training days. Shows a small multi-select chooser of the OTHER
  /// training days; on confirm, the source override is cloned to each pick.
  Future<void> _showCopyDaySheet(
    SheetColors colors,
    int sourceDay,
    List<int> trainingDays,
  ) async {
    const weekdayFull = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final source = _dayOverrides[sourceDay];
    if (source == null) return;

    final targets = trainingDays.where((d) => d != sourceDay).toList();
    final selected = <int>{};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final apply = await showGlassSheet<bool>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copy ${weekdayFull[sourceDay]} to…',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applies this day\'s focus, duration, intensity & gym to the days you pick.',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in targets)
                      PerDayChip(
                        label: weekdayFull[d],
                        icon: selected.contains(d)
                            ? Icons.check_rounded
                            : null,
                        selected: selected.contains(d),
                        accent: accent,
                        textPrimary: colors.textPrimary,
                        textMuted: colors.textMuted,
                        onTap: () => setSheetState(() {
                          if (!selected.add(d)) selected.remove(d);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selected.isEmpty
                          ? 'Pick at least one day'
                          : 'Copy to ${selected.length} day${selected.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (apply == true && selected.isNotEmpty && mounted) {
      setState(() {
        for (final d in selected) {
          _dayOverrides[d] = source.copyWith();
        }
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied ${weekdayFull[sourceDay]} to ${selected.length} day${selected.length == 1 ? '' : 's'}',
          ),
        ),
      );
    }
  }

  // ── Workout Type step (Strength / Cardio / Mixed) ──────────────────────

  /// B2: compact segmented chip row (Strength / Cardio / Mixed) — replaces the
  /// three big stacked cards to cut Schedule-tab scroll. The selected option's
  /// one-line description shows beneath the row.
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

    final selectedDesc = options
        .firstWhere((o) => o.value == _selectedWorkoutType,
            orElse: () => options.last)
        .desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.cardBorder.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              for (final opt in options)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedWorkoutType = opt.value);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedWorkoutType == opt.value
                            ? colors.purple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: _selectedWorkoutType == opt.value
                                ? Colors.white
                                : colors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedWorkoutType == opt.value
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedDesc,
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
      ],
    );
  }


  Widget _buildHealthStep(SheetColors colors) {
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
          ),
          // B5: the inline Health-tab Summary was removed to cut scroll — the
          // full summary now lives in the Save → confirm sheet
          // (_buildProgramSummaryCard), shown right before Apply now / Later.
        ],
      ),
    );
  }

  /// The per-day-aware program Summary card (B5). Lifted out of the Health tab
  /// so it can be shown in the Save → confirm sheet. Pure render off current
  /// state — safe to call from either the sheet or anywhere a recap is wanted.
  Widget _buildProgramSummaryCard(SheetColors colors) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
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
          if (_selectedProgramId != null)
            _buildSummaryRow(
              colors,
              AppLocalizations.of(context)!.editProgramSheetProgram,
              _selectedProgramId == 'custom' &&
                      _customProgramDescription.isNotEmpty
                  ? AppLocalizations.of(context)!
                      .editProgramSheetCustomValue(_customProgramDescription)
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
          if (_selectedInjuries.isNotEmpty)
            _buildSummaryRow(
              colors,
              AppLocalizations.of(context)!.editProgramSheetInjuries,
              _selectedInjuries.join(', '),
            ),

          // ── B4: Per-day breakdown ──
          // Each training day → its override ("Tue · Upper · 90m · Hell") or
          // "AI decides" when left on AI.
          if (_selectedDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Per-day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            for (final line in _perDaySummaryLines())
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// B5: Save → confirm sheet. Shows the program Summary and the Apply-now /
  /// Later decision. Returns true (Apply now), false (Later / Save), or null
  /// (dismissed). When nothing program-affecting changed there's nothing to
  /// regenerate, so it collapses to a single "Save" primary action.
  Future<bool?> _showApplyConfirmSheet(
    SheetColors colors,
    _ProgramSavePayload payload,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final willRegenerate = payload.didChange;

    return showGlassSheet<bool>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  willRegenerate ? 'Apply these changes?' : 'Save program?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  willRegenerate
                      ? 'Review your program below. Apply now rebuilds today & tomorrow right away — or save it for later and it\'ll kick in with your next workouts.'
                      : 'Review your program below, then save.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgramSummaryCard(colors),
                const SizedBox(height: 20),
                if (willRegenerate) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text(
                        'Apply now',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save for later',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Later = applies to your next generated workouts',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A4: the engaging multi-step Apply progress sheet. Non-dismissible. Driven
  /// by [controller]; each step maps honestly to a real operation
  /// (persist → invalidate → regenerate → finish). Resolves (and pops itself)
  /// when the controller signals complete or error.
  Future<void> _showApplyProgressSheet(_ApplyProgressController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final colors = context.sheetColors;

    return showGlassSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => GlassSheet(
        child: _ApplyProgressView(
          controller: controller,
          accent: accent,
          colors: colors,
        ),
      ),
    );
  }

  /// One human-readable line per training day for the summary's Per-day block.
  /// e.g. "Tue · Upper · 90m · Hell" — or "Tue · AI decides" for no override.
  List<String> _perDaySummaryLines() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final focusLabels = {for (final o in kFocusOptions) o.value: o.label};
    final intensityLabels = {
      for (final o in kIntensityOptions) o.value: o.label,
    };
    final lines = <String>[];
    for (final d in _selectedDays.toList()..sort()) {
      final ov = _dayOverrides[d];
      if (ov == null) {
        lines.add('${dayNames[d]} · AI decides');
        continue;
      }
      final parts = <String>[
        focusLabels[ov.focus] ?? ov.focus,
        if (ov.durationMin != null) '${ov.durationMin}m',
        if (ov.intensity != null)
          (intensityLabels[ov.intensity] ?? ov.intensity!),
      ];
      lines.add('${dayNames[d]} · ${parts.join(' · ')}');
    }
    return lines;
  }
}

/// Immutable snapshot of everything a program save needs, captured before the
/// editor sheet is popped so the background save can run dispose-proof off the
/// root container (the sheet's `ref` is invalid the moment it pops).
class _ProgramSavePayload {
  const _ProgramSavePayload({
    required this.userId,
    required this.didChange,
    required this.activeProfile,
    required this.sortedDays,
    required this.selectedDayNames,
    required this.difficulty,
    required this.durationMin,
    required this.durationMax,
    required this.injuries,
    required this.equipment,
    required this.workoutTypeSplit,
    required this.dumbbellCount,
    required this.kettlebellCount,
    required this.customProgramDescription,
    required this.mergedPrefs,
    required this.workoutTypeChanged,
    required this.newWorkoutType,
  });

  final String userId;
  final bool didChange;
  final GymProfile? activeProfile;
  final List<int> sortedDays;
  final List<String> selectedDayNames;
  final String difficulty;
  final int durationMin;
  final int durationMax;
  final List<String> injuries;
  final List<String>? equipment;
  final String workoutTypeSplit;
  final int? dumbbellCount;
  final int? kettlebellCount;
  final String? customProgramDescription;
  final Map<String, dynamic> mergedPrefs;
  final bool workoutTypeChanged;
  final WorkoutType newWorkoutType;
}

/// Drives the A4 Apply progress UI. The state class advances [setStep] as each
/// real operation runs, then calls [complete] or [fail]; the progress view
/// listens and renders the matching narrative, finally popping itself.
class _ApplyProgressController extends ChangeNotifier {
  int _step = 0;
  bool _done = false;
  bool _error = false;

  int get step => _step;
  bool get isDone => _done;
  bool get isError => _error;

  void setStep(int s) {
    _step = s;
    notifyListeners();
  }

  void complete() {
    _done = true;
    notifyListeners();
  }

  void fail() {
    _error = true;
    notifyListeners();
  }
}

/// A4: the visible multi-step Apply progress. Each step text maps 1:1 to a real
/// operation (persist → invalidate → regenerate → finish) — no fabricated
/// completion. On done it shows a brief success tick, then pops; on error it
/// pops immediately so the caller can surface the failure toast.
class _ApplyProgressView extends StatefulWidget {
  const _ApplyProgressView({
    required this.controller,
    required this.accent,
    required this.colors,
  });

  final _ApplyProgressController controller;
  final Color accent;
  final SheetColors colors;

  @override
  State<_ApplyProgressView> createState() => _ApplyProgressViewState();
}

class _ApplyProgressViewState extends State<_ApplyProgressView> {
  static const _steps = <({IconData icon, String label})>[
    (icon: Icons.tune_rounded, label: 'Reading your preferences…'),
    (icon: Icons.event_repeat_rounded, label: 'Updating your schedule…'),
    (icon: Icons.fitness_center_rounded, label: 'Building your workouts…'),
    (icon: Icons.auto_awesome_rounded, label: 'Finishing up…'),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    if (widget.controller.isError) {
      // Pop straight away on failure — caller shows the error toast.
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.controller.isDone) {
      setState(() {});
      // Hold on the success tick briefly, then close.
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final colors = widget.colors;
    final done = c.isDone;
    final activeStep = done ? _steps.length : c.step;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (done)
                  Icon(Icons.check_circle_rounded,
                      color: widget.accent, size: 26)
                else
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: widget.accent,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    done ? 'Your program is ready' : 'Applying your program',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < _steps.length; i++) ...[
              _ProgressStepRow(
                icon: _steps[i].icon,
                label: _steps[i].label,
                state: i < activeStep
                    ? _StepState.complete
                    : (i == activeStep
                        ? _StepState.active
                        : _StepState.pending),
                accent: widget.accent,
                colors: colors,
              ),
              if (i != _steps.length - 1) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StepState { pending, active, complete }

class _ProgressStepRow extends StatelessWidget {
  const _ProgressStepRow({
    required this.icon,
    required this.label,
    required this.state,
    required this.accent,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final _StepState state;
  final Color accent;
  final SheetColors colors;

  @override
  Widget build(BuildContext context) {
    final isComplete = state == _StepState.complete;
    final isActive = state == _StepState.active;
    final leadColor = isComplete || isActive ? accent : colors.textMuted;
    final textColor = isActive
        ? colors.textPrimary
        : (isComplete ? colors.textSecondary : colors.textMuted);

    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: isActive
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: accent,
                  ),
                )
              : Icon(
                  isComplete ? Icons.check_circle_rounded : icon,
                  size: 20,
                  color: leadColor.withOpacity(isComplete ? 1 : 0.5),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
