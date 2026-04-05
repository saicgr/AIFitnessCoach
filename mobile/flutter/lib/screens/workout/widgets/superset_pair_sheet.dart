import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import 'superset_exercise_picker.dart';

part 'superset_pair_sheet_part_superset_pair_sheet.dart';
part 'superset_pair_sheet_part_superset_pair_sheet_state.dart';


/// Superset type definitions
enum SupersetType {
  antagonist,
  compound,
  preExhaust,
  custom,
}

extension SupersetTypeExtension on SupersetType {
  String get label {
    switch (this) {
      case SupersetType.antagonist:
        return 'Antagonist';
      case SupersetType.compound:
        return 'Compound';
      case SupersetType.preExhaust:
        return 'Pre-exhaust';
      case SupersetType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case SupersetType.antagonist:
        return 'Different muscle groups';
      case SupersetType.compound:
        return 'Same muscle group';
      case SupersetType.preExhaust:
        return 'Isolation then compound';
      case SupersetType.custom:
        return 'Any combination';
    }
  }

  IconData get icon {
    switch (this) {
      case SupersetType.antagonist:
        return Icons.swap_horiz;
      case SupersetType.compound:
        return Icons.layers;
      case SupersetType.preExhaust:
        return Icons.trending_up;
      case SupersetType.custom:
        return Icons.tune;
    }
  }

  Color get color {
    switch (this) {
      case SupersetType.antagonist:
        return AppColors.cyan;
      case SupersetType.compound:
        return AppColors.purple;
      case SupersetType.preExhaust:
        return AppColors.orange;
      case SupersetType.custom:
        return AppColors.teal;
    }
  }
}

/// AI-suggested superset pair
class SupersetSuggestion {
  final WorkoutExercise exercise1;
  final WorkoutExercise exercise2;
  final SupersetType type;
  final String reason;

  const SupersetSuggestion({
    required this.exercise1,
    required this.exercise2,
    required this.type,
    required this.reason,
  });
}

/// Result from the superset pair sheet
class SupersetPairResult {
  final WorkoutExercise exercise1;
  final WorkoutExercise exercise2;
  final SupersetType type;
  final int restBetweenExercises;
  final int restAfterSuperset;
  final bool saveToFavorites;

  const SupersetPairResult({
    required this.exercise1,
    required this.exercise2,
    required this.type,
    required this.restBetweenExercises,
    required this.restAfterSuperset,
    required this.saveToFavorites,
  });
}

/// Shows the superset pair creation sheet
Future<SupersetPairResult?> showSupersetPairSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<WorkoutExercise> workoutExercises,
  WorkoutExercise? preselectedExercise,
}) async {
  return await showGlassSheet<SupersetPairResult>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _SupersetPairSheet(
        workoutExercises: workoutExercises,
        preselectedExercise: preselectedExercise,
      ),
    ),
  );
}
