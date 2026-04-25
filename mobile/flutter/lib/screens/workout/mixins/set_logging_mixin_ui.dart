part of 'set_logging_mixin.dart';

/// Extension providing additional set logging UI methods
extension SetLoggingMixinUI on SetLoggingMixin {

  // ── Helpers to access State<T> members through the mixin ──
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
  void applyProgressionTargets(int exerciseIndex, SetProgressionPattern pattern, {double? overrideWeight}) {
    final exercise = exercises[exerciseIndex];
    debugPrint('🎯 [ApplyTargets] ENTER: ex=$exerciseIndex "${exercise.name}", pattern=${pattern.displayName}, '
        'exercise.weight=${exercise.weight}, equipment=${exercise.equipment}, setTargets=${exercise.setTargets?.length ?? 0}, overrideWeight=$overrideWeight');

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

    double displayWeight;
    if (overrideWeight != null && overrideWeight > 0) {
      // Explicit correct weight from caller — bypasses controller entirely
      displayWeight = overrideWeight;
      debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from override: $displayWeight');
    } else {
      // Safety net: if current set is a warmup, the controller has the
      // warmup-halved weight — skip it and use exercise.weight instead.
      final completedCount = completedSets[exerciseIndex]?.length ?? 0;
      final currentSetTarget = exercise.setTargets != null && completedCount < exercise.setTargets!.length
          ? exercise.setTargets![completedCount] : null;
      final isOnWarmupSet = currentSetTarget?.isWarmup ?? false;

      final controllerWeight = (!isOnWarmupSet && exerciseIndex == currentExerciseIndex)
          ? (double.tryParse(weightController.text) ?? 0)
          : 0.0;

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
          debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from exercise.weight: $aiWeight kg → display=$displayWeight${isOnWarmupSet ? ' (warmup safety net)' : ''}');
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
                fitnessLevel: ref.read(authStateProvider).user?.effectiveFitnessLevel,
                gender: ref.read(authStateProvider).user?.gender,
                useKg: useKg);
            debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex weight from getDefaultWeight: $displayWeight');
          }
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

    final currentSetTargets = List<SetTarget>.from(exercise.setTargets ?? []);
    while (currentSetTargets.length < totalSets) {
      currentSetTargets.add(SetTarget(
        setNumber: currentSetTargets.length + 1,
        targetReps: baseReps,
        targetWeightKg: _displayToKg(enteredWeight),
      ));
    }

    // Count working sets (exclude warmups) so pyramid targets are generated
    // for working sets only. Without this, the warmup position consumes a
    // pyramid slot and the first working set starts one increment above the
    // entered weight instead of AT the entered weight.
    final warmupCount = currentSetTargets.where(
        (t) => t.setType.toLowerCase() == 'warmup').length;
    final workingSets = totalSets - warmupCount;
    final effectiveSetsForTargets = workingSets > 0 ? workingSets : totalSets;

    final workingWeight = pattern.deriveWorkingWeight(
      enteredWeight: enteredWeight,
      totalSets: effectiveSetsForTargets,
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
      totalSets: effectiveSetsForTargets,
      baseReps: baseReps,
      increment: effectiveIncrement,
      trainingGoal: userGoal,
      maxReps: maxRepsForCap,
      exerciseType: exTypeForCap,
      fitnessLevel: ref.read(authStateProvider).user?.effectiveFitnessLevel,
      equipment: exercise.equipment,
    );

    debugPrint('⚙️ [ApplyTargets] ex=$exerciseIndex totalSets=$totalSets, warmups=$warmupCount, '
        'workingSets=$effectiveSetsForTargets, targets=${targets.length}, enteredWeight=$enteredWeight, workingWeight=$workingWeight');

    final completedCount = completedSets[exerciseIndex]?.length ?? 0;

    // Map targets (generated for working sets only) to set positions.
    // Warmup sets get 50% of the first working target's weight.
    // Working sets get their targets in order.
    int workingTargetIdx = 0;
    // Count how many working sets were already completed to start the target index correctly
    for (int i = 0; i < completedCount && i < currentSetTargets.length; i++) {
      if (currentSetTargets[i].setType.toLowerCase() != 'warmup') {
        workingTargetIdx++;
      }
    }

    for (int i = completedCount; i < currentSetTargets.length; i++) {
      final isWarmupSet = currentSetTargets[i].setType.toLowerCase() == 'warmup';

      double targetWeight;
      int targetReps;
      int? targetRir;

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
        targetReps = baseReps.clamp(6, 12);
        targetRir = currentSetTargets[i].targetRir;
      } else if (workingTargetIdx < targets.length) {
        final pt = targets[workingTargetIdx];
        targetWeight = pt.weight;
        targetReps = pt.isAmrap ? 0 : pt.reps;
        targetRir = pt.rir ?? currentSetTargets[i].targetRir;
        workingTargetIdx++;
      } else {
        // More working sets than targets — use last target
        final pt = targets.last;
        targetWeight = pt.weight;
        targetReps = pt.isAmrap ? 0 : pt.reps;
        targetRir = pt.rir ?? currentSetTargets[i].targetRir;
      }

      // Snap to valid equipment weight (e.g., barbell 5 lb steps from 45)
      targetWeight = snapToRealIncrement(targetWeight, exercise.equipment,
          exerciseName: exercise.name, useKg: useKg);

      // Convert display-unit weight back to kg for storage — display layer
      // converts kg→display, so storing lbs would cause double-conversion
      currentSetTargets[i] = SetTarget(
        setNumber: i + 1,
        setType: isWarmupSet ? 'warmup' : (workingTargetIdx <= targets.length && workingTargetIdx > 0 && targets[workingTargetIdx - 1].isAmrap ? 'amrap' : currentSetTargets[i].setType),
        targetReps: targetReps,
        targetWeightKg: _displayToKg(targetWeight),
        targetRir: targetRir,
      );
    }

    _setState(() {
      exercises[exerciseIndex] = exercise.copyWith(setTargets: currentSetTargets);
    });

    if (completedCount < currentSetTargets.length) {
      final isWarmup = currentSetTargets[completedCount].setType.toLowerCase() == 'warmup';

      final double weight;
      final int reps;
      if (isWarmup) {
        final warmupTarget = currentSetTargets[completedCount];
        final rawKg = warmupTarget.targetWeightKg ?? 0;
        weight = useKg ? rawKg : kgToDisplayLbs(rawKg, exercise.equipment, exerciseName: exercise.name);
        reps = warmupTarget.targetReps;
      } else {
        // Find the first uncompleted working target
        int firstWorkingIdx = 0;
        for (int i = 0; i < completedCount && i < currentSetTargets.length; i++) {
          if (currentSetTargets[i].setType.toLowerCase() != 'warmup') {
            firstWorkingIdx++;
          }
        }
        if (firstWorkingIdx < targets.length) {
          final pt = targets[firstWorkingIdx];
          weight = snapToRealIncrement(pt.weight, exercise.equipment,
              exerciseName: exercise.name, useKg: useKg);
          reps = pt.reps;
        } else {
          weight = snapToRealIncrement(targets.last.weight, exercise.equipment,
              exerciseName: exercise.name, useKg: useKg);
          reps = targets.last.reps;
        }
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
      if (completedLogs != null && completedLogs.isNotEmpty) {
        // Warmups completed but no working sets yet. Check if the user
        // significantly overrode the warmup target (e.g., did 20kg when
        // target was 3kg) — if so, recalculate targets using their actual weight.
        final lastLog = completedLogs.last;
        final actualWeightKg = lastLog.weight;
        final actualWeight = useKg
            ? actualWeightKg
            : kgToDisplayLbs(actualWeightKg, exercise.equipment,
                exerciseName: exercise.name);

        final lastLogIdx = completedLogs.length - 1;
        final warmupTargetKg = exercise.setTargets != null && lastLogIdx < exercise.setTargets!.length
            ? (exercise.setTargets![lastLogIdx].targetWeightKg ?? 0.0) : 0.0;

        if (warmupTargetKg > 0 && actualWeightKg > warmupTargetKg * 1.3) {
          // User used significantly heavier weight than warmup target — recalculate
          debugPrint('📊 [NextSet] Warmup override detected: actual=${actualWeightKg}kg vs target=${warmupTargetKg}kg — recalculating');
          applyProgressionTargets(currentExerciseIndex, pattern, overrideWeight: actualWeight);
        }

        // Advance controller to the next set's target (original or recalculated)
        final updatedExercise = exercises[currentExerciseIndex];
        final nextSetIndex = completedLogs.length;
        if (updatedExercise.setTargets != null && nextSetIndex < updatedExercise.setTargets!.length) {
          final nextTarget = updatedExercise.setTargets![nextSetIndex];
          final nextWeightKg = nextTarget.targetWeightKg ?? 0;
          if (nextWeightKg > 0) {
            final nextDisplayWeight = useKg
                ? nextWeightKg
                : kgToDisplayLbs(nextWeightKg, exercise.equipment,
                    exerciseName: exercise.name);
            weightController.text = nextDisplayWeight.toStringAsFixed(
                nextDisplayWeight % 1 == 0 ? 0 : 1);
            repsController.text = (nextTarget.targetReps > 0
                ? nextTarget.targetReps
                : (exercise.reps ?? 10)).toString();
            repsRightController.text = repsController.text;
            debugPrint('📊 [NextSet] Warmup done — controller set to set ${nextSetIndex + 1}: $nextDisplayWeight');
            return;
          }
        }
      }
      // True fallback: no completed logs at all
      debugPrint('📊 [NextSet] No completed logs — delegating to initControllersForExercise');
      initControllersForExercise(currentExerciseIndex);
      return;
    }

    final actualWeightKg = lastWorkingLog.weight;
    final actualWeight = useKg
        ? actualWeightKg
        : kgToDisplayLbs(actualWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
    if (actualWeight <= 0) {
      // Bodyweight exercise: there's no load to progress, but we still
      // want the reps controller to advance to the next set's target
      // (e.g. 10 → 12 → 13 from the pyramid pattern) instead of leaving
      // the previous set's reps stuck in the input.
      final setTargets = exercise.setTargets;
      final nextSetIdx = completedCount;
      if (setTargets != null && nextSetIdx < setTargets.length) {
        final nextTarget = setTargets[nextSetIdx];
        final reps = nextTarget.targetReps > 0
            ? nextTarget.targetReps
            : (exercise.reps ?? lastWorkingLog.reps);
        repsController.text = reps.toString();
        repsRightController.text = reps.toString();
      }
      return;
    }

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

    // Count working sets (exclude warmups) for correct pyramid calculation
    final setTargetsRef = exercise.setTargets;
    final warmupCount = setTargetsRef != null
        ? setTargetsRef.where((t) => t.setType.toLowerCase() == 'warmup').length : 0;
    final workingSets = totalSets - warmupCount;
    final effectiveSetsForTargets = workingSets > 0 ? workingSets : totalSets;

    // Compute the working-set index of the last completed working set
    int completedWorkingIndex = 0;
    if (completedLogs != null) {
      for (int i = 0; i < completedLogs.length; i++) {
        final isWarmup = setTargetsRef != null && i < setTargetsRef.length &&
            setTargetsRef[i].setType.toLowerCase() == 'warmup';
        if (!isWarmup) completedWorkingIndex++;
      }
      completedWorkingIndex = (completedWorkingIndex - 1).clamp(0, effectiveSetsForTargets - 1);
    }

    final workingWeight = pattern.deriveWorkingWeight(
      enteredWeight: snapped,
      totalSets: effectiveSetsForTargets,
      increment: effectiveIncrement,
      completedSetIndex: completedWorkingIndex,
    );
    exerciseWorkingWeight[currentExerciseIndex] = workingWeight;

    final userGoal = ref.read(authStateProvider).user?.primaryGoal;
    final rawBaseReps = (lastWorkingLog.reps).clamp(1, 30);
    final baseReps = SetProgressionPatternX.reverseRepOffset(
      pattern, rawBaseReps, completedWorkingIndex, effectiveSetsForTargets,
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
      totalSets: effectiveSetsForTargets,
      baseReps: baseReps,
      increment: effectiveIncrement,
      trainingGoal: userGoal,
      maxReps: maxReps,
      exerciseType: exType,
      fitnessLevel: ref.read(authStateProvider).user?.effectiveFitnessLevel,
      equipment: exercise.equipment,
    );

    final completedSetLogs = completedSets[currentExerciseIndex];

    if (completedSetLogs != null && completedSetLogs.isNotEmpty) {
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

      final adaptResult = adaptTargetsWithFeedback(
        pattern: pattern,
        originalTargets: targets,
        completedSets: completedData,
        increment: effectiveIncrement,
        totalSets: effectiveSetsForTargets,
      );
      targets = adaptResult.targets;

      // Store adaptation feedback for inline rest row display
      if (_mounted) {
        _setState(() {
          (this as dynamic).inlineRestAdaptationFeedback = adaptResult.feedback;
        });
      }

      final currentSetTargets = List<SetTarget>.from(exercise.setTargets ?? []);
      while (currentSetTargets.length < totalSets) {
        currentSetTargets.add(SetTarget(
          setNumber: currentSetTargets.length + 1,
          targetReps: baseReps,
          targetWeightKg: _displayToKg(workingWeight),
        ));
      }
      // Map working-set targets to the correct positions (skip warmups)
      int workingTargetIdx = 0;
      for (int i = 0; i < completedCount && i < currentSetTargets.length; i++) {
        if (currentSetTargets[i].setType.toLowerCase() != 'warmup') {
          workingTargetIdx++;
        }
      }
      for (int i = completedCount; i < currentSetTargets.length; i++) {
        final isWarmup = currentSetTargets[i].setType.toLowerCase() == 'warmup';
        if (isWarmup) continue; // Don't overwrite warmup targets
        if (workingTargetIdx >= targets.length) break;
        final pt = targets[workingTargetIdx];
        final snappedWeight = snapToRealIncrement(pt.weight, exercise.equipment,
            exerciseName: exercise.name, useKg: useKg);
        currentSetTargets[i] = SetTarget(
          setNumber: i + 1,
          setType: pt.isAmrap ? 'amrap' : currentSetTargets[i].setType,
          targetReps: pt.isAmrap ? 0 : pt.reps,
          targetWeightKg: _displayToKg(snappedWeight),
          targetRir: currentSetTargets[i].targetRir,
        );
        workingTargetIdx++;
      }
      _setState(() {
        exercises[currentExerciseIndex] = exercise.copyWith(setTargets: currentSetTargets);
      });
    }

    // Find the next working set's target
    int nextWorkingIdx = 0;
    for (int i = 0; i < completedCount; i++) {
      final isWarmup = setTargetsRef != null && i < setTargetsRef.length &&
          setTargetsRef[i].setType.toLowerCase() == 'warmup';
      if (!isWarmup) nextWorkingIdx++;
    }
    if (nextWorkingIdx >= targets.length) return;

    final nextTarget = targets[nextWorkingIdx];

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

    // Weight change feedback now shown via inline adaptation chip (InlineRestRow)
    // instead of SnackBar — always visible in rest row, positioned in context.
  }

}
