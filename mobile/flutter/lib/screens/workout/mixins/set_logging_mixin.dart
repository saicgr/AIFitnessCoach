import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/services/fatigue_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/providers/sound_preferences_provider.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import '../models/workout_state.dart';
import '../widgets/exercise_options_sheet.dart' show RepProgressionType;
import '../widgets/number_input_widgets.dart';

part 'set_logging_mixin_ui.dart';


/// Mixin providing set logging, editing, and completion functionality.
mixin SetLoggingMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  int get viewingExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, List<Map<String, dynamic>>> get previousSets;
  Map<int, RepProgressionType> get repProgressionPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  Map<int, double> get exerciseWorkingWeight;
  Map<int, String> get exerciseBarType;
  Map<String, double> get exerciseMaxWeights;

  TextEditingController get repsController;
  TextEditingController get repsRightController;
  TextEditingController get weightController;
  bool get useKg;
  set useKg(bool value);
  bool get unitInitialized;
  double get weightIncrement;

  SetLog? get pendingSetLog;
  set pendingSetLog(SetLog? value);
  int? get lastSetRpe;
  set lastSetRpe(int? value);
  int? get lastSetRir;
  bool get isLeftRightMode;
  set isLeftRightMode(bool value);
  bool get isDoneButtonPressed;
  int? get justCompletedSetIndex;
  set justCompletedSetIndex(int? value);

  // Cross-mixin method access
  void checkForPRs(SetLog setLog, WorkoutExercise exercise);
  void moveToNextExercise();
  void startRest(bool betweenExercises, {Duration? overrideDuration});

  // Abstract methods implemented in ui part
  Future<void> fetchAIWeightSuggestion(SetLog setLog);
  Future<void> fetchRestSuggestion();
  Future<void> checkFatigue();
  void autoAdjustWeightIfNeeded(SetLog setLog, WorkoutExercise exercise);
  void markSupersetExerciseDoneInRound(int exerciseIndex, int groupId);
  int? getNextSupersetExerciseIndex(int currentIndex, int groupId);
  void resetSupersetRound(int groupId);
  void advanceToSupersetExercise(int nextIndex);
  void saveWeightUnitPreference(String unit);

  // ── Set Logging Methods ──

  /// Complete a set with current weight/reps values
  void completeSet() {
    final weight = double.tryParse(weightController.text) ?? 0;
    final reps = int.tryParse(repsController.text) ?? 0;
    final exercise = exercises[currentExerciseIndex];
    final currentSetNumber = (completedSets[currentExerciseIndex]?.length ?? 0) + 1;
    final setTarget = exercise.getTargetForSet(currentSetNumber);
    final targetReps = setTarget?.targetReps ?? exercise.reps ?? 10;

    final setLog = SetLog(
      reps: reps,
      weight: useKg ? weight : weight * 0.453592,
      targetReps: targetReps,
    );

    pendingSetLog = setLog;

    ref.read(posthogServiceProvider).capture(
      eventName: 'set_completed',
      properties: {
        'exercise_name': exercise.name,
        'set_number': currentSetNumber,
        'weight': weight,
        'reps': reps,
      },
    );

    HapticService.setCompletion();

    finalizeSetWithRpe();
  }

  /// Finalize the set log with RPE/RIR and continue
  void finalizeSetWithRpe() {
    if (pendingSetLog == null) return;

    final finalSetLog = pendingSetLog!.copyWith(
      rpe: lastSetRpe,
      rir: lastSetRir,
    );

    completedSets[currentExerciseIndex] ??= [];
    completedSets[currentExerciseIndex]!.add(finalSetLog);
    setState(() {
      justCompletedSetIndex = completedSets[currentExerciseIndex]!.length - 1;
    });

    final currentExercise = exercises[currentExerciseIndex];
    checkForPRs(finalSetLog, currentExercise);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => justCompletedSetIndex = null);
      }
    });

    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;
    final completedCount = completedSets[currentExerciseIndex]?.length ?? 0;

    if (completedCount >= totalSets) {
      ref.read(soundPreferencesProvider.notifier).playExerciseCompletion();

      final groupId = currentExercise.supersetGroup;
      if (groupId != null && currentExercise.isInSuperset) {
        markSupersetExerciseDoneInRound(currentExerciseIndex, groupId);

        final nextSupersetIdx = getNextSupersetExerciseIndex(currentExerciseIndex, groupId);
        if (nextSupersetIdx != null) {
          advanceToSupersetExercise(nextSupersetIdx);
        } else {
          resetSupersetRound(groupId);
          moveToNextExercise();
        }
      } else {
        moveToNextExercise();
      }
    } else {
      autoAdjustWeightIfNeeded(finalSetLog, currentExercise);
      updateControlsForNextSet(currentExercise, completedCount);

      final pattern = exerciseProgressionPattern[currentExerciseIndex]
          ?? SetProgressionPattern.pyramidUp;
      final patternRest = pattern.restDuration;

      final groupId = currentExercise.supersetGroup;
      if (groupId != null && currentExercise.isInSuperset) {
        markSupersetExerciseDoneInRound(currentExerciseIndex, groupId);

        final nextSupersetIdx = getNextSupersetExerciseIndex(currentExerciseIndex, groupId);
        if (nextSupersetIdx != null) {
          advanceToSupersetExercise(nextSupersetIdx);
        } else {
          resetSupersetRound(groupId);
          startRest(false);
          fetchAIWeightSuggestion(finalSetLog);
          fetchRestSuggestion();
          checkFatigue();
        }
      } else if (patternRest != null && patternRest.inSeconds <= 15) {
        startRest(false, overrideDuration: patternRest);
      } else {
        startRest(false);
        fetchAIWeightSuggestion(finalSetLog);
        fetchRestSuggestion();
        checkFatigue();
      }
    }

    pendingSetLog = null;
  }

  /// Initialize weight/reps controllers for a given exercise index.
  void initControllersForExercise(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    final exercise = exercises[exerciseIndex];
    final completedLogs = completedSets[exerciseIndex];

    if (completedLogs != null && completedLogs.isNotEmpty) {
      final lastIdx = completedLogs.length - 1;
      final setTargetsList = exercise.setTargets;
      final lastWasWarmup = setTargetsList != null && lastIdx < setTargetsList.length &&
          setTargetsList[lastIdx].setType.toLowerCase() == 'warmup';

      if (!lastWasWarmup) {
        final lastLog = completedLogs.last;
        final displayWeight = useKg
            ? lastLog.weight
            : kgToDisplayLbs(lastLog.weight, exercise.equipment,
                exerciseName: exercise.name,);
        weightController.text = displayWeight.toStringAsFixed(
            displayWeight % 1 == 0 ? 0 : 1);
        repsController.text = lastLog.reps.toString();
        repsRightController.text = lastLog.reps.toString();
        return;
      }
    }

    final completedCount = completedLogs?.length ?? 0;
    final setTarget = exercise.getTargetForSet(completedCount + 1);

    repsController.text = (setTarget?.targetReps ?? exercise.reps ?? 10).toString();
    repsRightController.text = repsController.text;

    final isWarmup = setTarget != null &&
        setTarget.setType.toLowerCase() == 'warmup';

    final prevSets = previousSets[exerciseIndex];
    final prevWeightKg = (prevSets != null && prevSets.isNotEmpty)
        ? (prevSets.last['weight'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    double displayWeight;
    if (prevWeightKg > 0) {
      displayWeight = useKg
          ? prevWeightKg
          : kgToDisplayLbs(prevWeightKg, exercise.equipment,
                exerciseName: exercise.name,);
    } else {
      double aiWt;
      if (isWarmup) {
        final workingTarget = exercise.setTargets?.cast<SetTarget?>().firstWhere(
          (t) => t != null && t.setType.toLowerCase() != 'warmup' && (t.targetWeightKg ?? 0) > 0,
          orElse: () => null,
        );
        aiWt = (workingTarget?.targetWeightKg ?? exercise.weight ?? 0).toDouble();
      } else {
        aiWt = (setTarget?.targetWeightKg ?? exercise.weight ?? 0).toDouble();
      }
      if (aiWt > 0 && !isGenericWeight(aiWt, exercise.weightSource)) {
        displayWeight = useKg
            ? aiWt
            : kgToDisplayLbs(aiWt, exercise.equipment,
                exerciseName: exercise.name,);
      } else if (aiWt > 0) {
        displayWeight = useKg
            ? aiWt
            : kgToDisplayLbs(aiWt, exercise.equipment,
                exerciseName: exercise.name,);
      } else {
        displayWeight = getDefaultWeight(exercise.equipment,
            exerciseName: exercise.name,
            fitnessLevel: ref.read(authStateProvider).user?.fitnessLevel,
            gender: ref.read(authStateProvider).user?.gender,
            useKg: useKg);
      }
    }

    final ownedWeights = _getOwnedWeightsForEquipment(exercise.equipment);

    if (isWarmup && displayWeight > 0) {
      final rawWarmup = displayWeight * 0.5;
      if (ownedWeights != null && ownedWeights.isNotEmpty) {
        displayWeight = snapToOwnedWeight(rawWarmup, ownedWeights,
            equipment: exercise.equipment, exerciseName: exercise.name, useKg: useKg);
      } else {
        final range = getWeightRange(exercise.equipment, exerciseName: exercise.name);
        final warmupStep = useKg ? range.stepKg : range.stepLbs;
        final minWeight = useKg ? range.minKg : range.minLbs;
        if (warmupStep > 0) {
          final warmupUpperBound = displayWeight > minWeight ? displayWeight : minWeight;
          displayWeight = ((rawWarmup / warmupStep).round() * warmupStep)
              .clamp(minWeight, warmupUpperBound);
        } else {
          displayWeight = rawWarmup;
        }
      }
    } else if (ownedWeights != null && ownedWeights.isNotEmpty && displayWeight > 0) {
      displayWeight = snapToOwnedWeight(displayWeight, ownedWeights,
          equipment: exercise.equipment, exerciseName: exercise.name, useKg: useKg);
    }

    if (displayWeight <= 0) {
      weightController.text = '';
    } else {
      weightController.text = displayWeight.toStringAsFixed(
          displayWeight % 1 == 0 ? 0 : 1);
    }

    final activePattern = exerciseProgressionPattern[exerciseIndex]
        ?? SetProgressionPattern.pyramidUp;
    applyProgressionTargets(exerciseIndex, activePattern);
  }

  /// Get the user's owned weights for an equipment type from their gym profile.
  List<double>? _getOwnedWeightsForEquipment(String? equipment) {
    final profile = ref.read(activeGymProfileProvider);
    if (profile == null || profile.equipmentDetails == null) return null;

    final eq = (equipment ?? '').toLowerCase();
    String profileKey;
    if (eq.contains('dumbbell')) {
      profileKey = 'dumbbells';
    } else if (eq.contains('kettlebell')) {
      profileKey = 'kettlebells';
    } else if (eq.contains('barbell') || eq.contains('ez') || eq.contains('trap')) {
      return null;
    } else {
      return null;
    }

    for (final detail in profile.equipmentDetails!) {
      final name = (detail['name'] as String? ?? '').toLowerCase();
      if (name == profileKey) {
        final item = EquipmentItem.fromJson(detail);
        final weights = item.availableWeights;
        if (weights.isNotEmpty) return weights;
      }
    }
    return null;
  }

  /// Handle set completed in V2 design
  void handleSetCompletedV2(int setIndex) {
    final completedCount = completedSets[viewingExerciseIndex]?.length ?? 0;

    if (setIndex == completedCount) {
      completeSet();
    } else if (setIndex < completedCount) {
      editCompletedSet(setIndex);
    }
  }

  /// Edit a completed set
  void editCompletedSet(int setIndex) {
    final set = completedSets[viewingExerciseIndex]![setIndex];
    final exercise = exercises[viewingExerciseIndex];
    final displayWeight = useKg
        ? set.weight
        : kgToDisplayLbs(set.weight, exercise.equipment,
                exerciseName: exercise.name,);
    final editWeightController =
        TextEditingController(text: displayWeight.toStringAsFixed(1));
    final editRepsController = TextEditingController(text: set.reps.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final bgColor = isDark ? AppColors.elevated : Colors.white;
    final titleColor = isDark ? AppColors.textPrimary : Colors.black87;
    int? editRir = set.rir;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          title: Text('Edit Set ${setIndex + 1}',
              style: TextStyle(color: titleColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NumberInputField(
                controller: editWeightController,
                icon: Icons.fitness_center,
                hint: 'Weight (${useKg ? 'kg' : 'lbs'})',
                color: accent,
                isDecimal: true,
              ),
              const SizedBox(height: 16),
              NumberInputField(
                controller: editRepsController,
                icon: Icons.repeat,
                hint: 'Reps',
                color: accent,
              ),
              const SizedBox(height: 16),
              // RIR selection
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RIR (Reps in Reserve)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  final rir = i;
                  final isSelected = editRir == rir;
                  final color = WorkoutDesign.getRirColor(rir);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setDialogState(() {
                        editRir = isSelected ? null : rir;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : color.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          rir == 5 ? '5+' : '$rir',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? WorkoutDesign.getRirTextColor(rir)
                                : color,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: isDark ? AppColors.textSecondary : Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () {
                final editedWeight =
                    double.tryParse(editWeightController.text) ?? displayWeight;
                final weightKg = useKg ? editedWeight : editedWeight * 0.453592;
                setState(() {
                  completedSets[viewingExerciseIndex]![setIndex] = SetLog(
                    reps: int.tryParse(editRepsController.text) ?? set.reps,
                    weight: weightKg,
                    completedAt: set.completedAt,
                    setType: set.setType,
                    rir: editRir,
                    rpe: set.rpe,
                    targetReps: set.targetReps,
                    notes: set.notes,
                  );
                });
                Navigator.pop(dialogContext);
              },
              child: Text('Save',
                  style: TextStyle(color: accent)),
            ),
          ],
        ),
      ),
    );
  }

  /// Update a completed set inline (without dialog)
  void updateCompletedSet(int setIndex, double weight, int reps) {
    if (completedSets[viewingExerciseIndex] == null ||
        setIndex < 0 ||
        setIndex >= completedSets[viewingExerciseIndex]!.length) {
      return;
    }

    setState(() {
      final existingSet = completedSets[viewingExerciseIndex]![setIndex];
      completedSets[viewingExerciseIndex]![setIndex] = SetLog(
        reps: reps,
        weight: weight,
        completedAt: existingSet.completedAt,
        setType: existingSet.setType,
      );
    });
  }

  /// Delete a completed set
  void deleteCompletedSet(int setIndex) {
    setState(() {
      if (setIndex == -1) {
        final currentTotal = totalSetsPerExercise[viewingExerciseIndex] ?? 3;
        final completedCount = completedSets[viewingExerciseIndex]?.length ?? 0;
        if (currentTotal > 1 && currentTotal > completedCount) {
          totalSetsPerExercise[viewingExerciseIndex] = currentTotal - 1;
        }
      } else if (completedSets[viewingExerciseIndex] != null &&
          setIndex >= 0 &&
          setIndex < completedSets[viewingExerciseIndex]!.length) {
        completedSets[viewingExerciseIndex]!.removeAt(setIndex);
      }
    });
  }

  /// Quick complete or uncomplete a set by tapping its number
  void quickCompleteSet(int setIndex, bool complete) {
    if (complete) {
      final exercise = exercises[viewingExerciseIndex];
      final prevSets = previousSets[viewingExerciseIndex] ?? [];

      double weight = double.tryParse(weightController.text) ?? 0;
      if (weight == 0 && exercise.weight != null) {
        weight = exercise.weight!;
      }
      if (weight == 0 && setIndex < prevSets.length) {
        weight = (prevSets[setIndex]['weight'] as double?) ?? 0;
      }

      int reps = int.tryParse(repsController.text) ?? 0;
      if (reps == 0 && exercise.reps != null) {
        reps = exercise.reps!;
      }
      if (reps == 0 && setIndex < prevSets.length) {
        reps = (prevSets[setIndex]['reps'] as int?) ?? 0;
      }

      if (weight == 0) weight = 20;
      if (reps == 0) reps = 10;

      final setLog = SetLog(
        weight: weight,
        reps: reps,
        completedAt: DateTime.now(),
        setType: 'working',
        targetReps: exercise.reps ?? reps,
      );

      completedSets[viewingExerciseIndex] ??= [];
      if (setIndex >= completedSets[viewingExerciseIndex]!.length) {
        completedSets[viewingExerciseIndex]!.add(setLog);
      } else {
        completedSets[viewingExerciseIndex]!.insert(setIndex, setLog);
      }

      setState(() {
        justCompletedSetIndex = setIndex;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => justCompletedSetIndex = null);
      });
    } else {
      if (completedSets[viewingExerciseIndex] != null &&
          setIndex >= 0 &&
          setIndex < completedSets[viewingExerciseIndex]!.length) {
        completedSets[viewingExerciseIndex]!.removeAt(setIndex);
      }
      setState(() {});
    }
  }

  /// Update target RIR for a set
  void updateSetTargetRir(int setIndex, int newRir) {
    final exercise = exercises[viewingExerciseIndex];
    if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
      setState(() {
        final updatedTargets = List<SetTarget>.from(exercise.setTargets!);
        final oldTarget = updatedTargets[setIndex];
        updatedTargets[setIndex] = SetTarget(
          setNumber: oldTarget.setNumber,
          setType: oldTarget.setType,
          targetWeightKg: oldTarget.targetWeightKg,
          targetReps: oldTarget.targetReps,
          targetRir: newRir,
        );
        exercises[viewingExerciseIndex] = exercise.copyWith(setTargets: updatedTargets);
      });
    }
  }

  /// Show RIR picker to edit target RIR for a set
  void showRirPicker(int setIndex, int? currentRir) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedRir = currentRir ?? 2;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Set Target RIR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Set ${setIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rir = index;
                      final isSelected = selectedRir == rir;
                      final color = WorkoutDesign.getRirColor(rir);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() => selectedRir = rir);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$rir',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? WorkoutDesign.getRirTextColor(rir)
                                    : color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      _getRirDescription(selectedRir),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        updateSetTargetRir(setIndex, selectedRir);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WorkoutDesign.getRirColor(selectedRir),
                        foregroundColor: WorkoutDesign.getRirTextColor(selectedRir),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRirDescription(int rir) {
    switch (rir) {
      case 0:
        return 'Failure - No reps left in tank';
      case 1:
        return 'Very hard - Maybe 1 more rep';
      case 2:
        return 'Hard - Could do 2 more reps';
      case 3:
        return 'Moderate - 3 reps in reserve';
      case 4:
        return 'Easy - 4+ reps in reserve';
      default:
        return '';
    }
  }

  /// Toggle weight unit between kg and lbs
  void toggleUnit() {
    setState(() {
      final currentVal = double.tryParse(weightController.text) ?? 0;
      final exercise = exercises[viewingExerciseIndex];
      if (useKg) {
        final lbsVal = currentVal * 2.20462;
        final snapped = snapToRealIncrement(lbsVal, exercise.equipment,
            exerciseName: exercise.name, useKg: false);
        weightController.text = snapped % 1 == 0
            ? snapped.toInt().toString()
            : snapped.toStringAsFixed(1);
      } else {
        final kgVal = currentVal * 0.453592;
        final eq = (exercise.equipment ?? '').toLowerCase();
        final name = exercise.name.toLowerCase();
        double step;
        if (eq.contains('barbell') || name.contains('barbell') || name.contains('bench press') || name.contains('deadlift')) {
          step = 2.5;
        } else if (eq.contains('cable') || name.contains('cable') || eq.contains('machine') || name.contains('machine')) {
          step = 5.0;
        } else {
          step = 2.5;
        }
        final snapped = (kgVal / step).ceil() * step;
        weightController.text = snapped % 1 == 0
            ? snapped.toInt().toString()
            : snapped.toStringAsFixed(1);
      }
      useKg = !useKg;
    });

    final newUnit = useKg ? 'kg' : 'lbs';
    saveWeightUnitPreference(newUnit);

    ref.read(weightIncrementsProvider.notifier).setUnit(newUnit);
  }

  /// Build comprehensive JSON string with all workout data
  String buildSetsJson() {
    final List<Map<String, dynamic>> allSets = [];

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];

      final pattern = exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;

      for (int j = 0; j < sets.length; j++) {
        final setTarget = exercise.getTargetForSet(j + 1);
        allSets.add({
          'exercise_index': i,
          'exercise_id': exercise.exerciseId ?? exercise.libraryId,
          'exercise_name': exercise.name,
          'set_number': j + 1,
          'reps': sets[j].reps,
          'weight_kg': sets[j].weight,
          'completed_at': sets[j].completedAt.toIso8601String(),
          if (sets[j].rpe != null) 'rpe': sets[j].rpe,
          if (sets[j].rir != null) 'rir': sets[j].rir,
          'target_weight_kg': setTarget?.targetWeightKg ?? exercise.weight,
          'target_reps': setTarget?.targetReps ?? exercise.reps,
          'progression_model': pattern.storageKey,
          if (exercise.supersetGroup != null) 'superset_group': exercise.supersetGroup,
          if (exercise.supersetOrder != null) 'superset_order': exercise.supersetOrder,
        });
      }
    }

    return jsonEncode(allSets);
  }

  /// Toggle left/right mode for unilateral exercises
  void toggleLeftRightMode() {
    setState(() {
      isLeftRightMode = !isLeftRightMode;
    });
  }
}
