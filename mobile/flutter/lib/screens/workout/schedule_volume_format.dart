import '../../data/models/program_template.dart';

// ===========================================================================
// Schedule-tab volume/subtitle formatting for [ProgramScheduleExercise] rows.
//
// `ProgramScheduleExercise.volumeLabel` / `.intervalLabel`
// (lib/data/models/program_template.dart) render "sets × reps" verbatim from
// the authored data, which breaks for two shapes the exercise library uses:
//  - interval exercises, where `reps` is always a meaningless "1" rounds-loop
//    placeholder, and rest durations round to a fractional-minute label
//    ("0.5 min" instead of "30 sec");
//  - single hold/timed exercises (e.g. a held stretch, a walk), where `reps`
//    is again a "1" placeholder and the real duration lives in
//    `durationSeconds`, never rendered at all.
//
// The model file is shared/off-limits for this pass, and
// program_detail_screen.dart is this app's sole reader of those getters, so
// the corrected formatting lives here instead — resolved from the exercise's
// raw public fields (sets/reps/durationSeconds/restSeconds), never from the
// getters above.
// ===========================================================================

/// Formats a whole number of seconds as a compact human duration —
/// "45 sec", "3 min", "1 min 30 sec" — never a fractional-minute label like
/// "0.5 min".
String formatScheduleSeconds(int seconds) {
  if (seconds <= 0) return '';
  if (seconds < 60) return '$seconds sec';
  final whole = seconds ~/ 60;
  final rem = seconds % 60;
  return rem == 0 ? '$whole min' : '$whole min $rem sec';
}

/// Volume ("sets × reps"-style trailing stat) + subtitle for one schedule
/// exercise row.
///
///  - A genuine multi-round interval (sets > 1 with a real work duration)
///    gets a plain-English "N rounds: work hard, rest easy" subtitle in
///    whole seconds/minutes, and its authored `reps` (always "1" for this
///    shape) is dropped from the trailing volume instead of rendering a
///    nonsense "N × 1".
///  - A single hold/timed exercise (reps == 1 with a real work duration, no
///    rounds) shows that duration ("3 min") instead of a meaningless
///    "1 × 1" / "2 × 1".
///  - Anything else falls back to the model's own `volumeLabel` /
///    `intervalLabel` — unauthored/unusual shapes render exactly as before.
({String volume, String? subtitle}) resolveScheduleVolume(
  ProgramScheduleExercise ex,
) {
  final setsN = int.tryParse(ex.sets?.trim() ?? '');
  final repsN = int.tryParse(ex.reps?.trim() ?? '');
  final dur = ex.durationSeconds;

  // Genuine interval structure: >1 rounds with a real per-round duration.
  if (setsN != null && setsN > 1 && dur != null && dur > 0) {
    final work = formatScheduleSeconds(dur);
    final rest = ex.restSeconds;
    final subtitle = (rest != null && rest > 0)
        ? '$setsN rounds: $work hard, ${formatScheduleSeconds(rest)} easy'
        : '$setsN rounds: $work';
    return (volume: '', subtitle: subtitle);
  }

  // Single hold/timed exercise: authored reps is a "1" placeholder but a
  // real work duration exists — show the duration, not "N × 1".
  if (repsN != null && repsN <= 1 && dur != null && dur > 0) {
    final work = formatScheduleSeconds(dur);
    final volume = (setsN != null && setsN > 1) ? '$setsN × $work' : work;
    return (volume: volume, subtitle: ex.intensityGuidance);
  }

  return (
    volume: ex.volumeLabel,
    subtitle: ex.intervalLabel ?? ex.intensityGuidance,
  );
}

/// Label for a rest-day card: appends " · Rest" only when the authored day
/// name doesn't already say so — some programs author rest days as e.g.
/// "Day 4 — Rest", and unconditionally appending produced "Day 4 — Rest ·
/// Rest".
String restDayLabel(String dayName) {
  final trimmed = dayName.trim();
  if (trimmed.toLowerCase().contains('rest')) return trimmed;
  return '$trimmed · Rest';
}
