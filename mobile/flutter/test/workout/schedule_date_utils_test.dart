// Regression guard for E2E #31 / #21 — the CLIENT half of the
// "local-day window on a timestamptz" class documented in CLAUDE.md.
//
// `workouts.scheduled_date` is a timestamptz stored at NOON of the intended
// day. Reading it with `DateTime.parse` yields a UTC instant; formatting or
// date-picker-seeding off that instant without `.toLocal()` renders the wrong
// day (and, when compared against a LOCAL `firstDate`, made the reschedule
// picker silently open on today instead of the workout's own day).
//
// Part 1 — behaviour of the shared resolver.
// Part 2 — a source guard: no workout-scheduling surface may go back to
//          parsing `scheduledDate` into a picker/label without the resolver.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/schedule_date_utils.dart';

void main() {
  group('scheduledLocalDay', () {
    test('bare DATE is read as a LOCAL calendar day, never UTC midnight', () {
      // DateTime.parse('2026-07-29') would give UTC midnight, which .toLocal()
      // rolls back to Jul 28 for every negative-offset user.
      final day = scheduledLocalDay('2026-07-29');
      expect(day, isNotNull);
      expect(day!.isUtc, isFalse);
      expect([day.year, day.month, day.day], [2026, 7, 29]);
    });

    test('noon-anchored timestamptz resolves to its local day', () {
      // Noon in ANY real timezone stays inside its own local day, which is
      // exactly why the noon anchor was chosen.
      final utcNoon = DateTime.utc(2026, 7, 29, 12);
      final local = utcNoon.toLocal();
      final day = scheduledLocalDay(utcNoon.toIso8601String());
      expect(day, DateTime(local.year, local.month, local.day));
    });

    test('Postgres space-separated text form parses', () {
      final day = scheduledLocalDay('2026-07-29 17:00:00+00');
      final expected = DateTime.utc(2026, 7, 29, 17).toLocal();
      expect(day, DateTime(expected.year, expected.month, expected.day));
    });

    test('never fabricates a day for missing or junk input', () {
      expect(scheduledLocalDay(null), isNull);
      expect(scheduledLocalDay(''), isNull);
      expect(scheduledLocalDay('   '), isNull);
      expect(scheduledLocalDay('not-a-date'), isNull);
    });

    test('result is always local midnight', () {
      final day = scheduledLocalDay('2026-07-29T17:00:00+00:00')!;
      expect([day.hour, day.minute, day.second, day.millisecond],
          [0, 0, 0, 0]);
      expect(day.isUtc, isFalse);
    });
  });

  group('scheduledDayLabel', () {
    final now = DateTime(2026, 7, 28, 9, 30);
    DateTime d(int day) => DateTime(2026, 7, day);

    test('relative days', () {
      expect(scheduledDayLabel(d(28), now: now), 'TODAY');
      expect(scheduledDayLabel(d(29), now: now), 'TOMORROW');
      expect(scheduledDayLabel(d(27), now: now), 'YESTERDAY');
    });

    test('absolute days name the weekday, matching the carousel card', () {
      // 2026-07-31 is a Friday.
      expect(scheduledDayLabel(d(31), now: now), 'FRI, JUL 31');
    });

    test('a different year is disambiguated', () {
      expect(scheduledDayLabel(DateTime(2027, 1, 4), now: now),
          'MON, JAN 4 2027');
    });

    test('null in, null out — no fabricated date', () {
      expect(scheduledDayLabel(null, now: now), isNull);
    });
  });

  group('reschedulePickerSeed', () {
    final firstDate = DateTime(2026, 7, 28);

    test('seeds on the workout own day, not today', () {
      // This is the #31 regression: the picker used to open on today.
      final seed = reschedulePickerSeed('2026-07-31T17:00:00+00:00', firstDate);
      expect(seed, DateTime(2026, 7, 31));
    });

    test('a past-dated (missed) workout clamps to firstDate', () {
      // showDatePicker asserts initialDate is not before firstDate. A legacy
      // midnight-UTC row (2026-07-28T00:00:00Z) is the previous local evening
      // for every negative-offset user — it must clamp, not throw.
      final seed = reschedulePickerSeed('2026-07-20', firstDate);
      expect(seed, firstDate);
      final legacy = reschedulePickerSeed('2026-07-28T00:00:00Z', firstDate);
      expect(legacy.isBefore(firstDate), isFalse);
    });

    test('no usable date falls back to firstDate', () {
      expect(reschedulePickerSeed(null, firstDate), firstDate);
      expect(reschedulePickerSeed('garbage', firstDate), firstDate);
    });
  });

  group('CarouselDateFocus (E2E #21 — strip vs card disagreed on the day)', () {
    // Tue Jul 28 is a rest day; the carousel auto-jumps to the Wed Jul 29 card.
    final wed = DateTime(2026, 7, 29);
    final fri = DateTime(2026, 7, 31);
    final sun = DateTime(2026, 8, 2);

    test('page-before-items (the real first-paint order) still resolves', () {
      // This is the regression. The carousel's initial jump fires
      // onPageChanged(0) in a post-frame callback registered BEFORE the one
      // that publishes its items, so at that instant the consumer holds an
      // empty list. The old code bailed out here and the strip stayed on
      // today ("Tuesday 28") while the card read "Wednesday".
      final focus = CarouselDateFocus();
      focus.onPageChanged(0);
      expect(focus.resolvedDay, isNull, reason: 'not resolvable yet');
      focus.onDaysChanged([wed, fri, sun]);
      expect(focus.resolvedDay, wed);
    });

    test('items-before-page also resolves', () {
      final focus = CarouselDateFocus();
      focus.onDaysChanged([wed, fri, sun]);
      expect(focus.resolvedDay, isNull);
      focus.onPageChanged(1);
      expect(focus.resolvedDay, fri);
    });

    test('onDaysChanged reports the change that unlocks the resolution', () {
      final focus = CarouselDateFocus();
      expect(focus.onPageChanged(2), isFalse, reason: 'nothing resolvable yet');
      expect(focus.onDaysChanged([wed, fri, sun]), isTrue);
      expect(focus.resolvedDay, sun);
    });

    test('an out-of-range index resolves to null, never to a wrong day', () {
      final focus = CarouselDateFocus();
      focus.onDaysChanged([wed]);
      focus.onPageChanged(4);
      expect(focus.resolvedDay, isNull);
    });

    test('a dateless card resolves to null rather than fabricating a day', () {
      final focus = CarouselDateFocus();
      focus.onDaysChanged([null, fri]);
      focus.onPageChanged(0);
      expect(focus.resolvedDay, isNull);
    });

    test('sameDays sees a mid-list change that length+first miss', () {
      // A Wednesday placeholder becoming a real workout keeps the length AND
      // the first date identical — the old guard skipped the update and every
      // later index lookup ran against a stale list.
      final focus = CarouselDateFocus();
      focus.onDaysChanged([wed, fri, sun]);
      expect(focus.sameDays([wed, fri, sun]), isTrue);
      expect(focus.sameDays([wed, DateTime(2026, 7, 30), sun]), isFalse);
      expect(focus.sameDays([wed, fri]), isFalse);
    });

    test('resolved day is normalized to local midnight', () {
      final focus = CarouselDateFocus();
      focus.onDaysChanged([DateTime(2026, 7, 29, 13, 45)]);
      focus.onPageChanged(0);
      expect(focus.resolvedDay, DateTime(2026, 7, 29));
    });
  });

  group('source guard — scheduling surfaces use the resolver', () {
    // Every surface that turns `scheduled_date` into a picker seed or a
    // user-visible day. Adding a new one? Route it through
    // schedule_date_utils.dart and list it here.
    const guarded = <String>[
      'lib/screens/workout/widgets/workout_actions_sheet.dart',
      'lib/screens/workout/widgets/reschedule_sheet.dart',
      'lib/screens/workout/workout_detail_screen_ui_2.dart',
    ];

    test('no raw DateTime.parse/tryParse of scheduledDate', () {
      final offenders = <String>[];
      for (final path in guarded) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'missing guarded file $path');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (!line.contains('scheduledDate')) continue;
          if (line.contains('DateTime.parse') ||
              line.contains('DateTime.tryParse')) {
            offenders.add('$path:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Parse scheduled_date with scheduledLocalDay() / '
            'reschedulePickerSeed() — a raw DateTime.parse yields a UTC '
            'instant off a noon-anchored timestamptz (E2E #31):\n'
            '${offenders.join('\n')}',
      );
    });

    test('date pickers do not use DateTime.now() as a bound', () {
      // `firstDate: DateTime.now()` carries a time-of-day, so a midnight
      // initialDate on the same day sorts before it.
      final offenders = <String>[];
      for (final path in guarded) {
        final lines = File(path).readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (RegExp(r'(firstDate|lastDate|initialDate)\s*:\s*DateTime\.now\(\)')
              .hasMatch(line)) {
            offenders.add('$path:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Use a local-midnight bound (DateTime(now.year, now.month, '
            'now.day)) for date-picker bounds:\n${offenders.join('\n')}',
      );
    });
  });
}
