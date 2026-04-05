part of 'staple_choice_sheet.dart';



/// Result type from the staple choice sheet.
/// [goBack] is reserved for future use (currently always false).
typedef StapleChoiceResult = ({
  bool addToday,
  String section,
  String? gymProfileId,
  String? swapExerciseId,
  Map<String, double>? cardioParams,
  int? userSets,
  String? userReps,
  int? userRestSeconds,
  double? userWeightLbs,
  List<int>? targetDays,
  bool goBack,
});

