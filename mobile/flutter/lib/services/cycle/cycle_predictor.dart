/// Deterministic menstrual-cycle & fertility prediction engine — Dart mirror.
///
/// This is a faithful port of the Python source-of-truth at
/// `backend/services/cycle/cycle_predictor.py`. It runs on-device so the
/// Cycle screen can render an instant prediction offline; the server value
/// (computed by the same algorithm) is then refreshed silently and wins on
/// any disagreement. **Keep the two in sync when changing the math.**
///
/// No LLM, no RAG — plain, inspectable arithmetic over a user's period
/// history plus optional BBT / cervical-mucus / LH-test signals.
///
/// Evidence base (see the planning doc for citations):
///  * Next-period prediction: recency-weighted average of the last up to 12
///    cycle lengths (Clue's documented 12-cycle window).
///  * Fertile window: ovulation-based window (5 days before ovulation
///    through 1 day after) cross-checked against the Ogino-Knaus calendar
///    method (first fertile day = shortest cycle - 18, last = longest - 11).
///  * Ovulation: counted back a luteal-phase length (default 14 days) from
///    the predicted next period; refined/confirmed by the Marshall
///    "three-over-six" BBT rule and the cervical-mucus peak-day rule
///    (sympto-thermal method).
///
/// Every output date is an ESTIMATE — never a contraceptive method.
library;

import 'dart:math' as math;

import '../../data/models/hormonal_health.dart';

/// A single basal-body-temperature reading. `tempCelsius` is the canonical
/// storage unit (matches `hormone_logs.basal_body_temperature`).
class CycleBbtPoint {
  final DateTime date;
  final double tempCelsius;
  const CycleBbtPoint(this.date, this.tempCelsius);
}

/// A single cervical-mucus observation. `mucus` is the raw enum string from
/// `hormone_logs.cervical_mucus` (e.g. `egg_white`, `watery`, `creamy`).
class CycleMucusPoint {
  final DateTime date;
  final String mucus;
  const CycleMucusPoint(this.date, this.mucus);
}

/// A single LH-test observation. `result` is the raw enum string from
/// `hormone_logs.lh_test_result` (`negative` / `positive` / `peak` / ...).
class CycleLhPoint {
  final DateTime date;
  final String result;
  const CycleLhPoint(this.date, this.result);
}

/// Pure deterministic cycle-prediction engine. Mirrors `cycle_predictor.py`.
class CyclePredictor {
  CyclePredictor._();

  // --- Tuning constants — MUST stay identical to cycle_predictor.py ---------
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int defaultLutealLength = 14; // luteal phase runs ~12-14 days
  static const int minPlausibleCycle = 15; // shorter gap => missed log
  static const int maxPlausibleCycle = 60; // longer gap  => missed log
  static const int maxHistoryCycles = 12; // Clue-style recency window
  static const double regularStddevThreshold = 4.0; // <= => "regular"
  static const int minPredictionWindow = 1;
  static const int maxPredictionWindow = 5; // +/- days around predicted date

  // Marshall three-over-six BBT rule. Stored temps are Celsius; the rule is
  // stated in Fahrenheit, so the thresholds are converted: 0.2 F = 0.111 C,
  // 0.4 F = 0.222 C.
  static const double bbtShiftC = 0.11;
  static const double bbtStrongC = 0.22;
  static const int bbtMinPoints = 9; // 6 baseline + 3 elevated

  static const int fertileDaysBefore = 5; // sperm survive ~5 days
  static const int fertileDaysAfter = 1; // egg survives ~1 day
  static const int peakDaysBefore = 2; // peak = 2 days pre-ovulation + ovu day

  static const Set<String> _fertileMucus = {'egg_white', 'watery'};
  static const Set<String> _positiveLh = {'positive', 'peak'};

  // ---------------------------------------------------------------------------
  // Pure helpers
  // ---------------------------------------------------------------------------

  /// Strip a [DateTime] to local-midnight so all arithmetic is calendar-based.
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole-day difference `b - a` (both are treated as calendar dates).
  static int _daysBetween(DateTime a, DateTime b) =>
      _dateOnly(b).difference(_dateOnly(a)).inDays;

  /// Mean weighted so recent values count more (linear weights 1..n).
  /// Mirrors `_recency_weighted_mean`.
  static double _recencyWeightedMean(List<double> values) {
    final n = values.length;
    double weightedSum = 0;
    double weightTotal = 0;
    for (var i = 0; i < n; i++) {
      final w = i + 1; // weights 1..n, oldest-first
      weightedSum += values[i] * w;
      weightTotal += w;
    }
    return weightedSum / weightTotal;
  }

  /// Gaps (days) between consecutive period starts, oldest-first.
  static List<int> _cycleLengths(List<DateTime> periodStarts) {
    final out = <int>[];
    for (var i = 0; i < periodStarts.length - 1; i++) {
      out.add(_daysBetween(periodStarts[i], periodStarts[i + 1]));
    }
    return out;
  }

  static int _clamp(int value, int low, int high) =>
      math.max(low, math.min(high, value));

  /// Population standard deviation (matches Python `statistics.pstdev`).
  static double _pstdev(List<int> values) {
    final n = values.length;
    if (n == 0) return 0.0;
    final mean = values.reduce((a, b) => a + b) / n;
    var sumSq = 0.0;
    for (final v in values) {
      final d = v - mean;
      sumSq += d * d;
    }
    return math.sqrt(sumSq / n);
  }

  /// Round to one decimal place (matches Python `round(x, 1)`).
  static double _round1(double x) => (x * 10).roundToDouble() / 10;

  /// Round to two decimal places (matches Python `round(x, 2)`).
  static double _round2(double x) => (x * 100).roundToDouble() / 100;

  // ---------------------------------------------------------------------------
  // Cycle statistics — mirrors compute_stats()
  // ---------------------------------------------------------------------------
  static CycleStats _computeStats(
    List<DateTime> periodStarts,
    Map<DateTime, DateTime> periodEnds,
    bool hasPcos,
  ) {
    final periodsLogged = periodStarts.length;

    final rawLengths = _cycleLengths(periodStarts);
    final plausible = rawLengths
        .where((ln) => ln >= minPlausibleCycle && ln <= maxPlausibleCycle)
        .toList();
    // Last `maxHistoryCycles` (Clue-style recency window).
    final used = plausible.length > maxHistoryCycles
        ? plausible.sublist(plausible.length - maxHistoryCycles)
        : plausible;

    double? avg;
    int? minLen;
    int? maxLen;
    double? stddev;
    if (used.isNotEmpty) {
      avg = _round1(
          _recencyWeightedMean(used.map((x) => x.toDouble()).toList()));
      minLen = used.reduce(math.min);
      maxLen = used.reduce(math.max);
      stddev = used.length > 1 ? _round1(_pstdev(used)) : 0.0;
    }

    // Period length from rows that have an end date.
    final periodLengths = <int>[];
    for (final s in periodStarts) {
      final e = periodEnds[s];
      if (e != null && !e.isBefore(s)) {
        periodLengths.add(_daysBetween(s, e) + 1);
      }
    }
    final double? avgPeriodLength = periodLengths.isEmpty
        ? null
        : _round1(periodLengths.reduce((a, b) => a + b) / periodLengths.length);

    String regularity;
    if (hasPcos) {
      regularity = 'irregular';
    } else if (used.length >= 2 && stddev != null) {
      regularity = stddev <= regularStddevThreshold ? 'regular' : 'irregular';
    } else {
      regularity = 'unknown';
    }

    return CycleStats(
      periodsLogged: periodsLogged,
      cyclesTracked: used.length,
      avgCycleLength: avg,
      minCycleLength: minLen,
      maxCycleLength: maxLen,
      cycleLengthStddev: stddev,
      avgPeriodLength: avgPeriodLength,
      regularity: regularity,
    );
  }

  /// Marshall three-over-six rule on Celsius BBT readings (date-ascending).
  ///
  /// Returns `(ovulationDate, coverLineCelsius)` when a sustained thermal
  /// shift is found — 3 consecutive readings at least [bbtShiftC] above the
  /// highest of the prior 6, with at least one [bbtStrongC] higher.
  /// Ovulation is placed on the day before the first elevated reading.
  /// Returns `(null, null)` when no shift is detected.
  static (DateTime?, double?) _detectBbtShift(List<CycleBbtPoint> points) {
    final temps = points.map((p) => p.tempCelsius).toList();
    final dates = points.map((p) => p.date).toList();
    final n = temps.length;
    if (n < bbtMinPoints) return (null, null);
    for (var j = 6; j < n - 2; j++) {
      final prior6 = temps.sublist(j - 6, j);
      final next3 = temps.sublist(j, j + 3);
      final baseline = prior6.reduce(math.max);
      final cover = baseline + bbtShiftC;
      final allAboveCover = next3.every((t) => t >= cover);
      final anyStrong = next3.any((t) => t >= baseline + bbtStrongC);
      if (allAboveCover && anyStrong) {
        return (
          dates[j].subtract(const Duration(days: 1)),
          _round2(cover),
        );
      }
    }
    return (null, null);
  }

  /// Map today onto a cycle phase using the predicted ovulation, not
  /// hardcoded day numbers. Mirrors `_phase_for`.
  static CyclePhase _phaseFor(
    DateTime today,
    DateTime periodStart,
    DateTime periodEndDay,
    DateTime fertileStart,
    DateTime fertileEnd,
  ) {
    if (!today.isBefore(periodStart) && !today.isAfter(periodEndDay)) {
      return CyclePhase.menstrual;
    }
    if (!today.isBefore(fertileStart) && !today.isAfter(fertileEnd)) {
      return CyclePhase.ovulation;
    }
    if (today.isBefore(fertileStart)) {
      return CyclePhase.follicular;
    }
    return CyclePhase.luteal;
  }

  /// A prediction object with everything blank — used for symptom-only
  /// profiles, pregnancy mode, and the zero-history case.
  /// Mirrors `_unavailable`.
  static CyclePrediction _unavailable(
    DateTime today,
    CycleTrackingMode trackingMode,
    CycleStats stats,
    List<String> notes,
  ) {
    return CyclePrediction(
      predictionsAvailable: false,
      trackingMode: trackingMode,
      today: today,
      confidence: 'low',
      ovulationStatus: 'estimated',
      stats: stats,
      notes: notes,
    );
  }

  // ---------------------------------------------------------------------------
  // Main entry point — pure. Mirrors predict().
  // ---------------------------------------------------------------------------
  /// Compute a full [CyclePrediction]. See the library docstring.
  ///
  /// - [periodStarts]: observed period start dates (order does not matter —
  ///   they are sorted + de-duplicated internally).
  /// - [periodEnds]: optional map of period-start date -> period-end date.
  /// - [bbtPoints] / [mucusPoints] / [lhPoints]: optional fertility signals,
  ///   typically the last ~120 days of `hormone_logs`.
  static CyclePrediction predict({
    required DateTime today,
    required List<DateTime> periodStarts,
    Map<DateTime, DateTime>? periodEnds,
    int cycleLengthDefault = defaultCycleLength,
    int periodLengthDefault = defaultPeriodLength,
    int? lutealLengthOverride,
    bool hasMenstrualPeriods = true,
    CycleTrackingMode trackingMode = CycleTrackingMode.tracking,
    bool hasPcos = false,
    List<CycleBbtPoint>? bbtPoints,
    List<CycleMucusPoint>? mucusPoints,
    List<CycleLhPoint>? lhPoints,
  }) {
    final todayD = _dateOnly(today);
    final ends = <DateTime, DateTime>{};
    (periodEnds ?? const {}).forEach((k, v) {
      ends[_dateOnly(k)] = _dateOnly(v);
    });
    final bbt = (bbtPoints ?? const <CycleBbtPoint>[])
        .map((p) => CycleBbtPoint(_dateOnly(p.date), p.tempCelsius))
        .toList();
    final mucus = (mucusPoints ?? const <CycleMucusPoint>[])
        .map((p) => CycleMucusPoint(_dateOnly(p.date), p.mucus))
        .toList();
    final lh = (lhPoints ?? const <CycleLhPoint>[])
        .map((p) => CycleLhPoint(_dateOnly(p.date), p.result))
        .toList();

    // Sorted + de-duplicated period starts (matches `sorted(set(...))`).
    final startSet = <int>{};
    final starts = <DateTime>[];
    for (final raw in periodStarts) {
      final d = _dateOnly(raw);
      final key = d.year * 10000 + d.month * 100 + d.day;
      if (startSet.add(key)) starts.add(d);
    }
    starts.sort();

    // Symptom-only profile or pregnancy mode: no period/fertility prediction.
    if (!hasMenstrualPeriods) {
      return _unavailable(
        todayD,
        trackingMode,
        const CycleStats(),
        const [
          'Period prediction is off for this profile — symptom and '
              'temperature tracking still work.',
        ],
      );
    }
    if (trackingMode == CycleTrackingMode.pregnancy) {
      final stats = starts.isNotEmpty
          ? _computeStats(starts, ends, hasPcos)
          : const CycleStats();
      return _unavailable(
        todayD,
        trackingMode,
        stats,
        const ['Cycle predictions are paused while pregnancy mode is on.'],
      );
    }
    if (starts.isEmpty) {
      return _unavailable(
        todayD,
        trackingMode,
        const CycleStats(),
        const ['Log your first period to start predictions.'],
      );
    }

    final stats = _computeStats(starts, ends, hasPcos);
    final notes = <String>[];

    final lastPeriodStart = starts.last;

    // --- Average cycle length & next-period prediction ----------------------
    final avgCycle = stats.avgCycleLength ?? cycleLengthDefault.toDouble();
    final cyclesTracked = stats.cyclesTracked;
    final stddev = stats.cycleLengthStddev ?? 0.0;
    final regularity = stats.regularity;

    final nextPeriodDate =
        lastPeriodStart.add(Duration(days: avgCycle.round()));
    var window =
        _clamp(stddev.round(), minPredictionWindow, maxPredictionWindow);
    if (cyclesTracked < 2) {
      window = math.max(window, 2); // little history => never claim pinpoint
    }
    final nextPeriodWindowStart =
        nextPeriodDate.subtract(Duration(days: window));
    final nextPeriodWindowEnd = nextPeriodDate.add(Duration(days: window));

    String confidence;
    if (cyclesTracked >= 6) {
      confidence = 'high';
    } else if (cyclesTracked >= 3) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }

    if (cyclesTracked < 2) {
      notes.add(
        'Based on limited history — predictions use a default '
        '$cycleLengthDefault-day cycle and will sharpen as you log more periods.',
      );
    }
    if (regularity == 'irregular') {
      notes.add(
          'Your cycles are irregular, so the fertile window is shown wider.');
    }

    // --- Ovulation estimate -------------------------------------------------
    final luteal = lutealLengthOverride ?? defaultLutealLength;
    final ovulationEstimate = nextPeriodDate.subtract(Duration(days: luteal));

    // --- Sympto-thermal refinement (current cycle only) ---------------------
    final cycleBbt = bbt
        .where((p) => !p.date.isBefore(lastPeriodStart))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final (ovuFromBbt, coverLine) = _detectBbtShift(cycleBbt);

    var ovulationStatus = 'estimated';
    DateTime ovulation;
    if (ovuFromBbt != null) {
      ovulation = ovuFromBbt;
      ovulationStatus = 'confirmed';
      notes.add(
          'Ovulation confirmed by a sustained basal temperature rise.');
    } else {
      final cycleLh = lh
          .where((p) =>
              !p.date.isBefore(lastPeriodStart) &&
              _positiveLh.contains(p.result))
          .map((p) => p.date)
          .toList()
        ..sort();
      final cycleMucus = mucus
          .where((p) =>
              !p.date.isBefore(lastPeriodStart) &&
              _fertileMucus.contains(p.mucus))
          .map((p) => p.date)
          .toList()
        ..sort();
      if (cycleLh.isNotEmpty) {
        ovulation = cycleLh.last.add(const Duration(days: 1));
        notes.add('Ovulation estimate refined by a positive LH test.');
      } else if (cycleMucus.isNotEmpty) {
        ovulation = cycleMucus.last;
        notes.add(
            'Ovulation estimate refined by cervical-mucus peak day.');
      } else {
        ovulation = ovulationEstimate;
      }
    }

    // --- Fertile window -----------------------------------------------------
    var fertileStart = ovulation.subtract(const Duration(days: fertileDaysBefore));
    var fertileEnd = ovulation.add(const Duration(days: fertileDaysAfter));

    if (regularity == 'irregular' &&
        stats.minCycleLength != null &&
        stats.maxCycleLength != null) {
      // Ogino-Knaus calendar cross-check; take the union (wider) for safety.
      final calFirstDaynum = math.max(1, stats.minCycleLength! - 18);
      final calLastDaynum =
          math.max(calFirstDaynum, stats.maxCycleLength! - 11);
      final calStart =
          lastPeriodStart.add(Duration(days: calFirstDaynum - 1));
      final calEnd = lastPeriodStart.add(Duration(days: calLastDaynum - 1));
      if (calStart.isBefore(fertileStart)) fertileStart = calStart;
      if (calEnd.isAfter(fertileEnd)) fertileEnd = calEnd;
    }

    final peakStart = ovulation.subtract(const Duration(days: peakDaysBefore));
    final peakEnd = ovulation;

    // --- Current period membership & cycle day ------------------------------
    final lastEnd = ends[lastPeriodStart];
    int periodLen;
    if (lastEnd != null && !lastEnd.isBefore(lastPeriodStart)) {
      periodLen = _daysBetween(lastPeriodStart, lastEnd) + 1;
    } else {
      periodLen = (stats.avgPeriodLength ?? periodLengthDefault.toDouble())
          .round();
    }
    final periodEndDay = lastPeriodStart
        .add(Duration(days: math.max(periodLen, 1) - 1));
    final inPeriod = !todayD.isBefore(lastPeriodStart) &&
        !todayD.isAfter(periodEndDay);

    final cycleDay = math.max(1, _daysBetween(lastPeriodStart, todayD) + 1);

    // --- Late-period state --------------------------------------------------
    int? daysUntilNextPeriod;
    int? periodLateBy;
    if (todayD.isBefore(nextPeriodDate)) {
      daysUntilNextPeriod = _daysBetween(todayD, nextPeriodDate);
    } else if (todayD.isAfter(nextPeriodWindowEnd)) {
      periodLateBy = _daysBetween(nextPeriodDate, todayD);
      notes.add(
          'Your period is $periodLateBy day(s) later than predicted.');
    }

    // --- Phase + next transition -------------------------------------------
    final phase = _phaseFor(
        todayD, lastPeriodStart, periodEndDay, fertileStart, fertileEnd);

    final transitions = <(DateTime, CyclePhase)>[
      (periodEndDay.add(const Duration(days: 1)), CyclePhase.follicular),
      (fertileStart, CyclePhase.ovulation),
      (fertileEnd.add(const Duration(days: 1)), CyclePhase.luteal),
      (nextPeriodDate, CyclePhase.menstrual),
    ];
    final upcoming = transitions
        .where((t) => t.$1.isAfter(todayD))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    CyclePhase nextPhase;
    int? daysUntilNextPhase;
    if (upcoming.isNotEmpty) {
      nextPhase = upcoming.first.$2;
      daysUntilNextPhase = _daysBetween(todayD, upcoming.first.$1);
    } else {
      nextPhase = CyclePhase.menstrual;
      daysUntilNextPhase = null;
    }

    final conceptionChance =
        (!todayD.isBefore(fertileStart) && !todayD.isAfter(fertileEnd))
            ? 'high'
            : 'low';

    return CyclePrediction(
      predictionsAvailable: true,
      trackingMode: trackingMode,
      today: todayD,
      currentCycleDay: cycleDay,
      currentPhase: phase,
      daysUntilNextPhase: daysUntilNextPhase,
      nextPhase: nextPhase,
      lastPeriodStart: lastPeriodStart,
      inPeriod: inPeriod,
      nextPeriodDate: nextPeriodDate,
      nextPeriodWindowStart: nextPeriodWindowStart,
      nextPeriodWindowEnd: nextPeriodWindowEnd,
      daysUntilNextPeriod: daysUntilNextPeriod,
      periodLateBy: periodLateBy,
      confidence: confidence,
      ovulationDate: ovulation,
      ovulationStatus: ovulationStatus,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      peakFertilityStart: peakStart,
      peakFertilityEnd: peakEnd,
      conceptionChance: conceptionChance,
      coverLineCelsius: coverLine,
      stats: stats,
      notes: notes,
    );
  }

  /// Convenience wrapper: run [predict] from a list of [CyclePeriod] rows
  /// (the shape returned by `HormonalHealthRepository.listPeriods`). Builds
  /// the `periodStarts` / `periodEnds` inputs and forwards the rest.
  static CyclePrediction predictFromPeriods({
    required DateTime today,
    required List<CyclePeriod> periods,
    int cycleLengthDefault = defaultCycleLength,
    int periodLengthDefault = defaultPeriodLength,
    int? lutealLengthOverride,
    bool hasMenstrualPeriods = true,
    CycleTrackingMode trackingMode = CycleTrackingMode.tracking,
    bool hasPcos = false,
    List<CycleBbtPoint>? bbtPoints,
    List<CycleMucusPoint>? mucusPoints,
    List<CycleLhPoint>? lhPoints,
  }) {
    final starts = <DateTime>[];
    final ends = <DateTime, DateTime>{};
    for (final p in periods) {
      final s = _dateOnly(p.startDate);
      starts.add(s);
      final e = p.endDate;
      if (e != null) ends[s] = _dateOnly(e);
    }
    return predict(
      today: today,
      periodStarts: starts,
      periodEnds: ends,
      cycleLengthDefault: cycleLengthDefault,
      periodLengthDefault: periodLengthDefault,
      lutealLengthOverride: lutealLengthOverride,
      hasMenstrualPeriods: hasMenstrualPeriods,
      trackingMode: trackingMode,
      hasPcos: hasPcos,
      bbtPoints: bbtPoints,
      mucusPoints: mucusPoints,
      lhPoints: lhPoints,
    );
  }
}
