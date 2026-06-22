import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/demo/preview_exercise_catalog.dart';

/// The plan-preview pool must only ever surface curated, media-verified
/// exercises — every picked exercise has a baked illustration asset, so the
/// preview never shows a mismatched icon or an un-verified movement.
void main() {
  const types = [
    'push', 'pull', 'legs', 'upper', 'lower', 'full_body', 'arms',
    'hiit', 'cardio', 'endurance', 'strength', 'core', 'active_recovery',
  ];

  test('every workout type yields only baked, well-formed exercises', () {
    for (final t in types) {
      final picks = curatedExercisesForType(t, seed: 1, goal: 'build_muscle');
      expect(picks, isNotEmpty, reason: 'type $t produced no exercises');
      final ids = <String>{};
      for (final e in picks) {
        expect(e['name'], isA<String>());
        expect((e['name'] as String).isNotEmpty, isTrue);
        expect(e['setsReps'], isA<String>());
        expect(e['muscle'], isA<String>());
        final id = e['id'] as String?;
        // Every pick is a real, baked catalog exercise.
        expect(previewAssetForId(id), isNotNull,
            reason: '$t -> ${e['name']} ($id) is not a baked catalog entry');
        // No duplicate exercise within a single day.
        expect(ids.add(id!), isTrue, reason: 'duplicate $id in $t');
      }
    }
  });

  test('picks are deterministic for a given (type, seed)', () {
    final a = curatedExercisesForType('push', seed: 3);
    final b = curatedExercisesForType('push', seed: 3);
    expect(a.map((e) => e['id']).toList(), b.map((e) => e['id']).toList());
  });

  test('cardio days are shorter than strength days', () {
    expect(curatedExercisesForType('cardio', seed: 0).length, 3);
    expect(curatedExercisesForType('push', seed: 0).length, 5);
  });

  test('push pulls from chest/shoulders/arms muscles, not legs', () {
    final muscles =
        curatedExercisesForType('push', seed: 7).map((e) => e['muscle']);
    expect(muscles.contains('Hamstrings'), isFalse);
    expect(muscles.contains('Quads'), isFalse);
  });
}
