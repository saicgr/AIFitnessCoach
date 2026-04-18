import '../data/models/mood.dart';
import '../data/models/workout_style.dart';

/// Static preset describing the recommended defaults for a mood-generated
/// workout. The user sees these selections pre-applied in the mood sheet's
/// Advanced Options — they can override any field.
///
/// Defaults are informed by the exercise-psychology literature (catharsis
/// refutation for anger via Bushman 2002; anxiety aerobic sweet spot via
/// Petruzzello 1991; resistance training for mild depression via Gordon
/// 2018; yoga for cortisol via Pascoe 2017; acute exercise boosts focus via
/// Chang 2012). Where the user explicitly prefers otherwise (e.g. Angry →
/// Hell), their preference wins — research only sets defaults.
class MoodPreset {
  /// Style pre-selected when the mood is tapped.
  final WorkoutStyle recommendedStyle;

  /// Difficulty pre-selected when the mood is tapped. One of
  /// 'easy' | 'medium' | 'hard' | 'hell' (matches
  /// `QuickWorkoutConstants.difficultyMultipliers`).
  final String recommendedDifficulty;

  /// Duration in minutes pre-selected when the mood is tapped.
  final int recommendedDuration;

  /// Alternative styles exposed to the user as chips (besides the
  /// recommended one). The Mixed chip is always available additionally.
  final List<WorkoutStyle> alternatives;

  /// Mood key passed to [QuickWorkoutEngine.generate]. `null` means "let the
  /// engine run without any mood multiplier" — used for Good / default.
  final String? engineMoodKey;

  /// Goal passed to the engine. Usually derived from the style but moods
  /// can bias it (e.g. Motivated prefers strength over hypertrophy).
  final String goal;

  /// Whether to use supersets. High-volume moods (Great, Motivated) enable
  /// them; recovery-oriented moods don't.
  final bool useSupersets;

  /// Minimum candidate pool size after style+mood filtering; if fewer
  /// exercises match, the algorithm fails open to the broader style filter.
  final int minPoolSize;

  /// Evidence grade for the recommended defaults (A|B|C) — surfaced in
  /// telemetry so we can correlate adoption with research strength.
  final String evidenceGrade;

  /// Caption suffix shown under the mood sheet title, e.g. "rhythmic flow".
  final String captionSuffix;

  const MoodPreset({
    required this.recommendedStyle,
    required this.recommendedDifficulty,
    required this.recommendedDuration,
    required this.alternatives,
    required this.engineMoodKey,
    required this.goal,
    required this.useSupersets,
    required this.minPoolSize,
    required this.evidenceGrade,
    required this.captionSuffix,
  });

  static const Map<Mood, MoodPreset> _table = {
    Mood.great: MoodPreset(
      recommendedStyle: WorkoutStyle.cardio,
      recommendedDifficulty: 'hard',
      recommendedDuration: 30,
      alternatives: [WorkoutStyle.weights, WorkoutStyle.bodyweight],
      engineMoodKey: 'energized',
      goal: 'hypertrophy',
      useSupersets: true,
      minPoolSize: 8,
      evidenceGrade: 'B',
      captionSuffix: 'push it',
    ),
    Mood.good: MoodPreset(
      recommendedStyle: WorkoutStyle.weights,
      recommendedDifficulty: 'medium',
      recommendedDuration: 45,
      alternatives: [WorkoutStyle.bodyweight, WorkoutStyle.cardio],
      engineMoodKey: null, // default engine behavior
      goal: 'hypertrophy',
      useSupersets: true,
      minPoolSize: 8,
      evidenceGrade: 'A',
      captionSuffix: 'balanced session',
    ),
    Mood.motivated: MoodPreset(
      recommendedStyle: WorkoutStyle.weights,
      recommendedDifficulty: 'hard',
      recommendedDuration: 50,
      alternatives: [WorkoutStyle.cardio, WorkoutStyle.bodyweight],
      engineMoodKey: 'motivated',
      goal: 'strength',
      useSupersets: false,
      minPoolSize: 8,
      evidenceGrade: 'B',
      captionSuffix: 'heavy lifts',
    ),
    Mood.angry: MoodPreset(
      recommendedStyle: WorkoutStyle.cardio,
      recommendedDifficulty: 'hell',
      recommendedDuration: 20,
      alternatives: [WorkoutStyle.weights, WorkoutStyle.bodyweight],
      engineMoodKey: 'angry',
      goal: 'endurance',
      useSupersets: false,
      minPoolSize: 6,
      evidenceGrade: 'B',
      captionSuffix: 'blow it out',
    ),
    Mood.calm: MoodPreset(
      recommendedStyle: WorkoutStyle.yogaStretch,
      recommendedDifficulty: 'easy',
      recommendedDuration: 25,
      alternatives: [WorkoutStyle.bodyweight, WorkoutStyle.cardio],
      engineMoodKey: 'chill',
      goal: 'mobility',
      useSupersets: false,
      minPoolSize: 5,
      evidenceGrade: 'B',
      captionSuffix: 'flow and breathe',
    ),
    Mood.stressed: MoodPreset(
      recommendedStyle: WorkoutStyle.yogaStretch,
      recommendedDifficulty: 'easy',
      recommendedDuration: 20,
      alternatives: [WorkoutStyle.cardio, WorkoutStyle.bodyweight],
      engineMoodKey: 'stressed',
      goal: 'mobility',
      useSupersets: false,
      minPoolSize: 5,
      evidenceGrade: 'A',
      captionSuffix: 'slow the system',
    ),
    Mood.anxious: MoodPreset(
      recommendedStyle: WorkoutStyle.cardio,
      recommendedDifficulty: 'easy',
      recommendedDuration: 25,
      alternatives: [WorkoutStyle.yogaStretch, WorkoutStyle.bodyweight],
      engineMoodKey: 'anxious',
      goal: 'endurance',
      useSupersets: false,
      minPoolSize: 6,
      evidenceGrade: 'A',
      captionSuffix: 'steady rhythm',
    ),
    Mood.tired: MoodPreset(
      recommendedStyle: WorkoutStyle.yogaStretch,
      recommendedDifficulty: 'easy',
      recommendedDuration: 15,
      alternatives: [WorkoutStyle.bodyweight, WorkoutStyle.cardio],
      engineMoodKey: 'tired',
      goal: 'mobility',
      useSupersets: false,
      minPoolSize: 5,
      evidenceGrade: 'B',
      captionSuffix: 'gentle recovery',
    ),
    Mood.low: MoodPreset(
      recommendedStyle: WorkoutStyle.weights,
      recommendedDifficulty: 'medium',
      recommendedDuration: 35,
      alternatives: [WorkoutStyle.cardio, WorkoutStyle.yogaStretch],
      engineMoodKey: 'low_energy',
      goal: 'hypertrophy',
      useSupersets: false,
      minPoolSize: 8,
      evidenceGrade: 'A',
      captionSuffix: 'small wins',
    ),
    Mood.focused: MoodPreset(
      recommendedStyle: WorkoutStyle.weights,
      recommendedDifficulty: 'hard',
      recommendedDuration: 50,
      alternatives: [WorkoutStyle.cardio, WorkoutStyle.bodyweight],
      engineMoodKey: 'focused',
      goal: 'strength',
      useSupersets: false,
      minPoolSize: 8,
      evidenceGrade: 'B',
      captionSuffix: 'dial in',
    ),
  };

  /// Lookup the preset for a mood. Guaranteed non-null — every [Mood] has an
  /// entry.
  static MoodPreset forMood(Mood mood) => _table[mood]!;

  /// All styles the user sees as chips (recommended + alternatives + Mixed).
  List<WorkoutStyle> get allStyleChoices => [
        recommendedStyle,
        ...alternatives.where((s) => s != recommendedStyle),
        if (!alternatives.contains(WorkoutStyle.mixed) &&
            recommendedStyle != WorkoutStyle.mixed)
          WorkoutStyle.mixed,
      ];
}
