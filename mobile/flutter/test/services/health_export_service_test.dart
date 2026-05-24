import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/repositories/cardio_log_repository.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import 'package:fitwiz/services/health_export_service.dart';

class _MockCardioRepo extends Mock implements CardioLogRepository {}

class _MockWorkoutRepo extends Mock implements WorkoutRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockCardioRepo cardio;
  late _MockWorkoutRepo workout;
  late HealthExportService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardio = _MockCardioRepo();
    workout = _MockWorkoutRepo();
    service = HealthExportService(cardioRepo: cardio, workoutRepo: workout);
  });

  group('toggle persistence (SharedPreferences)', () {
    test('isEnabled defaults to false', () async {
      expect(await service.isEnabled(), isFalse);
    });

    test('setEnabled(true) is observable via isEnabled', () async {
      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);
    });

    test('setEnabled(false) clears the flag', () async {
      await service.setEnabled(true);
      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
    });

    test('isEnabled reads pre-existing prefs value', () async {
      SharedPreferences.setMockInitialValues({
        HealthExportService.kEnabledPrefKey: true,
      });
      expect(await service.isEnabled(), isTrue);
    });
  });

  group('writeWorkout short-circuits when disabled', () {
    test('returns false and never touches health plugin when toggle is OFF',
        () async {
      // Toggle is OFF by default. writeWorkout must bail out before any
      // platform / plugin call. If it didn't short-circuit, calling
      // health.writeWorkoutData in a unit-test environment would throw
      // MissingPluginException and we'd never see `false`.
      final result = await service.writeWorkout(
        workoutType: 'strength',
        start: DateTime(2026, 5, 24, 8, 0),
        end: DateTime(2026, 5, 24, 8, 45),
        caloriesKcal: 300,
        externalId: 'wkt_test_1',
      );
      expect(result, isFalse);
      // No repo lookups should have happened either.
      verifyZeroInteractions(workout);
      verifyZeroInteractions(cardio);
    });

    test('writeCardioLog short-circuits when toggle is OFF', () async {
      final result = await service.writeCardioLog('card_xyz');
      expect(result, isFalse);
      verifyZeroInteractions(cardio);
      verifyZeroInteractions(workout);
    });

    test('writeStrengthWorkout short-circuits when toggle is OFF', () async {
      final result = await service.writeStrengthWorkout('wkt_xyz');
      expect(result, isFalse);
      verifyZeroInteractions(workout);
    });
  });

  group('tag stamping', () {
    test('buildTaggedTitle appends [Zealova:<id>] suffix', () {
      final t = HealthExportService.buildTaggedTitle('Push Day A', 'wkt_abc');
      expect(t, 'Push Day A [Zealova:wkt_abc]');
    });

    test('buildTaggedTitle handles null base title', () {
      final t = HealthExportService.buildTaggedTitle(null, 'card_xyz');
      expect(t, '[Zealova:card_xyz]');
    });

    test('buildTaggedTitle handles empty / whitespace base title', () {
      expect(
        HealthExportService.buildTaggedTitle('   ', 'wkt_1'),
        '[Zealova:wkt_1]',
      );
    });

    test('isZealovaTaggedTitle detects our marker', () {
      expect(
        HealthExportService.isZealovaTaggedTitle('Push Day A [Zealova:wkt_1]'),
        isTrue,
      );
      expect(
        HealthExportService.isZealovaTaggedTitle('[Zealova:card_1]'),
        isTrue,
      );
    });

    test('isZealovaTaggedTitle returns false for unrelated titles', () {
      expect(HealthExportService.isZealovaTaggedTitle('Push Day A'), isFalse);
      expect(HealthExportService.isZealovaTaggedTitle(''), isFalse);
      expect(HealthExportService.isZealovaTaggedTitle(null), isFalse);
      // Importantly, the marker is specific — a stray "Zealova" mention
      // (e.g. user-entered title) must NOT be treated as ours.
      expect(
        HealthExportService.isZealovaTaggedTitle('Zealova test'),
        isFalse,
      );
    });

    test('roundtrip: external_id can be recovered from the tagged title', () {
      const externalId = 'wkt_2026_05_24_alpha';
      final tagged =
          HealthExportService.buildTaggedTitle('Leg Day', externalId);
      expect(HealthExportService.isZealovaTaggedTitle(tagged), isTrue);
      // The importer can extract the id between the marker and the closing ']'.
      final start = tagged.indexOf(HealthExportService.kZealovaSourceTag) +
          HealthExportService.kZealovaSourceTag.length;
      final end = tagged.indexOf(']', start);
      expect(tagged.substring(start, end), externalId);
    });
  });

  group('last-sync timestamp', () {
    test('getLastSyncAt is null until first successful write', () async {
      expect(await service.getLastSyncAt(), isNull);
    });

    test('stamping a value persists across reads', () async {
      // We can't call the private _stampLastSync directly, but we can simulate
      // the on-disk state the way the production path would leave it.
      SharedPreferences.setMockInitialValues({
        HealthExportService.kLastSyncPrefKey:
            DateTime(2026, 5, 24, 9, 30).millisecondsSinceEpoch,
      });
      final last = await service.getLastSyncAt();
      expect(last, isNotNull);
      expect(last!.year, 2026);
      expect(last.month, 5);
      expect(last.day, 24);
    });
  });
}
