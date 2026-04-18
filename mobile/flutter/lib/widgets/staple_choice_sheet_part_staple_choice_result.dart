part of 'staple_choice_sheet.dart';



/// Result type from the staple choice sheet.
/// [goBack] is reserved for future use (currently always false).
///
/// [cardioParams] carries numeric fields that apply to many exercise types:
///   - duration_seconds, speed_mph, incline_percent, distance_miles
///   - rpm, resistance_level, stroke_rate_spm
///   - rpe (perceived effort 1-10)
///
/// Advanced string fields (tempo, notes, band color, ROM) are separate
/// because cardioParams is typed as Map<String, double>.
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
  String? userTempo,
  String? userNotes,
  String? userBandColor,
  String? userRangeOfMotion,
  bool goBack,
});

