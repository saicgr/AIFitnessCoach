import 'package:flutter/foundation.dart';

/// Cardio personal record — single row from `personal_records` where
/// `sport IS NOT NULL` (see migration 2094). Cardio PRs share the same
/// table as strength PRs but use a different subset of columns:
/// `record_value`/`record_unit`/`sport` instead of `weight_kg`/`reps`/`estimated_1rm_kg`.
///
/// `kind` matches the backend's `record_type` vocabulary:
///   longest_distance | fastest_mile | fastest_5k | fastest_10k |
///   longest_duration_session | best_avg_speed | biggest_weekly_distance_km
@immutable
class CardioPersonalRecord {
  final String sport;
  final String kind;
  final double recordValue;
  final String recordUnit;
  final double? previousValue;
  final double? improvementPercent;
  final bool isFirstTimeActivity;
  final DateTime achievedAt;
  final String? celebrationMessage;
  final List<CardioPrSparklinePoint> sparkline;

  const CardioPersonalRecord({
    required this.sport,
    required this.kind,
    required this.recordValue,
    required this.recordUnit,
    required this.previousValue,
    required this.improvementPercent,
    required this.isFirstTimeActivity,
    required this.achievedAt,
    required this.celebrationMessage,
    required this.sparkline,
  });

  factory CardioPersonalRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['sparkline'] as List<dynamic>? ?? const [];
    return CardioPersonalRecord(
      sport: (json['sport'] ?? '') as String,
      kind: (json['kind'] ?? json['record_type'] ?? '') as String,
      recordValue: (json['record_value'] as num?)?.toDouble() ?? 0.0,
      recordUnit: (json['record_unit'] ?? '') as String,
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      improvementPercent: (json['improvement_percent'] as num?)?.toDouble(),
      isFirstTimeActivity: (json['is_first_time_activity'] as bool?) ?? false,
      achievedAt: _parseDate(json['achieved_at']),
      celebrationMessage: json['celebration_message'] as String?,
      sparkline: raw
          .map((p) => CardioPrSparklinePoint.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'sport': sport,
        'kind': kind,
        'record_value': recordValue,
        'record_unit': recordUnit,
        'previous_value': previousValue,
        'improvement_percent': improvementPercent,
        'is_first_time_activity': isFirstTimeActivity,
        'achieved_at': achievedAt.toIso8601String(),
        'celebration_message': celebrationMessage,
        'sparkline': sparkline.map((s) => s.toJson()).toList(),
      };

  /// Human-readable kind label for sheet rows.
  String get kindLabel {
    switch (kind) {
      case 'longest_distance':
        return 'Longest distance';
      case 'fastest_mile':
        return 'Fastest mile';
      case 'fastest_5k':
        return 'Fastest 5K';
      case 'fastest_10k':
        return 'Fastest 10K';
      case 'longest_duration_session':
        return 'Longest session';
      case 'best_avg_speed':
        return 'Top avg speed';
      case 'biggest_weekly_distance_km':
        return 'Biggest week';
      default:
        return kind;
    }
  }

  /// Format `recordValue`+`recordUnit` based on kind. Pace-style kinds
  /// (`fastest_*`) render as m:ss; durations as h:mm; distances as km/mi;
  /// speeds keep the stored unit (kmh / mph).
  String formatValue() {
    switch (kind) {
      case 'longest_distance':
        // recordUnit = 'm' — show km with two decimals.
        final km = recordValue / 1000.0;
        return '${km.toStringAsFixed(2)} km';
      case 'biggest_weekly_distance_km':
        return '${recordValue.toStringAsFixed(1)} km';
      case 'longest_duration_session':
        // seconds → h:mm or m:ss.
        final total = recordValue.round();
        final h = total ~/ 3600;
        final m = (total % 3600) ~/ 60;
        final s = total % 60;
        if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
        return '$m:${s.toString().padLeft(2, '0')}';
      case 'fastest_mile':
        return '${_formatPace(recordValue)} / mi';
      case 'fastest_5k':
      case 'fastest_10k':
        return _formatPace(recordValue);
      case 'best_avg_speed':
        // Stored kmh; show km/h. (Per-user mph display is a wiring concern
        // — keep raw here, presentation layer can convert if needed.)
        return '${recordValue.toStringAsFixed(1)} km/h';
      default:
        return '${recordValue.toStringAsFixed(1)} $recordUnit';
    }
  }

  /// Improvement copy ("+0:23 faster", "+0.4 km", "+2.1%"). Returns null
  /// when there's no prior value (first PR for this kind).
  String? formatDelta() {
    if (previousValue == null) return null;
    final delta = (recordValue - previousValue!).abs();
    switch (kind) {
      case 'fastest_mile':
      case 'fastest_5k':
      case 'fastest_10k':
        return '${_formatPace(delta)} faster';
      case 'longest_distance':
        return '+${(delta / 1000).toStringAsFixed(2)} km';
      case 'longest_duration_session':
        final m = (delta / 60).round();
        return '+${m}m';
      case 'best_avg_speed':
        return '+${delta.toStringAsFixed(1)} km/h';
      case 'biggest_weekly_distance_km':
        return '+${delta.toStringAsFixed(1)} km';
      default:
        if (improvementPercent != null) {
          return '+${improvementPercent!.toStringAsFixed(1)}%';
        }
        return null;
    }
  }

  static String _formatPace(double seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v).toUtc();
      } catch (_) {}
    }
    return DateTime.now().toUtc();
  }
}

@immutable
class CardioPrSparklinePoint {
  final DateTime achievedAt;
  final double recordValue;
  final String? recordUnit;
  final String? sport;
  final String? kind;
  final bool isFirstTimeActivity;

  const CardioPrSparklinePoint({
    required this.achievedAt,
    required this.recordValue,
    this.recordUnit,
    this.sport,
    this.kind,
    this.isFirstTimeActivity = false,
  });

  factory CardioPrSparklinePoint.fromJson(Map<String, dynamic> json) =>
      CardioPrSparklinePoint(
        achievedAt: CardioPersonalRecord._parseDate(json['achieved_at']),
        recordValue: (json['record_value'] as num?)?.toDouble() ?? 0.0,
        recordUnit: json['record_unit'] as String?,
        sport: json['sport'] as String?,
        kind: json['kind'] as String?,
        isFirstTimeActivity:
            (json['is_first_time_activity'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'achieved_at': achievedAt.toIso8601String(),
        'record_value': recordValue,
        if (recordUnit != null) 'record_unit': recordUnit,
        if (sport != null) 'sport': sport,
        if (kind != null) 'kind': kind,
        'is_first_time_activity': isFirstTimeActivity,
      };
}

/// Lightweight group wrapper returned by `GET /cardio-prs`.
@immutable
class CardioPrGroup {
  final String sport;
  final List<CardioPersonalRecord> items;

  const CardioPrGroup({required this.sport, required this.items});

  factory CardioPrGroup.fromJson(Map<String, dynamic> json) => CardioPrGroup(
        sport: (json['sport'] ?? '') as String,
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) =>
                CardioPersonalRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );
}
