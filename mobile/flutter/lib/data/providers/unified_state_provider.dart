import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_preferences.dart';
import '../models/fasting.dart';
import '../models/workout.dart';
import '../services/dynamic_nutrition_service.dart';
import 'fasting_provider.dart';
import 'nutrition_preferences_provider.dart';

// ============================================
// App State Enum
// ============================================

/// Current app state based on fasting, workout, and nutrition context
enum AppState {
  fastingActive('Fasting', 'Currently in a fasting window'),
  eatingWindow('Eating Window', 'Eating window is open'),
  preworkout('Pre-Workout', 'Workout scheduled soon'),
  duringWorkout('Active Workout', 'Currently working out'),
  postWorkout('Post-Workout', 'Recovery period after workout'),
  restDay('Rest Day', 'No workout scheduled today');

  final String displayName;
  final String description;

  const AppState(this.displayName, this.description);
}

// ============================================
// Unified State
// ============================================

/// Unified state combining fasting, nutrition, and workout contexts
class UnifiedState {
  // Core state
  final AppState currentState;
  final DateTime lastUpdated;

  // Fasting context
  final FastingRecord? activeFast;
  final FastingPreferences? fastingPreferences;
  final FastingZone? currentFastingZone;
  final int hoursFasted;
  final bool isInEatingWindow;

  // Nutrition context
  final NutritionPreferences? nutritionPreferences;
  final DynamicTargetsResult? dynamicTargets;
  final bool isTrainingDay;
  final bool isFastingDay;
  final bool isRestDay;

  // Workout context
  final Workout? todaysWorkout;
  final bool hasWorkoutScheduled;
  final bool workoutCompleted;
  final DateTime? workoutCompletedAt;
  final int minutesSinceWorkout;

  // Conflicts and warnings
  final List<StateConflict> conflicts;
  final List<String> warnings;

  const UnifiedState({
    required this.currentState,
    required this.lastUpdated,
    this.activeFast,
    this.fastingPreferences,
    this.currentFastingZone,
    this.hoursFasted = 0,
    this.isInEatingWindow = true,
    this.nutritionPreferences,
    this.dynamicTargets,
    this.isTrainingDay = false,
    this.isFastingDay = false,
    this.isRestDay = true,
    this.todaysWorkout,
    this.hasWorkoutScheduled = false,
    this.workoutCompleted = false,
    this.workoutCompletedAt,
    this.minutesSinceWorkout = 0,
    this.conflicts = const [],
    this.warnings = const [],
  });

  UnifiedState copyWith({
    AppState? currentState,
    DateTime? lastUpdated,
    FastingRecord? activeFast,
    FastingPreferences? fastingPreferences,
    FastingZone? currentFastingZone,
    int? hoursFasted,
    bool? isInEatingWindow,
    NutritionPreferences? nutritionPreferences,
    DynamicTargetsResult? dynamicTargets,
    bool? isTrainingDay,
    bool? isFastingDay,
    bool? isRestDay,
    Workout? todaysWorkout,
    bool? hasWorkoutScheduled,
    bool? workoutCompleted,
    DateTime? workoutCompletedAt,
    int? minutesSinceWorkout,
    List<StateConflict>? conflicts,
    List<String>? warnings,
    bool clearActiveFast = false,
    bool clearWorkout = false,
  }) {
    return UnifiedState(
      currentState: currentState ?? this.currentState,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      activeFast: clearActiveFast ? null : (activeFast ?? this.activeFast),
      fastingPreferences: fastingPreferences ?? this.fastingPreferences,
      currentFastingZone: currentFastingZone ?? this.currentFastingZone,
      hoursFasted: hoursFasted ?? this.hoursFasted,
      isInEatingWindow: isInEatingWindow ?? this.isInEatingWindow,
      nutritionPreferences: nutritionPreferences ?? this.nutritionPreferences,
      dynamicTargets: dynamicTargets ?? this.dynamicTargets,
      isTrainingDay: isTrainingDay ?? this.isTrainingDay,
      isFastingDay: isFastingDay ?? this.isFastingDay,
      isRestDay: isRestDay ?? this.isRestDay,
      todaysWorkout: clearWorkout ? null : (todaysWorkout ?? this.todaysWorkout),
      hasWorkoutScheduled: hasWorkoutScheduled ?? this.hasWorkoutScheduled,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      workoutCompletedAt: workoutCompletedAt ?? this.workoutCompletedAt,
      minutesSinceWorkout: minutesSinceWorkout ?? this.minutesSinceWorkout,
      conflicts: conflicts ?? this.conflicts,
      warnings: warnings ?? this.warnings,
    );
  }

  /// Check if there are any active conflicts
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if user is currently fasting
  bool get isFasting => activeFast != null;

  /// Check if safe to do high intensity workout
  bool get safeForHighIntensity {
    if (!isFasting) return true;
    return hoursFasted < 14;
  }

  /// Get recommended action based on current state
  String get recommendedAction {
    switch (currentState) {
      case AppState.fastingActive:
        if (hasWorkoutScheduled && !safeForHighIntensity) {
          return 'Consider eating before your high-intensity workout';
        }
        return 'Stay hydrated and focus on activities';
      case AppState.eatingWindow:
        if (workoutCompleted && minutesSinceWorkout < 120) {
          return 'Prioritize a protein-rich recovery meal';
        }
        return 'Focus on hitting your nutrition targets';
      case AppState.preworkout:
        if (isFasting) {
          return 'Light workout is fine fasted, eat for high intensity';
        }
        return 'Have a light snack 1-2 hours before workout';
      case AppState.duringWorkout:
        return 'Focus on your workout, stay hydrated';
      case AppState.postWorkout:
        return 'Time for recovery nutrition - protein and carbs';
      case AppState.restDay:
        return 'Focus on recovery and hitting your targets';
    }
  }
}

// ============================================
// State Conflict
// ============================================

/// Represents a conflict between fasting and workout schedules
class StateConflict {
  final ConflictType type;
  final String severity; // 'low', 'medium', 'high'
  final String title;
  final String description;
  final List<String> suggestions;
  final Workout? relatedWorkout;

  const StateConflict({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
    this.relatedWorkout,
  });
}

/// Types of conflicts that can occur
enum ConflictType {
  highIntensityExtendedFast,
  enduranceDuringFast,
  postWorkoutOutsideEatingWindow,
  heavyTrainingOnFastingDay,
}

// ============================================
// Unified State Notifier
// ============================================

/// Notifier for managing unified state across the app
class UnifiedStateNotifier extends StateNotifier<UnifiedState> {
  final Ref _ref;

  UnifiedStateNotifier(this._ref)
      : super(UnifiedState(
          currentState: AppState.restDay,
          lastUpdated: DateTime.now(),
        ));

  /// Update unified state based on current fasting, nutrition, and workout data
  void updateState({
    FastingState? fastingState,
    NutritionPreferencesState? nutritionState,
    Workout? todaysWorkout,
    bool? workoutCompleted,
    DateTime? workoutCompletedAt,
    String? gender,
  }) {
    debugPrint('🔄 [UnifiedState] Updating state');

    final now = DateTime.now();

    // Extract fasting info
    final activeFast = fastingState?.activeFast;
    final fastingPrefs = fastingState?.preferences;
    final hoursFasted = activeFast?.elapsedHours ?? 0;
    final currentZone = activeFast?.currentZone;

    // Extract nutrition info
    final nutritionPrefs = nutritionState?.preferences;

    // Calculate dynamic targets if we have the data
    DynamicTargetsResult? dynamicTargets;
    if (nutritionPrefs != null) {
      final dynamicService = _ref.read(dynamicNutritionServiceProvider);
      dynamicTargets = dynamicService.calculateTodaysTargets(
        preferences: nutritionPrefs,
        todaysWorkout: todaysWorkout,
        workoutCompleted: workoutCompleted ?? false,
        fastingPreferences: fastingPrefs,
        activeFast: activeFast,
        gender: gender ?? 'male',
      );
    }

    // Calculate minutes since workout
    int minutesSinceWorkout = 0;
    if (workoutCompletedAt != null) {
      minutesSinceWorkout = now.difference(workoutCompletedAt).inMinutes;
    }

    // Determine current app state
    final appState = _calculateAppState(
      activeFast: activeFast,
      fastingPrefs: fastingPrefs,
      todaysWorkout: todaysWorkout,
      workoutCompleted: workoutCompleted ?? false,
      minutesSinceWorkout: minutesSinceWorkout,
    );

    // Detect conflicts
    final conflicts = _detectConflicts(
      fastingPrefs: fastingPrefs,
      todaysWorkout: todaysWorkout,
      hoursFasted: hoursFasted,
      dynamicTargets: dynamicTargets,
    );

    // Generate warnings
    final warnings = _generateWarnings(
      activeFast: activeFast,
      hoursFasted: hoursFasted,
      todaysWorkout: todaysWorkout,
      workoutCompleted: workoutCompleted ?? false,
      minutesSinceWorkout: minutesSinceWorkout,
    );

    state = state.copyWith(
      currentState: appState,
      lastUpdated: now,
      activeFast: activeFast,
      fastingPreferences: fastingPrefs,
      currentFastingZone: currentZone,
      hoursFasted: hoursFasted,
      isInEatingWindow: activeFast == null,
      nutritionPreferences: nutritionPrefs,
      dynamicTargets: dynamicTargets,
      isTrainingDay: dynamicTargets?.isTrainingDay ?? (todaysWorkout != null),
      isFastingDay: dynamicTargets?.isFastingDay ?? false,
      isRestDay: dynamicTargets?.isRestDay ?? (todaysWorkout == null),
      todaysWorkout: todaysWorkout,
      hasWorkoutScheduled: todaysWorkout != null,
      workoutCompleted: workoutCompleted,
      workoutCompletedAt: workoutCompletedAt,
      minutesSinceWorkout: minutesSinceWorkout,
      conflicts: conflicts,
      warnings: warnings,
    );

    debugPrint('✅ [UnifiedState] State updated: ${appState.displayName}, conflicts=${conflicts.length}, warnings=${warnings.length}');
  }

  /// Calculate current app state based on all factors
  AppState _calculateAppState({
    FastingRecord? activeFast,
    FastingPreferences? fastingPrefs,
    Workout? todaysWorkout,
    required bool workoutCompleted,
    required int minutesSinceWorkout,
  }) {
    // Priority 1: Active fast
    if (activeFast != null) {
      return AppState.fastingActive;
    }

    // Priority 2: Post-workout recovery (within 2 hours)
    if (workoutCompleted && minutesSinceWorkout < 120) {
      return AppState.postWorkout;
    }

    // Priority 3: Pre-workout (within 2 hours of scheduled workout)
    // Note: This would need scheduled time info to be accurate
    // For now, check if there's an incomplete workout today
    if (todaysWorkout != null && !workoutCompleted) {
      // Assume if workout exists and not completed, could be pre-workout
      return AppState.preworkout;
    }

    // Priority 4: Eating window (no active fast, completed workout or rest day)
    if (todaysWorkout != null && workoutCompleted) {
      return AppState.eatingWindow;
    }

    // Priority 5: Rest day (no workout scheduled)
    if (todaysWorkout == null) {
      return AppState.restDay;
    }

    return AppState.eatingWindow;
  }

  /// Detect conflicts between fasting and workout schedules
  List<StateConflict> _detectConflicts({
    FastingPreferences? fastingPrefs,
    Workout? todaysWorkout,
    required int hoursFasted,
    DynamicTargetsResult? dynamicTargets,
  }) {
    final conflicts = <StateConflict>[];

    if (todaysWorkout == null) return conflicts;

    final workoutIntensity = todaysWorkout.difficulty?.toLowerCase() ?? 'moderate';
    final isHighIntensity =
        workoutIntensity.contains('hard') || workoutIntensity.contains('high');

    // Conflict 1: High intensity during extended fast
    if (isHighIntensity && hoursFasted > 14) {
      conflicts.add(StateConflict(
        type: ConflictType.highIntensityExtendedFast,
        severity: 'high',
        title: 'High-Intensity Workout During Extended Fast',
        description: 'You\'ve been fasting for $hoursFasted hours. '
            'High-intensity workouts aren\'t recommended after 14+ hours fasted.',
        suggestions: [
          'Move workout to eating window',
          'Switch to lighter exercise',
          'Have a small pre-workout snack (will break fast)',
        ],
        relatedWorkout: todaysWorkout,
      ));
    }

    // Conflict 2: Endurance workout during fast
    if ((todaysWorkout.durationMinutes ?? 0) > 60 && hoursFasted > 12) {
      conflicts.add(StateConflict(
        type: ConflictType.enduranceDuringFast,
        severity: 'medium',
        title: 'Long Workout During Fast',
        description: 'Long workouts (${todaysWorkout.durationMinutes}+ min) need fuel.',
        suggestions: [
          'Schedule for eating window',
          'Reduce duration',
          'Bring emergency fuel',
        ],
        relatedWorkout: todaysWorkout,
      ));
    }

    // Conflict 3: Heavy training on fasting day (5:2, ADF)
    if (dynamicTargets?.isFastingDay == true && isHighIntensity) {
      conflicts.add(StateConflict(
        type: ConflictType.heavyTrainingOnFastingDay,
        severity: 'medium',
        title: 'Heavy Training on Fasting Day',
        description: 'Intense workouts on 5:2/ADF fasting days may impact performance and recovery.',
        suggestions: [
          'Move intense workouts to normal eating days',
          'Do light cardio on fasting days',
          'Adjust fasting days around workout schedule',
        ],
        relatedWorkout: todaysWorkout,
      ));
    }

    return conflicts;
  }

  /// Generate warnings based on current state
  List<String> _generateWarnings({
    FastingRecord? activeFast,
    required int hoursFasted,
    Workout? todaysWorkout,
    required bool workoutCompleted,
    required int minutesSinceWorkout,
  }) {
    final warnings = <String>[];

    // Warning: Extended fast approaching danger zone
    if (activeFast != null && hoursFasted >= 24) {
      warnings.add('Extended fast - ensure adequate hydration and consider consulting a healthcare provider.');
    }

    // Warning: Post-workout nutrition delayed
    if (workoutCompleted && minutesSinceWorkout > 60 && minutesSinceWorkout < 120) {
      warnings.add('Post-workout nutrition window closing - prioritize a protein-rich meal soon.');
    }

    // Warning: Fasted training in progress
    if (activeFast != null && todaysWorkout != null && !workoutCompleted) {
      if (hoursFasted >= 12) {
        warnings.add('Training fasted for ${hoursFasted}h - listen to your body and hydrate well.');
      }
    }

    return warnings;
  }
}

// ============================================
// Providers
// ============================================

/// Unified state provider
final unifiedStateProvider =
    StateNotifierProvider<UnifiedStateNotifier, UnifiedState>((ref) {
  return UnifiedStateNotifier(ref);
});

/// Current app state provider (convenience)
final currentAppStateProvider = Provider<AppState>((ref) {
  return ref.watch(unifiedStateProvider).currentState;
});

/// Has conflicts provider (convenience)
final hasConflictsProvider = Provider<bool>((ref) {
  return ref.watch(unifiedStateProvider).hasConflicts;
});

/// Conflicts list provider (convenience)
final stateConflictsProvider = Provider<List<StateConflict>>((ref) {
  return ref.watch(unifiedStateProvider).conflicts;
});

/// Safe for high intensity provider (convenience)
final safeForHighIntensityProvider = Provider<bool>((ref) {
  return ref.watch(unifiedStateProvider).safeForHighIntensity;
});

/// Recommended action provider (convenience)
final recommendedActionProvider = Provider<String>((ref) {
  return ref.watch(unifiedStateProvider).recommendedAction;
});

// ============================================
// AI Coach Context Provider
// ============================================

/// Provides context string for AI coach integration
final aiCoachContextProvider = Provider<String>((ref) {
  final state = ref.watch(unifiedStateProvider);

  final buffer = StringBuffer();

  buffer.writeln('## User\'s Current State');
  buffer.writeln();

  // Fasting status
  buffer.writeln('### Fasting Status');
  buffer.writeln('- Currently fasting: ${state.isFasting}');
  if (state.isFasting) {
    buffer.writeln('- Hours fasted: ${state.hoursFasted}');
    buffer.writeln('- Current zone: ${state.currentFastingZone?.displayName ?? "Unknown"}');
  }
  if (state.fastingPreferences != null) {
    buffer.writeln('- Protocol: ${state.fastingPreferences!.defaultProtocol}');
  }
  buffer.writeln();

  // Workout status
  buffer.writeln('### Today\'s Workout');
  buffer.writeln('- Has workout scheduled: ${state.hasWorkoutScheduled}');
  if (state.todaysWorkout != null) {
    buffer.writeln('- Type: ${state.todaysWorkout!.type ?? "General"}');
    buffer.writeln('- Intensity: ${state.todaysWorkout!.difficulty ?? "Moderate"}');
    buffer.writeln('- Completed: ${state.workoutCompleted}');
    if (state.workoutCompleted && state.minutesSinceWorkout > 0) {
      buffer.writeln('- Time since completion: ${state.minutesSinceWorkout} minutes');
    }
  }
  buffer.writeln();

  // Nutrition status
  buffer.writeln('### Nutrition Today');
  if (state.dynamicTargets != null) {
    buffer.writeln('- Calorie target: ${state.dynamicTargets!.targetCalories}');
    buffer.writeln('- Protein target: ${state.dynamicTargets!.targetProteinG}g');
    buffer.writeln('- Is training day: ${state.isTrainingDay}');
    buffer.writeln('- Is fasting day (5:2/ADF): ${state.isFastingDay}');
    buffer.writeln('- Is rest day: ${state.isRestDay}');
    if (state.dynamicTargets!.adjustmentNotes.isNotEmpty) {
      buffer.writeln('- Adjustments: ${state.dynamicTargets!.adjustmentNotes.join(", ")}');
    }
  }
  buffer.writeln();

  // Conflicts and warnings
  if (state.hasConflicts) {
    buffer.writeln('### Active Conflicts');
    for (final conflict in state.conflicts) {
      buffer.writeln('- [${conflict.severity.toUpperCase()}] ${conflict.title}');
      buffer.writeln('  ${conflict.description}');
    }
    buffer.writeln();
  }

  if (state.hasWarnings) {
    buffer.writeln('### Warnings');
    for (final warning in state.warnings) {
      buffer.writeln('- $warning');
    }
    buffer.writeln();
  }

  // Current state and recommendation
  buffer.writeln('### Current App State: ${state.currentState.displayName}');
  buffer.writeln('Recommended action: ${state.recommendedAction}');

  return buffer.toString();
});
