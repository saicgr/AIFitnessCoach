// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strain_prevention.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MuscleGroupRisk _$MuscleGroupRiskFromJson(Map<String, dynamic> json) =>
    MuscleGroupRisk(
      muscleGroup: json['muscle_group'] as String,
      riskLevel: json['risk_level'] as String,
      currentVolumeKg: (json['current_volume_kg'] as num).toDouble(),
      volumeCapKg: (json['volume_cap_kg'] as num).toDouble(),
      weeklyIncreasePercent:
          (json['weekly_increase_percent'] as num?)?.toDouble() ?? 0,
      recommendedMaxIncrease:
          (json['recommended_max_increase'] as num?)?.toDouble() ?? 10,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
      hasActiveAlert: json['has_active_alert'] as bool? ?? false,
      alertMessage: json['alert_message'] as String?,
    );

Map<String, dynamic> _$MuscleGroupRiskToJson(MuscleGroupRisk instance) =>
    <String, dynamic>{
      'muscle_group': instance.muscleGroup,
      'risk_level': instance.riskLevel,
      'current_volume_kg': instance.currentVolumeKg,
      'volume_cap_kg': instance.volumeCapKg,
      'weekly_increase_percent': instance.weeklyIncreasePercent,
      'recommended_max_increase': instance.recommendedMaxIncrease,
      'last_updated': instance.lastUpdated?.toIso8601String(),
      'has_active_alert': instance.hasActiveAlert,
      'alert_message': instance.alertMessage,
    };

VolumeAlert _$VolumeAlertFromJson(Map<String, dynamic> json) => VolumeAlert(
  id: json['id'] as String,
  muscleGroup: json['muscle_group'] as String,
  alertType: json['alert_type'] as String,
  increasePercent: (json['increase_percent'] as num).toDouble(),
  currentVolumeKg: (json['current_volume_kg'] as num).toDouble(),
  previousVolumeKg: (json['previous_volume_kg'] as num).toDouble(),
  message: json['message'] as String,
  recommendation: json['recommendation'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  acknowledgedAt: json['acknowledged_at'] == null
      ? null
      : DateTime.parse(json['acknowledged_at'] as String),
  isAcknowledged: json['is_acknowledged'] as bool? ?? false,
);

Map<String, dynamic> _$VolumeAlertToJson(VolumeAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'muscle_group': instance.muscleGroup,
      'alert_type': instance.alertType,
      'increase_percent': instance.increasePercent,
      'current_volume_kg': instance.currentVolumeKg,
      'previous_volume_kg': instance.previousVolumeKg,
      'message': instance.message,
      'recommendation': instance.recommendation,
      'created_at': instance.createdAt.toIso8601String(),
      'acknowledged_at': instance.acknowledgedAt?.toIso8601String(),
      'is_acknowledged': instance.isAcknowledged,
    };

WeeklyVolumeData _$WeeklyVolumeDataFromJson(Map<String, dynamic> json) =>
    WeeklyVolumeData(
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      weekLabel: json['week_label'] as String,
      totalVolumeKg: (json['total_volume_kg'] as num).toDouble(),
      volumeByMuscle: (json['volume_by_muscle'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      workoutCount: (json['workout_count'] as num).toInt(),
      percentChange: (json['percent_change'] as num?)?.toDouble(),
      isDangerousIncrease: json['is_dangerous_increase'] as bool? ?? false,
    );

Map<String, dynamic> _$WeeklyVolumeDataToJson(WeeklyVolumeData instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart.toIso8601String(),
      'week_end': instance.weekEnd.toIso8601String(),
      'week_label': instance.weekLabel,
      'total_volume_kg': instance.totalVolumeKg,
      'volume_by_muscle': instance.volumeByMuscle,
      'workout_count': instance.workoutCount,
      'percent_change': instance.percentChange,
      'is_dangerous_increase': instance.isDangerousIncrease,
    };

VolumeHistoryData _$VolumeHistoryDataFromJson(Map<String, dynamic> json) =>
    VolumeHistoryData(
      muscleGroup: json['muscle_group'] as String?,
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => WeeklyVolumeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgWeeklyVolume: (json['avg_weekly_volume'] as num).toDouble(),
      peakVolume: (json['peak_volume'] as num).toDouble(),
      dangerousWeeksCount:
          (json['dangerous_weeks_count'] as num?)?.toInt() ?? 0,
      availableMuscleGroups:
          (json['available_muscle_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$VolumeHistoryDataToJson(VolumeHistoryData instance) =>
    <String, dynamic>{
      'muscle_group': instance.muscleGroup,
      'weeks': instance.weeks,
      'avg_weekly_volume': instance.avgWeeklyVolume,
      'peak_volume': instance.peakVolume,
      'dangerous_weeks_count': instance.dangerousWeeksCount,
      'available_muscle_groups': instance.availableMuscleGroups,
    };

StrainDashboardData _$StrainDashboardDataFromJson(Map<String, dynamic> json) =>
    StrainDashboardData(
      muscleRisks: (json['muscle_risks'] as List<dynamic>)
          .map((e) => MuscleGroupRisk.fromJson(e as Map<String, dynamic>))
          .toList(),
      unacknowledgedAlerts:
          (json['unacknowledged_alerts'] as List<dynamic>?)
              ?.map((e) => VolumeAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentVolumeSummary: json['recent_volume_summary'] == null
          ? null
          : VolumeHistoryData.fromJson(
              json['recent_volume_summary'] as Map<String, dynamic>,
            ),
      overallRiskLevel: json['overall_risk_level'] as String? ?? 'safe',
      totalAlertsCount: (json['total_alerts_count'] as num?)?.toInt() ?? 0,
      lastStrainReport: json['last_strain_report'] == null
          ? null
          : StrainReport.fromJson(
              json['last_strain_report'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$StrainDashboardDataToJson(
  StrainDashboardData instance,
) => <String, dynamic>{
  'muscle_risks': instance.muscleRisks,
  'unacknowledged_alerts': instance.unacknowledgedAlerts,
  'recent_volume_summary': instance.recentVolumeSummary,
  'overall_risk_level': instance.overallRiskLevel,
  'total_alerts_count': instance.totalAlertsCount,
  'last_strain_report': instance.lastStrainReport,
};

StrainReport _$StrainReportFromJson(Map<String, dynamic> json) => StrainReport(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  bodyPart: json['body_part'] as String,
  severity: json['severity'] as String,
  activityType: json['activity_type'] as String,
  notes: json['notes'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  painLevel: (json['pain_level'] as num?)?.toInt(),
  limitsActivity: json['limits_activity'] as bool? ?? false,
);

Map<String, dynamic> _$StrainReportToJson(StrainReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'body_part': instance.bodyPart,
      'severity': instance.severity,
      'activity_type': instance.activityType,
      'notes': instance.notes,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'pain_level': instance.painLevel,
      'limits_activity': instance.limitsActivity,
    };

StrainReportRequest _$StrainReportRequestFromJson(Map<String, dynamic> json) =>
    StrainReportRequest(
      bodyPart: json['body_part'] as String,
      severity: json['severity'] as String,
      activityType: json['activity_type'] as String,
      notes: json['notes'] as String?,
      occurredAt: json['occurred_at'] == null
          ? null
          : DateTime.parse(json['occurred_at'] as String),
      painLevel: (json['pain_level'] as num?)?.toInt(),
      limitsActivity: json['limits_activity'] as bool? ?? false,
    );

Map<String, dynamic> _$StrainReportRequestToJson(
  StrainReportRequest instance,
) => <String, dynamic>{
  'body_part': instance.bodyPart,
  'severity': instance.severity,
  'activity_type': instance.activityType,
  'notes': instance.notes,
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'pain_level': instance.painLevel,
  'limits_activity': instance.limitsActivity,
};

AcknowledgeAlertResponse _$AcknowledgeAlertResponseFromJson(
  Map<String, dynamic> json,
) => AcknowledgeAlertResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  alertId: json['alert_id'] as String,
);

Map<String, dynamic> _$AcknowledgeAlertResponseToJson(
  AcknowledgeAlertResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'alert_id': instance.alertId,
};
