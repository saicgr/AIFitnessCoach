part of 'quick_workout_sheet.dart';

/// Methods extracted from _QuickWorkoutSheetState
extension __QuickWorkoutSheetStateExt2 on _QuickWorkoutSheetState {

  void _showDiscoverSheet() {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                children: [
                  Icon(Icons.auto_awesome, color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l.quickWorkoutDiscoverWorkouts,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.quickWorkoutDiscoverSubtitle,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              if (_discoverPool.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l.quickWorkoutNoSuggestions,
                    style: TextStyle(color: textSecondary),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _discoverPool.map((preset) {
                    final presetColor = preset.color;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateFromPreset(preset);
                      },
                      child: Container(
                        width: (MediaQuery.of(ctx).size.width - 56) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: presetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: presetColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(preset.icon, size: 20, color: presetColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    preset.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }


  Future<void> _generateQuickWorkout() async {
    HapticService.medium();

    ref.read(posthogServiceProvider).capture(
      eventName: 'quick_workout_generated',
      properties: {
        'duration': _selectedDuration,
        'focus': _selectedFocus ?? '',
        'difficulty': _selectedDifficulty ?? '',
      },
    );

    // Check for conflict with existing workout on today's date
    final conflictResult = await _checkConflict();
    if (conflictResult == _ConflictAction.cancelled) return;

    // If user chose "Change Date", use the override date
    DateTime? scheduledDateOverride;
    if (conflictResult == _ConflictAction.changeDate) {
      final pickedDate = await _pickAlternateDate();
      if (pickedDate == null || !mounted) return;
      scheduledDateOverride = pickedDate;
    }

    // Glass loading overlay covers the multi-step flow (delete existing →
    // generate → invalidate providers → pop) so the user sees a continuous
    // affordance instead of the in-button spinner alone, which leaves a
    // 1-2s "stuck" gap during the DELETE that runs OUTSIDE quickWorkoutProvider.
    final loadingOverlay = mounted
        ? showGlassLoadingOverlay(context, message: 'Generating workout…')
        : null;

    try {
      // If user chose "Replace", delete the existing workout first
      if (conflictResult == _ConflictAction.replace && _conflictWorkoutId != null) {
        try {
          final apiClient = ref.read(apiClientProvider);
          await apiClient.delete(
            '${ApiConstants.workouts}/$_conflictWorkoutId',
          );
        } catch (e) {
          debugPrint('[QuickWorkout] Failed to delete existing workout: $e');
          // Continue anyway — the new workout will still be created
        }
      }

      final workout = await ref.read(quickWorkoutProvider.notifier).generateQuickWorkout(
        duration: _selectedDuration,
        focus: _selectedFocus,
        difficulty: _selectedDifficulty,
        mood: _selectedMood,
        goal: _selectedGoal,
        useSupersets: _useSupersets,
        equipment: _selectedEquipment.isNotEmpty ? _selectedEquipment.toList() : null,
        injuries: _selectedInjuries.isNotEmpty ? _selectedInjuries.toList() : null,
        equipmentDetails: _equipmentDetails.isNotEmpty ? _equipmentDetails : null,
        scheduledDate: scheduledDateOverride,
      );

      if (workout != null && mounted) {
        // Auto-capture preset
        _autoCapturePreset();

        // AWAIT both refreshes before popping — the previous fire-and-forget
        // pattern returned to home with stale provider state, so the carousel
        // didn't show the new quick workout until the user switched tabs and
        // came back. invalidateAndRefresh() also clears the static dedup cache
        // so a Replace flow doesn't pull a still-cached deleted workout.
        await Future.wait([
          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh(),
          ref.read(workoutsProvider.notifier).silentRefresh(),
        ]);

        if (!mounted) return;
        Navigator.pop(context, workout);
      }
    } finally {
      loadingOverlay?.dismiss();
    }
  }


  /// Check if there's a workout conflict on today's date.
  /// Returns the action the user chose (or noConflict if no existing workout).
  Future<_ConflictAction> _checkConflict() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await apiClient.get(
        '${ApiConstants.workouts}/quick/conflict-check',
        queryParameters: {'date': dateStr},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['has_conflict'] == true && data['existing_workout'] != null) {
          final existing = data['existing_workout'] as Map<String, dynamic>;
          _conflictWorkoutId = existing['id'] as String?;
          final existingName = existing['name'] as String? ?? 'Workout';

          if (!mounted) return _ConflictAction.cancelled;
          return await _showConflictDialog(existingName);
        }
      }
    } catch (e) {
      debugPrint('[QuickWorkout] Conflict check failed: $e');
      // Graceful degradation: proceed without dialog
    }
    return _ConflictAction.noConflict;
  }


  /// Show the conflict resolution dialog.
  Future<_ConflictAction> _showConflictDialog(String existingWorkoutName) async {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<_ConflictAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.quickWorkoutConflictTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          l.quickWorkoutConflictBody(existingWorkoutName),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.changeDate),
            child: Text(l.quickWorkoutConflictChangeDate),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.addAnyway),
            child: Text(l.quickWorkoutConflictAddAnyway),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ConflictAction.replace),
            child: Text(l.quickWorkoutConflictReplace),
          ),
        ],
      ),
    );
    return result ?? _ConflictAction.cancelled;
  }


  /// Show a date picker for the "Change Date" option.
  Future<DateTime?> _pickAlternateDate() async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Schedule quick workout for...',
    );
  }


  Future<void> _autoCapturePreset() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      if (user == null) return;

      await QuickWorkoutPresetService.autoCapture(
        db,
        user.id,
        duration: _selectedDuration,
        focus: _selectedFocus,
        difficulty: _selectedDifficulty,
        goal: _selectedGoal,
        mood: _selectedMood,
        useSupersets: _useSupersets,
        equipment: _selectedEquipment.toList(),
        injuries: _selectedInjuries.toList(),
        equipmentDetails: _equipmentDetails.isNotEmpty ? _equipmentDetails : null,
      );
    } catch (e) {
      debugPrint('[QuickPresets] Auto-capture failed: $e');
    }
  }

}
