part of 'set_logging_mixin.dart';

/// Extension providing additional set logging UI methods
extension SetLoggingMixinUI on SetLoggingMixin {

  // ── Helpers to access State<T> members through the mixin ──
  BuildContext get _ctx => (this as dynamic).context as BuildContext;
  bool get _mounted => (this as dynamic).mounted as bool;
  void _setState(VoidCallback fn) => (this as dynamic).setState(fn);

  /// Convert a display-unit weight back to kg for storage in [SetTarget.targetWeightKg].
  /// Pattern math runs in display units (lbs or kg) for correct snapping, but
  /// [SetTarget.targetWeightKg] must always be in kg so the display layer can
  /// convert once (kg→display). Without this, each re-application would
  /// compound the kg→lbs conversion.
  double _displayToKg(double displayWeight) {
    return useKg ? displayWeight : displayWeight * WeightUtils.lbsToKgFactor;
  }

  /// Recalculate and apply progression targets for an exercise.
  /// Works in DISPLAY units to avoid kg/lbs rounding issues.
  /// Handles warmup sets with 50% weight and 6-12 rep clamping.
  void applyProgressionTargets(int exerciseIndex, SetProgressionPattern pattern) {
    final exercise = exercises[exerciseIndex];
    debugPrint('🎯 [ApplyTargets] ENTER: ex=$exerciseIndex "${exercise.name}", pattern=${pattern.displayName}, '
        'exercise.weight=${exercise.weight}, equipment=${exercise.equipment}, setTargets=${exercise.setTargets?.length ?? 0}');

    final eq = (exercise.equipment ?? '').toLowerCase();
    if (eq.contains('bodyweight') || eq.contains('body weight')) {
      debugPrint('🎯 [ApplyTargets] SKIP — bodyweight exercise (equipment=$eq)');
      return;
    }

    final incrementState = ref.read(weightIncrementsProvider);
    final incrementRaw = incrementState.getIncrement(exercise.equipment);
    final incrementUnit = incrementState.unit;
    final double effectiveIncrement;
    if (useKg && incrementUnit == 'lbs') {
      effectiveIncrement = incrementRaw * 0.453592;
    } else if (!useKg && incrementUnit == 'kg') {
      effectiveIncrement = (incrementRaw * 2.20462).roundToDouble();
    } else {
      effectiveIncrement = incrementRaw;
    }

    final controllerWeight = exerciseIndex == currentExerciseIndex
        ? (double.tryParse(weightController.text) ?? 0)
        : 0.0;
    double displayWeight;
    if (controllerWeight > 0) {
      displayWeight = controllerWeight;
      debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from controller: $displayWeight');
    } else {
      final aiWeight = exercise.weight?.toDouble() ?? 0;
      if (aiWeight > 0) {
        displayWeight = useKg
            ? aiWeight
            : kgToDisplayLbs(aiWeight, exercise.equipment,
                exerciseName: exercise.name,);
        debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from exercise.weight: $aiWeight kg → display=$displayWeight');
      } else {
        final workingTarget = exercise.setTargets?.cast<SetTarget?>().firstWhere(
          (t) => t != null && t.setType.toLowerCase() != 'warmup' && (t.targetWeightKg ?? 0) > 0,
          orElse: () => exercise.setTargets?.isNotEmpty == true ? exercise.setTargets!.first : null,
        );
        final targetWt = workingTarget?.targetWeightKg ?? 0;
        if (targetWt > 0) {
          displayWeight = useKg
              ? targetWt
              : kgToDisplayLbs(targetWt, exercise.equipment,
                exerciseName: exercise.name,);
          debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from setTarget: $targetWt → display=$displayWeight');
        } else {
          displayWeight = getDefaultWeight(exercise.equipment,
              exerciseName: exercise.name,
              fitnessLevel: ref.read(authStateProvider).user?.fitnessLevel,
              gender: ref.read(authStateProvider).user?.gender,
              useKg: useKg);
          debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from getDefaultWeight: $displayWeight');
        }
      }
    }

    if (displayWeight <= 0) {
      debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex SKIP — bodyweight (displayWeight=0)');
      return;
    }

    final enteredWeight = effectiveIncrement > 0
        ? (displayWeight / effectiveIncrement).round() * effectiveIncrement
        : displayWeight;

    final baseReps = exercise.reps ?? 10;
    final totalSets = totalSetsPerExercise[exerciseIndex] ?? 3;

    final workingWeight = pattern.deriveWorkingWeight(
      enteredWeight: enteredWeight,
      totalSets: totalSets,
      increment: effectiveIncrement,
    );
    exerciseWorkingWeight[exerciseIndex] = workingWeight;

    final userGoal = ref.read(authStateProvider).user?.primaryGoal;
    final exTypeForCap = FatigueService.getExerciseType(exercise.muscleGroup, exercise.name);
    final int maxRepsForCap;
    if (pattern == SetProgressionPattern.endurance) {
      maxRepsForCap = exTypeForCap == 'compound' ? 15 : exTypeForCap == 'bodyweight' ? 30 : 25;
    } else {
      maxRepsForCap = exTypeForCap == 'compound' ? 12 : exTypeForCap == 'bodyweight' ? 20 : 15;
    }

    final targets = pattern.generateTargets(
      workingWeight: workingWeight,
      totalSets: totalSets,
      baseReps: baseReps,
      increment: effectiveIncrement,
      trainingGoal: userGoal,
      maxReps: maxRepsForCap,
    );

    final currentSetTargets = List<SetTarget>.from(exercise.setTargets ?? []);
    while (currentSetTargets.length < totalSets) {
      currentSetTargets.add(SetTarget(
        setNumber: currentSetTargets.length + 1,
        targetReps: baseReps,
        targetWeightKg: _displayToKg(workingWeight),
      ));
    }

    final completedCount = completedSets[exerciseIndex]?.length ?? 0;

    for (int i = completedCount; i < targets.length && i < currentSetTargets.length; i++) {
      final pt = targets[i];
      final isWarmupSet = currentSetTargets[i].setType.toLowerCase() == 'warmup';

      double targetWeight;
      int targetReps;

      if (isWarmupSet) {
        targetWeight = targets.first.weight * 0.5;
        final range = getWeightRange(exercise.equipment, exerciseName: exercise.name);
        final warmupStep = useKg ? range.stepKg : range.stepLbs;
        final minWeight = useKg ? range.minKg : range.minLbs;
        if (warmupStep > 0) {
          final upperBound = targets.first.weight > minWeight ? targets.first.weight : minWeight;
          targetWeight = ((targetWeight / warmupStep).round() * warmupStep)
              .clamp(minWeight, upperBound);
        }
        targetReps = (pt.reps > 0 ? pt.reps : baseReps).clamp(6, 12);
      } else {
        targetWeight = pt.weight;
        targetReps = pt.isAmrap ? 0 : pt.reps;
      }

      // Snap to valid equipment weight (e.g., barbell 5 lb steps from 45)
      targetWeight = snapToRealIncrement(targetWeight, exercise.equipment,
          exerciseName: exercise.name, useKg: useKg);

      // Convert display-unit weight back to kg for storage — display layer
      // converts kg→display, so storing lbs would cause double-conversion
      currentSetTargets[i] = SetTarget(
        setNumber: i + 1,
        setType: isWarmupSet ? 'warmup' : (pt.isAmrap ? 'amrap' : currentSetTargets[i].setType),
        targetReps: targetReps,
        targetWeightKg: _displayToKg(targetWeight),
        targetRir: pt.rir ?? currentSetTargets[i].targetRir,
      );
    }

    _setState(() {
      exercises[exerciseIndex] = exercise.copyWith(setTargets: currentSetTargets);
    });

    if (completedCount < targets.length) {
      final isWarmup = currentSetTargets.length > completedCount &&
          currentSetTargets[completedCount].setType.toLowerCase() == 'warmup';

      final double weight;
      final int reps;
      if (isWarmup) {
        final warmupTarget = currentSetTargets[completedCount];
        weight = warmupTarget.targetWeightKg ?? 0;
        reps = warmupTarget.targetReps;
      } else {
        final pt = targets[completedCount];
        weight = snapToRealIncrement(pt.weight, exercise.equipment,
            exerciseName: exercise.name, useKg: useKg);
        reps = pt.reps;
      }

      weightController.text = weight > 0
          ? weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1) : '';
      repsController.text = reps > 0 ? reps.toString() : '';
      repsRightController.text = repsController.text;
    }
  }


  /// Update weight/reps controllers for the next set based on progression pattern.
  void updateControlsForNextSet(WorkoutExercise exercise, int completedCount) {
    final pattern = exerciseProgressionPattern[currentExerciseIndex]
        ?? SetProgressionPattern.pyramidUp;

    final incrementState = ref.read(weightIncrementsProvider);
    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;

    final completedLogs = completedSets[currentExerciseIndex];

    SetLog? lastWorkingLog;
    if (completedLogs != null) {
      for (int i = completedLogs.length - 1; i >= 0; i--) {
        final setTargets = exercise.setTargets;
        final isWarmup = setTargets != null && i < setTargets.length &&
            setTargets[i].setType.toLowerCase() == 'warmup';
        if (!isWarmup) {
          lastWorkingLog = completedLogs[i];
          break;
        }
      }
    }

    if (lastWorkingLog == null) {
      debugPrint('📊 [NextSet] No working sets completed yet — delegating to initControllersForExercise');
      initControllersForExercise(currentExerciseIndex);
      return;
    }

    final actualWeightKg = lastWorkingLog.weight;
    final actualWeight = useKg
        ? actualWeightKg
        : kgToDisplayLbs(actualWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
    if (actualWeight <= 0) return;

    final incrementRaw = incrementState.getIncrement(exercise.equipment);
    final incrementUnit = incrementState.unit;
    final double effectiveIncrement;
    if (useKg && incrementUnit == 'lbs') {
      effectiveIncrement = incrementRaw * 0.453592;
    } else if (!useKg && incrementUnit == 'kg') {
      effectiveIncrement = (incrementRaw * 2.20462).roundToDouble();
    } else {
      effectiveIncrement = incrementRaw;
    }

    final snapped = effectiveIncrement > 0
        ? (actualWeight / effectiveIncrement).round() * effectiveIncrement
        : actualWeight;

    final completedIndex = (completedLogs?.length ?? 1) - 1;

    final workingWeight = pattern.deriveWorkingWeight(
      enteredWeight: snapped,
      totalSets: totalSets,
      increment: effectiveIncrement,
      completedSetIndex: completedIndex,
    );
    exerciseWorkingWeight[currentExerciseIndex] = workingWeight;

    final userGoal = ref.read(authStateProvider).user?.primaryGoal;
    final rawBaseReps = (lastWorkingLog.reps).clamp(1, 30);
    final baseReps = SetProgressionPatternX.reverseRepOffset(
      pattern, rawBaseReps, completedIndex, totalSets,
    );

    final exType = FatigueService.getExerciseType(exercise.muscleGroup, exercise.name);
    final int maxReps;
    if (pattern == SetProgressionPattern.endurance) {
      maxReps = exType == 'compound' ? 15 : exType == 'bodyweight' ? 30 : 25;
    } else {
      maxReps = exType == 'compound' ? 12 : exType == 'bodyweight' ? 20 : 15;
    }

    var targets = pattern.generateTargets(
      workingWeight: workingWeight,
      totalSets: totalSets,
      baseReps: baseReps,
      increment: effectiveIncrement,
      trainingGoal: userGoal,
      maxReps: maxReps,
    );

    final completedSetLogs = completedSets[currentExerciseIndex];
    final nextIdx = completedSetLogs?.length ?? 0;
    final originalNextWeight = nextIdx < targets.length ? targets[nextIdx].weight : null;

    if (completedSetLogs != null && completedSetLogs.isNotEmpty) {
      final setTargetsRef = exercise.setTargets;
      final completedData = <CompletedSetData>[];
      for (int i = 0; i < completedSetLogs.length; i++) {
        final log = completedSetLogs[i];
        if (setTargetsRef != null && i < setTargetsRef.length &&
            setTargetsRef[i].setType.toLowerCase() == 'warmup') {
          continue;
        }
        completedData.add(CompletedSetData(
          weight: useKg
              ? log.weight
              : kgToDisplayLbs(log.weight, exercise.equipment,
                exerciseName: exercise.name,),
          reps: log.reps,
          rir: log.rir,
        ));
      }

      targets = adaptTargets(
        pattern: pattern,
        originalTargets: targets,
        completedSets: completedData,
        increment: effectiveIncrement,
        totalSets: totalSets,
      );

      final currentSetTargets = List<SetTarget>.from(exercise.setTargets ?? []);
      while (currentSetTargets.length < totalSets) {
        currentSetTargets.add(SetTarget(
          setNumber: currentSetTargets.length + 1,
          targetReps: baseReps,
          targetWeightKg: _displayToKg(workingWeight),
        ));
      }
      for (int i = completedCount; i < targets.length && i < currentSetTargets.length; i++) {
        final pt = targets[i];
        final snappedWeight = snapToRealIncrement(pt.weight, exercise.equipment,
            exerciseName: exercise.name, useKg: useKg);
        currentSetTargets[i] = SetTarget(
          setNumber: i + 1,
          setType: pt.isAmrap ? 'amrap' : currentSetTargets[i].setType,
          targetReps: pt.isAmrap ? 0 : pt.reps,
          targetWeightKg: _displayToKg(snappedWeight),
          targetRir: currentSetTargets[i].targetRir,
        );
      }
      _setState(() {
        exercises[currentExerciseIndex] = exercise.copyWith(setTargets: currentSetTargets);
      });
    }

    final nextSetIndex = completedCount;
    if (nextSetIndex >= targets.length) return;

    final nextTarget = targets[nextSetIndex];

    final currentControllerWeight = double.tryParse(weightController.text) ?? 0;
    final previousSetWeightKg = completedSets[currentExerciseIndex]?.last.weight ?? 0;
    final previousSetWeight = useKg
        ? previousSetWeightKg
        : kgToDisplayLbs(previousSetWeightKg, exercise.equipment,
                exerciseName: exercise.name,);

    if ((currentControllerWeight - previousSetWeight).abs() > 0.01) {
      if (!nextTarget.isAmrap) {
        repsController.text = nextTarget.reps.toString();
        repsRightController.text = nextTarget.reps.toString();
      }
      return;
    }

    final displayWeightVal = snapToRealIncrement(
      effectiveIncrement > 0
          ? (nextTarget.weight / effectiveIncrement).round() * effectiveIncrement
          : nextTarget.weight,
      exercise.equipment,
      exerciseName: exercise.name,
      useKg: useKg,
    );
    weightController.text = displayWeightVal.toStringAsFixed(1);

    if (nextTarget.isAmrap) {
      repsController.text = '';
      repsRightController.text = '';
    } else {
      repsController.text = nextTarget.reps.toString();
      repsRightController.text = nextTarget.reps.toString();
    }

    if (originalNextWeight != null && _mounted) {
      final diff = nextTarget.weight - originalNextWeight;
      if (diff.abs() > 0.01) {
        final unit = useKg ? 'kg' : 'lb';
        final fromDisplay = useKg
            ? originalNextWeight
            : kgToDisplayLbs(originalNextWeight, exercise.equipment,
                exerciseName: exercise.name,);
        final toDisplay = useKg
            ? nextTarget.weight
            : kgToDisplayLbs(nextTarget.weight, exercise.equipment,
                exerciseName: exercise.name,);
        final arrow = diff > 0 ? '↑' : '↓';
        ScaffoldMessenger.of(_ctx).showSnackBar(
          SnackBar(
            content: Text(
              'Weight $arrow ${fromDisplay.toStringAsFixed(0)} → ${toDisplay.toStringAsFixed(0)} $unit',
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: diff > 0 ? AppColors.success : WorkoutDesign.rir2,
          ),
        );
      }
    }
  }

}
