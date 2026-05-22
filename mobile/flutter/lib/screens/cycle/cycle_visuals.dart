/// Shared visual + formatting helpers for the Cycle feature.
///
/// Centralises phase colours, BBT unit conversion, date formatting and the
/// dynamic-copy variant pools so every Cycle widget (Today / Calendar /
/// Insights / home card / chart) reads consistently. No state — pure
/// functions and constants.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/hormonal_health.dart';

/// Canonical per-phase colours for the Cycle feature. Distinct hues are
/// intentional — a single pink accent cannot disambiguate four phase bands
/// on a chart or calendar. The pink accent is reserved for chrome / CTAs.
class CyclePhaseColors {
  CyclePhaseColors._();

  static const Color menstrual = Color(0xFFE5567B); // deep rose
  static const Color follicular = Color(0xFF66BB6A); // fresh green
  static const Color ovulation = Color(0xFFFFB300); // warm amber
  static const Color luteal = Color(0xFF7E8CE0); // soft indigo
  static const Color unknown = Color(0xFF9E9E9E);

  static Color of(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return menstrual;
      case CyclePhase.follicular:
        return follicular;
      case CyclePhase.ovulation:
        return ovulation;
      case CyclePhase.luteal:
        return luteal;
      case null:
        return unknown;
    }
  }

  /// Emoji glyph for the phase — used on the phase ring + day callouts.
  static String emoji(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '🌙';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '☀️';
      case CyclePhase.luteal:
        return '🍂';
      case null:
        return '✨';
    }
  }

  /// A short, human one-liner for the phase (non-clinical, encouraging).
  static String tagline(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Rest and recover — be kind to yourself.';
      case CyclePhase.follicular:
        return 'Energy is climbing — a good week to push.';
      case CyclePhase.ovulation:
        return 'Peak energy — strength and stamina shine now.';
      case CyclePhase.luteal:
        return 'Winding down — steady effort over intensity.';
      case null:
        return 'Log your cycle to see phase guidance.';
    }
  }
}

/// Basal-body-temperature unit conversion + display. The canonical storage
/// unit is Celsius (`hormone_logs.basal_body_temperature`); the user works in
/// imperial so Fahrenheit is the display default.
class CycleTemp {
  CycleTemp._();

  static double cToF(double c) => c * 9 / 5 + 32;
  static double fToC(double f) => (f - 32) * 5 / 9;

  /// Whether the user's profile unit string means Fahrenheit. Defaults to
  /// true (imperial) for anything not explicitly 'celsius'/'c'.
  static bool isFahrenheit(String? bbtUnit) {
    final u = bbtUnit?.trim().toLowerCase();
    return u != 'celsius' && u != 'c';
  }

  /// Format a canonical-Celsius temperature in the user's unit, e.g.
  /// `36.55` °C → `97.79°F` or `36.55°C`.
  static String format(double celsius, {required bool fahrenheit}) {
    if (fahrenheit) {
      return '${cToF(celsius).toStringAsFixed(2)}°F';
    }
    return '${celsius.toStringAsFixed(2)}°C';
  }

  /// The display value (number only) in the user's unit.
  static double display(double celsius, {required bool fahrenheit}) =>
      fahrenheit ? cToF(celsius) : celsius;

  /// Sensible BBT slider bounds in the user's unit (covers the realistic
  /// 35.5–37.8 °C waking-temperature band with margin).
  static double minDisplay({required bool fahrenheit}) =>
      fahrenheit ? 96.0 : 35.5;
  static double maxDisplay({required bool fahrenheit}) =>
      fahrenheit ? 100.0 : 37.8;
}

/// Compact date formatting used across the Cycle feature.
class CycleDates {
  CycleDates._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// `May 22`
  static String medium(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// `Thu, May 22`
  static String withWeekday(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${medium(d)}';

  /// `May 2026`
  static String monthYear(DateTime d) =>
      '${_monthsFull[d.month - 1]} ${d.year}';

  /// Strip a [DateTime] to local-midnight.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Dynamic-copy variant pools so headline lines never read robotically.
/// Each pool has ≥4 variants; [pick] selects deterministically from a seed
/// (e.g. the cycle day) so the copy is stable within a day but varied across
/// days.
class CycleCopy {
  CycleCopy._();

  static T pick<T>(List<T> pool, int seed) =>
      pool[seed.abs() % pool.length];

  /// "Period in N days" headline variants.
  static String periodIn(int days, int seed) {
    if (days <= 0) return 'Period expected today';
    final pool = <String>[
      'Period in $days day${days == 1 ? '' : 's'}',
      '$days day${days == 1 ? '' : 's'} until your period',
      'Next period: ~$days day${days == 1 ? '' : 's'} away',
      'About $days day${days == 1 ? '' : 's'} to your period',
    ];
    return pick(pool, seed);
  }

  /// Fertile-window headline variants.
  static String fertileNow(int seed) {
    final pool = <String>[
      'Fertile window is open',
      "You're in your fertile window",
      'Fertile days are here',
      'High-fertility window now',
    ];
    return pick(pool, seed);
  }

  /// Late-period framing (never alarmist).
  static String lateBy(int days, int seed) {
    final pool = <String>[
      'Period is $days day${days == 1 ? '' : 's'} later than expected',
      '$days day${days == 1 ? '' : 's'} past your predicted date',
      'Running $days day${days == 1 ? '' : 's'} late vs the estimate',
      'No period logged yet — $days day${days == 1 ? '' : 's'} past estimate',
    ];
    return pick(pool, seed);
  }
}

/// Confidence-level presentation (estimates are always labelled).
class CycleConfidence {
  CycleConfidence._();

  static String label(String confidence) {
    switch (confidence) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Medium confidence';
      default:
        return 'Low confidence';
    }
  }

  static Color color(String confidence) {
    switch (confidence) {
      case 'high':
        return const Color(0xFF66BB6A);
      case 'medium':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFE5567B);
    }
  }

  /// 0..1 fill for a confidence meter.
  static double fraction(String confidence) {
    switch (confidence) {
      case 'high':
        return 1.0;
      case 'medium':
        return 0.6;
      default:
        return 0.3;
    }
  }
}

/// Map a date to its cycle phase using a [CyclePrediction]'s window dates.
/// Used by the Calendar tab to colour each day cell. Returns null when the
/// prediction has no window data (e.g. zero history).
CyclePhase? cyclePhaseForDate(CyclePrediction prediction, DateTime date) {
  final d = CycleDates.dateOnly(date);
  final lastStart = prediction.lastPeriodStart;
  if (lastStart == null) return null;

  // Menstrual: within the last logged period span.
  final periodLen = prediction.stats.avgPeriodLength?.round() ?? 5;
  final periodEnd = lastStart.add(Duration(days: math.max(periodLen, 1) - 1));
  if (!d.isBefore(lastStart) && !d.isAfter(periodEnd)) {
    return CyclePhase.menstrual;
  }

  final fStart = prediction.fertileWindowStart;
  final fEnd = prediction.fertileWindowEnd;
  if (fStart != null && fEnd != null) {
    if (!d.isBefore(fStart) && !d.isAfter(fEnd)) return CyclePhase.ovulation;
    if (d.isAfter(periodEnd) && d.isBefore(fStart)) {
      return CyclePhase.follicular;
    }
  }

  final nextPeriod = prediction.nextPeriodDate;
  if (nextPeriod != null && d.isBefore(nextPeriod) && fEnd != null &&
      d.isAfter(fEnd)) {
    return CyclePhase.luteal;
  }
  return null;
}
