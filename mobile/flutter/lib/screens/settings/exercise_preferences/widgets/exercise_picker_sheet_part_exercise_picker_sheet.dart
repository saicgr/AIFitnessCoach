part of 'exercise_picker_sheet.dart';


class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ExercisePickerType type;
  final Set<String> excludeExercises;

  const _ExercisePickerSheet({
    required this.type,
    required this.excludeExercises,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

