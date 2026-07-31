import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// The Easy tier must have exactly ONE workout surface.
///
/// It shipped with two: `easy_active_workout_view.dart` (working sets) and a
/// bespoke `easy_warmup_runner.dart` that re-composed `EasyExerciseHeader` +
/// `EasyFocalColumn` into its own Scaffold with a different top bar, no stats
/// strip, no set ledger and no Ask-coach footer. The user hit the warm-up and
/// asked why it "isn't the active workout easy ui" — because it wasn't the
/// same screen. Warm-up now renders through `EasyActiveWorkoutView` like any
/// other exercise (see `_buildWarmupView` in easy_active_workout_state.dart).
///
/// This guard fails the moment a second file starts composing the Easy focal
/// pair itself, which is how the divergence gets reintroduced. If you need a
/// new Easy phase (cooldown, stretches, a finisher), wire it through
/// `EasyActiveWorkoutView` — don't build a parallel screen.
void main() {
  test('only easy_active_workout_view composes the Easy focal surface', () {
    final dir = Directory('lib/screens/workout/easy');
    expect(dir.existsSync(), isTrue, reason: 'Easy tier directory moved?');

    const owner = 'lib/screens/workout/easy/easy_active_workout_view.dart';
    final offenders = <String>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('easy_active_workout_view.dart')) continue;
      // The widgets' own definition files obviously name their own class.
      if (path.endsWith('/easy_exercise_header.dart')) continue;
      if (path.endsWith('/easy_focal_column.dart')) continue;

      final src = entity.readAsStringSync();
      final buildsHeader = src.contains('EasyExerciseHeader(');
      final buildsFocal = src.contains('EasyFocalColumn(');
      if (buildsHeader && buildsFocal) offenders.add(path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files re-compose the Easy focal surface instead of reusing '
          '$owner, which is how a second, differently-shaped Easy screen gets '
          'reintroduced:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the deleted bespoke warm-up runner has not come back', () {
    final ghost =
        File('lib/screens/workout/easy/widgets/easy_warmup_runner.dart');
    expect(
      ghost.existsSync(),
      isFalse,
      reason: 'Warm-up must render through EasyActiveWorkoutView, not a '
          'separate runner screen.',
    );
  });
}
