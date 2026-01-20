import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../core/utils/difficulty_utils.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_generation_params.dart';
import '../../data/models/coach_persona.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/components/training_program_selector.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/expanded_exercise_card.dart';
import 'widgets/superset_indicator.dart';
import 'widgets/superset_reorder_sheet.dart';
import 'package:flutter/services.dart';
import '../../widgets/fasting_training_warning.dart';
import '../../widgets/coach_avatar.dart';
import '../../models/equipment_item.dart';
import '../../core/providers/environment_equipment_provider.dart';
import 'widgets/edit_workout_equipment_sheet.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  Workout? _workout;
  bool _isLoading = true;
  String? _error;
  String? _workoutSummary;
  bool _isLoadingSummary = true;  // Start as true to show loading immediately
  bool _isWarmupExpanded = false;  // For warmup section
  bool _isStretchesExpanded = false;  // For stretches section
  bool _isChallengeExpanded = false;  // For challenge exercise section
  bool _isEquipmentExpanded = false;  // For equipment section
  String? _trainingSplit;  // Training program type from user preferences
  WorkoutGenerationParams? _generationParams;  // AI reasoning and parameters
  bool _isLoadingParams = false;  // Loading state for generation params
  bool _isAIReasoningExpanded = false;  // For AI reasoning section
  bool _isMoreInfoExpanded = false;  // For More Info section (AI insights)
  bool? _useKgOverride;  // Local override for kg/lbs toggle
  int? _pendingSupersetIndex;  // Index of exercise waiting to be paired via menu

  // Equipment edit revert state
  List<WorkoutExercise>? _originalExercises;  // Snapshot before equipment changes
  bool _hasEquipmentModifications = false;  // Track if equipment was modified

  // Auto-save state for exercise modifications
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  /// Toggle between kg and lbs units locally
  void _toggleUnit() {
    setState(() {
      final bool currentUseKg = _useKgOverride ?? ref.read(useKgProvider);
      _useKgOverride = !currentUseKg;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Schedule auto-save with debounce (2 seconds)
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSaveExercises);
  }

  /// Auto-save exercise modifications to backend
  Future<void> _autoSaveExercises() async {
    if (_workout?.id == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final exercises = _workout!.exercises.map((e) => e.toJson()).toList();
      final result = await ref.read(workoutRepositoryProvider).updateWorkoutExercises(
        workoutId: _workout!.id!,
        exercises: exercises,
      );
      if (result != null && mounted) {
        debugPrint('✅ [WorkoutDetail] Auto-saved exercise modifications');
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Auto-save failed: $e');
      // Silently fail - changes are still in local state
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadWorkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.getWorkout(widget.workoutId);
      setState(() {
        _workout = workout;
        _isLoading = false;
      });
      // Load workout summary, training split, and generation params after workout loads
      _loadWorkoutSummary();
      _loadTrainingSplit();
      _loadGenerationParams();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrainingSplit() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final prefs = await workoutRepo.getProgramPreferences(userId);
      if (mounted && prefs?.trainingSplit != null) {
        // Resolve 'dont_know' to actual split based on workout days
        final resolvedSplit = _resolveTrainingSplit(
          prefs!.trainingSplit!,
          prefs.workoutDays.length ?? 3,
        );
        setState(() {
          _trainingSplit = resolvedSplit;
        });
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load training split: $e');
    }
  }

  /// Resolve 'dont_know' to actual training split based on workout days count
  String _resolveTrainingSplit(String split, int numDays) {
    if (split.toLowerCase() != 'dont_know') {
      return split;  // Already a specific split
    }

    // Auto-pick based on days per week (matches backend logic)
    if (numDays <= 3) {
      return 'full_body';
    } else if (numDays == 4) {
      return 'upper_lower';
    } else if (numDays <= 6) {
      return 'push_pull_legs';
    } else {
      return 'full_body';
    }
  }

  Future<void> _loadWorkoutSummary() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load summary - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Starting to load workout summary for: ${widget.workoutId}');
    setState(() => _isLoadingSummary = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final summary = await workoutRepo.getWorkoutSummary(widget.workoutId);
      debugPrint('🔍 [WorkoutDetail] Got summary response: ${summary != null ? "yes (${summary.length} chars)" : "null"}');
      if (mounted) {
        setState(() {
          _workoutSummary = summary;
          _isLoadingSummary = false;
        });
        debugPrint('✅ [WorkoutDetail] Summary state updated - summary: ${_workoutSummary != null}, loading: $_isLoadingSummary');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WorkoutDetail] Failed to load workout summary: $e');
      debugPrint('❌ [WorkoutDetail] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  /// Load generation parameters and AI reasoning for the workout
  Future<void> _loadGenerationParams() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load generation params - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Loading generation params for: ${widget.workoutId}');
    setState(() => _isLoadingParams = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final params = await workoutRepo.getWorkoutGenerationParams(widget.workoutId);
      if (mounted) {
        setState(() {
          _generationParams = params;
          _isLoadingParams = false;
        });
        debugPrint('✅ [WorkoutDetail] Generation params loaded - ${params?.exerciseReasoning.length ?? 0} exercise reasons');
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load generation params: $e');
      if (mounted) {
        setState(() => _isLoadingParams = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // EQUIPMENT EDITING
  // ─────────────────────────────────────────────────────────────────

  /// Show sheet to edit equipment for this workout session
  void _showEditEquipmentSheet(Workout workout) {
    // Convert equipment strings to EquipmentItem objects
    final currentEquipmentDetails = workout.equipmentNeeded.map((name) {
      return EquipmentItem.fromName(name.toLowerCase().replaceAll(' ', '_'));
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditWorkoutEquipmentSheet(
        currentEquipment: workout.equipmentNeeded,
        equipmentDetails: currentEquipmentDetails,
        onApply: (selectedEquipment) => _applyEquipmentChanges(workout, selectedEquipment),
      ),
    );
  }

  /// Apply equipment changes and update workout
  Future<void> _applyEquipmentChanges(
    Workout workout,
    List<EquipmentItem> selectedEquipment,
  ) async {
    final analysis = _analyzeEquipmentChanges(workout, selectedEquipment);
    debugPrint('🔧 [Equipment] Analysis: ${analysis.weightAdjustments.length} weight adjustments, ${analysis.exercisesToReplace.length} to replace');

    if (analysis.exercisesToReplace.isEmpty && analysis.weightAdjustments.isEmpty) {
      // No changes needed
      _showSnackBar('No changes needed');
      return;
    }

    // Store snapshot BEFORE first modification (for revert functionality)
    if (_originalExercises == null) {
      _originalExercises = List<WorkoutExercise>.from(workout.exercises);
      debugPrint('🔧 [Equipment] Stored original exercises snapshot (${_originalExercises!.length} exercises)');
    }

    if (analysis.exercisesToReplace.isNotEmpty) {
      // Quick replace exercises one by one (faster than full regeneration)
      await _quickReplaceExercises(workout, analysis.exercisesToReplace, selectedEquipment);
    } else {
      // Only weight adjustments - apply locally
      _applyWeightAdjustments(workout, analysis.weightAdjustments);
    }

    // Mark as modified (enables revert button)
    setState(() => _hasEquipmentModifications = true);

    // Ask if user wants to save to profile
    if (mounted) {
      _showSaveToProfileDialog(selectedEquipment);
    }
  }

  /// Analyze what changes are needed based on equipment selection
  _EquipmentChangeAnalysis _analyzeEquipmentChanges(
    Workout workout,
    List<EquipmentItem> selectedEquipment,
  ) {
    final selectedNames = selectedEquipment.map((e) => e.name.toLowerCase()).toSet();
    final equipmentWeights = {
      for (final e in selectedEquipment) e.name.toLowerCase(): e.weights,
    };

    final weightAdjustments = <_ExerciseWeightAdjustment>[];
    final exercisesToReplace = <WorkoutExercise>[];

    for (final exercise in workout.exercises) {
      final eqNeeded = (exercise.equipment ?? 'bodyweight').toLowerCase().replaceAll(' ', '_');

      // Bodyweight exercises are always fine
      if (eqNeeded == 'bodyweight' || eqNeeded == 'body_weight' || eqNeeded.isEmpty) {
        continue;
      }

      // Check if equipment is still selected
      if (!selectedNames.contains(eqNeeded)) {
        exercisesToReplace.add(exercise);
        continue;
      }

      // Equipment available - check if weight adjustment needed
      final availableWeights = equipmentWeights[eqNeeded];
      if (availableWeights != null && availableWeights.isNotEmpty) {
        final currentWeight = exercise.weight ?? 0;
        if (currentWeight > 0) {
          final nearestWeight = _findNearestWeight(currentWeight, availableWeights);
          if ((nearestWeight - currentWeight).abs() > 0.1) {
            weightAdjustments.add(_ExerciseWeightAdjustment(
              exercise: exercise,
              oldWeight: currentWeight,
              newWeight: nearestWeight,
            ));
          }
        }
      }
    }

    return _EquipmentChangeAnalysis(
      weightAdjustments: weightAdjustments,
      exercisesToReplace: exercisesToReplace,
    );
  }

  /// Find nearest available weight
  double _findNearestWeight(double target, List<double> available) {
    if (available.isEmpty) return target;
    return available.reduce((a, b) =>
      (a - target).abs() < (b - target).abs() ? a : b
    );
  }

  /// Apply weight adjustments locally
  void _applyWeightAdjustments(
    Workout workout,
    List<_ExerciseWeightAdjustment> adjustments,
  ) {
    final updatedExercises = List<WorkoutExercise>.from(workout.exercises);

    for (final adj in adjustments) {
      final index = updatedExercises.indexWhere((e) => e.id == adj.exercise.id);
      if (index != -1) {
        final exercise = updatedExercises[index];
        // Update weight and set targets
        List<SetTarget>? updatedTargets;
        if (exercise.setTargets != null && exercise.setTargets!.isNotEmpty) {
          updatedTargets = exercise.setTargets!.map((target) {
            return SetTarget(
              setNumber: target.setNumber,
              setType: target.setType,
              targetReps: target.targetReps,
              targetWeightKg: adj.newWeight,
              targetRpe: target.targetRpe,
              targetRir: target.targetRir,
            );
          }).toList();
        }

        updatedExercises[index] = exercise.copyWith(
          weight: adj.newWeight,
          setTargets: updatedTargets,
        );
      }
    }

    // Convert to JSON and update workout locally
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();
    setState(() {
      _workout = workout.copyWith(exercisesJson: exercisesJson);
    });

    _showSnackBar('Weights updated to match available equipment');
  }

  /// Quick replace exercises that need different equipment (faster than full regeneration)
  Future<void> _quickReplaceExercises(
    Workout workout,
    List<WorkoutExercise> exercisesToReplace,
    List<EquipmentItem> selectedEquipment,
  ) async {
    if (workout.id == null) {
      _showSnackBar('Cannot update - workout ID missing', isError: true);
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _QuickReplaceProgressDialog(
          total: exercisesToReplace.length,
        ),
      );
    }

    final workoutRepo = ref.read(workoutRepositoryProvider);
    int replaced = 0;
    int failed = 0;

    for (final exercise in exercisesToReplace) {
      try {
        debugPrint('🔄 [Equipment] Replacing: ${exercise.name}');
        final result = await workoutRepo.replaceExerciseSafe(
          workoutId: workout.id!,
          exerciseName: exercise.name ?? '',
          exerciseId: exercise.id,
          reason: 'equipment_unavailable',
        );

        if (result?.replaced == true) {
          replaced++;
          debugPrint('✅ [Equipment] Replaced ${exercise.name} with ${result!.replacement}');
        } else {
          failed++;
          debugPrint('⚠️ [Equipment] Could not replace ${exercise.name}');
        }
      } catch (e) {
        failed++;
        debugPrint('❌ [Equipment] Error replacing ${exercise.name}: $e');
      }
    }

    if (mounted) Navigator.of(context).pop(); // Close progress dialog

    // Reload the workout with new data
    await _loadWorkout();

    if (mounted) {
      if (failed == 0) {
        _showSnackBar('Replaced $replaced exercise${replaced > 1 ? 's' : ''} for available equipment');
      } else {
        _showSnackBar('Replaced $replaced, $failed could not be replaced');
      }
    }
  }

  /// Show dialog asking if user wants to save equipment to profile
  void _showSaveToProfileDialog(List<EquipmentItem> equipment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Save to Profile?',
          style: TextStyle(color: textPrimary, fontSize: 18),
        ),
        content: Text(
          'Would you like to save this equipment configuration to your profile for future workouts?',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No Thanks',
              style: TextStyle(color: textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveEquipmentToProfile(equipment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Save'),
          ),
        ],
      ),
    );
  }

  /// Save equipment configuration to user profile (Supabase)
  Future<void> _saveEquipmentToProfile(List<EquipmentItem> equipment) async {
    debugPrint('💾 [Equipment] Saving ${equipment.length} items to profile');

    try {
      // Convert EquipmentItem list to the format expected by the provider
      final equipmentDetails = equipment.map((item) => item.toJson()).toList();

      // Save to Supabase via the environment equipment provider
      await ref.read(environmentEquipmentProvider.notifier).setEquipmentDetails(equipmentDetails);

      if (mounted) {
        _showSnackBar('Equipment saved to profile');
      }
      debugPrint('✅ [Equipment] Successfully saved ${equipment.length} items to Supabase');
    } catch (e) {
      debugPrint('❌ [Equipment] Failed to save to profile: $e');
      if (mounted) {
        _showSnackBar('Failed to save equipment to profile', isError: true);
      }
    }
  }

  /// Revert workout to original exercises (before equipment changes)
  Future<void> _revertToOriginalExercises() async {
    if (_originalExercises == null || _workout == null) return;

    final accentColor = ref.colors(context).accent;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert to Original?'),
        content: const Text(
          'This will restore all exercises to their original state before equipment changes were applied.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);

      debugPrint('🔄 [Equipment] Reverting to original ${_originalExercises!.length} exercises');

      // Restore original exercises via API
      await workoutRepo.updateWorkoutExercises(
        workoutId: _workout!.id!,
        exercises: _originalExercises!.map((e) => e.toJson()).toList(),
      );

      // Reload workout and clear snapshot
      await _loadWorkout();
      _originalExercises = null;
      _hasEquipmentModifications = false;

      if (mounted) {
        _showSnackBar('Workout restored to original');
      }
      debugPrint('✅ [Equipment] Successfully reverted to original exercises');
    } catch (e) {
      debugPrint('❌ [Equipment] Failed to revert: $e');
      if (mounted) {
        _showSnackBar('Failed to revert: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Convert training split ID to display name
  /// Returns the program name if found, or null for special cases like 'nothing_structured'
  String? _getTrainingProgramName(String splitId) {
    // Handle special cases that are valid but don't have a display badge
    if (splitId == 'nothing_structured' || splitId == 'dont_know') {
      // User chose "let AI decide" - no specific program badge to show
      return null;
    }

    // Look up the program in our known list
    final program = defaultTrainingPrograms.where((p) => p.id == splitId).firstOrNull;
    if (program == null) {
      // Unknown split ID - log it but don't crash
      debugPrint('⚠️ [WorkoutDetail] Unknown training split: $splitId');
      return null;
    }
    return program.name;
  }

  // ─────────────────────────────────────────────────────────────────
  // SUPERSET HANDLERS
  // ─────────────────────────────────────────────────────────────────

  /// Create superset from two exercise indices (via drag-drop or menu)
  void _createSuperset(int firstIndex, int secondIndex) {
    final exercise1 = _workout!.exercises[firstIndex];
    final exercise2 = _workout!.exercises[secondIndex];

    debugPrint('🔗 [Superset] _createSuperset called: firstIndex=$firstIndex, secondIndex=$secondIndex');
    debugPrint('🔗 [Superset] exercise1: ${exercise1.name}, isInSuperset=${exercise1.isInSuperset}, group=${exercise1.supersetGroup}');
    debugPrint('🔗 [Superset] exercise2: ${exercise2.name}, isInSuperset=${exercise2.isInSuperset}, group=${exercise2.supersetGroup}');

    // Case 1: Both exercises are already in different supersets - cannot merge
    if (exercise1.isInSuperset && exercise2.isInSuperset) {
      if (exercise1.supersetGroup != exercise2.supersetGroup) {
        debugPrint('🔗 [Superset] Case 1: Cannot merge different supersets');
        HapticService.error();
        _showCannotMergeSupersetDialog(exercise1, exercise2);
        return;
      }
      // Same superset - do nothing
      debugPrint('🔗 [Superset] Case 1b: Same superset, doing nothing');
      return;
    }

    // Case 2: One exercise is in a superset - offer to add the other to it
    if (exercise1.isInSuperset || exercise2.isInSuperset) {
      debugPrint('🔗 [Superset] Case 2: One in superset, showing add dialog');
      final existingSuperset = exercise1.isInSuperset ? exercise1 : exercise2;
      final newExercise = exercise1.isInSuperset ? exercise2 : exercise1;
      final newExerciseIndex = exercise1.isInSuperset ? secondIndex : firstIndex;
      _showAddToSupersetDialog(existingSuperset, newExercise, newExerciseIndex);
      return;
    }

    // Case 3: Neither is in a superset - create new superset
    debugPrint('🔗 [Superset] Case 3: Neither in superset, creating new');
    _performCreateSuperset(firstIndex, secondIndex);
  }

  /// Show dialog when both exercises are already in different supersets (cannot merge)
  Future<void> _showCannotMergeSupersetDialog(
    WorkoutExercise exercise1,
    WorkoutExercise exercise2,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cannot Merge Supersets',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '"${exercise1.name}" and "${exercise2.name}" are already in different supersets.\n\nBreak the existing supersets first to create a new pairing.',
          style: TextStyle(color: textPrimary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Clear pending state
    setState(() => _pendingSupersetIndex = null);
  }

  /// Show dialog offering to add an exercise to an existing superset
  Future<void> _showAddToSupersetDialog(
    WorkoutExercise existingSuperset,
    WorkoutExercise newExercise,
    int newExerciseIndex,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentColor = isDark ? AppColors.purple : AppColorsLight.purple;

    // Count exercises in the existing superset
    final existingCount = _workout!.exercises
        .where((e) => e.supersetGroup == existingSuperset.supersetGroup)
        .length;

    final setType = switch (existingCount) {
      2 => 'superset',
      3 => 'tri-set',
      _ => 'giant set',
    };

    final newSetType = switch (existingCount + 1) {
      3 => 'tri-set',
      _ => 'giant set',
    };

    // Capitalize first letter helper
    String capitalize(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_link, color: accentColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Create ${capitalize(newSetType)}?',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Add "${newExercise.name}" to create a $newSetType?',
          style: TextStyle(color: textPrimary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: textPrimary.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Create ${capitalize(newSetType)}'),
          ),
        ],
      ),
    );

    if (result == true) {
      _addToExistingSuperset(newExerciseIndex, existingSuperset.supersetGroup!);
    }

    // Clear pending state
    setState(() => _pendingSupersetIndex = null);
  }

  /// Add an exercise to an existing superset
  void _addToExistingSuperset(int exerciseIndex, int targetGroup) {
    HapticService.medium();

    // Find the maximum order in the target group
    final maxOrder = _workout!.exercises
        .where((e) => e.supersetGroup == targetGroup)
        .map((e) => e.supersetOrder ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    final updatedExercises = _workout!.exercises.asMap().map((i, e) {
      if (i == exerciseIndex) {
        return MapEntry(i, e.copyWith(
          supersetGroup: targetGroup,
          supersetOrder: maxOrder + 1,
        ));
      }
      return MapEntry(i, e);
    }).values.toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();

    // Get count for snackbar message
    final newCount = _workout!.exercises
        .where((e) => e.supersetGroup == targetGroup)
        .length + 1;
    final setType = switch (newCount) {
      3 => 'Tri-set',
      _ => 'Giant set',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$setType created!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Actually create the superset (called after validation passes)
  void _performCreateSuperset(int firstIndex, int secondIndex) {
    HapticService.medium();

    // Find next available group number
    final existingGroups = _workout!.exercises
        .where((e) => e.supersetGroup != null)
        .map((e) => e.supersetGroup!)
        .toSet();
    int newGroup = 1;
    while (existingGroups.contains(newGroup)) {
      newGroup++;
    }

    final updatedExercises = _workout!.exercises.asMap().map((i, e) {
      if (i == firstIndex) {
        return MapEntry(i, e.copyWith(supersetGroup: newGroup, supersetOrder: 1));
      }
      if (i == secondIndex) {
        return MapEntry(i, e.copyWith(supersetGroup: newGroup, supersetOrder: 2));
      }
      return MapEntry(i, e);
    }).values.toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() {
      _workout = _workout!.copyWith(exercisesJson: exercisesJson);
      _pendingSupersetIndex = null;
    });
    _scheduleAutoSave();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Superset created!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Start pairing from 3-dot menu - stores pending index
  void _startSupersetPairing(int index) {
    setState(() => _pendingSupersetIndex = index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tap another exercise to link as superset'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {
            setState(() => _pendingSupersetIndex = null);
          },
        ),
      ),
    );
  }

  /// Break superset (long-press on header)
  Future<void> _breakSuperset(int groupNumber) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColorsLight.surface,
        title: const Text('Break Superset?'),
        content: const Text('This will unlink these exercises so they are performed separately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Break', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedExercises = _workout!.exercises.map((e) {
        if (e.supersetGroup == groupNumber) {
          return e.copyWith(clearSuperset: true);
        }
        return e;
      }).toList();

      // Convert exercises back to JSON for storage
      final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

      setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
      _scheduleAutoSave();
      HapticService.light();
    }
  }

  /// Swap the order of exercises within a superset (1 becomes 2, 2 becomes 1)
  void _swapSupersetOrder(int groupNumber) {
    HapticService.light();

    final updatedExercises = _workout!.exercises.map((e) {
      if (e.supersetGroup == groupNumber) {
        // Swap order: 1 becomes 2, 2 becomes 1
        final newOrder = e.supersetOrder == 1 ? 2 : 1;
        return e.copyWith(supersetOrder: newOrder);
      }
      return e;
    }).toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();
  }

  /// Show edit sheet for tri-sets and giant sets (3+ exercises) - reorder & remove
  Future<void> _showReorderSheet(int groupNumber, List<int> exerciseIndices) async {
    // Get the exercises in this superset, sorted by current order
    final supersetExercises = exerciseIndices
        .map((idx) => _workout!.exercises[idx])
        .toList()
      ..sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

    final result = await showSupersetEditSheet(
      context,
      exercises: supersetExercises,
      groupNumber: groupNumber,
    );

    if (result != null) {
      // Apply both removals and reorder in one atomic update
      _applyEditSheetResult(groupNumber, result);
    }
  }

  /// Apply the edit sheet result - handles both removals and reordering atomically
  void _applyEditSheetResult(int groupNumber, SupersetEditResult result) {
    HapticService.medium();

    // Create set of keys for removed exercises
    final removeKeys = result.removedExercises.map((e) => e.id ?? e.name).toSet();

    // Create a map of exercise ID/name to new order for remaining exercises
    final orderMap = <String, int>{};
    for (int i = 0; i < result.exercises.length; i++) {
      final key = result.exercises[i].id ?? result.exercises[i].name;
      orderMap[key] = i + 1; // supersetOrder is 1-indexed
    }

    // Apply both changes in one pass
    final updatedExercises = _workout!.exercises.map((e) {
      final key = e.id ?? e.name;

      // Check if this exercise was removed from the superset
      if (removeKeys.contains(key)) {
        return e.copyWith(
          supersetGroup: null,
          supersetOrder: null,
        );
      }

      // Check if this exercise is in the superset and needs reordering
      if (e.supersetGroup == groupNumber) {
        final newOrderValue = orderMap[key];
        if (newOrderValue != null) {
          return e.copyWith(supersetOrder: newOrderValue);
        }
      }

      return e;
    }).toList();

    // Convert exercises back to JSON for storage
    final exercisesJson = updatedExercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();

    // Show appropriate feedback
    final hasRemovals = result.removedExercises.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasRemovals
            ? '${result.removedExercises.length} exercise${result.removedExercises.length > 1 ? 's' : ''} removed from superset'
            : 'Exercise order updated!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Reorder exercises (and supersets as single units) in the list
  void _reorderExercises(int oldIndex, int newIndex) {
    HapticService.medium();

    // Adjust for Flutter's ReorderableListView behavior
    if (newIndex > oldIndex) newIndex -= 1;

    final displayItems = _groupExercisesForDisplay(_workout!.exercises);
    final exercises = List<WorkoutExercise>.from(_workout!.exercises);

    if (oldIndex >= displayItems.length || newIndex >= displayItems.length) return;

    final movedItem = displayItems[oldIndex];

    if (movedItem.isSuperset) {
      // Move all exercises in the superset together (supports 2+ exercises)
      final supersetIndices = movedItem.supersetIndices!;

      // Get exercises sorted by their superset order
      final supersetExercises = supersetIndices
          .map((idx) => exercises[idx])
          .toList()
        ..sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

      // Remove all exercises in the superset (remove from highest index to lowest to preserve indices)
      final sortedIndices = List<int>.from(supersetIndices)..sort((a, b) => b.compareTo(a));
      for (final idx in sortedIndices) {
        exercises.removeAt(idx);
      }

      // Calculate new insert position
      int insertPos = _calculateInsertPosition(displayItems, newIndex, exercises);

      // Insert all exercises at new position (maintain their relative order)
      for (int i = 0; i < supersetExercises.length; i++) {
        exercises.insert(insertPos + i, supersetExercises[i]);
      }
    } else {
      // Single exercise - simple move
      final ex = exercises.removeAt(movedItem.singleIndex!);
      int insertPos = _calculateInsertPosition(displayItems, newIndex, exercises);
      exercises.insert(insertPos.clamp(0, exercises.length), ex);
    }

    // Convert exercises back to JSON for storage
    final exercisesJson = exercises.map((e) => e.toJson()).toList();

    setState(() => _workout = _workout!.copyWith(exercisesJson: exercisesJson));
    _scheduleAutoSave();
  }

  /// Calculate the actual exercise list position for a display index
  int _calculateInsertPosition(
    List<_ExerciseDisplayItem> displayItems,
    int targetDisplayIndex,
    List<WorkoutExercise> currentExercises,
  ) {
    if (targetDisplayIndex >= displayItems.length) {
      return currentExercises.length;
    }
    if (targetDisplayIndex <= 0) {
      return 0;
    }

    // Find the actual exercise index for the target display position
    int exerciseIndex = 0;
    for (int i = 0; i < targetDisplayIndex && i < displayItems.length; i++) {
      final item = displayItems[i];
      if (item.isSuperset) {
        exerciseIndex += item.exerciseCount; // Supersets can contain 2+ exercises
      } else {
        exerciseIndex += 1;
      }
    }
    return exerciseIndex.clamp(0, currentExercises.length);
  }

  /// Build exercise card widget (used for both single and superset exercises)
  /// [reorderIndex] is the index within the SliverReorderableList for drag handle reordering
  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    Color accentColor, {
    int? reorderIndex,
    bool isPendingPair = false,
    void Function(int draggedIndex)? onSupersetDrop,
  }) {
    return ExpandedExerciseCard(
      key: ValueKey(exercise.id ?? index),
      exercise: exercise,
      index: index,
      workoutId: widget.workoutId,
      initiallyExpanded: false,
      reorderIndex: reorderIndex,
      isPendingPair: isPendingPair,
      onSupersetDrop: onSupersetDrop,  // Allow drop even if in superset (to add to tri-set/giant set)
      onTap: () {
        debugPrint('🎯 [WorkoutDetail] Exercise tapped: ${exercise.name}');
        context.push('/exercise-detail', extra: exercise);
      },
      onSwap: () async {
        final updatedWorkout = await showExerciseSwapSheet(
          context,
          ref,
          workoutId: widget.workoutId,
          exercise: exercise,
        );
        if (updatedWorkout != null) {
          setState(() => _workout = updatedWorkout);
        }
      },
      onLinkSuperset: exercise.isInSuperset
          ? null  // Already in a superset
          : () => _startSupersetPairing(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [WorkoutDetail] build() - _isLoading: $_isLoading, _isLoadingSummary: $_isLoadingSummary, _workoutSummary: ${_workoutSummary != null}');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    if (_error != null || _workout == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadWorkout,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final workout = _workout!;
    final exercises = workout.exercises;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Spacer for top bar
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 60),
              ),

              // Type badges row - single line horizontal scroll
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Workout Type Badge - now with semantic color
                        _buildLabeledBadge(
                          label: 'Type',
                          value: (workout.type ?? 'strength').capitalize(),
                          color: AppColors.getWorkoutTypeColor(workout.type ?? 'strength'),
                          backgroundColor: AppColors.getWorkoutTypeColor(workout.type ?? 'strength').withOpacity(0.15),
                        ),
                        const SizedBox(width: 8),
                        // Difficulty Badge - special animated version for Hell
                        if ((workout.difficulty ?? 'medium').toLowerCase() == 'hell')
                          const AnimatedHellBadge()
                        else
                          _buildLabeledBadge(
                            label: 'Difficulty',
                            value: DifficultyUtils.getDisplayName(workout.difficulty ?? 'medium'),
                            color: DifficultyUtils.getColor(workout.difficulty ?? 'medium'),
                            backgroundColor: DifficultyUtils.getColor(workout.difficulty ?? 'medium').withOpacity(0.15),
                          ),
                        // Training Program Badge (only show if we have a valid program name)
                        if (_trainingSplit != null && _getTrainingProgramName(_trainingSplit!) != null) ...[
                          const SizedBox(width: 8),
                          _buildLabeledBadge(
                            label: 'Program',
                            value: _getTrainingProgramName(_trainingSplit!)!,
                            color: accentColor,
                            backgroundColor: accentColor.withOpacity(0.15),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Fasting Training Warning (if applicable)
              SliverToBoxAdapter(
                child: FastingTrainingWarning(
                  workoutIntensity: workout.difficulty,
                  workoutType: workout.type,
                  durationMinutes: workout.durationMinutes,
                ),
              ),

              // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    value: '${workout.durationMinutes ?? 45}',
                    label: 'min',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.fitness_center,
                    value: '${exercises.length}',
                    label: 'exercises',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${workout.estimatedCalories}',
                    label: 'cal',
                    color: const Color(0xFFF97316),  // Orange fire color
                    useAnimatedFire: true,
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
              .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
          ),

          // ─────────────────────────────────────────────────────────────────
          // EQUIPMENT SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          if (workout.equipmentNeeded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCollapsibleSectionHeader(
                  title: 'EQUIPMENT',
                  icon: Icons.fitness_center,
                  color: Colors.blueGrey,
                  isExpanded: _isEquipmentExpanded,
                  onTap: () => setState(() => _isEquipmentExpanded = !_isEquipmentExpanded),
                  itemCount: workout.equipmentNeeded.length,
                  subtitle: workout.equipmentNeeded.take(3).join(', ') + (workout.equipmentNeeded.length > 3 ? '...' : ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Revert button (only shown when modifications exist)
                      if (_hasEquipmentModifications)
                        GestureDetector(
                          onTap: _revertToOriginalExercises,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              'Revert',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      // Edit button
                      GestureDetector(
                        onTap: () => _showEditEquipmentSheet(workout),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Equipment items (shown when expanded)
            if (_isEquipmentExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workout.equipmentNeeded.map((equipment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              equipment,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate()
                .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
                .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
              ),
          ],

          // ─────────────────────────────────────────────────────────────────
          // WARMUP SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'WARM UP',
                icon: Icons.whatshot,
                color: AppColors.orange,
                isExpanded: _isWarmupExpanded,
                onTap: () => setState(() => _isWarmupExpanded = !_isWarmupExpanded),
                itemCount: _getWarmupExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).warmupEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                },
              ),
            ),
          ),

          // Warmup items (shown when expanded)
          if (_isWarmupExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWarmupStretchItem(
                  _getWarmupExercises()[index],
                  AppColors.orange,
                ),
                childCount: _getWarmupExercises().length,
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // EXERCISES SECTION (with + icon)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.fitness_center, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EXERCISES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // kg/lb toggle button
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _toggleUnit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: accentColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_useKgOverride ?? ref.watch(useKgProvider)) ? 'kg' : 'lbs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add exercise button (+ icon)
                  GestureDetector(
                    onTap: () async {
                      final currentExerciseNames = exercises.map((e) => e.name).toList();
                      final updatedWorkout = await showExerciseAddSheet(
                        context,
                        ref,
                        workoutId: widget.workoutId,
                        workoutType: _workout?.type ?? 'strength',
                        currentExerciseNames: currentExerciseNames,
                      );
                      if (updatedWorkout != null) {
                        setState(() => _workout = updatedWorkout);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercise List with superset grouping, drag-to-superset, and reordering
          SliverReorderableList(
            itemCount: _groupExercisesForDisplay(exercises).length,
            onReorder: _reorderExercises,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 8).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ).value;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.transparent,
                    shadowColor: accentColor.withOpacity(0.3),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final displayItems = _groupExercisesForDisplay(exercises);
              if (index >= displayItems.length) return const SizedBox.shrink();
              final item = displayItems[index];

              // ─── SUPERSET GROUPED CARD (supports 2+ exercises) ───
              if (item.isSuperset) {
                // Build list of exercise widgets for the superset
                // Pass onSupersetDrop AND reorderIndex to enable DragTarget for adding more exercises
                final supersetExercises = item.supersetIndices!
                    .map((idx) => _buildExerciseCard(
                          exercises[idx],
                          idx,
                          accentColor,
                          reorderIndex: idx,  // Required for DragTarget to be created
                          onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, idx),
                        ))
                    .toList();

                return AnimationConfiguration.staggeredList(
                  key: ValueKey('superset-${item.groupNumber}'),
                  position: index,
                  duration: AppAnimations.listItem,
                  child: SlideAnimation(
                    verticalOffset: 20,
                    curve: AppAnimations.fastOut,
                    child: FadeInAnimation(
                      curve: AppAnimations.fastOut,
                      child: SupersetGroupCard(
                        groupNumber: item.groupNumber!,
                        isActive: false,
                        reorderIndex: index,
                        exercises: supersetExercises,
                        onBreakSuperset: () => _breakSuperset(item.groupNumber!),
                        onSwapOrder: item.exerciseCount == 2
                            ? () => _swapSupersetOrder(item.groupNumber!)
                            : null,
                        onReorderExercises: item.exerciseCount >= 3
                            ? () => _showReorderSheet(item.groupNumber!, item.supersetIndices!)
                            : null,
                      ),
                    ),
                  ),
                );
              }

              // ─── SINGLE EXERCISE ───
              // Drag strip handles both reordering (short drag) and superset creation (long-press drag)
              final exerciseIndex = item.singleIndex!;
              final exercise = exercises[exerciseIndex];
              final isPendingPair = _pendingSupersetIndex == exerciseIndex;

              return AnimationConfiguration.staggeredList(
                key: ValueKey('exercise-$exerciseIndex-${exercise.id ?? exercise.name}'),
                position: index,
                duration: AppAnimations.listItem,
                child: SlideAnimation(
                  verticalOffset: 20,
                  curve: AppAnimations.fastOut,
                  child: FadeInAnimation(
                    curve: AppAnimations.fastOut,
                    child: GestureDetector(
                      onTap: _pendingSupersetIndex != null &&
                              _pendingSupersetIndex != exerciseIndex
                          ? () => _createSuperset(_pendingSupersetIndex!, exerciseIndex)
                          : null,
                      child: _buildExerciseCard(
                        exercise,
                        exerciseIndex,
                        accentColor,
                        reorderIndex: index,
                        isPendingPair: isPendingPair,
                        onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, exerciseIndex),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ─────────────────────────────────────────────────────────────────
          // CHALLENGE SECTION (Collapsible) - For beginners and intermediate
          // ─────────────────────────────────────────────────────────────────
          if (workout.hasChallenge)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildCollapsibleSectionHeader(
                  title: 'WANT A CHALLENGE?',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  isExpanded: _isChallengeExpanded,
                  onTap: () => setState(() => _isChallengeExpanded = !_isChallengeExpanded),
                  itemCount: 1,
                  subtitle: workout.challengeExercise?.progressionFrom != null
                      ? 'Progression from ${workout.challengeExercise!.progressionFrom}'
                      : 'Try this advanced exercise',
                ),
              ),
            ),

          // Challenge exercise item (shown when expanded)
          if (workout.hasChallenge && _isChallengeExpanded)
            SliverToBoxAdapter(
              child: _buildChallengeExerciseCard(workout.challengeExercise!),
            ),

          // ─────────────────────────────────────────────────────────────────
          // STRETCHES SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'COOL DOWN STRETCHES',
                icon: Icons.self_improvement,
                color: AppColors.green,
                isExpanded: _isStretchesExpanded,
                onTap: () => setState(() => _isStretchesExpanded = !_isStretchesExpanded),
                itemCount: _getStretchExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).stretchEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                },
              ),
            ),
          ),

          // Stretches items (shown when expanded)
          if (_isStretchesExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWarmupStretchItem(
                  _getStretchExercises()[index],
                  AppColors.green,
                ),
                childCount: _getStretchExercises().length,
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // MORE INFO SECTION (Collapsible) - AI Insights moved here
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'MORE INFO',
                icon: Icons.lightbulb_outline,
                color: accentColor,
                isExpanded: _isMoreInfoExpanded,
                onTap: () => setState(() => _isMoreInfoExpanded = !_isMoreInfoExpanded),
                itemCount: 3,  // Summary, Muscles, AI Reasoning
                subtitle: 'AI insights & exercise details',
              ),
            ),
          ),

          // More Info content (shown when expanded)
          if (_isMoreInfoExpanded) ...[
            // Workout Summary Section (AI-generated)
            if (_workoutSummary != null || _isLoadingSummary)
              SliverToBoxAdapter(
                child: _buildWorkoutSummarySection(),
              ),

            // Targeted Muscles Section
            SliverToBoxAdapter(
              child: _buildTargetedMusclesSection(workout.primaryMuscles),
            ),

            // AI Reasoning Section (expandable)
            if (_generationParams != null || _isLoadingParams)
              SliverToBoxAdapter(
                child: _buildAIReasoningSection(),
              ),
          ],

          // Bottom padding for FAB and floating nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
      // Floating top bar - positioned below status bar
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Row(
          children: [
            // Back button - floating pill
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Workout name in center
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          workout.name ?? 'Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColorsLight.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isSaving) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: isDark ? Colors.white54 : AppColorsLight.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Menu button - floating pill
            GestureDetector(
              onTap: () => _showWorkoutActions(context, ref, workout),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      ],
      ),

      // Custom floating buttons: AI + Play
      floatingActionButton: _buildFloatingButtons(context, ref, workout),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingButtons(BuildContext context, WidgetRef ref, Workout workout) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
    final accentColor = ref.colors(context).accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Coach Button
        CoachAvatar(
          coach: coach,
          size: 48,
          showBorder: true,
          borderWidth: 2,
          showShadow: true,
          enableTapToView: false,
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to full chat screen for proper keyboard handling
            context.push('/chat');
          },
        ),
        const SizedBox(width: 12),
        // Let's Go Button - custom styled to ensure full text visibility
        GestureDetector(
          onTap: () => context.push('/active-workout', extra: workout),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 24,
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                ),
                const SizedBox(width: 8),
                Text(
                  "Let's Go",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showWorkoutActions(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await showWorkoutActionsSheet(
      context,
      ref,
      workout,
      onRefresh: () {
        _loadWorkout();
      },
    );
  }

  /// Strip markdown formatting from text
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')  // Bold
        .replaceAll(RegExp(r'\*'), '')    // Italic
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'^-\s*', multiLine: true), '') // List items
        .replaceAll(RegExp(r'^•\s*', multiLine: true), '') // Bullet points
        .replaceAll(RegExp(r'`'), '')     // Code
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // Links
        .trim();
  }

  /// Get color from string name
  Color _getColorFromName(String colorName, Color accentColor) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return accentColor;
      case 'purple':
        return accentColor;
      case 'orange':
        return AppColors.orange;
      case 'green':
        return AppColors.green;
      default:
        return accentColor;
    }
  }

  /// Parse structured JSON insights
  Map<String, dynamic>? _parseInsightsJson(String? summary) {
    if (summary == null) return null;
    try {
      return json.decode(summary) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ [WorkoutDetail] Failed to parse insights JSON: $e');
      return null;
    }
  }

  /// Build a labeled badge with "Label: Value" format for clarity
  Widget _buildLabeledBadge({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummarySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;

    // Try to parse JSON insights
    final insights = _parseInsightsJson(_workoutSummary);
    String? shortPreview;

    if (insights != null) {
      // Use headline from structured JSON
      shortPreview = insights['headline'] as String?;
    } else if (_workoutSummary != null) {
      // Fallback: strip markdown and take first few words
      final cleanSummary = _stripMarkdown(_workoutSummary!);
      final words = cleanSummary.split(' ');
      if (words.length <= 6) {
        shortPreview = cleanSummary;
      } else {
        shortPreview = '${words.take(6).join(' ')}...';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: _workoutSummary != null ? () => _showAIInsightsPopup(_workoutSummary!) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.15),
                accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI INSIGHTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_isLoadingSummary)
                      Text(
                        'Generating insights...',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (shortPreview != null)
                      Text(
                        shortPreview,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!_isLoadingSummary && _workoutSummary != null)
                Icon(
                  Icons.open_in_new,
                  color: accentColor.withOpacity(0.7),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show AI insights in a draggable popup modal with formatted sections
  void _showAIInsightsPopup(String summaryJson) {
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentColor = ref.colors(context).accent;

    // Parse JSON insights - use mutable state that persists across rebuilds
    var currentSummary = summaryJson;
    var insights = _parseInsightsJson(currentSummary);
    var headline = insights?['headline'] as String? ?? 'Workout Insights';
    var sections = (insights?['sections'] as List<dynamic>?) ?? [];
    var isRegenerating = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> regenerateInsights() async {
            setModalState(() => isRegenerating = true);
            try {
              final workoutRepo = ref.read(workoutRepositoryProvider);
              final newSummary = await workoutRepo.regenerateWorkoutSummary(widget.workoutId);
              if (newSummary != null) {
                currentSummary = newSummary;
                insights = _parseInsightsJson(newSummary);
                headline = insights?['headline'] as String? ?? 'Workout Insights';
                sections = (insights?['sections'] as List<dynamic>?) ?? [];
                // Also update the parent state
                setState(() {
                  _workoutSummary = newSummary;
                });
              }
            } catch (e) {
              debugPrint('❌ Error regenerating insights: $e');
            }
            setModalState(() => isRegenerating = false);
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draggable handle bar
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textMuted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Header with headline
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            headline,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        // Regenerate button
                        IconButton(
                          onPressed: isRegenerating ? null : regenerateInsights,
                          tooltip: 'Regenerate insights',
                          icon: isRegenerating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentColor,
                                  ),
                                )
                              : Icon(Icons.refresh, color: accentColor),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Divider(
                    color: cardBorder.withOpacity(0.3),
                    height: 1,
                  ),
                  // Content - structured sections
                  Expanded(
                    child: isRegenerating
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: accentColor),
                                const SizedBox(height: 16),
                                Text(
                                  'Generating new insights...',
                                  style: TextStyle(color: textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (sections.isNotEmpty)
                                ...sections.map((section) {
                                  final icon = section['icon'] as String? ?? '💡';
                                  final title = section['title'] as String? ?? 'Tip';
                                  final content = section['content'] as String? ?? '';
                                  final colorName = section['color'] as String? ?? 'cyan';
                                  final color = _getColorFromName(colorName, accentColor);

                                  return _buildInsightSection(icon, title, content, color, textPrimary);
                                })
                              else
                                // Fallback for non-JSON or parse error
                                Text(
                                  _stripMarkdown(currentSummary),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                              // Extra padding at bottom
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a single insight section with icon, colored title, and content
  Widget _buildInsightSection(String icon, String title, String content, Color color, Color textPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          // Title + Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract just the main muscle name (remove parenthetical details)
  String _shortenMuscleName(String muscle) {
    // Extract just the main name before parentheses
    // e.g., "Quadriceps (Quadriceps Femoris)" -> "Quadriceps"
    final match = RegExp(r'^([^(]+)').firstMatch(muscle);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // If comma separated, take first part
    if (muscle.contains(',')) {
      return muscle.split(',').first.trim();
    }
    return muscle.trim();
  }

  /// Build targeted muscles section - compact version
  Widget _buildTargetedMusclesSection(List<String> muscles) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // Extract unique short muscle names, filtering out empty strings
    final shortMuscles = muscles
        .map(_shortenMuscleName)
        .where((m) => m.isNotEmpty)
        .toSet()
        .take(6) // Max 6 muscles shown
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.accessibility_new,
                color: accentColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: shortMuscles.map((muscle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscle,
                      style: TextStyle(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Build AI Reasoning section - expandable section showing why exercises were selected
  Widget _buildAIReasoningSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Expandable header
          GestureDetector(
            onTap: () => setState(() => _isAIReasoningExpanded = !_isAIReasoningExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withOpacity(0.15),
                    accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(_isAIReasoningExpanded ? 0 : 12),
                  bottomRight: Radius.circular(_isAIReasoningExpanded ? 0 : 12),
                ),
                border: Border.all(
                  color: AppColors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY THESE EXERCISES?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_isLoadingParams)
                          Text(
                            'Loading AI reasoning...',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Text(
                            'Tap to see AI reasoning for exercise selection',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isAIReasoningExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.green,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_isAIReasoningExpanded && _generationParams != null)
            Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: cardBorder.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall workout reasoning
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Workout Design',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generationParams!.workoutReasoning,
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: cardBorder.withOpacity(0.3), height: 1),
                  // Exercise-specific reasoning
                  if (_generationParams!.exerciseReasoning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exercise Selection',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._generationParams!.exerciseReasoning.take(5).map((er) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6, right: 10),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          er.exerciseName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          er.reasoning,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_generationParams!.exerciseReasoning.length > 5)
                            Text(
                              '+ ${_generationParams!.exerciseReasoning.length - 5} more exercises...',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // View Parameters button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: () => _showViewParametersModal(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              color: AppColors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View All Parameters Sent to AI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange,
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
        ],
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show modal with all parameters sent to AI
  void _showViewParametersModal() {
    if (_generationParams == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final params = _generationParams!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Draggable handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withOpacity(0.3),
                            accentColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: AppColors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Generation Parameters',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder.withOpacity(0.3), height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Profile Section
                    _buildParamsSection(
                      title: 'User Profile',
                      icon: Icons.person,
                      color: accentColor,
                      items: [
                        if (params.userProfile.fitnessLevel != null)
                          _ParamItem('Fitness Level', params.userProfile.fitnessLevel!.capitalize()),
                        if (params.userProfile.goals.isNotEmpty)
                          _ParamItem('Goals', params.userProfile.goals.join(', ')),
                        if (params.userProfile.equipment.isNotEmpty)
                          _ParamItem('Equipment', params.userProfile.equipment.join(', ')),
                        if (params.userProfile.injuries.isNotEmpty)
                          _ParamItem('Injuries/Limitations', params.userProfile.injuries.join(', ')),
                        if (params.userProfile.age != null)
                          _ParamItem('Age', '${params.userProfile.age}'),
                        if (params.userProfile.gender != null)
                          _ParamItem('Gender', params.userProfile.gender!.capitalize()),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Program Preferences Section
                    _buildParamsSection(
                      title: 'Program Preferences',
                      icon: Icons.settings,
                      color: accentColor,
                      items: [
                        if (params.programPreferences.difficulty != null)
                          _ParamItem('Difficulty', DifficultyUtils.getDisplayName(params.programPreferences.difficulty!)),
                        if (params.programPreferences.durationMinutes != null)
                          _ParamItem('Duration', '${params.programPreferences.durationMinutes} min'),
                        if (params.programPreferences.workoutType != null)
                          _ParamItem('Workout Type', params.programPreferences.workoutType!.capitalize()),
                        if (params.programPreferences.trainingSplit != null)
                          _ParamItem('Training Split', params.programPreferences.trainingSplit!.replaceAll('_', ' ').capitalize()),
                        if (params.programPreferences.focusAreas.isNotEmpty)
                          _ParamItem('Focus Areas', params.programPreferences.focusAreas.join(', ')),
                        if (params.programPreferences.workoutDays.isNotEmpty)
                          _ParamItem('Workout Days', params.programPreferences.workoutDays.join(', ')),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Workout Specifics Section
                    _buildParamsSection(
                      title: 'Workout Specifics',
                      icon: Icons.fitness_center,
                      color: AppColors.green,
                      items: [
                        _ParamItem('Workout Name', params.workoutName ?? 'N/A'),
                        _ParamItem('Type', (params.workoutType ?? 'N/A').capitalize()),
                        _ParamItem('Difficulty', params.difficulty != null ? DifficultyUtils.getDisplayName(params.difficulty!) : 'N/A'),
                        _ParamItem('Duration', '${params.durationMinutes ?? 0} min'),
                        _ParamItem('Generation Method', (params.generationMethod ?? 'ai').toUpperCase()),
                        if (params.targetMuscles.isNotEmpty)
                          _ParamItem('Target Muscles', params.targetMuscles.join(', ')),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These parameters were used by the AI to generate personalized exercises that match your fitness level, goals, and available equipment.',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section in the parameters modal
  Widget _buildParamsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_ParamItem> items,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Filter out empty items
    final validItems = items.where((item) => item.value.isNotEmpty && item.value != 'N/A').toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cardBorder.withOpacity(0.3), height: 1),
          // Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: validItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build collapsible section header for warmup/stretches
  Widget _buildCollapsibleSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required int itemCount,
    String? subtitle,
    bool? toggleValue,
    ValueChanged<bool>? onToggleChanged,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$itemCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Toggle switch (if provided)
            if (toggleValue != null && onToggleChanged != null) ...[
              GestureDetector(
                onTap: () {}, // Absorb tap to prevent collapse/expand
                child: Switch.adaptive(
                  value: toggleValue,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    onToggleChanged(value);
                  },
                  activeColor: color,
                ),
              ),
              const SizedBox(width: 4),
            ],
            // Custom trailing widget (if provided)
            if (trailing != null) ...[
              GestureDetector(
                onTap: () {}, // Absorb tap to prevent collapse/expand
                child: trailing,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Build warmup exercises (static list for now)
  List<Map<String, String>> _getWarmupExercises() {
    return [
      {'name': 'Jumping Jacks', 'duration': '60 sec'},
      {'name': 'Arm Circles', 'duration': '30 sec'},
      {'name': 'Hip Circles', 'duration': '30 sec'},
      {'name': 'Leg Swings', 'duration': '30 sec each'},
      {'name': 'Light Cardio', 'duration': '2-3 min'},
    ];
  }

  /// Build stretch exercises (static list for now)
  List<Map<String, String>> _getStretchExercises() {
    return [
      {'name': 'Quad Stretch', 'duration': '30 sec each'},
      {'name': 'Hamstring Stretch', 'duration': '30 sec each'},
      {'name': 'Shoulder Stretch', 'duration': '30 sec each'},
      {'name': 'Chest Opener', 'duration': '30 sec'},
      {'name': 'Cat-Cow Stretch', 'duration': '60 sec'},
    ];
  }

  /// Build warmup/stretch item
  /// Build challenge exercise card for beginners
  Widget _buildChallengeExerciseCard(WorkoutExercise exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final color = Colors.orange;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise thumbnail/icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.gifUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_fire_department,
                              color: color,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.local_fire_department,
                          color: color,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CHALLENGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (exercise.difficulty != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              exercise.difficulty!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            exercise.setsRepsDisplay,
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (exercise.restSeconds != null) ...[
                            Icon(Icons.timer_outlined, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${exercise.restSeconds}s rest',
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Note about challenge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.white24,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is an optional advanced exercise. Try it when you feel ready!',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupStretchItem(Map<String, String> item, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['name'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item['duration'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool useAnimatedFire;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.useAnimatedFire = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Use animated fire icon for calories, static icon otherwise
            if (useAnimatedFire)
              AnimatedFireIcon(size: 24, color: color)
            else
              Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Param Item (helper for parameters modal)
// ─────────────────────────────────────────────────────────────────

class _ParamItem {
  final String label;
  final String value;

  _ParamItem(this.label, this.value);
}


// ─────────────────────────────────────────────────────────────────
// String Extension
// ─────────────────────────────────────────────────────────────────

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}


// ─────────────────────────────────────────────────────────────────
// Animated Fire Icon - Flickering flame effect for calorie stat
// ─────────────────────────────────────────────────────────────────

class AnimatedFireIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedFireIcon({
    super.key,
    this.size = 24,
    this.color = const Color(0xFFF97316),
  });

  @override
  State<AnimatedFireIcon> createState() => _AnimatedFireIconState();
}

class _AnimatedFireIconState extends State<AnimatedFireIcon>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _glowController;
  late Animation<double> _flickerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Fast flicker for flame movement (quick random-ish changes)
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Slower breathing/glow pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Flicker intensity - simulates flame brightness variation
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.95), weight: 1),
    ]).animate(_flickerController);

    // Scale breathing - flame grows and shrinks
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Slight rotation wobble - flame dancing
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _flickerController.repeat();
    _glowController.repeat();
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flickerController, _glowController]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.yellow.withValues(alpha: _flickerAnimation.value),
                    widget.color,
                    const Color(0xFFDC2626).withValues(alpha: 0.9), // Darker red at base
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Icon(
                Icons.local_fire_department,
                size: widget.size,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Animated Hell Badge - Radiating glow for maximum intensity
// ─────────────────────────────────────────────────────────────────

class AnimatedHellBadge extends StatefulWidget {
  final String label;
  final String value;

  const AnimatedHellBadge({
    super.key,
    this.label = 'Difficulty',
    this.value = 'Hell',
  });

  @override
  State<AnimatedHellBadge> createState() => _AnimatedHellBadgeState();
}

class _AnimatedHellBadgeState extends State<AnimatedHellBadge>
    with TickerProviderStateMixin {
  static const Color hellRed = Color(0xFFEF4444);

  late AnimationController _glowController;
  late AnimationController _fireController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fireScaleAnimation;
  late Animation<double> _fireRotationAnimation;

  @override
  void initState() {
    super.initState();

    // Glow pulsing
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fire flickering
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.2), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _fireScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));

    _fireRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat();
    _fireController.repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _fireController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: hellRed.withValues(alpha: _glowAnimation.value),
                blurRadius: 8 + (_glowAnimation.value * 12),
                spreadRadius: _glowAnimation.value * 4,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hellRed.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hellRed.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flickering fire icon
                Transform.rotate(
                  angle: _fireRotationAnimation.value,
                  child: Transform.scale(
                    scale: _fireScaleAnimation.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.yellow,
                            Color(0xFFF97316), // Orange
                            hellRed,
                          ],
                          stops: [0.0, 0.4, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: hellRed.withValues(alpha: 0.8),
                      ),
                    ),
                    const Text(
                      'Hell',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hellRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Display item for exercise list - either a single exercise or a superset group (2+ exercises)
class _ExerciseDisplayItem {
  final bool isSuperset;
  final int? singleIndex;
  final List<int>? supersetIndices;  // All exercise indices in the superset, sorted by order
  final int? groupNumber;

  _ExerciseDisplayItem.single({required int index})
      : isSuperset = false,
        singleIndex = index,
        supersetIndices = null,
        groupNumber = null;

  _ExerciseDisplayItem.superset({
    required List<int> indices,
    required int group,
  })  : isSuperset = true,
        supersetIndices = indices,
        groupNumber = group,
        singleIndex = null;

  /// For backward compatibility - first exercise index
  int? get firstIndex => supersetIndices?.isNotEmpty == true ? supersetIndices!.first : null;

  /// For backward compatibility - second exercise index
  int? get secondIndex => supersetIndices != null && supersetIndices!.length > 1 ? supersetIndices![1] : null;

  /// Number of exercises in this superset
  int get exerciseCount => supersetIndices?.length ?? 0;
}

/// Groups exercises for display, grouping all superset exercises together (supports 2+ exercises)
List<_ExerciseDisplayItem> _groupExercisesForDisplay(List<WorkoutExercise> exercises) {
  final items = <_ExerciseDisplayItem>[];
  final processed = <int>{};

  // First, group all exercises by their supersetGroup
  final supersetGroups = <int, List<int>>{};
  for (int i = 0; i < exercises.length; i++) {
    final ex = exercises[i];
    if (ex.isInSuperset) {
      supersetGroups.putIfAbsent(ex.supersetGroup!, () => []).add(i);
    }
  }

  // Sort each group by supersetOrder
  for (final group in supersetGroups.values) {
    group.sort((a, b) =>
        (exercises[a].supersetOrder ?? 0).compareTo(exercises[b].supersetOrder ?? 0));
  }

  for (int i = 0; i < exercises.length; i++) {
    if (processed.contains(i)) continue;
    final ex = exercises[i];

    // Check if this exercise is part of a superset
    if (ex.isInSuperset && supersetGroups.containsKey(ex.supersetGroup)) {
      final groupIndices = supersetGroups[ex.supersetGroup]!;
      // Only add the superset item once (when we encounter any exercise in it)
      if (groupIndices.isNotEmpty) {
        items.add(_ExerciseDisplayItem.superset(
          indices: List.from(groupIndices),
          group: ex.supersetGroup!,
        ));
        processed.addAll(groupIndices);
        continue;
      }
    }

    // Single exercise (not in a superset)
    if (!ex.isInSuperset) {
      items.add(_ExerciseDisplayItem.single(index: i));
      processed.add(i);
    }
  }
  return items;
}

// ─────────────────────────────────────────────────────────────────
// EQUIPMENT CHANGE ANALYSIS HELPERS
// ─────────────────────────────────────────────────────────────────

/// Analysis result for equipment changes
class _EquipmentChangeAnalysis {
  final List<_ExerciseWeightAdjustment> weightAdjustments;
  final List<WorkoutExercise> exercisesToReplace;

  _EquipmentChangeAnalysis({
    required this.weightAdjustments,
    required this.exercisesToReplace,
  });
}

/// Weight adjustment for a single exercise
class _ExerciseWeightAdjustment {
  final WorkoutExercise exercise;
  final double oldWeight;
  final double newWeight;

  _ExerciseWeightAdjustment({
    required this.exercise,
    required this.oldWeight,
    required this.newWeight,
  });
}

/// Progress dialog for quick exercise replacement
class _QuickReplaceProgressDialog extends StatelessWidget {
  final int total;

  const _QuickReplaceProgressDialog({required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Updating Exercises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Replacing $total exercise${total > 1 ? 's' : ''} for available equipment...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
