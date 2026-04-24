// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_analyzer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostureFinding _$PostureFindingFromJson(Map<String, dynamic> json) =>
    PostureFinding(
      issue: json['issue'] as String,
      severity: (json['severity'] as num).toInt(),
      description: json['description'] as String,
      correctiveExerciseTag: json['corrective_exercise_tag'] as String,
    );

Map<String, dynamic> _$PostureFindingToJson(PostureFinding instance) =>
    <String, dynamic>{
      'issue': instance.issue,
      'severity': instance.severity,
      'description': instance.description,
      'corrective_exercise_tag': instance.correctiveExerciseTag,
    };

BodyAnalyzerSnapshot _$BodyAnalyzerSnapshotFromJson(
  Map<String, dynamic> json,
) =>
    BodyAnalyzerSnapshot(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      overallRating: (json['overall_rating'] as num?)?.toInt(),
      bodyType: json['body_type'] as String?,
      bodyFatPercent: (json['body_fat_percent'] as num?)?.toDouble(),
      muscleMassPercent: (json['muscle_mass_percent'] as num?)?.toDouble(),
      symmetryScore: (json['symmetry_score'] as num?)?.toInt(),
      bodyAge: (json['body_age'] as num?)?.toInt(),
      feedbackText: json['feedback_text'] as String?,
      improvementTips: (json['improvement_tips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      postureFindings: (json['posture_findings'] as List<dynamic>?)
              ?.map((e) => PostureFinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PostureFinding>[],
      frontPhotoId: json['front_photo_id'] as String?,
      backPhotoId: json['back_photo_id'] as String?,
      sideLeftPhotoId: json['side_left_photo_id'] as String?,
      sideRightPhotoId: json['side_right_photo_id'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$BodyAnalyzerSnapshotToJson(
  BodyAnalyzerSnapshot instance,
) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'overall_rating': instance.overallRating,
      'body_type': instance.bodyType,
      'body_fat_percent': instance.bodyFatPercent,
      'muscle_mass_percent': instance.muscleMassPercent,
      'symmetry_score': instance.symmetryScore,
      'body_age': instance.bodyAge,
      'feedback_text': instance.feedbackText,
      'improvement_tips': instance.improvementTips,
      'posture_findings':
          instance.postureFindings.map((e) => e.toJson()).toList(),
      'front_photo_id': instance.frontPhotoId,
      'back_photo_id': instance.backPhotoId,
      'side_left_photo_id': instance.sideLeftPhotoId,
      'side_right_photo_id': instance.sideRightPhotoId,
      'created_at': instance.createdAt,
    };

BodyAnalyzerRequest _$BodyAnalyzerRequestFromJson(Map<String, dynamic> json) =>
    BodyAnalyzerRequest(
      photoIds:
          (json['photo_ids'] as List<dynamic>).map((e) => e as String).toList(),
      includeMeasurements: json['include_measurements'] as bool? ?? true,
      userContext: json['user_context'] as String?,
    );

Map<String, dynamic> _$BodyAnalyzerRequestToJson(BodyAnalyzerRequest instance) =>
    <String, dynamic>{
      'photo_ids': instance.photoIds,
      'include_measurements': instance.includeMeasurements,
      'user_context': instance.userContext,
    };

BodyAnalyzerAnalyzeResponse _$BodyAnalyzerAnalyzeResponseFromJson(
  Map<String, dynamic> json,
) =>
    BodyAnalyzerAnalyzeResponse(
      snapshot: BodyAnalyzerSnapshot.fromJson(
          json['snapshot'] as Map<String, dynamic>),
      seededMuscleFocusPoints:
          json['seeded_muscle_focus_points'] as bool? ?? false,
    );

PhotoMeasurementEstimate _$PhotoMeasurementEstimateFromJson(
  Map<String, dynamic> json,
) =>
    PhotoMeasurementEstimate(
      metric: json['metric'] as String,
      valueCm: (json['value_cm'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      method: json['method'] as String? ?? 'photo_ratio',
    );

Map<String, dynamic> _$PhotoMeasurementEstimateToJson(
  PhotoMeasurementEstimate instance,
) =>
    <String, dynamic>{
      'metric': instance.metric,
      'value_cm': instance.valueCm,
      'confidence': instance.confidence,
      'method': instance.method,
    };

PhotoMeasurementExtractionResponse _$PhotoMeasurementExtractionResponseFromJson(
  Map<String, dynamic> json,
) =>
    PhotoMeasurementExtractionResponse(
      estimates: (json['estimates'] as List<dynamic>?)
              ?.map((e) => PhotoMeasurementEstimate.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <PhotoMeasurementEstimate>[],
      scaleReferenceDetected:
          json['scale_reference_detected'] as bool? ?? false,
      overallConfidence: (json['overall_confidence'] as num).toDouble(),
    );

BodyAgeResult _$BodyAgeResultFromJson(Map<String, dynamic> json) =>
    BodyAgeResult(
      bodyAge: (json['body_age'] as num).toInt(),
      chronologicalAge: (json['chronological_age'] as num).toInt(),
      delta: (json['delta'] as num).toInt(),
    );

RetuneProposal _$RetuneProposalFromJson(Map<String, dynamic> json) =>
    RetuneProposal(
      id: json['id'] as String,
      bodyAnalyzerSnapshotId: json['body_analyzer_snapshot_id'] as String,
      proposalJson: Map<String, dynamic>.from(
          json['proposal_json'] as Map<String, dynamic>),
      reasoning: json['reasoning'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      status: json['status'] as String,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
    );

RetunePreview _$RetunePreviewFromJson(Map<String, dynamic> json) =>
    RetunePreview(
      before: Map<String, dynamic>.from(json['before'] as Map<String, dynamic>),
      after: Map<String, dynamic>.from(json['after'] as Map<String, dynamic>),
      fieldDiffs: (json['field_diffs'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList() ??
          const <Map<String, dynamic>>[],
      muscleFocusDiffs: (json['muscle_focus_diffs'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList() ??
          const <Map<String, dynamic>>[],
      reasoning: json['reasoning'] as String? ?? '',
      postureCorrectiveTags: (json['posture_corrective_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      priorityMuscles: (json['priority_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      restDaysPerWeekSuggested:
          (json['rest_days_per_week_suggested'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
    );

RetuneApplyResponse _$RetuneApplyResponseFromJson(Map<String, dynamic> json) =>
    RetuneApplyResponse(
      proposalId: json['proposal_id'] as String,
      status: json['status'] as String,
      appliedAt: json['applied_at'] as String,
      updatedUser: (json['updated_user'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v)) ??
          const <String, dynamic>{},
    );

ApplyCorrectivesResponse _$ApplyCorrectivesResponseFromJson(
  Map<String, dynamic> json,
) =>
    ApplyCorrectivesResponse(
      exercisesAdded: (json['exercises_added'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
              .toList() ??
          const <Map<String, dynamic>>[],
      issuesAddressed: (json['issues_addressed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

DeloadCheckResult _$DeloadCheckResultFromJson(Map<String, dynamic> json) =>
    DeloadCheckResult(
      needsDeload: json['needs_deload'] as bool,
      reason: json['reason'] as String? ?? '',
    );

AudioCoachBrief _$AudioCoachBriefFromJson(Map<String, dynamic> json) =>
    AudioCoachBrief(
      briefId: json['brief_id'] as String,
      briefDate: json['brief_date'] as String,
      scriptText: json['script_text'] as String,
      audioUrl: json['audio_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      coachPersonaId: json['coach_persona_id'] as String?,
      listened: json['listened'] as bool? ?? false,
    );

MenstrualCycleLog _$MenstrualCycleLogFromJson(Map<String, dynamic> json) =>
    MenstrualCycleLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cycleStartDate: json['cycle_start_date'] as String,
      cycleLengthDays: (json['cycle_length_days'] as num?)?.toInt() ?? 28,
      periodLengthDays: (json['period_length_days'] as num?)?.toInt() ?? 5,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MenstrualCycleLogToJson(MenstrualCycleLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'cycle_start_date': instance.cycleStartDate,
      'cycle_length_days': instance.cycleLengthDays,
      'period_length_days': instance.periodLengthDays,
      'notes': instance.notes,
    };

WeeklyVolumeEntry _$WeeklyVolumeEntryFromJson(Map<String, dynamic> json) =>
    WeeklyVolumeEntry(
      muscleGroup: json['muscle_group'] as String,
      weeklySets: (json['weekly_sets'] as num?)?.toInt() ?? 0,
      weeklyVolumeKg: (json['weekly_volume_kg'] as num?)?.toDouble() ?? 0.0,
      capSets: (json['cap_sets'] as num?)?.toInt(),
      pctOfCap: (json['pct_of_cap'] as num?)?.toDouble(),
    );
