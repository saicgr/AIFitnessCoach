import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/workout_detail_helpers.dart';

void main() {
  test('E2E #48 — "Chest (pectoralis major)" and "Chest" collapse to one', () {
    final out = dedupeMuscleNames(const [
      'Chest (pectoralis major)',
      'Chest',
      'chest',
      'Triceps (triceps brachii)',
      'Quadriceps, hamstrings',
      'Quadriceps',
      '   ',
    ]);
    // ignore: avoid_print
    print('deduped: $out');
    expect(out, ['Chest', 'Triceps', 'Quadriceps']);
  });
}
