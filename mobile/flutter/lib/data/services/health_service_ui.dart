part of 'health_service.dart';

/// Methods extracted from HealthService
extension HealthServiceExt on HealthService {

  // Data types we want to read from Health Connect / HealthKit.
  //
  // Removed 2026-05-07 to comply with Google Play "Minimum Scope" Health
  // Connect Permissions policy: Distance (delta + walking/running),
  // FloorsClimbed (FLIGHTS_CLIMBED), HeartRateVariability (RMSSD + SDNN),
  // ElevationGained, Power, Speed, RespiratoryRate, BasalMetabolicRate
  // (BASAL_ENERGY_BURNED), OxygenSaturation (BLOOD_OXYGEN), BodyTemperature.
  // None of these surface in the user-facing product.
  static final List<HealthDataType> _readTypes = [
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,

    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,

    // Workout
    HealthDataType.WORKOUT,

    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_SESSION,

    // Hydration
    HealthDataType.WATER,

    // Diabetic metrics
    HealthDataType.BLOOD_GLUCOSE,
  ];

  // Data types we want to write to Health Connect / HealthKit.
  //
  // WATER + NUTRITION added 2026-05-21: the app already writes a logged
  // meal (`writeMealToHealth`) and water (`writeHydrationToHealth`) back
  // to the platform, but those two types were missing here — so the
  // write-permission grant never covered them and every meal / hydration
  // write-back silently failed. WATER maps to the `WRITE_HYDRATION`
  // Android manifest permission (already declared); NUTRITION required
  // adding `WRITE_NUTRITION` to AndroidManifest.xml to match. On iOS the
  // single `NSHealthUpdateUsageDescription` string already covers them.
  static final List<HealthDataType> _writeTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WATER,
    HealthDataType.NUTRITION,
  ];

  /// Check if Health Connect is available on the device
  Future<bool> isHealthConnectAvailable() async {
    try {
      await _ensureConfigured();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      } else if (Platform.isIOS) {
        // HealthKit is always available on iOS (if device supports it)
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking Health Connect availability: $e');
      return false;
    }
  }


  // ============================================
  // Sleep Data
  // ============================================

  /// Get sleep data summary for recent nights.
  ///
  /// Health Connect stores each sleep as a `SleepSessionRecord` that may or
  /// may not carry a fine-grained `stages` breakdown:
  ///   • A watch-staged session is split into DEEP / LIGHT / REM / AWAKE
  ///     stages and carries NO generic "asleep" stage.
  ///   • A session a source logged without staging — a manual entry, a
  ///     short nap, phone-only bedtime detection — is either a single flat
  ///     "asleep" stage, or has no stages at all (visible ONLY through the
  ///     SLEEP_SESSION envelope).
  ///
  /// Because of this, total sleep MUST be summed per session and the
  /// SLEEP_SESSION type MUST be queried. Otherwise an un-staged session is
  /// invisible, and — worse — a fully staged main sleep is dropped from the
  /// headline total the instant any other session (e.g. a morning nap)
  /// contributes a flat "asleep" stage, because the old code derived the
  /// total purely from SLEEP_ASLEEP and only fell back to the stage sum
  /// when that total happened to be exactly zero.
  ///
  /// The actual aggregation lives in [aggregateSleepSummary] so it can be
  /// unit-tested against synthetic Health Connect / HealthKit payloads.
  Future<SleepSummary> getSleepData({int days = 1}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // SLEEP_SESSION is mandatory: it is the only query that returns a
      // session with no stage breakdown. `_getAvailableTypes` drops it on
      // iOS automatically (HealthKit has no session-envelope record).
      final sleepTypes = _getAvailableTypes(_sleepQueryTypes);
      // Skip when READ_SLEEP isn't granted — avoids the plugin SecurityException
      // spam (it logs internally before we can catch it).
      if (!await hasReadAccess(sleepTypes)) return const SleepSummary();

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: sleepTypes,
      );

      final uniqueData = _health.removeDuplicates(data);
      final summary = aggregateSleepSummary(uniqueData);

      debugPrint('😴 Sleep data: ${summary.totalMinutes}min total, '
          '${summary.deepMinutes}min deep, ${summary.remMinutes}min REM, '
          '${summary.lightMinutes}min light, ${summary.awakeMinutes}min awake '
          '(bed ${summary.bedTime}, wake ${summary.wakeTime})');
      return summary;
    } catch (e) {
      debugPrint('❌ Error getting sleep data: $e');
      return const SleepSummary();
    }
  }

  /// The sleep types queried by every sleep read. SLEEP_SESSION is
  /// mandatory — see [getSleepData] for why. `_getAvailableTypes` drops the
  /// Android-only types on iOS automatically.
  static const List<HealthDataType> _sleepQueryTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
  ];

  /// Get sleep for an explicit [start, end] window.
  ///
  /// Identical aggregation to [getSleepData] but with caller-supplied
  /// bounds instead of a day count. Used by the 30-day activity backfill so
  /// each historical day's `[dayStart, dayEnd]` sleep can be summed onto
  /// its [DailyActivity].
  Future<SleepSummary> getSleepForRange(DateTime start, DateTime end) async {
    try {
      await _ensureConfigured();
      final sleepTypes = _getAvailableTypes(_sleepQueryTypes);
      if (!await hasReadAccess(sleepTypes)) return const SleepSummary();

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: sleepTypes,
      );

      final uniqueData = _health.removeDuplicates(data);
      return aggregateSleepSummary(uniqueData);
    } catch (e) {
      debugPrint('❌ Error getting sleep for range $start..$end: $e');
      return const SleepSummary();
    }
  }

  /// Get a per-night sleep history for the last [days] days.
  ///
  /// Health Connect / HealthKit return a flat point list; this groups the
  /// points into sessions by `uuid`, then buckets each session by its WAKE
  /// date — the local calendar date of the session's latest end — so a
  /// sleep that crosses midnight files under the morning it ended. Per
  /// night the longest session becomes the [DailySleep.mainSleep] and every
  /// other session of that wake date becomes a nap.
  ///
  /// Each session's points are aggregated through [aggregateSleepSummary]
  /// individually; because one session never overlaps itself, the
  /// multi-source overlap pre-pass inside the aggregator is a no-op here.
  ///
  /// The uuid-grouping + wake-date-bucketing is shared with
  /// [getDailySleepByWakeDate] via [bucketSleepPointsByWakeDate].
  ///
  /// Returns the nights newest-first.
  Future<List<DailySleep>> getNightlySleepHistory({int days = 30}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final sleepTypes = _getAvailableTypes(_sleepQueryTypes);
      if (!await hasReadAccess(sleepTypes)) return [];
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: sleepTypes,
      );
      final uniqueData = _health.removeDuplicates(data);

      // Group points into sessions by uuid and bucket by wake date — the
      // single shared implementation, also used by getDailySleepByWakeDate.
      final byNight = bucketSleepPointsByWakeDate(uniqueData);

      final nights = <DailySleep>[];
      byNight.forEach((wakeDate, nightSessions) {
        // Longest session (by wall-clock span) is the main sleep; the rest
        // are naps. Sort descending by span so index 0 is the main sleep
        // and naps stay longest-first.
        nightSessions.sort((a, b) => _sessionSpanMinutes(b)
            .compareTo(_sessionSpanMinutes(a)));

        final mainSleep = aggregateSleepSummary(nightSessions.first);
        final naps = nightSessions
            .skip(1)
            .map((pts) => aggregateSleepSummary(pts))
            .toList();

        var totalAsleep = mainSleep.totalMinutes;
        for (final nap in naps) {
          totalAsleep += nap.totalMinutes;
        }

        nights.add(DailySleep(
          date: wakeDate,
          mainSleep: mainSleep,
          naps: naps,
          totalAsleepMinutes: totalAsleep,
        ));
      });

      // Newest night first.
      nights.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('😴 Nightly sleep history: ${nights.length} nights '
          'over $days days');
      return nights;
    } catch (e) {
      debugPrint('❌ Error getting nightly sleep history: $e');
      return const [];
    }
  }

  /// Get ONE combined [SleepSummary] per wake date for the last [days] days,
  /// keyed by that wake date (local-midnight `DateTime`).
  ///
  /// Unlike [getNightlySleepHistory] this does NOT split a night into
  /// main-sleep + naps: the `daily_activity` row stores a single combined
  /// sleep value per calendar day, so every point that wakes on a given
  /// date is folded through [aggregateSleepSummary] together.
  ///
  /// This is the correct source for the activity backfill: a sleep that
  /// crosses midnight (11pm Mon -> 6am Tue) is attributed to its WAKE date
  /// (Tue) exactly once — never double-counted across two per-day windows,
  /// which is the bug a per-day `getSleepForRange` loop would cause.
  Future<Map<DateTime, SleepSummary>> getDailySleepByWakeDate(
      {int days = 30}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      final sleepTypes = _getAvailableTypes(_sleepQueryTypes);
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: sleepTypes,
      );
      final uniqueData = _health.removeDuplicates(data);

      // Same uuid-grouping + wake-date-bucketing as getNightlySleepHistory.
      final byNight = bucketSleepPointsByWakeDate(uniqueData);

      final byDate = <DateTime, SleepSummary>{};
      byNight.forEach((wakeDate, nightSessions) {
        // Flatten every session of this wake date into one point list and
        // aggregate once — a single combined SleepSummary for the day.
        final allPoints = <HealthDataPoint>[
          for (final session in nightSessions) ...session,
        ];
        byDate[wakeDate] = aggregateSleepSummary(allPoints);
      });

      debugPrint('😴 Daily sleep by wake date: ${byDate.length} days '
          'over $days days');
      return byDate;
    } catch (e) {
      debugPrint('❌ Error getting daily sleep by wake date: $e');
      return const {};
    }
  }

  /// Wall-clock span (latest end − earliest start, in minutes) of one
  /// session's point list. Used to pick the longest session of a night.
  /// Today's mindful minutes from Apple Health (iOS only).
  ///
  /// Returns 0 on Android by design: MINDFULNESS is not part of the Android
  /// Health Connect scope (Play minimum-scope compliance —
  /// project_play_health_connect_rejection), so on Android the mindful-minutes
  /// metric comes purely from in-app session logs. The caller merges this with
  /// the in-app server aggregate using max() so a single session counted by
  /// both sources is not double-counted (plan edge case B3).
  Future<int> getTodayMindfulnessMinutes() async {
    if (!Platform.isIOS) return 0;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.MINDFULNESS],
      );
      final unique = _health.removeDuplicates(data);

      double minutes = 0;
      for (final point in unique) {
        // MINDFULNESS points are sessions; prefer the actual time span, and
        // fall back to a numeric MINUTE value if the span is zero-length.
        final spanSecs = point.dateTo.difference(point.dateFrom).inSeconds;
        if (spanSecs > 0) {
          minutes += spanSecs / 60.0;
        } else if (point.value is NumericHealthValue) {
          minutes += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return minutes.round();
    } catch (e) {
      debugPrint('❌ [Health] mindfulness read failed: $e');
      return 0;
    }
  }

  int _sessionSpanMinutes(List<HealthDataPoint> pts) {
    DateTime? start;
    DateTime? end;
    for (final p in pts) {
      if (start == null || p.dateFrom.isBefore(start)) start = p.dateFrom;
      if (end == null || p.dateTo.isAfter(end)) end = p.dateTo;
    }
    if (start == null || end == null) return 0;
    final span = end.difference(start).inMinutes;
    return span > 0 ? span : 0;
  }


  // ============================================
  // Recovery Metrics
  // ============================================

  /// Get recovery metrics. HRV and SpO2 were removed 2026-05-07 (Google Play
  /// minimum scope), so this now only returns resting heart rate. The
  /// RecoveryMetrics class still carries hrv/bloodOxygen fields for
  /// backwards compatibility — they are always null.
  Future<RecoveryMetrics> getRecoveryMetrics() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));

      final types = _getAvailableTypes([
        HealthDataType.RESTING_HEART_RATE,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int? restingHR;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        if (point.type == HealthDataType.RESTING_HEART_RATE) {
          restingHR ??= value.toInt();
        }
      }

      debugPrint('💚 Recovery: HR=$restingHR');
      return RecoveryMetrics(restingHR: restingHR);
    } catch (e) {
      debugPrint('❌ Error getting recovery metrics: $e');
      return const RecoveryMetrics();
    }
  }


  /// Get today's vitals (heart rate + water).
  ///
  /// HRV, SpO2, body temperature, respiratory rate, basal calories, and
  /// flights climbed were removed 2026-05-07 (Google Play minimum scope).
  /// The legacy null-valued keys for those metrics were also dropped — UI
  /// consumers no longer look them up.
  Future<Map<String, dynamic>> getTodayVitals() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final types = _getAvailableTypes([
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.WATER,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int heartRateSum = 0;
      int heartRateCount = 0;
      int maxHeartRate = 0;
      int? minHeartRate;
      int? restingHeartRate; // today's resting HR (most recent reading)
      double waterMl = 0;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.HEART_RATE:
            final v = value.toInt();
            heartRateSum += v;
            heartRateCount++;
            if (v > maxHeartRate) maxHeartRate = v;
            if (minHeartRate == null || v < minHeartRate) minHeartRate = v;
            break;
          case HealthDataType.RESTING_HEART_RATE:
            // removeDuplicates keeps these time-ordered; last one wins so we
            // surface today's most recent resting-HR reading.
            restingHeartRate = value.toInt();
            break;
          case HealthDataType.WATER:
            waterMl += value;
            break;
          default:
            break;
        }
      }

      return {
        'avgHeartRate': heartRateCount > 0 ? heartRateSum ~/ heartRateCount : null,
        'maxHeartRate': maxHeartRate > 0 ? maxHeartRate : null,
        'minHeartRate': minHeartRate,
        'restingHeartRate': restingHeartRate,
        'waterMl': waterMl > 0 ? waterMl.toInt() : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting today vitals: $e');
      return {};
    }
  }

}


/// Per-session sleep accumulator used by [aggregateSleepSummary].
///
/// One instance holds a single Health Connect `SleepSessionRecord` (or, on
/// iOS, a single HealthKit sleep sample) while its stage points are tallied,
/// then yields that one session's asleep minutes.
class _SleepSessionAgg {
  /// Duration of the SLEEP_SESSION envelope (the whole session, stages
  /// aside). Only used when the session carries no stage data at all.
  int sessionMinutes = 0;

  /// Generic "asleep" stage minutes — a source reported "asleep" with no
  /// deep / light / REM breakdown (Health Connect `STAGE_TYPE_SLEEPING`,
  /// HealthKit `asleepUnspecified`).
  int asleepMinutes = 0;
  int deepMinutes = 0;
  int lightMinutes = 0;
  int remMinutes = 0;
  int awakeMinutes = 0;

  /// Start of the SLEEP_SESSION envelope, if this session carried one.
  /// Preferred origin for the latency calculation: the envelope begins
  /// the instant the source considers the user "in bed".
  DateTime? envelopeStart;

  /// Earliest `dateFrom` and latest `dateTo` across ALL of this session's
  /// points (stages AND the SLEEP_SESSION envelope). Together they give
  /// the real wall-clock span the session occupied — used both for the
  /// multi-source overlap pre-pass and as the time-in-bed fallback when
  /// no envelope is present.
  DateTime? earliestStart;
  DateTime? latestEnd;

  /// Earliest start among the ASLEEP / DEEP / LIGHT / REM stage points —
  /// the moment the user first fell asleep. AWAKE / AWAKE_IN_BED points
  /// are deliberately excluded so awake-in-bed time before sleep onset
  /// counts towards latency, not against it.
  DateTime? firstAsleepStart;

  /// True once ANY stage point (asleep OR awake) has landed for this
  /// session — meaning the source DID stage it, so the stages are trusted
  /// over the raw SLEEP_SESSION envelope.
  bool get _hasStageData =>
      asleepMinutes > 0 ||
      deepMinutes > 0 ||
      lightMinutes > 0 ||
      remMinutes > 0 ||
      awakeMinutes > 0;

  /// Minutes ASLEEP for this one session (excludes awake-in-bed time):
  ///   • staged session    → deep + light + REM + generic-asleep stages
  ///   • un-staged session → the SLEEP_SESSION envelope duration
  ///
  /// A staged session never also adds its envelope, so each session is
  /// counted exactly once — there is no double counting.
  int get asleepMinutesForSession {
    if (_hasStageData) {
      return asleepMinutes + deepMinutes + lightMinutes + remMinutes;
    }
    return sessionMinutes;
  }

  /// Wall-clock span of the session in minutes — latest end minus earliest
  /// start across every point. 0 when the session has no usable points
  /// (defensive; the caller skips zero-length points so this rarely is 0).
  int get spanMinutes {
    final start = earliestStart;
    final end = latestEnd;
    if (start == null || end == null) return 0;
    final span = end.difference(start).inMinutes;
    return span > 0 ? span : 0;
  }

  /// The instant the source considers the user "in bed" for this session:
  /// the SLEEP_SESSION envelope start when present, otherwise the earliest
  /// point start. Null only when the session has no points at all.
  DateTime? get sessionStart => envelopeStart ?? earliestStart;

  /// Time the user spent in bed for this session — asleep PLUS awake-in-bed:
  ///   • the SLEEP_SESSION envelope duration when one was reported;
  ///   • otherwise the wall-clock [spanMinutes].
  /// 0 when neither is known.
  int get timeInBedMinutes =>
      sessionMinutes > 0 ? sessionMinutes : spanMinutes;

  /// Minutes from [sessionStart] to [firstAsleepStart] — how long the user
  /// took to fall asleep. Null when either bound is unknown (un-staged
  /// session, or no envelope/point start). Clamped at 0 so a first-asleep
  /// point that very slightly precedes the envelope start (source clock
  /// rounding) can never report a negative latency.
  int? get latencyMinutes {
    final start = sessionStart;
    final asleep = firstAsleepStart;
    if (start == null || asleep == null) return null;
    final latency = asleep.difference(start).inMinutes;
    return latency > 0 ? latency : 0;
  }
}

/// Fold a flat list of Health Connect / HealthKit sleep [HealthDataPoint]s
/// into a single [SleepSummary].
///
/// Sleep is summed PER SESSION, then across sessions:
///   • points are grouped by `uuid` — on Health Connect every stage of one
///     `SleepSessionRecord` (and that record's SLEEP_SESSION envelope)
///     shares the parent record id; on iOS each sample carries its own id,
///     so a "group" degrades to a single sample, which still sums correctly;
///   • a staged session contributes deep + light + REM + generic-asleep;
///   • an un-staged session contributes its SLEEP_SESSION envelope;
///   • each session is therefore counted exactly once.
///
/// This is the fix for the headline total dropping a watch-staged main
/// sleep whenever a second, flat-logged session (e.g. a morning nap) was
/// also present — see [HealthServiceExt.getSleepData].
@visibleForTesting
SleepSummary aggregateSleepSummary(List<HealthDataPoint> points) {
  final sessions = <String, _SleepSessionAgg>{};
  var orphanCounter = 0;

  for (final point in points) {
    final durationMin = point.dateTo.difference(point.dateFrom).inMinutes;
    // Skip zero- / negative-length artifacts (clock skew, malformed writes).
    if (durationMin <= 0) continue;

    // Group by session id. Points with an empty uuid (older Health Connect
    // rows, some HealthKit samples) can't be grouped, so each gets its own
    // synthetic key — never merged together, never dropped.
    final key =
        point.uuid.isNotEmpty ? point.uuid : '__orphan_${orphanCounter++}';
    final agg = sessions.putIfAbsent(key, () => _SleepSessionAgg());

    switch (point.type) {
      case HealthDataType.SLEEP_SESSION:
        // Whole-session envelope. A session can be returned more than once
        // across paged reads — keep the longest rather than summing.
        if (durationMin > agg.sessionMinutes) {
          agg.sessionMinutes = durationMin;
        }
        // The earliest envelope start is the "in bed" instant for latency.
        if (agg.envelopeStart == null ||
            point.dateFrom.isBefore(agg.envelopeStart!)) {
          agg.envelopeStart = point.dateFrom;
        }
        break;
      case HealthDataType.SLEEP_ASLEEP:
        agg.asleepMinutes += durationMin;
        break;
      case HealthDataType.SLEEP_DEEP:
        agg.deepMinutes += durationMin;
        break;
      case HealthDataType.SLEEP_REM:
        agg.remMinutes += durationMin;
        break;
      case HealthDataType.SLEEP_LIGHT:
        agg.lightMinutes += durationMin;
        break;
      case HealthDataType.SLEEP_AWAKE:
      case HealthDataType.SLEEP_AWAKE_IN_BED:
        agg.awakeMinutes += durationMin;
        break;
      default:
        // Non-sleep point — ignore (defensive; the caller only queries
        // sleep types).
        break;
    }

    // Per-session span — earliest start / latest end across every point.
    if (agg.earliestStart == null ||
        point.dateFrom.isBefore(agg.earliestStart!)) {
      agg.earliestStart = point.dateFrom;
    }
    if (agg.latestEnd == null || point.dateTo.isAfter(agg.latestEnd!)) {
      agg.latestEnd = point.dateTo;
    }

    // First-asleep marker — earliest start among the ASLEEP-family stages
    // (AWAKE / AWAKE_IN_BED excluded so pre-sleep awake time counts as
    // latency). Drives [_SleepSessionAgg.latencyMinutes].
    if (point.type == HealthDataType.SLEEP_ASLEEP ||
        point.type == HealthDataType.SLEEP_DEEP ||
        point.type == HealthDataType.SLEEP_LIGHT ||
        point.type == HealthDataType.SLEEP_REM) {
      if (agg.firstAsleepStart == null ||
          point.dateFrom.isBefore(agg.firstAsleepStart!)) {
        agg.firstAsleepStart = point.dateFrom;
      }
    }
  }

  // ── Multi-source overlap pre-pass ──────────────────────────────────────
  // Two apps tracking the same night (e.g. a watch + a phone bedtime
  // detector) each write their own SleepSessionRecord with a DISTINCT uuid.
  // Summing both double-counts the night. Detect pairs of distinct-uuid
  // sessions whose [earliestStart,latestEnd] spans overlap by more than
  // 50% of the SHORTER span, and drop the shorter session (keep the longer,
  // i.e. the more complete record). Deterministic tie-break on equal span:
  // keep the lexicographically smaller uuid. A dropped session contributes
  // nothing to any total. Single-source nights have no distinct-uuid
  // overlap, so this pre-pass leaves them untouched.
  final droppedKeys = <String>{};
  final keys = sessions.keys.toList();
  for (var i = 0; i < keys.length; i++) {
    final ki = keys[i];
    if (droppedKeys.contains(ki)) continue;
    for (var j = i + 1; j < keys.length; j++) {
      final kj = keys[j];
      if (droppedKeys.contains(kj)) continue;
      final a = sessions[ki]!;
      final b = sessions[kj]!;
      final aStart = a.earliestStart;
      final aEnd = a.latestEnd;
      final bStart = b.earliestStart;
      final bEnd = b.latestEnd;
      // Need a real span on both sides to compare.
      if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
        continue;
      }
      final aSpan = aEnd.difference(aStart).inMinutes;
      final bSpan = bEnd.difference(bStart).inMinutes;
      if (aSpan <= 0 || bSpan <= 0) continue;

      // Intersection of the two [start,end] intervals.
      final overlapStart = aStart.isAfter(bStart) ? aStart : bStart;
      final overlapEnd = aEnd.isBefore(bEnd) ? aEnd : bEnd;
      final overlapMin = overlapEnd.difference(overlapStart).inMinutes;
      if (overlapMin <= 0) continue; // disjoint — distinct nights/naps

      final shorterSpan = aSpan < bSpan ? aSpan : bSpan;
      // More than 50% of the SHORTER span overlapping ⇒ same night.
      if (overlapMin * 2 <= shorterSpan) continue;

      // Drop the shorter; keep the longer. Equal span ⇒ keep the
      // lexicographically smaller uuid (drop the larger).
      String loser;
      if (aSpan != bSpan) {
        loser = aSpan < bSpan ? ki : kj;
      } else {
        loser = ki.compareTo(kj) <= 0 ? kj : ki;
      }
      droppedKeys.add(loser);
      // If the session we're iterating from (ki) was just dropped, stop
      // pairing it against further sessions.
      if (loser == ki) break;
    }
  }

  // Aggregate only the KEPT sessions.
  int totalMinutes = 0;
  int deepMinutes = 0;
  int remMinutes = 0;
  int lightMinutes = 0;
  int awakeMinutes = 0;
  int timeInBedMinutes = 0;
  int? longestKeptLatency;
  int longestKeptTimeInBed = -1; // span of the session owning the latency
  DateTime? earliestBed;
  DateTime? latestWake;

  sessions.forEach((key, agg) {
    if (droppedKeys.contains(key)) return;

    totalMinutes += agg.asleepMinutesForSession;
    deepMinutes += agg.deepMinutes;
    remMinutes += agg.remMinutes;
    lightMinutes += agg.lightMinutes;
    awakeMinutes += agg.awakeMinutes;
    timeInBedMinutes += agg.timeInBedMinutes;

    // Bed / wake window spans every kept stage AND every kept envelope.
    final s = agg.earliestStart;
    final e = agg.latestEnd;
    if (s != null && (earliestBed == null || s.isBefore(earliestBed!))) {
      earliestBed = s;
    }
    if (e != null && (latestWake == null || e.isAfter(latestWake!))) {
      latestWake = e;
    }

    // Latency is reported for the longest kept session (by time-in-bed).
    final latency = agg.latencyMinutes;
    if (latency != null && agg.timeInBedMinutes > longestKeptTimeInBed) {
      longestKeptTimeInBed = agg.timeInBedMinutes;
      longestKeptLatency = latency;
    }
  });

  // Efficiency only when time-in-bed is a usable, non-zero divisor.
  final double? efficiency =
      timeInBedMinutes > 0 ? totalMinutes / timeInBedMinutes : null;

  return SleepSummary(
    totalMinutes: totalMinutes,
    deepMinutes: deepMinutes,
    remMinutes: remMinutes,
    lightMinutes: lightMinutes,
    awakeMinutes: awakeMinutes,
    bedTime: earliestBed,
    wakeTime: latestWake,
    timeInBedMinutes: timeInBedMinutes > 0 ? timeInBedMinutes : null,
    efficiency: efficiency,
    latencyMinutes: longestKeptLatency,
  );
}

/// Group a flat list of Health Connect / HealthKit sleep [HealthDataPoint]s
/// into sessions, then bucket those sessions by their WAKE date.
///
/// Returned map: key = the local calendar date (midnight `DateTime`) the
/// session woke on; value = the list of sessions that woke on that date,
/// each session being its own `List<HealthDataPoint>`.
///
/// Rules — the single source of truth shared by
/// [HealthServiceExt.getNightlySleepHistory] and
/// [HealthServiceExt.getDailySleepByWakeDate]:
///   • points are grouped into sessions by `uuid` (one Health Connect
///     `SleepSessionRecord` = one uuid). Empty-uuid points (older Health
///     Connect rows, some HealthKit samples) each become their own
///     synthetic session, never merged together and never dropped;
///   • zero- / negative-length artifacts (clock skew, malformed writes)
///     are dropped up front so they cannot affect a wake-date decision;
///   • a session's WAKE date is the local calendar date of its LATEST
///     `dateTo` — so a sleep that crosses midnight (e.g. 11pm Mon -> 6am
///     Tue) files under the morning it ended (Tue), counted exactly once.
///
/// This is a pure function (no I/O) so the wake-date attribution can be
/// unit-tested directly against synthetic payloads.
@visibleForTesting
Map<DateTime, List<List<HealthDataPoint>>> bucketSleepPointsByWakeDate(
    List<HealthDataPoint> points) {
  // Group points into sessions by uuid.
  final sessionPoints = <String, List<HealthDataPoint>>{};
  var orphanCounter = 0;
  for (final point in points) {
    // Skip zero- / negative-length artifacts up front.
    if (point.dateTo.difference(point.dateFrom).inMinutes <= 0) continue;
    final key =
        point.uuid.isNotEmpty ? point.uuid : '__orphan_${orphanCounter++}';
    sessionPoints.putIfAbsent(key, () => <HealthDataPoint>[]).add(point);
  }

  // Bucket each session under the local calendar date of its latest end.
  final byNight = <DateTime, List<List<HealthDataPoint>>>{};
  sessionPoints.forEach((_, pts) {
    DateTime? latestEnd;
    for (final p in pts) {
      if (latestEnd == null || p.dateTo.isAfter(latestEnd)) {
        latestEnd = p.dateTo;
      }
    }
    if (latestEnd == null) return;
    final wakeDate = DateTime(latestEnd.year, latestEnd.month, latestEnd.day);
    byNight.putIfAbsent(wakeDate, () => <List<HealthDataPoint>>[]).add(pts);
  });

  return byNight;
}
