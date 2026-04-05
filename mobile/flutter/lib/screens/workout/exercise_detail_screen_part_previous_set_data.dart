part of 'exercise_detail_screen.dart';


/// Model for previous set performance
class PreviousSetData {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final String setType;
  final int? rir;
  final int? rpe;

  PreviousSetData({
    required this.setNumber,
    this.weightKg,
    this.reps,
    required this.setType,
    this.rir,
    this.rpe,
  });
}

