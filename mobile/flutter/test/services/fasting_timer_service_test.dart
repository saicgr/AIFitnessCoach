import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/models/fasting.dart';

void main() {
  group('FastingZone', () {
    group('forElapsedHours', () {
      test('should return fed state for 0-4 hours fasted', () {
        expect(FastingZone.forElapsedHours(0), FastingZone.fed);
        expect(FastingZone.forElapsedHours(1), FastingZone.fed);
        expect(FastingZone.forElapsedHours(3), FastingZone.fed);
      });

      test('should return postAbsorptive for 4-8 hours fasted', () {
        expect(FastingZone.forElapsedHours(4), FastingZone.postAbsorptive);
        expect(FastingZone.forElapsedHours(6), FastingZone.postAbsorptive);
        expect(FastingZone.forElapsedHours(7), FastingZone.postAbsorptive);
      });

      test('should return earlyFasting for 8-12 hours fasted', () {
        expect(FastingZone.forElapsedHours(8), FastingZone.earlyFasting);
        expect(FastingZone.forElapsedHours(10), FastingZone.earlyFasting);
        expect(FastingZone.forElapsedHours(11), FastingZone.earlyFasting);
      });

      test('should return fatBurning for 12-16 hours fasted', () {
        expect(FastingZone.forElapsedHours(12), FastingZone.fatBurning);
        expect(FastingZone.forElapsedHours(14), FastingZone.fatBurning);
        expect(FastingZone.forElapsedHours(15), FastingZone.fatBurning);
      });

      test('should return ketosis for 16-24 hours fasted', () {
        expect(FastingZone.forElapsedHours(16), FastingZone.ketosis);
        expect(FastingZone.forElapsedHours(18), FastingZone.ketosis);
        expect(FastingZone.forElapsedHours(20), FastingZone.ketosis);
        expect(FastingZone.forElapsedHours(23), FastingZone.ketosis);
      });

      test('should return deepKetosis for 24-48 hours fasted', () {
        expect(FastingZone.forElapsedHours(24), FastingZone.deepKetosis);
        expect(FastingZone.forElapsedHours(30), FastingZone.deepKetosis);
        expect(FastingZone.forElapsedHours(40), FastingZone.deepKetosis);
        expect(FastingZone.forElapsedHours(47), FastingZone.deepKetosis);
      });

      test('should return extended for 48+ hours fasted', () {
        expect(FastingZone.forElapsedHours(48), FastingZone.extended);
        expect(FastingZone.forElapsedHours(72), FastingZone.extended);
      });

      test('should adjust zones for keto-adapted users', () {
        // Keto-adapted users enter zones 2 hours earlier

        // At 6 hours, non-keto is postAbsorptive, keto-adapted is earlyFasting
        expect(FastingZone.forElapsedHours(6, isKetoAdapted: false),
            FastingZone.postAbsorptive);
        expect(FastingZone.forElapsedHours(6, isKetoAdapted: true),
            FastingZone.earlyFasting);

        // At 10 hours, non-keto is earlyFasting, keto-adapted is fatBurning
        expect(FastingZone.forElapsedHours(10, isKetoAdapted: false),
            FastingZone.earlyFasting);
        expect(FastingZone.forElapsedHours(10, isKetoAdapted: true),
            FastingZone.fatBurning);

        // At 14 hours, non-keto is fatBurning, keto-adapted is ketosis
        expect(FastingZone.forElapsedHours(14, isKetoAdapted: false),
            FastingZone.fatBurning);
        expect(FastingZone.forElapsedHours(14, isKetoAdapted: true),
            FastingZone.ketosis);
      });
    });

    group('fromElapsedMinutes', () {
      test('should convert minutes to hours and return correct zone', () {
        // 0-239 minutes = 0-3 hours = fed state
        expect(FastingZone.fromElapsedMinutes(0), FastingZone.fed);
        expect(FastingZone.fromElapsedMinutes(60), FastingZone.fed); // 1 hour
        expect(FastingZone.fromElapsedMinutes(180), FastingZone.fed); // 3 hours
        expect(FastingZone.fromElapsedMinutes(239), FastingZone.fed); // 3:59

        // 240-479 minutes = 4-7 hours = postAbsorptive
        expect(
            FastingZone.fromElapsedMinutes(240), FastingZone.postAbsorptive); // 4 hours
        expect(
            FastingZone.fromElapsedMinutes(360), FastingZone.postAbsorptive); // 6 hours
        expect(
            FastingZone.fromElapsedMinutes(479), FastingZone.postAbsorptive); // 7:59

        // 480-719 minutes = 8-11 hours = earlyFasting
        expect(
            FastingZone.fromElapsedMinutes(480), FastingZone.earlyFasting); // 8 hours
        expect(
            FastingZone.fromElapsedMinutes(600), FastingZone.earlyFasting); // 10 hours
        expect(
            FastingZone.fromElapsedMinutes(719), FastingZone.earlyFasting); // 11:59

        // 720-959 minutes = 12-15 hours = fatBurning
        expect(
            FastingZone.fromElapsedMinutes(720), FastingZone.fatBurning); // 12 hours
        expect(
            FastingZone.fromElapsedMinutes(840), FastingZone.fatBurning); // 14 hours
        expect(
            FastingZone.fromElapsedMinutes(959), FastingZone.fatBurning); // 15:59

        // 960-1439 minutes = 16-23 hours = ketosis
        expect(FastingZone.fromElapsedMinutes(960), FastingZone.ketosis); // 16 hours
        expect(FastingZone.fromElapsedMinutes(1080), FastingZone.ketosis); // 18 hours
        expect(FastingZone.fromElapsedMinutes(1200), FastingZone.ketosis); // 20 hours
        expect(FastingZone.fromElapsedMinutes(1439), FastingZone.ketosis); // 23:59

        // 1440-2879 minutes = 24-47 hours = deepKetosis
        expect(
            FastingZone.fromElapsedMinutes(1440), FastingZone.deepKetosis); // 24 hours
        expect(
            FastingZone.fromElapsedMinutes(1800), FastingZone.deepKetosis); // 30 hours
        expect(
            FastingZone.fromElapsedMinutes(2400), FastingZone.deepKetosis); // 40 hours
        expect(
            FastingZone.fromElapsedMinutes(2879), FastingZone.deepKetosis); // 47:59

        // 2880+ minutes = 48+ hours = extended
        expect(FastingZone.fromElapsedMinutes(2880), FastingZone.extended); // 48 hours
        expect(FastingZone.fromElapsedMinutes(4320), FastingZone.extended); // 72 hours
      });

      test('should pass through keto-adapted flag', () {
        // At 360 minutes (6 hours)
        expect(FastingZone.fromElapsedMinutes(360, isKetoAdapted: false),
            FastingZone.postAbsorptive);
        expect(FastingZone.fromElapsedMinutes(360, isKetoAdapted: true),
            FastingZone.earlyFasting);
      });
    });

    group('properties', () {
      test('should have correct display names', () {
        expect(FastingZone.fed.displayName, 'Fed State');
        expect(FastingZone.postAbsorptive.displayName, 'Processing');
        expect(FastingZone.earlyFasting.displayName, 'Early Fasting');
        expect(FastingZone.fatBurning.displayName, 'Fat Burning');
        expect(FastingZone.ketosis.displayName, 'Ketosis');
        expect(FastingZone.deepKetosis.displayName, 'Deep Ketosis');
        expect(FastingZone.extended.displayName, 'Extended');
      });

      test('should have correct start hours', () {
        expect(FastingZone.fed.startHour, 0);
        expect(FastingZone.postAbsorptive.startHour, 4);
        expect(FastingZone.earlyFasting.startHour, 8);
        expect(FastingZone.fatBurning.startHour, 12);
        expect(FastingZone.ketosis.startHour, 16);
        expect(FastingZone.deepKetosis.startHour, 24);
        expect(FastingZone.extended.startHour, 48);
      });

      test('should have non-empty descriptions', () {
        for (final zone in FastingZone.values) {
          expect(zone.description, isNotEmpty);
          expect(zone.description.length, greaterThan(10));
        }
      });
    });
  });

  group('FastingProtocol', () {
    test('should have correct fasting hours', () {
      expect(FastingProtocol.twelve12.fastingHours, 12);
      expect(FastingProtocol.fourteen10.fastingHours, 14);
      expect(FastingProtocol.sixteen8.fastingHours, 16);
      expect(FastingProtocol.eighteen6.fastingHours, 18);
      expect(FastingProtocol.twenty4.fastingHours, 20);
      expect(FastingProtocol.omad.fastingHours, 23);
      expect(FastingProtocol.fiveTwo.fastingHours, 24);
      expect(FastingProtocol.adf.fastingHours, 24);
    });

    test('should have correct eating hours', () {
      expect(FastingProtocol.twelve12.eatingHours, 12);
      expect(FastingProtocol.fourteen10.eatingHours, 10);
      expect(FastingProtocol.sixteen8.eatingHours, 8);
      expect(FastingProtocol.eighteen6.eatingHours, 6);
      expect(FastingProtocol.twenty4.eatingHours, 4);
      expect(FastingProtocol.omad.eatingHours, 1);
    });

    test('should have correct protocol types', () {
      expect(FastingProtocol.sixteen8.type, FastingProtocolType.tre);
      expect(FastingProtocol.fiveTwo.type, FastingProtocolType.modified);
      expect(FastingProtocol.adf.type, FastingProtocolType.modified);
      expect(FastingProtocol.custom.type, FastingProtocolType.custom);
    });

    test('should have correct difficulty levels', () {
      expect(FastingProtocol.twelve12.difficulty, 'Beginner');
      expect(FastingProtocol.fourteen10.difficulty, 'Beginner');
      expect(FastingProtocol.sixteen8.difficulty, 'Intermediate');
      expect(FastingProtocol.eighteen6.difficulty, 'Intermediate');
      expect(FastingProtocol.twenty4.difficulty, 'Advanced');
      expect(FastingProtocol.omad.difficulty, 'Advanced');
      expect(FastingProtocol.fiveTwo.difficulty, 'Intermediate');
      expect(FastingProtocol.adf.difficulty, 'Advanced');
    });

    test('should parse from string correctly', () {
      expect(FastingProtocol.fromString('16:8'), FastingProtocol.sixteen8);
      expect(FastingProtocol.fromString('18:6'), FastingProtocol.eighteen6);
      expect(FastingProtocol.fromString('5:2'), FastingProtocol.fiveTwo);
      expect(FastingProtocol.fromString('OMAD'), FastingProtocol.omad);
      expect(FastingProtocol.fromString('ADF'), FastingProtocol.adf);
      expect(FastingProtocol.fromString('unknown'), FastingProtocol.sixteen8); // Default
    });
  });

  group('FastingRecord computed properties', () {
    test('should calculate progress correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 8));

      final record = FastingRecord(
        id: 'test-id',
        userId: 'user-id',
        startTime: startTime,
        goalDurationMinutes: 16 * 60, // 16 hour fast
        protocol: '16:8',
        protocolType: 'tre',
        status: 'active',
        completedGoal: false,
        createdAt: startTime,
      );

      // 8 hours elapsed out of 16 = 50%
      expect(record.progress, closeTo(0.5, 0.1));
    });

    test('should calculate elapsed minutes correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 5, minutes: 30));

      final record = FastingRecord(
        id: 'test-id',
        userId: 'user-id',
        startTime: startTime,
        goalDurationMinutes: 16 * 60,
        protocol: '16:8',
        protocolType: 'tre',
        status: 'active',
        completedGoal: false,
        createdAt: startTime,
      );

      // Allow for some time drift during test execution
      expect(record.elapsedMinutes, closeTo(330, 2)); // 5.5 hours = 330 min
    });

    test('should get current zone correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 14));

      final record = FastingRecord(
        id: 'test-id',
        userId: 'user-id',
        startTime: startTime,
        goalDurationMinutes: 16 * 60,
        protocol: '16:8',
        protocolType: 'tre',
        status: 'active',
        completedGoal: false,
        createdAt: startTime,
      );

      expect(record.currentZone, FastingZone.fatBurning);
    });

    test('should calculate remaining minutes correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 10));

      final record = FastingRecord(
        id: 'test-id',
        userId: 'user-id',
        startTime: startTime,
        goalDurationMinutes: 16 * 60, // 960 minutes
        protocol: '16:8',
        protocolType: 'tre',
        status: 'active',
        completedGoal: false,
        createdAt: startTime,
      );

      // 10 hours elapsed, 6 hours remaining = 360 minutes
      expect(record.remainingMinutes, closeTo(360, 2));
    });

    test('should format elapsed time correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 14, minutes: 30));

      final record = FastingRecord(
        id: 'test-id',
        userId: 'user-id',
        startTime: startTime,
        goalDurationMinutes: 16 * 60,
        protocol: '16:8',
        protocolType: 'tre',
        status: 'active',
        completedGoal: false,
        createdAt: startTime,
      );

      expect(record.elapsedTimeString, contains('14'));
      expect(record.elapsedTimeString, contains('30'));
    });
  });
}
