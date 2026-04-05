part of 'quick_workout_engine.dart';


/// Internal helper to track selected exercises with their slot and time cost.
class _SelectedExercise {
  final OfflineExercise exercise;
  final QuickMuscleSlot slot;
  final int timeCost;
  final int? supersetGroup;
  final int? supersetOrder;

  const _SelectedExercise({
    required this.exercise,
    required this.slot,
    required this.timeCost,
    this.supersetGroup,
    this.supersetOrder,
  });

  _SelectedExercise copyWith({int? supersetGroup, int? supersetOrder}) {
    return _SelectedExercise(
      exercise: exercise,
      slot: slot,
      timeCost: timeCost,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      supersetOrder: supersetOrder ?? this.supersetOrder,
    );
  }
}

