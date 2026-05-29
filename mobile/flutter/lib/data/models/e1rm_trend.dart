/// Per-muscle estimated-1RM trend — feeds the Stats-tab "Next-PR ETA" /
/// strength-trend surface. Backed by `GET /api/v1/scores/strength/e1rm-trend`.
///
/// best_e1rm_kg is the MAX estimated 1RM (KILOGRAMS) across a muscle's
/// exercises completed that ISO week, or null when no loaded set was logged
/// that week. The backend zero/null-fills to exactly `weeks` buckets
/// (oldest to newest, local-Monday weeks) and only returns muscles with at
/// least one non-null week. Weight is kg (UI converts to lbs per
/// feedback_weight_units.md). Hand-written fromJson — no codegen / .g.dart.
library;

import 'package:flutter/foundation.dart';

/// One ISO-week bucket of a muscle's best estimated 1RM.
@immutable
class E1rmPoint {
  /// Monday of the ISO week, user-local (parsed from "YYYY-MM-DD").
  final DateTime weekStart;

  /// Best estimated 1RM that week (kg), or null when nothing loaded was logged.
  final double? bestE1rmKg;

  const E1rmPoint({required this.weekStart, required this.bestE1rmKg});

  factory E1rmPoint.fromJson(Map<String, dynamic> json) {
    final raw = (json['week_start'] as String?) ?? '';
    final parsed =
        DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return E1rmPoint(
      weekStart: parsed,
      bestE1rmKg: (json['best_e1rm_kg'] as num?)?.toDouble(),
    );
  }
}

/// A single muscle group's e1RM trend (exactly `weeks` buckets, oldest→newest).
@immutable
class MuscleE1rmTrend {
  final String muscleGroup;
  final List<E1rmPoint> weeks;

  const MuscleE1rmTrend({required this.muscleGroup, required this.weeks});

  /// The most recent non-null estimated 1RM (kg), or null if the series is all
  /// null. Walks from newest to oldest so a sparse recent week doesn't hide an
  /// earlier real value.
  double? get currentBestKg {
    for (var i = weeks.length - 1; i >= 0; i--) {
      final v = weeks[i].bestE1rmKg;
      if (v != null) return v;
    }
    return null;
  }

  factory MuscleE1rmTrend.fromJson(Map<String, dynamic> json) {
    final list = (json['weeks'] as List?) ?? const [];
    return MuscleE1rmTrend(
      muscleGroup: (json['muscle_group'] as String?) ?? '',
      weeks: list
          .whereType<Map<String, dynamic>>()
          .map(E1rmPoint.fromJson)
          .toList(growable: false),
    );
  }
}

/// The full set of per-muscle e1RM trends.
@immutable
class E1rmTrend {
  final List<MuscleE1rmTrend> muscles;

  const E1rmTrend({required this.muscles});

  /// True when no muscle has any loaded-set history in the window.
  bool get hasNoData => muscles.isEmpty;

  /// Case-insensitive lookup of one muscle's trend, or null if absent.
  MuscleE1rmTrend? forMuscle(String muscleGroup) {
    final target = muscleGroup.trim().toLowerCase();
    for (final m in muscles) {
      if (m.muscleGroup.trim().toLowerCase() == target) return m;
    }
    return null;
  }

  factory E1rmTrend.fromJson(Map<String, dynamic> json) {
    final list = (json['muscles'] as List?) ?? const [];
    return E1rmTrend(
      muscles: list
          .whereType<Map<String, dynamic>>()
          .map(MuscleE1rmTrend.fromJson)
          .toList(growable: false),
    );
  }
}
