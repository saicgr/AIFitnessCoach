part of 'superset_pair_sheet.dart';


class _SupersetPairSheet extends ConsumerStatefulWidget {
  final List<WorkoutExercise> workoutExercises;
  final WorkoutExercise? preselectedExercise;

  const _SupersetPairSheet({
    required this.workoutExercises,
    this.preselectedExercise,
  });

  @override
  ConsumerState<_SupersetPairSheet> createState() => _SupersetPairSheetState();
}

