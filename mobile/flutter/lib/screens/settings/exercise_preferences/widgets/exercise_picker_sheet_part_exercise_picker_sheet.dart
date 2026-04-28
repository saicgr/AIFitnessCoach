part of 'exercise_picker_sheet.dart';


class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ExercisePickerType type;
  final Set<String> excludeExercises;
  final bool multiSelect;

  const _ExercisePickerSheet({
    required this.type,
    required this.excludeExercises,
    this.multiSelect = false,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

