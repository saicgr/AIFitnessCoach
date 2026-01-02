import 'package:json_annotation/json_annotation.dart';

part 'strain_prevention.g.dart';

enum StrainRiskLevel {
  @JsonValue('safe')
  safe,
  @JsonValue('warning')
  warning,
  @JsonValue('danger')
  danger,
  @JsonValue('critical')
  critical,
}

enum StrainActivityType {
  @JsonValue('strength')
  strength,
  @JsonValue('cardio')
  cardio,
  @JsonValue('flexibility')
  flexibility,
  @JsonValue('sports')
  sports,
  @JsonValue('other')
  other,
}

extension StrainRiskLevelExtension on StrainRiskLevel {
  String get displayName {
    switch (this) {
      case StrainRiskLevel.safe:
        return 'Safe';
      case StrainRiskLevel.warning:
        return 'Warning';
      case StrainRiskLevel.danger:
        return 'Danger';
      case StrainRiskLevel.critical:
        return 'Critical';
    }
  }

  int get colorValue {
    switch (this) {
      case StrainRiskLevel.safe:
        return 0xFF22C55E;
      case StrainRiskLevel.warning:
        return 0xFFF59E0B;
      case StrainRiskLevel.danger:
        return 0xFFEF4444;
      case StrainRiskLevel.critical:
        return 0xFF7C3AED;
    }
  }

  String get iconName {
    switch (this) {
      case StrainRiskLevel.safe:
        return 'check_circle';
      case StrainRiskLevel.warning:
        return 'warning_amber';
      case StrainRiskLevel.danger:
        return 'error';
      case StrainRiskLevel.critical:
        return 'dangerous';
    }
  }
}

extension StrainActivityTypeExtension on StrainActivityType {
  String get displayName {
    switch (this) {
      case StrainActivityType.strength:
        return 'Strength Training';
      case StrainActivityType.cardio:
        return 'Cardio';
      case StrainActivityType.flexibility:
        return 'Flexibility';
      case StrainActivityType.sports:
        return 'Sports';
      case StrainActivityType.other:
        return 'Other';
    }
  }
}

@JsonSerializable()
class MuscleGroupRisk {
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'risk_level')
  final String riskLevel;
  @JsonKey(name: 'current_volume_kg')
  final double currentVolumeKg;
  @JsonKey(name: 'volume_cap_kg')
  final double volumeCapKg;
  @JsonKey(name: 'weekly_increase_percent')
  final double weeklyIncreasePercent;
  @JsonKey(name: 'recommended_max_increase')
  final double recommendedMaxIncrease;
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;
  @JsonKey(name: 'has_active_alert')
  final bool hasActiveAlert;
  @JsonKey(name: 'alert_message')
  final String? alertMessage;

  const MuscleGroupRisk({
    required this.muscleGroup,
    required this.riskLevel,
    required this.currentVolumeKg,
    required this.volumeCapKg,
    this.weeklyIncreasePercent = 0,
    this.recommendedMaxIncrease = 10,
    this.lastUpdated,
    this.hasActiveAlert = false,
    this.alertMessage,
  });

  factory MuscleGroupRisk.fromJson(Map<String, dynamic> json) =>
      _$MuscleGroupRiskFromJson(json);
  Map<String, dynamic> toJson() => _$MuscleGroupRiskToJson(this);

  StrainRiskLevel get riskLevelEnum {
    switch (riskLevel.toLowerCase()) {
      case 'safe':
        return StrainRiskLevel.safe;
      case 'warning':
        return StrainRiskLevel.warning;
      case 'danger':
        return StrainRiskLevel.danger;
      case 'critical':
        return StrainRiskLevel.critical;
      default:
        return StrainRiskLevel.safe;
    }
  }

  double get volumeUtilization {
    if (volumeCapKg <= 0) return 0;
    return (currentVolumeKg / volumeCapKg) * 100;
  }

  bool get isOverCap => currentVolumeKg > volumeCapKg;

  String get muscleGroupDisplay {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

@JsonSerializable()
class VolumeAlert {
  final String id;
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'alert_type')
  final String alertType;
  @JsonKey(name: 'increase_percent')
  final double increasePercent;
  @JsonKey(name: 'current_volume_kg')
  final double currentVolumeKg;
  @JsonKey(name: 'previous_volume_kg')
  final double previousVolumeKg;
  final String message;
  final String recommendation;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'acknowledged_at')
  final DateTime? acknowledgedAt;
  @JsonKey(name: 'is_acknowledged')
  final bool isAcknowledged;

  const VolumeAlert({
    required this.id,
    required this.muscleGroup,
    required this.alertType,
    required this.increasePercent,
    required this.currentVolumeKg,
    required this.previousVolumeKg,
    required this.message,
    required this.recommendation,
    required this.createdAt,
    this.acknowledgedAt,
    this.isAcknowledged = false,
  });

  factory VolumeAlert.fromJson(Map<String, dynamic> json) =>
      _$VolumeAlertFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeAlertToJson(this);

  String get formattedIncrease => '+${increasePercent.toStringAsFixed(0)}%';

  String get muscleGroupDisplay {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

@JsonSerializable()
class WeeklyVolumeData {
  @JsonKey(name: 'week_start')
  final DateTime weekStart;
  @JsonKey(name: 'week_end')
  final DateTime weekEnd;
  @JsonKey(name: 'week_label')
  final String weekLabel;
  @JsonKey(name: 'total_volume_kg')
  final double totalVolumeKg;
  @JsonKey(name: 'volume_by_muscle')
  final Map<String, double> volumeByMuscle;
  @JsonKey(name: 'workout_count')
  final int workoutCount;
  @JsonKey(name: 'percent_change')
  final double? percentChange;
  @JsonKey(name: 'is_dangerous_increase')
  final bool isDangerousIncrease;

  const WeeklyVolumeData({
    required this.weekStart,
    required this.weekEnd,
    required this.weekLabel,
    required this.totalVolumeKg,
    required this.volumeByMuscle,
    required this.workoutCount,
    this.percentChange,
    this.isDangerousIncrease = false,
  });

  factory WeeklyVolumeData.fromJson(Map<String, dynamic> json) =>
      _$WeeklyVolumeDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyVolumeDataToJson(this);

  String get formattedVolume {
    if (totalVolumeKg >= 1000) {
      return '${(totalVolumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg.toStringAsFixed(0)}kg';
  }
}

@JsonSerializable()
class VolumeHistoryData {
  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;
  final List<WeeklyVolumeData> weeks;
  @JsonKey(name: 'avg_weekly_volume')
  final double avgWeeklyVolume;
  @JsonKey(name: 'peak_volume')
  final double peakVolume;
  @JsonKey(name: 'dangerous_weeks_count')
  final int dangerousWeeksCount;
  @JsonKey(name: 'available_muscle_groups')
  final List<String> availableMuscleGroups;

  const VolumeHistoryData({
    this.muscleGroup,
    required this.weeks,
    required this.avgWeeklyVolume,
    required this.peakVolume,
    this.dangerousWeeksCount = 0,
    this.availableMuscleGroups = const [],
  });

  factory VolumeHistoryData.fromJson(Map<String, dynamic> json) =>
      _$VolumeHistoryDataFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeHistoryDataToJson(this);

  List<WeeklyVolumeData> get sortedWeeks {
    final sorted = List<WeeklyVolumeData>.from(weeks);
    sorted.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return sorted;
  }
}

@JsonSerializable()
class StrainDashboardData {
  @JsonKey(name: 'muscle_risks')
  final List<MuscleGroupRisk> muscleRisks;
  @JsonKey(name: 'unacknowledged_alerts')
  final List<VolumeAlert> unacknowledgedAlerts;
  @JsonKey(name: 'recent_volume_summary')
  final VolumeHistoryData? recentVolumeSummary;
  @JsonKey(name: 'overall_risk_level')
  final String overallRiskLevel;
  @JsonKey(name: 'total_alerts_count')
  final int totalAlertsCount;
  @JsonKey(name: 'last_strain_report')
  final StrainReport? lastStrainReport;

  const StrainDashboardData({
    required this.muscleRisks,
    this.unacknowledgedAlerts = const [],
    this.recentVolumeSummary,
    this.overallRiskLevel = 'safe',
    this.totalAlertsCount = 0,
    this.lastStrainReport,
  });

  factory StrainDashboardData.fromJson(Map<String, dynamic> json) =>
      _$StrainDashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$StrainDashboardDataToJson(this);

  StrainRiskLevel get overallRiskLevelEnum {
    switch (overallRiskLevel.toLowerCase()) {
      case 'safe':
        return StrainRiskLevel.safe;
      case 'warning':
        return StrainRiskLevel.warning;
      case 'danger':
        return StrainRiskLevel.danger;
      case 'critical':
        return StrainRiskLevel.critical;
      default:
        return StrainRiskLevel.safe;
    }
  }

  bool get hasUnacknowledgedAlerts => unacknowledgedAlerts.isNotEmpty;

  List<MuscleGroupRisk> get sortedMuscleRisks {
    final sorted = List<MuscleGroupRisk>.from(muscleRisks);
    final riskOrder = {'critical': 0, 'danger': 1, 'warning': 2, 'safe': 3};
    sorted.sort((a, b) {
      final aOrder = riskOrder[a.riskLevel.toLowerCase()] ?? 4;
      final bOrder = riskOrder[b.riskLevel.toLowerCase()] ?? 4;
      return aOrder.compareTo(bOrder);
    });
    return sorted;
  }
}

@JsonSerializable()
class StrainReport {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'body_part')
  final String bodyPart;
  final String severity;
  @JsonKey(name: 'activity_type')
  final String activityType;
  final String? notes;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'pain_level')
  final int? painLevel;
  @JsonKey(name: 'limits_activity')
  final bool limitsActivity;

  const StrainReport({
    this.id,
    this.userId,
    required this.bodyPart,
    required this.severity,
    required this.activityType,
    this.notes,
    this.occurredAt,
    this.createdAt,
    this.painLevel,
    this.limitsActivity = false,
  });

  factory StrainReport.fromJson(Map<String, dynamic> json) =>
      _$StrainReportFromJson(json);
  Map<String, dynamic> toJson() => _$StrainReportToJson(this);

  String get bodyPartDisplay {
    return bodyPart
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String get severityDisplay {
    switch (severity.toLowerCase()) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      default:
        return severity;
    }
  }
}

@JsonSerializable()
class StrainReportRequest {
  @JsonKey(name: 'body_part')
  final String bodyPart;
  final String severity;
  @JsonKey(name: 'activity_type')
  final String activityType;
  final String? notes;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  @JsonKey(name: 'pain_level')
  final int? painLevel;
  @JsonKey(name: 'limits_activity')
  final bool limitsActivity;

  const StrainReportRequest({
    required this.bodyPart,
    required this.severity,
    required this.activityType,
    this.notes,
    this.occurredAt,
    this.painLevel,
    this.limitsActivity = false,
  });

  factory StrainReportRequest.fromJson(Map<String, dynamic> json) =>
      _$StrainReportRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StrainReportRequestToJson(this);
}

@JsonSerializable()
class AcknowledgeAlertResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'alert_id')
  final String alertId;

  const AcknowledgeAlertResponse({
    required this.success,
    required this.message,
    required this.alertId,
  });

  factory AcknowledgeAlertResponse.fromJson(Map<String, dynamic> json) =>
      _$AcknowledgeAlertResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AcknowledgeAlertResponseToJson(this);
}
