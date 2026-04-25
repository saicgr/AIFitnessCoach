part of 'workout_ui_builders_mixin.dart';

/// Extension providing UI builder methods
extension WorkoutUIBuildersMixinUI2 on WorkoutUIBuildersMixin {

  // ── Helpers to access State<T> members through the mixin ──
  BuildContext get _ctx => (this as dynamic).context as BuildContext;
  void _setState(VoidCallback fn) => (this as dynamic).setState(fn);

  /// Build the V2 MacroFactor-style active workout screen.
  Widget buildActiveWorkoutScreenV2(bool isDark, Color backgroundColor) {
    final currentExercise = exercises[currentExerciseIndex];
    final nextExercise = currentExerciseIndex < exercises.length - 1
        ? exercises[currentExerciseIndex + 1]
        : null;

    // Get set data for current exercise
    final setRows = buildSetRowsForExercise(viewingExerciseIndex);
    final completedExerciseIndices = getCompletedExerciseIndices();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showQuitDialog();
        }
      },
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          // Use landscape layout when rotated
          if (isLandscape) {
            return buildLandscapeLayoutV2(
              isDark: isDark,
              currentExercise: currentExercise,
              nextExercise: nextExercise,
              setRows: setRows,
              completedExerciseIndices: completedExerciseIndices,
            );
          }

          // Portrait layout (original)
          return Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(
        backgroundColor: isDark ? WorkoutDesign.background : Colors.grey.shade50,
        body: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // V2 Top bar - wrapped in RepaintBoundary to isolate per-second timer repaints
                RepaintBoundary(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final warmupEnabled = ref.watch(warmupDurationProvider).warmupEnabled;
                      final favoritesState = ref.watch(favoritesProvider);
                      final currentExercise = exercises.isNotEmpty ? exercises[currentExerciseIndex] : null;
                      final isFavorite = currentExercise != null
                          ? favoritesState.isFavorite(currentExercise.name)
                          : false;

                      return WorkoutTopBarV2(
                        workoutSeconds: timerController.workoutSeconds,
                        restSecondsRemaining: isResting ? timerController.restSecondsRemaining : null,
                        totalRestSeconds: isResting ? timerController.initialRestDuration : null,
                        isPaused: isPaused,
                        showBackButton: warmupEnabled && (warmupExercises?.isNotEmpty ?? false),
                        backButtonLabel: (warmupEnabled && (warmupExercises?.isNotEmpty ?? false)) ? 'Warmup' : null,
                        onMenuTap: showWorkoutPlanDrawer,
                        onBackTap: (warmupEnabled && (warmupExercises?.isNotEmpty ?? false)) ? goBackToWarmup : null,
                        onCloseTap: showQuitDialog,
                        onTimerTap: togglePause,
                        onMinimize: minimizeWorkout,
                        onFavoriteTap: currentExercise != null ? () => toggleFavoriteExercise() : null,
                        isFavorite: isFavorite,
                        onCompleteWorkoutNow: completeWorkoutNow,
                      );
                    },
                  ),
                ),

                // Live stats strip — Duration / Calories / Volume.
                // Isolated in its own RepaintBoundary so the per-second
                // timer tick doesn't force the exercise body to repaint.
                RepaintBoundary(
                  child: Builder(
                    builder: (_) {
                      final allSets = <SetLog>[
                        for (final entry in completedSets.values) ...entry,
                      ];
                      return WorkoutStatsStrip(
                        workoutSeconds: timerController.workoutSeconds,
                        setLogs: allSets,
                        useKg: useKg,
                        isDark: isDark,
                      );
                    },
                  ),
                ),

                // Swipeable exercise content area
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // Swipe left (next exercise) - negative velocity
                      if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                        if (viewingExerciseIndex < exercises.length - 1) {
                          HapticFeedback.selectionClick();
                          _setState(() => viewingExerciseIndex++);
                        }
                      }
                      // Swipe right (previous exercise) - positive velocity
                      else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                        if (viewingExerciseIndex > 0) {
                          HapticFeedback.selectionClick();
                          _setState(() => viewingExerciseIndex--);
                        }
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise title and set counter with info button
                        Container(
                          key: AppTourKeys.exerciseCardKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exercise name and set counter (long-press for options)
                                Expanded(
                                  child: GestureDetector(
                                    onLongPress: () => showExerciseOptionsSheet(viewingExerciseIndex),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final name = exercises[viewingExerciseIndex].name;
                                            final len = name.length;
                                            final fontSize = len <= 15 ? 26.0
                                                : len <= 25 ? 22.0
                                                : len <= 35 ? 19.0
                                                : 16.0;
                                            return Text(
                                              name,
                                              style: WorkoutDesign.titleStyle.copyWith(
                                                fontSize: fontSize,
                                                color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // Live heart rate display (merged WearOS + BLE)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HeartRateDisplay(
                                    iconSize: 24,
                                    fontSize: 18,
                                    showZoneLabel: false,
                                  ),
                                  // BLE connection indicator
                                  Consumer(builder: (context, ref, _) {
                                    final connAsync = ref.watch(bleHrConnectionStateProvider);
                                    final connState = connAsync.whenOrNull(data: (s) => s);
                                    if (connState == null || connState == BleHrConnectionState.disconnected) {
                                      return const SizedBox.shrink();
                                    }
                                    final color = connState == BleHrConnectionState.connected
                                        ? Colors.green
                                        : Colors.orange;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.bluetooth_connected,
                                        size: 14,
                                        color: color,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Info magic pill (styled like Video chip)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  exerciseInfoOpened++;
                                  showExerciseDetailsSheet(exercises[viewingExerciseIndex]);
                                },
                                child: Container(
                                  height: WorkoutDesign.chipHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? WorkoutDesign.surface : Colors.white,
                                    borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
                                    border: Border.all(
                                      color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Info',
                                        style: WorkoutDesign.chipStyle.copyWith(
                                          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),

                        // Set counter row with skip on the right
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                'Set ${(completedSets[viewingExerciseIndex]?.length ?? 0) + 1} of ${totalSetsPerExercise[viewingExerciseIndex] ?? 3}',
                                style: WorkoutDesign.subtitleStyle.copyWith(
                                  color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              // Breathing guide button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  breathingGuideOpened++;
                                  showBreathingGuide(
                                    context: context,
                                    exercise: exercises[viewingExerciseIndex],
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? WorkoutDesign.surface : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.air_rounded,
                                        size: 16,
                                        color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Breathing',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Skip button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  skipExercise();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.orange.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.skip_next_rounded,
                                        size: 16,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Skip',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action chips row (Superset, Warm Up, etc.) - Video moved to bottom, Info moved to title
                        Container(
                          key: AppTourKeys.swapExerciseKey,
                          child: ActionChipsRow(
                          chips: buildActionChipsForCurrentExercise()
                              .where((chip) => chip.label != 'Video' && chip.label != 'Info')
                              .toList(),
                          onChipTapped: handleChipTapped,
                          showAiChip: false,
                          hasAiNotification: currentWeightSuggestion != null,
                          onAiChipTapped: () => showAICoachSheet(currentExercise),
                        ),
                        ),

                        const SizedBox(height: 8),

                        // Progression strip — last 3 sessions + today's target.
                        // Renders above the set table so users see their
                        // trajectory (and today's goal) before logging set 1.
                        // Auto-hides when we have no prior sessions for this
                        // exercise (the PreSetCoachingBanner handles
                        // first-time empty state inside the table).
                        Builder(builder: (ctx) {
                          final ex = exercises[viewingExerciseIndex];
                          final sessions =
                              preSetHistoryByExerciseName[ex.name] ?? const [];
                          if (sessions.isEmpty) return const SizedBox.shrink();

                          final firstSet = setRows.isNotEmpty ? setRows.first : null;
                          final isBw = firstSet?.isBodyweight ?? false;
                          final isTm = firstSet?.isTimedExercise ?? false;
                          return ProgressionStrip(
                            sessions: sessions,
                            useKg: useKg,
                            targetWeightKg: firstSet?.targetWeight,
                            targetReps: firstSet?.targetReps,
                            targetDurationSeconds:
                                firstSet?.targetDurationSeconds ?? firstSet?.targetHoldSeconds,
                            isBodyweight: isBw,
                            isTimed: isTm,
                            // Tap target pill → put the weight input in
                            // "edit mode": select all text in the weight
                            // controller + pop the soft keyboard. The set
                            // table already binds the weight TextField to
                            // weightController so changes here flow back
                            // to the active row's target. This is the
                            // "morph pill → editor → save on ✓" flow.
                            onTargetTap: () {
                              HapticFeedback.selectionClick();
                              if (weightController.text.isNotEmpty) {
                                weightController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: weightController.text.length,
                                );
                              }
                              // Nudge the field to open via SystemChannels —
                              // mirrors the tap-on-input behavior without
                              // having direct access to the table's internal
                              // FocusNode. If the keyboard is already open
                              // this is a no-op.
                              SystemChannels.textInput
                                  .invokeMethod<void>('TextInput.show');
                            },
                            // Tap prior-session pill → show the full set
                            // breakdown for that day.
                            onSessionTap: (session) {
                              showSessionDetailSheet(
                                context: ctx,
                                session: session,
                                useKg: useKg,
                                isBodyweight: isBw,
                                isTimed: isTm,
                                exerciseName: ex.name,
                              );
                            },
                          );
                        }),

                        // Set tracking table with inline rest row.
                        //
                        // No-scroll refactor (Task #15): the table itself now
                        // enforces a fixed-height budget via `maxVisibleRows`
                        // + the shared `SetRail` + overflow sheet. The
                        // `Expanded` here hands the table the remaining
                        // vertical space; anything past the 4-row budget
                        // collapses into the rail (≥5 sets) or the overflow
                        // sheet (≥12 sets). The Plate indicator + AI input
                        // live below as direct siblings — they're always
                        // visible and never pushed off-screen by a long set
                        // list.
                        Expanded(
                          child: Container(
                            key: AppTourKeys.setLoggingKey,
                            child: SetTrackingTable(
                              key: ValueKey('set_tracking_$viewingExerciseIndex'),
                              exercise: exercises[viewingExerciseIndex],
                              sets: setRows,
                              useKg: useKg,
                              activeSetIndex: completedSets[viewingExerciseIndex]?.length ?? 0,
                              weightController: weightController,
                              repsController: repsController,
                              repsRightController: isLeftRightMode ? repsRightController : null,
                              onSetCompleted: handleSetCompletedV2,
                              onSetUpdated: updateCompletedSet,
                              onAddSet: () => _setState(() {
                                totalSetsPerExercise[viewingExerciseIndex] =
                                    (totalSetsPerExercise[viewingExerciseIndex] ?? 3) + 1;
                              }),
                              isLeftRightMode: isLeftRightMode,
                              allSetsCompleted: isExerciseCompleted(viewingExerciseIndex),
                              onSelectAllTapped: () {
                                if (isExerciseCompleted(viewingExerciseIndex)) {
                                  HapticFeedback.lightImpact();
                                }
                              },
                              onSetDeleted: (index) => deleteCompletedSet(index),
                              onToggleUnit: toggleUnit,
                              onRirTapped: (setIndex, currentRir) => showRirPicker(setIndex, currentRir),
                              activeRir: lastSetRir,
                              onActiveRirChanged: (rir) => _setState(() => lastSetRir = rir),
                              showInlineRest: showInlineRest &&
                                  viewingExerciseIndex == currentExerciseIndex &&
                                  !isRestingBetweenExercises,
                              inlineRestRowWidget: buildInlineRestRowV2(),
                              preSetBannerMessage: preSetBannerMessageFor(viewingExerciseIndex),
                              onPreSetBannerDismissed: () =>
                                  dismissPreSetBanner(viewingExerciseIndex),
                              preSetBannerAnimationKey:
                                  'pre_set_${exercises[viewingExerciseIndex].id}',
                              // Rail-tap handler: the Advanced screen derives
                              // `activeSetIndex` from `completedSets.length`,
                              // so there's no separate "view set N" state to
                              // flip. The table's internal `_focusOverride`
                              // re-centers the render window; leaving this
                              // null keeps write state untouched while still
                              // letting the user peek any set via the rail.
                              onJumpToSet: null,
                            ),
                          ),
                        ),

                        // Barbell plate indicator (only for barbell exercises).
                        // Outside the Expanded so it sits on top of the AI
                        // input bar without being clipped by a long set list.
                        if (isBarbell(exercises[viewingExerciseIndex].equipment, exerciseName: exercises[viewingExerciseIndex].name))
                          AnimatedBuilder(
                            animation: weightController,
                            builder: (context, _) {
                              final weight = double.tryParse(weightController.text) ?? 0;
                              final barEquipment = exerciseBarType[viewingExerciseIndex]
                                  ?? exercises[viewingExerciseIndex].equipment;
                              final barWt = getBarWeight(barEquipment, useKg: useKg);
                              if (weight < barWt) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: GestureDetector(
                                  onTap: () => showBarTypeSelectorImpl(exercises[viewingExerciseIndex]),
                                  child: BarbellPlateIndicator(
                                    totalWeight: weight,
                                    barWeight: barWt,
                                    useKg: useKg,
                                  ),
                                ),
                              );
                            },
                          ),

                        // AI Text Input Bar — always on screen (below the
                        // table), never pushed off by a long set list.
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AiTextInputBar(
                            workoutId: (workoutWidget as dynamic).workout.id ?? '',
                            useKg: useKg,
                            currentExerciseName: exercises.isNotEmpty
                                ? exercises[viewingExerciseIndex].name
                                : null,
                            currentExerciseIndex: viewingExerciseIndex,
                            lastSetWeight: completedSets[viewingExerciseIndex]?.isNotEmpty == true
                                ? completedSets[viewingExerciseIndex]!.last.weight
                                : null,
                            lastSetReps: completedSets[viewingExerciseIndex]?.isNotEmpty == true
                                ? completedSets[viewingExerciseIndex]!.last.reps
                                : null,
                            onExercisesParsed: (exercises) => handleParsedExercises(exercises),
                            onV2Parsed: (response) => handleV2Parsed(response),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Instructions, Video, Hydration, and Note quick actions row
                HydrationQuickActions(
                  onTap: () => showHydrationDialogImpl(),
                  onNoteTap: () => showNotesSheet(exercises[viewingExerciseIndex]),
                  onVideoTap: () => handleChipTapped('video'),
                  onInstructionsTap: () =>
                      showExerciseDetailsSheet(exercises[viewingExerciseIndex]),
                ),

                // Exercise thumbnail strip (bottom navigation)
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: isDark ? WorkoutDesign.surface : Colors.white,
                      child: SafeArea(
                        top: false,
                        child: ExerciseThumbnailStripV2(
                          key: ValueKey('thumb_strip_${exercises.map((e) => e.id ?? e.name).join('_')}'),
                          exercises: exercises.toList(), // Create new list instance
                          currentIndex: viewingExerciseIndex,
                          completedExercises: completedExerciseIndices,
                          onExerciseTap: (index) {
                            HapticFeedback.selectionClick();
                            _setState(() {
                              viewingExerciseIndex = index;
                              currentExerciseIndex = index;
                            });
                            initControllersForExercise(index);
                          },
                          onExerciseLongPress: (index) => showExerciseOptionsSheet(index),
                          onAddTap: () => showExerciseAddSheetImpl(),
                          showAddButton: true,
                          onReorder: onExercisesReordered,
                          onCreateSuperset: onSupersetFromDrag,
                          onDragActiveChanged: (isDragging, index) {
                            _setState(() {
                              isDragActive = isDragging;
                              draggedExerciseIndex = index;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Drag-to-action zones (Delete + Swap) — appear when dragging a thumbnail
            if (isDragActive)
              buildDragActionZones(isDark),

            // Rest overlay (shows on top) - only for rest between exercises
            // Between-sets rest is handled by inline rest row
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (isResting && isRestingBetweenExercises)
              Positioned.fill(
                key: AppTourKeys.restTimerKey,
                child: RepaintBoundary(
                  child: RestTimerOverlay(
                    restSecondsRemaining: timerController.restSecondsRemaining,
                    initialRestDuration: timerController.initialRestDuration,
                    restMessage: currentRestMessage,
                    currentExercise: currentExercise,
                    completedSetsCount: completedSets[currentExerciseIndex]?.length ?? 0,
                    totalSets: totalSetsPerExercise[currentExerciseIndex] ?? 3,
                    nextExercise: nextExercise,
                    isRestBetweenExercises: isRestingBetweenExercises,
                    onSkipRest: () => timerController.skipRest(),
                    onLog1RM: () => showLog1RMSheet(currentExercise),
                    weightSuggestion: currentWeightSuggestion,
                    isLoadingWeightSuggestion: isLoadingWeightSuggestion,
                    onAcceptWeightSuggestion: acceptWeightSuggestion,
                    onDismissWeightSuggestion: dismissWeightSuggestion,
                    restSuggestion: restSuggestion,
                    isLoadingRestSuggestion: isLoadingRestSuggestion,
                    onAcceptRestSuggestion: acceptRestSuggestion,
                    onDismissRestSuggestion: dismissRestSuggestion,
                    currentRpe: lastSetRpe,
                    currentRir: lastSetRir,
                    onRpeChanged: (rpe) => _setState(() => lastSetRpe = rpe),
                    onRirChanged: (rir) => _setState(() => lastSetRir = rir),
                    lastSetReps: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.reps
                        : null,
                    lastSetTargetReps: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.targetReps
                        : null,
                    lastSetWeight: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.weight
                        : null,
                    onAskAICoach: () => showAICoachSheet(currentExercise),
                    coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
                  ),
                ),
              ),

            // Fatigue alert modal
            if (showFatigueAlert && fatigueAlertData != null)
              Positioned.fill(
                child: FatigueAlertModal(
                  alertData: fatigueAlertData!,
                  currentWeight: double.tryParse(weightController.text) ?? 0,
                  exerciseName: currentExercise.name,
                  onAcceptSuggestion: handleAcceptFatigueSuggestion,
                  onContinueAsPlanned: handleDismissFatigueAlert,
                  onStopExercise: skipExercise,
                ),
              ),

            // Floating AI Coach FAB (positioned above thumbnail strip)
            if (!isResting && !hideAICoachForSession && ref.watch(aiSettingsProvider).showAICoachDuringWorkouts)
              Positioned(
                key: AppTourKeys.workoutAiKey,
                bottom: MediaQuery.of(context).padding.bottom + 100, // Above thumbnail strip (~80px height + padding)
                right: 20,
                child: buildFloatingAICoachButton(currentExercise),
              ),
          ],
        ),
      );
            },
          );
        },
      ),
    );
  }


  /// Build landscape layout with side-by-side video + set table.
  Widget buildLandscapeLayoutV2({
    required bool isDark,
    required dynamic currentExercise,
    required dynamic nextExercise,
    required List<SetRowData> setRows,
    required Set<int> completedExerciseIndices,
  }) {
    final backgroundColor = isDark ? WorkoutDesign.background : Colors.grey.shade50;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // LEFT PANEL (~35%): Video Player + Thumbnail Strip
                SizedBox(
                  width: MediaQuery.of(_ctx).size.width * 0.35,
                  child: Column(
                    children: [
                      // Exercise VIDEO player (auto-plays, looped)
                      Expanded(
                        child: buildLandscapeVideoPlayer(isDark),
                      ),
                      // Horizontal thumbnail strip at bottom
                      buildLandscapeThumbnailStrip(
                        isDark: isDark,
                        completedExerciseIndices: completedExerciseIndices,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                ),

                // Vertical divider
                VerticalDivider(width: 1, color: cardBorder, thickness: 1),

                // RIGHT PANEL (~65%): Top Bar + Set Table + Actions
                Expanded(
                  child: Column(
                    children: [
                      // Compact top bar: <- | Timer | Title | Set X/Y | x
                      buildLandscapeTopBar(isDark: isDark, accentColor: accentColor),

                      // Set tracking table (gets most vertical space).
                      //
                      // No-scroll refactor (Task #15): landscape budget is
                      // even tighter than iPhone SE portrait, so we lean on
                      // the table's fixed-row windowing HARD here — only 3
                      // rows in the focal window, with the rail picking up
                      // the slack. Anything past the 3 rows collapses into
                      // the rail (≥4 sets) or the overflow sheet (≥12 sets).
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SetTrackingTable(
                            key: ValueKey('set_tracking_landscape_$viewingExerciseIndex'),
                            exercise: exercises[viewingExerciseIndex],
                            sets: setRows,
                            useKg: useKg,
                            activeSetIndex: completedSets[viewingExerciseIndex]?.length ?? 0,
                            weightController: weightController,
                            repsController: repsController,
                            repsRightController: isLeftRightMode ? repsRightController : null,
                            onSetCompleted: handleSetCompletedV2,
                            onSetUpdated: updateCompletedSet,
                            onAddSet: () => _setState(() {
                              totalSetsPerExercise[viewingExerciseIndex] =
                                  (totalSetsPerExercise[viewingExerciseIndex] ?? 3) + 1;
                            }),
                            isLeftRightMode: isLeftRightMode,
                            allSetsCompleted: isExerciseCompleted(viewingExerciseIndex),
                            onSelectAllTapped: () {
                              if (isExerciseCompleted(viewingExerciseIndex)) {
                                HapticFeedback.lightImpact();
                              }
                            },
                            onSetDeleted: (index) => deleteCompletedSet(index),
                            onToggleUnit: toggleUnit,
                            onRirTapped: (setIndex, currentRir) => showRirPicker(setIndex, currentRir),
                            activeRir: lastSetRir,
                            onActiveRirChanged: (rir) => _setState(() => lastSetRir = rir),
                            showInlineRest: showInlineRest &&
                                viewingExerciseIndex == currentExerciseIndex &&
                                !isRestingBetweenExercises,
                            inlineRestRowWidget: buildInlineRestRowV2(),
                            preSetBannerMessage: preSetBannerMessageFor(viewingExerciseIndex),
                            onPreSetBannerDismissed: () =>
                                dismissPreSetBanner(viewingExerciseIndex),
                            preSetBannerAnimationKey:
                                'pre_set_${exercises[viewingExerciseIndex].id}_landscape',
                            // Landscape: tighter budget, 3 visible rows instead of 4.
                            maxVisibleRows: 3,
                            onJumpToSet: null,
                          ),
                        ),
                      ),

                      // Compact action chips row (no Video chip - it's always visible)
                      buildLandscapeActions(isDark: isDark, accentColor: accentColor),
                    ],
                  ),
                ),
              ],
            ),

            // Rest overlay (shows on top) - for rest between exercises
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (isResting && isRestingBetweenExercises)
              Positioned.fill(
                child: RepaintBoundary(
                  child: RestTimerOverlay(
                    restSecondsRemaining: timerController.restSecondsRemaining,
                    initialRestDuration: timerController.initialRestDuration,
                    restMessage: currentRestMessage,
                    currentExercise: currentExercise,
                    completedSetsCount: completedSets[currentExerciseIndex]?.length ?? 0,
                    totalSets: totalSetsPerExercise[currentExerciseIndex] ?? 3,
                    nextExercise: nextExercise,
                    isRestBetweenExercises: isRestingBetweenExercises,
                    onSkipRest: () => timerController.skipRest(),
                    onLog1RM: () => showLog1RMSheet(currentExercise),
                    weightSuggestion: currentWeightSuggestion,
                    isLoadingWeightSuggestion: isLoadingWeightSuggestion,
                    onAcceptWeightSuggestion: acceptWeightSuggestion,
                    onDismissWeightSuggestion: dismissWeightSuggestion,
                    restSuggestion: restSuggestion,
                    isLoadingRestSuggestion: isLoadingRestSuggestion,
                    onAcceptRestSuggestion: acceptRestSuggestion,
                    onDismissRestSuggestion: dismissRestSuggestion,
                    currentRpe: lastSetRpe,
                    currentRir: lastSetRir,
                    onRpeChanged: (rpe) => _setState(() => lastSetRpe = rpe),
                    onRirChanged: (rir) => _setState(() => lastSetRir = rir),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
