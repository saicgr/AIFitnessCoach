import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/models/mood.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/models/workout_style.dart';
import 'package:fitwiz/services/mood_workout_adaptation.dart';
import 'package:fitwiz/services/mood_workout_presets.dart';
import 'package:fitwiz/services/mood_workout_wrapper.dart';

void main() {
  group('Mood enum', () {
    test('has exactly 10 moods', () {
      expect(Mood.values.length, 10);
    });

    test('every mood has a non-empty label and emoji', () {
      for (final m in Mood.values) {
        expect(m.label, isNotEmpty, reason: '${m.name} missing label');
        expect(m.emoji, isNotEmpty, reason: '${m.name} missing emoji');
        expect(m.description, isNotEmpty);
      }
    });

    test('fromString maps canonical values', () {
      expect(Mood.fromString('angry'), Mood.angry);
      expect(Mood.fromString('great'), Mood.great);
      expect(Mood.fromString('calm'), Mood.calm);
      expect(Mood.fromString('focused'), Mood.focused);
    });

    test('fromString honors legacy aliases', () {
      expect(Mood.fromString('chill'), Mood.calm);
      expect(Mood.fromString('energized'), Mood.great);
      expect(Mood.fromString('low_energy'), Mood.low);
      expect(Mood.fromString('sad'), Mood.low);
    });

    test('fromString falls back to good for unknown', () {
      expect(Mood.fromString('gibberish'), Mood.good);
      expect(Mood.fromString(''), Mood.good);
    });

    test('Stressed uses the sweat emoji (not steam)', () {
      // Steam (0x1F624) used to belong to stressed. We reassigned it to
      // angry and moved stressed to the sweat-face (0x1F630) so the picker
      // reads correctly.
      expect(Mood.angry.emoji, '\u{1F624}');
      expect(Mood.stressed.emoji, '\u{1F630}');
    });
  });

  group('WorkoutStyle', () {
    test('has exactly 5 styles', () {
      expect(WorkoutStyle.values.length, 5);
    });

    test('toFocus returns cardio/stretch for specialized styles', () {
      expect(WorkoutStyle.cardio.toFocus(), 'cardio');
      expect(WorkoutStyle.yogaStretch.toFocus(), 'stretch');
    });

    test('toFocus falls back for weights/bodyweight/mixed', () {
      expect(WorkoutStyle.weights.toFocus(), 'full_body');
      expect(WorkoutStyle.weights.toFocus(fallbackFocus: 'push'), 'push');
      expect(WorkoutStyle.bodyweight.toFocus(), 'full_body');
      expect(WorkoutStyle.mixed.toFocus(), 'full_body');
    });

    test('toGoal yields sensible defaults per style', () {
      expect(WorkoutStyle.cardio.toGoal(), 'endurance');
      expect(WorkoutStyle.yogaStretch.toGoal(), 'mobility');
      expect(WorkoutStyle.weights.toGoal(), 'hypertrophy');
      expect(WorkoutStyle.bodyweight.toGoal(), 'endurance');
    });

    test('fromValue is forgiving', () {
      expect(WorkoutStyle.fromValue('weights'), WorkoutStyle.weights);
      expect(WorkoutStyle.fromValue('WEIGHTS'), WorkoutStyle.weights);
      expect(WorkoutStyle.fromValue('yoga_stretch'), WorkoutStyle.yogaStretch);
      expect(WorkoutStyle.fromValue('nope'), WorkoutStyle.mixed);
    });
  });

  group('MoodPreset', () {
    test('every mood resolves to a preset with sensible fields', () {
      for (final m in Mood.values) {
        final p = MoodPreset.forMood(m);
        expect(p.recommendedDuration, inInclusiveRange(10, 60));
        expect(
          ['easy', 'medium', 'hard', 'hell'],
          contains(p.recommendedDifficulty),
        );
        expect(p.alternatives, isNotEmpty);
        expect(p.goal, isNotEmpty);
        expect(['A', 'B', 'C'], contains(p.evidenceGrade));
      }
    });

    test('Angry defaults to Cardio + Hell (user preference)', () {
      final p = MoodPreset.forMood(Mood.angry);
      expect(p.recommendedStyle, WorkoutStyle.cardio);
      expect(p.recommendedDifficulty, 'hell');
      expect(p.recommendedDuration, 20);
    });

    test('Tired defaults to easy yoga/stretch', () {
      final p = MoodPreset.forMood(Mood.tired);
      expect(p.recommendedStyle, WorkoutStyle.yogaStretch);
      expect(p.recommendedDifficulty, 'easy');
    });

    test('Low (sad) defaults to Weights + Medium (Gordon 2018)', () {
      final p = MoodPreset.forMood(Mood.low);
      expect(p.recommendedStyle, WorkoutStyle.weights);
      expect(p.recommendedDifficulty, 'medium');
    });

    test('Good mood does NOT set a mood multiplier key', () {
      final p = MoodPreset.forMood(Mood.good);
      expect(p.engineMoodKey, isNull);
    });

    test('allStyleChoices always includes Mixed', () {
      for (final m in Mood.values) {
        final choices = MoodPreset.forMood(m).allStyleChoices;
        expect(choices, contains(WorkoutStyle.mixed),
            reason: '${m.name} missing Mixed fallback');
        // Dedupe check: no duplicates.
        expect(choices.length, choices.toSet().length,
            reason: '${m.name} has duplicate style choices');
      }
    });
  });

  group('MoodWorkoutWrapper', () {
    Workout baseWorkout() => const Workout(
          id: 'w1',
          userId: 'u1',
          name: 'Placeholder',
          type: 'full_body',
          difficulty: 'medium',
          scheduledDate: '2026-04-17',
          exercisesJson: [],
          durationMinutes: 30,
        );

    test('attaches mood metadata and renames workout', () {
      final decorated = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.angry,
        style: WorkoutStyle.cardio,
        difficulty: 'hell',
      );
      expect(decorated.name, isNot('Placeholder'));
      final meta = decorated.generationMetadata!;
      expect(meta['mood_name'], decorated.name);
      expect(meta['mood_quote'], isA<String>());
      expect(meta['mood_music_vibe'], isA<String>());
      expect(meta['mood_include_cooldown'], true);
      expect(meta['mood_breath_prompt'], isA<Map>());
    });

    test('Anxious gets a breath prompt config', () {
      final decorated = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.anxious,
        style: WorkoutStyle.cardio,
        difficulty: 'easy',
      );
      final meta = decorated.generationMetadata!;
      final breath = meta['mood_breath_prompt'] as Map?;
      expect(breath, isNotNull);
      expect(breath!['pattern'], 'box_4_4_4_4');
    });

    test('Stressed gets 4-7-8 breath prompt', () {
      final decorated = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.stressed,
        style: WorkoutStyle.yogaStretch,
        difficulty: 'easy',
      );
      final meta = decorated.generationMetadata!;
      final breath = meta['mood_breath_prompt'] as Map?;
      expect(breath!['pattern'], 'four_seven_eight');
    });

    test('Calm / Stressed / Low include gratitude closer', () {
      for (final m in [Mood.calm, Mood.stressed, Mood.low]) {
        final decorated = MoodWorkoutWrapper.decorate(
          baseWorkout(),
          mood: m,
          style: WorkoutStyle.yogaStretch,
          difficulty: 'easy',
        );
        expect(
          decorated.generationMetadata!['mood_include_gratitude'],
          true,
          reason: '${m.name} should include gratitude closer',
        );
      }
    });

    test('Great + easy does NOT force cooldown', () {
      final decorated = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.great,
        style: WorkoutStyle.cardio,
        difficulty: 'easy',
      );
      expect(decorated.generationMetadata!['mood_include_cooldown'], false);
    });

    test('Music vibe is mood-appropriate', () {
      final angry = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.angry,
        style: WorkoutStyle.cardio,
        difficulty: 'hell',
      );
      expect(
        (angry.generationMetadata!['mood_music_vibe'] as String).toLowerCase(),
        contains('hard'),
      );

      final calm = MoodWorkoutWrapper.decorate(
        baseWorkout(),
        mood: Mood.calm,
        style: WorkoutStyle.yogaStretch,
        difficulty: 'easy',
      );
      expect(
        (calm.generationMetadata!['mood_music_vibe'] as String).toLowerCase(),
        anyOf(contains('ambient'), contains('lo-fi')),
      );
    });
  });

  group('MoodWorkoutAdaptation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null before 3 completions', () async {
      // One generation, one completion — below threshold.
      await MoodWorkoutAdaptation.recordGeneration(Mood.angry, WorkoutStyle.weights);
      await MoodWorkoutAdaptation.recordCompletion(Mood.angry, WorkoutStyle.weights);
      expect(await MoodWorkoutAdaptation.personalizedStyleFor(Mood.angry), isNull);
    });

    test('flips to Weights once user completes 3+ Angry+Weights', () async {
      for (var i = 0; i < 4; i++) {
        await MoodWorkoutAdaptation.recordGeneration(Mood.angry, WorkoutStyle.weights);
        await MoodWorkoutAdaptation.recordCompletion(Mood.angry, WorkoutStyle.weights);
      }
      expect(
        await MoodWorkoutAdaptation.personalizedStyleFor(Mood.angry),
        WorkoutStyle.weights,
      );
    });

    test('ignores style with <60% completion rate', () async {
      // 5 generations, only 2 completions = 40%.
      for (var i = 0; i < 5; i++) {
        await MoodWorkoutAdaptation.recordGeneration(Mood.low, WorkoutStyle.cardio);
      }
      await MoodWorkoutAdaptation.recordCompletion(Mood.low, WorkoutStyle.cardio);
      await MoodWorkoutAdaptation.recordCompletion(Mood.low, WorkoutStyle.cardio);
      expect(await MoodWorkoutAdaptation.personalizedStyleFor(Mood.low), isNull);
    });

    test('picks the best style when multiple qualify', () async {
      // Weights: 5 gen, 4 complete (80%).
      for (var i = 0; i < 5; i++) {
        await MoodWorkoutAdaptation.recordGeneration(Mood.motivated, WorkoutStyle.weights);
      }
      for (var i = 0; i < 4; i++) {
        await MoodWorkoutAdaptation.recordCompletion(Mood.motivated, WorkoutStyle.weights);
      }
      // Cardio: 4 gen, 3 complete (75%).
      for (var i = 0; i < 4; i++) {
        await MoodWorkoutAdaptation.recordGeneration(Mood.motivated, WorkoutStyle.cardio);
      }
      for (var i = 0; i < 3; i++) {
        await MoodWorkoutAdaptation.recordCompletion(Mood.motivated, WorkoutStyle.cardio);
      }
      expect(
        await MoodWorkoutAdaptation.personalizedStyleFor(Mood.motivated),
        WorkoutStyle.weights,
      );
    });

    test('clear() wipes adaptation data', () async {
      await MoodWorkoutAdaptation.recordGeneration(Mood.angry, WorkoutStyle.weights);
      await MoodWorkoutAdaptation.clear();
      final matrix = await MoodWorkoutAdaptation.completionMatrix();
      expect(matrix.isEmpty, true);
    });
  });
}
