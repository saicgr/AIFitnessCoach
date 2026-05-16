part of 'workout_ui_builders_mixin.dart';

/// Extension providing UI builder methods
extension WorkoutUIBuildersMixinUI1 on WorkoutUIBuildersMixin {

  // ── Helpers to access State<T> members through the mixin ──
  BuildContext get _ctx => (this as dynamic).context as BuildContext;
  void _setState(VoidCallback fn) => (this as dynamic).setState(fn);

  // ── UI Builder Methods ──

  /// Build the warmup loading screen shown while warmup data is being fetched.
  Widget buildWarmupLoadingScreen() {
    final isDark = Theme.of(_ctx).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.orange),
            const SizedBox(height: 20),
            Text(
              'Preparing warmup...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading your personalized warmup exercises',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: handleSkipWarmup,
              child: Text(
                'Skip warmup',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Build the V1 active workout screen (non-MacroFactor style).
  Widget buildActiveWorkoutScreen(bool isDark, Color backgroundColor) {
    final currentExercise = exercises[currentExerciseIndex];
    final nextExercise = currentExerciseIndex < exercises.length - 1
        ? exercises[currentExerciseIndex + 1]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showQuitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Background media (tappable - minimizes overlay or toggles video)
            Positioned.fill(
              child: GestureDetector(
                onTap: handleVideoAreaTap,
                behavior: HitTestBehavior.opaque,
                child: buildMediaBackground(),
              ),
            ),

            // Rest overlay with weight suggestion (only for rest between exercises)
            // Between-sets rest is handled by inline rest row in SetTrackingOverlay
            // Wrapped in RepaintBoundary to isolate per-second rest timer repaints
            if (isResting && isRestingBetweenExercises)
              Positioned.fill(
                child: RepaintBoundary(
                  child: RestTimerOverlay(
                    restSecondsRemaining: timerController.restSecondsRemaining,
                    initialRestDuration: timerController.initialRestDuration,
                    restMessage: currentRestMessage,
                    currentExercise: currentExercise,
                    completedSetsCount:
                        completedSets[currentExerciseIndex]?.length ?? 0,
                    totalSets: totalSetsPerExercise[currentExerciseIndex] ?? 3,
                    nextExercise: nextExercise,
                    isRestBetweenExercises: isRestingBetweenExercises,
                    onSkipRest: () => timerController.skipRest(),
                    onLog1RM: () => showLog1RMSheet(currentExercise),
                    // Weight suggestion props
                    weightSuggestion: currentWeightSuggestion,
                    isLoadingWeightSuggestion: isLoadingWeightSuggestion,
                    onAcceptWeightSuggestion: acceptWeightSuggestion,
                    onDismissWeightSuggestion: dismissWeightSuggestion,
                    // Rest suggestion props (AI-powered)
                    restSuggestion: restSuggestion,
                    isLoadingRestSuggestion: isLoadingRestSuggestion,
                    onAcceptRestSuggestion: acceptRestSuggestion,
                    onDismissRestSuggestion: dismissRestSuggestion,
                    // RPE/RIR input during rest
                    currentRpe: lastSetRpe,
                    currentRir: lastSetRir,
                    onRpeChanged: (rpe) => _setState(() => lastSetRpe = rpe),
                    onRirChanged: (rir) => _setState(() => lastSetRir = rir),
                    // Last set performance data for display
                    lastSetReps: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.reps
                        : null,
                    lastSetTargetReps: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.targetReps
                        : null,
                    lastSetWeight: completedSets[currentExerciseIndex]?.isNotEmpty == true
                        ? completedSets[currentExerciseIndex]!.last.weight
                        : null,
                    // Ask AI Coach button with coach persona (reactive to changes)
                    onAskAICoach: () => showAICoachSheet(currentExercise),
                    coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
                  ),
                ),
              ),

            // Fatigue alert modal (AI-powered)
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

            // Floating rest pill: shown when the user is between-sets-resting
            // AND peeking another exercise (viewing != current). Without
            // this, peeking hides the inline rest UI and the user
            // perceives the rest as "reset" — actually still ticking, but
            // invisible. Tap returns to the current exercise.
            if (isResting &&
                !isRestingBetweenExercises &&
                viewingExerciseIndex != currentExerciseIndex)
              Positioned(
                top: MediaQuery.of(_ctx).padding.top + 64,
                left: 16,
                right: 16,
                child: RepaintBoundary(
                  child: _FloatingRestPeekPill(
                    secondsRemaining: timerController.restSecondsRemaining,
                    onReturn: () => _setState(() =>
                        viewingExerciseIndex = currentExerciseIndex),
                  ),
                ),
              ),

            // Top overlay (show during active workout OR between-sets rest)
            // Wrapped in RepaintBoundary to isolate per-second timer repaints
            if (!isResting || (isResting && !isRestingBetweenExercises))
              RepaintBoundary(
                child: WorkoutTopOverlay(
                  workoutSeconds: timerController.workoutSeconds,
                  isPaused: isPaused,
                  totalExercises: exercises.length,
                  currentExerciseIndex: currentExerciseIndex,
                  totalCompletedSets: completedSets.values
                      .fold(0, (sum, sets) => sum + sets.length),
                  onTogglePause: togglePause,
                  onShowExerciseList: () {},
                  onQuit: showQuitDialog,
                ),
              ),

            // Set tracking overlay - full screen (no floating card, no minimize)
            // Show during active workout OR during between-sets rest (for inline rest row)
            if (!isResting || (isResting && !isRestingBetweenExercises))
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(_ctx).padding.top + 70,
                bottom: 90, // Leave space for bottom bar
                child: SetTrackingOverlay(
                  exercise: exercises[viewingExerciseIndex],
                  viewingExerciseIndex: viewingExerciseIndex,
                  currentExerciseIndex: currentExerciseIndex,
                  totalExercises: exercises.length,
                  totalSets: totalSetsPerExercise[viewingExerciseIndex] ?? 3,
                  completedSets:
                      completedSets[viewingExerciseIndex] ?? [],
                  previousSets: previousSets[viewingExerciseIndex] ?? [],
                  useKg: useKg,
                  weightController: weightController,
                  repsController: repsController,
                  isActiveRowExpanded: isActiveRowExpanded,
                  justCompletedSetIndex: justCompletedSetIndex,
                  isDoneButtonPressed: isDoneButtonPressed,
                  onToggleRowExpansion: () =>
                      _setState(() => isActiveRowExpanded = !isActiveRowExpanded),
                  onCompleteSet: completeSet,
                  onToggleUnit: toggleUnit,
                  onClose: () {}, // No close needed for full screen
                  onPreviousExercise: viewingExerciseIndex > 0
                      ? () => _setState(() => viewingExerciseIndex--)
                      : null,
                  onNextExercise: viewingExerciseIndex < exercises.length - 1
                      ? () => _setState(() => viewingExerciseIndex++)
                      : null,
                  onAddSet: () => _setState(() {
                    totalSetsPerExercise[viewingExerciseIndex] =
                        (totalSetsPerExercise[viewingExerciseIndex] ?? 3) + 1;
                  }),
                  onBackToCurrentExercise: () =>
                      _setState(() => viewingExerciseIndex = currentExerciseIndex),
                  onEditSet: (index) => editCompletedSet(index),
                  onUpdateSet: (index, weight, reps) => updateCompletedSet(index, weight, reps),
                  onDeleteSet: (index) => deleteCompletedSet(index),
                  onQuickCompleteSet: (index, complete) => quickCompleteSet(index, complete),
                  onDoneButtonPressDown: () =>
                      _setState(() => isDoneButtonPressed = true),
                  onDoneButtonPressUp: () {
                    _setState(() => isDoneButtonPressed = false);
                    HapticFeedback.heavyImpact();
                    completeSet();
                  },
                  onDoneButtonPressCancel: () =>
                      _setState(() => isDoneButtonPressed = false),
                  onShowNumberInputDialog: showNumberInputDialogImpl,
                  onSkipExercise: skipExercise,
                  onOpenWorkoutPlan: showWorkoutPlanDrawer,
                  onOpenExerciseOptions: () => showExerciseOptionsSheet(viewingExerciseIndex),
                  isMinimized: false, // Always expanded
                  onMinimizedChanged: null, // No minimize needed
                  lastSessionData: getLastSessionData(viewingExerciseIndex),
                  prData: getPrData(viewingExerciseIndex),
                  currentWeightIncrement: weightIncrement,
                  onWeightIncrementChanged: (value) =>
                      _setState(() => weightIncrement = value),
                  currentProgressionType: (repProgressionPerExercise[viewingExerciseIndex] ?? RepProgressionType.straight).displayName,
                  onOpenProgressionPicker: () => showProgressionPicker(viewingExerciseIndex),
                  onEditTarget: (setIndex, weight, reps, rir) {
                    _setState(() {
                      final exercise = exercises[viewingExerciseIndex];
                      final existingTargets = List<SetTarget>.from(exercise.setTargets ?? []);

                      // Find or create target for this set (setIndex is 0-indexed, setNumber is 1-indexed)
                      final setNumber = setIndex + 1;
                      final targetIndex = existingTargets.indexWhere((t) => t.setNumber == setNumber);
                      final newTarget = SetTarget(
                        setNumber: setNumber,
                        setType: 'working',
                        targetReps: reps,
                        targetWeightKg: weight,
                        targetRir: rir,
                      );

                      if (targetIndex >= 0) {
                        existingTargets[targetIndex] = newTarget;
                      } else {
                        existingTargets.add(newTarget);
                      }

                      exercises[viewingExerciseIndex] = exercise.copyWith(setTargets: existingTargets);
                    });
                  },
                  // Inline rest row props
                  showInlineRest: (() {
                    final show = showInlineRest && viewingExerciseIndex == currentExerciseIndex;
                    debugPrint('🟡 [SetTrackingOverlay] showInlineRest=$show (showInlineRest=$showInlineRest, viewing=$viewingExerciseIndex, current=$currentExerciseIndex, isResting=$isResting, isBetweenEx=$isRestingBetweenExercises)');
                    return show;
                  })(),
                  restTimeRemaining: timerController.restSecondsRemaining,
                  restDurationTotal: inlineRestDuration,
                  onRestComplete: handleInlineRestComplete,
                  onSkipRest: handleInlineRestSkip,
                  onAdjustTime: handleInlineRestTimeAdjust,
                  onRateRpe: handleInlineRestRpeRating,
                  onAddSetNote: handleInlineRestNote,
                  currentRpe: inlineRestCurrentRpe,
                  achievementPrompt: inlineRestAchievementPrompt,
                  aiTip: inlineRestAiTip,
                  isLoadingAiTip: isLoadingAiTip,
                ),
              ),

            // Bottom bar with action buttons (show during active workout OR between-sets rest)
            if (!isResting || (isResting && !isRestingBetweenExercises))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: WorkoutBottomBar(
                  currentExercise: currentExercise,
                  nextExercise: nextExercise,
                  allExercises: exercises,
                  currentExerciseIndex: currentExerciseIndex,
                  completedSetsPerExercise: completedSets.map(
                    (key, value) => MapEntry(key, value.length),
                  ),
                  showInstructions: showInstructions,
                  isResting: isResting,
                  onToggleInstructions: () =>
                      _setState(() => showInstructions = !showInstructions),
                  onSkip: isResting
                      ? () => timerController.skipRest()
                      : skipExercise,
                  onExerciseTap: (index) {
                    _setState(() {
                      viewingExerciseIndex = index;
                      currentExerciseIndex = index;
                    });
                    initControllersForExercise(index);
                  },
                  // New action button callbacks
                  currentCompletedSets:
                      completedSets[currentExerciseIndex]?.length ?? 0,
                  onAddSet: () => _setState(() {
                    totalSetsPerExercise[currentExerciseIndex] =
                        (totalSetsPerExercise[currentExerciseIndex] ?? 3) + 1;
                  }),
                  onDeleteSet: () {
                    final sets = completedSets[currentExerciseIndex];
                    if (sets != null && sets.isNotEmpty) {
                      _setState(() => sets.removeLast());
                    }
                  },
                  onAddWater: showHydrationDialogImpl,
                  onOpenBreathingGuide: () => showBreathingGuideImpl(currentExercise),
                  onOpenAICoach: () => showAICoachSheet(currentExercise),
                  coachPersona: ref.watch(aiSettingsProvider).getCurrentCoach(),
                  onShowExerciseInfo: () => showExerciseInfoSheet(
                    context: _ctx,
                    exercise: currentExercise,
                  ),
                ),
              ),

            // Floating AI Coach FAB (visible when not resting, not hidden for session, and enabled in settings)
            if (!isResting && !hideAICoachForSession && ref.watch(aiSettingsProvider).showAICoachDuringWorkouts)
              Positioned(
                bottom: MediaQuery.of(_ctx).padding.bottom + 90,
                right: 20,
                child: buildFloatingAICoachButton(currentExercise),
              ),
          ],
        ),
      ),
    );
  }

}

/// Slim pill anchored under the workout top bar that surfaces the
/// still-ticking between-sets rest timer whenever the user is peeking a
/// different exercise. Solves the perceived "rest reset" — the timer
/// state itself is fine, the inline UI just hides while peeking. Tap
/// the pill (or label) to snap back to the current exercise.
///
/// One sentence per visual element so it stays scannable without a
/// magnifying glass: clock icon · `mm:ss` countdown · "tap to return".
class _FloatingRestPeekPill extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onReturn;

  const _FloatingRestPeekPill({
    required this.secondsRemaining,
    required this.onReturn,
  });

  String _fmt(int s) {
    if (s < 0) s = 0;
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.92);
    return Semantics(
      button: true,
      label:
          'Rest ${_fmt(secondsRemaining)} remaining. Tap to return to current exercise.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onReturn,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Text(
                  _fmt(secondsRemaining),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: fg.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tap to return',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: fg.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
