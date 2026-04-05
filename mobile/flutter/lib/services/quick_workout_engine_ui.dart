part of 'quick_workout_engine.dart';

/// Methods extracted from QuickWorkoutEngine
extension _QuickWorkoutEngineExt on QuickWorkoutEngine {
  /// Generate a complete quick workout.
  ///
  /// Returns a [Workout] object fully compatible with the server format,
  /// ready for immediate use in the workout execution screen.
  Workout generate({
    required String userId,
    required int durationMinutes,
    String? focus,
    String difficulty = 'medium',
    String? mood,
    bool useSupersets = true,
    List<String> equipment = const [],
    List<String> injuries = const [],
    required List<OfflineExercise> exerciseLibrary,
    String fitnessLevel = 'intermediate',
    Map<String, double> oneRepMaxes = const {},
    List<String> stapleExercises = const [],
    List<String> avoidedExercises = const [],
    Set<String> recentlyUsedExercises = const {},
    EquipmentContext? equipmentContext,
    String? goal,
    Map<String, double> muscleRecoveryScores = const {},
    Map<String, int> sessionsSinceLastUse = const {},
    Map<String, ExerciseRpeSummary> rpeFeedback = const {},
    Map<String, int> weeklyVolume = const {},
    Map<String, VolumeLandmarks> volumeLandmarks = const {},
    MesocycleContext? mesocycleContext,
    Map<String, double> collaborativeScores = const {},
    Map<String, double> sfrScores = const {},
    HrvRecoveryModifiers? hrvModifiers,
  }) {
    // =====================================================================
    // Phase 1: Preparation
    // =====================================================================
    final effectiveFocus = focus ?? 'full_body';
    final diffMult = QuickWorkoutConstants.difficultyMultipliers[difficulty] ??
        QuickWorkoutConstants.difficultyMultipliers['medium']!;
    final effectiveGoal = goal ?? 'hypertrophy';
    final effectiveFitnessLevel = fitnessLevel;

    // Expand injuries → avoided muscles
    final avoidedMuscles = expandInjuriesToMuscles(injuries);

    // Force format constraints
    var effectiveSupersets = useSupersets;
    if (effectiveFocus == 'cardio' || effectiveFocus == 'stretch') {
      effectiveSupersets = false;
    }

    // Strategy dispatch
    final strategy = focusStrategies[effectiveFocus] ??
        focusStrategies['full_body']!;

    // Mood multipliers
    double volumeMultiplier = diffMult.volume;
    double restMultiplier = diffMult.rest;
    double intensityMultiplier = 1.0;
    String? exerciseBias;
    if (mood != null) {
      final moodMult = QuickWorkoutConstants.moodMultipliers[mood];
      if (moodMult != null) {
        volumeMultiplier *= moodMult.volume;
        restMultiplier *= moodMult.rest;
        intensityMultiplier = moodMult.intensity;
        exerciseBias = moodMult.exerciseBias;
      }
    }

    // Phase 1 — Global RPE intensity modifier
    if (rpeFeedback.isNotEmpty) {
      final globalAvgRpe = RpeFeedbackService.computeGlobalAvgRpe(rpeFeedback);
      if (globalAvgRpe > 9.0) {
        intensityMultiplier *= 0.85;
        volumeMultiplier *= 0.80;
      } else if (globalAvgRpe > 8.5) {
        intensityMultiplier *= 0.92;
      } else if (globalAvgRpe < 6.5) {
        intensityMultiplier *= 1.05;
        volumeMultiplier *= 1.05;
      }
    }

    // Mesocycle intensity override
    if (mesocycleContext != null) {
      intensityMultiplier *= mesocycleContext.intensityMultiplier;
    }

    // HRV/sleep recovery modifiers (Feature 4)
    if (hrvModifiers != null && hrvModifiers.hasData) {
      volumeMultiplier *= hrvModifiers.volumeMultiplier;
      intensityMultiplier *= hrvModifiers.intensityMultiplier;
    }

    // RPE floor for very short workouts — ensure sufficient stimulus
    final rpeFloor = durationMinutes < 10 ? 6 : 0;

    // =====================================================================
    // Phase 2: Time Budget
    // =====================================================================
    final totalBudgetSeconds = durationMinutes * 60;
    final warmupSeconds = QuickWorkoutConstants.getWarmupSeconds(durationMinutes);
    const bufferSeconds = 45;
    final workingBudget = totalBudgetSeconds - warmupSeconds - bufferSeconds;

    // Get format
    final format = strategy.getFormat(effectiveSupersets, durationMinutes);

    // Base sets for this duration + difficulty
    final baseSets = QuickWorkoutConstants.getBaseSets(durationMinutes, difficulty);

    // Adjust sets by volume multiplier
    final adjustedSets = (baseSets * volumeMultiplier).round().clamp(1, 5);

    // =====================================================================
    // Phase 3: Exercise Selection
    // =====================================================================
    final slots = strategy.getSlots(durationMinutes);
    final selectedExercises = <_SelectedExercise>[];
    final alreadySelectedNames = <String>{};
    int runningTime = 0;

    // Equipment handling: empty = bodyweight only (not "all allowed")
    final effectiveEquipment = equipment.isEmpty
        ? ['bodyweight']
        : equipment;

    // Build previously performed set from 1RM data
    final previouslyPerformed =
        oneRepMaxes.keys.map((k) => k.toLowerCase()).toSet();

    // Determine if we should prefer unilateral exercises
    // (any pair-type equipment has only quantity 1)
    bool preferUnilateral = false;
    if (equipmentContext != null && equipmentContext.hasDetailedInventory) {
      for (final entry in equipmentContext.inventory.entries) {
        final inv = entry.value;
        if (inv.isPairType) {
          // Check if ALL weights have quantity < 2
          final allSingle = inv.weightToQuantity.values.every((qty) => qty < 2);
          if (allSingle && inv.weightToQuantity.isNotEmpty) {
            preferUnilateral = true;
            break;
          }
        }
      }
    }

    // Muscle recovery: deprioritize muscles below 60% recovery
    var effectiveSlots = slots;
    if (muscleRecoveryScores.isNotEmpty) {
      // Sort slots: recovered muscles first, fatigued muscles last
      final sortedSlots = List<QuickMuscleSlot>.from(slots);
      sortedSlots.sort((a, b) {
        final scoreA = muscleRecoveryScores[a.muscle.toLowerCase()] ?? 100.0;
        final scoreB = muscleRecoveryScores[b.muscle.toLowerCase()] ?? 100.0;
        return scoreB.compareTo(scoreA); // Higher recovery = earlier in list
      });
      effectiveSlots = sortedSlots;
    }

    // Volume landmark sorting: muscles below MEV first, near MRV last
    if (volumeLandmarks.isNotEmpty && weeklyVolume.isNotEmpty) {
      final sortedSlots = List<QuickMuscleSlot>.from(effectiveSlots);
      sortedSlots.sort((a, b) {
        final muscleA = a.muscle.toLowerCase();
        final muscleB = b.muscle.toLowerCase();
        final landmarkA = volumeLandmarks[muscleA];
        final landmarkB = volumeLandmarks[muscleB];
        if (landmarkA == null || landmarkB == null) return 0;
        final volA = weeklyVolume[muscleA] ?? 0;
        final volB = weeklyVolume[muscleB] ?? 0;
        final statusA = VolumeLandmarkService.getVolumeStatus(volA, landmarkA);
        final statusB = VolumeLandmarkService.getVolumeStatus(volB, landmarkB);
        return statusA.index.compareTo(statusB.index); // belowMev first
      });
      effectiveSlots = sortedSlots;
    }

    for (final slot in effectiveSlots) {
      // Calculate time cost for this exercise
      final cost = strategy.timeCostPerExercise(difficulty, effectiveSupersets);

      // Budget check
      if (runningTime + cost > workingBudget) break;

      // Select exercise for this slot
      final exercise = _selectExerciseForSlot(
        slot: slot,
        library: exerciseLibrary,
        effectiveEquipment: effectiveEquipment,
        avoidedExercises: avoidedExercises,
        avoidedMuscles: avoidedMuscles,
        effectiveFitnessLevel: effectiveFitnessLevel,
        stapleExercises: stapleExercises,
        previouslyPerformed: previouslyPerformed,
        alreadySelectedNames: alreadySelectedNames,
        recentlyUsedExercises: recentlyUsedExercises,
        exerciseBias: exerciseBias,
        focus: effectiveFocus,
        equipmentContext: equipmentContext,
        preferUnilateral: preferUnilateral,
        sessionsSinceLastUse: sessionsSinceLastUse,
        collaborativeScores: collaborativeScores,
        sfrScores: sfrScores,
      );

      if (exercise == null) continue;

      alreadySelectedNames.add((exercise.name ?? '').toLowerCase());
      selectedExercises.add(_SelectedExercise(
        exercise: exercise,
        slot: slot,
        timeCost: cost,
      ));
      runningTime += cost;
    }

    // Minimum exercise check for severe injury scenarios
    if (selectedExercises.length < 2) {
      // Try adding from fallback pools
      _addFallbackExercises(
        selectedExercises,
        effectiveFocus,
        alreadySelectedNames,
        avoidedMuscles,
        difficulty,
      );
    }

    // Movement pattern diversity check
    if (effectiveFocus != 'cardio' && effectiveFocus != 'stretch' &&
        format != 'emom' && format != 'amrap') {
      final exerciseNames = selectedExercises
          .map((s) => s.exercise.name ?? '')
          .toList();
      final missing = getMissingPatterns(exerciseNames, durationMinutes);

      if (missing.isNotEmpty && selectedExercises.length >= 3) {
        // Try to swap the last exercise for one matching a missing pattern
        final targetMuscle = patternToMuscle(missing.first);
        final replacement = _selectExerciseForSlot(
          slot: QuickMuscleSlot(targetMuscle, preferCompound: true),
          library: exerciseLibrary,
          effectiveEquipment: effectiveEquipment,
          avoidedExercises: avoidedExercises,
          avoidedMuscles: avoidedMuscles,
          effectiveFitnessLevel: effectiveFitnessLevel,
          stapleExercises: stapleExercises,
          previouslyPerformed: previouslyPerformed,
          alreadySelectedNames: alreadySelectedNames,
          recentlyUsedExercises: recentlyUsedExercises,
          exerciseBias: exerciseBias,
          focus: effectiveFocus,
          equipmentContext: equipmentContext,
          preferUnilateral: preferUnilateral,
          sessionsSinceLastUse: sessionsSinceLastUse,
          collaborativeScores: collaborativeScores,
          sfrScores: sfrScores,
        );
        if (replacement != null) {
          selectedExercises[selectedExercises.length - 1] = _SelectedExercise(
            exercise: replacement,
            slot: QuickMuscleSlot(targetMuscle, preferCompound: true),
            timeCost: selectedExercises.last.timeCost,
          );
        }
      }
    }

    // =====================================================================
    // Phase 4: Set Target Generation
    // =====================================================================
    final workoutExercises = <WorkoutExercise>[];
    int supersetGroupCounter = 0;

    // Track which exercises are paired for supersets
    final pairedIndices = <int>{};

    for (int i = 0; i < selectedExercises.length; i++) {
      final sel = selectedExercises[i];
      final ex = sel.exercise;
      final isCompound = sel.slot.preferCompound;
      final exName = (ex.name ?? '').toLowerCase();
      final orm = oneRepMaxes[exName];

      List<SetTarget> setTargets;
      int? restSeconds;
      int? holdSeconds;
      int? durationSeconds;
      bool? isTimed;
      String? notes;
      int? supersetGroup;
      int? supersetOrder;

      if (format == 'flow') {
        // Stretch: hold-based targets
        final holdTime = difficulty == 'easy' ? 20 : (difficulty == 'hell' ? 45 : 30);
        setTargets = List.generate(
          adjustedSets.clamp(1, 2),
          (s) => SetTarget(
            setNumber: s + 1,
            setType: 'working',
            targetReps: 1,
            targetHoldSeconds: holdTime,
          ),
        );
        holdSeconds = holdTime;
        isTimed = true;
        restSeconds = 8;
        notes = 'Hold for ${holdTime}s, breathe deeply';
      } else if (format == 'hiit' || format == 'tabata') {
        // HIIT/Tabata: timed intervals
        final workTime = format == 'tabata' ? 20 : (difficulty == 'hell' ? 40 : 30);
        final restTime = format == 'tabata' ? 10 : (difficulty == 'easy' ? 30 : 20);
        final rounds = format == 'tabata' ? 8 : adjustedSets.clamp(2, 4);

        setTargets = List.generate(
          rounds,
          (s) => SetTarget(
            setNumber: s + 1,
            setType: 'working',
            targetReps: 1,
            targetHoldSeconds: workTime,
          ),
        );
        durationSeconds = workTime;
        isTimed = true;
        restSeconds = restTime;
        notes = format == 'tabata'
            ? 'Tabata: ${workTime}s max effort / ${restTime}s rest x $rounds'
            : 'HIIT: ${workTime}s all-out / ${restTime}s recovery x $rounds';
      } else if (format == 'circuit') {
        // Circuit: moderate work periods
        final workTime = 40;
        setTargets = List.generate(
          adjustedSets,
          (s) => SetTarget(
            setNumber: s + 1,
            setType: 'working',
            targetReps: 1,
            targetHoldSeconds: workTime,
          ),
        );
        durationSeconds = workTime;
        isTimed = true;
        restSeconds = (20 * restMultiplier).round();
        notes = 'Circuit: complete all exercises, rest ${restSeconds}s between rounds';
      } else if (format == 'emom') {
        // EMOM: prescribed reps + rest fills remainder of each minute
        final totalRounds = durationMinutes; // one round per minute
        final exerciseCount = selectedExercises.length;
        final roundsPerExercise = exerciseCount > 0 ? totalRounds ~/ exerciseCount : totalRounds;
        final baseReps = isCompound ? 8 : 12;
        // Fatigue reduction: -1 rep after round 8
        final effectiveReps = roundsPerExercise > 8 ? baseReps - 1 : baseReps;

        setTargets = List.generate(
          roundsPerExercise.clamp(1, 12),
          (s) => SetTarget(
            setNumber: s + 1,
            setType: 'working',
            targetReps: s >= 8 ? effectiveReps : baseReps,
          ),
        );
        durationSeconds = 60;
        isTimed = true;
        restSeconds = 0; // rest is whatever time remains in the minute
        notes = 'EMOM: Complete $baseReps reps, rest for remainder of the minute';
      } else if (format == 'amrap') {
        // AMRAP: all exercises in one round, cycle for duration
        final baseReps = isCompound ? 8 : 12;
        final estimatedRounds = (durationMinutes * 60) ~/
            (selectedExercises.length * 45); // ~45s per exercise per round

        setTargets = List.generate(
          estimatedRounds.clamp(2, 8),
          (s) => SetTarget(
            setNumber: s + 1,
            setType: 'working',
            targetReps: baseReps,
          ),
        );
        isTimed = true;
        restSeconds = 0; // minimal rest, keep moving
        notes = 'AMRAP: Complete as many rounds as possible in ${durationMinutes}min';
      } else {
        // Strength-style: use progressive overload
        setTargets = overload.generateSetTargets(
          exerciseName: ex.name ?? '',
          oneRepMax: orm,
          fitnessLevel: effectiveFitnessLevel,
          goal: effectiveGoal,
          isCompound: isCompound,
          equipment: ex.equipment,
        );

        // Override working sets count to match our duration-adjusted sets
        if (setTargets.length > adjustedSets + 1) {
          // Keep warmup (if any) + adjustedSets working sets
          final warmups = setTargets.where((t) => t.isWarmup).toList();
          final working = setTargets.where((t) => !t.isWarmup).take(adjustedSets).toList();
          setTargets = [...warmups, ...working];
          // Renumber
          for (int s = 0; s < setTargets.length; s++) {
            setTargets[s] = SetTarget(
              setNumber: s + 1,
              setType: setTargets[s].setType,
              targetReps: setTargets[s].targetReps,
              targetWeightKg: setTargets[s].targetWeightKg != null
                  ? setTargets[s].targetWeightKg! * intensityMultiplier
                  : null,
              targetRpe: setTargets[s].targetRpe != null
                  ? max(rpeFloor, setTargets[s].targetRpe!)
                  : null,
              targetRir: setTargets[s].targetRir,
            );
          }
        }

        restSeconds = (RestPeriodTable.getRestSeconds(
          effectiveGoal, isCompound, effectiveFitnessLevel,
        ) * restMultiplier).round();

        // Superset pairing
        if (effectiveSupersets && sel.slot.supersetPartner != null && !pairedIndices.contains(i)) {
          // Find the partner exercise
          final partnerIdx = _findPartnerIndex(
            selectedExercises, i, sel.slot.supersetPartner!, pairedIndices,
          );
          if (partnerIdx != null) {
            supersetGroupCounter++;
            supersetGroup = supersetGroupCounter;
            supersetOrder = 1;
            pairedIndices.add(i);
            pairedIndices.add(partnerIdx);
            // Mark partner (will be applied when we process it)
            selectedExercises[partnerIdx] = selectedExercises[partnerIdx].copyWith(
              supersetGroup: supersetGroupCounter,
              supersetOrder: 2,
            );
            restSeconds = RestPeriodTable.getSupersetIntraPairRest();
            notes = 'Superset: perform both exercises back-to-back, rest ${RestPeriodTable.getSupersetInterPairRest(effectiveGoal)}s between pairs';
          }
        }

        // Check if this exercise was pre-marked as superset partner
        if (sel.supersetGroup != null) {
          supersetGroup = sel.supersetGroup;
          supersetOrder = sel.supersetOrder;
          restSeconds = RestPeriodTable.getSupersetIntraPairRest();
        }
      }

      // Phase 4 — Per-exercise RPE tuning
      final rpeSummary = rpeFeedback[exName];
      if (rpeSummary != null && orm != null) {
        switch (rpeSummary.decision) {
          case RpeDecision.progress:
            // Weight increase applied in weight calculation section below
            break;
          case RpeDecision.maintain:
            // Keep last weight — no change needed
            break;
          case RpeDecision.reduceVolume:
            // Same weight, -1 set
            final workingSets = setTargets.where((t) => !t.isWarmup).toList();
            if (workingSets.length > 1) {
              setTargets = [
                ...setTargets.where((t) => t.isWarmup),
                ...workingSets.take(workingSets.length - 1),
              ];
              // Renumber
              for (int s = 0; s < setTargets.length; s++) {
                setTargets[s] = SetTarget(
                  setNumber: s + 1,
                  setType: setTargets[s].setType,
                  targetReps: setTargets[s].targetReps,
                  targetWeightKg: setTargets[s].targetWeightKg,
                  targetRpe: setTargets[s].targetRpe,
                  targetRir: setTargets[s].targetRir,
                );
              }
            }
            break;
          case RpeDecision.deload:
            // 85% of last weight — handled in weight calculation
            break;
        }
      }

      // Volume landmark enforcement: cap sets at MRV, floor at MEV
      if (volumeLandmarks.isNotEmpty && weeklyVolume.isNotEmpty) {
        final muscle = sel.slot.muscle.toLowerCase();
        final landmarks = volumeLandmarks[muscle];
        if (landmarks != null) {
          final currentVol = weeklyVolume[muscle] ?? 0;
          final workingSets = setTargets.where((t) => !t.isWarmup).length;

          // Cap: if adding these sets would exceed MRV, reduce
          if (currentVol + workingSets > landmarks.mrv) {
            final allowedSets = (landmarks.mrv - currentVol).clamp(1, workingSets);
            if (allowedSets < workingSets) {
              final warmups = setTargets.where((t) => t.isWarmup).toList();
              final working = setTargets.where((t) => !t.isWarmup).take(allowedSets).toList();
              setTargets = [...warmups, ...working];
              for (int s = 0; s < setTargets.length; s++) {
                setTargets[s] = SetTarget(
                  setNumber: s + 1,
                  setType: setTargets[s].setType,
                  targetReps: setTargets[s].targetReps,
                  targetWeightKg: setTargets[s].targetWeightKg,
                  targetRpe: setTargets[s].targetRpe,
                  targetRir: setTargets[s].targetRir,
                );
              }
            }
          }

          // Floor: ensure at least enough to reach MEV
          // (Only adds sets if current volume is below MEV and we have room)
          if (currentVol < landmarks.mev && workingSets < 2) {
            final needed = landmarks.mev - currentVol;
            if (needed > 0 && setTargets.isNotEmpty) {
              final templateSet = setTargets.last;
              for (int extra = 0; extra < needed.clamp(0, 2); extra++) {
                setTargets.add(SetTarget(
                  setNumber: setTargets.length + 1,
                  setType: 'working',
                  targetReps: templateSet.targetReps,
                  targetWeightKg: templateSet.targetWeightKg,
                  targetRpe: templateSet.targetRpe,
                  targetRir: templateSet.targetRir,
                ));
              }
            }
          }
        }
      }

      // Mesocycle weekly set targets
      if (mesocycleContext != null) {
        final muscle = sel.slot.muscle.toLowerCase();
        final targetSets = mesocycleContext.targetWeeklySets[muscle];
        if (targetSets != null) {
          final currentVol = weeklyVolume[muscle] ?? 0;
          final remaining = (targetSets - currentVol).clamp(0, 5);
          final workingSets = setTargets.where((t) => !t.isWarmup).length;

          if (remaining < workingSets && remaining > 0) {
            final warmups = setTargets.where((t) => t.isWarmup).toList();
            final working = setTargets.where((t) => !t.isWarmup).take(remaining).toList();
            setTargets = [...warmups, ...working];
            for (int s = 0; s < setTargets.length; s++) {
              setTargets[s] = SetTarget(
                setNumber: s + 1,
                setType: setTargets[s].setType,
                targetReps: setTargets[s].targetReps,
                targetWeightKg: setTargets[s].targetWeightKg,
                targetRpe: setTargets[s].targetRpe,
                targetRir: setTargets[s].targetRir,
              );
            }
          }
        }
      }

      // Calculate working weight
      double? workingWeight;
      String? weightSource = orm != null ? '1rm_calculated' : null;
      String? equipNote;

      if (orm != null && orm > 0) {
        final intensity = overload.getIntensityPercent(
          goal: effectiveGoal,
          fitnessLevel: effectiveFitnessLevel,
        );
        workingWeight = overload.calculateWorkingWeight(
          orm,
          intensity,
          equipmentType: overload.detectEquipmentType(ex.equipment),
        ) * intensityMultiplier;

        // Apply RPE-based weight adjustments
        if (rpeSummary != null) {
          if (rpeSummary.decision == RpeDecision.deload) {
            workingWeight = workingWeight * 0.85;
          } else if (rpeSummary.decision == RpeDecision.progress) {
            final increment = _getEquipmentIncrement(ex.equipment);
            workingWeight = workingWeight + increment;
          }
        }

        // Equipment-aware weight snapping
        if (equipmentContext != null &&
            equipmentContext.hasDetailedInventory &&
            workingWeight > 0) {
          final eqType = EquipmentContextResolver.normalizeType(
            overload.detectEquipmentType(ex.equipment),
          );
          final snapResult = equipmentContext.snapWeight(workingWeight, eqType);

          if (snapResult.wasSnapped && snapResult.snappedWeight != null) {
            // Adjust set targets for the snap
            setTargets = overload.adjustSetTargetsForSnap(
              setTargets, snapResult, effectiveGoal,
            );
            workingWeight = snapResult.snappedWeight;

            // Adjust rest for significant snaps
            if (snapResult.ratio > 1.20) {
              restSeconds = (restSeconds * 0.85).round();
            }

            equipNote = snapResult.adjustmentNote;
            if (snapResult.ratio > 1.20) {
              equipNote = '${equipNote ?? ''} - Higher reps for equivalent stimulus';
            }
          }
        }
      } else if (orm == null &&
          equipmentContext != null &&
          equipmentContext.hasDetailedInventory) {
        // No 1RM but has detailed inventory — suggest conservative starting weight
        final eqType = EquipmentContextResolver.normalizeType(
          overload.detectEquipmentType(ex.equipment),
        );
        final inv = equipmentContext.getInventory(eqType);
        if (inv != null && inv.sortedWeights.isNotEmpty) {
          // 40th percentile for compounds, 25th for isolation
          final percentile = isCompound ? 0.40 : 0.25;
          workingWeight = inv.getPercentileWeight(percentile);
          weightSource = 'suggested';

          // Generate conservative set targets
          if (workingWeight != null) {
            // Rebuild set targets with conservative RPE/RIR
            final conservativeTargets = <SetTarget>[];
            int sn = 1;
            for (final st in setTargets) {
              if (st.isWarmup) {
                conservativeTargets.add(SetTarget(
                  setNumber: sn++,
                  setType: 'warmup',
                  targetReps: st.targetReps,
                  targetWeightKg: _roundWeight(workingWeight * 0.5),
                  targetRpe: 4,
                  targetRir: 6,
                ));
              } else {
                conservativeTargets.add(SetTarget(
                  setNumber: sn++,
                  setType: 'working',
                  targetReps: st.targetReps,
                  targetWeightKg: workingWeight,
                  targetRpe: (st.targetRpe != null)
                      ? (st.targetRpe! - 1).clamp(6, 8)
                      : 7,
                  targetRir: (st.targetRir != null)
                      ? (st.targetRir! + 1).clamp(2, 4)
                      : 3,
                ));
              }
            }
            setTargets = conservativeTargets;
            equipNote = 'Suggested starting weight - adjust as needed';
          }
        }
      }

      // Append equipment note to exercise notes
      if (equipNote != null) {
        notes = notes != null ? '$notes\n$equipNote' : equipNote;
      }

      final displayReps = setTargets.isNotEmpty && setTargets.first.targetReps > 0
          ? setTargets.first.targetReps
          : overload.getDefaultReps(goal: effectiveGoal);

      workoutExercises.add(WorkoutExercise(
        id: _uuid.v4(),
        exerciseId: ex.id,
        nameValue: ex.name,
        sets: setTargets.length,
        reps: displayReps,
        restSeconds: restSeconds,
        durationSeconds: durationSeconds,
        holdSeconds: holdSeconds,
        isTimed: isTimed,
        weight: workingWeight,
        notes: notes,
        videoUrl: ex.videoUrl,
        imageS3Path: ex.imageS3Path,
        bodyPart: ex.bodyPart,
        equipment: ex.equipment,
        muscleGroup: sel.slot.muscle,
        primaryMuscle: ex.primaryMuscle ?? ex.targetMuscle,
        secondaryMuscles: ex.secondaryMuscles,
        difficulty: ex.difficulty,
        difficultyNum: ex.difficultyNum,
        weightSource: weightSource,
        setTargets: setTargets,
        supersetGroup: supersetGroup,
        supersetOrder: supersetOrder,
        isCompleted: false,
      ));
    }

    // =====================================================================
    // Phase 4.5: Advanced Technique Application
    // =====================================================================
    // Apply technique to last isolation exercise if time margin > 60s
    if (format != 'emom' && format != 'amrap' && format != 'hiit' &&
        format != 'tabata' && format != 'circuit' && format != 'flow') {
      final timeMargin = workingBudget - runningTime;
      if (timeMargin > 60 && workoutExercises.length >= 2) {
        // Find last isolation exercise
        int lastIsolationIdx = -1;
        for (int i = workoutExercises.length - 1; i >= 0; i--) {
          if (workoutExercises[i].supersetGroup == null) {
            lastIsolationIdx = i;
            break;
          }
        }
        if (lastIsolationIdx >= 0) {
          final target = workoutExercises[lastIsolationIdx];
          final techniqueResult = applyTechniqueForGoal(
            effectiveGoal,
            target.setTargets ?? [],
            workingWeight: target.weight,
          );
          if (techniqueResult != null) {
            final newNotes = target.notes != null
                ? '${target.notes}\n${techniqueResult.description}'
                : techniqueResult.description;
            workoutExercises[lastIsolationIdx] = WorkoutExercise(
              id: target.id,
              exerciseId: target.exerciseId,
              nameValue: target.nameValue,
              sets: techniqueResult.modifiedSets.length,
              reps: target.reps,
              restSeconds: target.restSeconds,
              durationSeconds: target.durationSeconds,
              holdSeconds: target.holdSeconds,
              isTimed: target.isTimed,
              weight: target.weight,
              notes: newNotes,
              videoUrl: target.videoUrl,
              imageS3Path: target.imageS3Path,
              bodyPart: target.bodyPart,
              equipment: target.equipment,
              muscleGroup: target.muscleGroup,
              primaryMuscle: target.primaryMuscle,
              secondaryMuscles: target.secondaryMuscles,
              difficulty: target.difficulty,
              difficultyNum: target.difficultyNum,
              weightSource: target.weightSource,
              setTargets: techniqueResult.modifiedSets,
              supersetGroup: target.supersetGroup,
              supersetOrder: target.supersetOrder,
              isCompleted: false,
            );
          }
        }
      }
    }

    // =====================================================================
    // Phase 5: Time Validation
    // =====================================================================
    var estimatedSeconds = warmupSeconds + runningTime;
    // If way over budget, remove last exercise(s)
    while (estimatedSeconds > totalBudgetSeconds + 60 && workoutExercises.length > 2) {
      workoutExercises.removeLast();
      // Recalculate
      estimatedSeconds = warmupSeconds + workoutExercises.length *
          strategy.timeCostPerExercise(difficulty, effectiveSupersets);
    }

    final estimatedMinutes = (estimatedSeconds / 60).ceil().clamp(
      durationMinutes > 5 ? durationMinutes - 2 : 1,
      durationMinutes + 2,
    );

    // =====================================================================
    // Phase 6: Build Workout
    // =====================================================================
    final workoutName = QuickWorkoutConstants.getRandomWorkoutName(effectiveFocus);
    final exercisesJsonList = workoutExercises.map((e) => e.toJson()).toList();

    final now = DateTime.now();
    final scheduledDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Workout(
      id: _uuid.v4(),
      userId: userId,
      name: workoutName,
      type: effectiveFocus,
      difficulty: difficulty,
      scheduledDate: scheduledDate,
      isCompleted: false,
      exercisesJson: exercisesJsonList,
      durationMinutes: durationMinutes,
      estimatedDurationMinutes: estimatedMinutes,
      generationMethod: 'quick_rule_based',
      generationMetadata: {
        'generator': 'quick_workout_engine',
        'source': 'quick_button',
        'quick_workout': true,
        'focus': effectiveFocus,
        'difficulty': difficulty,
        'mood': mood,
        'format': format,
        'exercise_count': workoutExercises.length,
        'duration_target': durationMinutes,
        'duration_estimated': estimatedMinutes,
        'use_supersets': effectiveSupersets,
        'equipment': equipment,
        'injuries': injuries,
        'had_1rm_data': oneRepMaxes.isNotEmpty,
        'has_equipment_context': equipmentContext?.hasDetailedInventory ?? false,
        'variety_skipped': recentlyUsedExercises.isNotEmpty,
        'goal': effectiveGoal,
        'has_recovery_data': muscleRecoveryScores.isNotEmpty,
        'has_session_tracking': sessionsSinceLastUse.isNotEmpty,
        'has_rpe_feedback': rpeFeedback.isNotEmpty,
        'has_volume_landmarks': volumeLandmarks.isNotEmpty,
        'has_mesocycle': mesocycleContext != null,
        'mesocycle_phase': mesocycleContext?.phaseDisplayName,
        'mesocycle_week': mesocycleContext?.weekNumber,
        'has_collaborative_scores': collaborativeScores.isNotEmpty,
        'has_sfr_scores': sfrScores.isNotEmpty,
        'has_hrv_data': hrvModifiers?.hasData ?? false,
        'hrv_readiness': hrvModifiers?.readinessLevel.name,
        'generation_source': 'quick_workout',
      },
      createdAt: now.toIso8601String(),
    );
  }

}
