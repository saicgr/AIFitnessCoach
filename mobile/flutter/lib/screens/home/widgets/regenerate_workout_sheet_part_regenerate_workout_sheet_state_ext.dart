part of 'regenerate_workout_sheet.dart';

/// Methods extracted from _RegenerateWorkoutSheetState
extension __RegenerateWorkoutSheetStateExt on _RegenerateWorkoutSheetState {

  Future<void> _regenerate() async {
    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_regeneration_started',
      properties: {
        'difficulty': _selectedDifficulty,
      },
    );

    // Persist the user's current picks as last-used so the next regen open
    // pre-fills with the same values. Skip duration (continuous slider) and
    // injuries (health facts, not a "preference" to remember). Fire-and-
    // forget — don't block the regen call on prefs flush.
    final lastUsed = ref.read(lastUsedServiceProvider);
    // ignore: unawaited_futures
    lastUsed.set(_kRegenDifficultyKey, _selectedDifficulty);
    final typeToSave = _customWorkoutType.isNotEmpty
        ? _customWorkoutType
        : (_selectedWorkoutType ?? '');
    if (typeToSave.isNotEmpty) {
      // ignore: unawaited_futures
      lastUsed.set(_kRegenWorkoutTypeKey, typeToSave);
    }
    if (_selectedFocusAreas.isNotEmpty) {
      // ignore: unawaited_futures
      lastUsed.set(_kRegenFocusAreasKey, _selectedFocusAreas.join(','));
    }
    if (_selectedEquipment.isNotEmpty) {
      // ignore: unawaited_futures
      lastUsed.set(_kRegenEquipmentKey, _selectedEquipment.join(','));
    }

    _startElapsedTimer();
    setState(() {
      _isRegenerating = true;
      _currentStep = 0;
      _progressMessage = 'Starting...';
      _progressDetail = null;
      _lastBackendUpdateAt = DateTime.now();
    });

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      final allFocusAreas = _selectedFocusAreas.toList();
      if (_customFocusArea.isNotEmpty) {
        allFocusAreas.add(_customFocusArea);
      }

      final allInjuries = _selectedInjuries.toList();
      if (_customInjury.isNotEmpty) {
        allInjuries.add(_customInjury);
      }

      final allEquipment = _selectedEquipment.toList();
      if (_customEquipment.isNotEmpty) {
        allEquipment.add(_customEquipment);
      }

      final workoutType = _customWorkoutType.isNotEmpty
          ? _customWorkoutType
          : _selectedWorkoutType;

      final repo = ref.read(workoutRepositoryProvider);

      // "Do this today": hand the backend today's YYYY-MM-DD and flag force
      // so the preferred-day gate accepts the move. When the chip stays on
      // "Keep original", leave both null so the server preserves the date.
      String? newScheduledDate;
      bool forceNonPreferredDay = false;
      if (_moveToToday) {
        final now = DateTime.now();
        newScheduledDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayIdx = now.weekday - 1;
        forceNonPreferredDay =
            _userWorkoutDays.isNotEmpty && !_userWorkoutDays.contains(todayIdx);
      }

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: _selectedDifficulty,
        durationMinutesMin: _selectedDurationMin.round(),
        durationMinutesMax: _selectedDurationMax.round(),
        focusAreas: allFocusAreas,
        injuries: allInjuries,
        equipment: allEquipment.isNotEmpty ? allEquipment : null,
        workoutType: workoutType,
        dumbbellCount:
            _selectedEquipment.contains('Dumbbells') ? _dumbbellCount : null,
        kettlebellCount:
            _selectedEquipment.contains('Kettlebell') ? _kettlebellCount : null,
        newScheduledDate: newScheduledDate,
        forceNonPreferredDay: forceNonPreferredDay,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _stopElapsedTimer();
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to regenerate: ${progress.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (progress.isCompleted && progress.workout != null) {
          _stopElapsedTimer();
          // Update progress to show we're loading the review
          setState(() {
            _progressMessage = 'Loading review...';
            _progressDetail = 'Preparing your workout';
            _lastBackendUpdateAt = DateTime.now();
          });

          // Phase 1D: require preview_id to wire commit/discard. If the
          // backend didn't return one (e.g. pre-1C deploy), we surface an
          // error instead of silently falling through to a broken flow —
          // the no-silent-fallbacks principle from user feedback.
          final previewId = progress.previewId;
          if (previewId == null) {
            setState(() => _isRegenerating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Preview not supported by server. Please update the app or contact support.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          // Show review sheet for user to approve. The sheet commits on
          // Approve (returning a committed Workout) or discards on Back
          // (returning null).
          final approvedWorkout = await showWorkoutReviewSheet(
            context,
            ref,
            progress.workout!,
            previewId: previewId,
            originalWorkoutId: widget.workout.id!,
          );

          if (approvedWorkout != null && mounted) {
            // The commit has already materialized in the DB — original is
            // superseded by approvedWorkout. Ask user whether to keep the
            // old one visible alongside (un-supersede) or just replace.
            final shouldReplace = await _showReplaceOrAddDialog();
            if (!mounted) return;

            if (shouldReplace == null) {
              // Dialog dismissed AFTER commit. The supersede is already
              // persisted, so the effective state is Replace. Tell the user
              // explicitly — silent default would look like a bug (and per
              // feedback_no_silent_fallbacks.md).
              setState(() => _isRegenerating = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Defaulted to Replace — your previous workout was overwritten.'),
                  duration: Duration(seconds: 4),
                ),
              );
              TodayWorkoutNotifier.clearCache();
              ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
              ref.read(workoutsProvider.notifier).silentRefresh();
              Navigator.pop(context, approvedWorkout);
              return;
            }

            if (shouldReplace) {
              WorkoutsNotifier.replaceInCache(widget.workout.id!, approvedWorkout);
            } else {
              // Un-supersede old workout so both appear in carousel. If this
              // fails the user gets the silent Replace they didn't ask for —
              // surface it so they can retry instead of losing the original.
              try {
                final repo = ref.read(workoutRepositoryProvider);
                await repo.unsupersedeWorkout(workoutId: widget.workout.id!);
              } catch (e) {
                debugPrint('⚠️ Failed to un-supersede old workout: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          "Couldn't keep your original workout — only the new one is visible."),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }

            TodayWorkoutNotifier.clearCache();
            ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
            ref.read(workoutsProvider.notifier).silentRefresh();
            Navigator.pop(context, approvedWorkout);
          } else if (mounted) {
            // User pressed Back → preview was discarded, original is still
            // is_current=true. No-op on caches, just re-enable the form.
            // (Previously we invalidated caches here too — that was wrong,
            // because the original was already superseded mid-stream. After
            // Phase 1C that mutation is gone, so refreshing would just
            // bounce the home UI for no reason.)
            setState(() => _isRegenerating = false);
          }
          return;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
          _lastBackendUpdateAt = DateTime.now();
        });
      }
    } catch (e) {
      _stopElapsedTimer();
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  Future<void> _applyAISuggestion() async {
    if (_selectedSuggestionIndex == null ||
        _selectedSuggestionIndex! >= _aiSuggestions.length) {
      return;
    }

    _startElapsedTimer();
    setState(() {
      _isRegenerating = true;
      _currentStep = 0;
      _progressMessage = 'Applying suggestion...';
      _progressDetail = null;
      _lastBackendUpdateAt = DateTime.now();
    });

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      _stopElapsedTimer();
      setState(() => _isRegenerating = false);
      return;
    }

    try {
      final suggestion = _aiSuggestions[_selectedSuggestionIndex!];
      final repo = ref.read(workoutRepositoryProvider);

      // Mirror the Customize-tab "Do this today" behavior for AI suggestions.
      String? newScheduledDate;
      bool forceNonPreferredDay = false;
      if (_moveToToday) {
        final now = DateTime.now();
        newScheduledDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayIdx = now.weekday - 1;
        forceNonPreferredDay =
            _userWorkoutDays.isNotEmpty && !_userWorkoutDays.contains(todayIdx);
      }

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId,
        difficulty: suggestion['difficulty'] ?? _selectedDifficulty,
        durationMinutesMin:
            suggestion['duration_minutes'] ?? _selectedDurationMin.round(),
        durationMinutesMax:
            suggestion['duration_minutes'] ?? _selectedDurationMax.round(),
        focusAreas:
            (suggestion['focus_areas'] as List?)?.cast<String>() ?? [],
        workoutType: suggestion['type'],
        aiPrompt: _aiPromptController.text.trim().isEmpty
            ? null
            : _aiPromptController.text.trim(),
        workoutName: suggestion['name'] as String?,
        newScheduledDate: newScheduledDate,
        forceNonPreferredDay: forceNonPreferredDay,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _stopElapsedTimer();
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to apply suggestion: ${progress.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (progress.isCompleted && progress.workout != null) {
          _stopElapsedTimer();
          // Update progress to show we're loading the review
          setState(() {
            _progressMessage = 'Loading review...';
            _progressDetail = 'Preparing your workout';
            _lastBackendUpdateAt = DateTime.now();
          });

          // Phase 1D: require preview_id. Same contract as _regenerate().
          final previewId = progress.previewId;
          if (previewId == null) {
            setState(() => _isRegenerating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Preview not supported by server. Please update the app or contact support.'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          // Show review sheet for user to approve. Commit/discard happens
          // inside the sheet.
          final approvedWorkout = await showWorkoutReviewSheet(
            context,
            ref,
            progress.workout!,
            previewId: previewId,
            originalWorkoutId: widget.workout.id!,
          );

          if (approvedWorkout != null && mounted) {
            // Commit already persisted. Ask user: replace existing or keep both?
            final shouldReplace = await _showReplaceOrAddDialog();
            if (!mounted) return;

            if (shouldReplace == null) {
              // Dialog dismissed AFTER commit — supersede is persisted, so
              // effective state is Replace. Same handling as _regenerate().
              setState(() => _isRegenerating = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Defaulted to Replace — your previous workout was overwritten.'),
                  duration: Duration(seconds: 4),
                ),
              );
              TodayWorkoutNotifier.clearCache();
              ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
              ref.read(workoutsProvider.notifier).silentRefresh();
              Navigator.pop(context, approvedWorkout);
              return;
            }

            if (shouldReplace) {
              WorkoutsNotifier.replaceInCache(widget.workout.id!, approvedWorkout);
            } else {
              // Un-supersede old workout so both appear in carousel. Surface
              // failures — silent fallback would look like Replace.
              try {
                final repo = ref.read(workoutRepositoryProvider);
                await repo.unsupersedeWorkout(workoutId: widget.workout.id!);
              } catch (e) {
                debugPrint('⚠️ Failed to un-supersede old workout: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          "Couldn't keep your original workout — only the new one is visible."),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }

            TodayWorkoutNotifier.clearCache();
            ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
            ref.read(workoutsProvider.notifier).silentRefresh();
            Navigator.pop(context, approvedWorkout);
          } else if (mounted) {
            // Back path — preview discarded, original untouched, no refresh.
            setState(() => _isRegenerating = false);
          }
          return;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
          _lastBackendUpdateAt = DateTime.now();
        });
      }
    } catch (e) {
      _stopElapsedTimer();
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply suggestion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  Widget _buildProgressSection(SheetColors colors, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Step indicators row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (i) {
              final stepNum = i + 1;
              final isActive = stepNum == _currentStep;
              final isDone = stepNum < _currentStep;
              return Row(
                children: [
                  if (i > 0)
                    Container(
                      width: 24,
                      height: 2,
                      color: isDone
                          ? accentColor
                          : accentColor.withOpacity(0.2),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 32 : 28,
                    height: isActive ? 32 : 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? accentColor
                          : isActive
                              ? accentColor.withOpacity(0.15)
                              : colors.glassSurface,
                      border: Border.all(
                        color: isDone || isActive
                            ? accentColor
                            : accentColor.withOpacity(0.3),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? accentColor
                                    : colors.textMuted,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          // Main message (AnimatedSwitcher so changes fade rather than pop).
          // Rotates through phase labels when the backend goes quiet so the
          // headline never feels frozen on a single sentence.
          Builder(builder: (_) {
            final mainMessage = _displayMainMessage();
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                mainMessage,
                key: ValueKey(mainMessage),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          // Substatus — either backend detail or a rotating phase hint so the
          // UI always looks alive during the long AI call.
          Builder(builder: (_) {
            final detail = _displayDetail();
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: detail == null
                  ? const SizedBox(key: ValueKey('no-detail'), height: 0)
                  : Row(
                      key: ValueKey(detail),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            detail,
                            style: TextStyle(
                                fontSize: 13, color: colors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
            );
          }),
          const SizedBox(height: 10),
          // Elapsed time + step count row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                _formatElapsed(_elapsed),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (_currentStep > 0) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 14,
                  color: colors.textMuted.withOpacity(0.3),
                ),
                Text(
                  'Step $_currentStep of $_totalSteps',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (_estimatedRemainingHint() != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 14,
                  color: colors.textMuted.withOpacity(0.3),
                ),
                Text(
                  _estimatedRemainingHint()!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _totalSteps > 0 && _currentStep > 0
                  ? _currentStep / _totalSteps
                  : null,
              backgroundColor: accentColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 10),
          // "Takes time" hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 13, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                'AI generation typically takes 15-30s',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
