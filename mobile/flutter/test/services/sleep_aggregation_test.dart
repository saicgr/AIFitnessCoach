import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'package:fitwiz/data/services/health_service.dart';

/// Tests for [aggregateSleepSummary] — the per-session sleep folding that
/// powers the home / You-tab "Last Night's Sleep" card and the synced
/// `sleep_minutes` value.
///
/// Regression context: a user slept ~11:00pm–6:00am (a watch-staged main
/// sleep) and then again ~6:30am–8:00am (a flat-logged morning nap). The
/// app showed ONLY the nap — the 7h main sleep was dropped. Cause: the old
/// aggregation derived the headline total purely from `SLEEP_ASLEEP` points
/// and folded the deep/light/REM stage minutes in ONLY when that total was
/// exactly zero. The nap's flat `SLEEP_ASLEEP` made the total non-zero, so
/// the staged main sleep's stages were never counted.
void main() {
  // Fixed reference date — the "night" spans 2026-05-19 into 2026-05-20.
  DateTime dt(int day, int hour, int minute) =>
      DateTime(2026, 5, day, hour, minute);

  /// Build a sleep [HealthDataPoint] the way Health Connect / HealthKit
  /// would deliver one. Only `type`, `uuid`, `dateFrom` and `dateTo` matter
  /// to the aggregator; `value` is recomputed from the dates by the
  /// `HealthDataPoint` constructor for stage types anyway.
  HealthDataPoint sleepPoint(
    HealthDataType type,
    String uuid,
    DateTime from,
    DateTime to,
  ) {
    return HealthDataPoint(
      uuid: uuid,
      value: NumericHealthValue(
          numericValue: to.difference(from).inMinutes.toDouble()),
      type: type,
      unit: HealthDataUnit.MINUTE,
      dateFrom: from,
      dateTo: to,
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'test-device',
      sourceId: 'test-source',
      sourceName: 'test',
    );
  }

  group('aggregateSleepSummary — reported regression', () {
    test(
        'watch-staged main sleep + flat-logged nap: BOTH are counted '
        '(the bug dropped the 7h main sleep)', () {
      final points = <HealthDataPoint>[
        // Main night sleep 11:00pm -> 6:00am, fully staged by a watch.
        // A staged session has NO generic "asleep" stage — only the
        // deep/light/REM/awake breakdown.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'main', dt(19, 23, 0),
            dt(20, 6, 0)), // 420m envelope
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'main', dt(19, 23, 0),
            dt(19, 23, 10)), // 10m settling in
        sleepPoint(HealthDataType.SLEEP_DEEP, 'main', dt(19, 23, 10),
            dt(20, 0, 30)), // 80m
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'main', dt(20, 0, 30),
            dt(20, 4, 30)), // 240m
        sleepPoint(HealthDataType.SLEEP_REM, 'main', dt(20, 4, 30),
            dt(20, 6, 0)), // 90m
        // Morning nap 6:30am -> 8:00am, logged flat (a single "asleep"
        // block with no deep/light/REM breakdown).
        sleepPoint(HealthDataType.SLEEP_SESSION, 'nap', dt(20, 6, 30),
            dt(20, 8, 0)), // 90m envelope
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'nap', dt(20, 6, 30),
            dt(20, 8, 0)), // 90m flat asleep
      ];

      final summary = aggregateSleepSummary(points);

      // Main asleep = 80 deep + 240 light + 90 rem = 410. Nap = 90 flat.
      // The OLD code returned 90 here (SLEEP_ASLEEP only) — that was the bug.
      expect(summary.totalMinutes, 500,
          reason: 'main staged sleep (410m) + nap (90m) must both count');
      expect(summary.deepMinutes, 80);
      expect(summary.lightMinutes, 240);
      expect(summary.remMinutes, 90);
      expect(summary.awakeMinutes, 10);
      // Bed/wake window spans the earliest start and latest end.
      expect(summary.bedTime, dt(19, 23, 0));
      expect(summary.wakeTime, dt(20, 8, 0));
      expect(summary.hasData, isTrue);
    });
  });

  group('aggregateSleepSummary — staging variations', () {
    test('two fully staged sessions, no flat "asleep" stage anywhere', () {
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'a', dt(19, 23, 0),
            dt(20, 5, 0)),
        sleepPoint(
            HealthDataType.SLEEP_DEEP, 'a', dt(19, 23, 0), dt(20, 0, 0)), // 60
        sleepPoint(
            HealthDataType.SLEEP_LIGHT, 'a', dt(20, 0, 0), dt(20, 3, 0)), // 180
        sleepPoint(
            HealthDataType.SLEEP_REM, 'a', dt(20, 3, 0), dt(20, 4, 0)), // 60
        sleepPoint(HealthDataType.SLEEP_SESSION, 'b', dt(20, 13, 0),
            dt(20, 14, 30)),
        sleepPoint(
            HealthDataType.SLEEP_DEEP, 'b', dt(20, 13, 0), dt(20, 13, 20)), // 20
        sleepPoint(
            HealthDataType.SLEEP_LIGHT, 'b', dt(20, 13, 20), dt(20, 14, 0)), // 40
        sleepPoint(
            HealthDataType.SLEEP_REM, 'b', dt(20, 14, 0), dt(20, 14, 10)), // 10
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 370, reason: '(60+180+60) + (20+40+10)');
      expect(summary.deepMinutes, 80);
      expect(summary.lightMinutes, 220);
      expect(summary.remMinutes, 70);
    });

    test('two flat sessions (SLEEP_ASLEEP only) are summed', () {
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'a', dt(19, 23, 0),
            dt(20, 5, 40)), // 400m
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'b', dt(20, 6, 30),
            dt(20, 7, 30)), // 60m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 460);
      expect(summary.deepMinutes, 0);
    });

    test('un-staged session with ONLY a SLEEP_SESSION envelope is counted',
        () {
      // A session a source wrote with no stages at all is visible only via
      // SLEEP_SESSION. The old code never queried SLEEP_SESSION, so this
      // night used to vanish entirely.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'x', dt(19, 23, 0),
            dt(20, 6, 30)), // 450m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 450);
      expect(summary.hasData, isTrue);
    });

    test('staged session is NOT double-counted with its own envelope', () {
      // One session that has BOTH a SLEEP_SESSION envelope and a full stage
      // breakdown must count its stages once — never envelope + stages.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'one', dt(19, 23, 0),
            dt(20, 7, 0)), // 480m envelope
        sleepPoint(
            HealthDataType.SLEEP_DEEP, 'one', dt(19, 23, 0), dt(20, 1, 0)), // 120
        sleepPoint(
            HealthDataType.SLEEP_LIGHT, 'one', dt(20, 1, 0), dt(20, 5, 0)), // 240
        sleepPoint(
            HealthDataType.SLEEP_REM, 'one', dt(20, 5, 0), dt(20, 6, 30)), // 90
        sleepPoint(
            HealthDataType.SLEEP_AWAKE, 'one', dt(20, 6, 30), dt(20, 7, 0)), // 30
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 450,
          reason: 'stages (120+240+90) win; envelope 480 is ignored');
      expect(summary.awakeMinutes, 30);
    });

    test('mixed: staged main sleep + un-staged session with no stages', () {
      final points = <HealthDataPoint>[
        // Staged main sleep.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'main', dt(19, 23, 0),
            dt(20, 6, 0)),
        sleepPoint(
            HealthDataType.SLEEP_DEEP, 'main', dt(19, 23, 0), dt(20, 1, 0)), // 120
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'main', dt(20, 1, 0),
            dt(20, 5, 30)), // 270
        sleepPoint(
            HealthDataType.SLEEP_REM, 'main', dt(20, 5, 30), dt(20, 6, 0)), // 30
        // A second session with no stage breakdown at all.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'late', dt(20, 14, 0),
            dt(20, 15, 0)), // 60m envelope, no stages
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 480, reason: '(120+270+30) staged + 60 env');
    });
  });

  group('aggregateSleepSummary — edge cases', () {
    test('empty input yields an empty summary', () {
      final summary = aggregateSleepSummary(const []);
      expect(summary.totalMinutes, 0);
      expect(summary.hasData, isFalse);
      expect(summary.bedTime, isNull);
      expect(summary.wakeTime, isNull);
    });

    test('a session that is entirely AWAKE counts as zero sleep', () {
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'aw', dt(19, 23, 0),
            dt(19, 23, 40)),
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'aw', dt(19, 23, 0),
            dt(19, 23, 40)), // 40m, never fell asleep
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 0,
          reason: 'staged-but-all-awake session is not sleep');
      expect(summary.awakeMinutes, 40);
      expect(summary.hasData, isFalse);
    });

    test('zero- and negative-length points are skipped', () {
      final points = <HealthDataPoint>[
        // Zero length.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'z', dt(20, 6, 0),
            dt(20, 6, 0)),
        // Negative length (clock skew / malformed write).
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'n', dt(20, 6, 30),
            dt(20, 6, 0)),
        // One real 100-minute block.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'real', dt(19, 23, 0),
            dt(20, 0, 40)),
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 100);
    });

    test('points with an empty uuid are each treated as their own session',
        () {
      // Empty uuids must not be merged into one bucket (which would let one
      // session overwrite another) — each becomes its own group.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_ASLEEP, '', dt(19, 23, 0),
            dt(20, 2, 20)), // 200m
        sleepPoint(HealthDataType.SLEEP_ASLEEP, '', dt(20, 3, 0),
            dt(20, 4, 0)), // 60m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 260);
    });

    test('bed/wake window spans the earliest start and latest end', () {
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_DEEP, 'm', dt(19, 22, 45),
            dt(20, 0, 45)),
        sleepPoint(HealthDataType.SLEEP_SESSION, 'm', dt(19, 22, 45),
            dt(20, 7, 15)),
        sleepPoint(HealthDataType.SLEEP_REM, 'm', dt(20, 5, 30),
            dt(20, 7, 15)),
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.bedTime, dt(19, 22, 45));
      expect(summary.wakeTime, dt(20, 7, 15));
    });
  });

  group('aggregateSleepSummary — multi-source overlap pre-pass', () {
    test(
        'two distinct-uuid sessions of the SAME night (>50% overlap): the '
        'shorter is dropped, the night is counted once', () {
      // A watch logged the night as a fully staged session; a phone bedtime
      // detector ALSO logged the same night as a shorter flat session. Both
      // are distinct SleepSessionRecords (distinct uuids). Summing them
      // double-counts the night — the pre-pass must drop the shorter.
      final points = <HealthDataPoint>[
        // Watch session — 23:00 -> 6:30 (450m span), fully staged.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'watch', dt(19, 23, 0),
            dt(20, 6, 30)),
        sleepPoint(HealthDataType.SLEEP_DEEP, 'watch', dt(19, 23, 0),
            dt(20, 1, 0)), // 120
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'watch', dt(20, 1, 0),
            dt(20, 5, 0)), // 240
        sleepPoint(HealthDataType.SLEEP_REM, 'watch', dt(20, 5, 0),
            dt(20, 6, 30)), // 90
        // Phone session — 23:20 -> 6:10 (410m span), flat asleep. Fully
        // inside the watch span, so overlap is 100% of the shorter span.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'phone', dt(19, 23, 20),
            dt(20, 6, 10)), // 410m envelope
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'phone', dt(19, 23, 20),
            dt(20, 6, 10)), // 410m flat asleep
      ];

      final summary = aggregateSleepSummary(points);

      // ONLY the watch session counts: 120 + 240 + 90 = 450 asleep.
      // If the phone session were not dropped the total would be 860.
      expect(summary.totalMinutes, 450,
          reason: 'overlapping duplicate night must be counted once');
      expect(summary.deepMinutes, 120);
      expect(summary.lightMinutes, 240);
      expect(summary.remMinutes, 90);
      // Window + time-in-bed reflect only the kept (watch) session.
      expect(summary.bedTime, dt(19, 23, 0));
      expect(summary.wakeTime, dt(20, 6, 30));
      expect(summary.timeInBedMinutes, 450,
          reason: 'kept watch envelope only');
    });

    test(
        'distinct-uuid sessions that overlap by <=50% of the shorter span '
        'are BOTH kept (a real main sleep + a real nap that touch)', () {
      // Main sleep 23:00 -> 6:00 (420m). Nap 5:30 -> 7:00 (90m). They
      // overlap 5:30-6:00 = 30m. 30m is exactly 1/3 of the 90m shorter
      // span — well under 50% — so these are two genuine sessions and the
      // pre-pass must keep both.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'main', dt(19, 23, 0),
            dt(20, 6, 0)), // 420m
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'nap', dt(20, 5, 30),
            dt(20, 7, 0)), // 90m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 510,
          reason: '420m + 90m — <=50% overlap keeps both');
    });

    test(
        'equal-span overlapping sessions: tie-break keeps the '
        'lexicographically smaller uuid', () {
      // Two distinct sessions, identical 300m span (23:00 -> 4:00), fully
      // overlapping. The deterministic tie-break keeps uuid "aaa" (smaller)
      // and drops "zzz". "aaa" is staged 150m deep + 150m light; "zzz" is a
      // flat 300m asleep block — so whichever survives also yields 300m
      // total, and the deep/light split is the discriminator.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'zzz', dt(19, 23, 0),
            dt(20, 4, 0)), // 300m flat
        sleepPoint(HealthDataType.SLEEP_DEEP, 'aaa', dt(19, 23, 0),
            dt(20, 1, 30)), // 150m
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'aaa', dt(20, 1, 30),
            dt(20, 4, 0)), // 150m
      ];

      final summary = aggregateSleepSummary(points);

      // "aaa" kept (150 deep + 150 light = 300 asleep); "zzz" dropped. The
      // staged deep/light split proves "aaa" — not "zzz" — survived.
      expect(summary.totalMinutes, 300,
          reason: 'tie-break keeps lexicographically smaller uuid "aaa"');
      expect(summary.deepMinutes, 150,
          reason: 'staged "aaa" survived, not flat "zzz"');
      expect(summary.lightMinutes, 150);
    });

    test('a third overlapping session is also dropped against the keeper',
        () {
      // Three distinct sessions all covering roughly the same night. The
      // longest is kept; the two shorter overlapping ones are both dropped.
      final points = <HealthDataPoint>[
        // Longest — 480m.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'long', dt(19, 23, 0),
            dt(20, 7, 0)), // 480m
        // Shorter overlappers.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'mid', dt(19, 23, 30),
            dt(20, 6, 0)), // 390m
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'short', dt(20, 0, 0),
            dt(20, 5, 30)), // 330m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 480,
          reason: 'only the longest of three overlapping sessions counts');
    });
  });

  group('aggregateSleepSummary — latency', () {
    test(
        'latency = minutes from session start to the first asleep stage '
        '(awake-in-bed gap before sleep onset)', () {
      // Envelope opens at 23:00. The user lies awake 23:00-23:25 (a 25m
      // AWAKE stage), then the first DEEP stage starts at 23:25. Latency is
      // therefore 25 minutes.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'lat', dt(19, 23, 0),
            dt(20, 6, 0)), // 420m envelope
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'lat', dt(19, 23, 0),
            dt(19, 23, 25)), // 25m awake-in-bed before sleep onset
        sleepPoint(HealthDataType.SLEEP_DEEP, 'lat', dt(19, 23, 25),
            dt(20, 1, 25)), // 120m — first asleep stage
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'lat', dt(20, 1, 25),
            dt(20, 4, 55)), // 210m
        sleepPoint(HealthDataType.SLEEP_REM, 'lat', dt(20, 4, 55),
            dt(20, 6, 0)), // 65m
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.latencyMinutes, 25,
          reason: 'session start 23:00 -> first DEEP stage 23:25');
      // 120 + 210 + 65 = 395 asleep; awake-in-bed 25m is not sleep.
      expect(summary.totalMinutes, 395);
      expect(summary.awakeMinutes, 25);
    });

    test('latency is null when a session is un-staged (no asleep stage)',
        () {
      // A bare SLEEP_SESSION envelope with no stage points — there is no
      // first-asleep marker, so latency genuinely cannot be computed.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'bare', dt(19, 23, 0),
            dt(20, 6, 0)), // 420m envelope, no stages
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.latencyMinutes, isNull,
          reason: 'no asleep stage ⇒ latency unknown');
      expect(summary.totalMinutes, 420);
    });

    test('latency is 0 when the first asleep stage starts at session start',
        () {
      // No awake-in-bed gap — the first DEEP stage begins exactly when the
      // envelope opens. Latency is 0, not null.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'z', dt(19, 23, 0),
            dt(20, 5, 0)),
        sleepPoint(HealthDataType.SLEEP_DEEP, 'z', dt(19, 23, 0),
            dt(20, 1, 0)), // 120 — starts at envelope start
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'z', dt(20, 1, 0),
            dt(20, 5, 0)), // 240
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.latencyMinutes, 0);
    });

    test('latency uses the LONGEST kept session when several are present',
        () {
      // A long main sleep (latency 20m) plus a disjoint short nap
      // (latency 5m). The reported latency is the main sleep's 20m.
      final points = <HealthDataPoint>[
        // Main sleep — envelope 23:00, first asleep 23:20 ⇒ latency 20.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'main', dt(19, 23, 0),
            dt(20, 6, 0)),
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'main', dt(19, 23, 0),
            dt(19, 23, 20)),
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'main', dt(19, 23, 20),
            dt(20, 6, 0)), // 400
        // Nap — envelope 13:00, first asleep 13:05 ⇒ latency 5.
        sleepPoint(HealthDataType.SLEEP_SESSION, 'nap', dt(20, 13, 0),
            dt(20, 13, 50)),
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'nap', dt(20, 13, 0),
            dt(20, 13, 5)),
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'nap', dt(20, 13, 5),
            dt(20, 13, 50)), // 45
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.latencyMinutes, 20,
          reason: 'longest kept session (the main sleep) owns the latency');
      expect(summary.totalMinutes, 445, reason: '400 main + 45 nap');
    });
  });

  group('aggregateSleepSummary — efficiency & time-in-bed', () {
    test(
        'efficiency = asleep / time-in-bed when asleep is less than the '
        'envelope (awake-in-bed time present)', () {
      // 480m envelope. Staged: 60 awake + 420 asleep (120+240+60). Asleep
      // is less than time-in-bed, so efficiency = 420 / 480 = 0.875.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'eff', dt(19, 23, 0),
            dt(20, 7, 0)), // 480m envelope
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'eff', dt(19, 23, 0),
            dt(19, 23, 30)), // 30m awake at the start
        sleepPoint(HealthDataType.SLEEP_DEEP, 'eff', dt(19, 23, 30),
            dt(20, 1, 30)), // 120
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'eff', dt(20, 1, 30),
            dt(20, 5, 30)), // 240
        sleepPoint(HealthDataType.SLEEP_REM, 'eff', dt(20, 5, 30),
            dt(20, 6, 30)), // 60
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'eff', dt(20, 6, 30),
            dt(20, 7, 0)), // 30m awake at the end
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 420, reason: '120 + 240 + 60 asleep');
      expect(summary.timeInBedMinutes, 480,
          reason: 'the SLEEP_SESSION envelope is time-in-bed');
      expect(summary.efficiency, isNotNull);
      expect(summary.efficiency!, closeTo(420 / 480, 1e-9)); // 0.875
    });

    test(
        'time-in-bed falls back to the wall-clock span when there is no '
        'SLEEP_SESSION envelope', () {
      // No envelope — only stage points. Span is 23:00 -> 6:00 = 420m.
      // Asleep = 60 awake excluded ⇒ 360 (120 deep + 240 light). Efficiency
      // = 360 / 420.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_DEEP, 'span', dt(19, 23, 0),
            dt(20, 1, 0)), // 120
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'span', dt(20, 1, 0),
            dt(20, 5, 0)), // 240
        sleepPoint(HealthDataType.SLEEP_AWAKE, 'span', dt(20, 5, 0),
            dt(20, 6, 0)), // 60m awake at the end
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 360);
      expect(summary.timeInBedMinutes, 420,
          reason: 'no envelope ⇒ wall-clock span 23:00-6:00');
      expect(summary.efficiency!, closeTo(360 / 420, 1e-9));
    });

    test(
        'a fully staged session with no awake time has efficiency 1.0 '
        '(time-in-bed equals asleep)', () {
      // No awake stage, no envelope: span equals the asleep total, so
      // efficiency is exactly 1.0.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_DEEP, 'full', dt(19, 23, 0),
            dt(20, 1, 0)), // 120
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'full', dt(20, 1, 0),
            dt(20, 5, 0)), // 240
      ];

      final summary = aggregateSleepSummary(points);

      expect(summary.totalMinutes, 360);
      expect(summary.timeInBedMinutes, 360);
      expect(summary.efficiency, 1.0);
    });

    test('efficiency and time-in-bed are null for an empty summary', () {
      final summary = aggregateSleepSummary(const []);
      expect(summary.timeInBedMinutes, isNull);
      expect(summary.efficiency, isNull);
      expect(summary.latencyMinutes, isNull);
    });
  });

  group('bucketSleepPointsByWakeDate — wake-date attribution', () {
    test(
        'a session crossing midnight files under its WAKE date '
        '(the morning it ended), not its bed date', () {
      // Slept 11:00pm on the 19th -> 6:00am on the 20th. The session must
      // bucket under the 20th (wake date), NOT the 19th (bed date).
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 'night', dt(19, 23, 0),
            dt(20, 6, 0)),
        sleepPoint(HealthDataType.SLEEP_DEEP, 'night', dt(19, 23, 0),
            dt(20, 1, 0)),
        sleepPoint(HealthDataType.SLEEP_LIGHT, 'night', dt(20, 1, 0),
            dt(20, 6, 0)),
      ];

      final byNight = bucketSleepPointsByWakeDate(points);

      expect(byNight.keys, hasLength(1));
      expect(byNight.containsKey(DateTime(2026, 5, 20)), isTrue,
          reason: 'midnight-crossing sleep files under the wake date');
      expect(byNight.containsKey(DateTime(2026, 5, 19)), isFalse,
          reason: 'it must NOT also appear under the bed date');
      // The one wake-date bucket holds exactly one session of 3 points.
      final sessions = byNight[DateTime(2026, 5, 20)]!;
      expect(sessions, hasLength(1));
      expect(sessions.first, hasLength(3));
    });

    test(
        'two distinct nights bucket under their own wake dates; a same-day '
        'nap joins that day', () {
      final points = <HealthDataPoint>[
        // Night A: 11pm 18th -> 6am 19th → wake date 19th.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'a', dt(18, 23, 0),
            dt(19, 6, 0)),
        // Night B: 11pm 19th -> 6am 20th → wake date 20th.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'b', dt(19, 23, 0),
            dt(20, 6, 0)),
        // A nap on the 20th (1pm -> 2pm) → also wake date 20th.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'nap', dt(20, 13, 0),
            dt(20, 14, 0)),
      ];

      final byNight = bucketSleepPointsByWakeDate(points);

      expect(byNight.keys, hasLength(2));
      // 19th has just night A.
      expect(byNight[DateTime(2026, 5, 19)], hasLength(1));
      // 20th has night B AND the nap → two sessions.
      expect(byNight[DateTime(2026, 5, 20)], hasLength(2));
    });

    test('the wake date is the LATEST end across all of a session\'s points',
        () {
      // The SLEEP_SESSION envelope ends earlier than the final REM stage —
      // the latest end (the REM stage) decides the wake date.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_SESSION, 's', dt(19, 23, 0),
            dt(20, 5, 0)), // envelope ends 5:00am on the 20th
        sleepPoint(HealthDataType.SLEEP_REM, 's', dt(20, 5, 0),
            dt(20, 5, 30)), // a stage ending 5:30am on the 20th
      ];

      final byNight = bucketSleepPointsByWakeDate(points);

      expect(byNight.keys.single, DateTime(2026, 5, 20));
    });

    test('zero- and negative-length points are excluded from bucketing', () {
      final points = <HealthDataPoint>[
        // Zero length — must not create a bucket.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'z', dt(20, 6, 0),
            dt(20, 6, 0)),
        // Negative length — must not create a bucket.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'n', dt(20, 7, 0),
            dt(20, 6, 0)),
        // One real session waking on the 20th.
        sleepPoint(HealthDataType.SLEEP_ASLEEP, 'real', dt(19, 23, 0),
            dt(20, 6, 0)),
      ];

      final byNight = bucketSleepPointsByWakeDate(points);

      expect(byNight.keys, hasLength(1));
      expect(byNight[DateTime(2026, 5, 20)], hasLength(1));
    });

    test('empty input yields an empty map', () {
      expect(bucketSleepPointsByWakeDate(const []), isEmpty);
    });

    test('empty-uuid points each become their own session in the bucket',
        () {
      // Two empty-uuid points that both wake on the 20th must NOT be merged
      // into one session — each is its own session of that wake date.
      final points = <HealthDataPoint>[
        sleepPoint(HealthDataType.SLEEP_ASLEEP, '', dt(19, 23, 0),
            dt(20, 2, 0)),
        sleepPoint(HealthDataType.SLEEP_ASLEEP, '', dt(20, 3, 0),
            dt(20, 5, 0)),
      ];

      final byNight = bucketSleepPointsByWakeDate(points);

      expect(byNight.keys, hasLength(1));
      expect(byNight[DateTime(2026, 5, 20)], hasLength(2),
          reason: 'empty uuids are not merged into one session');
    });
  });
}
